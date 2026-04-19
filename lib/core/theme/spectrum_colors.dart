import 'package:flutter/material.dart';

/// Spectrum Global Design System: Crimson Obsidian
/// Centralized color palette for the entire application.
class SpectrumColors {
  // Core Surfaces (Now Dynamic)
  static Color background = const Color(0xFF010000);
  static Color surface = const Color(0xFF030000);
  static Color card = const Color(0xFF050505);

  // Accents
  static Color accent = const Color(0xFFFF0055);
  static Color accentSecondary = const Color(0xFF8B0000);
  static Color accentMuted = const Color(0x33FF0055); // Pre-computed withOpacity(0.2)

  // Logic & Status
  static Color success = const Color(0xFF00FF66);
  static Color warning = const Color(0xFFFFCC00);
  static Color error = const Color(0xFFFF0055);

  // Text Hierarchy (Baked for performance)
  static Color textPrimary = Colors.white;
  static Color textSecondary = const Color(0xB3FFFFFF); // 70% opacity
  static Color textMuted = const Color(0x3DFFFFFF); // 24% opacity
  static Color textUltraMuted = const Color(0x1FFFFFFF); // 12% opacity

  // Overlays & Borders (Baked)
  static Color border = const Color(0x26FF0055); // 15% accent fallback
  static Color borderStrong = const Color(0x4DFF0055); // 30% accent fallback
  static Color divider = const Color(0x0DFFFFFF); // 5% white
  static Color hudLabel = const Color(0x66FFFFFF); // 40% white
  static Color glassOverlay = const Color(0x0F000000);

  /// Entirely replaces the current theme colors with new values
  static void applyTheme({
    required Color bg,
    required Color surf,
    required Color crd,
    required Color primary,
    required Color textP,
    required Color textS,
    required Color brdr,
  }) {
    background = bg;
    surface = surf;
    card = crd;
    accent = primary;
    accentSecondary = primary.withOpacity(0.5);
    accentMuted = primary.withOpacity(0.2);
    textPrimary = textP;
    textSecondary = textS;
    border = brdr;
    borderStrong = brdr.withOpacity(0.3);
    error = primary;
  }

  /// Legacy update method for backward compatibility
  static void updateTheme(Color primary) {
    applyTheme(
      bg: background,
      surf: surface,
      crd: card,
      primary: primary,
      textP: textPrimary,
      textS: textSecondary,
      brdr: primary.withOpacity(0.15),
    );
  }

  // Assets & Fallbacks
  static const String fallbackArtworkUrl =
      'https://images.unsplash.com/photo-1614613535308-eb5fbd3d2c17?q=80&w=500&auto=format&fit=crop';

  static Widget artworkErrorPlaceholder({double size = 48}) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: surface,
        border: Border.all(color: accent.withOpacity(0.1), width: 1),
      ),
      child: Center(
        child: Icon(Icons.music_note_rounded,
            color: accent.withOpacity(0.2), size: size * 0.5),
      ),
    );
  }
}
