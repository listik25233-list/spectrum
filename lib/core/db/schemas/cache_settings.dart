import 'package:isar/isar.dart';

part 'cache_settings.g.dart';

@collection
class CacheSettings {
  Id id = Isar.autoIncrement;

  /// Max cache size in Gigabytes
  double maxCacheSizeGb = 5.0;

  /// Whether to show a notification when the cache is nearly full
  bool notificationsEnabled = true;

  /// Last time the cache was auto-cleaned
  DateTime? lastCleanup;
}
