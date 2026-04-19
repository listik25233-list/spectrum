import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar/isar.dart';
import 'package:spectrum/core/db/isar_service.dart';
import 'package:spectrum/core/db/schemas/track_schema.dart';
import 'package:spectrum/features/player/audio_player_service.dart';

final trackLibraryServiceProvider = Provider((ref) {
  return TrackLibraryService(ref: ref);
});

final downloadQueueProvider = StateProvider<List<String>>((ref) => []);
final downloadProgressProvider =
    StateProvider<Map<String, double>>((ref) => {});

class TrackLibraryService {
  final Ref _ref;

  TrackLibraryService({required Ref ref}) : _ref = ref;

  /// Deletes a track from the library and disk
  Future<void> deleteTrack(Track track) async {
    final isar = IsarService.instance;

    // 1. Delete from disk if local path exists
    if (track.localPath != null) {
      try {
        final file = File(track.localPath!);
        if (await file.exists()) {
          await file.delete();
        }
      } catch (e) {
        print('[TrackLibraryService] Error deleting file: $e');
      }
    }

    // 2. Remove from Isar
    await isar.writeTxn(() async {
      await isar.tracks.delete(track.id);
    });

    print('[TrackLibraryService] Track deleted: ${track.title}');
  }

  /// Downloads all tracks in the library that are not already local
  Future<void> downloadAllTracks() async {
    final isar = IsarService.instance;
    final allTracks = await isar.tracks.where().findAll();
    final toDownload = allTracks.where((t) => t.localPath == null).toList();

    if (toDownload.isEmpty) return;

    final ytService = _ref.read(youtubeServiceProvider);
    final queue = _ref.read(downloadQueueProvider.notifier);
    final progress = _ref.read(downloadProgressProvider.notifier);

    queue.state = toDownload.map((t) => t.id.toString()).toList();

    for (var track in toDownload) {
      try {
        progress.state = {...progress.state, track.id.toString(): 0.1};
        final path = await ytService.downloadTrackToPermanent(track);
        if (path != null) {
          await isar.writeTxn(() async {
            track.localPath = path;
            await isar.tracks.put(track);
          });
          progress.state = {...progress.state, track.id.toString(): 1.0};
        }
      } catch (e) {
        print('[TrackLibraryService] Failed to download ${track.title}: $e');
        progress.state = {
          ...progress.state,
          track.id.toString(): -1.0
        }; // Error state
      } finally {
        queue.state =
            queue.state.where((id) => id != track.id.toString()).toList();
      }
    }
  }
}
