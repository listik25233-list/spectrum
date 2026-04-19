import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar/isar.dart';
import 'package:spectrum/core/db/isar_service.dart';
import 'package:spectrum/core/db/schemas/playlist_schema.dart';
import 'package:spectrum/core/db/schemas/track_schema.dart';

final playlistTracksProvider =
    StreamProvider.family<List<Track>, int>((ref, playlistId) async* {
  final isar = IsarService.instance;

  await for (final playlist
      in isar.playlists.watchObject(playlistId, fireImmediately: true)) {
    if (playlist == null || playlist.trackSpotifyIds.isEmpty) {
      yield [];
      continue;
    }

    final dbTracks = await isar.tracks
        .filter()
        .anyOf(
            playlist.trackSpotifyIds, (q, String id) => q.spotifyIdEqualTo(id))
        .findAll();

    final tracksMap = <String, Track>{};
    for (final track in dbTracks) {
      if (track.spotifyId != null && !tracksMap.containsKey(track.spotifyId)) {
        tracksMap[track.spotifyId!] = track;
      }
    }

    final orderedTracks = <Track>[];
    for (final id in playlist.trackSpotifyIds) {
      final track = tracksMap[id];
      if (track != null) {
        orderedTracks.add(track);
      }
    }

    yield orderedTracks;
  }
});
