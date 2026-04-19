import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:spectrum/core/db/schemas/track_schema.dart';
import 'package:spectrum/features/player/audio_player_service.dart';
import 'package:spectrum/features/player/dominant_color_provider.dart';
import 'package:spectrum/features/settings/settings_providers.dart';
import 'package:spectrum/features/visualizer/high_tech_visualizer.dart';
import 'package:spectrum/core/theme/spectrum_colors.dart';
import 'package:spectrum/features/jam/jam_screen.dart';
import 'package:spectrum/features/jam/jam_provider.dart';
import 'package:spectrum/core/db/isar_service.dart';
import 'package:spectrum/features/player/aura_background.dart';
import 'package:spectrum/features/player/lyrics_provider.dart';
import 'package:spectrum/features/player/synced_lyrics_view.dart';
import 'package:spectrum/core/network/lyrics_api.dart';
import 'package:spectrum/src/rust/api/lyrics.dart' as rust_lyrics;
import 'package:spectrum/core/navigation/navigator_key.dart';

class FullPlayerScreen extends ConsumerStatefulWidget {
  const FullPlayerScreen({super.key});

  @override
  ConsumerState<FullPlayerScreen> createState() => _FullPlayerScreenState();
}

class _FullPlayerScreenState extends ConsumerState<FullPlayerScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _scaleAnim;
  bool _showVisualizer = false;

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

    // Listen for playback errors and show them to the user
    ref.listenManual(playbackErrorProvider, (prev, next) {
      if (next != null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next, style: const TextStyle(color: Colors.white)),
            backgroundColor: Colors.redAccent.withOpacity(0.9),
            duration: const Duration(seconds: 5),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    });
    _animController.forward();
  }

  @override
  void dispose() {
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
    final size = MediaQuery.of(context).size;
    final artSize = (size.width * 0.65).clamp(200.0, 400.0);

    if (track == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) Navigator.pop(context);
      });
      return const SizedBox.shrink();
    }

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Background Layer: Aura or Visualizer
          const NeuralAura(),
          if (_showVisualizer)
            Consumer(
              builder: (context, ref, _) {
                final dominantColor =
                    ref.watch(dominantColorProvider).value ??
                        const Color(0xFF1E1E2E);
                final isPlaying = ref.watch(isPlayingProvider);
                return HighTechVisualizer(
                  key: const ValueKey('visualizer'),
                  baseColor: dominantColor,
                  isPlaying: isPlaying,
                );
              },
            ),
          SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: ConstrainedBox(
                    constraints:
                        BoxConstraints(minHeight: constraints.maxHeight),
                    child: IntrinsicHeight(
                      child: Column(
                        children: [
                          _buildTopBar(context, ref, track),
                          const Spacer(flex: 2),
                          ScaleTransition(
                            scale: _scaleAnim,
                            child:
                                _PlayerArtwork(track: track, artSize: artSize),
                          ),
                          const Spacer(flex: 2),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 32),
                            child: _TrackInfoRow(track: track),
                          ),
                          const SizedBox(height: 20),
                          const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 24),
                            child: _PlaybackSeekSection(),
                          ),
                          const SizedBox(height: 16),
                          const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 32),
                            child: _PlaybackControlsRow(),
                          ),
                          const SizedBox(height: 18),
                          const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 32),
                            child: _VolumeSection(),
                          ),
                          const SizedBox(height: 18),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 24),
                            child: GestureDetector(
                              onTap: () => _openLyricsFullscreen(context),
                              child: _LyricsPreviewCard(
                                track: track,
                                height: size.height * 0.18,
                                lyricsText: _buildLyricsPreviewText(track),
                                onQueuePressed: () =>
                                    _showQueueEditor(context, ref),
                                onSourcePressed: () =>
                                    showLyricsSourceSelector(context, ref, track),
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopBar(BuildContext context, WidgetRef ref, Track track) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Left: Close Button
          IconButton(
            icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 32),
            color: Colors.white70,
            onPressed: () => Navigator.pop(context),
          ),
          // Center: Track/Artist Info & Quality Badge
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'СЕЙЧАС ИГРАЕТ',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 2.0,
                    color: Colors.white.withOpacity(0.4),
                  ),
                ),
                const SizedBox(height: 6),
                const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _AudioQualityBadge(),
                    SizedBox(width: 8),
                    _NeuralRadioBadge(),
                  ],
                ),
              ],
            ),
          ),
          // Right: Toolbar Buttons
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: Icon(
                    _showVisualizer
                        ? Icons.visibility_off_rounded
                        : Icons.stream_rounded,
                    size: 22),
                color: _showVisualizer
                    ? Theme.of(context).colorScheme.primary
                    : Colors.white70,
                tooltip: 'Визуализация',
                onPressed: () =>
                    setState(() => _showVisualizer = !_showVisualizer),
              ),
              IconButton(
                icon: const Icon(Icons.queue_music_rounded, size: 22),
                color: Colors.white70,
                tooltip: 'Очередь',
                onPressed: () => _showQueueEditor(context, ref),
              ),
              IconButton(
                icon: const Icon(Icons.layers_rounded, size: 22),
                color: (ref.watch(currentLyricsSourceProvider) != null)
                    ? SpectrumColors.accent
                    : Colors.white70,
                tooltip: 'Источник Текста',
                onPressed: () => showLyricsSourceSelector(context, ref, track),
              ),
              IconButton(
                icon: const Icon(Icons. hub_outlined, size: 22),
                color: ref.watch(jamProvider) != null
                    ? SpectrumColors.accent
                    : Colors.white70,
                tooltip: 'Jam (Слушать вместе)',
                onPressed: () {
                  globalNavigatorKey.currentState?.push(
                    MaterialPageRoute(
                        builder: (ctx) => const JamSessionScreen()),
                  );
                },
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
        ],
      ),
    );
  }

  String _buildLyricsPreviewText(Track track) {
    final parsed = _parseLyrics(track.lyrics);
    if (parsed.isNotEmpty) {
      return parsed.take(8).map((line) => line.text).join('\n');
    }
    return 'Текст песни пока не найден.\n\n'
        '${track.title}\n${track.artist}\n\n'
        'Открой полноэкранный режим текста позже, когда лирика появится в данных трека.';
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
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              ListTile(
                leading:
                    const Icon(Icons.download_rounded, color: Colors.white70),
                title: const Text('Скачать трек',
                    style: TextStyle(color: Colors.white)),
                subtitle: track.localPath == null
                    ? const Text(
                        'Сохранить для офлайн',
                        style: TextStyle(color: Colors.white38, fontSize: 12),
                      )
                    : null,
                onTap: () async {
                  Navigator.pop(ctx);
                  if (track.localPath == null) {
                    final scaffold = ScaffoldMessenger.of(context);
                    scaffold.showSnackBar(
                      const SnackBar(content: Text('Скачивание началось...')),
                    );
                    final success = await ref
                        .read(audioPlayerServiceProvider)
                        .downloadCurrentTrack();
                    if (mounted) {
                      scaffold.hideCurrentSnackBar();
                      scaffold.showSnackBar(
                        SnackBar(
                          content: Text(success
                              ? 'Трек успешно сохранён для офлайн прослушивания!'
                              : 'Ошибка при сохранении трека.'),
                          backgroundColor:
                              success ? Colors.green[800] : Colors.red[800],
                        ),
                      );
                    }
                  }
                },
              ),
              ListTile(
                leading: const Icon(Icons.queue_music_rounded,
                    color: Colors.white70),
                title: const Text('Очередь',
                    style: TextStyle(color: Colors.white)),
                subtitle: const Text('Редактировать порядок и удалить треки',
                    style: TextStyle(color: Colors.white38, fontSize: 12)),
                onTap: () {
                  Navigator.pop(ctx);
                  _showQueueEditor(context, ref);
                },
              ),
              ListTile(
                leading: const Icon(Icons.share_rounded, color: Colors.white70),
                title: const Text('Поделиться',
                    style: TextStyle(color: Colors.white)),
                onTap: () async {
                  Navigator.pop(ctx);
                  final shareText = '${track.title} - ${track.artist}'
                      '${track.spotifyId != null ? '\nhttps://open.spotify.com/track/${track.spotifyId}' : ''}';
                  await Clipboard.setData(ClipboardData(text: shareText));
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text('Информация о треке скопирована')),
                    );
                  }
                },
              ),
              ListTile(
                leading: const Icon(Icons.info_outline_rounded,
                    color: Colors.white70),
                title: const Text('Информация о треке',
                    style: TextStyle(color: Colors.white)),
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
            opacity:
                CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
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
                    child: Text('Очередь пуста',
                        style: TextStyle(color: Colors.white70)),
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
                          ref
                              .read(audioPlayerServiceProvider)
                              .reorderQueue(oldIndex, newIndex);
                        },
                        itemBuilder: (context, index) {
                          final item = queue[index];
                          final isCurrent = index == queueIndex;
                          return ListTile(
                            key: ValueKey(
                                '${item.id}_${item.spotifyId ?? item.title}_$index'),
                            leading: Icon(
                              isCurrent
                                  ? Icons.graphic_eq_rounded
                                  : Icons.music_note_rounded,
                              color: isCurrent
                                  ? Theme.of(context).colorScheme.primary
                                  : Colors.white54,
                            ),
                            title: Text(
                              item.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color:
                                    isCurrent ? Colors.white : Colors.white70,
                                fontWeight: isCurrent
                                    ? FontWeight.w700
                                    : FontWeight.w500,
                              ),
                            ),
                            subtitle: Text(
                              item.artist,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(color: Colors.white54),
                            ),
                            trailing: IconButton(
                              icon: const Icon(Icons.close_rounded,
                                  color: Colors.white54),
                              onPressed: () => ref
                                  .read(audioPlayerServiceProvider)
                                  .removeFromQueue(index),
                            ),
                            onTap: () {
                              ref
                                  .read(audioPlayerServiceProvider)
                                  .playQueue(queue, initialIndex: index);
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

class _AudioQualityBadge extends ConsumerWidget {
  const _AudioQualityBadge();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sampleRate = ref.watch(audioSampleRateProvider);
    final bitDepth = ref.watch(audioBitDepthProvider);
    final format = ref.watch(audioFormatProvider);
    final isTidalMode = ref.watch(tidalEnhancementProvider);

    if (sampleRate == null) return const SizedBox.shrink();

    // Show REAL values from mpv
    final kHz = (sampleRate / 1000.0).toStringAsFixed(1);
    final bitDisplay = bitDepth != null ? '$bitDepth bit' : '— bit';
    final isHiRes = sampleRate > 48000;
    final badgeColor = isHiRes
        ? Colors.cyanAccent
        : (isTidalMode ? Colors.tealAccent : Colors.white38);

    return GestureDetector(
      onTap: () {
        showDialog<void>(
          context: context,
          builder: (ctx) => AlertDialog(
            backgroundColor: const Color(0xFF1A1A2E),
            title: Row(
              children: [
                Icon(Icons.tune_rounded, color: badgeColor),
                const SizedBox(width: 12),
                const Text('Audio Engine'),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _TechDetailRow(label: 'Output Sample Rate', value: '$kHz kHz'),
                _TechDetailRow(label: 'Bit Depth', value: bitDisplay),
                _TechDetailRow(label: 'MPV Format', value: format ?? 'unknown'),
                const Divider(color: Colors.white12, height: 24),
                const Text('Active Processing:',
                    style: TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                        fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                if (isTidalMode) ...[
                  const _AlgoItem(
                      name: 'SoX Resampler → 96 kHz',
                      desc: 'High-precision sinc interpolation'),
                  const _AlgoItem(
                      name: 'Bass/Treble Shelf EQ',
                      desc: 'Restoring low-end warmth and treble sparkle'),
                  const _AlgoItem(
                      name: 'Parametric EQ (firequalizer)',
                      desc: 'Detail recovery in sub-bass and upper harmonics'),
                  const _AlgoItem(
                      name: 'Stereo Widener',
                      desc: 'Subtle stereo image expansion'),
                ] else
                  const _AlgoItem(
                      name: 'Transparent',
                      desc: 'Direct passthrough, no processing'),
                if (ref.watch(pcOfflineSuperResEnabledProvider)) ...[
                  const Divider(color: Colors.white12, height: 24),
                  const _AlgoItem(
                      name: '🧠 AudioSR (Offline AI)',
                      desc:
                          'Diffusion neural network that reconstructs missing '
                          'high-frequency content. Falls back to FFmpeg DSP if not installed.'),
                ],
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: isHiRes
              ? Colors.cyanAccent.withOpacity(0.08)
              : (isTidalMode
                  ? Colors.tealAccent.withOpacity(0.06)
                  : Colors.white.withOpacity(0.05)),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: isHiRes
                ? Colors.cyanAccent.withOpacity(0.3)
                : (isTidalMode
                    ? Colors.tealAccent.withOpacity(0.2)
                    : Colors.white10),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isHiRes || isTidalMode) ...[
              Icon(
                isHiRes ? Icons.auto_awesome : Icons.equalizer_rounded,
                size: 12,
                color: badgeColor,
              ),
              const SizedBox(width: 6),
            ],
            Text(
              '$kHz kHz / $bitDisplay',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: badgeColor,
                letterSpacing: 0.2,
              ),
            ),
            if (isHiRes) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                decoration: BoxDecoration(
                  color: Colors.cyanAccent,
                  borderRadius: BorderRadius.circular(2),
                ),
                child: const Text(
                  'HI-RES',
                  style: TextStyle(
                    fontSize: 7,
                    color: Colors.black,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ] else if (isTidalMode) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                decoration: BoxDecoration(
                  color: Colors.tealAccent.withOpacity(0.8),
                  borderRadius: BorderRadius.circular(2),
                ),
                child: const Text(
                  'DSP',
                  style: TextStyle(
                    fontSize: 7,
                    color: Colors.black,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _NeuralRadioBadge extends ConsumerWidget {
  const _NeuralRadioBadge();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final enabled = ref.watch(neuralRadioEnabledProvider);
    if (!enabled) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: SpectrumColors.accent.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
            color: SpectrumColors.accent.withOpacity(0.3), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.auto_awesome, size: 11, color: SpectrumColors.accent),
          const SizedBox(width: 6),
          Text(
            'NEURAL FLOW',
            style: TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w900,
              color: SpectrumColors.accent,
              letterSpacing: 1.0,
            ),
          ),
        ],
      ),
    );
  }
}

class _TechDetailRow extends StatelessWidget {
  final String label, value;
  const _TechDetailRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: const TextStyle(color: Colors.white54, fontSize: 13)),
          Text(value,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}

class _AlgoItem extends StatelessWidget {
  final String name, desc;
  const _AlgoItem({required this.name, required this.desc});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(name,
              style: const TextStyle(
                  color: Colors.cyanAccent,
                  fontSize: 12,
                  fontWeight: FontWeight.bold)),
          const SizedBox(height: 2),
          Text(desc,
              style: const TextStyle(color: Colors.white38, fontSize: 11)),
        ],
      ),
    );
  }
}

class _PlayerBackdrop extends ConsumerWidget {
  final Track track;

  const _PlayerBackdrop({super.key, required this.track});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dominantColorAsync = ref.watch(dominantColorProvider);
    final baseColor = dominantColorAsync.when(
      data: (color) => color ?? const Color(0xFF1A1A2E),
      loading: () => const Color(0xFF1A1A2E),
      error: (_, __) => const Color(0xFF1A1A2E),
    );

    return Stack(
      fit: StackFit.expand,
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 400),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                baseColor.withOpacity(0.85),
                const Color(0xFF000000),
              ],
            ),
          ),
        ),
        if (track.albumArtUrl != null)
          Positioned.fill(
            child: Opacity(
              opacity: 0.6,
              child: ImageFiltered(
                imageFilter: ImageFilter.blur(sigmaX: 70, sigmaY: 70),
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 400),
                  child: SizedBox.expand(
                    key: ValueKey(track.albumArtUrl),
                    child: CachedNetworkImage(
                      imageUrl: track.albumArtUrl!,
                      fit: BoxFit.cover,
                      memCacheWidth: 600,
                      errorWidget: (_, __, ___) =>
                          SpectrumColors.artworkErrorPlaceholder(size: 600),
                    ),
                  ),
                ),
              ),
            ),
          ),
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              stops: const [0.0, 0.4, 1.0],
              colors: [
                Colors.black.withOpacity(0.3),
                Colors.black.withOpacity(0.8),
                Colors.black.withOpacity(0.98),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _PlayerArtwork extends ConsumerWidget {
  final Track track;
  final double artSize;

  const _PlayerArtwork({
    required this.track,
    required this.artSize,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dominantColorAsync = ref.watch(dominantColorProvider);
    final baseColor = dominantColorAsync.when(
      data: (color) => color ?? const Color(0xFF1C1C2E),
      loading: () => const Color(0xFF1C1C2E),
      error: (_, __) => const Color(0xFF1C1C2E),
    );

    return Stack(
      alignment: Alignment.center,
      children: [
        // Ambient Glow (Spectrum Fusion / Cyberpunk)
        AnimatedContainer(
          duration: const Duration(milliseconds: 1000),
          width: artSize * 0.9,
          height: artSize * 0.9,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: baseColor.withOpacity(0.35),
                blurRadius: 80,
                spreadRadius: 10,
              ),
            ],
          ),
        ),
        Hero(
          tag: _playerArtHeroTag(track),
          child: Container(
            width: artSize,
            height: artSize,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white.withOpacity(0.1), width: 1),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.4),
                  blurRadius: 30,
                  offset: const Offset(0, 15),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 400),
                child: track.albumArtUrl != null
                    ? CachedNetworkImage(
                        key: ValueKey(track.albumArtUrl),
                        imageUrl: track.albumArtUrl!,
                        fit: BoxFit.cover,
                        memCacheWidth: 1024,
                        placeholder: (_, __) => Container(
                          color: const Color(0xFF16161E),
                          child: const Center(
                            child: Icon(Icons.music_note_rounded,
                                size: 64, color: Colors.white10),
                          ),
                        ),
                        errorWidget: (_, __, ___) =>
                            SpectrumColors.artworkErrorPlaceholder(
                                size: artSize),
                      )
                    : SpectrumColors.artworkErrorPlaceholder(size: artSize),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _TrackInfoRow extends ConsumerWidget {
  final Track track;

  const _TrackInfoRow({required this.track});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isLoading = ref.watch(isLoadingStreamProvider);
    final isAiProcessing = ref.watch(isAiProcessingProvider);

    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                track.title,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
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
                  color: Colors.white.withOpacity(0.5),
                  fontWeight: FontWeight.w500,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              if (ref.watch(isSuperResActiveProvider))
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Row(
                    children: [
                      const Icon(Icons.auto_awesome,
                          size: 14, color: Colors.cyanAccent),
                      const SizedBox(width: 6),
                      Text(
                        'AI SUPER-RES',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          color: Colors.cyanAccent.withOpacity(0.9),
                          letterSpacing: 1.0,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
        IconButton(
          icon: Icon(
            track.isFavorite
                ? Icons.favorite_rounded
                : Icons.favorite_border_rounded,
            color: track.isFavorite ? SpectrumColors.accent : Colors.white54,
            size: 28,
          ),
          onPressed: () async {
            final isar = IsarService.instance;
            await isar.writeTxn(() async {
              track.isFavorite = !track.isFavorite;
              if (track.isFavorite) track.inLibrary = true;
              await isar.tracks.put(track);
            });
            ref.read(currentTrackProvider.notifier).state = null;
            ref.read(currentTrackProvider.notifier).state = track;
          },
        ),
        if (isLoading || isAiProcessing)
          const Padding(
            padding: EdgeInsets.only(left: 8.0),
            child: SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                  strokeWidth: 2, color: Colors.white54),
            ),
          ),
      ],
    );
  }
}

