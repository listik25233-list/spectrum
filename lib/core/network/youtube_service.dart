import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';
import 'package:dio/dio.dart';
import 'package:spectrum/src/rust/api/simple.dart';
import 'package:logger/logger.dart';
import 'package:spectrum/core/db/schemas/track_schema.dart';
import 'package:spectrum/core/db/isar_service.dart';
import 'package:spectrum/core/network/soundcloud_service.dart';
import 'package:spectrum/src/rust/api/simple.dart' as rust_simple;
import 'package:spectrum/src/rust/api/cache.dart' as rust_cache;
import 'package:spectrum/src/rust/api/models.dart' as rust_models;
import 'package:spectrum/core/db/schemas/youtube_search_cache.dart';
import 'package:isar/isar.dart';

class YoutubeAudioService {
  static const _ytDlpPathsLinux = ['/usr/bin/yt-dlp', '/usr/local/bin/yt-dlp'];
  static const _ytDlpPathsWindows = [
    'C:\\yt-dlp\\yt-dlp.exe',
    'yt-dlp.exe',
    'yt-dlp'
  ];

  /// Piped instances for mobile fallback (public, no auth needed)
  static const _pipedInstances = [
    'https://pipedapi.kavin.rocks',
    'https://pipedapi.adminforge.de',
    'https://api.piped.projectsegfau.lt',
    'https://pipedapi.in.projectsegfau.lt',
    'https://pipedapi.leptons.xyz',
  ];

  final _log = Logger();
  YoutubeExplode _yt = YoutubeExplode();
  final HttpClient _httpClient = HttpClient()
    ..connectionTimeout = const Duration(seconds: 10)
    ..idleTimeout = const Duration(seconds: 15);

  /// Tracks currently being background-cached to avoid duplicate downloads
  final Set<String> _backgroundCacheInProgress = {};

  /// Rotate piped instances to spread load
  int _pipedIndex = 0;

  // ---------------------------------------------------------------------------
  //  Public API
  // ---------------------------------------------------------------------------

  /// Gets audio source for a track.
  /// Primary strategy: youtube_explode_dart gets a direct YouTube URL.
  /// Fallback on mobile: Piped API proxy.
  /// media_kit/mpv can stream it directly — no download needed for playback.
  /// Background caching downloads the file for future instant playback.
  Future<String?> getAudioStreamUrl(Track track) async {
    try {
      var videoId = track.youtubeId;

      // Step 1: Resolve video ID (search YouTube if needed)
      if (videoId == null || videoId.isEmpty) {
        videoId = await _resolveVideoId(track);
      }

      if (videoId == null) {
        print(
            '[YoutubeAudioService] Could not resolve video ID for: ${track.artist} - ${track.title}');
        return null;
      }

      // Step 2: Check local file caches (instant playback from disk)
      final localPath = await _checkLocalCache(videoId);
      if (localPath != null) {
        print('[YoutubeAudioService] Playing from local cache: $localPath');
        return localPath;
      }

      // Step 3: Get a playable URL via Rust Core (Ultra Performance)
      print('[YoutubeAudioService] Resolving stream via Rust Core for $videoId...');
      final rustUrl = await rust_simple.resolveYoutubeStream(videoId: videoId);
      
      if (rustUrl != null) {
        print('[YoutubeAudioService] Rust Core resolved URL successfully');
        _triggerBackgroundCache(videoId);
        return rustUrl;
      }

      print('[YoutubeAudioService] Rust Core failed, falling back to legacy strategies...');
      
      final isMobile = Platform.isAndroid || Platform.isIOS;
      if (isMobile) {
        return await _getMobileStreamUrl(videoId);
      } else {
        return await _getDesktopStreamUrl(videoId);
      }
    } catch (e) {
      print('[YoutubeAudioService] Failed to get audio stream: $e');
      return null;
    }
  }

  /// Mobile strategy: VPS proxy -> Piped -> yt-explode fallback
  /// Mobile strategy: VPS proxy -> Piped -> yt-explode fallback
  Future<String?> _getMobileStreamUrl(String videoId) async {
    // Attempt 1: Our own VPS Proxy (Fastest & most reliable)
    print('[YoutubeAudioService] [mobile] Trying custom VPS proxy...');
    final vpsUrl = 'http://144.31.26.207:3001/api/stream/$videoId';
    try {
      final request = await _httpClient
          .getUrl(Uri.parse(vpsUrl))
          .timeout(const Duration(seconds: 5));
      final response = await request.close();
      // Even if it returns 400 or other, if it's reachable, it's alive.
      // But 200 is best. Our server returns 200/206 for audio.
      if (response.statusCode < 500) {
        print(
            '[YoutubeAudioService] [mobile] VPS proxy is reachable and responsive');
        return vpsUrl;
      }
    } catch (_) {
      print(
          '[YoutubeAudioService] [mobile] VPS proxy unreachable via GET, skipping...');
    }

    // Attempt 2: Piped API fallback
    print('[YoutubeAudioService] [mobile] Trying Piped API...');
    final pipedUrl = await _getUrlViaPiped(videoId);
    if (pipedUrl != null) return pipedUrl;

    // Attempt 3: Invidious API
    print('[YoutubeAudioService] [mobile] Trying Invidious fallback...');
    final invUrl = await _getUrlViaInvidious(videoId);
    if (invUrl != null) return invUrl;

    // Attempt 4: youtube_explode_dart (Native but throttled/risky)
    print('[YoutubeAudioService] [mobile] Trying yt-explode native...');
    final directUrl = await _getDirectStreamUrl(videoId);
    if (directUrl != null) return directUrl;

    return null;
  }

