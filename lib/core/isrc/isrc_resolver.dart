import 'dart:convert';

import 'package:logger/logger.dart';
import 'package:spectrum/core/db/isar_service.dart';
import 'package:spectrum/core/db/schemas/track_schema.dart';
import 'package:spectrum/core/network/spotify_api.dart';
import 'package:spectrum/core/network/spectrum_api.dart';

/// Resolves a track's cross-service IDs using a 3-layer cache strategy:
///   Layer 1: Local Isar DB  (instant, always available)
///   Layer 2: Cloud PostgreSQL via SpectrumApi (fast, community cache)
///   Layer 3: Spotify API  (ground truth, counts against rate limit)
///
/// Every newly discovered mapping is saved to BOTH Layer 1 and Layer 2.
class IsrcResolver {
  final SpotifyApi _spotify;
  final SpectrumApi _cloud;
  final _log = Logger();

  IsrcResolver(this._spotify, this._cloud);

  /// Given a Spotify track object, resolve its full cross-service mapping.
  /// Returns the Track saved to Isar (new or updated).
  Future<Track?> resolveFromSpotifyTrack(
      Map<String, dynamic> spotifyTrack) async {
    final spotifyId = spotifyTrack['id'] as String?;
    final isrc = SpotifyApi.extractIsrc(spotifyTrack) ??
        await _fetchIsrcFromSpotify(spotifyId);

    if (isrc == null) {
      _log.w('No ISRC found for track: ${spotifyTrack['name']}');
      // TODO: fallback to fuzzy matching
      return null;
    }

    // Layer 1: Check local Isar
    final isar = IsarService.instance;
    Track? existing =
        await isar.tracks.where().isrcEqualTo(isrc).findFirst();

    if (existing != null) {
      _log.d('ISRC cache hit (Isar): $isrc');
      // Update Spotify ID if not already set
      if (existing.spotifyId == null && spotifyId != null) {
        await isar.writeTxn(() async {
          existing.spotifyId = spotifyId;
          if (!existing.availableOn.contains('spotify')) {
            existing.availableOn = [...existing.availableOn, 'spotify'];
          }
          await isar.tracks.put(existing);
        });
      }
      return existing;
    }

    // Layer 2: Check cloud cache
    final cloudMapping = await _cloud.getMappingByIsrc(isrc);
    if (cloudMapping != null) {
      _log.d('ISRC cache hit (Cloud): $isrc');
      return _saveTrackFromMapping(spotifyTrack, isrc, cloudMapping);
    }

    // Layer 3: Build from Spotify data and save to both caches
    _log.d('ISRC cache miss, saving new mapping: $isrc');
    return _saveNewMapping(spotifyTrack, isrc, spotifyId);
  }

  Future<String?> _fetchIsrcFromSpotify(String? spotifyId) async {
    if (spotifyId == null) return null;
    final fullTrack = await _spotify.getTrack(spotifyId);
    return fullTrack != null ? SpotifyApi.extractIsrc(fullTrack) : null;
  }

  Future<Track> _saveNewMapping(
    Map<String, dynamic> spotifyTrack,
    String isrc,
    String? spotifyId,
  ) async {
    final track = Track()
      ..isrc = isrc
      ..title = spotifyTrack['name'] ?? ''
      ..artist = _joinArtists(spotifyTrack['artists'])
      ..album = spotifyTrack['album']?['name'] ?? ''
      ..durationMs = spotifyTrack['duration_ms'] ?? 0
      ..artworkUrl = _extractArtwork(spotifyTrack)
      ..spotifyId = spotifyId
      ..availableOn = ['spotify']
      ..likedOn = '{}'
      ..addedAt = DateTime.now();

    final isar = IsarService.instance;
    await isar.writeTxn(() => isar.tracks.put(track));

    // Upload to cloud asynchronously (fire-and-forget)
    _cloud.upsertMapping(
      isrc: isrc,
      title: track.title,
      artist: track.artist,
      spotifyId: spotifyId,
    );

    return track;
  }

  Future<Track> _saveTrackFromMapping(
    Map<String, dynamic> spotifyTrack,
    String isrc,
    Map<String, dynamic> cloudData,
  ) async {
    final track = Track()
      ..isrc = isrc
      ..title = cloudData['title'] ?? spotifyTrack['name'] ?? ''
      ..artist = cloudData['artist'] ?? _joinArtists(spotifyTrack['artists'])
      ..album = spotifyTrack['album']?['name'] ?? ''
      ..durationMs = spotifyTrack['duration_ms'] ?? 0
      ..artworkUrl = _extractArtwork(spotifyTrack)
      ..spotifyId = cloudData['spotify_id'] ?? spotifyTrack['id']
      ..appleId = cloudData['apple_id']
      ..youtubeId = cloudData['youtube_id']
      ..deezerId = cloudData['deezer_id']
      ..tidalId = cloudData['tidal_id']
      ..availableOn = _buildAvailableOn(cloudData)
      ..likedOn = '{}'
      ..addedAt = DateTime.now();

    final isar = IsarService.instance;
    await isar.writeTxn(() => isar.tracks.put(track));
    return track;
  }

  List<String> _buildAvailableOn(Map<String, dynamic> data) {
    return [
      if (data['spotify_id'] != null) 'spotify',
      if (data['apple_id'] != null) 'apple',
      if (data['youtube_id'] != null) 'youtube',
      if (data['deezer_id'] != null) 'deezer',
      if (data['tidal_id'] != null) 'tidal',
    ];
  }

  String _joinArtists(dynamic artists) {
    if (artists == null) return '';
    return (artists as List)
        .map((a) => a['name'] as String)
        .join(', ');
  }

  String? _extractArtwork(Map<String, dynamic> track) {
    final images = track['album']?['images'] as List?;
    if (images == null || images.isEmpty) return null;
    // Prefer medium image (index 1) if available
    return images.length > 1
        ? images[1]['url']
        : images[0]['url'];
  }
}
