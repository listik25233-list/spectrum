import 'dart:io';
import 'dart:async';
import 'dart:math';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:media_kit/media_kit.dart' hide Track;
import 'package:isar/isar.dart';
import 'package:spectrum/core/db/schemas/track_schema.dart';
import 'package:spectrum/core/db/isar_service.dart';
import 'package:spectrum/core/network/lyrics_api.dart';
import 'package:spectrum/core/network/youtube_service.dart';
import 'package:spectrum/core/network/soundcloud_service.dart';
import 'package:spectrum/features/player/spectrum_audio_handler.dart';
import 'package:audio_session/audio_session.dart';
import 'package:spectrum/features/settings/settings_providers.dart';
import 'package:spectrum/core/utils/mpv_helper.dart';
import 'package:path_provider/path_provider.dart';
import 'package:spectrum/src/rust/api/dsp.dart' as rust_dsp;
import 'package:spectrum/src/rust/api/cache.dart' as rust_cache;
import 'package:spectrum/src/rust/api/image_processor.dart' as rust_image;
import 'package:spectrum/src/rust/api/loudness.dart' as rust_loudness;
import 'package:spectrum/src/rust/api/simple.dart' as rust_simple;
import 'package:spectrum/features/player/dominant_color_provider.dart';
import 'package:spectrum/features/player/lyrics_provider.dart';
import 'package:spectrum/features/player/synced_lyrics_view.dart';
import 'package:spectrum/features/player/neural_radio_provider.dart';

final isDesktop = Platform.isWindows || Platform.isLinux || Platform.isMacOS;

final youtubeServiceProvider = Provider<YoutubeAudioService>((ref) {
  final service = YoutubeAudioService();
  ref.onDispose(() {
    service.dispose();
  });
  return service;
});

final soundcloudServiceProvider = Provider<SoundCloudService>((ref) {
  return SoundCloudService();
});

final lyricsApiProvider = Provider<LyricsApi>((ref) {
  return LyricsApi();
});

final audioHandlerProvider = Provider<SpectrumAudioHandler>((ref) {
  throw UnimplementedError('Initialize in main.dart');
});

final audioPlayerServiceProvider = Provider<AudioPlayerService>((ref) {
  final handler = ref.watch(audioHandlerProvider);
  return AudioPlayerService(ref, handler);
});

enum PlayerRepeatMode { off, all, one }

final currentQueueProvider = StateProvider<List<Track>>((ref) => []);
final isShufflingProvider = StateProvider<bool>((ref) => false);
final repeatModeProvider =
    StateProvider<PlayerRepeatMode>((ref) => PlayerRepeatMode.off);
final queueIndexProvider = StateProvider<int>((ref) => -1);

final currentTrackProvider = StateProvider<Track?>((ref) => null);
final isPlayingProvider = StateProvider<bool>((ref) => false);
final isLoadingStreamProvider = StateProvider<bool>((ref) => false);
final playbackPositionProvider =
    StateProvider<Duration>((ref) => Duration.zero);
final playbackDurationProvider =
    StateProvider<Duration>((ref) => Duration.zero);

final lyricsSyncOffsetMsProvider = StateProvider<int>((ref) => 0);
final recentPlayedTracksProvider = StateProvider<List<Track>>((ref) => []);
final djModeEnabledProvider = StateProvider<bool>((ref) => false);
final isAiProcessingProvider = StateProvider<bool>((ref) => false);
final isSuperResActiveProvider = StateProvider<bool>((ref) => false);
final djPromptProvider = StateProvider<String>((ref) => '');
final djHostMessagesProvider = StateProvider<List<String>>((ref) => []);
final djQueuedBlockStartIndexProvider = StateProvider<int>((ref) => -1);
final djQueuedBlockPhraseProvider = StateProvider<String?>((ref) => null);

// Error feedback provider — shown to user when playback fails
final playbackErrorProvider = StateProvider<String?>((ref) => null);
final isHostSpeakingProvider = StateProvider<bool>((ref) => false);

// Quality info providers
final audioSampleRateProvider = StateProvider<int?>((ref) => null);
final audioBitDepthProvider = StateProvider<int?>((ref) => null);
final audioFormatProvider = StateProvider<String?>((ref) => null);

class AudioPlayerService {
  late Player _playerA;
  late final Player _playerB = Player();
  final Player _voicePlayer = Player(); // Separate player for DJ host voice
  final Ref _ref;
  final SpectrumAudioHandler _handler;

  int _activePlayerIndex = 0; // 0 for A, 1 for B
  bool _isCrossfading = false;
  Timer? _fadeTimer;

  // Storing original queue to restore after shuffling
  List<Track> _originalQueue = [];
  int _playGeneration = 0;
  final Random _random = Random();
  bool _djWasShuffling = false;

  AudioPlayerService(this._ref, this._handler) {
    _playerA = _handler.player;
    _init();
    _setupAudioHandler();
    _ref.onDispose(() => dispose());

    // Listen to shuffle changes to reorder pending queue
    _ref.listen<bool>(isShufflingProvider, (prev, isShuffling) {
      if (prev == isShuffling) return;
      _handleShuffleChange(isShuffling);
    });

    // Listen to Tidal enhancement changes
    _ref.listen<bool>(tidalEnhancementProvider, (prev, isEnabled) {
      if (prev == isEnabled) return;
      _applyAudioFilters();
    });

    // Listen to volume changes (including initial load from disk)
    _ref.listen<double>(volumeProvider, (prev, vol) {
      player.setVolume(vol * 100.0);
      _voicePlayer.setVolume(vol * 100.0);
    });

    // Publish DJ phrase exactly when we enter the queued block start index.
    _ref.listen<int>(queueIndexProvider, (prev, next) {
      if (!_ref.read(djModeEnabledProvider)) return;
      final queuedStart = _ref.read(djQueuedBlockStartIndexProvider);
      final queuedPhrase = _ref.read(djQueuedBlockPhraseProvider);
      if (queuedStart >= 0 && queuedPhrase != null && next == queuedStart) {
        final msgs = List<String>.from(_ref.read(djHostMessagesProvider))
          ..add(queuedPhrase);
        _ref.read(djHostMessagesProvider.notifier).state = msgs;
        _ref.read(djQueuedBlockStartIndexProvider.notifier).state = -1;
        _ref.read(djQueuedBlockPhraseProvider.notifier).state = null;

        // Speak the phrase!
        _speak(queuedPhrase);
      }
      
      // Trigger Neural Radio check to keep the music flowing
      _ref.read(neuralRadioServiceProvider).checkAndFillQueue();
    });

    // Ensure initial volume is applied from state (which might have loaded fast)
    Future.microtask(() {
      final vol = _ref.read(volumeProvider);
      _playerA.setVolume(vol * 100.0);
      _playerB.setVolume(vol * 100.0);
      _voicePlayer.setVolume(vol * 100.0);
    });
  }

  void _setupAudioHandler() {
    SpeedCommand.onNext = () => playNext();
    SpeedCommand.onPrev = () => playPrevious();
  }

  Player get player => _activePlayerIndex == 0 ? _playerA : _playerB;
  Player get _idlePlayer => _activePlayerIndex == 0 ? _playerB : _playerA;

  void _init() {
    _initPlayerListeners(_playerA, 0);
    _initPlayerListeners(_playerB, 1);

    _voicePlayer.stream.playing.listen((playing) {
      _ref.read(isHostSpeakingProvider.notifier).state = playing;
      final baseVol = _ref.read(volumeProvider);
      if (playing) {
        // Lower music volume while DJ is speaking
        player.setVolume(baseVol * 30.0);
      } else {
        // Restore music volume
        player.setVolume(baseVol * 100.0);
      }
    });

    _applyAudioFilters(); // Initial state
    _setupAudioSession();
  }