  /// Desktop strategy: yt-explode and yt-dlp in parallel (original logic)
  Future<String?> _getDesktopStreamUrl(String videoId) async {
    final completer = Completer<String?>();
    var failCount = 0;
    final totalStrategies = _hasYtDlp() ? 2 : 1;

    void onResult(String? result, String name, {bool triggerCache = false}) {
      if (completer.isCompleted) return;
      if (result != null) {
        print('[YoutubeAudioService] [$name] got playable URL');
        if (triggerCache) {
          _triggerBackgroundCache(videoId);
        }
        completer.complete(result);
      } else {
        failCount++;
        print(
            '[YoutubeAudioService] [$name] failed ($failCount/$totalStrategies)');
        if (failCount >= totalStrategies) {
          print('[YoutubeAudioService] All strategies failed for $videoId');
          completer.complete(null);
        }
      }
    }

    // Strategy A: youtube_explode_dart
    unawaited(
      _getDirectStreamUrl(videoId)
          .timeout(const Duration(seconds: 15), onTimeout: () => null)
          .then((url) => onResult(url, 'yt-explode-url', triggerCache: true))
          .catchError((_) {
        onResult(null, 'yt-explode-url');
        return null;
      }),
    );

    // Strategy B: yt-dlp get URL
    if (_hasYtDlp()) {
      unawaited(
        _getUrlViaYtDlp(videoId)
            .timeout(const Duration(seconds: 20), onTimeout: () => null)
            .then((url) => onResult(url, 'yt-dlp-url', triggerCache: true))
            .catchError((_) {
          onResult(null, 'yt-dlp-url');
          return null;
        }),
      );
    }

    return await completer.future;
  }

  /// Prefetch/cache an upcoming track so it starts instantly.
  Future<void> prefetchTrack(Track track) async {
    try {
      var videoId = track.youtubeId;
      if (videoId == null || videoId.isEmpty) {
        videoId = await _resolveVideoId(track);
      }
      if (videoId == null) return;

      final localPath = await _checkLocalCache(videoId);
      if (localPath != null) return;

      _triggerBackgroundCache(videoId);
      print('[YoutubeAudioService] Triggered prefetch cache for $videoId');
    } catch (e) {
      // Prefetch failures are non-critical
    }
  }

  /// Public method to explicitly download a track and return the permanent local path.
  Future<String?> downloadTrackToPermanent(Track track) async {
    try {
      var videoId = track.youtubeId;

      if (videoId == null || videoId.isEmpty) {
        print(
            '[YoutubeAudioService] downloadTrackToPermanent: Searching for: ${track.artist} - ${track.title}');
        videoId = await _resolveVideoId(track);
      }

      if (videoId == null) throw Exception('Трек не найден на YouTube');

      final docsDir = await getApplicationDocumentsDirectory();
      final musicDir = Directory('${docsDir.path}/spectrum_music');
      if (!await musicDir.exists()) {
        await musicDir.create(recursive: true);
      }

      // Check if already downloaded
      final existing = await _findDownloadedFile(musicDir, videoId);
      if (existing != null && await existing.length() > 0) {
        return existing.path;
      }

      // 1. Try yt-dlp first (most reliable for downloading on desktop)
      final ytDlpPath = await _downloadWithYtDlp(videoId, musicDir);
      if (ytDlpPath != null) return ytDlpPath;

      // 2. Свой VPS сервер yt-dlp (Супербыстрый приватный прокси)
      _log.i('[download] Attempting custom VPS yt-dlp private proxy...');
      try {
        final serverUrl = 'http://144.31.26.207:3001/api/stream/$videoId';
        final path = await _downloadUrlToCache(videoId, serverUrl, musicDir,
            userAgent: 'Spectrum/1.0 (Mobile)');
        if (path != null) {
          _log.i('[download] Downloaded successfully via custom VPS proxy!');
          return path;
        }
      } catch (e) {
        _log.w('[download] Custom VPS proxy failed (likely 403/429): $e');
        // If the VPS says no, don't waste time, go for SoundCloud if possible
        if (e.toString().contains('403') || e.toString().contains('429')) {
          print(
              '[YoutubeAudioService] Throttling detected! Attempting SoundCloud fallback immediately...');
          final scService = SoundCloudService();
          return await scService.downloadTrackToPermanent(track);
        }
      }

      // 3. Fallback: get URL from yt-explode and download with HttpClient
      final downloadPath = await _downloadWithHttpClient(videoId, musicDir);
      if (downloadPath != null) return downloadPath;

      // 4. Last resort on mobile: try Piped URL + HttpClient download
      if (Platform.isAndroid || Platform.isIOS) {
        final pipedPath = await _downloadViaPiped(videoId, musicDir);
        if (pipedPath != null) return pipedPath;
      }

      throw Exception(
          'Сервер загрузки недоступен. Попробуйте включить VPN или SoundCloud.');
    } catch (e) {
      print('[YoutubeAudioService] downloadTrackToPermanent failed: $e');
      rethrow;
    }
  }

