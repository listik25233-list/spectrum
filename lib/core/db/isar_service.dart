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
      // Use ApplicationSupport on Linux/Android, but for Windows we want a more stable path
      final dir = await getApplicationSupportDirectory();
      finalPath = '${dir.path}${Platform.isWindows ? '\\db' : '/db'}';
    } catch (e) {
      // Ultimate fallback: Documents folder (always has write access)
      final docDir = await getApplicationDocumentsDirectory();
      finalPath = '${docDir.path}${Platform.isWindows ? '\\Spectrum\\db' : '/Spectrum/db'}';
    }

    try {
      _isar = await _openIsar(finalPath);
    } catch (e) {
      // Final attempt with a unique fallback if the above is locked
      final tempDir = await getTemporaryDirectory();
      final fallbackPath = '${tempDir.path}${Platform.isWindows ? '\\spectrum_db_emergency' : '/spectrum_db_emergency'}';
      
      print('Isar normal init failed: $e. Trying emergency path: $fallbackPath');
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
