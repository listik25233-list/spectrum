import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:spectrum/features/auth/auth_provider.dart';
import 'package:spectrum/features/library/playlist_screen.dart';
import 'package:spectrum/features/library/playlists_provider.dart';
import 'package:spectrum/features/library/tracks_provider.dart';
import 'package:spectrum/features/player/audio_player_service.dart';
import 'package:spectrum/features/player/mini_player.dart';
import 'package:spectrum/features/sync/sync_service.dart';

enum TrackSortMode { recentlyAdded, title, artist, duration }

final tracksSearchQueryProvider = StateProvider<String>((ref) => '');
final downloadedOnlyProvider = StateProvider<bool>((ref) => false);
final trackSortModeProvider = StateProvider<TrackSortMode>((ref) => TrackSortMode.recentlyAdded);

class LibraryScreen extends ConsumerWidget {
  const LibraryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isSyncing = ref.watch(isSyncingProvider);
    final syncProgress = ref.watch(syncProgressProvider);
    final query = ref.watch(tracksSearchQueryProvider);

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: const Color(0xFF121212),
        appBar: AppBar(
          backgroundColor: const Color(0xFF121212),
          elevation: 0,
          title: const Text(
            'Library',
            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 26, letterSpacing: -0.5),
          ),
          bottom: const TabBar(
            indicatorColor: Colors.white,
            indicatorWeight: 3,
            labelStyle: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            unselectedLabelStyle: TextStyle(fontWeight: FontWeight.w500, fontSize: 16),
            tabs: [
              Tab(text: 'Треки'),
              Tab(text: 'Плейлисты'),
            ],
          ),
          actions: [
            IconButton(
              icon: isSyncing
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.sync),
              onPressed: isSyncing ? null : () => ref.read(syncServiceProvider).syncSpotifyLibrary(),
            ),
            IconButton(
              icon: const Icon(Icons.tune_rounded),
              onPressed: () => _showFiltersSheet(context, ref),
            ),
            IconButton(
              icon: const Icon(Icons.account_circle_outlined),
              onPressed: () => _showAccountSheet(context, ref),
            ),
            IconButton(
              icon: const Icon(Icons.graphic_eq_rounded),
              tooltip: 'DJ',
              onPressed: () => _showDjAssistantSheet(context, ref),
            ),
            const SizedBox(width: 8),
          ],
        ),
        body: Column(
          children: [
            if (isSyncing)
              Container(
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                color: Colors.deepPurple.withOpacity(0.2),
                width: double.infinity,
                child: Text(
                  syncProgress,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 12, color: Colors.white70),
                ),
              ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 10, 24, 6),
              child: TextField(
                onChanged: (value) => ref.read(tracksSearchQueryProvider.notifier).state = value.trim(),
                decoration: InputDecoration(
                  hintText: 'Поиск треков и артистов',
                  prefixIcon: const Icon(Icons.search_rounded, size: 20),
                  suffixIcon: query.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.close_rounded, size: 18),
                          onPressed: () => ref.read(tracksSearchQueryProvider.notifier).state = '',
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
            ),
            Expanded(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1300),
                  child: TabBarView(
                    children: [
                      _buildTracksTab(ref),
                      _buildPlaylistsTab(ref),
                    ],
                  ),
                ),
              ),
            ),
            const MiniPlayer(),
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
          return track.title.toLowerCase().contains(query) || track.artist.toLowerCase().contains(query);
        }).toList();

        switch (sortMode) {
          case TrackSortMode.title:
            filtered.sort((a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()));
            break;
          case TrackSortMode.artist:
            filtered.sort((a, b) => a.artist.toLowerCase().compareTo(b.artist.toLowerCase()));
            break;
          case TrackSortMode.duration:
            filtered.sort((a, b) => b.durationMs.compareTo(a.durationMs));
            break;
          case TrackSortMode.recentlyAdded:
            break;
        }

        if (filtered.isEmpty) {
          return _buildEmptyState(ref, searchMode: query.isNotEmpty || downloadedOnly);
        }

        return ListView.builder(
          padding: const EdgeInsets.only(bottom: 100, top: 8),
          itemCount: filtered.length,
          itemBuilder: (context, index) {
            final track = filtered[index];
            final compact = MediaQuery.of(context).size.width < 740;
            return Material(
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
                subtitle: Row(
                  children: [
                    Expanded(
                      child: Text(
                        track.artist,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: Colors.white54, fontSize: 13),
                      ),
                    ),
                    if (track.localPath != null) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.green.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.green.withOpacity(0.45)),
                        ),
                        child: const Text(
                          'Загружен',
                          style: TextStyle(color: Colors.greenAccent, fontSize: 11, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ],
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
                      onPressed: () => ref.read(audioPlayerServiceProvider).playQueue(filtered, initialIndex: index),
                    ),
                  ],
                ),
                onTap: () => ref.read(audioPlayerServiceProvider).playQueue(filtered, initialIndex: index),
              ),
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, _) => Center(child: Text('Ошибка: $err')),
    );
  }

  Widget _buildPlaylistsTab(WidgetRef ref) {
    final playlistsAsync = ref.watch(playlistsProvider);
    return playlistsAsync.when(
      data: (playlists) {
        if (playlists.isEmpty) return _buildEmptyState(ref);
        return LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth;
            final crossAxisCount = width < 700 ? 2 : width < 1040 ? 4 : width < 1400 ? 5 : 6;
            return GridView.builder(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 100),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: crossAxisCount,
                crossAxisSpacing: 20,
                mainAxisSpacing: 20,
                childAspectRatio: 0.78,
              ),
              itemCount: playlists.length,
              itemBuilder: (context, index) {
                final playlist = playlists[index];
                return InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => PlaylistScreen(playlist: playlist),
                      ),
                    );
                  },
                  hoverColor: Colors.white.withOpacity(0.04),
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Container(
                            width: double.infinity,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.4),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(16),
                              child: playlist.artworkUrl != null
                                  ? Image.network(playlist.artworkUrl!, fit: BoxFit.cover)
                                  : Container(
                                      color: Colors.white12,
                                      child: const Icon(Icons.queue_music, size: 48, color: Colors.white38),
                                    ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          playlist.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${playlist.trackSpotifyIds.length} треков',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 12, color: Colors.white54),
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, _) => Center(child: Text('Ошибка: $err')),
    );
  }

  Widget _buildEmptyState(WidgetRef ref, {bool searchMode = false}) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.library_music_outlined, size: 64, color: Colors.white24),
          const SizedBox(height: 16),
          Text(
            searchMode ? 'Ничего не найдено' : 'Библиотека пуста',
            style: const TextStyle(color: Colors.white54, fontSize: 16),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () => ref.read(syncServiceProvider).syncSpotifyLibrary(),
            icon: const Icon(Icons.sync),
            label: const Text('Синхронизировать Spotify'),
          ),
        ],
      ),
    );
  }

  void _showFiltersSheet(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1A1A2E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        final downloadedOnly = ref.watch(downloadedOnlyProvider);
        final sortMode = ref.watch(trackSortModeProvider);
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
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
                SwitchListTile(
                  title: const Text('Только загруженные', style: TextStyle(color: Colors.white)),
                  value: downloadedOnly,
                  onChanged: (value) => ref.read(downloadedOnlyProvider.notifier).state = value,
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<TrackSortMode>(
                  value: sortMode,
                  dropdownColor: const Color(0xFF1A1A2E),
                  decoration: const InputDecoration(
                    labelText: 'Сортировка',
                    labelStyle: TextStyle(color: Colors.white70),
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(value: TrackSortMode.recentlyAdded, child: Text('Недавно добавленные')),
                    DropdownMenuItem(value: TrackSortMode.title, child: Text('По названию')),
                    DropdownMenuItem(value: TrackSortMode.artist, child: Text('По артисту')),
                    DropdownMenuItem(value: TrackSortMode.duration, child: Text('По длительности')),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      ref.read(trackSortModeProvider.notifier).state = value;
                    }
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showAccountSheet(BuildContext context, WidgetRef ref) {
    final authAsync = ref.read(authProvider);
    final connectedServices = authAsync.maybeWhen(data: (services) => services, orElse: () => <String>[]);
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
              const ListTile(
                leading: Icon(Icons.person_outline_rounded, color: Colors.white70),
                title: Text('Профиль', style: TextStyle(color: Colors.white)),
                subtitle: Text('Управление подключенными сервисами', style: TextStyle(color: Colors.white54)),
              ),
              ListTile(
                leading: const Icon(Icons.link_rounded, color: Colors.white70),
                title: const Text('Подключенные сервисы', style: TextStyle(color: Colors.white)),
                subtitle: Text(
                  connectedServices.isEmpty ? 'Нет подключений' : connectedServices.join(', '),
                  style: const TextStyle(color: Colors.white54),
                ),
              ),
              ListTile(
                leading: const Icon(Icons.settings_rounded, color: Colors.white70),
                title: const Text('Открыть настройки', style: TextStyle(color: Colors.white)),
                onTap: () {
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Открой Settings в меню навигации')),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showDjAssistantSheet(BuildContext context, WidgetRef ref) {
    final promptController = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF1A1A2E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        bool loading = false;
        DjMixResult? result;
        return StatefulBuilder(
          builder: (context, setState) {
            return SafeArea(
              child: Padding(
                padding: EdgeInsets.fromLTRB(16, 12, 16, 16 + MediaQuery.of(context).viewInsets.bottom),
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
                      'DJ Assistant',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: promptController,
                      minLines: 1,
                      maxLines: 3,
                      decoration: InputDecoration(
                        hintText: 'Напиши вайб: "ночной драйв", "спокойный вечер", "мрак + энергия"...',
                        filled: true,
                        fillColor: Colors.white.withOpacity(0.06),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Align(
                      alignment: Alignment.centerRight,
                      child: FilledButton.icon(
                        onPressed: loading
                            ? null
                            : () async {
                                setState(() => loading = true);
                                final generated = await ref.read(audioPlayerServiceProvider).generateDjMix(
                                  prompt: promptController.text.trim(),
                                  count: 5,
                                );
                                setState(() {
                                  result = generated;
                                  loading = false;
                                });
                              },
                        icon: loading
                            ? const SizedBox(
                                width: 14,
                                height: 14,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(Icons.auto_awesome_rounded),
                        label: const Text('Собрать подборку'),
                      ),
                    ),
                    if (result != null) ...[
                      const SizedBox(height: 12),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.deepPurple.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          result!.parsedArtist != null
                              ? '${result!.phrase}\n\nРаспознан исполнитель: ${result!.parsedArtist}'
                              : result!.phrase,
                          style: const TextStyle(color: Colors.white70),
                        ),
                      ),
                      const SizedBox(height: 8),
                      SizedBox(
                        height: 180,
                        child: ListView.builder(
                          itemCount: result!.tracks.length,
                          itemBuilder: (context, index) {
                            final t = result!.tracks[index];
                            return ListTile(
                              dense: true,
                              leading: Text('${index + 1}', style: const TextStyle(color: Colors.white54)),
                              title: Text(t.title, maxLines: 1, overflow: TextOverflow.ellipsis),
                              subtitle: Text(t.artist, maxLines: 1, overflow: TextOverflow.ellipsis),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 8),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton(
                          onPressed: result!.tracks.isEmpty
                              ? null
                              : () {
                                  Navigator.pop(ctx);
                                  ref.read(audioPlayerServiceProvider).startDjSession(
                                        prompt: promptController.text.trim(),
                                        count: 5,
                                      );
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('DJ v2 запущен: автоподборки по 5 треков')),
                                  );
                                },
                          child: const Text('Запустить подборку'),
                        ),
                      ),
                    ],
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


