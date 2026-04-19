import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:spectrum/features/auth/auth_service.dart';
import 'package:spectrum/features/settings/settings_providers.dart';
import 'package:spectrum/features/settings/storage_settings_screen.dart';
import 'package:spectrum/features/player/neural_radio_provider.dart';
import 'package:spectrum/core/theme/spectrum_colors.dart';
import 'package:spectrum/features/settings/theme_designer_screen.dart';
import 'package:spectrum/features/player/audio_player_service.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final highQualityAudio = ref.watch(highQualityAudioProvider);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverAppBar(
            expandedHeight: 100,
            collapsedHeight: 70,
            pinned: true,
            backgroundColor: SpectrumColors.background.withOpacity(0.85),
            elevation: 0,
            flexibleSpace: FlexibleSpaceBar(
              titlePadding:
                  const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              centerTitle: false,
              title: Text(
                'OPTIONS',
                style: TextStyle(
                  color: SpectrumColors.textPrimary,
                  fontWeight: FontWeight.w900,
                  fontSize: 20,
                  letterSpacing: 3.0,
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 120),
              child: Column(
                children: [
                  _buildSectionHeader('NEURAL_INTERFACE', 'THM-C01'),
                  _SettingsGroup(
                    children: [
                      _buildTile(
                        icon: Icons.palette_outlined,
                        color:
                            Color(ref.watch(spectrumThemeProvider).accentColor),
                        title: 'System Design Engine',
                        subtitle: 'Customize every coordinate of the HUD',
                        onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (c) => const ThemeDesignerScreen())),
                        trailing: _ColorIndicator(
                            color: Color(
                                ref.watch(spectrumThemeProvider).accentColor)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),
                  _buildSectionHeader('AUDIO_ORCHESTRATION', 'SR-96KHZ'),
                  _SettingsGroup(
                    children: [
                      _buildSwitchTile(
                        icon: Icons.bolt_rounded,
                        color: Colors.deepPurpleAccent,
                        title: 'Extreme Streaming',
                        subtitle: 'Lossless data whenever possible',
                        value: highQualityAudio,
                        onChanged: (v) => ref
                            .read(highQualityAudioProvider.notifier)
                            .updateValue(v),
                      ),
                      _buildSwitchTile(
                        icon: Icons.flare_rounded,
                        color: Colors.cyanAccent,
                        title: 'Hi-Fi Restoration (AI)',
                        subtitle: 'Real-time master-quality enhancement',
                        value: ref.watch(tidalEnhancementProvider),
                        onChanged: (v) => ref
                            .read(tidalEnhancementProvider.notifier)
                            .updateValue(v),
                      ),
                      if (Platform.isLinux ||
                          Platform.isWindows ||
                          Platform.isMacOS)
                        _buildSwitchTile(
                          icon: Icons.shutter_speed_rounded,
                          color: Colors.orangeAccent,
                          title: 'Spectrum Super-Res',
                          subtitle: 'Offline upscaling to 96kHz FLAC',
                          value: ref.watch(pcOfflineSuperResEnabledProvider),
                          onChanged: (v) => ref
                              .read(pcOfflineSuperResEnabledProvider.notifier)
                              .updateValue(v),
                        ),
                      _buildSwitchTile(
                        icon: Icons.auto_awesome_rounded,
                        color: Colors.pinkAccent,
                        title: 'Smart Crossfade (AI DJ)',
                        subtitle: 'Seamless transitions between tracks',
                        value: ref.watch(smartCrossfadeEnabledProvider),
                        onChanged: (v) => ref
                            .read(smartCrossfadeEnabledProvider.notifier)
                            .updateValue(v),
                      ),
                      if (ref.watch(smartCrossfadeEnabledProvider))
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text('Crossfade Duration',
                                      style: TextStyle(
                                          color: SpectrumColors.textMuted,
                                          fontSize: 12)),
                                  Text('${ref.watch(crossfadeDurationProvider)}s',
                                      style: TextStyle(
                                          color: SpectrumColors.textPrimary,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 12)),
                                ],
                              ),
                              Slider(
                                value: ref.watch(crossfadeDurationProvider).toDouble(),
                                min: 1.0,
                                max: 15.0,
                                divisions: 14,
                                activeColor: Colors.pinkAccent,
                                inactiveColor: SpectrumColors.surface,
                                onChanged: (v) {
                                  ref.read(crossfadeDurationProvider.notifier).updateValue(v.toInt());
                                },
                              ),
                            ],
                          ),
                        ),
                      _buildSwitchTile(
                        icon: Icons.graphic_eq_rounded,
                        color: Colors.greenAccent,
                        title: 'Loudness Normalization',
                        subtitle: 'Consistent volume across all tracks',
                        value: ref.watch(replayGainEnabledProvider),
                        onChanged: (v) => ref
                            .read(replayGainEnabledProvider.notifier)
                            .updateValue(v),
                      ),
                      _buildSwitchTile(
                        icon: Icons.auto_awesome_rounded,
                        color: Colors.deepPurpleAccent,
                        title: 'Neural Radio',
                        subtitle: 'Auto-fill queue with similar vibes',
                        value: ref.watch(neuralRadioEnabledProvider),
                        onChanged: (v) =>
                            ref.read(neuralRadioEnabledProvider.notifier).updateValue(v),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),
                  _buildSectionHeader('STORAGE_MATRICES', 'CACH-L1'),
                  _SettingsGroup(
                    children: [
                      _buildTile(
                        icon: Icons.memory_rounded,
                        color: Colors.amberAccent,
                        title: 'Cache Management',
                        subtitle: 'Analyze and purge downloaded sectors',
                        onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (c) => const StorageSettingsScreen())),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),
                  _buildSectionHeader('CREDENTIALS', 'SEC-SYNC'),
                  _SettingsGroup(
                    children: [
                      _buildTile(
                        icon: Icons.terminal_rounded,
                        color: Colors.lightGreenAccent,
                        title: 'Sync External Identity',
                        subtitle: 'Manage connected streaming accounts',
                        onTap: () =>
                            ref.read(authServiceProvider).loginWithSpotify(),
                      ),
                      _buildTile(
                        icon: Icons.power_settings_new_rounded,
                        color: Colors.redAccent,
                        title: 'Sever Connection',
                        subtitle: 'Reset and disconnect from system',
                        onTap: () => ref.read(authServiceProvider).logout(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 64),
                  const SizedBox(height: 32),
                  _buildSectionHeader('RECENT_ACTIVITY', 'HIST-LOG'),
                  _SettingsGroup(
                    children: [
                      Consumer(
                        builder: (context, ref, child) {
                          final recent = ref.watch(recentPlayedTracksProvider);
                          if (recent.isEmpty) {
                            return const Padding(
                              padding: EdgeInsets.all(16),
                              child: Text('No recent activity detected.',
                                  style: TextStyle(
                                      color: Colors.white24, fontSize: 11)),
                            );
                          }
                          return Column(
                            children: recent.take(5).map((track) {
                              return ListTile(
                                dense: true,
                                leading: Icon(Icons.history_rounded,
                                    color: SpectrumColors.accent.withOpacity(0.5),
                                    size: 16),
                                title: Text(track.title,
                                    style: const TextStyle(
                                        color: Colors.white70, fontSize: 12)),
                                subtitle: Text(track.artist.toUpperCase(),
                                    style: TextStyle(
                                        color: SpectrumColors.textUltraMuted,
                                        fontSize: 9)),
                              );
                            }).toList(),
                          );
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 64),
                  Text('SPECTRUM // CORE v1.0.0 // MASTER_EDITION',
                      style: TextStyle(
                          color: SpectrumColors.textUltraMuted,
                          fontSize: 9,
                          fontFamily: 'monospace',
                          letterSpacing: 2)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
 
  Widget _buildSectionHeader(String title, String id) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Text(title.toUpperCase(),
              style: TextStyle(
                  color: SpectrumColors.textMuted,
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.5)),
          const Spacer(),
          Text('[ $id ]',
              style: TextStyle(
                  color: SpectrumColors.textUltraMuted.withOpacity(0.3),
                  fontSize: 8,
                  fontFamily: 'monospace')),
        ],
      ),
    );
  }
 
  Widget _buildTile(
      {required IconData icon,
      required Color color,
      required String title,
      required String subtitle,
      required VoidCallback onTap,
      Widget? trailing}) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
            color: color.withOpacity(0.08),
            borderRadius: BorderRadius.circular(8)),
        child: Icon(icon, color: color, size: 22),
      ),
      title: Text(title,
          style: TextStyle(
              color: SpectrumColors.textPrimary,
              fontWeight: FontWeight.w800,
              fontSize: 14)),
      subtitle: Text(subtitle,
          style: TextStyle(color: SpectrumColors.textMuted, fontSize: 11)),
      trailing: trailing ??
          Icon(Icons.arrow_forward_ios_rounded,
              color: SpectrumColors.textUltraMuted, size: 12),
      onTap: onTap,
    );
  }
 
  Widget _buildSwitchTile(
      {required IconData icon,
      required Color color,
      required String title,
      required String subtitle,
      required bool value,
      required ValueChanged<bool> onChanged}) {
    return SwitchListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      activeThumbColor: SpectrumColors.accent,
      activeTrackColor: SpectrumColors.accent.withOpacity(0.3),
      inactiveTrackColor: SpectrumColors.surface,
      secondary: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
            color: color.withOpacity(0.08),
            borderRadius: BorderRadius.circular(8)),
        child: Icon(icon, color: color, size: 22),
      ),
      title: Text(title,
          style: TextStyle(
              color: SpectrumColors.textPrimary,
              fontWeight: FontWeight.w800,
              fontSize: 14)),
      subtitle: Text(subtitle,
          style: TextStyle(color: SpectrumColors.textMuted, fontSize: 11)),
      value: value,
      onChanged: onChanged,
    );
  }
}
 
class _SettingsGroup extends StatelessWidget {
  final List<Widget> children;
  const _SettingsGroup({required this.children});
 
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: SpectrumColors.surface.withOpacity(0.4),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: SpectrumColors.border.withOpacity(0.5)),
      ),
      child: Column(children: children),
    );
  }
}
 
class _ColorIndicator extends StatelessWidget {
  final Color color;
  const _ColorIndicator({required this.color});
 
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 24,
      height: 24,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(4),
        boxShadow: [BoxShadow(color: color.withOpacity(0.3), blurRadius: 10)],
        border: Border.all(color: Colors.white24, width: 0.5),
      ),
    );
  }
}
 
