import 'dart:ui';
import 'package:flutter/material.dart' hide RepeatMode;
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:spectrum/core/db/schemas/track_schema.dart';
import 'package:spectrum/features/player/audio_player_service.dart';

class FullPlayerScreen extends ConsumerStatefulWidget {
  const FullPlayerScreen({super.key});

  @override
  ConsumerState<FullPlayerScreen> createState() => _FullPlayerScreenState();
}

class _FullPlayerScreenState extends ConsumerState<FullPlayerScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _scaleAnim;
  final ScrollController _lyricsScrollController = ScrollController();
  bool _isSeeking = false;
  double _seekValue = 0;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _scaleAnim = Tween<double>(begin: 0.85, end: 1.0).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeOutBack),
    );
    _animController.forward();
  }

  @override
  void dispose() {
    _lyricsScrollController.dispose();
    _animController.dispose();
    super.dispose();
  }

  String _fmt(Duration d) {
    final m = d.inMinutes;
    final s = d.inSeconds % 60;
    return '$m:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final track = ref.watch(currentTrackProvider);
    final isPlaying = ref.watch(isPlayingProvider);
    final position = ref.watch(playbackPositionProvider);
    final duration = ref.watch(playbackDurationProvider);
    final volume = ref.watch(volumeProvider);
    final isLoading = ref.watch(isLoadingStreamProvider);
    final isShuffling = ref.watch(isShufflingProvider);
    final djEnabled = ref.watch(djModeEnabledProvider);
    final repeatMode = ref.watch(repeatModeProvider);
    final size = MediaQuery.of(context).size;
    final artSize = (size.width * 0.65).clamp(200.0, 400.0);

    if (track == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) Navigator.pop(context);
      });
      return const SizedBox.shrink();
    }

    final maxMs = duration.inMilliseconds.toDouble();
    final posMs = position.inMilliseconds.toDouble();
    final sliderMax = maxMs > 0 ? maxMs : 1.0;
    final sliderValue = _isSeeking ? _seekValue : posMs.clamp(0.0, sliderMax);
    _syncLyricsScroll(position, duration);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // --- Blurred background from album art ---
          if (track.albumArtUrl != null)
            CachedNetworkImage(
              imageUrl: track.albumArtUrl!,
              fit: BoxFit.cover,
              errorWidget: (_, __, ___) => Container(color: const Color(0xFF0A0A0F)),
            ),
          BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 60, sigmaY: 60),
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withOpacity(0.4),
                    Colors.black.withOpacity(0.85),
                    Colors.black.withOpacity(0.95),
                  ],
                ),
              ),
            ),
          ),

          // --- Content ---
          SafeArea(
            child: Column(
              children: [
                // Top bar
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 32),
                        color: Colors.white70,
                        onPressed: () => Navigator.pop(context),
                      ),
                      const Spacer(),
                      Column(
                        children: [
                          Text(
                            'СЕЙЧАС ИГРАЕТ',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 1.5,
                              color: Colors.white.withOpacity(0.5),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            track.album ?? '',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: Colors.white70,
                            ),
                          ),
                        ],
                      ),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.queue_music_rounded, size: 22),
                        color: Colors.white70,
                        tooltip: 'Очередь',
                        onPressed: () => _showQueueEditor(context, ref),
                      ),
                      IconButton(
                        icon: const Icon(Icons.more_vert_rounded, size: 24),
                        color: Colors.white70,
                        onPressed: () {
                          _showTrackMenu(context, ref);
                        },
                      ),
                    ],
                  ),
                ),

                const Spacer(flex: 2),

                // Album Art
                ScaleTransition(
                  scale: _scaleAnim,
                  child: Container(
                    width: artSize,
                    height: artSize,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.6),
                          blurRadius: 40,
                          offset: const Offset(0, 20),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: track.albumArtUrl != null
                          ? CachedNetworkImage(
                              imageUrl: track.albumArtUrl!,
                              fit: BoxFit.cover,
                              placeholder: (_, __) => Container(
                                color: Colors.grey[900],
                                child: const Center(
                                  child: Icon(Icons.music_note_rounded, size: 64, color: Colors.white24),
                                ),
                              ),
                              errorWidget: (_, __, ___) => Container(
                                color: Colors.grey[900],
                                child: const Center(
                                  child: Icon(Icons.music_note_rounded, size: 64, color: Colors.white24),
                                ),
                              ),
                            )
                          : Container(
                              color: Colors.grey[900],
                              child: const Center(
                                child: Icon(Icons.music_note_rounded, size: 64, color: Colors.white24),
                              ),
                            ),
                    ),
                  ),
                ),

                const Spacer(flex: 2),

                // Track info
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              track.title,
                              style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                                letterSpacing: -0.5,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              track.artist,
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.white.withOpacity(0.6),
                                fontWeight: FontWeight.w400,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      if (isLoading)
                        const SizedBox(
                          width: 20, height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white54),
                        ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // Seek slider
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      trackHeight: 3.0,
                      thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 5.0),
                      overlayShape: const RoundSliderOverlayShape(overlayRadius: 16.0),
                      activeTrackColor: Colors.white,
                      inactiveTrackColor: Colors.white.withOpacity(0.15),
                      thumbColor: Colors.white,
                      overlayColor: Colors.white.withOpacity(0.1),
                    ),
                    child: Slider(
                      value: sliderValue,
                      max: sliderMax,
                      onChangeStart: (v) {
                        setState(() {
                          _isSeeking = true;
                          _seekValue = v;
                        });
                      },
                      onChanged: (v) {
                        setState(() => _seekValue = v);
                      },
                      onChangeEnd: (v) {
                        ref.read(audioPlayerServiceProvider).seek(Duration(milliseconds: v.toInt()));
                        setState(() => _isSeeking = false);
                      },
                    ),
                  ),
                ),

                // Time labels
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _fmt(_isSeeking ? Duration(milliseconds: _seekValue.toInt()) : position),
                        style: TextStyle(fontSize: 11, color: Colors.white.withOpacity(0.45), fontWeight: FontWeight.w500),
                      ),
                      Text(
                        _fmt(duration),
                        style: TextStyle(fontSize: 11, color: Colors.white.withOpacity(0.45), fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // Main controls
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      IconButton(
                        iconSize: 28,
                        icon: const Icon(Icons.shuffle_rounded),
                        color: djEnabled
                            ? Colors.white24
                            : (isShuffling ? Theme.of(context).colorScheme.primary : Colors.white54),
                        onPressed: () {
                          if (djEnabled) return;
                          ref.read(isShufflingProvider.notifier).state = !isShuffling;
                        },
                      ),
                      IconButton(
                        iconSize: 36,
                        icon: const Icon(Icons.skip_previous_rounded),
                        color: Colors.white,
                        onPressed: () => ref.read(audioPlayerServiceProvider).playPrevious(),
                      ),
                      // Play / Pause
                      GestureDetector(
                        onTap: () => ref.read(audioPlayerServiceProvider).togglePlay(),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          width: 68,
                          height: 68,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white,
                          ),
                          child: Icon(
                            isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                            size: 36,
                            color: Colors.black,
                          ),
                        ),
                      ),
                      IconButton(
                        iconSize: 36,
                        icon: const Icon(Icons.skip_next_rounded),
                        color: Colors.white,
                        onPressed: () => ref.read(audioPlayerServiceProvider).playNext(),
                      ),
                      IconButton(
                        iconSize: 28,
                        icon: Icon(_repeatIconData(repeatMode)),
                        color: repeatMode == RepeatMode.off ? Colors.white54 : Theme.of(context).colorScheme.primary,
                        onPressed: () {
                          final next = RepeatMode.values[(repeatMode.index + 1) % RepeatMode.values.length];
                          ref.read(repeatModeProvider.notifier).state = next;
                        },
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 18),

                // Volume
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: Row(
                    children: [
                      Icon(
                        volume <= 0 ? Icons.volume_off_rounded : Icons.volume_down_rounded,
                        color: Colors.white38,
                        size: 18,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: SliderTheme(
                          data: SliderTheme.of(context).copyWith(
                            trackHeight: 2.5,
                            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 4.0),
                            overlayShape: const RoundSliderOverlayShape(overlayRadius: 12.0),
                            activeTrackColor: Colors.white.withOpacity(0.7),
                            inactiveTrackColor: Colors.white.withOpacity(0.12),
                            thumbColor: Colors.white,
                            overlayColor: Colors.white.withOpacity(0.08),
                          ),
                          child: Slider(
                            value: volume.clamp(0.0, 1.0),
                            onChanged: (v) {
                              ref.read(audioPlayerServiceProvider).setVolume(v);
                            },
                          ),
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Icon(Icons.volume_up_rounded, color: Colors.white38, size: 18),
                    ],
                  ),
                ),

                const SizedBox(height: 18),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: GestureDetector(
                    onTap: () => _openLyricsFullscreen(context),
                    child: Container(
                      width: double.infinity,
                      height: size.height * 0.18,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.06),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: Colors.white.withOpacity(0.08)),
                      ),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.lyrics_rounded, color: Colors.white70, size: 18),
                              const SizedBox(width: 8),
                              const Text(
                                'Текст песни',
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13,
                                ),
                              ),
                              const Spacer(),
                              IconButton(
                                icon: const Icon(Icons.queue_music_rounded, color: Colors.white70, size: 18),
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(minWidth: 20, minHeight: 20),
                                onPressed: () => _showQueueEditor(context, ref),
                              ),
                              const SizedBox(width: 8),
                              Icon(Icons.open_in_full_rounded, color: Colors.white.withOpacity(0.7), size: 18),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Expanded(
                            child: SingleChildScrollView(
                              controller: _lyricsScrollController,
                              child: Text(
                                _buildLyricsText(track),
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 13,
                                  height: 1.55,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
              ],
            ),
          ),
        ],
      ),
    );
  }

  IconData _repeatIconData(RepeatMode mode) {
    switch (mode) {
      case RepeatMode.one:
        return Icons.repeat_one_rounded;
      case RepeatMode.all:
        return Icons.repeat_rounded;
      case RepeatMode.off:
        return Icons.repeat_rounded;
    }
  }

  String _buildLyricsText(Track track) {
    final parsed = _parseLyrics(track.lyrics);
    if (parsed.isNotEmpty) {
      return parsed.map((line) => line.text).join('\n');
    }
    return 'Текст песни пока не найден.\n\n'
        '${track.title}\n${track.artist}\n\n'
        'Как только лирика появится в данных трека, она будет отображаться здесь и прокручиваться автоматически по ходу воспроизведения.';
  }

  void _syncLyricsScroll(Duration position, Duration duration) {
    if (!_lyricsScrollController.hasClients) return;
    final maxExtent = _lyricsScrollController.position.maxScrollExtent;
    if (maxExtent <= 0) return;

    final totalMs = duration.inMilliseconds;
    if (totalMs <= 0) return;

    final ratio = (position.inMilliseconds / totalMs).clamp(0.0, 1.0);
    final targetOffset = maxExtent * ratio;
    final currentOffset = _lyricsScrollController.offset;
    if ((currentOffset - targetOffset).abs() < 8) return;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_lyricsScrollController.hasClients) return;
      _lyricsScrollController.animateTo(
        targetOffset,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    });
  }

  void _showTrackMenu(BuildContext context, WidgetRef ref) {
    final track = ref.read(currentTrackProvider);
    if (track == null) return;

    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1A1A2E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40, height: 4,
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: const Icon(Icons.download_rounded, color: Colors.white70),
                title: const Text('Скачать трек', style: TextStyle(color: Colors.white)),
                subtitle: Text(
                  track.localPath != null ? 'Уже скачан' : 'Сохранить для офлайн',
                  style: const TextStyle(color: Colors.white38, fontSize: 12),
                ),
                onTap: () async {
                  Navigator.pop(ctx);
                  if (track.localPath == null) {
                    final scaffold = ScaffoldMessenger.of(context);
                    scaffold.showSnackBar(
                      const SnackBar(content: Text('Скачивание началось...')),
                    );
                    final success = await ref.read(audioPlayerServiceProvider).downloadCurrentTrack();
                    if (mounted) {
                      scaffold.hideCurrentSnackBar();
                      scaffold.showSnackBar(
                        SnackBar(
                          content: Text(success ? 'Трек успешно сохранён для офлайн прослушивания!' : 'Ошибка при сохранении трека.'),
                          backgroundColor: success ? Colors.green[800] : Colors.red[800],
                        ),
                      );
                    }
                  }
                },
              ),
              ListTile(
                leading: const Icon(Icons.queue_music_rounded, color: Colors.white70),
                title: const Text('Очередь', style: TextStyle(color: Colors.white)),
                subtitle: const Text('Редактировать порядок и удалить треки', style: TextStyle(color: Colors.white38, fontSize: 12)),
                onTap: () {
                  Navigator.pop(ctx);
                  _showQueueEditor(context, ref);
                },
              ),
              ListTile(
                leading: const Icon(Icons.share_rounded, color: Colors.white70),
                title: const Text('Поделиться', style: TextStyle(color: Colors.white)),
                onTap: () async {
                  Navigator.pop(ctx);
                  final shareText = '${track.title} - ${track.artist}'
                      '${track.spotifyId != null ? '\nhttps://open.spotify.com/track/${track.spotifyId}' : ''}';
                  await Clipboard.setData(ClipboardData(text: shareText));
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Информация о треке скопирована')),
                    );
                  }
                },
              ),
              ListTile(
                leading: const Icon(Icons.info_outline_rounded, color: Colors.white70),
                title: const Text('Информация о треке', style: TextStyle(color: Colors.white)),
                subtitle: Text(
                  'ISRC: ${track.isrc ?? "—"}',
                  style: const TextStyle(color: Colors.white38, fontSize: 12),
                ),
                onTap: () {
                  Navigator.pop(ctx);
                  showDialog<void>(
                    context: context,
                    builder: (dialogContext) => AlertDialog(
                      backgroundColor: const Color(0xFF1A1A2E),
                      title: const Text('О треке'),
                      content: Text(
                        'Название: ${track.title}\n'
                        'Артист: ${track.artist}\n'
                        'Альбом: ${track.album ?? "—"}\n'
                        'Длительность: ${_fmt(Duration(milliseconds: track.durationMs))}\n'
                        'ISRC: ${track.isrc ?? "—"}\n'
                        'Spotify ID: ${track.spotifyId ?? "—"}',
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(dialogContext),
                          child: const Text('Закрыть'),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _openLyricsFullscreen(BuildContext context) {
    Navigator.of(context).push(
      PageRouteBuilder(
        opaque: false,
        transitionDuration: const Duration(milliseconds: 320),
        reverseTransitionDuration: const Duration(milliseconds: 240),
        pageBuilder: (_, __, ___) => const LyricsFullscreenScreen(),
        transitionsBuilder: (_, animation, __, child) {
          return FadeTransition(
            opacity: CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
            child: child,
          );
        },
      ),
    );
  }

  void _showQueueEditor(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF12121C),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: SizedBox(
            height: MediaQuery.of(context).size.height * 0.72,
            child: Consumer(
              builder: (context, ref, _) {
                final queue = ref.watch(currentQueueProvider);
                final queueIndex = ref.watch(queueIndexProvider);
                if (queue.isEmpty) {
                  return const Center(
                    child: Text('Очередь пуста', style: TextStyle(color: Colors.white70)),
                  );
                }
                return Column(
                  children: [
                    const SizedBox(height: 10),
                    Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.white24,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(height: 14),
                    const Text(
                      'Очередь воспроизведения',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Expanded(
                      child: ReorderableListView.builder(
                        itemCount: queue.length,
                        onReorder: (oldIndex, newIndex) {
                          ref.read(audioPlayerServiceProvider).reorderQueue(oldIndex, newIndex);
                        },
                        itemBuilder: (context, index) {
                          final item = queue[index];
                          final isCurrent = index == queueIndex;
                          return ListTile(
                            key: ValueKey('${item.id}_${item.spotifyId ?? item.title}_$index'),
                            leading: Icon(
                              isCurrent ? Icons.graphic_eq_rounded : Icons.music_note_rounded,
                              color: isCurrent ? Theme.of(context).colorScheme.primary : Colors.white54,
                            ),
                            title: Text(
                              item.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: isCurrent ? Colors.white : Colors.white70,
                                fontWeight: isCurrent ? FontWeight.w700 : FontWeight.w500,
                              ),
                            ),
                            subtitle: Text(
                              item.artist,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(color: Colors.white54),
                            ),
                            trailing: IconButton(
                              icon: const Icon(Icons.close_rounded, color: Colors.white54),
                              onPressed: () => ref.read(audioPlayerServiceProvider).removeFromQueue(index),
                            ),
                            onTap: () {
                              ref.read(audioPlayerServiceProvider).playQueue(queue, initialIndex: index);
                            },
                          );
                        },
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        );
      },
    );
  }
}

class LyricsFullscreenScreen extends ConsumerStatefulWidget {
  const LyricsFullscreenScreen({super.key});

  @override
  ConsumerState<LyricsFullscreenScreen> createState() => _LyricsFullscreenScreenState();
}

class _LyricsFullscreenScreenState extends ConsumerState<LyricsFullscreenScreen> {
  static const _lineExtent = 46.0;
  final ScrollController _scrollController = ScrollController();
  int _lastActiveIndex = -1;

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final track = ref.watch(currentTrackProvider);
    final position = ref.watch(playbackPositionProvider);
    final duration = ref.watch(playbackDurationProvider);
    final isPlaying = ref.watch(isPlayingProvider);
    final syncOffsetMs = ref.watch(lyricsSyncOffsetMsProvider);

    if (track == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) Navigator.pop(context);
      });
      return const SizedBox.shrink();
    }

    final lines = _parseLyrics(track.lyrics);
    final activeIndex = _activeLineIndex(lines, position + Duration(milliseconds: syncOffsetMs), duration);
    _syncScrollToIndex(activeIndex);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        fit: StackFit.expand,
        children: [
          if (track.albumArtUrl != null)
            CachedNetworkImage(
              imageUrl: track.albumArtUrl!,
              fit: BoxFit.cover,
              errorWidget: (_, __, ___) => Container(color: const Color(0xFF0A0A0F)),
            ),
          BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 70, sigmaY: 70),
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withOpacity(0.55),
                    Colors.black.withOpacity(0.86),
                    Colors.black.withOpacity(0.96),
                  ],
                ),
              ),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 32),
                        color: Colors.white70,
                        onPressed: () => Navigator.pop(context),
                      ),
                      const Spacer(),
                      Column(
                        children: [
                          const Text(
                            'LYRICS',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 1.8,
                              color: Colors.white54,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${track.title} - ${track.artist}',
                            style: const TextStyle(fontSize: 12, color: Colors.white70),
                          ),
                        ],
                      ),
                      const Spacer(),
                      Text(
                        'Offset: ${syncOffsetMs >= 0 ? '+' : ''}${(syncOffsetMs / 1000).toStringAsFixed(1)}s',
                        style: const TextStyle(color: Colors.white60, fontSize: 11),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        icon: const Icon(Icons.remove_circle_outline_rounded, color: Colors.white70, size: 20),
                        onPressed: () {
                          final next = (syncOffsetMs - 250).clamp(-5000, 5000);
                          ref.read(lyricsSyncOffsetMsProvider.notifier).state = next;
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.add_circle_outline_rounded, color: Colors.white70, size: 20),
                        onPressed: () {
                          final next = (syncOffsetMs + 250).clamp(-5000, 5000);
                          ref.read(lyricsSyncOffsetMsProvider.notifier).state = next;
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.refresh_rounded, color: Colors.white70, size: 20),
                        onPressed: () => ref.read(lyricsSyncOffsetMsProvider.notifier).state = 0,
                      ),
                      Icon(
                        isPlaying ? Icons.graphic_eq_rounded : Icons.pause_rounded,
                        color: Colors.white60,
                        size: 22,
                      ),
                      const SizedBox(width: 16),
                    ],
                  ),
                ),
                const SizedBox(height: 6),
                Expanded(
                  child: Stack(
                    children: [
                      ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 220),
                        itemCount: lines.length,
                        itemExtent: _lineExtent,
                        itemBuilder: (context, index) {
                          final distance = (activeIndex - index).abs();
                          final isActive = index == activeIndex;
                          final opacity = isActive ? 1.0 : (1.0 - (distance * 0.16)).clamp(0.25, 0.7);
                          return AnimatedDefaultTextStyle(
                            duration: const Duration(milliseconds: 220),
                            curve: Curves.easeOutCubic,
                            style: TextStyle(
                              fontSize: isActive ? 30 : 23,
                              fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                              color: Colors.white.withOpacity(opacity),
                              height: 1.05,
                            ),
                            child: Text(
                              lines[index].text,
                              textAlign: TextAlign.center,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          );
                        },
                      ),
                      IgnorePointer(
                        child: Column(
                          children: [
                            Container(
                              height: 140,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [Colors.black.withOpacity(0.82), Colors.transparent],
                                ),
                              ),
                            ),
                            const Spacer(),
                            Container(
                              height: 170,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [Colors.transparent, Colors.black.withOpacity(0.9)],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  int _activeLineIndex(List<ParsedLyricLine> lines, Duration position, Duration duration) {
    final linesCount = lines.length;
    if (linesCount <= 0) return 0;

    if (lines.any((line) => line.time != null)) {
      for (var i = lines.length - 1; i >= 0; i--) {
        final time = lines[i].time;
        if (time != null && position >= time) {
          return i;
        }
      }
      return 0;
    }

    final totalMs = duration.inMilliseconds;
    if (totalMs <= 0) return 0;
    final ratio = (position.inMilliseconds / totalMs).clamp(0.0, 1.0);
    return (ratio * (linesCount - 1)).round();
  }

  void _syncScrollToIndex(int activeIndex) {
    if (!_scrollController.hasClients) return;
    if (activeIndex == _lastActiveIndex) return;
    _lastActiveIndex = activeIndex;

    final targetOffset = (activeIndex * _lineExtent) - (_lineExtent * 1.5);
    final clampedTarget = targetOffset.clamp(
      0.0,
      _scrollController.position.maxScrollExtent,
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_scrollController.hasClients) return;
      _scrollController.animateTo(
        clampedTarget,
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeOutCubic,
      );
    });
  }
}

class ParsedLyricLine {
  final Duration? time;
  final String text;

  const ParsedLyricLine({
    required this.time,
    required this.text,
  });
}

List<ParsedLyricLine> _parseLyrics(String? lyricsRaw) {
  if (lyricsRaw == null || lyricsRaw.trim().isEmpty) {
    return const [
      ParsedLyricLine(
        time: null,
        text: 'Текст пока загружается...',
      ),
      ParsedLyricLine(
        time: null,
        text: 'Если текст не появился, возможно для этого трека его нет в открытой базе.',
      ),
    ];
  }

  final lines = lyricsRaw.split('\n').map((line) => line.trimRight()).where((line) => line.trim().isNotEmpty);
  final tsRegExp = RegExp(r'^\[(\d{1,2}):(\d{2})(?:[.:](\d{1,3}))?\]\s*(.*)$');
  final parsed = <ParsedLyricLine>[];
  var timedCount = 0;

  for (final line in lines) {
    final match = tsRegExp.firstMatch(line.trim());
    if (match != null) {
      timedCount++;
      final mm = int.tryParse(match.group(1) ?? '') ?? 0;
      final ss = int.tryParse(match.group(2) ?? '') ?? 0;
      final msRaw = match.group(3);
      final lyricText = (match.group(4) ?? '').trim();
      final ms = msRaw == null
          ? 0
          : (msRaw.length == 2 ? int.parse(msRaw) * 10 : msRaw.length == 1 ? int.parse(msRaw) * 100 : int.parse(msRaw));
      parsed.add(
        ParsedLyricLine(
          time: Duration(minutes: mm, seconds: ss, milliseconds: ms),
          text: lyricText.isEmpty ? '...' : lyricText,
        ),
      );
    } else {
      parsed.add(ParsedLyricLine(time: null, text: line.trim()));
    }
  }

  if (timedCount == 0) {
    return parsed.map((line) => ParsedLyricLine(time: null, text: line.text)).toList(growable: false);
  }

  return parsed;
}