  /// Explicitly download to temporary cache and return the local path.
  Future<String?> downloadToCache(Track track) async {
    try {
      var videoId = track.youtubeId;

      if (videoId == null || videoId.isEmpty) {
        videoId = await _resolveVideoId(track);
      }

      if (videoId == null) throw Exception('Трек не найден на YouTube');

      // Ensure download directory
      final cacheDir = await _ensureCacheDir();

      // Check if already downloaded
      final existing = await _checkLocalCache(videoId);
      if (existing != null) return existing;

      // 0. Desktop yt-dlp (most reliable for Linux/Windows/Mac)
      if (Platform.isLinux || Platform.isWindows || Platform.isMacOS) {
        try {
          _log.i('[desktop] Attempting yt-dlp download for cache...');
          final ytDlpPath = await _downloadWithYtDlp(videoId, cacheDir);
          if (ytDlpPath != null) return ytDlpPath;
        } catch (e) {
          _log.w('[desktop] yt-dlp failed: $e');
        }
      }

      // 1. VPS Proxy (Super fast, bypasses throttling)
      try {
        final serverUrl = 'http://144.31.26.207:3001/api/stream/$videoId';
        _log.i('[cache] Trying VPS private proxy for $videoId');
        final path = await _downloadUrlToCache(videoId, serverUrl, cacheDir,
            userAgent: 'Spectrum/1.0 (Mobile)');
        if (path != null) return path;
      } catch (e) {
        _log.w('VPS proxy download failed: $e');
      }

      // 2. Fallback B: get URL from Piped (Proxy-able stream URLs)
      _log.i('[cache] Trying Piped fallback for $videoId');
      try {
        final pipedUrl = await _getUrlViaPiped(videoId);
        if (pipedUrl != null) {
          final path = await _downloadUrlToCache(videoId, pipedUrl, cacheDir);
          if (path != null) return path;
        }
      } catch (e) {
        _log.w('[cache] Piped fallback failed: $e');
      }

      // 3. Fallback C: get URL from Innertube API
      _log.i('[mobile] Getting playable URL via Innertube API...');
      try {
        final fallbackResult = await _getUrlViaInnertube(videoId);
        if (fallbackResult != null) {
          final path = await _downloadUrlToCache(
              videoId, fallbackResult['url']!, cacheDir,
              userAgent: fallbackResult['userAgent']);
          if (path != null) return path;
        }
      } catch (e) {
        _log.w('[mobile] Innertube API failed: $e');
      }

      // 4. HAIL MARY: If YouTube is totally dead, try SoundCloud!
      _log.i('[last-resort] Youtube blocked! Trying SoundCloud hail mary...');
      try {
        final scService = SoundCloudService();
        final scPath = await scService.downloadToCache(track);
        if (scPath != null) {
          _log.i('[last-resort] SoundCloud saved the day!');
          return scPath;
        }
      } catch (e) {
        _log.w('[last-resort] SoundCloud fallback also failed: $e');
      }

      throw Exception(
          'Не удалось загрузить трек: YouTube и SoundCloud заблокированы. Проверьте подключение к VPS.');
    } catch (e) {
      _log.e('downloadToCache failed: $e');
      rethrow;
    }
  }

  /// Helper to map an arbitrary extracted URL to a local file
  Future<String?> _downloadUrlToCache(
      String videoId, String url, Directory targetDir,
      {String? userAgent}) async {
    try {
      final finalFile = File('${targetDir.path}/$videoId.m4a');
      
      if (await finalFile.exists()) await finalFile.delete();

      _log.i('[rust-cache] Downloading $videoId via Rust core...');
      await rust_cache.downloadTo(url: url, path: finalFile.path);

      if (await finalFile.exists() && await finalFile.length() > 0) {
        final len = await finalFile.length();
        _log.i('[rust-cache] Complete: ${finalFile.path} ($len bytes)');
        if (len < 50000) {
          await finalFile.delete();
          return null;
        }
        return finalFile.path;
      }
      return null;
    } catch (e) {
      _log.w('[rust-cache] Download failed: $e');
      return null;
    }
  }

  // ---------------------------------------------------------------------------
  //  Video ID resolution
  // ---------------------------------------------------------------------------

