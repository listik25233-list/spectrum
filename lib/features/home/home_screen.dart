import 'package:flutter/material.dart';
import 'package:spectrum/features/dj/dj_station_screen.dart';
import 'package:spectrum/features/home/dashboard_screen.dart';
import 'package:spectrum/features/library/library_screen.dart';
import 'package:spectrum/features/search/search_screen.dart';
import 'package:spectrum/features/settings/settings_screen.dart';
import 'package:spectrum/features/player/mini_player.dart';
import 'package:spectrum/features/jam/jam_screen.dart';
import 'package:spectrum/core/theme/spectrum_colors.dart';
import 'package:spectrum/features/player/audio_player_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:window_manager/window_manager.dart';
import 'dart:ui';
import 'dart:io';
import 'package:spectrum/core/providers/layout_provider.dart';
import 'package:spectrum/features/player/mini_player.dart';
import 'package:spectrum/features/player/audio_player_service.dart';
import 'package:spectrum/features/settings/settings_providers.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    final isCompact = ref.watch(isCompactProvider);
        final content = switch (_selectedIndex) {
          0 => const DashboardScreen(),
          1 => const SearchScreen(),
          2 => const LibraryScreen(),
          3 => const DjStationScreen(),
          4 => const JamSessionScreen(),
          _ => const SettingsScreen(),
        };

        return Scaffold(
          backgroundColor: const Color(0xFF050508),
          extendBody: true,
          body: Row(
            children: [
              if (!isCompact) _buildNavigationRail(),
              Expanded(
                child: Stack(
                  children: [
                    // TOP LAYER CONTENT
                    KeyedSubtree(
                      key: ValueKey(_selectedIndex),
                      child: content,
                    ),
                    
                    // PERSISTENT MINI PLAYER (Internal to HomeScreen Stack for stability)
                    Positioned(
                      left: isCompact ? 0 : 16,
                      right: isCompact ? 0 : 16,
                      bottom: isCompact ? 65 : 24,
                      child: MiniPlayer(isIsland: !isCompact),
                    ),
                  ],
                ),
              ),
            ],
          ),
          bottomNavigationBar: isCompact ? _buildFusionNavBar() : null,
        );
  }

  Widget _buildFusionNavBar() {
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 25, sigmaY: 25),
        child: Container(
          decoration: BoxDecoration(
            color: const Color(0xFF0A0A0F).withOpacity(0.7),
            border: Border(
              top: BorderSide(color: Colors.white.withOpacity(0.05), width: 1),
              bottom: BorderSide(
                  color: SpectrumColors.accent, width: 2), // RED BOTTOM SYNC
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              NavigationBarTheme(
                data: NavigationBarThemeData(
                  indicatorColor: SpectrumColors.accent.withOpacity(0.1),
                  iconTheme: WidgetStateProperty.resolveWith((states) {
                    if (states.contains(WidgetState.selected)) {
                      return IconThemeData(
                          color: SpectrumColors.accent, size: 28);
                    }
                    return IconThemeData(
                        color: Colors.white.withOpacity(0.35), size: 24);
                  }),
                  labelTextStyle: WidgetStateProperty.resolveWith((states) {
                    final style = TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 1.0,
                        color: Colors.white.withOpacity(0.35));
                    if (states.contains(WidgetState.selected)) {
                      return style.copyWith(
                          color: SpectrumColors.textPrimary,
                          fontWeight: FontWeight.w800);
                    }
                    return style;
                  }),
                ),
                child: NavigationBar(
                  backgroundColor: Colors.transparent,
                  height: 65,
                  elevation: 0,
                  selectedIndex: _selectedIndex,
                  onDestinationSelected: (index) =>
                      setState(() => _selectedIndex = index),
                  destinations: const [
                    NavigationDestination(
                      icon: Icon(Icons.grid_view_outlined),
                      selectedIcon: Icon(Icons.grid_view_rounded),
                      label: 'DASH',
                    ),
                    NavigationDestination(
                      icon: Icon(Icons.search_outlined),
                      selectedIcon: Icon(Icons.search_rounded),
                      label: 'SEARCH',
                    ),
                    NavigationDestination(
                      icon: Icon(Icons.library_music_outlined),
                      selectedIcon: Icon(Icons.library_music_rounded),
                      label: 'LIB',
                    ),
                    NavigationDestination(
                      icon: Icon(Icons.auto_awesome_outlined),
                      selectedIcon: Icon(Icons.auto_awesome_rounded),
                      label: 'DJ',
                    ),
                    NavigationDestination(
                      icon: Icon(Icons.hub_outlined),
                      selectedIcon: Icon(Icons.hub_rounded),
                      label: 'JAM',
                    ),
                    NavigationDestination(
                      icon: Icon(Icons.settings_outlined),
                      selectedIcon: Icon(Icons.settings_rounded),
                      label: 'OPTS',
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavigationRail() {
    return Container(
      width: 72,
      decoration: BoxDecoration(
        color: const Color(0xFF050508),
        border: Border(
          right: BorderSide(color: Colors.white.withOpacity(0.05), width: 1),
          left: BorderSide(
              color: SpectrumColors.accent, width: 2), // RED LEFT SYNC
        ),
      ),
      child: NavigationRail(
        backgroundColor: Colors.transparent,
        selectedIndex: _selectedIndex,
        useIndicator: true,
        indicatorColor: SpectrumColors.accent.withOpacity(0.12),
        indicatorShape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
        extended: false,
        labelType: NavigationRailLabelType.all,
        selectedIconTheme:
            IconThemeData(color: SpectrumColors.accent, size: 26),
        unselectedIconTheme:
            IconThemeData(color: Colors.white.withOpacity(0.2), size: 22),
        selectedLabelTextStyle: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w800,
            fontSize: 9,
            letterSpacing: 1),
        unselectedLabelTextStyle: TextStyle(
            color: Colors.white.withOpacity(0.2),
            fontSize: 8,
            fontWeight: FontWeight.w500,
            letterSpacing: 1),
        onDestinationSelected: (index) =>
            setState(() => _selectedIndex = index),
        destinations: const [
          NavigationRailDestination(
            icon: Icon(Icons.grid_view_rounded),
            selectedIcon: Icon(Icons.grid_view_rounded),
            label: Text('DASH'),
          ),
          NavigationRailDestination(
            icon: Icon(Icons.search_rounded),
            selectedIcon: Icon(Icons.search_rounded),
            label: Text('SEARCH'),
          ),
          NavigationRailDestination(
            icon: Icon(Icons.blur_on_rounded),
            selectedIcon: Icon(Icons.blur_on_rounded),
            label: Text('LIB'),
          ),
          NavigationRailDestination(
            icon: Icon(Icons.auto_awesome_mosaic_rounded),
            selectedIcon: Icon(Icons.auto_awesome_mosaic_rounded),
            label: Text('DJ'),
          ),
          NavigationRailDestination(
            icon: Icon(Icons.hub_rounded),
            selectedIcon: Icon(Icons.hub_rounded),
            label: Text('JAM'),
          ),
          NavigationRailDestination(
            icon: Icon(Icons.vignette_rounded),
            selectedIcon: Icon(Icons.vignette_rounded),
            label: Text('OPTS'),
          ),
        ],
      ),
    );
  }
}

