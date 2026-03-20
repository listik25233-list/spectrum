import 'package:isar/isar.dart';

part 'pending_action_schema.g.dart';

/// An action queued for execution when the network is available.
@Collection()
class PendingAction {
  Id id = Isar.autoIncrement;

  /// 'like' | 'unlike' | 'add_to_playlist' | 'remove_from_playlist'
  late String type;

  /// 'spotify' | 'apple' | 'youtube' | 'deezer' | 'tidal'
  late String service;

  late String trackIsrc;

  /// Additional data as JSON string (e.g. {"playlistId": "xyz"})
  String payload = '{}';

  late DateTime createdAt;
  int retries = 0;
}
