// GENERATED CODE - DO NOT MODIFY BY HAND
// Run: flutter pub run build_runner build

import 'dart:io';
import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';
import 'package:spectrum/core/db/schemas/track_schema.dart';
import 'package:spectrum/core/db/schemas/playlist_schema.dart';
import 'package:spectrum/core/db/schemas/pending_action_schema.dart';
import 'package:spectrum/core/db/schemas/auth_token_schema.dart';

class IsarService {
  static late Isar _isar;

  static Isar get instance => _isar;

  static Future<void> init() async {
    String? finalPath;
    try {
      final supportDir = await getApplicationSupportDirectory().timeout(const Duration(seconds: 3));
      finalPath = supportDir.path;
    } catch (e) {
      finalPath = 'C:\\spectrum_db'; 
    }

    // Try to open first time
    try {
      _isar = await _openIsar(finalPath);
    } catch (e) {
      // If failed (MdbxError 775), try a "safe" path in the root of C:
      final fallbackPath = 'C:\\spectrum_db';
      if (finalPath == fallbackPath) rethrow; // Already tried fallback

      print("Isar failed at $finalPath, trying fallback: $fallbackPath");
      _isar = await _openIsar(fallbackPath);
    }
  }

  static Future<Isar> _openIsar(String path) async {
    final directory = Directory(path);
    if (!await directory.exists()) {
      await directory.create(recursive: true);
    }

    return await Isar.open(
      [
        TrackSchema,
        PlaylistSchema,
        PendingActionSchema,
        AuthTokenSchema,
      ],
      directory: path,
      name: 'spectrum_db',
    );
  }
}
