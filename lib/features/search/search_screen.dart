import 'dart:async';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:spectrum/features/library/playlist_editor_service.dart';
import 'package:spectrum/features/player/audio_player_service.dart';
import 'package:spectrum/core/theme/spectrum_colors.dart';
import 'package:spectrum/src/rust/api/simple.dart' as rust;
import 'package:spectrum/src/rust/api/search.dart' as search_rust;
import 'package:spectrum/src/rust/api/models.dart' as rust_models;
import 'package:youtube_explode_dart/youtube_explode_dart.dart' as yt_exp;
import 'package:spectrum/core/db/isar_service.dart';
import 'package:spectrum/core/db/schemas/track_schema.dart';
import 'package:isar/isar.dart';

enum SearchSource { auto, youtube, soundcloud }

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  Timer? _debounce;

  String _query = '';
  bool _loading = false;
  String? _error;
  int _searchToken = 0;
  SearchSource _selectedSource = SearchSource.auto;

  List<rust_models.SpectrumTrackMetadata> _tracks = [];

  @override
  void dispose() {
    _scrollController.dispose();
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _onChanged(String value) {
    final normalized = value.trim();
    setState(() {
      _query = normalized;
      _error = null;
    });

    _debounce?.cancel();
    if (normalized.length < 2) {
      setState(() {
        _tracks = [];
        _loading = false;
      });
      return;
    }

    _debounce = Timer(const Duration(milliseconds: 350), () {
      _search(normalized);
    });
  }

  Future<void> _search(String query) async {
    if (query.isEmpty) return;
    final requestToken = ++_searchToken;
    
    setState(() {
      _loading = true;
      _error = null;
      _tracks = [];
    });

    try {
      // 1. Gather local tracks for the Unified Matrix Engine
      final isar = IsarService.instance;
      final localTracks = await isar.tracks.where().findAll();
      final localMetadata = localTracks.map((t) => rust_models.SpectrumTrackMetadata(
        id: t.id.toString(),
        title: t.title,
        artist: t.artist,
        durationMs: t.durationMs.toInt(),
        artworkUrl: t.albumArtUrl,
        source: 'local',
        localPath: t.localPath,
        dominantColor: t.dominantColor,
        blurHashPath: t.blurHashPath,
      )).toList();

      // 2. Execute Unified Search in Rust (Local + YouTube + SoundCloud)
      final sourceStr = _selectedSource.name;
      final results = await search_rust.unifiedSearch(
        query: query,
        localTracks: localMetadata,
        source: sourceStr,
      ).timeout(const Duration(seconds: 15));

      if (!mounted || requestToken != _searchToken) return;

      final processedResults = results.toList();

      // HYBRID FALLBACK: If Rust network engine failed (instances down), 
      // trigger the robust Dart scraper for YouTube specifically.
      final hasYouTube = processedResults.any((t) => t.source == 'youtube');
      if (!hasYouTube &&
          (_selectedSource == SearchSource.auto ||
              _selectedSource == SearchSource.youtube)) {
        try {
          final yt = yt_exp.YoutubeExplode();
          final ytResults = await yt.search.search(query);
          for (final video in ytResults.take(10)) {
            final ytTrack = rust_models.SpectrumTrackMetadata(
              id: video.id.value,
              title: video.title,
              artist: video.author,
              durationMs: video.duration?.inMilliseconds ?? 0,
              artworkUrl: video.thumbnails.highResUrl,
              source: 'youtube',
            );
            // Deduplicate against what we already have
            if (!processedResults
                .any((t) => t.title == ytTrack.title && t.artist == ytTrack.artist)) {
              processedResults.add(ytTrack);
            }
          }
          yt.close();
        } catch (e) {
          debugPrint('[Search] Hybrid fallback failed: $e');
        }
      }

      // 3. Post-process (Hi-res artwork and duplicates)
      final finalResults = processedResults.map<rust_models.SpectrumTrackMetadata>((t) {
        String? art = t.artworkUrl;
        if (t.source == 'soundcloud' && art != null && art.contains('-large.jpg')) {
          art = art.replaceAll('-large.jpg', '-t500x500.jpg');
          return rust_models.SpectrumTrackMetadata(
            id: t.id,
            title: t.title,
            artist: t.artist,
            durationMs: t.durationMs,
            artworkUrl: art,
            source: t.source,
          );
        }
        return t;
      }).toList();

      setState(() {
        _tracks = finalResults;
        _loading = false;
      });
    } catch (e) {
      if (!mounted || requestToken != _searchToken) return;
      setState(() {
        _loading = false;
        _error = 'Matrix Search Error: $e';
      });
    }
  }

  void _playTrack(rust_models.SpectrumTrackMetadata track) {
    final internalTrack = Track()
      ..title = track.title
      ..artist = track.artist
      ..durationMs = track.durationMs.toInt()
      ..albumArtUrl = track.artworkUrl
      ..youtubeId = track.source == 'youtube' ? track.id : null
      ..soundcloudId = track.source == 'soundcloud' ? track.id : null;
    
    ref.read(audioPlayerServiceProvider).playTrack(internalTrack);
  }

  void _toggleFavorite(rust_models.SpectrumTrackMetadata track) async {
    final isar = IsarService.instance;
    await isar.writeTxn(() async {
      final existing = await isar.tracks
          .filter()
          .titleEqualTo(track.title)
          .artistEqualTo(track.artist)
          .findFirst();

      if (existing != null) {
        existing.isFavorite = !existing.isFavorite;
        await isar.tracks.put(existing);
      } else {
        final newTrack = Track()
          ..title = track.title
          ..artist = track.artist
          ..durationMs = track.durationMs.toInt()
          ..albumArtUrl = track.artworkUrl
          ..youtubeId = track.source == 'youtube' ? track.id : null
          ..soundcloudId = track.source == 'soundcloud' ? track.id : null
          ..isFavorite = true
          ..inLibrary = true;
        await isar.tracks.put(newTrack);
      }
    });
    setState(() {});
  }

  Future<bool> _checkIsFavorite(rust_models.SpectrumTrackMetadata track) async {
    final isar = IsarService.instance;
    final existing = await isar.tracks
        .filter()
        .titleEqualTo(track.title)
        .artistEqualTo(track.artist)
        .findFirst();
    return existing?.isFavorite ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'SEARCH_MATRIX',
          style: TextStyle(
            color: SpectrumColors.textPrimary,
            fontWeight: FontWeight.w900,
            fontSize: 16,
            letterSpacing: 2.0,
          ),
        ),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1100),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              children: [
                _buildSearchBar(),
                const SizedBox(height: 12),
                _buildSourceSelector(),
                const SizedBox(height: 24),
                Expanded(child: _buildBody()),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return TextField(
      controller: _controller,
      onChanged: _onChanged,
      style: TextStyle(color: SpectrumColors.textPrimary, fontSize: 14),
      decoration: InputDecoration(
        hintText: 'Искать в сети Spectrum...',
        hintStyle: TextStyle(color: SpectrumColors.textMuted),
        prefixIcon: Icon(Icons.search_rounded,
            color: SpectrumColors.accent.withOpacity(0.5), size: 20),
        filled: true,
        fillColor: SpectrumColors.surface.withOpacity(0.5),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(4),
          borderSide: BorderSide(color: SpectrumColors.border),
        ),
      ),
    );
  }

  Widget _buildSourceSelector() {
    return Row(
      children: SearchSource.values.map((source) {
        final isSelected = _selectedSource == source;
        return Padding(
          padding: const EdgeInsets.only(right: 8),
          child: ChoiceChip(
            label: Text(source.name.toUpperCase()),
            selected: isSelected,
            onSelected: (val) {
              if (val) {
                setState(() => _selectedSource = source);
                if (_query.isNotEmpty) _search(_query);
              }
            },
            labelStyle: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w900,
              color: isSelected ? Colors.black : SpectrumColors.textMuted,
            ),
            selectedColor: SpectrumColors.accent,
            backgroundColor: SpectrumColors.surface,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
            side: BorderSide(
                color: isSelected ? SpectrumColors.accent : SpectrumColors.border),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildBody() {
    if (_query.isEmpty)
      return const Center(child: Text('Введите запрос для начала поиска'));
    if (_loading && _tracks.isEmpty)
      return const Center(child: CircularProgressIndicator());
    if (_error != null)
      return Center(
          child: Text(_error!, style: const TextStyle(color: Colors.redAccent)));
    if (_tracks.isEmpty) return const Center(child: Text('Ничего не найдено'));

    return ListView.builder(
      controller: _scrollController,
      itemCount: _tracks.length,
      itemBuilder: (context, index) {
        final track = _tracks[index];
        return _TrackTile(
          track: track,
          onTap: () => _playTrack(track),
          onFavoriteToggle: () => _toggleFavorite(track),
          isFavoriteFuture: _checkIsFavorite(track),
          isPlaying: false,
        );
      },
    );
  }
}

class _TrackTile extends StatelessWidget {
  final rust_models.SpectrumTrackMetadata track;
  final VoidCallback onTap;
  final VoidCallback onFavoriteToggle;
  final Future<bool> isFavoriteFuture;
  final bool isPlaying;

  const _TrackTile({
    required this.track,
    required this.onTap,
    required this.onFavoriteToggle,
    required this.isFavoriteFuture,
    required this.isPlaying,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 2),
      decoration: BoxDecoration(
        color: isPlaying
            ? SpectrumColors.accent.withOpacity(0.1)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(4),
      ),
      child: ListTile(
        onTap: onTap,
        dense: true,
        leading: _TrackArtwork(url: track.artworkUrl),
        title: Text(
          track.title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
              color: SpectrumColors.textPrimary,
              fontWeight: FontWeight.bold,
              fontSize: 13),
        ),
        subtitle: Row(
          children: [
            Flexible(
              child: Text(
                track.artist.toUpperCase(),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                    color: SpectrumColors.textSecondary,
                    fontSize: 9,
                    letterSpacing: 0.5),
              ),
            ),
            const SizedBox(width: 8),
            _SourceTag(source: track.source),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            FutureBuilder<bool>(
              future: isFavoriteFuture,
              builder: (context, snapshot) {
                final isFav = snapshot.data ?? false;
                return IconButton(
                  icon: Icon(
                    isFav ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                    color: isFav ? SpectrumColors.accent : SpectrumColors.textUltraMuted,
                    size: 18,
                  ),
                  onPressed: onFavoriteToggle,
                );
              },
            ),
            Text(
              _formatDuration(track.durationMs.toInt()),
              style: TextStyle(
                  color: SpectrumColors.textUltraMuted,
                  fontSize: 9,
                  fontFamily: 'monospace'),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDuration(int ms) {
    final dur = Duration(milliseconds: ms);
    return '${dur.inMinutes}:${(dur.inSeconds % 60).toString().padLeft(2, '0')}';
  }
}

class _TrackArtwork extends StatelessWidget {
  final String? url;
  const _TrackArtwork({this.url});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: SpectrumColors.surface,
        borderRadius: BorderRadius.circular(4),
        image: url != null ? DecorationImage(image: NetworkImage(url!), fit: BoxFit.cover) : null,
      ),
      child: url == null ? Icon(Icons.music_note_rounded, color: SpectrumColors.accent.withOpacity(0.2), size: 20) : null,
    );
  }
}

class _SourceTag extends StatelessWidget {
  final String source;
  const _SourceTag({required this.source});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
      decoration: BoxDecoration(
        color: source == 'youtube'
            ? Colors.red.withOpacity(0.2)
            : Colors.orange.withOpacity(0.2),
        borderRadius: BorderRadius.circular(2),
        border: Border.all(
            color: source == 'youtube'
                ? Colors.red.withOpacity(0.5)
                : Colors.orange.withOpacity(0.5),
            width: 0.5),
      ),
      child: Text(
        source.toUpperCase(),
        style: TextStyle(
          color: source == 'youtube' ? Colors.redAccent : Colors.orangeAccent,
          fontSize: 7,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
