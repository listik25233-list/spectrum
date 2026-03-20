import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar/isar.dart';
import 'package:spectrum/core/db/isar_service.dart';
import 'package:spectrum/core/db/schemas/auth_token_schema.dart';
import 'package:spectrum/core/db/schemas/track_schema.dart';
import 'package:spectrum/core/db/schemas/playlist_schema.dart';
import 'package:spectrum/features/auth/auth_provider.dart';
import 'package:spectrum/features/player/mini_player.dart';

final highQualityAudioProvider = StateProvider<bool>((ref) => true);

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final highQualityAudio = ref.watch(highQualityAudioProvider);
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        title: const Text('Settings', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 26, letterSpacing: -0.5)),
        backgroundColor: const Color(0xFF121212),
        elevation: 0,
      ),
      body: Column(
        children: [
          Expanded(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 980),
                child: ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  children: [
                    const Text('Accounts', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white70)),
                    const SizedBox(height: 16),
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final compact = constraints.maxWidth < 560;
                        final disconnectButton = ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white12,
                            foregroundColor: Colors.white,
                          ),
                          onPressed: () async {
                            final shouldDisconnect = await showDialog<bool>(
                                  context: context,
                                  builder: (ctx) => AlertDialog(
                                    backgroundColor: const Color(0xFF1E1E1E),
                                    title: const Text('Отключить Spotify?'),
                                    content: const Text('Будут удалены токены, треки и плейлисты из локальной базы.'),
                                    actions: [
                                      TextButton(
                                        onPressed: () => Navigator.pop(ctx, false),
                                        child: const Text('Отмена'),
                                      ),
                                      FilledButton(
                                        onPressed: () => Navigator.pop(ctx, true),
                                        child: const Text('Отключить'),
                                      ),
                                    ],
                                  ),
                                ) ??
                                false;
                            if (!shouldDisconnect) return;

                            final isar = IsarService.instance;
                            await isar.writeTxn(() async {
                              await isar.authTokens.filter().serviceEqualTo('spotify').deleteAll();
                              await isar.tracks.clear();
                              await isar.playlists.clear();
                            });
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Spotify отключён')),
                              );
                            }
                          },
                          child: const Text('Disconnect'),
                        );

                        return ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: const Icon(Icons.music_note, color: Colors.greenAccent),
                          title: const Text('Spotify Connected', style: TextStyle(fontWeight: FontWeight.w600)),
                          subtitle: compact
                              ? Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text('Sync saved tracks and playlists', style: TextStyle(color: Colors.white54)),
                                    const SizedBox(height: 10),
                                    disconnectButton,
                                  ],
                                )
                              : const Text('Sync saved tracks and playlists', style: TextStyle(color: Colors.white54)),
                          trailing: compact ? null : disconnectButton,
                        );
                      },
                    ),
                    const Divider(color: Colors.white12, height: 48),
                    const Text('Playback', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white70)),
                    const SizedBox(height: 16),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('High Quality Audio', style: TextStyle(fontWeight: FontWeight.w600)),
                      subtitle: const Text('Use more data for better streaming quality', style: TextStyle(color: Colors.white54)),
                      value: highQualityAudio,
                      activeColor: Colors.deepPurpleAccent,
                      onChanged: (val) {
                        ref.read(highQualityAudioProvider.notifier).state = val;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(val ? 'Высокое качество включено' : 'Высокое качество выключено')),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
          const MiniPlayer(), // Mini player stays on screen bottom
        ],
      ),
    );
  }
}