  /// Search YouTube for the videoId and cache it in Isar.
  Future<String?> _resolveVideoId(Track track) async {
    if (track.title.trim().isEmpty && track.artist.trim().isEmpty) {
      print('[YoutubeAudioService] Cannot search: empty metadata');
      return null;
    }

    final query = '${track.artist} - ${track.title}';
    final isar = IsarService.instance;

    // Layer 0: Local Search Cache
    final cachedResults = await isar.youtubeSearchCaches
        .filter()
        .queryEqualTo(query)
        .findAll();
    final cached = cachedResults.isNotEmpty ? cachedResults.first : null;
    if (cached != null) {
      print('[YoutubeAudioService] [cache-hit] Found videoId for query: $query');
      return cached.videoId;
    }

    print('[YoutubeAudioService] Searching for: $query');

    try {
      final searchResults =
          await _yt.search('$query audio').timeout(const Duration(seconds: 10));

      if (searchResults.isNotEmpty) {
        // Scoring Logic
        var bestScore = -999;
        String? bestId;

        for (final video in searchResults.take(5)) {
          var score = 0;
          final title = video.title.toLowerCase();
          final artist = video.author.toLowerCase();
          final qLower = query.toLowerCase();
          final trackArtist = track.artist.toLowerCase();

          // Penalize remixes/edits
          final penalties = ["remix", "edit", "sped up", "speed up", "slowed", "reverb", "cover", "bootleg", "nightcore"];
          for (final p in penalties) {
            if (title.contains(p) && !qLower.contains(p)) {
              score -= 100;
            }
          }

          // Boost if artist matches author
          if (title.contains(trackArtist) || artist.contains(trackArtist)) {
            score += 50;
          }

          if (score > bestScore) {
            bestScore = score;
            bestId = video.id.value;
          }
        }

        if (bestId != null) {
          print('[YoutubeAudioService] Best match found (score $bestScore): $bestId');
          
          await isar.writeTxn(() async {
            // Save to track
            track.youtubeId = bestId;
            await isar.tracks.put(track);

            // Save to search cache
            final entry = YoutubeSearchCache()
              ..query = query
              ..videoId = bestId!
              ..createdAt = DateTime.now();
            await isar.youtubeSearchCaches.put(entry);
          });
          return bestId;
        }
      }
    } on TimeoutException {
      print('[YoutubeAudioService] YouTube search timed out');
    } catch (e) {
      print('[YoutubeAudioService] YouTube search error: $e');
    }

    // Fallback: search via Piped API
    if (Platform.isAndroid || Platform.isIOS) {
      try {
        final videoId = await _searchViaPiped(query);
        if (videoId != null) {
          print('[YoutubeAudioService] [piped-search] Found videoId: $videoId');
          final isar = IsarService.instance;
          await isar.writeTxn(() async {
            track.youtubeId = videoId;
            await isar.tracks.put(track);
          });
          return videoId;
        }
      } catch (e) {
        print('[YoutubeAudioService] Piped search fallback failed: $e');
      }
    }

    return null;
  }

  // ---------------------------------------------------------------------------
  //  Strategy 1: youtube_explode_dart — direct URL (no download, instant)
  // ---------------------------------------------------------------------------

  Future<String?> _getDirectStreamUrl(String videoId) async {
    try {
      print(
          '[YoutubeAudioService] [yt-explode] Getting stream manifest for $videoId...');
      final manifest = await _yt.videos.streamsClient
          .getManifest(videoId)
          .timeout(const Duration(seconds: 12));

      final audioOnly = manifest.audioOnly.toList()
        ..sort((a, b) =>
            a.bitrate.bitsPerSecond.compareTo(b.bitrate.bitsPerSecond));

      if (audioOnly.isEmpty) {
        print('[YoutubeAudioService] [yt-explode] No audio streams available');
        return null;
      }

      // Pick best quality stream ≥128kbps, fallback to highest available
      final preferred = audioOnly.firstWhere(
        (stream) => stream.bitrate.bitsPerSecond >= 128000,
        orElse: () => audioOnly.last,
      );

      final url = preferred.url.toString();
      print('[YoutubeAudioService] [yt-explode] Got ${preferred.codec} '
          '${(preferred.bitrate.bitsPerSecond / 1000).toInt()}kbps stream URL');
      return url;
    } catch (e) {
      print('[YoutubeAudioService] [yt-explode] Failed to get stream URL: $e');
      // If the YoutubeExplode instance is stale (e.g. cipher cache), recreate it
      _yt.close();
      _yt = YoutubeExplode();
      return null;
    }
  }

  // ---------------------------------------------------------------------------
  //  Strategy 2: yt-dlp — get stream URL (desktop fallback, no download)
  // ---------------------------------------------------------------------------

  Future<String?> _getUrlViaYtDlp(String videoId) async {
    final ytDlpPath = _findYtDlp();
    if (ytDlpPath == null) return null;

    try {
      print(
          '[YoutubeAudioService] [yt-dlp] Getting stream URL for $videoId...');
      final result = await Process.run(ytDlpPath, [
        '--no-playlist',
        '--no-warnings',
        '--format',
        'bestaudio/best',
        '--get-url',
        '--extractor-args',
        'youtube:player_client=android,web',
        'https://www.youtube.com/watch?v=$videoId',
      ]).timeout(const Duration(seconds: 18));

      if (result.exitCode == 0) {
        final url = (result.stdout as String).trim();
        if (url.isNotEmpty && url.startsWith('http')) {
          print('[YoutubeAudioService] [yt-dlp] Got stream URL');
          return url;
        }
      }

      final stderr = (result.stderr as String).trim();
      if (stderr.isNotEmpty) {
        print('[YoutubeAudioService] [yt-dlp] Error: $stderr');
      }
      return null;
    } catch (e) {
      print('[YoutubeAudioService] [yt-dlp] Failed: $e');
      return null;
    }
  }
  // ---------------------------------------------------------------------------
  //  Strategy 2.5: YouTube innertube API — direct YouTube API (most reliable)
  // ---------------------------------------------------------------------------

