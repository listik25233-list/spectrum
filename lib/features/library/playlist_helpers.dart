import 'dart:async';
import 'package:youtube_explode_dart/youtube_explode_dart.dart' as yt;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:spectrum/core/db/schemas/playlist_schema.dart';
import 'package:spectrum/core/db/schemas/track_schema.dart';
import 'package:spectrum/core/network/spotify_api.dart';
import 'package:spectrum/features/library/playlist_editor_service.dart';
import 'package:spectrum/features/library/playlists_provider.dart';
import 'package:spectrum/features/library/tracks_provider.dart';
import 'package:spectrum/features/jam/jam_provider.dart';
import 'package:spectrum/core/theme/spectrum_colors.dart';

Future<void> showAddTrackToPlaylistSheet(
  BuildContext context,
  WidgetRef ref, {
  required Track track,
}) async {
  final playlistsAsync = ref.read(playlistsProvider);
  final existingPlaylists = playlistsAsync.maybeWhen(
    data: (playlists) => playlists,
    orElse: () => <Playlist>[],
  );

  var query = '';
  final searchController = TextEditingController();

  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: const Color(0xFF1A1A2E),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (ctx) {
      return StatefulBuilder(
        builder: (context, setState) {
          final filteredPlaylists = existingPlaylists.where((playlist) {
            if (query.isEmpty) return true;
            return playlist.name.toLowerCase().contains(query);
          }).toList()
            ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));

          return SafeArea(
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                16,
                12,
                16,
                16 + MediaQuery.of(context).viewInsets.bottom,
              ),
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
                  const SizedBox(height: 14),
                  const Text(
                    'Добавить в плейлист',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: searchController,
                    onChanged: (value) =>
                        setState(() => query = value.trim().toLowerCase()),
                    decoration: InputDecoration(
                      hintText: 'Поиск плейлиста',
                      prefixIcon: const Icon(Icons.search_rounded),
                      filled: true,
                      fillColor: Colors.white.withOpacity(0.06),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton.icon(
                      onPressed: () async {
                        final playlist =
                            await _showCreatePlaylistDialog(context, ref);
                        if (playlist == null) return;
                        if (!context.mounted) return;
                        await _addTrackAndNotify(
                            context, ref, playlist.id, track, playlist.name);
                        if (context.mounted) {
                          Navigator.of(ctx).pop();
                        }
                      },
                      icon: const Icon(Icons.add_rounded),
                      label: const Text('Новый плейлист'),
                    ),
                  ),
                  Flexible(
                    child: filteredPlaylists.isEmpty
                        ? const Center(
                            child: Padding(
                              padding: EdgeInsets.symmetric(vertical: 32),
                              child: Text(
                                'Плейлисты не найдены',
                                style: TextStyle(color: Colors.white54),
                              ),
                            ),
                          )
                        : ListView.builder(
                            shrinkWrap: true,
                            itemCount: filteredPlaylists.length,
                            itemBuilder: (context, index) {
                              final playlist = filteredPlaylists[index];
                              final alreadyAdded = track.spotifyId != null &&
                                  playlist.trackSpotifyIds
                                      .contains(track.spotifyId);

                              return ListTile(
                                contentPadding: EdgeInsets.zero,
                                leading: CircleAvatar(
                                  backgroundColor: Colors.white10,
                                  child: Icon(
                                    alreadyAdded
                                        ? Icons.check_rounded
                                        : Icons.queue_music_rounded,
                                    color: Colors.white70,
                                  ),
                                ),
                                title: Text(playlist.name),
                                subtitle: Text(
                                    '${playlist.trackSpotifyIds.length} треков'),
                                trailing: alreadyAdded
                                    ? const Text(
                                        'Уже есть',
                                        style: TextStyle(color: Colors.white38),
                                      )
                                    : const Icon(Icons.add_rounded),
                                onTap: alreadyAdded
                                    ? null
                                    : () async {
                                        await _addTrackAndNotify(
                                          context,
                                          ref,
                                          playlist.id,
                                          track,
                                          playlist.name,
                                        );
                                        if (context.mounted) {
                                          Navigator.of(ctx).pop();
                                        }
                                      },
                              );
                            },
                          ),
                  ),
                ],
              ),
            ),
          );
        },
      );
    },
  );
}

