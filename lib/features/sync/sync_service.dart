import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar/isar.dart';
import 'package:spectrum/core/db/isar_service.dart';
import 'package:spectrum/core/db/schemas/track_schema.dart';
import 'package:spectrum/core/db/schemas/playlist_schema.dart';
import 'package:spectrum/core/network/spotify_api.dart';
import 'package:spectrum/features/auth/auth_provider.dart';

final syncServiceProvider = Provider((ref) {
  return SyncService(ref: ref);
});

final isSyncingProvider = StateProvider<bool>((ref) => false);
final syncProgressProvider = StateProvider<String>((ref) => '');

class SyncService {
  final Ref _ref;
  final SpotifyApi _spotifyApi = SpotifyApi();

  SyncService({required Ref ref}) : _ref = ref;

  Future<void> syncSpotifyLibrary() async {
    _ref.read(isSyncingProvider.notifier).state = true;
    _ref.read(syncProgressProvider.notifier).state = 'Fetching tracks from Spotify...';

    try {
      final connectedServices = _ref.read(authProvider).value ?? [];
      if (!connectedServices.contains('spotify')) {
        throw Exception('Spotify account is not connected');
      }

      final allTracksMap = <String, Map<String, dynamic>>{};

      _ref.read(syncProgressProvider.notifier).state = 'Fetching liked songs...';
      final likedTracks = await _spotifyApi.getSavedTracks();
      for (final track in likedTracks) {
        if (track['id'] != null) {
          allTracksMap[track['id'] as String] = track;
        }
      }

      final playlistsToSave = <Playlist>[];

      _ref.read(syncProgressProvider.notifier).state = 'Fetching playlists...';
      final playlists = await _spotifyApi.getUserPlaylists();
      
      for (int i = 0; i < playlists.length; i++) {
        final playlistMap = playlists[i];
        final pName = playlistMap['name'] ?? 'Playlist';
        final pId = playlistMap['id'] as String?;
        if (pId == null) continue;

        _ref.read(syncProgressProvider.notifier).state = 
            'Fetching "$pName" (${i + 1}/${playlists.length})...';
        
        final pTracks = await _spotifyApi.getPlaylistTracks(pId);
        final trackIds = <String>[];
        
        for (final track in pTracks) {
          if (track['id'] != null) {
            final trackId = track['id'] as String;
            allTracksMap[trackId] = track;
            trackIds.add(trackId);
          }
        }
        
        final images = playlistMap['images'] as List?;
        final artworkUrl = images?.firstOrNull?['url'] as String?;

        final playlist = Playlist()
          ..name = pName
          ..source = 'spotify'
          ..sourceId = pId
          ..trackSpotifyIds = trackIds
          ..artworkUrl = artworkUrl
          ..updatedAt = DateTime.now();
        
        playlistsToSave.add(playlist);
      }

      final uniqueTracksList = allTracksMap.values.toList();
      final finalTracksList = <Map<String, dynamic>>[];
      final seenTitleArtistSync = <String>{};
      
      for (final track in uniqueTracksList) {
        final title = track['name'] as String? ?? '';
        final artistsData = track['artists'] as List?;
        final artist = artistsData?.firstOrNull?['name'] as String? ?? '';
        final key = '${title.toLowerCase()}_${artist.toLowerCase()}';
        
        if (!seenTitleArtistSync.contains(key)) {
          seenTitleArtistSync.add(key);
          finalTracksList.add(track);
        }
      }

      final tracksToSave = <Track>[];
      final isar = IsarService.instance;

      _ref.read(syncProgressProvider.notifier).state = 'Preparing ${finalTracksList.length} tracks...';

      for (int i = 0; i < finalTracksList.length; i++) {
        final trackData = finalTracksList[i];
        final spotifyId = trackData['id'] as String?;
        if (spotifyId == null) continue;

        final title = trackData['name'] as String? ?? 'Unknown Title';
        final isrc = SpotifyApi.extractIsrc(trackData);
        final albumData = trackData['album'] as Map<String, dynamic>?;
        final artistsData = trackData['artists'] as List?;
        final artistName = artistsData?.firstOrNull?['name'] as String? ?? 'Unknown Artist';
        final duration = trackData['duration_ms'] as int? ?? 0;
        final images = albumData?['images'] as List?;
        final albumArtUrl = images?.firstOrNull?['url'] as String?;

        // Try to find existing track to preserve id/metadata
        final existingTrack = await isar.tracks.filter()
            .spotifyIdEqualTo(spotifyId)
            .or()
            .group((q) => q.titleEqualTo(title).and().artistEqualTo(artistName))
            .findFirst();

        final track = Track()
          ..id = existingTrack?.id ?? Isar.autoIncrement
          ..spotifyId = spotifyId
          ..isrc = isrc
          ..title = title
          ..artist = artistName
          ..album = albumData?['name'] as String?
          ..durationMs = duration
          ..previewUrl = trackData['preview_url'] as String?
          ..albumArtUrl = albumArtUrl
          ..youtubeId = existingTrack?.youtubeId // Preserve cached youtube id
          ..localPath = existingTrack?.localPath // Preserve downloaded offline file path
          ..lyrics = existingTrack?.lyrics
          ..inLibrary = true;
        
        tracksToSave.add(track);
      }

      _ref.read(syncProgressProvider.notifier).state = 'Saving tracks to database...';
      await isar.writeTxn(() async {
        await isar.tracks.putAll(tracksToSave);
      });

      _ref.read(syncProgressProvider.notifier).state = 'Syncing playlists...';
      await isar.writeTxn(() async {
        await isar.playlists.putAll(playlistsToSave);
      });

      _ref.read(syncProgressProvider.notifier).state = 'Sync completed!';
    } catch (e) {
      print('Sync error: $e');
      _ref.read(syncProgressProvider.notifier).state = 'Sync failed: $e';
    } finally {
      await Future.delayed(const Duration(seconds: 1));
      _ref.read(isSyncingProvider.notifier).state = false;
    }
  }
}
