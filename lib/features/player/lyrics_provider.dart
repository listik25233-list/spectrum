import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:spectrum/features/player/audio_player_service.dart';

class LyricLine {
  final Duration startTime;
  final String text;

  LyricLine({required this.startTime, required this.text});
}

/// State management for manual lyrics source selection
final manualLyricsOverrideProvider = StateProvider<List<LyricLine>?>((ref) => null);
final manualLyricsContentProvider = StateProvider<String?>((ref) => null);
final currentLyricsSourceProvider = StateProvider<String?>((ref) => null);

/// Parses LRC formatted lyrics into a list of [LyricLine]
final lyricsProvider = Provider<List<LyricLine>>((ref) {
  final contentOverride = ref.watch(manualLyricsContentProvider);
  if (contentOverride != null) {
     return parseLrcText(contentOverride);
  }

  final track = ref.watch(currentTrackProvider);
  final lyrics = track?.lyrics;
  if (lyrics == null || lyrics.isEmpty) return [];

  return parseLrcText(lyrics);
});

List<LyricLine> parseLrcText(String lyrics) {
  final List<LyricLine> lines = [];
  
  // Match [mm:ss.xx] or [mm:ss]
  final regex = RegExp(r'\[(\d{1,2}):(\d{1,2}(?:\.\d+)?)\](.*)');

  for (final rawLine in lyrics.split('\n')) {
    final match = regex.firstMatch(rawLine);
    if (match != null) {
      final min = int.parse(match.group(1)!);
      final sec = double.parse(match.group(2)!);
      final text = match.group(3)!.trim();
      
      if (text.isNotEmpty) {
        lines.add(LyricLine(
          startTime: Duration(milliseconds: (min * 60 * 1000 + sec * 1000).toInt()),
          text: text,
        ));
      }
    }
  }
  
  lines.sort((a, b) => a.startTime.compareTo(b.startTime));
  return lines;
}

/// Returns the index of the lyric line currently being played
final currentLyricIndexProvider = Provider<int>((ref) {
  final lines = ref.watch(lyricsProvider);
  if (lines.isEmpty) return -1;

  final position = ref.watch(playbackPositionProvider);
  final offset = Duration(milliseconds: ref.watch(lyricsSyncOffsetMsProvider));
  final adjustedPosition = position + offset;

  for (int i = lines.length - 1; i >= 0; i--) {
    if (adjustedPosition >= lines[i].startTime) {
      return i;
    }
  }
  return -1;
});
