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
    Directory? dir;
    try {
      // getApplicationSupportDirectory maps to AppData/Roaming on Windows/Wine, 
      // which is the most reliable place for database files.
      dir = await getApplicationSupportDirectory().timeout(const Duration(seconds: 5));
    } catch (e) {
      print("Error getting support directory: $e");
      dir = Directory.current;
    }

    final path = dir.path;
    _isar = await Isar.open(
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
