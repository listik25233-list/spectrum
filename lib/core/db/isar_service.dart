// GENERATED CODE - DO NOT MODIFY BY HAND
// Run: flutter pub run build_runner build

import 'dart:io';
import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';
import 'package:spectrum/core/db/schemas/track_schema.dart';
import 'package:spectrum/core/db/schemas/playlist_schema.dart';
import 'package:spectrum/core/db/schemas/auth_token_schema.dart';
import 'package:spectrum/core/db/schemas/theme_settings.dart';
import 'package:spectrum/core/db/schemas/cache_settings.dart';
import 'package:spectrum/core/db/schemas/youtube_search_cache.dart';

class IsarService {
  static late Isar _isar;

  static Isar get instance => _isar;

  static Future<void> init() async {
    String? finalPath;
    try {
      final dir = await getApplicationSupportDirectory();
      finalPath = '${dir.path}${Platform.isWindows ? '\\db' : '/db'}';
    } catch (e) {
      final docDir = await getApplicationDocumentsDirectory();
      finalPath = '${docDir.path}${Platform.isWindows ? '\\Spectrum\\db' : '/Spectrum/db'}';
    }

    try {
      _isar = await _openIsar(finalPath);
    } catch (e) {
      // 1. Try to clean up lock file if it exists
      try {
        final lockFile = File('$finalPath${Platform.isWindows ? '\\' : '/'}spectrum_db.isar.lock');
        if (lockFile.existsSync()) {
          lockFile.deleteSync();
        }
      } catch (_) {}

      try {
        // 2. Try opening again after cleanup
        _isar = await _openIsar(finalPath);
      } catch (e2) {
        // 3. Last chance: truly unique emergency path in Temp
        try {
          final tempDir = await getTemporaryDirectory();
          final emergencyPath = '${tempDir.path}${Platform.isWindows ? '\\spectrum_emergency_${DateTime.now().millisecondsSinceEpoch}' : '/spectrum_emergency'}';
          _isar = await _openIsar(emergencyPath);
        } catch (e3) {
          // If EVERYTHING fails, rethrow with the path for user diagnosis
          throw 'IsarError: Cannot open Environment: $e2\nPath attempted: $finalPath';
        }
      }
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
        AuthTokenSchema,
        ThemeSettingsSchema,
        CacheSettingsSchema,
        YoutubeSearchCacheSchema,
      ],
      directory: path,
      name: 'spectrum_db',
    );
  }
}