  /// Get audio stream URL via YouTube's internal innertube API.
  Future<Map<String, String>?> _getUrlViaInnertube(String videoId) async {
    // Try multiple client types in order of reliability
    final clients = [
      {
        'clientName': 'ANDROID_MUSIC',
        'clientVersion': '7.27.52',
        'ua':
            'com.google.android.apps.youtube.music/7.27.52 (Linux; U; Android 11) gzip',
        'apiKey': 'AIzaSyAO_FJ2SlqU8Q4STEHLGCilw_Y9_11qcW8',
      },
      {
        'clientName': 'WEB_REMIX',
        'clientVersion': '1.20230508.01.00',
        'ua':
            'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/113.0.0.0 Safari/537.36',
        'apiKey': 'AIzaSyA8eiZmM1FaDVjRy-df2KTyQ_vz_yYM39w',
      },
      {
        'clientName': 'ANDROID',
        'clientVersion': '19.09.37',
        'ua': 'com.google.android.youtube/19.09.37 (Linux; U; Android 11) gzip',
        'apiKey': 'AIzaSyA8eiZmM1FaDVjRy-df2KTyQ_vz_yYM39w',
      },
    ];

    for (final client in clients) {
      try {
        print(
            '[YoutubeAudioService] [innertube] Trying ${client['clientName']} for $videoId...');
        final request = await _httpClient
            .postUrl(
              Uri.parse(
                  'https://www.youtube.com/youtubei/v1/player?key=${client['apiKey']}&prettyPrint=false'),
            )
            .timeout(const Duration(seconds: 8));

        request.headers.set('User-Agent', client['ua']!);
        request.headers.set('Content-Type', 'application/json');

        final body = json.encode({
          'videoId': videoId,
          'context': {
            'client': {
              'clientName': client['clientName'],
              'clientVersion': client['clientVersion'],
              'androidSdkVersion': 30,
              'hl': 'en',
              'gl': 'US',
            }
          }
        });

        request.write(body);
        final response =
            await request.close().timeout(const Duration(seconds: 10));

        if (response.statusCode != 200) {
          print(
              '[YoutubeAudioService] [innertube] ${client['clientName']} returned ${response.statusCode}');
          await response.drain<void>();
          continue;
        }

        final responseBody = await response
            .transform(utf8.decoder)
            .join()
            .timeout(const Duration(seconds: 8));
        final data = json.decode(responseBody);

        // Check for playability errors
        final status = data['playabilityStatus']?['status'];
        if (status != 'OK') {
          print(
              '[YoutubeAudioService] [innertube] ${client['clientName']} status: $status');
          continue;
        }

        final formats = data['streamingData']?['adaptiveFormats'] as List?;
        if (formats == null || formats.isEmpty) {
          print('[YoutubeAudioService] [innertube] No adaptive formats');
          continue;
        }

        // Find audio-only streams, prefer m4a/mp4
        final audioFormats = formats
            .where((f) =>
                (f['mimeType'] as String?)?.startsWith('audio/') ?? false)
            .toList();

        if (audioFormats.isEmpty) continue;

        // Sort: prefer audio/mp4 (AAC), then by bitrate desc
        audioFormats.sort((a, b) {
          final aMime = a['mimeType'] as String? ?? '';
          final bMime = b['mimeType'] as String? ?? '';
          final aIsMp4 = aMime.contains('audio/mp4') ? 1 : 0;
          final bIsMp4 = bMime.contains('audio/mp4') ? 1 : 0;
          if (aIsMp4 != bIsMp4) return bIsMp4.compareTo(aIsMp4);
          final aBr = a['bitrate'] as int? ?? 0;
          final bBr = b['bitrate'] as int? ?? 0;
          return bBr.compareTo(aBr);
        });

        final best = audioFormats.first;
        final url = best['url'] as String?;
        if (url != null && url.isNotEmpty) {
          final bitrate = best['bitrate'] as int? ?? 0;
          final mime = best['mimeType'] ?? 'unknown';
          print(
              '[YoutubeAudioService] [innertube] Got ${client['clientName']} stream: ${bitrate ~/ 1000}kbps $mime');
          return {'url': url, 'userAgent': client['ua']!};
        }
      } catch (e) {
        print(
            '[YoutubeAudioService] [innertube] ${client['clientName']} failed: $e');
      }
    }
    return null;
  }

  // ---------------------------------------------------------------------------
  //  Strategy 4: Invidious API — another proxy-based fallback
  // ---------------------------------------------------------------------------

  static const _invidiousInstances = [
    'https://inv.nadeko.net',
    'https://invidious.nerdvpn.de',
    'https://invidious.privacyredirect.com',
    'https://iv.datura.network',
  ];

  Future<String?> _getUrlViaInvidious(String videoId) async {
    for (var i = 0; i < _invidiousInstances.length; i++) {
      final instance = _invidiousInstances[i];
      try {
        print(
            '[YoutubeAudioService] [invidious] Trying $instance for $videoId...');
        final uri = Uri.parse(
            '$instance/api/v1/videos/$videoId?fields=adaptiveFormats');
        final request =
            await _httpClient.getUrl(uri).timeout(const Duration(seconds: 8));
        request.headers.set('User-Agent', 'Spectrum/1.0');
        final response =
            await request.close().timeout(const Duration(seconds: 8));

        if (response.statusCode != 200) {
          print(
              '[YoutubeAudioService] [invidious] $instance returned ${response.statusCode}');
          await response.drain<void>();
          continue;
        }

        final body = await response
            .transform(utf8.decoder)
            .join()
            .timeout(const Duration(seconds: 8));
        final data = json.decode(body);

        final formats = data['adaptiveFormats'] as List?;
        if (formats == null || formats.isEmpty) continue;

        // Find audio streams, prefer mp4/m4a
        final audioFormats = formats
            .where((f) => (f['type'] as String?)?.startsWith('audio/') ?? false)
            .toList();
        if (audioFormats.isEmpty) continue;

        audioFormats.sort((a, b) {
          final aType = a['type'] as String? ?? '';
          final bType = b['type'] as String? ?? '';
          final aIsMp4 = aType.contains('mp4') ? 1 : 0;
          final bIsMp4 = bType.contains('mp4') ? 1 : 0;
          if (aIsMp4 != bIsMp4) return bIsMp4.compareTo(aIsMp4);
          final aBr = (a['bitrate'] as String? ?? '0');
          final bBr = (b['bitrate'] as String? ?? '0');
          return (int.tryParse(bBr) ?? 0).compareTo(int.tryParse(aBr) ?? 0);
        });

        final url = audioFormats.first['url'] as String?;
        if (url != null && url.isNotEmpty) {
          final bitrate = audioFormats.first['bitrate'] ?? 'unknown';
          print('[YoutubeAudioService] [invidious] Got stream: ${bitrate}bps');
          return url;
        }
      } catch (e) {
        print('[YoutubeAudioService] [invidious] $instance failed: $e');
      }
    }
    return null;
  }

