import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar/isar.dart';
import 'package:spectrum/core/db/isar_service.dart';
import 'package:spectrum/core/db/schemas/playlist_schema.dart';
import 'package:spectrum/core/db/schemas/track_schema.dart';

final playlistTracksProvider = FutureProvider.family<List<Track>, Playlist>((ref, playlist) async {
  final isar = IsarService.instance;
  
  if (playlist.trackSpotifyIds.isEmpty) return [];

  // Fetch all tracks that match the IDs
  final dbTracks = await isar.tracks.filter()
      .anyOf(playlist.trackSpotifyIds, (q, String id) => q.spotifyIdEqualTo(id))
      .findAll();

  // Create a quick lookup map
  final tracksMap = <String, Track>{};
  for (var t in dbTracks) {
    if (t.spotifyId != null && !tracksMap.containsKey(t.spotifyId)) {
      tracksMap[t.spotifyId!] = t;
    }
  }

  // Reorder them according to the playlist's `trackSpotifyIds` array
  final orderedTracks = <Track>[];
  for (final id in playlist.trackSpotifyIds) {
    if (tracksMap.containsKey(id)) {
      orderedTracks.add(tracksMap[id]!);
    }
  }

  return orderedTracks;
});
