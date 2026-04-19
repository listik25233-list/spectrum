import 'dart:math';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:spectrum/core/db/schemas/track_schema.dart';
import 'package:spectrum/core/db/isar_service.dart';
import 'package:isar/isar.dart';
import 'package:spectrum/features/player/audio_player_service.dart';
import 'package:spectrum/features/settings/settings_providers.dart';
import 'package:spectrum/src/rust/api/search.dart' as search_rust;
import 'package:spectrum/src/rust/api/models.dart' as rust_models;

final neuralRadioServiceProvider = Provider((ref) => NeuralRadioService(ref));

class NeuralRadioService {
  final Ref _ref;
  bool _isFetching = false;
  final Random _random = Random();

  NeuralRadioService(this._ref);

  Future<void> checkAndFillQueue() async {
    if (!_ref.read(neuralRadioEnabledProvider)) return;
    if (_isFetching) return;

    final queue = _ref.read(currentQueueProvider);
    final index = _ref.read(queueIndexProvider);

    // If we have less than 4 tracks upcoming, fetch a mix of related ones
    if (queue.length - index < 4) {
      final currentTrack = _ref.read(currentTrackProvider);
      if (currentTrack == null) return;

      _isFetching = true;
      try {
        print('[NeuralRadio] Critical queue levels detected. Initializing multi-source harvesting protocol...');
        
        // 1. Prepare Local context for Unified Search
        final isar = IsarService.instance;
        final localTracks = await isar.tracks.where().findAll();
        final localMetadata = localTracks.map((t) => rust_models.SpectrumTrackMetadata(
          id: t.id.toString(),
          title: t.title,
          artist: t.artist,
          durationMs: t.durationMs.toInt(),
          artworkUrl: t.albumArtUrl,
          source: 'local',
          localPath: t.localPath,
        )).toList();

        // 2. Execute professional Unified Search (Local + YouTube + SoundCloud)
        // We use the current track's vibe as the seed
        final query = '${currentTrack.artist} ${currentTrack.title}';
        final results = await search_rust.unifiedSearch(
          query: query,
          localTracks: localMetadata,
          source: 'auto',
        );

        if (results.isNotEmpty) {
          final queueTitles = queue.map((t) => t.title.toLowerCase().trim()).toSet();
          final queueIds = queue.map((t) => t.youtubeId ?? t.soundcloudId ?? '').where((id) => id.isNotEmpty).toSet();
          
          final List<Track> toAdd = [];
          final rawCandidates = results.toList()..shuffle();

          for (final meta in rawCandidates) {
            if (toAdd.length >= 6) break;
            
            final normalizedTitle = meta.title.toLowerCase().trim();
            final isDuplicate = queueTitles.contains(normalizedTitle) || queueIds.contains(meta.id);
            
            if (!isDuplicate) {
              final t = Track()
                ..title = meta.title
                ..artist = meta.artist
                ..durationMs = meta.durationMs
                ..albumArtUrl = meta.artworkUrl
                ..youtubeId = meta.source == 'youtube' ? meta.id : null
                ..soundcloudId = meta.source == 'soundcloud' ? meta.id : null;
              
              toAdd.add(t);
              queueTitles.add(normalizedTitle);
              if (meta.id.isNotEmpty) queueIds.add(meta.id);
            }
          }

          if (toAdd.isNotEmpty) {
            final updatedQueue = [...queue, ...toAdd];
            _ref.read(currentQueueProvider.notifier).state = updatedQueue;
            
            print('[NeuralRadio] Succesfully injected ${toAdd.length} spectral signals. Infinity stream maintained.');

            // 3. Optional DJ Introduction for injected tracks
            if (_ref.read(djModeEnabledProvider)) {
              _queueDjHarvestPhrase(updatedQueue.length - toAdd.length);
            }
          }
        }
      } catch (e) {
        print('[NeuralRadio] Harvesting failure: $e');
      } finally {
        _isFetching = false;
      }
    }
  }

  void _queueDjHarvestPhrase(int startIndex) {
    // Only queue if not already waiting for another phrase
    if (_ref.read(djQueuedBlockStartIndexProvider) >= 0) return;

    final phrasesRu = [
        'Поток Спектрума расширяется. Я подобрал ещё несколько треков для твоей вселенной.',
        'Обнаружены новые звуковые сигналы. Интегрирую их в твой текущий вайб.',
        'Нейронные связи зафиксировали резонанс. Добавляю похожие вибрации в эфир.',
        'Твой вкус — мой компас. Расширяю очередь новыми находками из сети.',
        'Система нашла идеальное продолжение. Наслаждайся бесконечным потоком.',
    ];
    final phrasesEn = [
        'The Spectrum stream is expanding. I’ve discovered more signals for your universe.',
        'New sonic markers detected. Integrating them into your current vibe.',
        'Neural links confirmed a resonance. Adding similar vibrations to the airwaves.',
        'Your taste is my compass. Expanding the queue with new discoveries.',
        'The system found the perfect continuation. Enjoy the infinite flow.',
    ];

    final isRu = _random.nextBool(); // Randomly choose language or implement detection
    final phrase = isRu ? phrasesRu[_random.nextInt(phrasesRu.length)] : phrasesEn[_random.nextInt(phrasesEn.length)];

    _ref.read(djQueuedBlockStartIndexProvider.notifier).state = startIndex;
    _ref.read(djQueuedBlockPhraseProvider.notifier).state = phrase;
  }
}