Future<void> showAddSpotifyTrackToPlaylistSheet(
  BuildContext context,
  WidgetRef ref, {
  required Map<String, dynamic> trackData,
}) async {
  final playlistsAsync = ref.read(playlistsProvider);
  final existingPlaylists = playlistsAsync.maybeWhen(
    data: (playlists) => playlists,
    orElse: () => <Playlist>[],
  );

  var query = '';
  var submitting = false;
  final searchController = TextEditingController();
  final spotifyId = trackData['id'] as String?;

  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: const Color(0xFF1A1A2E),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (ctx) {
      return StatefulBuilder(
        builder: (context, setState) {
          final filteredPlaylists = existingPlaylists.where((playlist) {
            if (query.isEmpty) return true;
            return playlist.name.toLowerCase().contains(query);
          }).toList()
            ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));

          Future<void> addToPlaylist(Playlist playlist) async {
            setState(() => submitting = true);
            try {
              await ref
                  .read(playlistEditorServiceProvider)
                  .addSpotifyTrackToPlaylist(
                    playlistId: playlist.id,
                    trackData: trackData,
                  );
              if (!context.mounted) return;
              final title = trackData['name'] as String? ?? 'Трек';
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                    content: Text('"$title" добавлен в "${playlist.name}"')),
              );
              Navigator.of(ctx).pop();
            } catch (error) {
              if (!context.mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Не удалось добавить трек: $error')),
              );
            } finally {
              if (context.mounted) {
                setState(() => submitting = false);
              }
            }
          }

          return SafeArea(
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                16,
                12,
                16,
                16 + MediaQuery.of(context).viewInsets.bottom,
              ),
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
                  const SizedBox(height: 14),
                  const Text(
                    'Добавить в плейлист',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: searchController,
                    onChanged: (value) =>
                        setState(() => query = value.trim().toLowerCase()),
                    decoration: InputDecoration(
                      hintText: 'Поиск плейлиста',
                      prefixIcon: const Icon(Icons.search_rounded),
                      filled: true,
                      fillColor: Colors.white.withOpacity(0.06),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton.icon(
                      onPressed: submitting
                          ? null
                          : () async {
                              final playlist =
                                  await _showCreatePlaylistDialog(context, ref);
                              if (playlist == null || !context.mounted) return;
                              await addToPlaylist(playlist);
                            },
                      icon: const Icon(Icons.add_rounded),
                      label: const Text('Новый плейлист'),
                    ),
                  ),
                  Flexible(
                    child: filteredPlaylists.isEmpty
                        ? const Center(
                            child: Padding(
                              padding: EdgeInsets.symmetric(vertical: 32),
                              child: Text(
                                'Плейлисты не найдены',
                                style: TextStyle(color: Colors.white54),
                              ),
                            ),
                          )
                        : ListView.builder(
                            shrinkWrap: true,
                            itemCount: filteredPlaylists.length,
                            itemBuilder: (context, index) {
                              final playlist = filteredPlaylists[index];
                              final alreadyAdded = spotifyId != null &&
                                  playlist.trackSpotifyIds.contains(spotifyId);

                              return ListTile(
                                contentPadding: EdgeInsets.zero,
                                leading: CircleAvatar(
                                  backgroundColor: Colors.white10,
                                  child: Icon(
                                    alreadyAdded
                                        ? Icons.check_rounded
                                        : Icons.queue_music_rounded,
                                    color: Colors.white70,
                                  ),
                                ),
                                title: Text(playlist.name),
                                subtitle: Text(
                                    '${playlist.trackSpotifyIds.length} треков'),
                                trailing: submitting
                                    ? const SizedBox(
                                        width: 18,
                                        height: 18,
                                        child: CircularProgressIndicator(
                                            strokeWidth: 2),
                                      )
                                    : alreadyAdded
                                        ? const Text(
                                            'Уже есть',
                                            style: TextStyle(
                                                color: Colors.white38),
                                          )
                                        : const Icon(Icons.add_rounded),
                                onTap: submitting || alreadyAdded
                                    ? null
                                    : () => addToPlaylist(playlist),
                              );
                            },
                          ),
                  ),
                ],
              ),
            ),
          );
        },
      );
    },
  );
}

