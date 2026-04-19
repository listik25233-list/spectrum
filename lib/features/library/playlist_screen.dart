import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:spectrum/core/db/schemas/playlist_schema.dart';
import 'package:spectrum/features/library/playlist_tracks_provider.dart';
import 'package:spectrum/features/player/audio_player_service.dart';
import 'package:spectrum/features/jam/jam_provider.dart';
import 'package:spectrum/core/theme/spectrum_colors.dart';

class PlaylistScreen extends ConsumerStatefulWidget {
  final Playlist playlist;

  const PlaylistScreen({super.key, required this.playlist});

  @override
  ConsumerState<PlaylistScreen> createState() => _PlaylistScreenState();
}

class _PlaylistScreenState extends ConsumerState<PlaylistScreen> {
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final playlist = widget.playlist;
    final tracksAsync = ref.watch(playlistTracksProvider(playlist.id));

    return Scaffold(
      backgroundColor: SpectrumColors.background,
      body: Stack(
        children: [
          // 1. DYNAMIC BACKGROUND
          Positioned.fill(
            child: Opacity(
              opacity: 0.15,
              child: playlist.artworkUrl != null
                  ? CachedNetworkImage(
                      imageUrl: playlist.artworkUrl!, fit: BoxFit.cover)
                  : Container(color: SpectrumColors.surface),
            ),
          ),
          Positioned.fill(
              child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 80, sigmaY: 80),
                  child: Container(color: Colors.transparent))),

          // 2. MAIN SCROLL VIEW
          CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              _buildModernAppBar(context, playlist),

              // SEARCH & ACTION HUB
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
                  child: Row(
                    children: [
                      Expanded(
                        child: _HUDTextField(
                          hint: 'FILTER_DATA...',
                          onChanged: (v) =>
                              setState(() => _searchQuery = v.toLowerCase()),
                        ),
                      ),
                      const SizedBox(width: 16),
                      _EngageButton(onTap: () {
                        tracksAsync.whenData((tracks) {
                          if (tracks.isNotEmpty)
                            ref
                                .read(audioPlayerServiceProvider)
                                .playQueue(tracks);
                        });
                      }),
                    ],
                  ),
                ),
              ),

              tracksAsync.when(
                data: (tracks) {
                  final filtered = tracks
                      .where((t) =>
                          t.title.toLowerCase().contains(_searchQuery) ||
                          t.artist.toLowerCase().contains(_searchQuery))
                      .toList();
                  if (filtered.isEmpty) {
                    return const SliverFillRemaining(
                        child: Center(
                            child: Text('NO_SIGNAL_FOUND',
                                style: TextStyle(
                                    fontFamily: 'monospace',
                                    color: Colors.white24))));
                  }
                  return SliverPadding(
                    padding: const EdgeInsets.only(bottom: 140),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) => _ModernTrackTile(
                          track: filtered[index],
                          onTap: () => ref
                              .read(audioPlayerServiceProvider)
                              .playQueue(filtered, initialIndex: index),
                        ),
                        childCount: filtered.length,
                      ),
                    ),
                  );
                },
                loading: () => const SliverFillRemaining(
                    child: Center(child: CircularProgressIndicator())),
                error: (e, __) => SliverFillRemaining(
                    child: Center(child: Text('ENGINE_ERROR: $e'))),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildModernAppBar(BuildContext context, Playlist playlist) {
    return SliverAppBar(
      expandedHeight: 280,
      pinned: true,
      backgroundColor: SpectrumColors.background.withOpacity(0.8),
      elevation: 0,
      flexibleSpace: FlexibleSpaceBar(
        centerTitle: false,
        titlePadding: const EdgeInsets.only(left: 64, bottom: 20),
        title: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              playlist.name.toUpperCase(),
              style: TextStyle(
                  color: SpectrumColors.textPrimary,
                  fontWeight: FontWeight.w900,
                  fontSize: 18,
                  letterSpacing: 2.0),
            ),
            Text(
              '${playlist.trackSpotifyIds.length} LOCALIZED_SIGNALS',
              style: TextStyle(
                  color: SpectrumColors.accent,
                  fontSize: 8,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.0),
            ),
          ],
        ),
        background: Stack(
          fit: StackFit.expand,
          children: [
            if (playlist.artworkUrl != null)
              CachedNetworkImage(
                  imageUrl: playlist.artworkUrl!, fit: BoxFit.cover)
            else
              Container(color: SpectrumColors.surface),

            // Industrial overlay
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    SpectrumColors.background.withOpacity(0.5),
                    SpectrumColors.background,
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HUDTextField extends StatelessWidget {
  final String hint;
  final ValueChanged<String> onChanged;
  const _HUDTextField({required this.hint, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return TextField(
      onChanged: onChanged,
      style: TextStyle(
          color: SpectrumColors.textPrimary,
          fontSize: 12,
          fontFamily: 'monospace'),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle:
            TextStyle(color: SpectrumColors.textUltraMuted, fontSize: 10),
        prefixIcon: Icon(Icons.search_rounded,
            size: 18, color: SpectrumColors.accent.withOpacity(0.5)),
        filled: true,
        fillColor: SpectrumColors.surface.withOpacity(0.5),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(4),
            borderSide: BorderSide(color: SpectrumColors.border)),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(4),
            borderSide: BorderSide(color: SpectrumColors.border)),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(4),
            borderSide: BorderSide(color: SpectrumColors.accent)),
      ),
    );
  }
}

