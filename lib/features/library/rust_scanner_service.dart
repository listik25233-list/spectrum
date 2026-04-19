import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:spectrum/core/db/isar_service.dart';
import 'package:spectrum/core/db/schemas/track_schema.dart';
import 'package:spectrum/src/rust/api/library.dart' as rust;
import 'package:spectrum/src/rust/api/models.dart';
import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';

final rustScannerServiceProvider = Provider((ref) => RustScannerService());

class RustScannerService {
  bool _isScanning = false;
  bool get isScanning => _isScanning;

  Future<void> scanDirectory(String path) async {
    if (_isScanning) return;
    _isScanning = true;

    final isar = IsarService.instance;
    final tempDir = await getApplicationDocumentsDirectory();
    final cacheDir = '${tempDir.path}/covers';
    
    // We use the stream from Rust
    final stream = await rust.scanLocalDirectory(path: path, cacheDir: cacheDir);

    List<Track> batch = [];
    final batchSize = 50;

    await for (final metadata in stream) {
      if (metadata.localPath != null) {
        // This is a NEW track metadata
        final track = Track()
          ..title = metadata.title
          ..artist = metadata.artist
          ..durationMs = metadata.durationMs.toInt()
          ..localPath = metadata.localPath
          ..source = 'local'
          ..inLibrary = true;

        batch.add(track);

        if (batch.length >= batchSize) {
          await _flushBatch(isar, batch);
          batch = [];
        }
      } else {
        // This is an ASSET UPDATE (localPath is null in updated_metadata)
        await _updateAssets(isar, metadata);
      }
    }

    // Flush remaining
    if (batch.isNotEmpty) {
      await _flushBatch(isar, batch);
    }

    _isScanning = false;
  }

  Future<void> _flushBatch(Isar isar, List<Track> tracks) async {
    await isar.writeTxn(() async {
      for (final track in tracks) {
        final existing = await isar.tracks
            .filter()
            .localPathEqualTo(track.localPath)
            .findFirst();
            
        if (existing == null) {
          await isar.tracks.put(track);
        }
      }
    });
  }

  Future<void> _updateAssets(Isar isar, SpectrumTrackMetadata update) async {
    await isar.writeTxn(() async {
      final existing = await isar.tracks
          .filter()
          .localPathEqualTo(update.id)
          .findFirst();
          
      if (existing != null) {
        // Update only asset-related fields
        existing.artworkUrl = update.artworkUrl;
        existing.dominantColor = update.dominantColor;
        existing.blurHashPath = update.blurHashPath;
        await isar.tracks.put(existing);
      }
    });
  }
}
