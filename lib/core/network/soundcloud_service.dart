import 'dart:io';
import 'package:dio/dio.dart';
import 'package:spectrum/src/rust/api/simple.dart';
import 'package:spectrum/core/db/schemas/track_schema.dart';
import 'package:path_provider/path_provider.dart';

class SoundCloudService {
  final Dio _dio = Dio();
  String? _clientId;

  Future<String?> _getClientId() async {
    if (_clientId != null) return _clientId;

    try {
      // Try to get a fresh client_id from soundcloud.com
      final response = await _dio
          .get(
            'https://soundcloud.com/',
            options: Options(
              sendTimeout: const Duration(seconds: 5),
              receiveTimeout: const Duration(seconds: 5),
            ),
          )
          .timeout(const Duration(seconds: 7));

      final matches = RegExp(r'src="([^"]+/app-[^"]+\.js)"')
          .allMatches(response.data as String);

      for (final m in matches) {
        final jsUrl = m.group(1);
        if (jsUrl == null) continue;

        try {
          final jsResponse = await _dio
              .get(
                jsUrl,
                options: Options(
                  sendTimeout: const Duration(seconds: 3),
                  receiveTimeout: const Duration(seconds: 5),
                ),
              )
              .timeout(const Duration(seconds: 6));

          final clientIdMatch = RegExp(r'client_id:"([a-zA-Z0-9]{32})"')
              .firstMatch(jsResponse.data as String);
          if (clientIdMatch != null) {
            _clientId = clientIdMatch.group(1);
            print('[SoundCloudService] Extracted client_id: $_clientId');
            return _clientId;
          }
        } catch (_) {}
      }
    } catch (e) {
      print('[SoundCloudService] Failed to extract client_id: $e');
    }

    // Last resort fallback — slightly newer ID
    return 'tkIWLs4MIowq7bCXP80TOwx6DnDa7UPc';
  }

  Future<String?> _resolveViaRust(String query, {int? expectedDurationMs}) async {
    print('[SoundCloudService] Resolving via Rust Core: $query');
    return await resolveSoundcloudStream(
      query: query, 
      expectedDurationMs: expectedDurationMs
    );
  }

  Future<String?> searchTrack(String query, {int? expectedDurationMs}) async {
    return await _resolveViaRust(query, expectedDurationMs: expectedDurationMs);
  }

  Future<String?> getStreamUrl(String urlApiUrl) async {
    // Rust handles the full resolution now, so this is just a fallback wrapper
    return null; 
  }

  Future<String?> downloadToCache(Track track) async {
    try {
      final query = '${track.artist} ${track.title}';
      print('[SoundCloudService] Searching SC for: $query');

      var mediaApiUrl =
          await searchTrack(query, expectedDurationMs: track.durationMs);

      if (mediaApiUrl == null) {
        print(
            '[SoundCloudService] Initial search (Artist + Title) failed. Attempting Track-Only fallback...');
        mediaApiUrl = await searchTrack(track.title,
            expectedDurationMs: track.durationMs);
      }

      if (mediaApiUrl == null) {
        // Even broader try: strip common problematic characters like & and /
        final cleanedTitle =
            track.title.replaceAll('&', ' ').replaceAll('/', ' ');
        print(
            '[SoundCloudService] Secondary search failed. Trying Cleaned-Title fallback: $cleanedTitle');
        mediaApiUrl = await searchTrack(cleanedTitle,
            expectedDurationMs: track.durationMs);
      }

      if (mediaApiUrl == null) {
        throw Exception(
            'Трек не найден на SoundCloud. Попробуйте сменить источник на YouTube в настройках.');
      }

      print(
          '[SoundCloudService] Found track stream URL via Rust Core');
      final streamUrl = mediaApiUrl; // Rust already returns the final stream URL

      // If the URL contains "m3u8", it's a playlist, not a binary file!
      if (streamUrl.contains('m3u8')) {
        throw Exception(
            'SoundCloud вернул HLS-плейлист вместо файла. Загрузка невозможна.');
      }

      final cacheDir = await _ensureCacheDir();
      // Ensure the directory is actually there right now (sometimes /tmp is volatile)
      if (!await cacheDir.exists()) await cacheDir.create(recursive: true);

      final partFile = File('${cacheDir.path}/${track.id}.part');
      final finalFile = File('${cacheDir.path}/${track.id}.mp3');

      if (await partFile.exists()) await partFile.delete();
      if (await finalFile.exists()) await finalFile.delete();

      print('[SoundCloudService] Downloading binary from $streamUrl');
      final response = await _dio.download(
        streamUrl,
        partFile.path,
        options: Options(
          headers: {
            'User-Agent':
                'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36'
          },
        ),
      );

      if (response.statusCode == 200 || response.statusCode == 206) {
        // Validation Layer: Size + Magic Bytes
        final length = await partFile.length();
        if (length < 100 * 1024) {
          await partFile.delete();
          throw Exception('Скачанный файл слишком мал ($length байт).');
        }

        // DEEP CHECK: Verify magic bytes (ID3 header or MPEG sync)
        final raf = await partFile.open();
        final head = await raf.read(10);
        await raf.close();

        final isMp3 =
            (head[0] == 0x49 && head[1] == 0x44 && head[2] == 0x33) || // ID3
                (head[0] == 0xFF && (head[1] & 0xE0) == 0xE0); // MPEG Sync

        if (!isMp3) {
          final contentPreview =
              String.fromCharCodes(head.where((b) => b >= 32 && b <= 126));
          await partFile.delete();
          throw Exception(
              'Полученные данные не являются аудио-потоком (Header: $contentPreview).');
        }

        await partFile.rename(finalFile.path);
        print(
            '[SoundCloudService] Verified & Saved MP3: ${finalFile.path} ($length bytes)');
        return finalFile.path;
      }
      return null;
    } catch (e) {
      print('[SoundCloudService] downloadToCache failed: $e');
      rethrow;
    }
  }

  Future<String?> downloadTrackToPermanent(Track track) async {
    try {
      // Re-use cache logic for simplicity and reliability
      final cachedPath = await downloadToCache(track);
      if (cachedPath == null) return null;

      final docsDir = await getApplicationDocumentsDirectory();
      final musicDir = Directory('${docsDir.path}/spectrum_music');
      if (!await musicDir.exists()) await musicDir.create(recursive: true);

      final finalFile = File('${musicDir.path}/${track.id}.mp3');
      await File(cachedPath).copy(finalFile.path);
      return finalFile.path;
    } catch (e) {
      print('[SoundCloudService] Permanent download failed: $e');
      rethrow;
    }
  }

  Future<void> prefetchTrack(Track track) async {
    try {
      await downloadToCache(track);
    } catch (_) {}
  }

  Future<Directory> _ensureCacheDir() async {
    final tempDir = await getTemporaryDirectory();
    final cacheDir = Directory('${tempDir.path}/spectrum_sc_cache');
    if (!await cacheDir.exists()) {
      await cacheDir.create(recursive: true);
    }
    return cacheDir;
  }
}
