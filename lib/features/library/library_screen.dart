import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:spectrum/core/theme/spectrum_colors.dart';
import 'package:spectrum/features/library/playlist_screen.dart';
import 'package:spectrum/features/library/playlists_provider.dart';
import 'package:spectrum/features/library/tracks_provider.dart';
import 'package:spectrum/features/library/track_library_service.dart';
import 'package:spectrum/features/player/audio_player_service.dart';
import 'package:spectrum/features/sync/sync_service.dart';

enum TrackSortMode { recentlyAdded, title, artist, duration }

final tracksSearchQueryProvider = StateProvider<String>((ref) => '');
final downloadedOnlyProvider = StateProvider<bool>((ref) => false);
final trackSortModeProvider =
    StateProvider<TrackSortMode>((ref) => TrackSortMode.recentlyAdded);

class LibraryScreen extends ConsumerWidget {
  const LibraryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isSyncing = ref.watch(isSyncingProvider);
    final syncProgress = ref.watch(syncProgressProvider);
    final query = ref.watch(tracksSearchQueryProvider);
    final downloadQueue = ref.watch(downloadQueueProvider);

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: SpectrumColors.background,
        appBar: AppBar(
          backgroundColor: SpectrumColors.surface,
          elevation: 0,
          surfaceTintColor: Colors.transparent,
          title: Text(
            'LIBRARY',
            style: TextStyle(
                fontWeight: FontWeight.w900,
                fontSize: 22,
                letterSpacing: 2.0,
                color: SpectrumColors.textPrimary),
          ),
          bottom: TabBar(
            dividerColor: Colors.transparent,
            indicator: BoxDecoration(
              color: SpectrumColors.accent.withOpacity(0.1),
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: SpectrumColors.accent.withOpacity(0.5)),
            ),
            indicatorSize: TabBarIndicatorSize.tab,
            labelColor: SpectrumColors.textPrimary,
            unselectedLabelColor: SpectrumColors.textMuted,
            labelStyle: const TextStyle(
                fontWeight: FontWeight.w900,
                fontSize: 10,
                letterSpacing: 2.0,
                fontFamily: 'monospace'),
            unselectedLabelStyle: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 10,
                letterSpacing: 2.0,
                fontFamily: 'monospace',
                color: SpectrumColors.textUltraMuted),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            tabs: const [
              Tab(text: 'TRACK_CORE'),
              Tab(text: 'PLAYLIST_MIX'),
            ],
          ),
          actions: [
            if (downloadQueue.isNotEmpty)
              _DownloadStatusIndicator(count: downloadQueue.length),
            IconButton(
              icon: Icon(Icons.download_for_offline_rounded,
                  color: SpectrumColors.accent),
              tooltip: 'Загрузить все треки библиотеки',
              onPressed: () => _confirmDownloadAll(context, ref),
            ),
            IconButton(
              icon: isSyncing
                  ? SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                          strokeWidth: 1.5, color: SpectrumColors.accent))
                  : const Icon(Icons.sync_rounded),
              onPressed: isSyncing
                  ? null
                  : () => ref.read(syncServiceProvider).syncSpotifyLibrary(),
            ),
            IconButton(
              icon: const Icon(Icons.tune_rounded),
              onPressed: () => _showFiltersSheet(context, ref),
            ),
            const SizedBox(width: 8),
          ],
        ),
        body: Column(
          children: [
            if (isSyncing) _SyncProgressBar(progress: syncProgress),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      onChanged: (value) => ref
                          .read(tracksSearchQueryProvider.notifier)
                          .state = value.trim(),
                      style: TextStyle(
                          color: SpectrumColors.textPrimary, fontSize: 13),
                      decoration: InputDecoration(
                        hintText: 'SEARCH_LIBRARY_DATA...',
                        hintStyle: TextStyle(
                            color: SpectrumColors.textUltraMuted,
                            fontSize: 12,
                            letterSpacing: 1.0),
                        prefixIcon: Icon(Icons.search_rounded,
                            size: 18, color: SpectrumColors.textUltraMuted),
                        suffixIcon: query.isNotEmpty
                            ? IconButton(
                                icon: Icon(Icons.close_rounded,
                                    size: 16, color: SpectrumColors.accent),
                                onPressed: () => ref
                                    .read(tracksSearchQueryProvider.notifier)
                                    .state = '',
                              )
                            : null,
                        filled: true,
                        fillColor: SpectrumColors.surface,
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 0),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(4),
                          borderSide: BorderSide(color: SpectrumColors.border),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(4),
                          borderSide:
                              BorderSide(color: SpectrumColors.borderStrong),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: TabBarView(
                children: [
                  _buildTracksTab(ref),
                  _buildPlaylistsTab(ref),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTracksTab(WidgetRef ref) {
    final tracksAsync = ref.watch(tracksProvider);
    final query = ref.watch(tracksSearchQueryProvider).toLowerCase();
    final downloadedOnly = ref.watch(downloadedOnlyProvider);
    final sortMode = ref.watch(trackSortModeProvider);

    return tracksAsync.when(
      data: (tracks) {
        var filtered = tracks.where((track) {
          if (downloadedOnly && track.localPath == null) return false;
          if (query.isEmpty) return true;
          return track.title.toLowerCase().contains(query) ||
              track.artist.toLowerCase().contains(query);
        }).toList();

        switch (sortMode) {
          case TrackSortMode.title:
            filtered.sort((a, b) =>
                a.title.toLowerCase().compareTo(b.title.toLowerCase()));
            break;
          case TrackSortMode.artist:
            filtered.sort((a, b) =>
                a.artist.toLowerCase().compareTo(b.artist.toLowerCase()));
            break;
          case TrackSortMode.duration:
            filtered.sort((a, b) => b.durationMs.compareTo(a.durationMs));
            break;
          case TrackSortMode.recentlyAdded:
            break;
        }

        if (filtered.isEmpty) {
          return _buildEmptyState(ref,
              searchMode: query.isNotEmpty || downloadedOnly);
        }

        return ListView.builder(
          padding: const EdgeInsets.only(bottom: 120, top: 4),
          itemCount: filtered.length,
          itemBuilder: (context, index) {
            final track = filtered[index];
            return _TrackListTile(
              track: track,
              onTap: () => ref
                  .read(audioPlayerServiceProvider)
                  .playQueue(filtered, initialIndex: index),
              onDelete: () => _confirmDelete(context, ref, track),
            );
          },
        );
      },
      loading: () => Center(
          child: CircularProgressIndicator(color: SpectrumColors.accent)),
      error: (err, _) => Center(
          child: Text('ENGINE_ERROR: $err',
              style: TextStyle(color: SpectrumColors.error))),
    );
  }

  Widget _buildPlaylistsTab(WidgetRef ref) {
    final playlistsAsync = ref.watch(playlistsProvider);
    return playlistsAsync.when(
      data: (playlists) {
        if (playlists.isEmpty) return _buildEmptyState(ref);
        return GridView.builder(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 120),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 0.8,
          ),
          itemCount: playlists.length,
          itemBuilder: (context, index) {
            final playlist = playlists[index];
            return _PlaylistCard(playlist: playlist);
          },
        );
      },
      loading: () => Center(
          child: CircularProgressIndicator(color: SpectrumColors.accent)),
      error: (err, _) => Center(
          child: Text('ENGINE_ERROR: $err',
              style: TextStyle(color: SpectrumColors.error))),
    );
  }

  void _confirmDownloadAll(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: SpectrumColors.surface,
        shape: RoundedRectangleBorder(
            side: BorderSide(color: SpectrumColors.accent, width: 1),
            borderRadius: BorderRadius.circular(4)),
        title: Text('DOWNLOAD_ALL_SYNC',
            style: TextStyle(
                color: SpectrumColors.textPrimary,
                fontSize: 14,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.0)),
        content: const Text(
            'Запустить фоновую загрузку всех недостающих треков?',
            style: TextStyle(color: Colors.white60, fontSize: 13)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text('CANCEL',
                  style: TextStyle(color: SpectrumColors.textUltraMuted))),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              ref.read(trackLibraryServiceProvider).downloadAllTracks();
            },
            child: Text('INITIATE',
                style: TextStyle(color: SpectrumColors.accent)),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context, WidgetRef ref, dynamic track) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: SpectrumColors.surface,
        shape: RoundedRectangleBorder(
            side: BorderSide(color: SpectrumColors.accent, width: 0.5),
            borderRadius: BorderRadius.circular(4)),
        title: Text('DELETE_DATA_OBJECT',
            style: TextStyle(
                color: SpectrumColors.error,
                fontSize: 12,
                fontWeight: FontWeight.w900)),
        content: Text(
            'Удалить ${track.title} из библиотеки и памяти устройства?',
            style: const TextStyle(color: Colors.white70, fontSize: 13)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text('ABORT',
                  style: TextStyle(color: SpectrumColors.textUltraMuted))),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              ref.read(trackLibraryServiceProvider).deleteTrack(track);
            },
            child:
                Text('DELETE', style: TextStyle(color: SpectrumColors.error)),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(WidgetRef ref, {bool searchMode = false}) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.library_music_rounded,
              size: 64, color: SpectrumColors.textUltraMuted),
          const SizedBox(height: 16),
          Text(
            searchMode ? 'SEARCH_RESULT: EMPTY' : 'SYSTEM_LIBRARY: EMPTY',
            style: TextStyle(
                color: SpectrumColors.textMuted,
                fontSize: 12,
                letterSpacing: 2.0,
                fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  void _showFiltersSheet(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      backgroundColor: SpectrumColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.zero,
        side: BorderSide.none,
      ),
      builder: (ctx) {
        return Consumer(
          builder: (context, ref, _) {
            final downloadedOnly = ref.watch(downloadedOnlyProvider);
            final sortMode = ref.watch(trackSortModeProvider);
            return SafeArea(
              child: Container(
                decoration: BoxDecoration(
                  border: Border(
                      top: BorderSide(color: SpectrumColors.accent, width: 2)),
                ),
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('LIBRARY_QUERY_FILTERS',
                        style: TextStyle(
                            color: SpectrumColors.accent,
                            fontSize: 11,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 2.0)),
                    const SizedBox(height: 24),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text('OFFLINE_ONLY',
                          style: TextStyle(
                              color: SpectrumColors.textPrimary,
                              fontSize: 13,
                              letterSpacing: 1.0,
                              fontWeight: FontWeight.w800)),
                      value: downloadedOnly,
                      activeThumbColor: SpectrumColors.accent,
                      onChanged: (value) => ref
                          .read(downloadedOnlyProvider.notifier)
                          .state = value,
                    ),
                    const SizedBox(height: 12),
                    Divider(color: SpectrumColors.border),
                    const SizedBox(height: 20),
                    Text('SORTING_MODE:',
                        style: TextStyle(
                            color: SpectrumColors.textMuted,
                            fontSize: 10,
                            letterSpacing: 1.0,
                            fontWeight: FontWeight.bold)),
                    const SizedBox(height: 16),
                    _SortChip(
                        label: 'RECENTLY_ADDED',
                        mode: TrackSortMode.recentlyAdded,
                        current: sortMode),
                    _SortChip(
                        label: 'ALPHABETICAL_TITLE',
                        mode: TrackSortMode.title,
                        current: sortMode),
                    _SortChip(
                        label: 'ARTIST_DATA',
                        mode: TrackSortMode.artist,
                        current: sortMode),
                    _SortChip(
                        label: 'TEMPORAL_DURATION',
                        mode: TrackSortMode.duration,
                        current: sortMode),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class _TrackListTile extends StatelessWidget {
  final dynamic track;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _TrackListTile(
      {required this.track, required this.onTap, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    // Parse dominant color if available
    Color? bgColor;
    if (track.dominantColor != null) {
      final hex = track.dominantColor!.replaceAll('#', '');
      if (hex.length == 6) {
        bgColor = Color(int.parse('FF$hex', radix: 16));
      }
    }

    return Material(
      color: Colors.transparent,
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 2),
        hoverColor: SpectrumColors.accent.withOpacity(0.05),
        leading: ClipRRect(
          borderRadius: BorderRadius.circular(2),
          child: Container(
            width: 48,
            height: 48,
            color: bgColor ?? SpectrumColors.card,
            child: Stack(
              children: [
                // Layer 1: Blurred Placeholder (fast)
                if (track.blurHashPath != null)
                  Positioned.fill(
                    child: Image.file(
                      File(track.blurHashPath!),
                      fit: BoxFit.cover,
                      filterQuality: FilterQuality.low,
                    ),
                  ),
                // Layer 2: Main Artwork (local thumbnail or network)
                Positioned.fill(
                  child: _buildArtwork(track),
                ),
              ],
            ),
          ),
        ),
        title: Text(
          track.title.toUpperCase(),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
              fontWeight: FontWeight.w900,
              fontSize: 13,
              color: SpectrumColors.textPrimary,
              letterSpacing: 0.5),
        ),
        subtitle: Text(
          '// ARTIST: ${track.artist.toUpperCase()}',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
              color: SpectrumColors.textMuted,
              fontSize: 10,
              letterSpacing: 1.0),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (track.localPath != null)
              Icon(Icons.bolt, color: SpectrumColors.accent, size: 14),
            const SizedBox(width: 12),
            PopupMenuButton<String>(
              icon: Icon(Icons.more_horiz, color: SpectrumColors.textMuted),
              color: SpectrumColors.surface,
              shape: RoundedRectangleBorder(
                  side: BorderSide(color: SpectrumColors.accent, width: 0.5)),
              onSelected: (val) {
                if (val == 'delete') onDelete();
              },
              itemBuilder: (_) => [
                PopupMenuItem(
                  value: 'delete',
                  child: Text('WIPE_DATA',
                      style: TextStyle(
                          color: SpectrumColors.error,
                          fontSize: 11,
                          fontWeight: FontWeight.w900)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildArtwork(dynamic track) {
    // 1. Local Thumbnail Generated by Rust (High Performance)
    if (track.artworkUrl != null && track.artworkUrl!.isNotEmpty) {
      if (!track.artworkUrl!.startsWith('http')) {
        return Image.file(
          File(track.artworkUrl!),
          fit: BoxFit.cover,
          cacheWidth: 100, // Optimize memory for list icons
          cacheHeight: 100,
          errorBuilder: (_, __, ___) => const SizedBox.shrink(),
        );
      }
    }

    // 2. Network Artwork (Fallback)
    if (track.albumArtUrl != null && track.albumArtUrl!.isNotEmpty) {
      return CachedNetworkImage(
        imageUrl: track.albumArtUrl!,
        fit: BoxFit.cover,
        memCacheWidth: 100,
        memCacheHeight: 100,
        placeholder: (_, __) => const SizedBox.shrink(),
        errorWidget: (_, __, ___) => const SizedBox.shrink(),
      );
    }

    // 3. Default Icon
    return Center(
      child: Icon(Icons.music_note, color: SpectrumColors.textMuted, size: 20),
    );
  }
}

class _PlaylistCard extends StatelessWidget {
  final dynamic playlist;
  const _PlaylistCard({required this.playlist});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => Navigator.of(context).push(MaterialPageRoute(
          builder: (_) => PlaylistScreen(playlist: playlist))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                border: Border.all(color: SpectrumColors.border, width: 1),
                borderRadius: BorderRadius.circular(4),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: playlist.artworkUrl != null
                    ? CachedNetworkImage(
                        imageUrl: playlist.artworkUrl!, fit: BoxFit.cover)
                    : Center(
                        child: Icon(Icons.queue_music,
                            color: SpectrumColors.textUltraMuted, size: 40)),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(playlist.name.toUpperCase(),
              maxLines: 1,
              style: TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 12,
                  color: SpectrumColors.textPrimary,
                  letterSpacing: 1.0)),
          Text('// OBJECTS: ${playlist.trackSpotifyIds.length}',
              style: TextStyle(color: SpectrumColors.textMuted, fontSize: 9)),
        ],
      ),
    );
  }
}

class _SyncProgressBar extends StatelessWidget {
  final String progress;
  const _SyncProgressBar({required this.progress});
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: SpectrumColors.accent.withOpacity(0.05),
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 20),
      child: Row(
        children: [
          SizedBox(
              width: 12,
              height: 12,
              child: CircularProgressIndicator(
                  strokeWidth: 1, color: SpectrumColors.accent)),
          const SizedBox(width: 16),
          Expanded(
              child: Text('SYNC_PROTOCOL: $progress'.toUpperCase(),
                  style: TextStyle(
                      fontSize: 10,
                      color: SpectrumColors.accent,
                      letterSpacing: 1.5,
                      fontWeight: FontWeight.bold))),
        ],
      ),
    );
  }
}

class _DownloadStatusIndicator extends StatelessWidget {
  final int count;
  const _DownloadStatusIndicator({required this.count});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      margin: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: SpectrumColors.accentMuted,
        borderRadius: BorderRadius.circular(2),
        border: Border.all(color: SpectrumColors.borderStrong),
      ),
      child: Row(
        children: [
          Icon(Icons.download_rounded, size: 12, color: SpectrumColors.accent),
          const SizedBox(width: 6),
          Text('QUEUE: $count'.toUpperCase(),
              style: TextStyle(
                  color: SpectrumColors.accent,
                  fontSize: 9,
                  fontWeight: FontWeight.w900)),
        ],
      ),
    );
  }
}

class _SortChip extends ConsumerWidget {
  final String label;
  final TrackSortMode mode;
  final TrackSortMode current;
  const _SortChip(
      {required this.label, required this.mode, required this.current});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final active = current == mode;
    return InkWell(
      onTap: () => ref.read(trackSortModeProvider.notifier).state = mode,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            Icon(active ? Icons.radio_button_checked : Icons.radio_button_off,
                size: 16,
                color:
                    active ? SpectrumColors.accent : SpectrumColors.textMuted),
            const SizedBox(width: 12),
            Text(label,
                style: TextStyle(
                    color: active
                        ? SpectrumColors.textPrimary
                        : SpectrumColors.textMuted,
                    fontSize: 11,
                    fontWeight: active ? FontWeight.w900 : FontWeight.normal,
                    letterSpacing: 1.0)),
          ],
        ),
      ),
    );
  }
}
