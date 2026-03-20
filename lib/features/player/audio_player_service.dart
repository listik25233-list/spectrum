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

final youtubeServiceProvider = Provider<YoutubeAudioService>((ref) {
  final service = YoutubeAudioService();
  ref.onDispose(() {
    service.dispose();
  });
  return service;
});

final lyricsApiProvider = Provider<LyricsApi>((ref) {
  return LyricsApi();
});

final audioPlayerServiceProvider = Provider<AudioPlayerService>((ref) {
  final service = AudioPlayerService(ref);
  ref.onDispose(() {
    service.dispose();
  });
  return service;
});

enum RepeatMode { off, all, one }

final currentQueueProvider = StateProvider<List<Track>>((ref) => []);
final isShufflingProvider = StateProvider<bool>((ref) => false);
final repeatModeProvider = StateProvider<RepeatMode>((ref) => RepeatMode.off);
final queueIndexProvider = StateProvider<int>((ref) => -1);

final currentTrackProvider = StateProvider<Track?>((ref) => null);
final isPlayingProvider = StateProvider<bool>((ref) => false);
final isLoadingStreamProvider = StateProvider<bool>((ref) => false);
final playbackPositionProvider = StateProvider<Duration>((ref) => Duration.zero);
final playbackDurationProvider = StateProvider<Duration>((ref) => Duration.zero);
final volumeProvider = StateProvider<double>((ref) => 1.0);
final lyricsSyncOffsetMsProvider = StateProvider<int>((ref) => 0);
final recentPlayedTracksProvider = StateProvider<List<Track>>((ref) => []);
final djModeEnabledProvider = StateProvider<bool>((ref) => false);
final djPromptProvider = StateProvider<String>((ref) => '');
final djHostMessagesProvider = StateProvider<List<String>>((ref) => []);
final djQueuedBlockStartIndexProvider = StateProvider<int>((ref) => -1);
final djQueuedBlockPhraseProvider = StateProvider<String?>((ref) => null);

class AudioPlayerService {
  final Player _player = Player();
  final Player _voicePlayer = Player(); // Separate player for DJ host voice
  final Ref _ref;

  // Storing original queue to restore after shuffling
  List<Track> _originalQueue = [];
  bool _isChangingTrack = false;
  final Random _random = Random();
  bool _djWasShuffling = false;

  AudioPlayerService(this._ref) {
    _init();

    // Listen to shuffle changes to reorder pending queue
    _ref.listen<bool>(isShufflingProvider, (prev, isShuffling) {
      if (prev == isShuffling) return;
      _handleShuffleChange(isShuffling);
    });

    // Publish DJ phrase exactly when we enter the queued block start index.
    _ref.listen<int>(queueIndexProvider, (prev, next) {
      if (!_ref.read(djModeEnabledProvider)) return;
      final queuedStart = _ref.read(djQueuedBlockStartIndexProvider);
      final queuedPhrase = _ref.read(djQueuedBlockPhraseProvider);
      if (queuedStart >= 0 && queuedPhrase != null && next == queuedStart) {
        final msgs = List<String>.from(_ref.read(djHostMessagesProvider))..add(queuedPhrase);
        _ref.read(djHostMessagesProvider.notifier).state = msgs;
        _ref.read(djQueuedBlockStartIndexProvider.notifier).state = -1;
        _ref.read(djQueuedBlockPhraseProvider.notifier).state = null;
        
        // Speak the phrase!
        _speak(queuedPhrase);
      }
    });
  }

  Player get player => _player;

  void _init() {
    _player.stream.playing.listen((playing) {
      _ref.read(isPlayingProvider.notifier).state = playing;
    });

    _player.stream.position.listen((position) {
      _ref.read(playbackPositionProvider.notifier).state = position;
    });

    _player.stream.duration.listen((duration) {
      _ref.read(playbackDurationProvider.notifier).state = duration;
    });

    _player.stream.volume.listen((volume) {
      _ref.read(volumeProvider.notifier).state = volume / 100.0;
    });

    _voicePlayer.stream.playing.listen((playing) {
      if (playing) {
        // Lower music volume while DJ is speaking
        _player.setVolume(_ref.read(volumeProvider) * 30.0);
      } else {
        // Restore music volume
        _player.setVolume(_ref.read(volumeProvider) * 100.0);
      }
    });

    _player.stream.completed.listen((completed) {
      if (completed && !_isChangingTrack) {
        _handleTrackCompleted();
      }
    });

    _player.stream.log.listen((event) {
      print('[MediaKit-Internal] ${event.level}: ${event.text}');
    });

    _player.stream.error.listen((error) {
      print('[MediaKit-Error] $error');
    });
  }

