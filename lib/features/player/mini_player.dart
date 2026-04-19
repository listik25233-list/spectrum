import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:spectrum/core/db/isar_service.dart';
import 'package:spectrum/core/db/schemas/track_schema.dart';
import 'package:spectrum/features/player/audio_player_service.dart';
import 'package:spectrum/features/player/full_player_screen.dart';
import 'package:spectrum/features/player/dominant_color_provider.dart';
import 'package:spectrum/features/jam/jam_screen.dart';
import 'package:spectrum/features/jam/jam_provider.dart';
import 'package:spectrum/core/theme/spectrum_colors.dart';

import 'package:spectrum/core/navigation/navigator_key.dart';

class MiniPlayer extends ConsumerStatefulWidget {
  final bool isIsland;
  const MiniPlayer({
    super.key,
    this.isIsland = false,
  });

  @override
  ConsumerState<MiniPlayer> createState() => _MiniPlayerState();
}

class _MiniPlayerState extends ConsumerState<MiniPlayer> {
  String? _lastWarmedAlbumArtUrl;

  void _warmAlbumArt(String? albumArtUrl) {
    if (albumArtUrl == null || albumArtUrl == _lastWarmedAlbumArtUrl) return;
    _lastWarmedAlbumArtUrl = albumArtUrl;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      precacheImage(CachedNetworkImageProvider(albumArtUrl), context);
    });
  }

  @override
  Widget build(BuildContext context) {
    final ref = this.ref;
    final currentTrack = ref.watch(currentTrackProvider);
    final dominantColorAsync = ref.watch(dominantColorProvider);

    if (currentTrack == null) return const SizedBox.shrink();

    final baseColor = dominantColorAsync.when(
      data: (color) => color ?? const Color(0xFF1C1C2E),
      loading: () => const Color(0xFF1C1C2E),
      error: (_, __) => const Color(0xFF1C1C2E),
    );
    _warmAlbumArt(currentTrack.albumArtUrl);

    return GestureDetector(
      onTap: () {
        globalNavigatorKey.currentState?.push(
          PageRouteBuilder(
            settings: const RouteSettings(name: '/full_player'),
            pageBuilder: (_, __, ___) => const FullPlayerScreen(),
            transitionsBuilder: (_, animation, __, child) {
              return SlideTransition(
                position: Tween(
                  begin: const Offset(0.0, 1.0),
                  end: Offset.zero,
                ).animate(CurvedAnimation(
                    parent: animation, curve: Curves.easeOutCubic)),
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
          return AnimatedContainer(
            duration: const Duration(milliseconds: 600),
            padding: EdgeInsets.zero,
            child: ClipRRect(
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(24),
                topRight: const Radius.circular(24),
                bottomLeft: widget.isIsland ? const Radius.circular(24) : Radius.zero,
                bottomRight: widget.isIsland ? const Radius.circular(24) : Radius.zero,
              ),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 600),
                  padding: const EdgeInsets.symmetric(
                      vertical: 2), // Slight vertical padding for the frame
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.85), // Denser background
                    gradient: LinearGradient(
                      colors: [
                        baseColor.withOpacity(0.25),
                        Colors.black.withOpacity(0.9),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.12),
                      width: 1.0,
                    ),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const _MiniPlayerProgressBar(),
                      SizedBox(
                        height: compact ? 64 : 70,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 14),
                          child: Row(
                            children: [
                              Hero(
                                tag: _playerArtHeroTag(currentTrack),
                                child: Container(
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(12),
                                    boxShadow: [
                                      BoxShadow(
                                        color: baseColor.withOpacity(0.2),
                                        blurRadius: 10,
                                        spreadRadius: -2,
                                      ),
                                    ],
                                  ),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(12),
                                    child: currentTrack.albumArtUrl != null
                                        ? CachedNetworkImage(
                                            imageUrl: currentTrack.albumArtUrl!,
                                            width: 48,
                                            height: 48,
                                            fit: BoxFit.cover,
                                            memCacheWidth: 128,
                                            placeholder: (_, __) => Container(
                                              width: 48,
                                              height: 48,
                                              color: Colors.white
                                                  .withOpacity(0.05),
                                            ),
                                          )
                                        : Container(
                                            width: 48,
                                            height: 48,
                                            color:
                                                Colors.white.withOpacity(0.05),
                                            child: const Icon(
                                                Icons.music_note_rounded,
                                                color: Colors.white30,
                                                size: 24),
                                          ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      currentTrack.title.toUpperCase(),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w700,
                                        fontSize: 12,
                                        color: Colors.white,
                                        letterSpacing:
                                            1.2, // Techy/Nothing feel
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      currentTrack.artist,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w500,
                                        color: Colors.white.withOpacity(0.4),
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              _MiniPlayerControls(
                                currentTrack: currentTrack,
                                compact: compact,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _MiniPlayerProgressBar extends ConsumerWidget {
  const _MiniPlayerProgressBar();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final position = ref.watch(playbackPositionProvider);
    final duration = ref.watch(playbackDurationProvider);
    final maxMs = duration.inMilliseconds.toDouble();
    final progress =
        maxMs > 0 ? (position.inMilliseconds / maxMs).clamp(0.0, 1.0) : 0.0;

    return SizedBox(
      height: 2.5,
      child: LinearProgressIndicator(
        value: progress,
        backgroundColor: Colors.white.withOpacity(0.06),
        valueColor: AlwaysStoppedAnimation<Color>(
          Theme.of(context).colorScheme.primary.withOpacity(0.9),
        ),
      ),
    );
  }
}

class _MiniPlayerControls extends ConsumerWidget {
  final Track currentTrack;
  final bool compact;

  const _MiniPlayerControls({
    required this.currentTrack,
    required this.compact,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isPlaying = ref.watch(isPlayingProvider);
    final isLoadingStream = ref.watch(isLoadingStreamProvider);
    final djEnabled = ref.watch(djModeEnabledProvider);
    final isShuffling = ref.watch(isShufflingProvider);

    if (isLoadingStream) {
      return const Padding(
        padding: EdgeInsets.all(10.0),
        child: SizedBox(
          width: 22,
          height: 22,
          child:
              CircularProgressIndicator(strokeWidth: 2, color: Colors.white38),
        ),
      );
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          padding: EdgeInsets.zero,
          icon: Icon(
            currentTrack.isFavorite
                ? Icons.favorite_rounded
                : Icons.favorite_border_rounded,
            size: 22,
            color: currentTrack.isFavorite ? SpectrumColors.accent : Colors.white54,
          ),
          onPressed: () async {
            final isar = IsarService.instance;
            await isar.writeTxn(() async {
              currentTrack.isFavorite = !currentTrack.isFavorite;
              // Ensure it's also in the library if favorited
              if (currentTrack.isFavorite) {
                currentTrack.inLibrary = true;
              }
              await isar.tracks.put(currentTrack);
            });
            // Trigger UI refresh via the StateProvider
            ref.read(currentTrackProvider.notifier).state = null;
            ref.read(currentTrackProvider.notifier).state = currentTrack;
          },
        ),
        IconButton(
          padding: EdgeInsets.zero,
          icon: Icon(
            Icons.hub_outlined,
            size: 20,
            color: ref.watch(jamProvider) != null
                ? SpectrumColors.accent
                : Colors.white24,
          ),
          onPressed: () {
            globalNavigatorKey.currentState?.push(
              MaterialPageRoute(builder: (ctx) => const JamSessionScreen()),
            );
          },
        ),
        IconButton(
          padding: EdgeInsets.zero,
          icon: Icon(
            Icons.shuffle_rounded,
            size: 20,
            color: djEnabled
                ? Colors.white24
                : (isShuffling
                    ? Theme.of(context).colorScheme.primary
                    : Colors.white54),
          ),
          onPressed: () {
            if (djEnabled) return;
            ref.read(isShufflingProvider.notifier).state = !isShuffling;
          },
        ),
        IconButton(
          padding: EdgeInsets.zero,
          icon: const Icon(Icons.skip_previous_rounded,
              size: 28, color: Colors.white),
          onPressed: () => ref.read(audioPlayerServiceProvider).playPrevious(),
        ),
        IconButton(
          padding: EdgeInsets.zero,
          icon: AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            child: Icon(
              isPlaying
                  ? Icons.pause_circle_filled_rounded
                  : Icons.play_circle_filled_rounded,
              key: ValueKey(isPlaying),
              size: 40,
              color: Colors.white,
            ),
          ),
          onPressed: () => ref.read(audioPlayerServiceProvider).togglePlay(),
        ),
        IconButton(
          padding: EdgeInsets.zero,
          icon: const Icon(Icons.skip_next_rounded,
              size: 28, color: Colors.white),
          onPressed: () => ref.read(audioPlayerServiceProvider).playNext(),
        ),
        if (!compact)
          IconButton(
            padding: EdgeInsets.zero,
            icon: _RepeatIcon(),
            onPressed: () {
              final current = ref.read(repeatModeProvider);
              final next = PlayerRepeatMode
                  .values[(current.index + 1) % PlayerRepeatMode.values.length];
              ref.read(repeatModeProvider.notifier).state = next;
            },
          ),
      ],
    );
  }
}

class _RepeatIcon extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
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

String _playerArtHeroTag(Track track) =>
    'player-art-${track.spotifyId ?? track.id}';