  void _initPlayerListeners(Player p, int index) {
    p.stream.playing.listen((playing) {
      if (_activePlayerIndex == index) {
        _ref.read(isPlayingProvider.notifier).state = playing;
      }
    });

    p.stream.position.listen((position) {
      if (_activePlayerIndex == index) {
        _ref.read(playbackPositionProvider.notifier).state = position;
        _checkCrossfade(position, p.state.duration);
      }
    });

    p.stream.duration.listen((duration) {
      if (_activePlayerIndex == index) {
        _ref.read(playbackDurationProvider.notifier).state = duration;
      }
    });

    // We no longer listen to p.stream.volume because it causes the UI slider 
    // to jump wildly during automated internal volume operations like Crossfading 
    // or AI DJ ducking. The UI Provider is now the pure master source of truth.

    p.stream.completed.listen((completed) {
      if (completed &&
          !_ref.read(isLoadingStreamProvider) &&
          _activePlayerIndex == index &&
          !_isCrossfading) {
        _handleTrackCompleted();
      }
    });

    p.stream.error.listen((error) async {
      if (_activePlayerIndex != index) return;
      final errorStr = error.toString();
      print('[MediaKit-Error] $errorStr');

      // Corrupted file handling...
      if (errorStr.contains('Failed to recognize file format') ||
          errorStr.contains('Invalid data found')) {
        final track = _ref.read(currentTrackProvider);
        if (track != null && track.localPath != null) {
          try {
            final file = File(track.localPath!);
            if (await file.exists()) await file.delete();
            _ref.read(playbackErrorProvider.notifier).state =
                'Файл поврежден, путь сброшен. Попробуйте снова.';
          } catch (_) {}
        }
      }
    });

    p.stream.audioParams.listen((params) {
      if (_activePlayerIndex != index) return;
      _ref.read(audioFormatProvider.notifier).state = params.format;
      final fmt = params.format ?? '';
      int? bits;
      if (fmt.contains('s16')) {
        bits = 16;
      } else if (fmt.contains('s24'))
        bits = 24;
      else if (fmt.contains('s32') || fmt.contains('float')) bits = 32;
      _ref.read(audioBitDepthProvider.notifier).state = bits;
      _queryRealOutputParams();
    });
  }

  /// Query the real output sample rate & format from mpv via FFI
  Future<void> _queryRealOutputParams() async {
    // We now enable this on all platforms that use libmpv (Linux, Windows, macOS, Android)
    if (Platform.isIOS) return; // iOS uses a different media engine sometimes
    try {
      final h = await player.handle;
      final realSr = MpvHelper.getProperty(h, 'audio-params/samplerate');
      final realFmt = MpvHelper.getProperty(h, 'audio-out-params/format');
      final realOutSr = MpvHelper.getProperty(h, 'audio-out-params/samplerate');

      // Prefer the actual output (post-filter) sample rate
      final sr = int.tryParse(realOutSr ?? realSr ?? '');
      if (sr != null && sr > 0) {
        _ref.read(audioSampleRateProvider.notifier).state = sr;
      }

      // If output format differs, update bit depth from it
      if (realFmt != null && realFmt.isNotEmpty) {
        int? outBits;
        if (realFmt.contains('s16')) {
          outBits = 16;
        } else if (realFmt.contains('s24'))
          outBits = 24;
        else if (realFmt.contains('s32') || realFmt.contains('float'))
          outBits = 32;
        else if (realFmt.contains('dbl')) outBits = 64;
        if (outBits != null) {
          _ref.read(audioBitDepthProvider.notifier).state = outBits;
        }
      }
    } catch (e) {
      print('[AudioPlayerService] Could not query real output params: $e');
    }
  }

  Future<void> _applyAudioFilters() async {
    final isTidalEnabled = _ref.read(tidalEnhancementProvider);
    final isReplayGainEnabled = _ref.read(replayGainEnabledProvider);
    
    if (Platform.isIOS) return;

    final h = await player.handle;
    final track = _ref.read(currentTrackProvider);
    
    double gainDb = 0.0;
    if (isReplayGainEnabled && track != null && track.replayGain != null) {
      gainDb = track.replayGain!;
      print('[AudioPlayerService] Applying ReplayGain: ${gainDb.toStringAsFixed(2)}dB');
    }

    final processor = rust_dsp.AudioProcessor(
      restorationEnabled: isTidalEnabled,
      volumeDb: gainDb,
    );
    
    final filterString = await processor.generateMpvAfString();
    
    if (filterString.isNotEmpty) {
      print('[AudioPlayerService] Filter Chain: $filterString');
      MpvHelper.setProperty(h, 'audio-resample-filter-size', '32');
      MpvHelper.setProperty(h, 'af', filterString);
    } else {
      MpvHelper.setProperty(h, 'af', '');
    }
  }


  Future<void> _setupAudioSession() async {
    final session = await AudioSession.instance;
    await session.configure(const AudioSessionConfiguration.music());
  }

  void _checkCrossfade(Duration position, Duration duration) {
    if (!_ref.read(smartCrossfadeEnabledProvider)) return;
    if (_isCrossfading || duration == Duration.zero) return;

    final crossMargin = Duration(seconds: _ref.read(crossfadeDurationProvider));
    if (duration > crossMargin * 2 && duration - position < crossMargin) {
      _startCrossfade();
    }
  }

  Future<void> _startCrossfade() async {
    final queue = _ref.read(currentQueueProvider);
    var index = _ref.read(queueIndexProvider);
    if (queue.isEmpty || index + 1 >= queue.length) return;

    _isCrossfading = true;
    final nextIndex = index + 1;
    final nextTrack = queue[nextIndex];

    try {
      print('[AI DJ] Crossfading to: ${nextTrack.title}');
      final nextPlayer = _idlePlayer;

      // 1. Prepare next player silently
      final uri = await _getAudioUri(nextTrack);
      if (uri == null) {
        _isCrossfading = false;
        return;
      }

      await nextPlayer.open(Media(uri, extras: _getMediaExtras(nextTrack)),
          play: false);
      await nextPlayer.setVolume(0);
      nextPlayer.play();

      // 2. Start volume ramp
      final duration = _ref.read(crossfadeDurationProvider);
      _fadeVolumes(player, nextPlayer, duration);

      // 3. Middle-of-fade updates (UI & Notifications)
      await Future.delayed(Duration(seconds: duration ~/ 2));
      _ref.read(queueIndexProvider.notifier).state = nextIndex;
      _ref.read(currentTrackProvider.notifier).state = nextTrack;
      _handler.updateActivePlayer(nextPlayer);
      _handler.updateFromTrack(nextTrack);

      // 4. Cleanup
      await Future.delayed(Duration(seconds: duration ~/ 2));
      final oldPlayer = player;
      _activePlayerIndex = (_activePlayerIndex == 0) ? 1 : 0;
      oldPlayer.stop();

      _prefetchNextTrack();
    } catch (e) {
      print('[AI DJ] Crossfade error: $e');
    } finally {
      _isCrossfading = false;
    }
  }

