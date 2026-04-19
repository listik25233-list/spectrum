import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:palette_generator/palette_generator.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:spectrum/features/player/audio_player_service.dart';

final dominantColorProvider = FutureProvider<Color?>((ref) async {
  final track = ref.watch(currentTrackProvider);
  if (track == null) return null;

  // 1. Try to use the pre-calculated color from Rust/Isar
  if (track.dominantColor != null) {
    try {
      final colorStr = track.dominantColor!.replaceFirst('#', 'ff');
      return Color(int.parse(colorStr, radix: 16));
    } catch (e) {
      print('[DominantColorProvider] Failed to parse hex: ${track.dominantColor}');
    }
  }

  // 2. Fallback to PaletteGenerator for remote images or un-processed local files
  if (track.albumArtUrl == null) return null;

  try {
    final imageProvider = CachedNetworkImageProvider(track.albumArtUrl!);
    final palette = await PaletteGenerator.fromImageProvider(
      imageProvider,
      maximumColorCount: 10,
    );

    // Look for a vibrant aesthetic color, fallback to dominant
    return palette.vibrantColor?.color ??
        palette.dominantColor?.color ??
        palette.mutedColor?.color;
  } catch (e) {
    return null;
  }
});

/// Returns a list of colors extracted from the artwork to build the Neural Aura
final auraPaletteProvider = FutureProvider<List<Color>>((ref) async {
  final track = ref.watch(currentTrackProvider);
  if (track == null || track.albumArtUrl == null) return [const Color(0xFF1E1E2E)];

  try {
    final imageProvider = CachedNetworkImageProvider(track.albumArtUrl!);
    final palette = await PaletteGenerator.fromImageProvider(
      imageProvider,
      maximumColorCount: 15,
    );

    final colors = <Color>{};
    if (palette.vibrantColor != null) colors.add(palette.vibrantColor!.color);
    if (palette.lightVibrantColor != null) colors.add(palette.lightVibrantColor!.color);
    if (palette.darkVibrantColor != null) colors.add(palette.darkVibrantColor!.color);
    if (palette.mutedColor != null) colors.add(palette.mutedColor!.color);
    if (palette.dominantColor != null) colors.add(palette.dominantColor!.color);

    // If we have too few colors, add some variations
    if (colors.length < 3) {
      final base = colors.isNotEmpty ? colors.first : const Color(0xFF1E1E2E);
      colors.add(base.withOpacity(0.8));
      colors.add(HSLColor.fromColor(base).withHue((HSLColor.fromColor(base).hue + 30) % 360).toColor());
    }

    return colors.toList();
  } catch (e) {
    return [const Color(0xFF1E1E2E)];
  }
});