  void _handleTrackCompleted() {
    final repeatMode = _ref.read(repeatModeProvider);
    if (repeatMode == RepeatMode.one) {
      // Replay same track
      _player.seek(Duration.zero);
      _player.play();
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
        _ref.read(queueIndexProvider.notifier).state = originalIndex >= 0 ? originalIndex : 0;
      }
    }
  }

  Future<void> playQueue(List<Track> queue, {int initialIndex = 0}) async {
    if (queue.isEmpty) return;
    
    _originalQueue = List.of(queue);
    
    List<Track> actualQueue = List.of(queue);
    int actualIndex = initialIndex;

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
      if (_ref.read(repeatModeProvider) == RepeatMode.all) {
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
      _player.seek(Duration.zero);
      return;
    }
    
    index--;
    if (index < 0) {
      if (_ref.read(repeatModeProvider) == RepeatMode.all) {
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
      _player.stop();
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

  Future<void> _playTrackInternal(Track track) async {
    if (_isChangingTrack) return;
    _isChangingTrack = true;
    
    print('[AudioPlayerService] playTrack called for: ${track.title}');
    _ref.read(currentTrackProvider.notifier).state = track;
    _pushToRecentHistory(track);
    unawaited(_ensureLyricsLoaded(track));
    _ref.read(isLoadingStreamProvider.notifier).state = true;
    _ref.read(playbackPositionProvider.notifier).state = Duration.zero;
    _ref.read(playbackDurationProvider.notifier).state = Duration.zero;
    
    String? uriToPlay;
    
    final isar = IsarService.instance;
    Track? dbTrack;
    if (track.id != Isar.autoIncrement) {
      dbTrack = await isar.tracks.get(track.id);
    }
    if (dbTrack == null && track.spotifyId != null) {
      dbTrack = await isar.tracks.filter().spotifyIdEqualTo(track.spotifyId).findFirst();
    }
    
    if (dbTrack != null && dbTrack.localPath != null) {
      final file = File(dbTrack.localPath!);
      if (await file.exists()) {
        uriToPlay = dbTrack.localPath;
        print('[AudioPlayerService] Playing from explicitly saved local path: $uriToPlay');
      } else {
        await isar.writeTxn(() async {
          dbTrack!.localPath = null;
          await isar.tracks.put(dbTrack!);
        });
      }
    }
    
    if (uriToPlay == null) {
      final ytService = _ref.read(youtubeServiceProvider);
      try {
        print('[AudioPlayerService] Attempting YouTube lookup...');
        uriToPlay = await ytService.getAudioStreamUrl(track);
        print('[AudioPlayerService] YouTube URL/Path obtained: $uriToPlay');
      } catch (e) {
        print('[AudioPlayerService] YouTube stream failed: $e');
      }
    }

    if (uriToPlay == null && track.previewUrl != null && track.previewUrl!.isNotEmpty) {
      print('[AudioPlayerService] Falling back to 30 second preview.');
      uriToPlay = track.previewUrl;
    }

    if (uriToPlay != null) {
      try {
        print('[AudioPlayerService] Setting player source to: $uriToPlay');
        await _player.open(Media(uriToPlay));
        await _player.play();
        print('[AudioPlayerService] Player started successfully.');
      } catch (e) {
        print('[AudioPlayerService] Error playing track: $e');
        _ref.read(isPlayingProvider.notifier).state = false;
      }
    } else {
      print('[AudioPlayerService] No audio source available for ${track.title}');
    }

    _ref.read(isLoadingStreamProvider.notifier).state = false;
    _isChangingTrack = false;
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
        phrase: 'Пока не из чего собирать сет. Добавь больше музыки в библиотеку.',
        tracks: [],
      );
    }

    final parsed = _parseDjPrompt(prompt: prompt, tracks: allTracks);
    final recent = _ref.read(recentPlayedTracksProvider);
    final recentArtists = recent.take(20).map((t) => t.artist.toLowerCase()).toSet();
    final blocked = blockedSpotifyIds.toSet();

    final scored = <_ScoredTrack>[];
    for (final track in allTracks) {
      if (track.spotifyId != null && blocked.contains(track.spotifyId)) continue;
      if (parsed.explicitArtist != null && track.artist.toLowerCase() != parsed.explicitArtist!.toLowerCase()) {
        if (parsed.artistStrict) continue;
      }

      var score = 0.0;
      final durationSec = track.durationMs / 1000.0;

      if (recentArtists.contains(track.artist.toLowerCase())) score += 2.5;
      if (parsed.rawQuery.isNotEmpty &&
          (track.title.toLowerCase().contains(parsed.rawQuery) || track.artist.toLowerCase().contains(parsed.rawQuery))) {
        score += 3.0;
      }
      if (parsed.wantsCalm && durationSec > 170 && durationSec < 320) score += 1.4;
      if (parsed.wantsEnergy && durationSec < 230) score += 1.2;
      if (parsed.wantsDark && track.title.toLowerCase().contains('night')) score += 1.1;
      if (parsed.wantsPopular && (track.spotifyId != null && track.spotifyId!.isNotEmpty)) score += 0.8;
      if (parsed.wantsFresh && track.localPath == null) score += 0.6;
      if (parsed.explicitArtist != null && track.artist.toLowerCase() == parsed.explicitArtist!.toLowerCase()) score += 6.0;

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
    return DjMixResult(phrase: phrase, tracks: picked, parsedArtist: parsed.explicitArtist);
  }

  String _buildDjPhrase({
    required String prompt,
    required List<Track> tracks,
    required _ParsedDjPrompt parsed,
    required bool isFirstBlock,
  }) {
    if (tracks.isEmpty) {
      return _shortPhrase(
        prompt: prompt,
        ru: 'Сет пуст. Уточни вайб: например "спокойный вечер" или "энергия для тренировки".',
        en: 'Empty set. Try a vibe prompt like “calm evening” or “gym energy”.',
      );
    }

    final lang = _detectPromptLang(prompt);
    final firstArtists = tracks.take(2).map((t) => t.artist).toSet().join(', ');
    if (parsed.explicitArtist != null) {
      final artist = parsed.explicitArtist!;
      final ru = isFirstBlock
          ? 'Фокус на ${artist}. Запускаю первые 5 треков.'
          : 'Следующий блок: ${artist}. Продолжаю 5 треков.';
      final en = isFirstBlock
          ? 'Focusing on ${artist}. Starting the first 5 tracks.'
          : 'Next up: ${artist}. Here are the next 5 tracks.';
      return _shortPhrase(prompt: prompt, ru: ru, en: en);
    }

    final mood = prompt.trim().isEmpty ? '' : prompt.trim();
    final cleanedMood = _sanitizeMood(mood);
    final ru = isFirstBlock
        ? 'Поймал вайб: ${cleanedMood.isEmpty ? "твоя настройка" : cleanedMood}. Запускаю подборку из 5 треков.'
        : 'Продолжаю подборку по вайбу: ${cleanedMood.isEmpty ? "твоё настроение" : cleanedMood}. Следующие 5 треков.';
    final en = isFirstBlock
        ? 'Got the vibe: ${cleanedMood.isEmpty ? "your mood" : cleanedMood}. Starting a 5-track pick.'
        : 'Continuing the vibe: ${cleanedMood.isEmpty ? "your mood" : cleanedMood}. Next 5 tracks.';
    // Keep it short and consistent by language.
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

    final result = await generateDjMix(prompt: prompt, count: count, isFirstBlock: true);

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
      final msgs = List<String>.from(_ref.read(djHostMessagesProvider))..add(queuedPhrase);
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
    final maxChars = 120;
    final trimmed = phrase.trim();
    if (trimmed.length <= maxChars) return trimmed;
    return trimmed.substring(0, maxChars).trimRight() + '…';
  }

  _DjLang _detectPromptLang(String prompt) {
    final hasCyr = RegExp(r'[А-Яа-яЁё]').hasMatch(prompt);
    return hasCyr ? _DjLang.ru : _DjLang.en;
  }

  String _sanitizeMood(String mood) {
    var m = mood.trim();
    // Remove explicit durations like "118 минут", "15 min", "10 minutes", etc.
    m = m.replaceAll(RegExp(r'\b\d+\s*(минут|мин|minutes|mins|m)\b', caseSensitive: false), '');
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
      wantsCalm: q.contains('calm') || q.contains('спокой') || q.contains('чил') || q.contains('тихо'),
      wantsEnergy: q.contains('энерг') || q.contains('бодр') || q.contains('спорт') || q.contains('вечерин'),
      wantsDark: q.contains('dark') || q.contains('мрач') || q.contains('ноч'),
      wantsPopular: q.contains('поп') || q.contains('hit') || q.contains('хит'),
      wantsFresh: q.contains('нов') || q.contains('fresh') || q.contains('recent'),
    );
  }

  void _pushToRecentHistory(Track track) {
    final recent = List<Track>.from(_ref.read(recentPlayedTracksProvider));
    recent.removeWhere((t) => (t.spotifyId != null && t.spotifyId == track.spotifyId) || t.id == track.id);
    recent.insert(0, track);
    if (recent.length > 80) {
      recent.removeRange(80, recent.length);
    }
    _ref.read(recentPlayedTracksProvider.notifier).state = recent;
  }

  Future<void> _ensureLyricsLoaded(Track track) async {
    if (track.lyrics != null && track.lyrics!.trim().isNotEmpty) return;

    final isar = IsarService.instance;
    Track? dbTrack;
    if (track.id != Isar.autoIncrement) {
      dbTrack = await isar.tracks.get(track.id);
    }
    if (dbTrack == null && track.spotifyId != null) {
      dbTrack = await isar.tracks.filter().spotifyIdEqualTo(track.spotifyId).findFirst();
    }

    if (dbTrack?.lyrics != null && dbTrack!.lyrics!.trim().isNotEmpty) {
      _ref.read(currentTrackProvider.notifier).state = dbTrack;
      return;
    }

    final lyrics = await _ref.read(lyricsApiProvider).fetchLyrics(track);
    if (lyrics == null || lyrics.trim().isEmpty) return;

    if (dbTrack != null) {
      await isar.writeTxn(() async {
        dbTrack!.lyrics = lyrics;
        await isar.tracks.put(dbTrack!);
      });
    }

    final current = _ref.read(currentTrackProvider);
    if (current == null) return;
    if (current.id == track.id || (current.spotifyId != null && current.spotifyId == track.spotifyId)) {
      if (dbTrack != null) {
        _ref.read(currentTrackProvider.notifier).state = dbTrack;
      } else {
        current.lyrics = lyrics;
        _ref.read(currentTrackProvider.notifier).state = current;
      }
    }
  }

  void togglePlay() {
    _player.playOrPause();
  }
  
  void seek(Duration position) {
    _player.seek(position);
  }

  void setVolume(double volume) {
    _player.setVolume(volume * 100.0);
  }

  /// Explicitly download the current track for offline playback
  Future<bool> downloadCurrentTrack() async {
    final track = _ref.read(currentTrackProvider);
    if (track == null || track.localPath != null) return false;

    print('[AudioPlayerService] User requested download for: ${track.title}');
    
    final isar = IsarService.instance;
    Track dbTrack = track;
    if (track.id == Isar.autoIncrement && track.spotifyId != null) {
       final existing = await isar.tracks.filter().spotifyIdEqualTo(track.spotifyId).findFirst();
       if (existing != null) dbTrack = existing;
    }

    final ytService = _ref.read(youtubeServiceProvider);
    try {
      final path = await ytService.downloadTrackToPermanent(dbTrack);
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
      final lang = _detectPromptLang(text) == _DjLang.ru ? 'ru' : 'en';
      final encodedText = Uri.encodeComponent(text);
      final url = 'https://translate.google.com/translate_tts?ie=UTF-8&q=$encodedText&tl=$lang&client=tw-ob';
      
      await _voicePlayer.open(Media(url));
      await _voicePlayer.play();
    } catch (e) {
      print('[AudioPlayerService] TTS Error: $e');
    }
  }

  void dispose() {
    _player.dispose();
    _voicePlayer.dispose();
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

  const _ParsedDjPrompt({
    required this.rawQuery,
    required this.explicitArtist,
    required this.artistStrict,
    required this.wantsCalm,
    required this.wantsEnergy,
    required this.wantsDark,
    required this.wantsPopular,
    required this.wantsFresh,
  });
}

enum _DjLang { ru, en }