  void _fadeVolumes(Player outPlayer, Player inPlayer, int seconds) {
    _fadeTimer?.cancel();
    var steps = seconds * 10; // 100ms steps
    double currentStep = 0;
    final initialVolume = _ref.read(volumeProvider) * 100.0;

    _fadeTimer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
      currentStep++;
      var ratio = currentStep / steps;

      outPlayer.setVolume(initialVolume * (1.0 - ratio));
      inPlayer.setVolume(initialVolume * ratio);

      if (currentStep >= steps) {
        timer.cancel();
      }
    });
  }

  Future<String?> _getAudioUri(Track track) async {
    // Logic extracted from _playTrackInternal for reuse
    final isar = IsarService.instance;
    final dbTrack = await isar.tracks
        .filter()
        .spotifyIdEqualTo(track.spotifyId)
        .or()
        .titleEqualTo(track.title)
        .and()
        .artistEqualTo(track.artist)
        .findFirst();

    if (dbTrack?.localPath != null &&
        await File(dbTrack!.localPath!).exists()) {
      return dbTrack.localPath;
    }

    final audioSource = _ref.read(audioSourceProvider);
    if (audioSource == 'soundcloud') {
      return await _ref.read(soundcloudServiceProvider).downloadToCache(track);
    }
    return await _ref.read(youtubeServiceProvider).downloadToCache(track);
  }

  Map<String, String> _getMediaExtras(Track track) {
    return {
      'title': track.title,
      'artist': track.artist,
      'album': track.album ?? '',
      'art': track.albumArtUrl ?? '',
      'artwork': track.albumArtUrl ?? '',
    };
  }

  void _handleTrackCompleted() {
    final repeatMode = _ref.read(repeatModeProvider);
    if (repeatMode == PlayerRepeatMode.one) {
      // Replay same track
      player.seek(Duration.zero);
      player.play();
    } else {
      playNext();
      unawaited(_maybeExtendDjQueue());
    }
  }

  void _handleShuffleChange(bool isShuffling) {
    final queue = _ref.read(currentQueueProvider);
    final currentIndex = _ref.read(queueIndexProvider);
    if (queue.isEmpty || currentIndex < 0) return;

    final currentTrack = queue[currentIndex];

    if (isShuffling) {
      _originalQueue = List.of(queue);
      final remaining = queue.sublist(currentIndex + 1)..shuffle();
      final newQueue = queue.sublist(0, currentIndex + 1)..addAll(remaining);
      _ref.read(currentQueueProvider.notifier).state = newQueue;
      // currentIndex stays the same, we just randomized what comes after it
    } else {
      if (_originalQueue.isNotEmpty) {
        final originalIndex = _originalQueue.indexOf(currentTrack);
        _ref.read(currentQueueProvider.notifier).state = _originalQueue;
        _ref.read(queueIndexProvider.notifier).state =
            originalIndex >= 0 ? originalIndex : 0;
      }
    }
  }

  Future<void> playQueue(List<Track> queue, {int initialIndex = 0}) async {
    if (queue.isEmpty) return;

    _originalQueue = List.of(queue);

    var actualQueue = List<Track>.of(queue);
    var actualIndex = initialIndex;

    if (_ref.read(isShufflingProvider)) {
      final currentTrack = actualQueue[initialIndex];
      actualQueue.shuffle();
      actualIndex = actualQueue.indexOf(currentTrack);
    }

    _ref.read(currentQueueProvider.notifier).state = actualQueue;
    _ref.read(queueIndexProvider.notifier).state = actualIndex;

    await _playTrackInternal(actualQueue[actualIndex]);
  }

  Future<void> playNext() async {
    final queue = _ref.read(currentQueueProvider);
    var index = _ref.read(queueIndexProvider);

    if (queue.isEmpty) return;

    index++;
    if (index >= queue.length) {
      if (_ref.read(repeatModeProvider) == PlayerRepeatMode.all) {
        index = 0;
      } else {
        // Queue finished
        _ref.read(isPlayingProvider.notifier).state = false;
        _ref.read(playbackPositionProvider.notifier).state = Duration.zero;
        return;
      }
    }

    _ref.read(queueIndexProvider.notifier).state = index;
    await _playTrackInternal(queue[index]);
    unawaited(_maybeExtendDjQueue());
  }

  Future<void> playPrevious() async {
    final queue = _ref.read(currentQueueProvider);
    var index = _ref.read(queueIndexProvider);
    final position = _ref.read(playbackPositionProvider);

    if (queue.isEmpty) return;

    // If played more than 3 seconds, previous goes to start of current track
    if (position.inSeconds > 3) {
      player.seek(Duration.zero);
      return;
    }

    index--;
    if (index < 0) {
      if (_ref.read(repeatModeProvider) == PlayerRepeatMode.all) {
        index = queue.length - 1;
      } else {
        index = 0;
      }
    }

    _ref.read(queueIndexProvider.notifier).state = index;
    await _playTrackInternal(queue[index]);
  }

  void removeFromQueue(int index) {
    final queue = List<Track>.from(_ref.read(currentQueueProvider));
    if (index < 0 || index >= queue.length) return;
    var currentIndex = _ref.read(queueIndexProvider);

    final removingCurrent = index == currentIndex;
    queue.removeAt(index);

    if (queue.isEmpty) {
      _ref.read(currentQueueProvider.notifier).state = [];
      _ref.read(queueIndexProvider.notifier).state = -1;
      _ref.read(currentTrackProvider.notifier).state = null;
      _ref.read(isPlayingProvider.notifier).state = false;
      player.stop();
      return;
    }

    if (index < currentIndex) {
      currentIndex -= 1;
    } else if (removingCurrent) {
      if (currentIndex >= queue.length) currentIndex = queue.length - 1;
      final nextTrack = queue[currentIndex];
      _ref.read(currentQueueProvider.notifier).state = queue;
      _ref.read(queueIndexProvider.notifier).state = currentIndex;
      _playTrackInternal(nextTrack);
      return;
    }

    _ref.read(currentQueueProvider.notifier).state = queue;
    _ref.read(queueIndexProvider.notifier).state = currentIndex;
  }

  void addToQueue(Track track) {
    final queue = List<Track>.from(_ref.read(currentQueueProvider));
    queue.add(track);
    _ref.read(currentQueueProvider.notifier).state = queue;

    // If nothing was playing, start this track
    if (_ref.read(queueIndexProvider) == -1) {
      _ref.read(queueIndexProvider.notifier).state = 0;
      _playTrackInternal(track);
    }
  }

  void reorderQueue(int oldIndex, int newIndex) {
    final queue = List<Track>.from(_ref.read(currentQueueProvider));
    if (oldIndex < 0 || oldIndex >= queue.length) return;
    if (newIndex < 0 || newIndex > queue.length) return;

    if (newIndex > oldIndex) {
      newIndex -= 1;
    }

    final moved = queue.removeAt(oldIndex);
    queue.insert(newIndex, moved);

    var currentIndex = _ref.read(queueIndexProvider);
    if (currentIndex == oldIndex) {
      currentIndex = newIndex;
    } else if (oldIndex < currentIndex && newIndex >= currentIndex) {
      currentIndex -= 1;
    } else if (oldIndex > currentIndex && newIndex <= currentIndex) {
      currentIndex += 1;
    }

    _ref.read(currentQueueProvider.notifier).state = queue;
    _ref.read(queueIndexProvider.notifier).state = currentIndex;
  }

  // Fallback for single track plays
  Future<void> playTrack(Track track) async {
    await playQueue([track], initialIndex: 0);
  }

  void pause() {
    _ref.read(isPlayingProvider.notifier).state = false;
    player.pause();
  }

  void resume() {
    _ref.read(isPlayingProvider.notifier).state = true;
    player.play();
  }

  void seek(Duration position) {
    _ref.read(playbackPositionProvider.notifier).state = position;
    player.seek(position);
  }

  void ensurePlayingStatus(bool shouldBePlaying) {
    final current = _ref.read(isPlayingProvider);
    if (current != shouldBePlaying) {
      if (shouldBePlaying) {
        player.play();
      } else {
        player.pause();
      }
      _ref.read(isPlayingProvider.notifier).state = shouldBePlaying;
    }
  }

  Future<void> _playTrackInternal(Track track) async {
    final generation = ++_playGeneration;

    try {
      print(
          '[AudioPlayerService] playTrack ($generation) called for: ${track.title}');
      unawaited(
          player.stop()); // Immediately stop previous audio to signal loading
      _ref.read(currentTrackProvider.notifier).state = track;
      _handler.updateFromTrack(track);
      _pushToRecentHistory(track);
      unawaited(_ensureLyricsLoaded(track));
      _ref.read(isLoadingStreamProvider.notifier).state = true;
      _ref.read(playbackPositionProvider.notifier).state = Duration.zero;
      _ref.read(playbackDurationProvider.notifier).state = Duration.zero;

      // Trigger background cover art processing in Rust
      unawaited(_processCoverArtInRust(track));

      String? uriToPlay;
      var needsHeaders = false;

      final isar = IsarService.instance;
      Track? dbTrack;
      if (track.id != Isar.autoIncrement) {
        dbTrack = await isar.tracks.get(track.id);
      }
      if (dbTrack == null && track.spotifyId != null) {
        dbTrack = await isar.tracks
            .filter()
            .spotifyIdEqualTo(track.spotifyId)
            .findFirst();
      }

      // Fuzzy fallback: if we still don't have a record with a path,
      // search by Title + Artist (important for duplicate tracks from different sources)
      // Indexed fuzzy fallback: search by Title + Artist (Exact match first)
      if (dbTrack == null || dbTrack.localPath == null) {
        dbTrack = await isar.tracks
            .filter()
            .titleEqualTo(track.title, caseSensitive: false)
            .and()
            .artistEqualTo(track.artist, caseSensitive: false)
            .findFirst();
            
        if (dbTrack == null || dbTrack.localPath == null) {
          // Deep fuzzy scan (Full scan, only as last resort)
          final fuzzy = await isar.tracks
              .filter()
              .titleContains(track.title, caseSensitive: false)
              .and()
              .artistContains(track.artist, caseSensitive: false)
              .findFirst();
          if (fuzzy != null && fuzzy.localPath != null) {
            print('[AudioPlayerService] Found fuzzy match with local path: ${fuzzy.localPath}');
            dbTrack = fuzzy;
          }
        }
      }

      if (dbTrack != null && dbTrack.localPath != null) {
        final file = File(dbTrack.localPath!);
        if (await file.exists()) {
          uriToPlay = dbTrack.localPath;
          print(
              '[AudioPlayerService] Playing from explicitly saved local path: $uriToPlay');
        } else {
          await isar.writeTxn(() async {
            dbTrack!.localPath = null;
            await isar.tracks.put(dbTrack);
          });
        }
      }

      if (uriToPlay == null) {
        final preferredSource = _ref.read(audioSourceProvider);
        
        // Strategy: Try the preferred source first, then immediately fallback to the other
        final sourceSequence = preferredSource == 'youtube' 
            ? ['youtube', 'soundcloud'] 
            : ['soundcloud', 'youtube'];
            
        for (final source in sourceSequence) {
          try {
            print('[AudioPlayerService] Attempting $source lookup (Generation: $generation)...');
            
            String? localPath;
            if (source == 'soundcloud') {
              localPath = await _ref
                  .read(soundcloudServiceProvider)
                  .downloadToCache(track)
                  .timeout(const Duration(seconds: 30));
            } else {
              localPath = await _ref
                  .read(youtubeServiceProvider)
                  .downloadToCache(track)
                  .timeout(const Duration(seconds: 30));
            }

            if (localPath != null && await File(localPath).exists()) {
              uriToPlay = localPath;
              print('[AudioPlayerService] Source $source SUCCESS. Updating DB...');
              
              // Save path to Isar for offline
              try {
                final isar = IsarService.instance;
                Track? existing;
                if (track.id != Isar.autoIncrement) {
                  existing = await isar.tracks.get(track.id);
                }
                if (existing == null && track.spotifyId != null) {
                  existing = await isar.tracks.filter().spotifyIdEqualTo(track.spotifyId).findFirst();
                }
                if (existing != null) {
                  await isar.writeTxn(() async {
                    existing!.localPath = localPath;
                    await isar.tracks.put(existing);
                  });
                }
              } catch (_) {}
              
              break; // Found a working source!
            }
          } catch (e) {
            print('[AudioPlayerService] Source $source FAILED: $e. Trying fallback if available...');
            continue;
          }
        }
        
        if (uriToPlay == null) {
          print('[AudioPlayerService] All search strategies failed.');
          _ref.read(playbackErrorProvider.notifier).state = 'Не удалось найти рабочий источник ни в YouTube, ни в SoundCloud.';
        }
      }

      if (uriToPlay == null &&
          track.previewUrl != null &&
          track.previewUrl!.isNotEmpty) {
        print('[AudioPlayerService] Falling back to 30 second preview.');
        uriToPlay = track.previewUrl;
        // clear error since we have a fallback
        _ref.read(playbackErrorProvider.notifier).state = null;
      }

      if (generation != _playGeneration) {
        print('[AudioPlayerService] Aborting stale play request ($generation)');
        return;
      }


      final isSuperRes = uriToPlay != null && uriToPlay.contains('hifi_cache');
      _ref.read(isSuperResActiveProvider.notifier).state = isSuperRes;

      if (uriToPlay != null) {
        if (!uriToPlay.startsWith('http')) {
          _processCoverArtInRust(track);
        }
        try {
          print('[AudioPlayerService] Setting player source to: $uriToPlay');
          
          // Clear any potentially broken filters before opening new media (Desktop/MPV only)
          if (isDesktop) {
            final h = await player.handle;
            MpvHelper.setProperty(h, 'af', '');
          }
          
          // Always provide headers for HTTP streams to ensure reliable playback on Android
          final isHttp = uriToPlay.startsWith('http');
          final userAgent = (Platform.isAndroid || Platform.isIOS)
              ? 'Spectrum/1.0 (Mobile; Android 11)'
              : 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/122.0.0.0 Safari/537.36';

          await player.open(Media(
            uriToPlay,
            httpHeaders: isHttp
                ? {
                    'User-Agent': userAgent,
                    'Referer': 'https://www.youtube.com/',
                  }
                : null,
            extras: _getMediaExtras(track),
          ));
          
          // Apply Hi-Fi filters AFTER opening, when the player is ready
          await _applyAudioFilters();
          
          // Request ReplayGain analysis if missing
          if (_ref.read(replayGainEnabledProvider) && track.replayGain == null && !uriToPlay.startsWith('http')) {
             _analyzeReplayGainInBackground(uriToPlay, track);
          }

          print('[AudioPlayerService] Player started successfully.');
          _ref.read(playbackErrorProvider.notifier).state =
              null; // Clear error on success
          // Prefetch next track in queue for instant transitions
          _prefetchNextTrack();
        } catch (e) {
          print('[AudioPlayerService] Error playing track: $e');
          _ref.read(playbackErrorProvider.notifier).state = 'Ошибка плеера: $e';
          _ref.read(isPlayingProvider.notifier).state = false;
        }
      } else {
        print(
            '[AudioPlayerService] No audio source available for ${track.title}');
        // Only set this error if we haven't already set a more specific one from the catch block
        if (_ref.read(playbackErrorProvider) == null) {
          _ref.read(playbackErrorProvider.notifier).state =
              'Не удалось найти аудио для "${track.title}"';
        }
        _ref.read(isPlayingProvider.notifier).state = false;
      }
    } finally {
      if (generation == _playGeneration) {
        _ref.read(isLoadingStreamProvider.notifier).state = false;
      }
    }
  }

  Future<DjMixResult> generateDjMix({
    required String prompt,
    int count = 5,
    List<String> blockedSpotifyIds = const [],
    bool isFirstBlock = false,
  }) async {
    final allTracks = (await IsarService.instance.tracks.where().findAll())
        .where((t) => t.title.trim().isNotEmpty && t.artist.trim().isNotEmpty)
        .toList();

    if (allTracks.isEmpty) {
      return const DjMixResult(
        phrase:
            'Пока не из чего собирать сет. Добавь больше музыки в библиотеку.',
        tracks: [],
      );
    }

    final parsed = _parseDjPrompt(prompt: prompt, tracks: allTracks);
    final recent = _ref.read(recentPlayedTracksProvider);
    final recentArtists =
        recent.take(20).map((t) => t.artist.toLowerCase()).toSet();
    final blocked = blockedSpotifyIds.toSet();

    final scored = <_ScoredTrack>[];
    for (final track in allTracks) {
      if (track.spotifyId != null && blocked.contains(track.spotifyId)) {
        continue;
      }
      if (parsed.explicitArtist != null &&
          track.artist.toLowerCase() != parsed.explicitArtist!.toLowerCase()) {
        if (parsed.artistStrict) continue;
      }

      var score = 0.0;
      final durationSec = track.durationMs / 1000.0;

      if (recentArtists.contains(track.artist.toLowerCase())) score += 2.5;
      if (parsed.rawQuery.isNotEmpty &&
          (track.title.toLowerCase().contains(parsed.rawQuery) ||
              track.artist.toLowerCase().contains(parsed.rawQuery))) {
        score += 3.0;
      }
      if (parsed.wantsCalm && durationSec > 170 && durationSec < 320) {
        score += 1.4;
      }
      if (parsed.wantsEnergy && durationSec < 230) score += 1.2;
      if (parsed.wantsDark && track.title.toLowerCase().contains('night')) {
        score += 1.1;
      }
      if (parsed.wantsSad && (track.durationMs > 240000)) score += 1.5;
      if (parsed.wantsHappy && (track.durationMs < 200000)) score += 1.5;
      if (parsed.wantsAggressive && (track.title.toLowerCase().contains('metal') || track.title.toLowerCase().contains('rock'))) score += 2.0;

      if (parsed.wantsPopular &&
          (track.spotifyId != null && track.spotifyId!.isNotEmpty)) {
        score += 0.8;
      }
      if (parsed.wantsFresh && track.localPath == null) score += 0.6;
      if (parsed.explicitArtist != null &&
          track.artist.toLowerCase() == parsed.explicitArtist!.toLowerCase()) {
        score += 6.0;
      }

      score += _random.nextDouble() * 0.6;
      scored.add(_ScoredTrack(track: track, score: score));
    }

    scored.sort((a, b) => b.score.compareTo(a.score));

    final picked = <Track>[];
    final usedArtists = <String>{};
    for (final candidate in scored) {
      if (picked.length >= count) break;
      final key = candidate.track.artist.toLowerCase();
      if (usedArtists.contains(key) && picked.length < count - 1) continue;
      usedArtists.add(key);
      picked.add(candidate.track);
    }

    // Professional Fallback: If library is too small for the prompt, harvest from Web
    if (picked.length < count) {
      print('[AI DJ] Library exhausted for prompt "$prompt". Harvesting from Neural Web...');
      try {
         final webTracks = await rust_simple.searchTracks(query: prompt, source: 'auto');
         for (final meta in webTracks) {
           if (picked.length >= count) break;
           final t = Track()
             ..title = meta.title
             ..artist = meta.artist
             ..durationMs = meta.durationMs
             ..albumArtUrl = meta.artworkUrl;
           
           if (meta.source == 'youtube') t.youtubeId = meta.id;
           else t.soundcloudId = meta.id;

           if (!picked.any((ex) => ex.title.toLowerCase() == t.title.toLowerCase())) {
             picked.add(t);
           }
         }
      } catch (e) {
        print('[AI DJ] Web harvest failed: $e');
      }
    }

    if (picked.length < count) {
      for (final candidate in scored) {
        if (picked.length >= count) break;
        if (!picked.contains(candidate.track)) picked.add(candidate.track);
      }
    }

    final phrase = _buildDjPhrase(
      prompt: prompt,
      tracks: picked,
      parsed: parsed,
      isFirstBlock: isFirstBlock,
    );
    return DjMixResult(
        phrase: phrase, tracks: picked, parsedArtist: parsed.explicitArtist);
  }

  String _buildDjPhrase({
    required String prompt,
    required List<Track> tracks,
    required _ParsedDjPrompt parsed,
    required bool isFirstBlock,
  }) {
    if (tracks.isEmpty) {
      final emptyRu = [
        'Сет пуст. Попробуй уточнить вайб, например, "спокойный вечер" или "хип-хоп 90-х".',
        'Что-то не пошло, треков нет. Подкинь идею для настроения.',
        'Библиотека молчит по этому запросу. Дай мне другую команду.'
      ];
      final emptyEn = [
        'Empty set. Try a different vibe like “calm evening” or “gym energy”.',
        'No tracks found for that vibe. Tell me something else.',
        'I’m coming up empty here. Give me a new prompt.'
      ];
      return _shortPhrase(
        prompt: prompt,
        ru: emptyRu[_random.nextInt(emptyRu.length)],
        en: emptyEn[_random.nextInt(emptyEn.length)],
      );
    }
    if (parsed.explicitArtist != null) {
      final artist = parsed.explicitArtist!;

      String ru, en;
      if (isFirstBlock) {
        final variantsRu = [
          'Радио Спектрум на связи. Фокус дня — $artist. Поехали!',
          'Тихий вечер с $artist. Начинаем погружение в дискографию.',
          'Ты просил $artist, и я с радостью запускаю первые треки из твоей коллекции.',
          'Включаем волну $artist. Наслаждайся звучанием, это будет круто.',
          'Нейросеть настроена на $artist. Устраивайся поудобнее, начинаем.',
          'Твой личный эфир с акцентом на $artist. Первая подборка готова.',
          'В эфире только $artist. Погружаем реальность в ритм.',
          'Спектрум Диджей. Сегодня во главе стола — $artist. Стартуем!',
          'Нейронные связи зафиксировали резонанс с $artist. Твоя персональная волна запущена.',
          'Активация режима $artist. Вхожу в поток звуковых данных.',
          'Спектрум Лайв. Сегодня мы препарируем творчество $artist. Слушай внимательно.',
        ];
        ru = variantsRu[_random.nextInt(variantsRu.length)];

        final variantsEn = [
          'Spectrum DJ in the house. Focusing on $artist today. Let’s go!',
          'Atmospheric session with $artist starting now. Enjoy the ride.',
          'You asked for $artist, starting the first tracks from your soul right away.',
          'Locking in on the $artist frequency. Enjoy the vibe, we’re live.',
          'Neural core initialized for $artist. Get comfortable, we are diving in.',
          'Personal broadcast focusing on $artist. First set is ready.',
          'Only $artist on air right now. Feel the rhythm.',
          'Spectrum Radio. The $artist special begins right here.',
          'Neural links confirmed a resonance with $artist. Your personal wave is live.',
          'Activating $artist mode. Accessing deep sonic data streams.',
          'Spectrum Live. Today we deconstruct the soundscape of $artist. Stay tuned.',
        ];
        en = variantsEn[_random.nextInt(variantsEn.length)];
      } else {
        // CONTEXTUAL MOOD ACKNOWLEDGMENT (Professional DJ feel)
        if (isFirstBlock) {
          if (parsed.wantsCalm) {
             ru = 'Замедляем темп. Специально для твоего спокойствия — эта подборка. ... Погружайся.';
             en = 'Slowing things down. This selection is crafted for your peace of mind. ... Dive in.';
          } else if (parsed.wantsEnergy || parsed.wantsWorkout) {
             ru = 'Время поднять пульс! Активирую энергетический протокол. ... Погнали!';
             en = 'Time to ramp up the pulse! Activating the energy protocol. ... Let\'s go!';
          } else if (parsed.wantsDark || parsed.wantsCyberpunk) {
             ru = 'Входим в ночной режим. Неоновые огни и мрачный ритм — всё, как ты просил. ... Система готова.';
             en = 'Entering night mode. Neon lights and dark rhythms — just as requested. ... System ready.';
          } else if (parsed.wantsSad) {
             ru = 'Иногда нужно просто погрустить. Я рядом. ... Слушаем меланхолию.';
             en = 'Sometimes we just need to feel. I\'m here with you. ... Listening to melancholy.';
          } else {
             final variantsRu = [
                'Радио Спектрум на связи. Твой запрос принят. ... Начинаем сессию.',
                'Нейросеть проанализировала твой выбор. ... Лови первую волну.',
                'Спектрум Диджей. Твой персональный эфир стартует прямо сейчас.',
             ];
             ru = variantsRu[_random.nextInt(variantsRu.length)];
             en = 'Spectrum DJ. Your personal broadcast is starting right now. ... Stay localized.';
          }
        } else {
          final variantsRu = [
            'Продолжаем в том же духе. Следующие треки уже на подходе, не переключайся.',
            'Не уходи далеко. Ещё порция годноты специально для тебя.',
            'Сигнал стабилен. Продолжаем диктовать условия.',
            'Сканирую новые пласты звука. Оставайся в потоке.',
          ];
          ru = variantsRu[_random.nextInt(variantsRu.length)];

          final variantsEn = [
            'Keeping the energy alive. Next tracks coming up, stay tuned.',
            'Don’t tune out. More of that heat coming just for you.',
            'Sync maintained. Still leading the neural charge.',
            'Scanning more layers. Keep floating in the soundscape.',
          ];
          en = variantsEn[_random.nextInt(variantsEn.length)];
        }
      }
      return _shortPhrase(prompt: prompt, ru: ru, en: en);
    }

    final mood = prompt.trim().isEmpty ? '' : prompt.trim();
    final cleanedMood = _sanitizeMood(mood);
    final moodTxt = cleanedMood.isEmpty ? 'твоё настроение' : cleanedMood;
    final moodTxtEn = cleanedMood.isEmpty ? 'your mood' : cleanedMood;

    String ru, en;
    final firstArtists =
        tracks.take(2).map((t) => t.artist).toSet().join(' и ');
    final firstArtistsEn =
        tracks.take(2).map((t) => t.artist).toSet().join(' and ');

    if (isFirstBlock) {
      final variantsRu = [
        'Поймал вайб: $moodTxt. Сейчас зазвучат $firstArtists. Начинаем погружение!',
        'Волна: $moodTxt. Готовься, на подходе мощный саунд от $firstArtists.',
        'Это твой личный Диджей. Подборка для вайба $moodTxt начинается прямо сейчас. Первый на очереди — $firstArtists.',
        'Система проанализировала запрос: $moodTxt. Выбираю лучшее из $firstArtists.',
        'Спектрум на связи. Твой сегодняшний ритм — $moodTxt. Врываются $firstArtists.',
        'Настраиваюсь на частоту $moodTxt. Погнали, открываем сет треками $firstArtists.',
        'Нейро-сессия $moodTxt объявляется открытой. За пультом — Искусственный Интеллект и $firstArtists.',
      ];
      ru = variantsRu[_random.nextInt(variantsRu.length)];

      final variantsEn = [
        'Got the vibe: $moodTxtEn. Starting the set with $firstArtistsEn. Dive in!',
        'Frequency set to: $moodTxtEn. Get ready for some smooth sounds from $firstArtistsEn.',
        'Your personal DJ here. The $moodTxtEn session starts right now with $firstArtistsEn.',
        'System analyzed: $moodTxtEn. Picking the finest from $firstArtistsEn.',
        'Spectrum live. Your rhythm today is $moodTxtEn. Leading the way: $firstArtistsEn.',
        'Tuning into $moodTxtEn. Let’s go, opening the set with $firstArtistsEn.',
        'Neural session $moodTxtEn is live. Powered by AI and $firstArtistsEn.',
      ];
      en = variantsEn[_random.nextInt(variantsEn.length)];
    } else {
      final variantsRu = [
        'Мы продолжаем вайб $moodTxt. Следующие на очереди — $firstArtists. Не сбавляем темп!',
        'Пульс эфира — $moodTxt. Дальше послушаем новые грани, врываются $firstArtists.',
        'Не снижаем обороты. Подборка под $moodTxt продолжается, за вертушками $firstArtists.',
        'Эфир в самом разгаре. $moodTxt никуда не девается, на подходе $firstArtists.',
        'Вхожу в резонанс с $moodTxt. Слушаем дальше, на очереди $firstArtists.',
        'Ещё больше звука для твоего $moodTxt. Следующий блок открывают $firstArtists.',
      ];
      ru = variantsRu[_random.nextInt(variantsRu.length)];

      final variantsEn = [
        'Continuing the $moodTxtEn vibe. Next up, we have $firstArtistsEn. Keep the energy high!',
        'Holding the $moodTxtEn frequency. Coming up next: $firstArtistsEn.',
        'Momentum is building on the $moodTxtEn flow, now featuring $firstArtistsEn.',
        'Broadcast in full swing. $moodTxtEn is the mood, coming up: $firstArtistsEn.',
        'Resonating with $moodTxtEn. More tracks ahead, starting with $firstArtistsEn.',
        'More sonic textures for your $moodTxtEn. Next block is here with $firstArtistsEn.',
      ];
      en = variantsEn[_random.nextInt(variantsEn.length)];
    }

    return _shortPhrase(prompt: prompt, ru: ru, en: en);
  }

  Future<DjMixResult> startDjSession({
    required String prompt,
    int count = 5,
  }) async {
    _ref.read(djModeEnabledProvider.notifier).state = true;
    _ref.read(djPromptProvider.notifier).state = prompt;

    _ref.read(djHostMessagesProvider.notifier).state = [];
    _ref.read(djQueuedBlockStartIndexProvider.notifier).state = -1;
    _ref.read(djQueuedBlockPhraseProvider.notifier).state = null;

    // DJ should keep stable queue order so phrase timing stays accurate.
    _djWasShuffling = _ref.read(isShufflingProvider);
    _ref.read(isShufflingProvider.notifier).state = false;

    final result =
        await generateDjMix(prompt: prompt, count: count, isFirstBlock: true);

    // Phrase should appear exactly when the first block starts (queueIndex becomes 0).
    _ref.read(djQueuedBlockStartIndexProvider.notifier).state = 0;
    _ref.read(djQueuedBlockPhraseProvider.notifier).state = result.phrase;

    if (result.tracks.isNotEmpty) {
      await playQueue(result.tracks, initialIndex: 0);
      // If queueIndex didn't change (rare), publish immediately.
      _publishQueuedDjPhraseIfNeeded();
    }
    return result;
  }

  void stopDjSession() {
    _ref.read(djModeEnabledProvider.notifier).state = false;
    _ref.read(djQueuedBlockStartIndexProvider.notifier).state = -1;
    _ref.read(djQueuedBlockPhraseProvider.notifier).state = null;
    _ref.read(djHostMessagesProvider.notifier).state = [];
    _ref.read(isShufflingProvider.notifier).state = _djWasShuffling;
  }

  Future<void> _maybeExtendDjQueue() async {
    if (!_ref.read(djModeEnabledProvider)) return;

    final queue = _ref.read(currentQueueProvider);
    final index = _ref.read(queueIndexProvider);
    if (queue.isEmpty || index < 0) return;

    // Avoid overlapping generation.
    final alreadyQueuedStart = _ref.read(djQueuedBlockStartIndexProvider);
    if (alreadyQueuedStart >= 0) return;

    final remaining = queue.length - 1 - index;
    if (remaining > 2) return;

    final prompt = _ref.read(djPromptProvider);
    final blocked = queue.map((t) => t.spotifyId).whereType<String>().toList();
    final next = await generateDjMix(
      prompt: prompt,
      count: 5,
      blockedSpotifyIds: blocked,
      isFirstBlock: false,
    );
    if (next.tracks.isEmpty) return;

    final startIndex = queue.length; // new block starts at the old queue end
    final updatedQueue = List<Track>.from(queue)..addAll(next.tracks);
    _ref.read(currentQueueProvider.notifier).state = updatedQueue;

    // Publish phrase only when we actually reach this block's first track.
    _ref.read(djQueuedBlockStartIndexProvider.notifier).state = startIndex;
    _ref.read(djQueuedBlockPhraseProvider.notifier).state = next.phrase;
  }

  void _publishQueuedDjPhraseIfNeeded() {
    final queuedStart = _ref.read(djQueuedBlockStartIndexProvider);
    final queuedPhrase = _ref.read(djQueuedBlockPhraseProvider);
    final queueIndex = _ref.read(queueIndexProvider);
    if (!_ref.read(djModeEnabledProvider)) return;
    if (queuedStart >= 0 && queuedPhrase != null && queueIndex == queuedStart) {
      final msgs = List<String>.from(_ref.read(djHostMessagesProvider))
        ..add(queuedPhrase);
      _ref.read(djHostMessagesProvider.notifier).state = msgs;
      _ref.read(djQueuedBlockStartIndexProvider.notifier).state = -1;
      _ref.read(djQueuedBlockPhraseProvider.notifier).state = null;
    }
  }

  String _shortPhrase({
    required String prompt,
    required String ru,
    required String en,
  }) {
    final lang = _detectPromptLang(prompt);
    final phrase = lang == _DjLang.ru ? ru : en;
    // Keep it “TTS-friendly”: short and single sentence.
    const maxChars = 120;
    final trimmed = phrase.trim();
    if (trimmed.length <= maxChars) return trimmed;
    return '${trimmed.substring(0, maxChars).trimRight()}…';
  }

  _DjLang _detectPromptLang(String prompt) {
    final hasCyr = RegExp(r'[А-Яа-яЁё]').hasMatch(prompt);
    return hasCyr ? _DjLang.ru : _DjLang.en;
  }

  String _sanitizeMood(String mood) {
    var m = mood.trim();
    // Remove explicit durations like "118 минут", "15 min", "10 minutes", etc.
    m = m.replaceAll(
        RegExp(r'\b\d+\s*(минут|мин|minutes|mins|m)\b', caseSensitive: false),
        '');
    // Keep it short to avoid ultra-long phrases.
    m = m.replaceAll(RegExp(r'\s+'), ' ').trim();
    if (m.length > 36) m = m.substring(0, 36).trimRight();
    return m;
  }

  _ParsedDjPrompt _parseDjPrompt({
    required String prompt,
    required List<Track> tracks,
  }) {
    final q = prompt.toLowerCase().trim();
    final uniqueArtists = tracks.map((t) => t.artist).toSet().toList()
      ..sort((a, b) => b.length.compareTo(a.length));
    String? explicitArtist;

    for (final artist in uniqueArtists) {
      if (q.contains(artist.toLowerCase())) {
        explicitArtist = artist;
        break;
      }
    }

    final artistStrict = q.contains('только') ||
        q.contains('only') ||
        q.contains('исключительно') ||
        q.contains('just') ||
        q.contains('artist:');

    return _ParsedDjPrompt(
      rawQuery: q,
      explicitArtist: explicitArtist,
      artistStrict: artistStrict,
      wantsCalm: q.contains('calm') ||
          q.contains('спокой') ||
          q.contains('чил') ||
          q.contains('тихо'),
      wantsEnergy: q.contains('energ') ||
          q.contains('бодр') ||
          q.contains('спорт') ||
          q.contains('вечерин'),
      wantsDark: q.contains('dark') || q.contains('мрач') || q.contains('ноч'),
      wantsPopular: q.contains('поп') || q.contains('hit') || q.contains('хит'),
      wantsFresh:
          q.contains('нов') || q.contains('fresh') || q.contains('recent'),
      wantsSad: q.contains('грус') || q.contains('sad') || q.contains('плач') || q.contains('меланхол'),
      wantsHappy: q.contains('счаст') || q.contains('happy') || q.contains('радост'),
      wantsWorkout: q.contains('трени') || q.contains('work') || q.contains('зал') || q.contains('спорт'),
      wantsCyberpunk: q.contains('кибер') || q.contains('cyber') || q.contains('будущ') || q.contains('неон'),
      wantsAggressive: q.contains('агрес') || q.contains('aggress') || q.contains('зло') || q.contains('жест'),
    );
  }

  void _pushToRecentHistory(Track track) {
    final recent = List<Track>.from(_ref.read(recentPlayedTracksProvider));
    recent.removeWhere((t) =>
        (t.spotifyId != null && t.spotifyId == track.spotifyId) ||
        t.id == track.id);
    recent.insert(0, track);
    if (recent.length > 80) {
      recent.removeRange(80, recent.length);
    }
    _ref.read(recentPlayedTracksProvider.notifier).state = recent;
  }

  Future<void> _ensureLyricsLoaded(Track track) async {
    // Always fetch fresh lyrics from the Rust engine (the parser improves over time,
    // so stale DB cache might contain broken results)
    final isar = IsarService.instance;
    Track? dbTrack;
    if (track.id != Isar.autoIncrement) {
      dbTrack = await isar.tracks.get(track.id);
    }
    if (dbTrack == null && track.spotifyId != null) {
      dbTrack = await isar.tracks
          .filter()
          .spotifyIdEqualTo(track.spotifyId)
          .findFirst();
    }

    try {
      final lyrics = await _ref.read(lyricsApiProvider).fetchLyrics(track);
      if (lyrics != null && lyrics.trim().isNotEmpty) {
        if (dbTrack != null) {
          await isar.writeTxn(() async {
            dbTrack!.lyrics = lyrics;
            await isar.tracks.put(dbTrack!);
          });
        }
        final current = _ref.read(currentTrackProvider);
        if (current == null) return;
        if (current.id == track.id ||
            (current.spotifyId != null && current.spotifyId == track.spotifyId)) {
          if (dbTrack != null) {
            dbTrack.lyrics = lyrics;
            _ref.read(currentTrackProvider.notifier).state = dbTrack;
          } else {
            current.lyrics = lyrics;
            _ref.read(currentTrackProvider.notifier).state = current;
          }
        }
        return;
      }
    } catch (e) {
      print('[AudioPlayerService] Fresh lyrics fetch failed: $e');
    }

    // Fallback: use cached DB lyrics if fresh fetch failed
    if (dbTrack?.lyrics != null && dbTrack!.lyrics!.trim().isNotEmpty) {
      _ref.read(currentTrackProvider.notifier).state = dbTrack;
      return;
    }
  }

  /// Prefetch the next track in the queue so it starts instantly.
  void _prefetchNextTrack() {
    final queue = _ref.read(currentQueueProvider);
    final index = _ref.read(queueIndexProvider);
    if (queue.isEmpty || index < 0 || index + 1 >= queue.length) return;

    final nextTrack = queue[index + 1];
    final audioSource = _ref.read(audioSourceProvider);

    if (audioSource == 'soundcloud') {
      unawaited(_ref.read(soundcloudServiceProvider).prefetchTrack(nextTrack));
    } else {
      unawaited(_ref.read(youtubeServiceProvider).prefetchTrack(nextTrack));
    }
  }

  void togglePlay() {
    if (_ref.read(isPlayingProvider)) {
      pause();
    } else {
      resume();
    }
  }

  void setVolume(double volume) {
    _ref.read(volumeProvider.notifier).updateValue(volume);
    player.setVolume(volume * 100.0);
  }

  /// Explicitly download the current track for offline playback
  Future<bool> downloadCurrentTrack() async {
    final track = _ref.read(currentTrackProvider);
    if (track == null || track.localPath != null) return false;

    print('[AudioPlayerService] User requested download for: ${track.title}');

    final isar = IsarService.instance;
    var dbTrack = track;
    if (track.id == Isar.autoIncrement && track.spotifyId != null) {
      final existing = await isar.tracks
          .filter()
          .spotifyIdEqualTo(track.spotifyId)
          .findFirst();
      if (existing != null) dbTrack = existing;
    }

    try {
      final audioSource = _ref.read(audioSourceProvider);
      String? path;
      if (audioSource == 'soundcloud') {
        path = await _ref
            .read(soundcloudServiceProvider)
            .downloadTrackToPermanent(dbTrack);
      } else {
        path = await _ref
            .read(youtubeServiceProvider)
            .downloadTrackToPermanent(dbTrack);
      }

      if (path != null) {
        await isar.writeTxn(() async {
          dbTrack.localPath = path;
          await isar.tracks.put(dbTrack);
        });
        // Update tracked state
        _ref.read(currentTrackProvider.notifier).state = dbTrack;
        print('[AudioPlayerService] Track downloaded and saved: $path');
        return true;
      }
      return false;
    } catch (e) {
      print('[AudioPlayerService] Download failed: $e');
      return false;
    }
  }

  Future<void> _speak(String text) async {
    try {
      final lang = _detectPromptLang(text) == _DjLang.ru ? 'ru-RU' : 'en-US';
      
      // Dynamic speed based on context words
      double speed = 1.0;
      final lowerText = text.toLowerCase();
      if (lowerText.contains('энерг') || lowerText.contains('пульс') || lowerText.contains('energy') || lowerText.contains('погнали')) {
        speed = 1.05; // Slightly faster for excitement
      } else if (lowerText.contains('спокой') || lowerText.contains('тихо') || lowerText.contains('меланхол') || lowerText.contains('calm')) {
        speed = 0.92; // Slightly slower for chill vibes
      }

      final encodedText = Uri.encodeComponent(text);
      final url =
          'https://translate.google.com/translate_tts?ie=UTF-8&q=$encodedText&tl=$lang&client=tw-ob&ttsspeed=$speed';

      await _voicePlayer.open(Media(url));
      await _voicePlayer.play();
    } catch (e) {
      print('[AudioPlayerService] TTS Error: $e');
    }
  }


  Future<void> _analyzeReplayGainInBackground(String path, Track track) async {
    try {
      print('[AudioPlayerService] Analyzing loudness for: ${track.title}...');
      final gain = await rust_loudness.calculateReplayGain(path: path);
      
      final isar = IsarService.instance;
      await isar.writeTxn(() async {
        final existing = await isar.tracks.get(track.id);
        if (existing != null) {
          existing.replayGain = gain;
          await isar.tracks.put(existing);
          print('[AudioPlayerService] ReplayGain saved: ${gain.toStringAsFixed(2)}dB');
          
          // Apply filters again if it's still the current track
          if (_ref.read(currentTrackProvider)?.id == track.id) {
             _applyAudioFilters();
          }
        }
      });
    } catch (e) {
      print('[AudioPlayerService] Loudness analysis failed: $e');
    }
  }

  void dispose() {
    _playerA.dispose();
    _playerB.dispose();
    _voicePlayer.dispose();
    _fadeTimer?.cancel();
  }

  Future<void> _processCoverArtInRust(Track track) async {
    try {
      final isar = IsarService.instance;
      // Get fresh record to check if already processed
      final dbTrack = await isar.tracks.get(track.id);
      if (dbTrack == null || (dbTrack.dominantColor != null && dbTrack.blurHashPath != null)) {
        return;
      }

      if (dbTrack.localPath == null || !await File(dbTrack.localPath!).exists()) {
        return;
      }

      final cacheDir = (await getTemporaryDirectory()).path;
      final rustCacheDir = '${cacheDir}/spectrum_covers';
      await Directory(rustCacheDir).create(recursive: true);

      // Call Rust backend for processing
      final result = await rust_image.extractAndProcessCover(
        audioPath: dbTrack.localPath!,
        cacheDir: rustCacheDir,
      );

      // Update database
      await isar.writeTxn(() async {
        dbTrack.dominantColor = result.dominantColorHex;
        dbTrack.blurHashPath = result.blurHashSubset;
        await isar.tracks.put(dbTrack);
      });

      print('[AudioPlayerService] Processed cover art for: ${track.title} (Color: ${result.dominantColorHex})');
      
      // Trigger UI refresh for color
      _ref.invalidate(dominantColorProvider);
    } catch (e) {
      // Missing tags or processing error
      print('[AudioPlayerService] Rust cover processing failed: $e');
    }
  }
}

class DjMixResult {
  final String phrase;
  final List<Track> tracks;
  final String? parsedArtist;

  const DjMixResult({
    required this.phrase,
    required this.tracks,
    this.parsedArtist,
  });
}

class _ScoredTrack {
  final Track track;
  final double score;

  const _ScoredTrack({
    required this.track,
    required this.score,
  });
}

class _ParsedDjPrompt {
  final String rawQuery;
  final String? explicitArtist;
  final bool artistStrict;
  final bool wantsCalm;
  final bool wantsEnergy;
  final bool wantsDark;
  final bool wantsPopular;
  final bool wantsFresh;
  final bool wantsSad;
  final bool wantsHappy;
  final bool wantsWorkout;
  final bool wantsCyberpunk;
  final bool wantsAggressive;

  const _ParsedDjPrompt({
    required this.rawQuery,
    required this.explicitArtist,
    required this.artistStrict,
    required this.wantsCalm,
    required this.wantsEnergy,
    required this.wantsDark,
    required this.wantsPopular,
    required this.wantsFresh,
    required this.wantsSad,
    required this.wantsHappy,
    required this.wantsWorkout,
    required this.wantsCyberpunk,
    required this.wantsAggressive,
  });
}

enum _DjLang { ru, en }
