import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:spectrum/core/db/isar_service.dart';
import 'package:isar/isar.dart';
import 'package:spectrum/core/db/schemas/cache_settings.dart';
import 'package:spectrum/core/db/schemas/track_schema.dart';
import 'package:spectrum/core/network/notification_service.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class PersistentSettingsService {
  final _storage = const FlutterSecureStorage();

  Future<void> save(String key, String value) async {
    await _storage.write(key: key, value: value);
  }

  Future<String?> load(String key) async {
    return await _storage.read(key: key);
  }
}

final persistentSettingsProvider = Provider((ref) => PersistentSettingsService());

class StorageInfo {
  final int permanentSize;
  final int cacheSize;
  final int totalUsed;
  final int downloadedCount;

  StorageInfo({
    required this.permanentSize,
    required this.cacheSize,
    required this.totalUsed,
    required this.downloadedCount,
  });
}

final storageServiceProvider = Provider((ref) => StorageService());

final storageInfoProvider =
    FutureProvider.autoDispose<StorageInfo>((ref) async {
  final service = ref.watch(storageServiceProvider);
  return service.getStorageInfo();
});

class StorageService {
  static const String permanentDirName = 'spectrum_music';
  static const String cacheDirName = 'spectrum_cache';

  Future<StorageInfo> getStorageInfo() async {
    final docsDir = await getApplicationDocumentsDirectory();
    final tempDir = await getTemporaryDirectory();

    final permanentDir = Directory('${docsDir.path}/$permanentDirName');
    final cacheDir = Directory('${tempDir.path}/$cacheDirName');

    var permanentSize = 0;
    var cacheSize = 0;

    if (await permanentDir.exists()) {
      permanentSize = await _getDirSize(permanentDir);
    }

    if (await cacheDir.exists()) {
      cacheSize = await _getDirSize(cacheDir);
    }

    final isar = IsarService.instance;
    final downloadedCount =
        await isar.tracks.filter().localPathIsNotNull().count();

    return StorageInfo(
      permanentSize: permanentSize,
      cacheSize: cacheSize,
      totalUsed: permanentSize + cacheSize,
      downloadedCount: downloadedCount,
    );
  }

  Future<void> autoCleanupCache() async {
    final tempDir = await getTemporaryDirectory();
    final docsDir = await getApplicationDocumentsDirectory();
    final cacheDir = Directory('${tempDir.path}/$cacheDirName');
    final hifiDir = Directory('${docsDir.path}/hifi_cache');

    final isar = IsarService.instance;
    final settings = await isar.cacheSettings.get(1) ?? CacheSettings();

    // Convert GB to bytes
    final maxCacheSizeBytes = (settings.maxCacheSizeGb * 1024 * 1024 * 1024).toInt();
    final targetCacheSizeBytes = (maxCacheSizeBytes * 0.7).toInt(); // Cleanup to 70%

    int currentSize = 0;
    List<File> allFiles = [];

    if (await cacheDir.exists()) {
      final files = await cacheDir.list().where((e) => e is File).cast<File>().toList();
      allFiles.addAll(files);
    }
    if (await hifiDir.exists()) {
      final files = await hifiDir.list().where((e) => e is File).cast<File>().toList();
      allFiles.addAll(files);
    }

    if (allFiles.isEmpty) return;

    for (var f in allFiles) {
      currentSize += await f.length();
    }

    if (currentSize > maxCacheSizeBytes) {
      print('[StorageService] Quota exceeded: ${currentSize ~/ (1024 * 1024)}MB / ${settings.maxCacheSizeGb}GB');
      
      if (settings.notificationsEnabled) {
        NotificationService().showStorageAlert(
          'Cache full (${(currentSize / (1024 * 1024 * 1024)).toStringAsFixed(1)}GB). '
          'Automated cleanup in progress.'
        );
      }

      // Sort by modification time (oldest first)
      allFiles.sort((a, b) => a.lastModifiedSync().compareTo(b.lastModifiedSync()));

      for (var f in allFiles) {
        if (currentSize <= targetCacheSizeBytes) break;
        final size = await f.length();
        await f.delete();
        currentSize -= size;
      }
      
      print('[StorageService] Cleanup complete. New size: ${currentSize ~/ (1024 * 1024)}MB');
    }
  }

  Future<int> _getDirSize(Directory dir) async {
    var size = 0;
    try {
      await for (var entity in dir.list(recursive: true, followLinks: false)) {
        if (entity is File) {
          size += await entity.length();
        }
      }
    } catch (_) {}
    return size;
  }

  Future<void> clearCache() async {
    final tempDir = await getTemporaryDirectory();
    final docsDir = await getApplicationDocumentsDirectory();
    final cacheDir = Directory('${tempDir.path}/$cacheDirName');
    final hifiDir = Directory('${docsDir.path}/hifi_cache');

    if (await cacheDir.exists()) {
      await cacheDir.delete(recursive: true);
      await cacheDir.create();
    }
    if (await hifiDir.exists()) {
      await hifiDir.delete(recursive: true);
      await hifiDir.create();
    }
  }

  Future<void> deleteAllDownloads() async {
    final docsDir = await getApplicationDocumentsDirectory();
    final permanentDir = Directory('${docsDir.path}/$permanentDirName');
    if (await permanentDir.exists()) {
      await permanentDir.delete(recursive: true);
      await permanentDir.create();
    }

    final isar = IsarService.instance;
    await isar.writeTxn(() async {
      final tracks = await isar.tracks.filter().localPathIsNotNull().findAll();
      for (final t in tracks) {
        t.localPath = null;
        await isar.tracks.put(t);
      }
    });
  }
}
