import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:spectrum/features/auth/auth_guard.dart';
import 'package:spectrum/features/player/audio_player_service.dart';
import 'package:spectrum/core/theme/spectrum_colors.dart'; 
import 'package:spectrum/features/settings/settings_providers.dart';
import 'package:window_manager/window_manager.dart';
import 'package:spectrum/core/navigation/navigator_key.dart';
import 'package:spectrum/core/providers/layout_provider.dart';
import 'package:spectrum/features/player/neural_radio_provider.dart';

class SpectrumApp extends ConsumerWidget {
  const SpectrumApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeTrack = ref.watch(currentTrackProvider);
    final theme = ref.watch(spectrumThemeProvider);

    return MaterialApp(
      navigatorKey: globalNavigatorKey,
      title: 'Spectrum',
      debugShowCheckedModeBanner: false,
      theme: _buildTheme(),
      builder: (context, child) {
        final isDesktop =
            Platform.isWindows || Platform.isLinux || Platform.isMacOS;
        if (!isDesktop) return child!;

        final winWidth = MediaQuery.of(context).size.width;
        final isCompact = winWidth < 900;
        
        // Update shared layout state
        Future.microtask(() => ref.read(isCompactProvider.notifier).state = isCompact);

        return Scaffold(
          backgroundColor: Colors.transparent,
          body: Column(
            children: [
              // CRIMSON HUD TITLEBAR
              GestureDetector(
                onPanStart: (details) {
                  windowManager.startDragging();
                },
                child: Container(
                  height: 42,
                  decoration: BoxDecoration(
                    color: SpectrumColors.surface,
                    border: Border(
                      bottom:
                          BorderSide(color: SpectrumColors.border, width: 1.5),
                    ),
                  ),
                  child: Row(
                    children: [
                      const SizedBox(width: 16),
                      // Core Pulsar
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: SpectrumColors.accent,
                          borderRadius: BorderRadius.circular(1),
                          boxShadow: [
                            BoxShadow(
                                color: SpectrumColors.accent.withOpacity(0.5),
                                blurRadius: 10),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'SPECTRUM',
                        style: TextStyle(
                          color: SpectrumColors.textPrimary,
                          fontSize: 11,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 2.0,
                        ),
                      ),
                      const SizedBox(width: 20),
                      // Metadata HUD
                      if (activeTrack != null)
                        Expanded(
                          child: Row(
                            children: [
                              Text(
                                '[ NOW_PLAYING: ',
                                style: TextStyle(
                                    color: SpectrumColors.accent,
                                    fontSize: 9,
                                    fontFamily: 'monospace',
                                    fontWeight: FontWeight.bold),
                              ),
                              Flexible(
                                child: Text(
                                  '${activeTrack.title.toUpperCase()} // ${activeTrack.artist.toUpperCase()}',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                      color: SpectrumColors.textSecondary,
                                      fontSize: 9,
                                      fontFamily: 'monospace',
                                      letterSpacing: 1.0),
                                ),
                              ),
                              Text(
                                ' ]',
                                style: TextStyle(
                                    color: SpectrumColors.accent,
                                    fontSize: 9,
                                    fontFamily: 'monospace',
                                    fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        )
                      else
                        const Expanded(
                          child: Text(
                            '// SYSTEM_READY // WAITING_FOR_INPUT',
                            style: TextStyle(
                                color: Colors.white24,
                                fontSize: 9,
                                fontFamily: 'monospace',
                                letterSpacing: 1.5),
                          ),
                        ),

                      // Status Dashboard
                      const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _StatusTag(label: 'PCM', value: '48Khz'),
                          _StatusTag(label: 'LINK', value: 'ENCR'),
                        ],
                      ),
                      const SizedBox(width: 8),

                      // Crimson Window Button Variant
                      WindowCaptionButton.minimize(
                        brightness: Brightness.dark,
                        onPressed: () async => await windowManager.minimize(),
                      ),
                      WindowCaptionButton.maximize(
                        brightness: Brightness.dark,
                        onPressed: () async {
                          if (await windowManager.isMaximized()) {
                            await windowManager.unmaximize();
                          } else {
                            await windowManager.maximize();
                          }
                        },
                      ),
                      WindowCaptionButton.close(
                        brightness: Brightness.dark,
                        onPressed: () async => await windowManager.close(),
                      ),
                    ],
                  ),
                ),
              ),
              Expanded(
                child: child!,
              ),
            ],
          ),
        );
      },
      home: const AuthGuard(),
    );
  }

  ThemeData _buildTheme() {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: ColorScheme.dark(
        primary: SpectrumColors.accent,
        onPrimary: SpectrumColors.textPrimary,
        secondary: SpectrumColors.accentSecondary,
        surface: SpectrumColors.surface,
        onSurface: SpectrumColors.textPrimary,
        surfaceContainerHighest: SpectrumColors.card,
      ),
      scaffoldBackgroundColor: SpectrumColors.background,
      fontFamily: 'Inter',
      dividerTheme:
          DividerThemeData(color: SpectrumColors.divider, thickness: 1),
      cardTheme: CardThemeData(
        color: SpectrumColors.card.withOpacity(0.9),
        elevation: 0,
        shape: RoundedRectangleBorder(
          side: BorderSide(color: SpectrumColors.border, width: 1),
          borderRadius: BorderRadius.circular(4),
        ),
      ),
      textTheme: TextTheme(
        headlineLarge: TextStyle(
            fontWeight: FontWeight.w900,
            letterSpacing: -1.0,
            color: SpectrumColors.textPrimary),
        headlineMedium: TextStyle(
            fontWeight: FontWeight.w800,
            letterSpacing: -0.5,
            color: SpectrumColors.textPrimary),
        titleMedium: TextStyle(
            fontWeight: FontWeight.w700,
            color: SpectrumColors.textPrimary,
            letterSpacing: 0.5),
        bodyMedium: const TextStyle(
            color: Colors.white70,
            letterSpacing: 0.2), 
      ),
    );
  }
}

class _StatusTag extends StatelessWidget {
  final String label;
  final String value;
  const _StatusTag({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        border: Border.all(color: SpectrumColors.divider),
        borderRadius: BorderRadius.circular(2),
      ),
      child: Row(
        children: [
          Text(label,
              style: TextStyle(
                  color: SpectrumColors.textMuted,
                  fontSize: 7,
                  fontWeight: FontWeight.bold)),
          const SizedBox(width: 4),
          Text(
              value,
              style: TextStyle(
                  color: SpectrumColors.accent,
                  fontSize: 7,
                  fontWeight: FontWeight.w900)),
        ],
      ),
    );
  }
}