  // ---------------------------------------------------------------------------
  //  Strategy 5: Piped API — proxy-based URL extraction (mobile fallback)
  // ---------------------------------------------------------------------------

  /// Search for a video via Piped API
  Future<String?> _searchViaPiped(String query) async {
    for (var attempt = 0; attempt < 3; attempt++) {
      final instance =
          _pipedInstances[(_pipedIndex + attempt) % _pipedInstances.length];
      try {
        final uri = Uri.parse('$instance/search')
            .replace(queryParameters: {'q': query, 'filter': 'music_songs'});

        final request =
            await _httpClient.getUrl(uri).timeout(const Duration(seconds: 6));
        request.headers.set('User-Agent', 'Spectrum/1.0');
        final response =
            await request.close().timeout(const Duration(seconds: 6));

        if (response.statusCode != 200) {
          await response.drain<void>();
          continue;
        }

        final body = await response
            .transform(utf8.decoder)
            .join()
            .timeout(const Duration(seconds: 6));
        final data = json.decode(body);
        final items = data['items'] as List?;
        if (items != null && items.isNotEmpty) {
          // Items have 'url' like '/watch?v=VIDEO_ID'
          final url = items.first['url'] as String?;
          if (url != null) {
            final vidId =
                Uri.parse('https://youtube.com$url').queryParameters['v'];
            if (vidId != null && vidId.isNotEmpty) {
              _pipedIndex = (_pipedIndex + attempt) % _pipedInstances.length;
              return vidId;
            }
          }
        }
      } catch (e) {
        print(
            '[YoutubeAudioService] [piped-search] Instance $instance failed: $e');
      }
    }
    return null;
  }

  /// Get a stream URL via Piped API (bypasses YouTube's cipher/throttling)
  Future<String?> _getUrlViaPiped(String videoId) async {
    for (var attempt = 0; attempt < _pipedInstances.length; attempt++) {
      final instance =
          _pipedInstances[(_pipedIndex + attempt) % _pipedInstances.length];
      try {
        print('[YoutubeAudioService] [piped] Trying $instance for $videoId...');
        final uri = Uri.parse('$instance/streams/$videoId');

        final request =
            await _httpClient.getUrl(uri).timeout(const Duration(seconds: 8));
        request.headers.set('User-Agent', 'Spectrum/1.0');
        final response =
            await request.close().timeout(const Duration(seconds: 8));

        if (response.statusCode != 200) {
          print(
              '[YoutubeAudioService] [piped] $instance returned ${response.statusCode}');
          await response.drain<void>();
          continue;
        }

        final body = await response
            .transform(utf8.decoder)
            .join()
            .timeout(const Duration(seconds: 8));
        final data = json.decode(body);

        final audioStreams = data['audioStreams'] as List?;
        if (audioStreams == null || audioStreams.isEmpty) {
          print(
              '[YoutubeAudioService] [piped] No audio streams from $instance');
          continue;
        }

        // Sort by bitrate, pick best quality (prefer m4a/mp4 for compatibility)
        final sorted = List<Map<String, dynamic>>.from(audioStreams)
          ..sort((a, b) {
            final aBr = a['bitrate'] as int? ?? 0;
            final bBr = b['bitrate'] as int? ?? 0;
            return bBr.compareTo(aBr);
          });

        // Prefer m4a/mp4 formats for better Android compatibility
        Map<String, dynamic>? best;
        for (final stream in sorted) {
          final mimeType = stream['mimeType'] as String? ?? '';
          if (mimeType.contains('audio/mp4') ||
              mimeType.contains('audio/m4a')) {
            best = stream;
            break;
          }
        }
        // If no m4a, take the highest bitrate regardless of format
        best ??= sorted.first;

        final url = best['url'] as String?;
        if (url != null && url.isNotEmpty) {
          final bitrate = best['bitrate'] as int? ?? 0;
          final mime = best['mimeType'] ?? 'unknown';
          print(
              '[YoutubeAudioService] [piped] Got stream: ${bitrate ~/ 1000}kbps $mime');
          _pipedIndex = (_pipedIndex + attempt) % _pipedInstances.length;
          return url;
        }
      } catch (e) {
        print('[YoutubeAudioService] [piped] $instance failed: $e');
      }
    }

    print('[YoutubeAudioService] [piped] All instances failed');
    return null;
  }