class _EngageButton extends StatelessWidget {
  final VoidCallback onTap;
  const _EngageButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: SpectrumColors.accent,
          borderRadius: BorderRadius.circular(4),
          boxShadow: [
            BoxShadow(
                color: SpectrumColors.accent.withOpacity(0.5), blurRadius: 15)
          ],
        ),
        child:
            const Icon(Icons.play_arrow_rounded, color: Colors.black, size: 28),
      ),
    );
  }
}

class _ModernTrackTile extends ConsumerWidget {
  final dynamic track;
  final VoidCallback onTap;
  const _ModernTrackTile({required this.track, required this.onTap});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hasJam = ref.watch(jamProvider) != null;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
      child: Container(
        decoration: BoxDecoration(
          color: SpectrumColors.surface.withOpacity(0.3),
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: SpectrumColors.border.withOpacity(0.5)),
        ),
        child: ListTile(
          onTap: onTap,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          leading: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(2),
                border: Border.all(color: SpectrumColors.border)),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(1),
              child: track.albumArtUrl != null
                  ? CachedNetworkImage(
                      imageUrl: track.albumArtUrl!, fit: BoxFit.cover)
                  : Container(color: SpectrumColors.background),
            ),
          ),
          title: Text(track.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                  color: SpectrumColors.textPrimary,
                  fontWeight: FontWeight.w800,
                  fontSize: 13)),
          subtitle: Text(track.artist,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                  color: SpectrumColors.textMuted,
                  fontSize: 10,
                  letterSpacing: 0.5)),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (track.localPath != null)
                Icon(Icons.download_done_rounded,
                    color: SpectrumColors.accent, size: 14),
              const SizedBox(width: 8),
              PopupMenuButton<String>(
                icon: Icon(Icons.more_vert_rounded,
                    color: SpectrumColors.textUltraMuted, size: 18),
                color: SpectrumColors.surface,
                onSelected: (val) {
                  if (val == 'jam' && hasJam) {
                    ref.read(jamProvider.notifier).addToQueue(track);
                    ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('SIGNAL_QUEUED')));
                  }
                },
                itemBuilder: (ctx) => [
                  if (hasJam)
                    const PopupMenuItem(
                      value: 'jam',
                      child: Text('ADD_TO_JAM',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontFamily: 'monospace')),
                    ),
                  const PopupMenuItem(
                    value: 'info',
                    child: Text('METADATA',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontFamily: 'monospace')),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
