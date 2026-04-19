import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar/isar.dart';
import 'package:spectrum/core/db/isar_service.dart';
import 'package:spectrum/core/db/schemas/playlist_schema.dart';
import 'package:spectrum/core/db/schemas/track_schema.dart';
import 'package:spectrum/core/network/spotify_api.dart';

final playlistEditorServiceProvider = Provider((ref) {
  return PlaylistEditorService();
});

class PlaylistEditorService {
  Future<Playlist> createPlaylist(String name) async {
    final trimmedName = name.trim();
    if (trimmedName.isEmpty) {
      throw Exception('Введите название плейлиста');
    }

    final playlist = Playlist()
      ..name = trimmedName
      ..source = 'local'
      ..sourceId = 'local_${DateTime.now().microsecondsSinceEpoch}'
      ..updatedAt = DateTime.now();

    final isar = IsarService.instance;
    await isar.writeTxn(() async {
      await isar.playlists.put(playlist);
    });

    return playlist;
  }

  Future<void> addTrackToPlaylist({
    required int playlistId,
    required Track track,
  }) async {
    final spotifyId = track.spotifyId;
    if (spotifyId == null || spotifyId.isEmpty) {
      throw Exception(
          'У этого трека нет Spotify ID, его нельзя добавить в плейлист');
    }

    final isar = IsarService.instance;
    final playlist = await isar.playlists.get(playlistId);
    if (playlist == null) {
      throw Exception('Плейлист не найден');
    }

    if (playlist.trackSpotifyIds.contains(spotifyId)) {
      return;
    }

    playlist.trackSpotifyIds = [...playlist.trackSpotifyIds, spotifyId];
    playlist.updatedAt = DateTime.now();

    await isar.writeTxn(() async {
      await isar.playlists.put(playlist);
    });
  }

  Future<Track> saveSpotifyTrack(Map<String, dynamic> trackData) async {
    final spotifyId = trackData['id'] as String?;
    if (spotifyId == null || spotifyId.isEmpty) {
      throw Exception('У трека нет Spotify ID');
    }

    final isar = IsarService.instance;
    final title = trackData['name'] as String? ?? 'Unknown Title';
    final albumData = trackData['album'] as Map<String, dynamic>?;
    final artistsData = trackData['artists'] as List?;
    final artistName =
        artistsData?.firstOrNull?['name'] as String? ?? 'Unknown Artist';
    final duration = trackData['duration_ms'] as int? ?? 0;
    final images = albumData?['images'] as List?;
    String? albumArtUrl;
    if (images != null && images.isNotEmpty) {
      // Prioritize modern Spotify CDN (i.scdn.co) over legacy/broken ones (t.scdn.co)
      try {
        final betterImage = images.firstWhere(
          (img) => !(img['url'] as String? ?? '').contains('t.scdn.co'),
          orElse: () => images.first,
        );
        albumArtUrl = betterImage['url'] as String?;
      } catch (_) {
        albumArtUrl = images.first['url'] as String?;
      }
    }

    final existingTrack = await isar.tracks
        .filter()
        .spotifyIdEqualTo(spotifyId)
        .or()
        .group((q) => q.titleEqualTo(title).and().artistEqualTo(artistName))
        .findFirst();

    final track = Track()
      ..id = existingTrack?.id ?? Isar.autoIncrement
      ..spotifyId = spotifyId
      ..isrc = SpotifyApi.extractIsrc(trackData)
      ..title = title
      ..artist = artistName
      ..album = albumData?['name'] as String?
      ..durationMs = duration
      ..previewUrl = trackData['preview_url'] as String?
      ..albumArtUrl = albumArtUrl
      ..youtubeId = existingTrack?.youtubeId
      ..localPath = existingTrack?.localPath
      ..lyrics = existingTrack?.lyrics
      ..inLibrary = existingTrack?.inLibrary ?? false;

    await isar.writeTxn(() async {
      await isar.tracks.put(track);
    });

    return track;
  }

  Future<void> addSpotifyTrackToPlaylist({
    required int playlistId,
    required Map<String, dynamic> trackData,
  }) async {
    final track = await saveSpotifyTrack(trackData);
    await addTrackToPlaylist(
      playlistId: playlistId,
      track: track,
    );
  }

  static String cleanYoutubeTitle(String title) {
    var cleaned = title.replaceAll(RegExp(r'\([^)]*\)'), '');
    cleaned = cleaned.replaceAll(RegExp(r'\[[^\]]*\]'), '');
    cleaned = cleaned.replaceAll(
      RegExp(
          r'official video|official audio|lyric video|music video|lyric|video|audio',
          caseSensitive: false),
      '',
    );
    return cleaned.trim();
  }

  Future<Track> saveYoutubePreviewTrack(dynamic videoObj) async {
    // using dynamic to avoid importing youtube_explode_dart in this file if we don't strictly need to expose it,
    // but actually it's fine since we just map fields.
    // We expect videoObj to have id.value, title, author, duration?.inMilliseconds, thumbnails.mediumResUrl
    final video = videoObj;
    final String youtubeId = video.id.value;
    final String videoTitle = video.title;
    final String videoAuthor = video.author;
    final int? durationMs = video.duration?.inMilliseconds;
    final String? artUrl = video.thumbnails.mediumResUrl;

    final isar = IsarService.instance;
    final existingTrack =
        await isar.tracks.filter().youtubeIdEqualTo(youtubeId).findFirst();

    final title = cleanYoutubeTitle(videoTitle);

    final track = Track()
      ..id = existingTrack?.id ?? Isar.autoIncrement
      ..title = existingTrack?.title ?? title
      ..artist = existingTrack?.artist ?? videoAuthor
      ..durationMs = existingTrack?.durationMs ?? durationMs ?? 0
      ..albumArtUrl = existingTrack?.albumArtUrl ?? artUrl
      ..youtubeId = youtubeId
      ..spotifyId = existingTrack?.spotifyId
      ..isrc = existingTrack?.isrc
      ..album = existingTrack?.album
      ..localPath = existingTrack?.localPath
      ..lyrics = existingTrack?.lyrics
      ..inLibrary = existingTrack?.inLibrary ?? false;

    await isar.writeTxn(() async {
      await isar.tracks.put(track);
    });

    return track;
  }
}