  /// Download audio via Piped-provided URL
  Future<String?> _downloadViaPiped(String videoId, Directory targetDir) async {
    try {
      final url = await _getUrlViaPiped(videoId);
      if (url == null) return null;

      print('[YoutubeAudioService] [piped-download] Downloading $videoId...');
      final partFile = File('${targetDir.path}/$videoId.part');
      final finalFile = File('${targetDir.path}/$videoId.m4a');

      if (await partFile.exists()) await partFile.delete();
      if (await finalFile.exists()) await finalFile.delete();

      final request = await _httpClient
          .getUrl(Uri.parse(url))
          .timeout(const Duration(seconds: 8));
      request.headers.set('User-Agent', 'Spectrum/1.0');
      final response =
          await request.close().timeout(const Duration(seconds: 10));

      if (response.statusCode != 200) {
        print(
            '[YoutubeAudioService] [piped-download] Server returned ${response.statusCode}');
        await response.drain<void>();
        return null;
      }

      final sink = partFile.openWrite();
      try {
        await response.pipe(sink).timeout(const Duration(seconds: 120));
      } finally {
        await sink.flush();
        await sink.close();
      }

      if (await partFile.exists() && await partFile.length() > 0) {
        await partFile.rename(finalFile.path);
        print(
            '[YoutubeAudioService] [piped-download] Complete: ${finalFile.path} (${await finalFile.length()} bytes)');
        return finalFile.path;
      }
      return null;
    } catch (e) {
      print('[YoutubeAudioService] [piped-download] Failed: $e');
      return null;
    }
  }

  // ---------------------------------------------------------------------------
  //  Download strategies (for caching / offline)
  // ---------------------------------------------------------------------------

  /// Download via yt-dlp (most reliable when available)
  Future<String?> _downloadWithYtDlp(
      String videoId, Directory targetDir) async {
    final ytDlpPath = _findYtDlp();
    if (ytDlpPath == null) return null;

    try {
      if (!await targetDir.exists()) {
        await targetDir.create(recursive: true);
      }

      final existing = await _findDownloadedFile(targetDir, videoId);
      if (existing != null && await existing.length() > 0) {
        return existing.path;
      }

      final outputTemplate = '${targetDir.path}/$videoId.%(ext)s';
      print(
          '[YoutubeAudioService] [yt-dlp] Downloading $videoId to ${targetDir.path}...');

      final process = await Process.start(ytDlpPath, [
        '--no-playlist',
        '--no-progress',
        '--no-warnings',
        '--force-overwrites',
        '--format',
        'bestaudio/best',
        '--extractor-args',
        'youtube:player_client=android,web',
        '--output',
        outputTemplate,
        'https://www.youtube.com/watch?v=$videoId',
      ]);

      final stdoutFuture = process.stdout.transform(utf8.decoder).join();
      final stderrFuture = process.stderr.transform(utf8.decoder).join();
      final exitCode = await process.exitCode.timeout(
        const Duration(seconds: 60),
        onTimeout: () {
          process.kill(ProcessSignal.sigkill);
          return -1;
        },
      );

      await stdoutFuture;
      final stderr = await stderrFuture;

      if (exitCode == 0) {
        final downloaded = await _findDownloadedFile(targetDir, videoId);
        if (downloaded != null && await downloaded.length() > 0) {
          print(
              '[YoutubeAudioService] [yt-dlp] Download complete: ${downloaded.path}');
          return downloaded.path;
        }
      }

      if (stderr.trim().isNotEmpty) {
        print('[YoutubeAudioService] [yt-dlp] stderr: ${stderr.trim()}');
      }
      return null;
    } catch (e) {
      print('[YoutubeAudioService] [yt-dlp] Download failed: $e');
      return null;
    }
  }

  /// Download audio using a direct URL obtained from youtube_explode, via Dart HttpClient.
  Future<String?> _downloadWithHttpClient(
      String videoId, Directory targetDir) async {
    try {
      // First get the URL
      final url = await _getDirectStreamUrl(videoId);
      if (url == null) return null;

      print('[YoutubeAudioService] [http-download] Downloading $videoId...');
      final partFile = File('${targetDir.path}/$videoId.part');
      final finalFile = File('${targetDir.path}/$videoId.m4a');

      if (await partFile.exists()) await partFile.delete();
      if (await finalFile.exists()) await finalFile.delete();

      final request = await _httpClient
          .getUrl(Uri.parse(url))
          .timeout(const Duration(seconds: 8));
      request.headers.set('User-Agent',
          'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/122.0.0.0 Safari/537.36');
      request.headers.set('Referer', 'https://www.youtube.com/');
      final response =
          await request.close().timeout(const Duration(seconds: 10));

      if (response.statusCode != 200) {
        print(
            '[YoutubeAudioService] [http-download] Server returned ${response.statusCode}');
        await response.drain<void>();
        return null;
      }

      final sink = partFile.openWrite();
      try {
        await response.pipe(sink).timeout(const Duration(seconds: 60));
      } finally {
        await sink.flush();
        await sink.close();
      }

      if (await partFile.exists() && await partFile.length() > 0) {
        await partFile.rename(finalFile.path);
        print(
            '[YoutubeAudioService] [http-download] Complete: ${finalFile.path} (${await finalFile.length()} bytes)');
        return finalFile.path;
      }
      return null;
    } catch (e) {
      print('[YoutubeAudioService] [http-download] Failed: $e');
      return null;
    }
  }

