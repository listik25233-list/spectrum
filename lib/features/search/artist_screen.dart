import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:palette_generator/palette_generator.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart' as yt;
import 'package:spectrum/features/library/playlist_helpers.dart';
import 'package:spectrum/features/library/playlist_editor_service.dart';
import 'package:spectrum/features/player/audio_player_service.dart';

class ArtistScreen extends ConsumerStatefulWidget {
  final yt.Channel artist;

  const ArtistScreen({super.key, required this.artist});

  @override
  ConsumerState<ArtistScreen> createState() => _ArtistScreenState();
}

class _ArtistScreenState extends ConsumerState<ArtistScreen> {
  final yt.YoutubeExplode _yt = yt.YoutubeExplode();

  List<yt.Video> _tracks = [];
  bool _loading = true;
  bool _playingTrack = false;
  String? _error;
  Color? _dominantColor;

  @override
  void initState() {
    super.initState();
    _loadTracks();
    _fetchColor();
  }

  Future<void> _fetchColor() async {
    try {
      final palette = await PaletteGenerator.fromImageProvider(
        CachedNetworkImageProvider(widget.artist.logoUrl),
        maximumColorCount: 10,
      );
      if (mounted) {
        setState(() {
          _dominantColor =
              palette.vibrantColor?.color ?? palette.dominantColor?.color;
        });
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> _loadTracks() async {
    try {
      final uploads =
          await _yt.channels.getUploads(widget.artist.id).take(50).toList();
      if (!mounted) return;
      setState(() {
        _tracks = uploads;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Не удалось загрузить треки артиста.';
        _loading = false;
      });
    }
  }

  Future<void> _playYoutubeTrack(yt.Video video) async {
    if (_playingTrack) return;

    setState(() {
      _playingTrack = true;
    });

    try {
      final track = await ref
          .read(playlistEditorServiceProvider)
          .saveYoutubePreviewTrack(video);
      await ref.read(audioPlayerServiceProvider).playTrack(track);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Не удалось включить трек: $error')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _playingTrack = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        backgroundColor: const Color(0xFF121212),
        elevation: 0,
        title: Text(
          widget.artist.title,
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
      body: AnimatedContainer(
        duration: const Duration(milliseconds: 800),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            stops: const [0.0, 0.4, 1.0],
            colors: [
              (_dominantColor ?? const Color(0xFF121212)).withOpacity(0.4),
              const Color(0xFF121212),
              const Color(0xFF121212),
            ],
          ),
        ),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1100),
            child: Column(
              children: [
                const SizedBox(height: 16),
                CircleAvatar(
                  radius: 64,
                  backgroundColor: Colors.white12,
                  backgroundImage:
                      CachedNetworkImageProvider(widget.artist.logoUrl),
                ),
                const SizedBox(height: 16),
                Text(
                  widget.artist.title,
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 24),
                ),
                const SizedBox(height: 24),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 24),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Треки',
                      style:
                          TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: _buildBody(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Text(
          _error!,
          style: const TextStyle(color: Colors.white54),
          textAlign: TextAlign.center,
        ),
      );
    }

    if (_tracks.isEmpty) {
      return const Center(
        child: Text(
          'У этого артиста нет треков.',
          style: TextStyle(color: Colors.white54),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      itemCount: _tracks.length,
      itemBuilder: (context, index) {
        final video = _tracks[index];
        final title = PlaylistEditorService.cleanYoutubeTitle(video.title);

        return Column(
          children: [
            ListTile(
              contentPadding:
                  const EdgeInsets.symmetric(vertical: 6, horizontal: 16),
              hoverColor: Colors.white.withOpacity(0.04),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              leading: _ArtistTrackArtwork(url: video.thumbnails.mediumResUrl),
              title: Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              subtitle: Text(
                video.author,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: Colors.white54),
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.play_circle_fill_rounded),
                    tooltip: 'Включить',
                    onPressed:
                        _playingTrack ? null : () => _playYoutubeTrack(video),
                  ),
                  IconButton(
                    icon: const Icon(Icons.playlist_add_rounded),
                    tooltip: 'Добавить в плейлист',
                    onPressed: () => showAddYoutubeTrackToPlaylistSheet(
                      context,
                      ref,
                      video: video,
                    ),
                  ),
                ],
              ),
              onTap: _playingTrack ? null : () => _playYoutubeTrack(video),
            ),
          ],
        );
      },
    );
  }
}

class _ArtistTrackArtwork extends StatelessWidget {
  final String? url;

  const _ArtistTrackArtwork({required this.url});

  @override
  Widget build(BuildContext context) {
    if (url == null) {
      return Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: Colors.white12,
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Icon(Icons.music_note, color: Colors.white38),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: CachedNetworkImage(
        imageUrl: url!,
        width: 48,
        height: 48,
        fit: BoxFit.cover,
        placeholder: (context, _) => Container(
          color: Colors.white12,
          child: const Center(
            child: SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 1),
            ),
          ),
        ),
        errorWidget: (context, _, __) => Container(
          color: Colors.white12,
          child: const Icon(Icons.music_note, color: Colors.white38),
        ),
      ),
    );
  }
}
