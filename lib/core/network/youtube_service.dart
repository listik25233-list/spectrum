import 'dart:io';
import 'dart:convert';
import 'package:path_provider/path_provider.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';
import 'package:spectrum/core/db/schemas/track_schema.dart';
import 'package:spectrum/core/db/isar_service.dart';

class YoutubeAudioService {
  final YoutubeExplode _yt = YoutubeExplode();

  /// Gets the highest quality audio stream for a track,
  /// downloads it to cache, and returns the local file path.
  Future<String?> getAudioStreamUrl(Track track) async {
    try {
      String? videoId = track.youtubeId;

      if (videoId == null || videoId.isEmpty) {
        if (track.title.trim().isEmpty && track.artist.trim().isEmpty) {
          print('[YoutubeAudioService] Cannot search YouTube: Track metadata is empty.');
          return null;
        }
        
        print('[YoutubeAudioService] Searching for: ${track.artist} - ${track.title}');
        final query = '${track.artist} - ${track.title} audio';
        final searchResults = await _yt.search(query);
        
        if (searchResults.isNotEmpty) {
          final video = searchResults.first;
          videoId = video.id.value;
          print('[YoutubeAudioService] Found videoId: $videoId');

          // Cache the YouTube ID in Isar
          final isar = IsarService.instance;
          await isar.writeTxn(() async {
            track.youtubeId = videoId;
            await isar.tracks.put(track);
          });
        }
      }

      if (videoId == null) {
        print('[YoutubeAudioService] Video ID still null after search.');
        return null;
      }

      // Check permanent cache first
      final docsDir = await getApplicationDocumentsDirectory();
      final permFile = File('${docsDir.path}/spectrum_music/$videoId.m4a');
      if (await permFile.exists() && await permFile.length() > 0) {
        print('[YoutubeAudioService] Returning permanently cached file: ${permFile.path}');
        return permFile.path;
      }

      // Check temporary cache
      final tempDir = await getTemporaryDirectory();
      final cacheDir = Directory('${tempDir.path}/spectrum_cache');
      if (!await cacheDir.exists()) {
        await cacheDir.create(recursive: true);
      }
      
      final tempFile = File('${cacheDir.path}/$videoId.m4a');
      
      if (await tempFile.exists() && await tempFile.length() > 0) {
        print('[YoutubeAudioService] Returning temporary cached file: ${tempFile.path}');
        return tempFile.path;
      }

      print('[YoutubeAudioService] Video verified. Returning YouTube watch URL for streaming (skipping silent caching to prevent throttling).');
      return 'https://www.youtube.com/watch?v=$videoId';
    } catch (e) {
      print('Failed to get YouTube audio stream: $e');
      return null;
    }
  }

  Future<void> _downloadTrack(String videoId, File file) async {
    try {
      print('[YoutubeAudioService] 1. Starting download via yt-dlp... ($videoId)');
      
      // Delete any existing broken 0-byte file before starting, to prevent yt-dlp from skipping
      if (await file.exists()) {
        await file.delete();
      }
      
      final process = await Process.start('yt-dlp', [
        '-f', 'bestaudio[ext=m4a]',
        '--output', file.path,
        'https://www.youtube.com/watch?v=$videoId'
      ]);

      process.stdout.transform(utf8.decoder).listen((data) {
        if (data.contains('%')) {
          print('[yt-dlp] ${data.trim()}');
        }
      });
      
      process.stderr.transform(utf8.decoder).listen((data) {
        print('[yt-dlp ERROR] ${data.trim()}');
      });

      final exitCode = await process.exitCode;
      
      bool success = exitCode == 0;
      if (success) {
        // Double check length
        if (await file.exists() && await file.length() > 0) {
          print('[YoutubeAudioService] Download complete and cached: ${file.path}');
        } else {
          print('[YoutubeAudioService] yt-dlp produced an empty file.');
          success = false;
        }
      }
      
      if (!success) {
        print('[YoutubeAudioService] yt-dlp failed with exit code $exitCode. Deleting...');
        if (await file.exists()) await file.delete();
      }
    } catch (e) {
      print('[YoutubeAudioService] yt-dlp execution failed: $e');
      try {
        if (await file.exists()) await file.delete();
      } catch (_) {}
    }
  }

  /// Public method to explicitly download a track and return the permanent local path.
  Future<String?> downloadTrackToPermanent(Track track) async {
    try {
      String? videoId = track.youtubeId;

      if (videoId == null || videoId.isEmpty) {
        print('[YoutubeAudioService] downloadTrackToPermanent: Searching for: ${track.artist} - ${track.title}');
        final query = '${track.artist} - ${track.title} audio';
        final searchResults = await _yt.search(query);
        if (searchResults.isNotEmpty) {
          videoId = searchResults.first.id.value;
          final isar = IsarService.instance;
          await isar.writeTxn(() async {
            track.youtubeId = videoId;
            await isar.tracks.put(track);
          });
        }
      }

      if (videoId == null) return null;

      final docsDir = await getApplicationDocumentsDirectory();
      final musicDir = Directory('${docsDir.path}/spectrum_music');
      if (!await musicDir.exists()) {
        await musicDir.create(recursive: true);
      }

      final file = File('${musicDir.path}/$videoId.m4a');

      if (await file.exists() && await file.length() > 0) {
        return file.path;
      }

      await _downloadTrack(videoId, file);

      if (await file.exists() && await file.length() > 0) {
        return file.path;
      }
      return null;
    } catch (e) {
      print('[YoutubeAudioService] downloadTrackToPermanent failed: $e');
      return null;
    }
  }

  void dispose() {
    _yt.close();
  }
}