Future<void> showAddYoutubeTrackToPlaylistSheet(
  BuildContext context,
  WidgetRef ref, {
  required yt.Video video,
}) async {
  final playlistsAsync = ref.read(playlistsProvider);
  final existingPlaylists = playlistsAsync.maybeWhen(
    data: (playlists) => playlists,
    orElse: () => <Playlist>[],
  );

  var query = '';
  var submitting = false;
  final searchController = TextEditingController();

  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: const Color(0xFF1A1A2E),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (ctx) {
      return StatefulBuilder(
        builder: (context, setState) {
          final filteredPlaylists = existingPlaylists.where((playlist) {
            if (query.isEmpty) return true;
            return playlist.name.toLowerCase().contains(query);
          }).toList()
            ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));

          Future<void> addToPlaylist(Playlist playlist) async {
            setState(() => submitting = true);
            try {
              final cleanTitle =
                  PlaylistEditorService.cleanYoutubeTitle(video.title);
              final searchQuery = '$cleanTitle ${video.author}';

              final spotifySearch =
                  await SpotifyApi().search(searchQuery, limit: 1);
              if (spotifySearch.isEmpty) {
                throw Exception('Трек не найден в Spotify для синхронизации');
              }
              final trackData = spotifySearch.first;

              await ref
                  .read(playlistEditorServiceProvider)
                  .addSpotifyTrackToPlaylist(
                    playlistId: playlist.id,
                    trackData: trackData,
                  );
              if (!context.mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                    content: Text(
                        '"${trackData['name']}" добавлен в "${playlist.name}"')),
              );
              Navigator.of(ctx).pop();
            } catch (error) {
              if (!context.mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Не удалось добавить трек: $error')),
              );
            } finally {
              if (context.mounted) {
                setState(() => submitting = false);
              }
            }
          }

          return SafeArea(
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                16,
                12,
                16,
                16 + MediaQuery.of(context).viewInsets.bottom,
              ),
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
                  const SizedBox(height: 14),
                  const Text(
                    'Добавить в плейлист',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: searchController,
                    onChanged: (value) =>
                        setState(() => query = value.trim().toLowerCase()),
                    decoration: InputDecoration(
                      hintText: 'Поиск плейлиста',
                      prefixIcon: const Icon(Icons.search_rounded),
                      filled: true,
                      fillColor: Colors.white.withOpacity(0.06),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton.icon(
                      onPressed: submitting
                          ? null
                          : () async {
                              final playlist =
                                  await _showCreatePlaylistDialog(context, ref);
                              if (playlist == null || !context.mounted) return;
                              await addToPlaylist(playlist);
                            },
                      icon: const Icon(Icons.add_rounded),
                      label: const Text('Новый плейлист'),
                    ),
                  ),
                  Flexible(
                    child: filteredPlaylists.isEmpty
                        ? const Center(
                            child: Padding(
                              padding: EdgeInsets.symmetric(vertical: 32),
                              child: Text(
                                'Плейлисты не найдены',
                                style: TextStyle(color: Colors.white54),
                              ),
                            ),
                          )
                        : ListView.builder(
                            shrinkWrap: true,
                            itemCount: filteredPlaylists.length,
                            itemBuilder: (context, index) {
                              final playlist = filteredPlaylists[index];

                              return ListTile(
                                contentPadding: EdgeInsets.zero,
                                leading: const CircleAvatar(
                                  backgroundColor: Colors.white10,
                                  child: Icon(
                                    Icons.queue_music_rounded,
                                    color: Colors.white70,
                                  ),
                                ),
                                title: Text(playlist.name),
                                subtitle: Text(
                                    '${playlist.trackSpotifyIds.length} треков'),
                                trailing: submitting
                                    ? const SizedBox(
                                        width: 18,
                                        height: 18,
                                        child: CircularProgressIndicator(
                                            strokeWidth: 2),
                                      )
                                    : const Icon(Icons.add_rounded),
                                onTap: submitting
                                    ? null
                                    : () => addToPlaylist(playlist),
                              );
                            },
                          ),
                  ),
                ],
              ),
            ),
          );
        },
      );
    },
  );
}