  // ---------------------------------------------------------------------------
  //  yt-dlp detection
  // ---------------------------------------------------------------------------

  String? _findYtDlp() {
    // yt-dlp is desktop-only (Linux/Windows/macOS)
    if (Platform.isAndroid || Platform.isIOS) return null;

    final paths = Platform.isWindows ? _ytDlpPathsWindows : _ytDlpPathsLinux;
    for (final path in paths) {
      if (File(path).existsSync()) return path;
    }
    // Also check PATH
    try {
      final whichCmd = Platform.isWindows ? 'where' : 'which';
      final result = Process.runSync(whichCmd, ['yt-dlp']);
      if (result.exitCode == 0) {
        final path = (result.stdout as String).trim().split('\n').first;
        if (path.isNotEmpty) return path;
      }
    } catch (_) {}
    return null;
  }

  bool _hasYtDlp() => _findYtDlp() != null;

  // ---------------------------------------------------------------------------
  //  Local cache management
  // ---------------------------------------------------------------------------

  Future<Directory> _ensureCacheDir() async {
    final tempDir = await getTemporaryDirectory();
    final cacheDir = Directory('${tempDir.path}/spectrum_cache');
    if (!await cacheDir.exists()) {
      await cacheDir.create(recursive: true);
    }
    return cacheDir;
  }

  /// Check permanent + temporary caches for an already downloaded file.
  Future<String?> _checkLocalCache(String videoId) async {
    // Permanent cache
    final docsDir = await getApplicationDocumentsDirectory();
    final permDir = Directory('${docsDir.path}/spectrum_music');
    if (await permDir.exists()) {
      final permFile = File('${permDir.path}/$videoId.m4a');
      if (await permFile.exists() && await permFile.length() > 0) {
        return permFile.path;
      }
      final found = await _findDownloadedFile(permDir, videoId);
      if (found != null && await found.length() > 0) {
        return found.path;
      }
    }

    // Temporary cache
    final tempDir = await getTemporaryDirectory();
    final cacheDir = Directory('${tempDir.path}/spectrum_cache');
    if (await cacheDir.exists()) {
      final tempFile = File('${cacheDir.path}/$videoId.m4a');
      if (await tempFile.exists() && await tempFile.length() > 0) {
        return tempFile.path;
      }
      final found = await _findDownloadedFile(cacheDir, videoId);
      if (found != null && await found.length() > 0) {
        return found.path;
      }
    }

    return null;
  }

  Future<File?> _findDownloadedFile(Directory dir, String videoId) async {
    try {
      final entries = await dir.list().toList();
      for (final entry in entries) {
        if (entry is! File) continue;
        final name = entry.uri.pathSegments.isNotEmpty
            ? entry.uri.pathSegments.last
            : '';
        // Skip partial downloads
        if (name.endsWith('.part') ||
            name.endsWith('.tmp') ||
            name.endsWith('.ytdl')) continue;

        if (name.startsWith('$videoId.') && await entry.length() > 0) {
          return entry;
        }
      }
    } catch (e) {
      print('[YoutubeAudioService] Error scanning directory: $e');
    }
    return null;
  }

  // ---------------------------------------------------------------------------
  //  Background caching
  // ---------------------------------------------------------------------------

  Future<List<Track>> getRelatedTracks(Track originalTrack) async {
    final videoId = originalTrack.youtubeId;
    if (videoId == null || videoId.isEmpty) return [];

    try {
      print('[YoutubeAudioService] Fetching related tracks for: $videoId');
      // getRelatedVideos needs a Video object, not just ID
      final video = await _yt.videos.get(VideoId(videoId));
      final related = await _yt.videos.getRelatedVideos(video);
      if (related == null) return [];

      final List<Track> tracks = related.map((v) {
        final t = Track();
        t.title = v.title;
        t.artist = v.author;
        t.youtubeId = v.id.value;
        t.durationMs = v.duration?.inMilliseconds ?? 0;
        t.albumArtUrl = v.thumbnails.standardResUrl;
        return t;
      }).toList();
      
      return tracks;
    } catch (e) {
      print('[YoutubeAudioService] getRelatedTracks failed: $e');
      return [];
    }
  }

  void _triggerBackgroundCache(String videoId) {
    if (_backgroundCacheInProgress.contains(videoId)) return;
    _backgroundCacheInProgress.add(videoId);

    unawaited(_runBackgroundCache(videoId).whenComplete(() {
      _backgroundCacheInProgress.remove(videoId);
    }));
  }

  Future<void> _runBackgroundCache(String videoId) async {
    try {
      final existing = await _checkLocalCache(videoId);
      if (existing != null) return;

      final cacheDir = await _ensureCacheDir();

      // Prefer yt-dlp for download (most reliable)
      final ytDlpResult = await _downloadWithYtDlp(videoId, cacheDir);
      if (ytDlpResult != null) return;

      // Fallback: download via HttpClient with yt-explode URL
      final httpResult = await _downloadWithHttpClient(videoId, cacheDir);
      if (httpResult != null) return;

      // Last resort: download via Piped
      if (Platform.isAndroid || Platform.isIOS) {
        await _downloadViaPiped(videoId, cacheDir);
      }
    } catch (e) {
      _log.e('Background cache failed: $e');
    }
  }

  void dispose() {
    _yt.close();
    _httpClient.close();
  }
}
