import 'package:spectrum/src/rust/api/lyrics.dart' as rust_lyrics;
import 'package:spectrum/core/db/schemas/track_schema.dart';
import 'package:flutter/foundation.dart';

class LyricsApi {
  Future<String?> fetchLyrics(Track track) async {
    final title = track.title.trim();
    final artist = track.artist.trim();
    if (title.isEmpty || artist.isEmpty) return null;

    try {
      final rustResult = await rust_lyrics.getLyrics(
        title: title,
        artist: artist,
        album: track.album,
        durationMs: track.durationMs.toInt(),
      );

      if (rustResult != null) {
        debugPrint('[Lyrics] Fetched from Rust: ${rustResult.source}');
        return rustResult.content;
      }
    } catch (e) {
      debugPrint('[Lyrics] Rust engine error: $e');
    }

    return null;
  }

  Future<List<rust_lyrics.SpectrumLyrics>> fetchAllLyrics(Track track) async {
    final title = track.title.trim();
    final artist = track.artist.trim();
    if (title.isEmpty || artist.isEmpty) return [];

    try {
      return await rust_lyrics.getAllLyrics(
        title: title,
        artist: artist,
        album: track.album,
        durationMs: track.durationMs.toInt(),
      );
    } catch (e) {
      debugPrint('[Lyrics] Rust fetchAll error: $e');
      return [];
    }
  }
}
