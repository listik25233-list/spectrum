import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar/isar.dart';
import 'package:spectrum/core/db/isar_service.dart';
import 'package:spectrum/core/db/schemas/track_schema.dart';

final tracksProvider = StreamProvider<List<Track>>((ref) {
  final isar = IsarService.instance;
  // Listen to changes in the tracks collection and yield the updated list
  return isar.tracks.where().watch(fireImmediately: true);
});
