import 'package:dio/dio.dart';
import 'package:logger/logger.dart';

/// Spectrum backend API client.
/// Used to share and retrieve ISRC mappings from the community cloud cache.
class SpectrumApi {
  // TODO: Replace with your deployed backend URL
  static const _baseUrl = 'http://localhost:3000/api';

  final _dio = Dio(BaseOptions(
    baseUrl: _baseUrl,
    connectTimeout: const Duration(seconds: 5),
    receiveTimeout: const Duration(seconds: 10),
  ));
  final _log = Logger();

  /// Lookup a mapping from the cloud by ISRC.
  /// Returns null if not found or network unavailable.
  Future<Map<String, dynamic>?> getMappingByIsrc(String isrc) async {
    try {
      final response = await _dio.get('/isrc/$isrc');
      return response.data;
    } on DioException catch (e) {
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout ||
          e.type == DioExceptionType.connectionError) {
        _log.w('SpectrumAPI offline, skipping cloud lookup for $isrc');
        return null;
      }
      if (e.response?.statusCode == 404) return null;
      _log.e('SpectrumAPI error: $e');
      return null;
    }
  }

  /// Upload a new or updated ISRC mapping to the cloud.
  /// Fire-and-forget: errors are logged but not thrown.
  Future<void> upsertMapping({
    required String isrc,
    required String title,
    required String artist,
    String? spotifyId,
    String? appleId,
    String? youtubeId,
    String? deezerId,
    String? tidalId,
  }) async {
    try {
      await _dio.put('/isrc/$isrc', data: {
        'isrc': isrc,
        'title': title,
        'artist': artist,
        if (spotifyId != null) 'spotify_id': spotifyId,
        if (appleId != null) 'apple_id': appleId,
        if (youtubeId != null) 'youtube_id': youtubeId,
        if (deezerId != null) 'deezer_id': deezerId,
        if (tidalId != null) 'tidal_id': tidalId,
      });
    } catch (e) {
      _log.w('Failed to upsert mapping to cloud (non-fatal): $e');
    }
  }
}
