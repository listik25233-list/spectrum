import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:spectrum/features/library/playlists_provider.dart';
import 'package:spectrum/features/library/tracks_provider.dart';
import 'package:spectrum/features/library/playlist_screen.dart';
import 'package:spectrum/core/theme/spectrum_colors.dart';
import 'package:spectrum/features/player/audio_player_service.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _bgController;

  @override
  void initState() {
    super.initState();
    _bgController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 20),
    )..repeat();
  }

  @override
  void dispose() {
    _bgController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          // 1. NEURAL BACKGROUND LAYER
          Positioned.fill(
              child: RepaintBoundary(
                child: _AnimatedPulseBackground(controller: _bgController),
              )),

          // 2. SCROLLABLE CONTENT
          CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              _buildSliverAppBar(context),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 0.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // HERO SECTION
                      const _HeroSessionPanel(),

                      const SizedBox(height: 32),
                      _buildSectionHeader('NEURAL MIXES', 'MIX-RX-7'),
                      const SizedBox(height: 16),
                      _buildMixesCarousel(ref),

                      const SizedBox(height: 48),
                      _buildSectionHeader('RECENT ACCESS', 'LOG-ENTRY'),
                      const SizedBox(height: 16),
                      _buildRecentGrid(ref),

                      const SizedBox(height: 48),
                      _buildSectionHeader('MASTER COLLECTIONS', 'MQA-HIRES'),
                      const SizedBox(height: 16),
                      _buildMasterCarousel(ref),

                      const SizedBox(
                          height: 140), // Space for persistent player
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSliverAppBar(BuildContext context) {
    return SliverAppBar(
      expandedHeight: 100,
      collapsedHeight: 70,
      floating: false,
      pinned: true,
      backgroundColor: SpectrumColors.background.withOpacity(0.85),
      elevation: 0,
      flexibleSpace: FlexibleSpaceBar(
        titlePadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        centerTitle: false,
        title: Row(
          children: [
            Text(
              'DASHBOARD',
              style: TextStyle(
                color: SpectrumColors.textPrimary,
                fontWeight: FontWeight.w900,
                fontSize: 20,
                letterSpacing: 2.0,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                border:
                    Border.all(color: SpectrumColors.accent.withOpacity(0.5)),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                'v1.0.0',
                style: TextStyle(
                    color: SpectrumColors.accent,
                    fontSize: 8,
                    fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
      actions: [
        IconButton(
          icon:
              Icon(Icons.hub_outlined, color: SpectrumColors.accent, size: 20),
          onPressed: () {},
        ),
        const SizedBox(width: 24),
      ],
    );
  }

  Widget _buildSectionHeader(String title, String id) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.baseline,
        textBaseline: TextBaseline.alphabetic,
        children: [
          Container(
            width: 3,
            height: 14,
            decoration: BoxDecoration(
              color: SpectrumColors.accent,
              boxShadow: [
                BoxShadow(
                    color: SpectrumColors.accent.withOpacity(0.5),
                    blurRadius: 8)
              ],
            ),
          ),
          const SizedBox(width: 12),
          Text(
            title,
            style: TextStyle(
              color: SpectrumColors.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.5,
            ),
          ),
          const Spacer(),
          Text(
            '[ $id ]',
            style: TextStyle(
              color: SpectrumColors.textUltraMuted,
              fontSize: 9,
              fontFamily: 'monospace',
              letterSpacing: 1.0,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMixesCarousel(WidgetRef ref) {
    final playlistsAsync = ref.watch(playlistsProvider);
    return playlistsAsync.when(
      data: (playlists) {
        if (playlists.isEmpty)
          return const SizedBox(
              height: 200,
              child: Center(child: Text('No neural mixes found.')));
        return SizedBox(
          height: 220,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: playlists.length,
            physics: const BouncingScrollPhysics(),
            itemBuilder: (context, index) {
              final playlist = playlists[index];
              return _CarouselCard(
                title: playlist.name,
                subtitle: '${playlist.trackSpotifyIds.length} SIGNALS',
                imageUrl: playlist.artworkUrl,
                onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (ctx) => PlaylistScreen(playlist: playlist))),
              );
            },
          ),
        );
      },
      loading: () => const SizedBox(
          height: 200, child: Center(child: CircularProgressIndicator())),
      error: (_, __) => const SizedBox(height: 200),
    );
  }

  Widget _buildMasterCarousel(WidgetRef ref) {
    return SizedBox(
      height: 220,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: 4,
        physics: const BouncingScrollPhysics(),
        itemBuilder: (context, index) {
          final titles = [
            'Crimson Sessions',
            'Liquid Quartz',
            'Neural Pulse',
            'Void Echoes'
          ];
          return _CarouselCard(
            title: titles[index],
            subtitle: 'HI-RES MASTER',
            imageUrl:
                'https://images.unsplash.com/photo-1614613535308-eb5fbd3d2c17?w=400&h=400&fit=crop',
            onTap: () {},
            isMaster: true,
          );
        },
      ),
    );
  }

  Widget _buildRecentGrid(WidgetRef ref) {
    final tracksAsync = ref.watch(recentTracksProvider);
    return tracksAsync.when(
      data: (tracks) {
        if (tracks.isEmpty) return const SizedBox.shrink();
        final recent = tracks.take(6).toList();
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 2.8,
            ),
            itemCount: recent.length,
            itemBuilder: (context, index) {
              final track = recent[index];
              return Container(
                decoration: BoxDecoration(
                  color: SpectrumColors.surface.withOpacity(0.4),
                  borderRadius: BorderRadius.circular(4),
                  border:
                      Border.all(color: SpectrumColors.border.withOpacity(0.5)),
                ),
                child: InkWell(
                  onTap: () =>
                      ref.read(audioPlayerServiceProvider).playTrack(track),
                  borderRadius: BorderRadius.circular(4),
                  child: Row(
                    children: [
                      ClipRRect(
                        borderRadius: const BorderRadius.horizontal(
                            left: Radius.circular(3)),
                        child: AspectRatio(
                          aspectRatio: 1,
                          child: track.albumArtUrl != null
                              ? CachedNetworkImage(
                                  imageUrl: track.albumArtUrl!,
                                  fit: BoxFit.cover)
                              : Container(color: SpectrumColors.surface),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(track.title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                    color: SpectrumColors.textPrimary,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w800)),
                            Text(track.artist,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                    color: SpectrumColors.textMuted,
                                    fontSize: 10,
                                    letterSpacing: 0.5)),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Icon(Icons.play_circle_outline,
                          color: SpectrumColors.accent.withOpacity(0.3),
                          size: 16),
                      const SizedBox(width: 12),
                    ],
                  ),
                ),
              );
            },
          ),
        );
      },
      loading: () => const SizedBox(height: 100),
      error: (_, __) => const SizedBox(height: 100),
    );
  }
}

class _HeroSessionPanel extends ConsumerWidget {
  const _HeroSessionPanel();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.all(24),
      height: 180,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            SpectrumColors.accent.withOpacity(0.2),
            SpectrumColors.surface,
          ],
        ),
        border: Border.all(color: SpectrumColors.accent.withOpacity(0.15)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Stack(
          children: [
            Positioned(
              right: -20,
              top: -20,
              child: Icon(Icons.auto_awesome_outlined,
                  size: 150, color: SpectrumColors.accent.withOpacity(0.1)),
            ),
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: SpectrumColors.accent.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text('NEURAL STATION ACTIVE',
                        style: TextStyle(
                            color: SpectrumColors.accent,
                            fontSize: 8,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.5)),
                  ),
                  const SizedBox(height: 12),
                  Text('Crimson\nObsidian',
                      style: TextStyle(
                          color: SpectrumColors.textPrimary,
                          fontSize: 32,
                          fontWeight: FontWeight.w900,
                          height: 1.0)),
                  const Spacer(),
                  Row(
                    children: [
                      ElevatedButton(
                        onPressed: () {},
                        style: ElevatedButton.styleFrom(
                          backgroundColor: SpectrumColors.accent,
                          foregroundColor: Colors.black,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 24, vertical: 12),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(4)),
                        ),
                        child: const Text('ENGAGE AUTO-DJ',
                            style: TextStyle(
                                fontWeight: FontWeight.w900, fontSize: 11)),
                      ),
                      const SizedBox(width: 16),
                      Text('BIT DEPTH: 192kHz',
                          style: TextStyle(
                              color: SpectrumColors.textUltraMuted,
                              fontSize: 9,
                              fontFamily: 'monospace')),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CarouselCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final String? imageUrl;
  final VoidCallback onTap;
  final bool isMaster;

  const _CarouselCard(
      {required this.title,
      required this.subtitle,
      this.imageUrl,
      required this.onTap,
      this.isMaster = false});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 160,
        margin: const EdgeInsets.symmetric(horizontal: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AspectRatio(
              aspectRatio: 1,
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: SpectrumColors.border),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(3),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      if (imageUrl != null)
                        CachedNetworkImage(
                            imageUrl: imageUrl!, fit: BoxFit.cover)
                      else
                        Container(color: SpectrumColors.surface),
                      if (isMaster)
                        Positioned(
                          top: 8,
                          left: 8,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                                color: SpectrumColors.accent,
                                borderRadius: BorderRadius.circular(2)),
                            child: const Text('M',
                                style: TextStyle(
                                    color: Colors.black,
                                    fontSize: 9,
                                    fontWeight: FontWeight.w900)),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                    color: SpectrumColors.textPrimary,
                    fontWeight: FontWeight.w800,
                    fontSize: 13)),
            const SizedBox(height: 2),
            Text(subtitle,
                style: TextStyle(
                    color: isMaster
                        ? SpectrumColors.accent
                        : SpectrumColors.textMuted,
                    fontSize: 10,
                    fontWeight:
                        isMaster ? FontWeight.bold : FontWeight.normal)),
          ],
        ),
      ),
    );
  }
}

class _AnimatedPulseBackground extends StatelessWidget {
  final AnimationController controller;
  const _AnimatedPulseBackground({required this.controller});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, child) {
        return CustomPaint(
          painter: _PulseBackgroundPainter(controller.value),
        );
      },
    );
  }
}

class _PulseBackgroundPainter extends CustomPainter {
  final double time;
  _PulseBackgroundPainter(this.time);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.5;

    // Draw subtle neural lines
    for (var i = 0; i < 5; i++) {
      paint.color = SpectrumColors.accent
          .withOpacity(0.03 + (0.02 * math.sin(time * 2 * math.pi + i)));
      final y = size.height * (0.2 + 0.15 * i) +
          (math.sin(time * 2 * math.pi + i) * 30);
      canvas.drawLine(Offset(0, y), Offset(size.width, y + 50), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
