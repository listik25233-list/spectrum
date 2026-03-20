import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:spectrum/core/db/schemas/playlist_schema.dart';
import 'package:spectrum/features/library/playlist_tracks_provider.dart';
import 'package:spectrum/features/player/audio_player_service.dart';
import 'package:spectrum/features/player/mini_player.dart';

class PlaylistScreen extends ConsumerWidget {
  final Playlist playlist;

  const PlaylistScreen({super.key, required this.playlist});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tracksAsync = ref.watch(playlistTracksProvider(playlist));
    final screenHeight = MediaQuery.of(context).size.height;
    final expandedHeight = (screenHeight * 0.34).clamp(180.0, 320.0);

    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      body: Column(
        children: [
          Expanded(
            child: CustomScrollView(
              slivers: [
                SliverAppBar(
                  expandedHeight: expandedHeight,
                  pinned: true,
                  elevation: 0,
                  backgroundColor: const Color(0xFF121212),
                  flexibleSpace: FlexibleSpaceBar(
                    titlePadding: const EdgeInsets.only(left: 20, bottom: 16, right: 20),
                    title: Text(
                      playlist.name,
                      style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 28, letterSpacing: -0.5),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    background: Stack(
                      fit: StackFit.expand,
                      children: [
                        if (playlist.artworkUrl != null)
                          Image.network(
                            playlist.artworkUrl!,
                            fit: BoxFit.cover,
                          )
                        else
                          Container(
                            color: Colors.deepPurple.shade900,
                            child: const Center(
                              child: Icon(Icons.queue_music, size: 80, color: Colors.white24),
                            ),
                          ),
                        // Premium Gradient Overlay
                        Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.black.withOpacity(0.4),
                                Colors.transparent,
                                const Color(0xFF121212),
                              ],
                              stops: const [0.0, 0.4, 1.0],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                tracksAsync.when(
                  data: (tracks) {
                    if (tracks.isEmpty) {
                      return const SliverFillRemaining(
                        child: Center(
                          child: Text('В этом плейлисте нет треков', style: TextStyle(color: Colors.white54)),
                        ),
                      );
                    }
                    return SliverPadding(
                      padding: const EdgeInsets.only(bottom: 100),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            final track = tracks[index];
                            final compact = MediaQuery.of(context).size.width < 740;
                            return Center(
                              child: ConstrainedBox(
                                constraints: const BoxConstraints(maxWidth: 1200),
                                child: Material(
                                  color: Colors.transparent,
                                  child: ListTile(
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
                                    hoverColor: Colors.white.withOpacity(0.04),
                                    leading: track.albumArtUrl != null
                                        ? ClipRRect(
                                            borderRadius: BorderRadius.circular(8),
                                            child: Image.network(track.albumArtUrl!, width: 44, height: 44, fit: BoxFit.cover),
                                          )
                                        : Container(
                                            width: 44,
                                            height: 44,
                                            decoration: BoxDecoration(color: Colors.white12, borderRadius: BorderRadius.circular(8)),
                                            child: const Icon(Icons.music_note, color: Colors.white38),
                                          ),
                                    title: Text(
                                      track.title,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                                    ),
                                    subtitle: Text(
                                      track.localPath != null ? '${track.artist}  •  Загружен' : track.artist,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        color: track.localPath != null ? Colors.greenAccent.withOpacity(0.85) : Colors.white54,
                                        fontSize: 13,
                                      ),
                                    ),
                                    trailing: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        if (!compact && track.durationMs > 0)
                                          Text(
                                            '${(track.durationMs ~/ 60000)}:${((track.durationMs % 60000) ~/ 1000).toString().padLeft(2, '0')}',
                                            style: const TextStyle(color: Colors.white38, fontSize: 13),
                                          ),
                                        if (!compact) const SizedBox(width: 16),
                                        IconButton(
                                          icon: const Icon(Icons.play_circle_fill, color: Colors.white54),
                                          onPressed: () => ref.read(audioPlayerServiceProvider).playQueue(tracks, initialIndex: index),
                                        ),
                                      ],
                                    ),
                                    onTap: () {
                                      ref.read(audioPlayerServiceProvider).playQueue(tracks, initialIndex: index);
                                    },
                                  ),
                                ),
                              ),
                            );
                          },
                          childCount: tracks.length,
                        ),
                      ),
                    );
                  },
                  loading: () => const SliverFillRemaining(
                    child: Center(child: CircularProgressIndicator()),
                  ),
                  error: (error, _) => SliverFillRemaining(
                    child: Center(child: Text('Ошибка: $error')),
                  ),
                ),
              ],
            ),
          ),
          const MiniPlayer(),
        ],
      ),
    );
  }
}