Future<void> showSearchAndAddTracksSheet(
  BuildContext context,
  WidgetRef ref, {
  required Playlist playlist,
}) async {
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: const Color(0xFF1A1A2E),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (_) => _TrackSearchSheet(playlist: playlist),
  );
}

class _TrackSearchSheet extends ConsumerStatefulWidget {
  final Playlist playlist;

  const _TrackSearchSheet({required this.playlist});

  @override
  ConsumerState<_TrackSearchSheet> createState() => _TrackSearchSheetState();
}

class _TrackSearchSheetState extends ConsumerState<_TrackSearchSheet> {
  final TextEditingController _controller = TextEditingController();
  final SpotifyApi _spotifyApi = SpotifyApi();
  Timer? _debounce;

  String _query = '';
  bool _spotifyLoading = false;
  String? _spotifyError;
  int _searchToken = 0;
  Set<String> _addingTrackIds = <String>{};
  List<Map<String, dynamic>> _spotifyTracks = [];

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _onQueryChanged(String value) {
    final normalized = value.trim();
    setState(() {
      _query = normalized;
      _spotifyError = null;
    });

    _debounce?.cancel();
    if (normalized.length < 2) {
      setState(() {
        _spotifyLoading = false;
        _spotifyTracks = [];
      });
      return;
    }

    _debounce = Timer(const Duration(milliseconds: 350), () {
      _searchSpotify(normalized);
    });
  }

  Future<void> _searchSpotify(String query) async {
    final requestToken = ++_searchToken;
    setState(() {
      _spotifyLoading = true;
      _spotifyError = null;
    });

    try {
      final results = await _spotifyApi.search(query, limit: 20);
      if (!mounted || requestToken != _searchToken) return;

      setState(() {
        _spotifyTracks = results;
        _spotifyLoading = false;
      });
    } catch (error) {
      if (!mounted || requestToken != _searchToken) return;

      setState(() {
        _spotifyTracks = [];
        _spotifyLoading = false;
        _spotifyError = '$error';
      });
    }
  }

