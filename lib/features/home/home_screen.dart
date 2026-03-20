import 'package:flutter/material.dart';
import 'package:spectrum/features/dj/dj_station_screen.dart';
import 'package:spectrum/features/library/library_screen.dart';
import 'package:spectrum/features/settings/settings_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isCompact = constraints.maxWidth < 900;
        final content = switch (_selectedIndex) {
          0 => const LibraryScreen(),
          1 => const DjStationScreen(),
          _ => const SettingsScreen(),
        };

        if (isCompact) {
          return Scaffold(
            backgroundColor: const Color(0xFF0F0F0F),
            body: content,
            bottomNavigationBar: NavigationBar(
              backgroundColor: const Color(0xFF0A0A0A),
              selectedIndex: _selectedIndex,
              onDestinationSelected: (index) => setState(() => _selectedIndex = index),
              destinations: const [
                NavigationDestination(
                  icon: Icon(Icons.library_music_outlined),
                  selectedIcon: Icon(Icons.library_music),
                  label: 'Library',
                ),
                NavigationDestination(
                  icon: Icon(Icons.graphic_eq_outlined),
                  selectedIcon: Icon(Icons.graphic_eq),
                  label: 'DJ',
                ),
                NavigationDestination(
                  icon: Icon(Icons.settings_outlined),
                  selectedIcon: Icon(Icons.settings),
                  label: 'Settings',
                ),
              ],
            ),
          );
        }

        return Scaffold(
          backgroundColor: const Color(0xFF0F0F0F),
          body: Row(
            children: [
              NavigationRail(
                backgroundColor: const Color(0xFF0A0A0A),
                selectedIndex: _selectedIndex,
                labelType: NavigationRailLabelType.all,
                selectedIconTheme: const IconThemeData(color: Colors.white, size: 28),
                unselectedIconTheme: const IconThemeData(color: Colors.white54, size: 24),
                selectedLabelTextStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                unselectedLabelTextStyle: const TextStyle(color: Colors.white54, fontSize: 12),
                onDestinationSelected: (index) => setState(() => _selectedIndex = index),
                destinations: const [
                  NavigationRailDestination(
                    icon: Icon(Icons.library_music_outlined),
                    selectedIcon: Icon(Icons.library_music),
                    label: Text('Library'),
                  ),
                  NavigationRailDestination(
                    icon: Icon(Icons.graphic_eq_outlined),
                    selectedIcon: Icon(Icons.graphic_eq),
                    label: Text('DJ'),
                  ),
                  NavigationRailDestination(
                    icon: Icon(Icons.settings_outlined),
                    selectedIcon: Icon(Icons.settings),
                    label: Text('Settings'),
                  ),
                ],
              ),
              Expanded(child: content),
            ],
          ),
        );
      },
    );
  }
}