class _AiProcessingIndicator extends ConsumerWidget {
  const _AiProcessingIndicator();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isProcessing = ref.watch(isAiProcessingProvider);
    if (!isProcessing) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.orangeAccent.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.orangeAccent.withOpacity(0.3)),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 10,
            height: 10,
            child: CircularProgressIndicator(
              strokeWidth: 1.5,
              color: Colors.orangeAccent,
            ),
          ),
          SizedBox(width: 10),
          Text(
            'DEEP AI ENHANCING...',
            style: TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w800,
              color: Colors.orangeAccent,
              letterSpacing: 1.0,
            ),
          ),
        ],
      ),
    );
  }
}

class _PlaybackSeekSection extends ConsumerStatefulWidget {
  const _PlaybackSeekSection();

  @override
  ConsumerState<_PlaybackSeekSection> createState() =>
      _PlaybackSeekSectionState();
}

class _PlaybackSeekSectionState extends ConsumerState<_PlaybackSeekSection> {
  bool _isSeeking = false;
  double _seekValue = 0;

  String _fmt(Duration d) {
    final m = d.inMinutes;
    final s = d.inSeconds % 60;
    return '$m:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final position = ref.watch(playbackPositionProvider);
    final duration = ref.watch(playbackDurationProvider);
    final maxMs = duration.inMilliseconds.toDouble();
    final posMs = position.inMilliseconds.toDouble();
    final sliderMax = maxMs > 0 ? maxMs : 1.0;
    final sliderValue = _isSeeking ? _seekValue : posMs.clamp(0.0, sliderMax);

    return Column(
      children: [
        SliderTheme(
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
              ref
                  .read(audioPlayerServiceProvider)
                  .seek(Duration(milliseconds: v.toInt()));
              setState(() => _isSeeking = false);
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _fmt(_isSeeking
                    ? Duration(milliseconds: _seekValue.toInt())
                    : position),
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.white.withOpacity(0.45),
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                _fmt(duration),
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.white.withOpacity(0.45),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _PlaybackControlsRow extends ConsumerWidget {
  const _PlaybackControlsRow();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isPlaying = ref.watch(isPlayingProvider);
    final isShuffling = ref.watch(isShufflingProvider);
    final djEnabled = ref.watch(djModeEnabledProvider);
    final repeatMode = ref.watch(repeatModeProvider);

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        IconButton(
          iconSize: 28,
          icon: const Icon(Icons.shuffle_rounded),
          color: djEnabled
              ? Colors.white24
              : (isShuffling
                  ? Theme.of(context).colorScheme.primary
                  : Colors.white54),
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
        GestureDetector(
          onTap: () => ref.read(audioPlayerServiceProvider).togglePlay(),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.white.withOpacity(0.3),
                  blurRadius: 20,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Icon(
              isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
              size: 40,
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
          color: repeatMode == PlayerRepeatMode.off
              ? Colors.white54
              : Theme.of(context).colorScheme.primary,
          onPressed: () {
            final next = PlayerRepeatMode.values[
                (repeatMode.index + 1) % PlayerRepeatMode.values.length];
            ref.read(repeatModeProvider.notifier).state = next;
          },
        ),
      ],
    );
  }
}

class _VolumeSection extends ConsumerWidget {
  const _VolumeSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final volume = ref.watch(volumeProvider);

    return Row(
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
    );
  }
}

class _LyricsPreviewCard extends ConsumerWidget {
  final Track track;
  final double height;
  final String lyricsText;
  final VoidCallback onQueuePressed;
  final VoidCallback onSourcePressed;

  const _LyricsPreviewCard({
    required this.track,
    required this.height,
    required this.lyricsText,
    required this.onQueuePressed,
    required this.onSourcePressed,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lyrics = ref.watch(lyricsProvider);
    final activeIndex = ref.watch(currentLyricIndexProvider);

    String displayLyrics = lyricsText;
    if (lyrics.isNotEmpty && activeIndex >= 0) {
      // Show current + next line for context
      final current = lyrics[activeIndex].text;
      final next = (activeIndex + 1 < lyrics.length)
          ? '\n${lyrics[activeIndex + 1].text}'
          : '';
      displayLyrics = '$current$next';
    }

    return Container(
      width: double.infinity,
      height: height,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.04),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withOpacity(0.08), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.lyrics_rounded, color: Colors.white70, size: 16),
              const SizedBox(width: 8),
              const Text(
                'Текст песни',
                style: TextStyle(
                  color: Colors.white70,
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
              ),
              IconButton(
                icon: Icon(Icons.layers_rounded,
                    color: (ref.watch(currentLyricsSourceProvider) != null) 
                        ? SpectrumColors.accent 
                        : Colors.white70, 
                    size: 18),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 20, minHeight: 20),
                onPressed: onSourcePressed,
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.queue_music_rounded,
                    color: Colors.white70, size: 18),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 20, minHeight: 20),
                onPressed: onQueuePressed,
              ),
              const SizedBox(width: 8),
              const Icon(Icons.open_in_full_rounded,
                  color: Colors.white24, size: 18),
            ],
          ),
          const SizedBox(height: 12),
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: Text(
                displayLyrics.toUpperCase(),
                key: ValueKey(activeIndex),
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: (lyrics.isNotEmpty && activeIndex >= 0)
                      ? Colors.white
                      : Colors.white54,
                  fontSize: (lyrics.isNotEmpty && activeIndex >= 0) ? 18 : 13,
                  fontWeight: (lyrics.isNotEmpty && activeIndex >= 0)
                      ? FontWeight.w900
                      : FontWeight.w500,
                  height: 1.4,
                  letterSpacing: (lyrics.isNotEmpty && activeIndex >= 0) ? -0.5 : 0.2,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

IconData _repeatIconData(PlayerRepeatMode mode) {
  switch (mode) {
    case PlayerRepeatMode.one:
      return Icons.repeat_one_rounded;
    case PlayerRepeatMode.all:
    case PlayerRepeatMode.off:
      return Icons.repeat_rounded;
  }
}

String _playerArtHeroTag(Track track) =>
    'player-art-${track.spotifyId ?? track.id}';

class LyricsFullscreenScreen extends ConsumerStatefulWidget {
  const LyricsFullscreenScreen({super.key});

  @override
  ConsumerState<LyricsFullscreenScreen> createState() =>
      _LyricsFullscreenScreenState();
}

class _LyricsFullscreenScreenState
    extends ConsumerState<LyricsFullscreenScreen> {
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

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        fit: StackFit.expand,
        children: [
          if (track.albumArtUrl != null)
            CachedNetworkImage(
              imageUrl: track.albumArtUrl!,
              fit: BoxFit.cover,
              errorWidget: (_, __, ___) =>
                  Container(color: const Color(0xFF0A0A0F)),
            ),
          BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 70, sigmaY: 70),
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withOpacity(0.4),
                    Colors.black.withOpacity(0.7),
                    Colors.black.withOpacity(0.85),
                  ],
                ),
              ),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                _buildLyricsTitleBar(context, ref, track, syncOffsetMs, isPlaying),
                const Expanded(
                  child: SyncedLyricsView(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }


  Widget _buildLyricsTitleBar(BuildContext context, WidgetRef ref, Track track, 
      int syncOffsetMs, bool isPlaying) {
    return Padding(
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
                'SOURCE: ${ref.watch(currentLyricsSourceProvider) ?? 'AUTOMATIC'}',
                style: const TextStyle(
                  fontSize: 7,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 2.0,
                  color: Color(0xFF7C3AED), // Accent color for tech feel
                ),
              ),
              const SizedBox(height: 2),
              Text(
                '${track.title.toUpperCase()} // ${track.artist.toUpperCase()}',
                style: const TextStyle(
                  fontSize: 10, 
                  fontFamily: 'monospace',
                  color: Colors.white70,
                  letterSpacing: 1.0,
                ),
              ),
            ],
          ),
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.layers_rounded, color: Colors.white70, size: 20),
            tooltip: 'Switch Lyrics Source',
            onPressed: () => showLyricsSourceSelector(context, ref, track),
          ),
          const SizedBox(width: 8),
          Text(
            '${syncOffsetMs >= 0 ? '+' : ''}${(syncOffsetMs / 1000).toStringAsFixed(1)}s',
            style: const TextStyle(color: Colors.white60, fontSize: 11, fontFamily: 'monospace'),
          ),
          IconButton(
            icon: const Icon(Icons.remove_circle_outline_rounded,
                color: Colors.white70, size: 20),
            onPressed: () {
              final next = (syncOffsetMs - 250).clamp(-5000, 5000);
              ref.read(lyricsSyncOffsetMsProvider.notifier).state = next;
            },
          ),
          IconButton(
            icon: const Icon(Icons.add_circle_outline_rounded,
                color: Colors.white70, size: 20),
            onPressed: () {
              final next = (syncOffsetMs + 250).clamp(-5000, 5000);
              ref.read(lyricsSyncOffsetMsProvider.notifier).state = next;
            },
          ),
          const SizedBox(width: 12),
        ],
      ),
    );
  }
}