  Future<void> _addSpotifyTrack(Map<String, dynamic> trackData) async {
    final spotifyId = trackData['id'] as String?;
    if (spotifyId == null || spotifyId.isEmpty) return;

    setState(() {
      _addingTrackIds = {..._addingTrackIds, spotifyId};
    });

    try {
      await ref.read(playlistEditorServiceProvider).addSpotifyTrackToPlaylist(
            playlistId: widget.playlist.id,
            trackData: trackData,
          );

      if (!mounted) return;

      final title = trackData['name'] as String? ?? 'Трек';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('"$title" добавлен в "${widget.playlist.name}"')),
      );
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Не удалось добавить трек: $error')),
      );
    } finally {
      if (!mounted) return;
      setState(() {
        _addingTrackIds = {..._addingTrackIds}..remove(spotifyId);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final tracksAsync = ref.watch(tracksProvider);

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          16,
          12,
          16,
          16 + MediaQuery.of(context).viewInsets.bottom,
        ),
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
            const SizedBox(height: 14),
            Text(
              'Добавить треки в "${widget.playlist.name}"',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _controller,
              onChanged: _onQueryChanged,
              decoration: InputDecoration(
                hintText: 'Искать треки в Spotify',
                prefixIcon: const Icon(Icons.search_rounded),
                suffixIcon: _query.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.close_rounded),
                        onPressed: () {
                          _controller.clear();
                          _onQueryChanged('');
                        },
                      )
                    : null,
                filled: true,
                fillColor: Colors.white.withOpacity(0.06),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: tracksAsync.when(
                data: (tracks) {
                  final localTracks = tracks.where((track) {
                    if (track.spotifyId == null || track.spotifyId!.isEmpty) {
                      return false;
                    }
                    if (widget.playlist.trackSpotifyIds
                        .contains(track.spotifyId)) {
                      return false;
                    }
                    if (_query.isEmpty) return true;

                    final haystack = [
                      track.title,
                      track.artist,
                      track.album ?? '',
                    ].join(' ').toLowerCase();

                    return haystack.contains(_query.toLowerCase());
                  }).toList();

                  return CustomScrollView(
                    slivers: [
                      if (_query.isEmpty) ...[
                        SliverToBoxAdapter(
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(4, 4, 4, 12),
                            child: Text(
                              'Локальная библиотека',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.7),
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                        if (localTracks.isEmpty)
                          const SliverToBoxAdapter(
                            child: Padding(
                              padding: EdgeInsets.symmetric(vertical: 20),
                              child: Text(
                                'В библиотеке пока нет доступных треков. Начни вводить запрос, чтобы искать по Spotify.',
                                style: TextStyle(color: Colors.white54),
                              ),
                            ),
                          )
                        else
                          SliverList(
                            delegate: SliverChildBuilderDelegate(
                              (context, index) => _LocalTrackTile(
                                track: localTracks[index],
                                onTap: () => _addTrackAndNotify(
                                  context,
                                  ref,
                                  widget.playlist.id,
                                  localTracks[index],
                                  widget.playlist.name,
                                ),
                              ),
                              childCount: localTracks.length,
                            ),
                          ),
                      ] else ...[
                        SliverToBoxAdapter(
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(4, 4, 4, 12),
                            child: Text(
                              'Результаты Spotify',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.7),
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                        if (_spotifyLoading)
                          const SliverFillRemaining(
                            hasScrollBody: false,
                            child: Center(child: CircularProgressIndicator()),
                          )
                        else if (_spotifyError != null)
                          SliverFillRemaining(
                            hasScrollBody: false,
                            child: Center(
                              child: Text(
                                'Ошибка поиска: $_spotifyError',
                                style: const TextStyle(color: Colors.white54),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          )
                        else if (_spotifyTracks.isEmpty)
                          const SliverFillRemaining(
                            hasScrollBody: false,
                            child: Center(
                              child: Text(
                                'Ничего не найдено',
                                style: TextStyle(color: Colors.white54),
                              ),
                            ),
                          )
                        else
                          SliverList(
                            delegate: SliverChildBuilderDelegate(
                              (context, index) {
                                final trackData = _spotifyTracks[index];
                                final spotifyId = trackData['id'] as String?;
                                final alreadyAdded = spotifyId != null &&
                                    widget.playlist.trackSpotifyIds
                                        .contains(spotifyId);

                                return _SpotifyTrackTile(
                                  trackData: trackData,
                                  busy: spotifyId != null &&
                                      _addingTrackIds.contains(spotifyId),
                                  alreadyAdded: alreadyAdded,
                                  onTap: alreadyAdded
                                      ? null
                                      : () => _addSpotifyTrack(trackData),
                                );
                              },
                              childCount: _spotifyTracks.length,
                            ),
                          ),
                      ],
                    ],
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, _) => Center(
                  child: Text('Ошибка загрузки треков: $error'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LocalTrackTile extends ConsumerWidget {
  final Track track;
  final Future<void> Function() onTap;

  const _LocalTrackTile({
    required this.track,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hasJam = ref.watch(jamProvider) != null;

    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: _Artwork(url: track.albumArtUrl),
      title: Text(
        track.title,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Text(
        track.artist,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(color: Colors.white54),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: Icon(Icons.hub_outlined,
                color: hasJam ? SpectrumColors.accent : Colors.white10),
            onPressed: () {
              if (!hasJam) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                    content:
                        Text('Сначала создайте JAM_SESSION во вкладке JAM')));
              } else {
                ref.read(jamProvider.notifier).addToQueue(track);
                ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('SIGNAL_QUEUED_TO_JAM')));
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.add_rounded),
            onPressed: onTap,
          ),
        ],
      ),
      onTap: onTap,
    );
  }
}

class _SpotifyTrackTile extends ConsumerWidget {
  final Map<String, dynamic> trackData;
  final bool busy;
  final bool alreadyAdded;
  final VoidCallback? onTap;

  const _SpotifyTrackTile({
    required this.trackData,
    required this.busy,
    required this.alreadyAdded,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hasJam = ref.watch(jamProvider) != null;
    final albumData = trackData['album'] as Map<String, dynamic>?;
    final images = albumData?['images'] as List?;
    final albumArtUrl = images?.firstOrNull?['url'] as String?;
    final artistsData = trackData['artists'] as List?;
    final artistName =
        artistsData?.firstOrNull?['name'] as String? ?? 'Unknown Artist';

    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: _Artwork(url: albumArtUrl),
      title: Text(
        trackData['name'] as String? ?? 'Unknown Title',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Text(
        artistName,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(color: Colors.white54),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: Icon(Icons.hub_outlined,
                color: hasJam ? SpectrumColors.accent : Colors.white10),
            onPressed: () async {
              if (!hasJam) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                    content:
                        Text('Сначала создайте JAM_SESSION во вкладке JAM')));
              } else {
                final track = await ref
                    .read(playlistEditorServiceProvider)
                    .saveSpotifyTrack(trackData);
                ref.read(jamProvider.notifier).addToQueue(track);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('SIGNAL_QUEUED_TO_JAM')));
                }
              }
            },
          ),
          busy
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : alreadyAdded
                  ? const Text(
                      'Уже есть',
                      style: TextStyle(color: Colors.white38),
                    )
                  : IconButton(
                      icon: const Icon(Icons.add_rounded),
                      onPressed: onTap,
                    ),
        ],
      ),
      onTap: busy || alreadyAdded ? null : onTap,
    );
  }
}

