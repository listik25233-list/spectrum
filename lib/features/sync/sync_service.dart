import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import 'package:isar/isar.dart';
import 'package:logger/logger.dart';
import 'package:spectrum/core/db/isar_service.dart';
import 'package:spectrum/core/db/schemas/track_schema.dart';
import 'package:spectrum/core/db/schemas/playlist_schema.dart';
import 'package:spectrum/core/network/spotify_api.dart';
import 'package:spectrum/features/auth/auth_provider.dart';
import 'package:spectrum/src/rust/api/spotify.dart' as rust_spotify;
import 'package:spectrum/src/rust/api/metadata.dart' as rust_metadata;
import 'package:spectrum/src/rust/api/models.dart' as rust_models;

final syncServiceProvider = Provider((ref) {
  return SyncService(ref: ref);
});

final isSyncingProvider = StateProvider<bool>((ref) => false);
final syncProgressProvider = StateProvider<String>((ref) => '');

class SyncService {
  final Ref _ref;
  final SpotifyApi _spotifyApi = SpotifyApi();
  final _log = Logger();

  SyncService({required Ref ref}) : _ref = ref;

  Future<void> syncSpotifyLibrary() async {
    _ref.read(isSyncingProvider.notifier).state = true;
    _ref.read(syncProgressProvider.notifier).state =
        'Fetching tracks from Spotify...';

    try {
      final connectedServices = _ref.read(authProvider).value ?? [];
      if (!connectedServices.contains('spotify')) {
        throw Exception('Spotify account is not connected');
      }

      final token = await _spotifyApi.getValidToken();
      if (token == null) {
        throw Exception(
            'Не удалось получить действующий токен Spotify. Переподключите аккаунт.');
      }

      _ref.read(syncProgressProvider.notifier).state =
          'Fetching library via Rust Core (Concurrent)...';

      final syncResult = await rust_spotify.syncSpotifyLibrary(token: token.accessToken);
      final likedTrackIds = syncResult.likedTrackIds;

      final playlistsToSave = <Playlist>[];
      final isar = IsarService.instance;

      // 1. Process Liked Songs Playlist
      if (likedTrackIds.isNotEmpty) {
        final existingLiked = await isar.playlists
            .filter()
            .sourceEqualTo('spotify')
            .and()
            .sourceIdEqualTo('liked')
            .findFirst();

        final likedPlaylist = Playlist()
          ..id = existingLiked?.id ?? Isar.autoIncrement
          ..name = 'Любимые треки'
          ..source = 'spotify'
          ..sourceId = 'liked'
          ..trackSpotifyIds = likedTrackIds
          ..artworkUrl = 'https://misc.scdn.co/liked-songs/liked-songs-640.png'
          ..updatedAt = DateTime.now();

        playlistsToSave.add(likedPlaylist);
      }

      // 2. Process other playlists from Rust
      for (final p in syncResult.playlists) {
        final existingPlaylist = await isar.playlists
            .filter()
            .sourceEqualTo('spotify')
            .and()
            .sourceIdEqualTo(p.id)
            .findFirst();

        final playlist = Playlist()
          ..id = existingPlaylist?.id ?? Isar.autoIncrement
          ..name = p.name
          ..source = 'spotify'
          ..sourceId = p.id
          ..trackSpotifyIds = p.trackIds
          ..artworkUrl = p.artworkUrl
          ..updatedAt = DateTime.now();

        playlistsToSave.add(playlist);
      }

      // 3. Batch Metadata Normalization in Rust
      _ref.read(syncProgressProvider.notifier).state =
          'Normalizing metadata in Rust Core...';
      
      final rustTracksToNormalize = syncResult.tracks.map((rt) => rust_models.SpectrumTrackMetadata(
        id: rt.id,
        title: rt.title,
        artist: rt.artist,
        durationMs: rt.durationMs,
        artworkUrl: rt.artworkUrl,
        source: 'spotify',
      )).toList();

      final normalizedRustTracks = await rust_metadata.normalizeMetadataBulk(tracks: rustTracksToNormalize);
      final trackIdToNormalized = {
        for (var i = 0; i < rustTracksToNormalize.length; i++)
          rustTracksToNormalize[i].id: normalizedRustTracks[i]
      };

      // 4. Process All Tracks (Reverse to give newer tracks higher IDs)
      final tracksToSave = <Track>[];
      _ref.read(syncProgressProvider.notifier).state =
          'Preparing ${syncResult.tracks.length} tracks...';

      for (final rustTrack in syncResult.tracks.reversed) {
        final existingTrack = await isar.tracks
            .filter()
            .spotifyIdEqualTo(rustTrack.id)
            .or()
            .group((q) => q.titleEqualTo(rustTrack.title).and().artistEqualTo(rustTrack.artist))
            .findFirst();

        final normalized = trackIdToNormalized[rustTrack.id]!;

        final track = Track()
          ..id = existingTrack?.id ?? Isar.autoIncrement
          ..spotifyId = rustTrack.id
          ..title = normalized.title
          ..artist = normalized.artist
          ..durationMs = rustTrack.durationMs.toInt()
          ..albumArtUrl = rustTrack.artworkUrl
          ..youtubeId = existingTrack?.youtubeId
          ..localPath = existingTrack?.localPath
          ..lyrics = existingTrack?.lyrics
          ..isFavorite = likedTrackIds.contains(rustTrack.id)
          ..inLibrary = true;

        tracksToSave.add(track);
      }

      _ref.read(syncProgressProvider.notifier).state =
          'Committing changes to database...';
      await isar.writeTxn(() async {
        await isar.tracks.putAll(tracksToSave);
        await isar.playlists.putAll(playlistsToSave);
      });

      _ref.read(syncProgressProvider.notifier).state = 'Sync completed!';
    } on DioException catch (e) {
      final statusCode = e.response?.statusCode;
      final detail =
          e.response?.data?.toString() ?? e.message ?? 'Unknown error';
      _log.e('Sync Dio error [$statusCode]: $detail');
      _ref.read(syncProgressProvider.notifier).state =
          'Sync failed: Spotify API error ${statusCode ?? ''} $detail'.trim();
    } catch (e) {
      _log.e('Sync error: $e');
      _ref.read(syncProgressProvider.notifier).state = 'Sync failed: $e';
    } finally {
      await Future<void>.delayed(const Duration(seconds: 1));
      _ref.read(isSyncingProvider.notifier).state = false;
    }
  }
}
