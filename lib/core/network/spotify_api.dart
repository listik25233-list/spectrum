import 'package:dio/dio.dart';
import 'package:isar/isar.dart';
import 'package:spectrum/core/db/isar_service.dart';
import 'package:spectrum/core/db/schemas/auth_token_schema.dart';
import 'package:logger/logger.dart';

class SpotifyApi {
  static const _baseUrl = 'https://api.spotify.com/v1';
  static const _accountsUrl = 'https://accounts.spotify.com';

  // TODO: Replace with your Spotify Developer Dashboard credentials
  static const clientId = 'c5e7218d856e463aa2582a535fea4596';
  static const redirectUri = 'http://127.0.0.1:8888/callback';
  static const scopes = [
    'user-library-read',
    'user-library-modify',
    'playlist-read-private',
    'playlist-modify-public',
    'playlist-modify-private',
    'user-read-playback-state',
    'user-modify-playback-state',
  ];

  final _dio = Dio(BaseOptions(baseUrl: _baseUrl));
  final _log = Logger();

  SpotifyApi() {
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final token = await _getToken();
        if (token != null) {
          options.headers['Authorization'] = 'Bearer ${token.accessToken}';
        }
        handler.next(options);
      },
      onError: (error, handler) async {
        if (error.response?.statusCode == 401 && error.requestOptions.extra['isRetry'] != true) {
          final success = await _refreshToken();
          if (success) {
            error.requestOptions.extra['isRetry'] = true;
            try {
              final response = await _retry(error.requestOptions);
              handler.resolve(response);
            } on DioException catch (e) {
              handler.next(e);
            }
          } else {
            // Delete invalid token to force re-login
            final isar = IsarService.instance;
            await isar.writeTxn(() async {
              await isar.authTokens.filter().serviceEqualTo('spotify').deleteAll();
            });
            handler.next(error);
          }
        } else {
          handler.next(error);
        }
      },
    ));
  }

  Future<AuthToken?> _getToken() async {
    final isar = IsarService.instance;
    return isar.authTokens.where().serviceEqualTo('spotify').findFirst();
  }

  Future<bool> _refreshToken() async {
    final token = await _getToken();
    if (token?.refreshToken == null) return false;

    try {
      final response = await Dio().post(
        '$_accountsUrl/api/token',
        data: {
          'grant_type': 'refresh_token',
          'refresh_token': token!.refreshToken,
          'client_id': clientId,
        },
        options: Options(
          contentType: Headers.formUrlEncodedContentType,
        ),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final isar = IsarService.instance;
        await isar.writeTxn(() async {
          token
            ..accessToken = response.data['access_token']
            ..expiresAt = DateTime.now()
                .add(Duration(seconds: response.data['expires_in']));
          if (response.data['refresh_token'] != null) {
            token.refreshToken = response.data['refresh_token'];
          }
          await isar.authTokens.put(token);
        });
        return true;
      }
      return false;
    } catch (e) {
      _log.e('Failed to refresh Spotify token: $e');
      return false;
    }
  }

  Future<Response<dynamic>> _retry(RequestOptions requestOptions) {
    return _dio.request(
      requestOptions.path,
      data: requestOptions.data,
      queryParameters: requestOptions.queryParameters,
      options: Options(method: requestOptions.method),
    );
  }

  /// Fetch the current user's saved tracks (liked songs)
  /// Returns all tracks with pagination handled automatically.
  Future<List<Map<String, dynamic>>> getSavedTracks({int limit = 50}) async {
    final tracks = <Map<String, dynamic>>[];
    final seenIds = <String>{};
    final seenTitleArtist = <String>{};
    String? nextUrl = '/me/tracks?limit=$limit&market=from_token';

    while (nextUrl != null) {
      final path = nextUrl.startsWith('http')
          ? nextUrl.replaceFirst(_baseUrl, '')
          : nextUrl;

      final response = await _dio.get(path);
      final items = response.data['items'] as List;

      for (final item in items) {
        final track = item['track'] as Map<String, dynamic>;
        
        final trackId = track['id'] as String?;
        final title = track['name'] as String? ?? '';
        final artistsData = track['artists'] as List?;
        final artist = artistsData?.firstOrNull?['name'] as String? ?? '';
        final titleArtistKey = '${title.toLowerCase()}_${artist.toLowerCase()}';

        if (trackId != null && seenIds.contains(trackId)) continue;
        if (seenTitleArtist.contains(titleArtistKey)) continue;

        if (trackId != null) seenIds.add(trackId);
        seenTitleArtist.add(titleArtistKey);

        tracks.add(track);
      }

      nextUrl = response.data['next'];
    }

    return tracks;
  }

  /// Get a single track's full details including ISRC
  Future<Map<String, dynamic>?> getTrack(String spotifyId) async {
    try {
      final response = await _dio.get('/tracks/$spotifyId');
      return response.data;
    } catch (e) {
      _log.e('Failed to get track $spotifyId: $e');
      return null;
    }
  }

  /// Extract ISRC from a track object returned by the API
  static String? extractIsrc(Map<String, dynamic> track) {
    return track['external_ids']?['isrc'];
  }

  /// Search for a track by name and artist (fallback when ISRC not available)
  Future<List<Map<String, dynamic>>> search(String query,
      {int limit = 15}) async {
    final response = await _dio.get('/search', queryParameters: {
      'q': query,
      'type': 'track',
      'limit': limit,
      'market': 'from_token',
    });
    
    final items = List<Map<String, dynamic>>.from(
        response.data['tracks']['items'] ?? []);
        
    final tracks = <Map<String, dynamic>>[];
    final seenIds = <String>{};
    final seenTitleArtist = <String>{};
    
    for (final track in items) {
      final trackId = track['id'] as String?;
      final title = track['name'] as String? ?? '';
      final artistsData = track['artists'] as List?;
      final artist = artistsData?.firstOrNull?['name'] as String? ?? '';
      final titleArtistKey = '${title.toLowerCase()}_${artist.toLowerCase()}';

      if (trackId != null && seenIds.contains(trackId)) continue;
      if (seenTitleArtist.contains(titleArtistKey)) continue;

      if (trackId != null) seenIds.add(trackId);
      seenTitleArtist.add(titleArtistKey);

      tracks.add(track);
    }
    
    return tracks;
  }

  /// Get all playlists for the current user
  Future<List<Map<String, dynamic>>> getUserPlaylists() async {
    final playlists = <Map<String, dynamic>>[];
    String? nextUrl = '/me/playlists?limit=50';

    while (nextUrl != null) {
      final path = nextUrl.startsWith('http')
          ? nextUrl.replaceFirst(_baseUrl, '')
          : nextUrl;
      final response = await _dio.get(path);
      playlists.addAll(List<Map<String, dynamic>>.from(
          response.data['items'] ?? []));
      nextUrl = response.data['next'];
    }

    return playlists;
  }

  /// Get all tracks from a specific playlist
  Future<List<Map<String, dynamic>>> getPlaylistTracks(String playlistId, {int limit = 50}) async {
    final tracks = <Map<String, dynamic>>[];
    final seenIds = <String>{};
    final seenTitleArtist = <String>{};
    String? nextUrl = '/playlists/$playlistId/tracks?limit=$limit&market=from_token';

    while (nextUrl != null) {
      final path = nextUrl.startsWith('http')
          ? nextUrl.replaceFirst(_baseUrl, '')
          : nextUrl;

      try {
        final response = await _dio.get(path);
        final items = response.data['items'] as List;

        for (final item in items) {
          if (item['track'] != null) {
            final track = item['track'] as Map<String, dynamic>;
            final trackId = track['id'] as String?;
            final title = track['name'] as String? ?? '';
            final artistsData = track['artists'] as List?;
            final artist = artistsData?.firstOrNull?['name'] as String? ?? '';
            final titleArtistKey = '${title.toLowerCase()}_${artist.toLowerCase()}';

            if (trackId != null && seenIds.contains(trackId)) continue;
            if (seenTitleArtist.contains(titleArtistKey)) continue;

            if (trackId != null) seenIds.add(trackId);
            seenTitleArtist.add(titleArtistKey);

            tracks.add(track);
          }
        }

        nextUrl = response.data['next'];
      } catch (e) {
        _log.e('Failed to get playlist tracks $playlistId: $e');
        break;
      }
    }

    return tracks;
  }
}
