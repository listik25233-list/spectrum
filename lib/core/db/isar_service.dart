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
      // 1. Try AppSupport (AppData/Roaming) - best for Windows
      final supportDir = await getApplicationSupportDirectory().timeout(const Duration(seconds: 3));
      finalPath = supportDir.path;
    } catch (e) {
      // 2. Fallback to a very simple path that Wine usually likes
      finalPath = 'C:\\spectrum_db'; 
    }

    // Ensure directory exists manually
    final directory = Directory(finalPath);
    if (!await directory.exists()) {
      await directory.create(recursive: true);
    }

    try {
      _isar = await Isar.open(
        [
          TrackSchema,
          PlaylistSchema,
          PendingActionSchema,
          AuthTokenSchema,
        ],
        directory: finalPath,
        name: 'spectrum_db',
      );
    } catch (e) {
      // If it still fails, wrap the error with the path info for debugging
      throw "Isar failed to open at $finalPath. Error: $e";
    }
  }
}
