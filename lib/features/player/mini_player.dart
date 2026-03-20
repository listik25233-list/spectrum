import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:spectrum/features/player/audio_player_service.dart';
import 'package:spectrum/features/player/full_player_screen.dart';

class MiniPlayer extends ConsumerWidget {
  const MiniPlayer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentTrack = ref.watch(currentTrackProvider);
    final isPlaying = ref.watch(isPlayingProvider);
    final isLoadingStream = ref.watch(isLoadingStreamProvider);
    final position = ref.watch(playbackPositionProvider);
    final duration = ref.watch(playbackDurationProvider);
    final djEnabled = ref.watch(djModeEnabledProvider);

    if (currentTrack == null) return const SizedBox.shrink();

    final maxMs = duration.inMilliseconds.toDouble();
    final progress = maxMs > 0
        ? (position.inMilliseconds / maxMs).clamp(0.0, 1.0)
        : 0.0;

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          PageRouteBuilder(
            pageBuilder: (_, __, ___) => const FullPlayerScreen(),
            transitionsBuilder: (_, animation, __, child) {
              return SlideTransition(
                position: Tween(
                  begin: const Offset(0.0, 1.0),
                  end: Offset.zero,
                ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOutCubic)),
                child: child,
              );
            },
            transitionDuration: const Duration(milliseconds: 350),
          ),
        );
      },
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 880;
          return Container(
            margin: const EdgeInsets.fromLTRB(12, 4, 12, 8),
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              color: const Color(0xFF1C1C2E),
              border: Border.all(color: Colors.white.withOpacity(0.06)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.5),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  height: 2.5,
                  child: LinearProgressIndicator(
                    value: progress,
                    backgroundColor: Colors.white.withOpacity(0.06),
                    valueColor: AlwaysStoppedAnimation<Color>(
                      Theme.of(context).colorScheme.primary.withOpacity(0.9),
                    ),
                  ),
                ),
                SizedBox(
                  height: compact ? 58 : 62,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    child: Row(
                      children: [
                    // Album art
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: currentTrack.albumArtUrl != null
                          ? CachedNetworkImage(
                              imageUrl: currentTrack.albumArtUrl!,
                              width: 44,
                              height: 44,
                              fit: BoxFit.cover,
                              placeholder: (_, __) => Container(
                                width: 44, height: 44,
                                color: Colors.white10,
                              ),
                              errorWidget: (_, __, ___) => Container(
                                width: 44, height: 44,
                                color: Colors.white10,
                                child: const Icon(Icons.music_note_rounded, color: Colors.white24, size: 20),
                              ),
                            )
                          : Container(
                              width: 44, height: 44,
                              color: Colors.white10,
                              child: const Icon(Icons.music_note_rounded, color: Colors.white24, size: 20),
                            ),
                    ),
                    const SizedBox(width: 10),

                    // Title & artist
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            currentTrack.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                              color: Colors.white,
                              letterSpacing: -0.2,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            currentTrack.artist,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.white.withOpacity(0.45),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Controls
                    if (isLoadingStream)
                      const Padding(
                        padding: EdgeInsets.all(10.0),
                        child: SizedBox(
                          width: 22, height: 22,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white38),
                        ),
                      )
                    else ...[
                      if (!compact)
                        IconButton(
                          padding: EdgeInsets.zero,
                        icon: Icon(
                          Icons.shuffle_rounded,
                          size: 20,
                          color: djEnabled
                              ? Colors.white24
                              : (ref.watch(isShufflingProvider) ? Theme.of(context).colorScheme.primary : Colors.white54),
                        ),
                          onPressed: () {
                          if (djEnabled) return;
                            final current = ref.read(isShufflingProvider);
                            ref.read(isShufflingProvider.notifier).state = !current;
                          },
                        ),
                      // Previous
                      IconButton(
                        padding: EdgeInsets.zero,
                        icon: const Icon(Icons.skip_previous_rounded, size: 28, color: Colors.white),
                        onPressed: () => ref.read(audioPlayerServiceProvider).playPrevious(),
                      ),
                      // Play/Pause
                      IconButton(
                        padding: EdgeInsets.zero,
                        icon: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 200),
                          child: Icon(
                            isPlaying ? Icons.pause_circle_filled_rounded : Icons.play_circle_filled_rounded,
                            key: ValueKey(isPlaying),
                            size: 40,
                            color: Colors.white,
                          ),
                        ),
                        onPressed: () => ref.read(audioPlayerServiceProvider).togglePlay(),
                      ),
                      // Next
                      IconButton(
                        padding: EdgeInsets.zero,
                        icon: const Icon(Icons.skip_next_rounded, size: 28, color: Colors.white),
                        onPressed: () => ref.read(audioPlayerServiceProvider).playNext(),
                      ),
                      if (!compact)
                        IconButton(
                          padding: EdgeInsets.zero,
                          icon: _buildRepeatIcon(ref),
                          onPressed: () {
                            final current = ref.read(repeatModeProvider);
                            final next = PlayerRepeatMode.values[(current.index + 1) % PlayerRepeatMode.values.length];
                            ref.read(repeatModeProvider.notifier).state = next;
                          },
                        ),
                    ],
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildRepeatIcon(WidgetRef ref) {
    final mode = ref.watch(repeatModeProvider);
    IconData iconData;
    Color color;

    switch (mode) {
      case PlayerRepeatMode.off:
        iconData = Icons.repeat_rounded;
        color = Colors.white54;
        break;
      case PlayerRepeatMode.all:
        iconData = Icons.repeat_rounded;
        color = Theme.of(ref.context).colorScheme.primary;
        break;
      case PlayerRepeatMode.one:
        iconData = Icons.repeat_one_rounded;
        color = Theme.of(ref.context).colorScheme.primary;
        break;
    }
    return Icon(iconData, size: 20, color: color);
  }
}
