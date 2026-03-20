import 'package:dio/dio.dart';
import 'package:spectrum/core/db/schemas/track_schema.dart';

class LyricsApi {
  static const _baseUrl = 'https://lrclib.net/api';
  static const _lyricsOvhBaseUrl = 'https://api.lyrics.ovh/v1';

  final Dio _dio = Dio(
    BaseOptions(
      baseUrl: _baseUrl,
      connectTimeout: const Duration(seconds: 5),
      receiveTimeout: const Duration(seconds: 8),
    ),
  );

  Future<String?> fetchLyrics(Track track) async {
    final title = track.title.trim();
    final artist = track.artist.trim();
    if (title.isEmpty || artist.isEmpty) return null;

    final direct = await _fetchFromLrcLibGet(track);
    if (direct != null) return direct;

    final search = await _fetchFromLrcLibSearch(track);
    if (search != null) return search;

    final ovh = await _fetchFromLyricsOvh(track);
    if (ovh != null) return ovh;

    return null;
  }

  Future<String?> _fetchFromLrcLibGet(Track track) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '/get',
        queryParameters: {
          'track_name': track.title.trim(),
          'artist_name': track.artist.trim(),
          if (track.album != null && track.album!.trim().isNotEmpty) 'album_name': track.album!.trim(),
          if (track.durationMs > 0) 'duration': (track.durationMs / 1000).round(),
        },
      );
      return _extractBestLyrics(response.data);
    } on DioException {
      return null;
    } catch (_) {
      return null;
    }
  }

  Future<String?> _fetchFromLrcLibSearch(Track track) async {
    try {
      final response = await _dio.get<List<dynamic>>(
        '/search',
        queryParameters: {
          'track_name': track.title.trim(),
          'artist_name': track.artist.trim(),
        },
      );
      final list = response.data;
      if (list == null || list.isEmpty) return null;
      for (final item in list) {
        if (item is! Map<String, dynamic>) continue;
        final lyrics = _extractBestLyrics(item);
        if (lyrics != null) return lyrics;
      }
    } on DioException {
      return null;
    } catch (_) {
      return null;
    }
    return null;
  }

  Future<String?> _fetchFromLyricsOvh(Track track) async {
    try {
      final response = await Dio(
        BaseOptions(
          baseUrl: _lyricsOvhBaseUrl,
          connectTimeout: const Duration(seconds: 5),
          receiveTimeout: const Duration(seconds: 8),
        ),
      ).get<Map<String, dynamic>>(
        '/${Uri.encodeComponent(track.artist.trim())}/${Uri.encodeComponent(track.title.trim())}',
      );
      final lyrics = (response.data?['lyrics'] as String?)?.trim();
      if (lyrics != null && lyrics.isNotEmpty) return lyrics;
    } on DioException {
      return null;
    } catch (_) {
      return null;
    }
    return null;
  }

  String? _extractBestLyrics(Map<String, dynamic>? data) {
    if (data == null) return null;
    final syncedLyrics = (data['syncedLyrics'] as String?)?.trim();
    if (_hasLrcTimestamps(syncedLyrics)) {
      return syncedLyrics;
    }
    final plainLyrics = (data['plainLyrics'] as String?)?.trim();
    if (plainLyrics != null && plainLyrics.isNotEmpty) {
      return plainLyrics;
    }
    if (syncedLyrics != null && syncedLyrics.isNotEmpty) {
      return syncedLyrics;
    }
    return null;
  }

  bool _hasLrcTimestamps(String? value) {
    if (value == null || value.isEmpty) return false;
    final ts = RegExp(r'^\[\d{1,2}:\d{2}(?:[.:]\d{1,3})?\]', multiLine: true);
    return ts.hasMatch(value);
  }
}