void showLyricsSourceSelector(BuildContext context, WidgetRef ref, Track track) {
  const providers = ['LRCLIB', 'LRCLIB Search', 'NetEase', 'Genius', 'Lyrics.ovh'];
  
  showModalBottomSheet(
    context: context,
    backgroundColor: const Color(0xFF0F0F1A),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      side: BorderSide(color: Colors.white12),
    ),
    builder: (ctx) {
      return FutureBuilder<List<rust_lyrics.SpectrumLyrics>>(
        future: LyricsApi().fetchAllLyrics(track),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return SizedBox(
              height: 300,
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const CircularProgressIndicator(color: Color(0xFF7C3AED)),
                    const SizedBox(height: 16),
                    Text(
                      'CHECKING ${providers.length} PROVIDERS...',
                      style: const TextStyle(color: Colors.white30, fontSize: 10, letterSpacing: 2),
                    ),
                  ],
                ),
              ),
            );
          }

          final results = snapshot.data ?? [];

          return Container(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Text('ВЫБОР ИСТОЧНИКА', style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold, letterSpacing: 2.0)),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: results.isNotEmpty ? const Color(0xFF7C3AED).withOpacity(0.2) : Colors.red.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        '${results.length} / ${providers.length}',
                        style: TextStyle(
                          color: results.isNotEmpty ? const Color(0xFF7C3AED) : Colors.red.shade300,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'Проверено: ${providers.join(" · ")}',
                  style: const TextStyle(color: Colors.white24, fontSize: 9),
                ),
                const SizedBox(height: 16),
                if (results.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 24),
                    child: Center(child: Text('НИ ОДИН ПРОВАЙДЕР НЕ НАШЁЛ ТЕКСТ', style: TextStyle(color: Colors.white24, fontSize: 11))),
                  )
                else
                  Flexible(
                    child: ListView.separated(
                      shrinkWrap: true,
                      itemCount: results.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (ctx, index) {
                        final res = results[index];
                        final isSynced = res.lines.isNotEmpty;
                        final currentSource = ref.read(currentLyricsSourceProvider);
                        final isActive = currentSource == res.source;
                        return ListTile(
                          onTap: () {
                            ref.read(manualLyricsContentProvider.notifier).state = res.content;
                            ref.read(currentLyricsSourceProvider.notifier).state = res.source;
                            Navigator.pop(context);
                          },
                          dense: true,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                            side: BorderSide(
                              color: isActive ? const Color(0xFF7C3AED).withOpacity(0.5) : Colors.white.withOpacity(0.05),
                            ),
                          ),
                          tileColor: isActive ? const Color(0xFF7C3AED).withOpacity(0.08) : Colors.white.withOpacity(0.03),
                          leading: Icon(
                            isSynced ? Icons.timer_outlined : Icons.notes_rounded,
                            color: isSynced ? const Color(0xFF7C3AED) : Colors.white38,
                            size: 18,
                          ),
                          title: Text(res.source.toUpperCase(), style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                          subtitle: Text(
                            isSynced ? 'СИНХРОНИЗИРОВАННЫЙ' : 'ТЕКСТ',
                            style: const TextStyle(color: Colors.white38, fontSize: 9),
                          ),
                          trailing: isActive
                              ? const Icon(Icons.check_circle_rounded, color: Color(0xFF7C3AED), size: 18)
                              : const Icon(Icons.chevron_right_rounded, color: Colors.white24),
                        );
                      },
                    ),
                  ),
                const SizedBox(height: 16),
                TextButton(
                  onPressed: () {
                    ref.read(manualLyricsOverrideProvider.notifier).state = null;
                    ref.read(manualLyricsContentProvider.notifier).state = null;
                    ref.read(currentLyricsSourceProvider.notifier).state = null;
                    Navigator.pop(context);
                  },
                  child: const Text('СБРОСИТЬ НА АВТОМАТИЧЕСКИЙ', style: TextStyle(color: Colors.white30, fontSize: 10)),
                ),
              ],
            ),
          );
        },
      );
    },
  );
}
class ParsedLyricLine {
  final Duration? time;
  final String text;
  const ParsedLyricLine({required this.time, required this.text});
}

List<ParsedLyricLine> _parseLyrics(String? lyricsRaw) {
  if (lyricsRaw == null || lyricsRaw.trim().isEmpty) return [];
  return lyricsRaw.split('\n').map((line) => ParsedLyricLine(time: null, text: line.trim())).toList();
}