class _Artwork extends StatelessWidget {
  final String? url;

  const _Artwork({required this.url});

  @override
  Widget build(BuildContext context) {
    if (url == null) {
      return Container(
        width: 44,
        height: 44,
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
        width: 44,
        height: 44,
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

Future<Playlist?> _showCreatePlaylistDialog(
  BuildContext context,
  WidgetRef ref,
) async {
  final controller = TextEditingController();
  var creating = false;

  return showDialog<Playlist>(
    context: context,
    builder: (dialogContext) {
      return StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            backgroundColor: const Color(0xFF1A1A2E),
            title: const Text('Новый плейлист'),
            content: TextField(
              controller: controller,
              autofocus: true,
              decoration: const InputDecoration(
                hintText: 'Название плейлиста',
              ),
            ),
            actions: [
              TextButton(
                onPressed:
                    creating ? null : () => Navigator.of(dialogContext).pop(),
                child: const Text('Отмена'),
              ),
              FilledButton(
                onPressed: creating
                    ? null
                    : () async {
                        setState(() => creating = true);
                        try {
                          final playlist = await ref
                              .read(playlistEditorServiceProvider)
                              .createPlaylist(controller.text);
                          if (dialogContext.mounted) {
                            Navigator.of(dialogContext).pop(playlist);
                          }
                        } catch (error) {
                          if (!context.mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('$error')),
                          );
                        } finally {
                          if (context.mounted) {
                            setState(() => creating = false);
                          }
                        }
                      },
                child: creating
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Создать'),
              ),
            ],
          );
        },
      );
    },
  );
}

Future<void> _addTrackAndNotify(
  BuildContext context,
  WidgetRef ref,
  int playlistId,
  Track track,
  String playlistName,
) async {
  try {
    await ref.read(playlistEditorServiceProvider).addTrackToPlaylist(
          playlistId: playlistId,
          track: track,
        );
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Трек добавлен в "$playlistName"')),
    );
  } catch (error) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Не удалось добавить трек: $error')),
    );
  }
}
