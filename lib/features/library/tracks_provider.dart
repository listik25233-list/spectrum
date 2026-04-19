import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar/isar.dart';
import 'package:spectrum/core/db/isar_service.dart';
import 'package:spectrum/core/db/schemas/track_schema.dart';

final tracksProvider = StreamProvider<List<Track>>((ref) {
  final isar = IsarService.instance;
  return isar.tracks
      .where()
      .watch(fireImmediately: true)
      .map((tracks) {
        final sorted = List<Track>.from(tracks);
        sorted.sort((a, b) => b.id.compareTo(a.id));
        return sorted;
      });
});

final recentTracksProvider = StreamProvider<List<Track>>((ref) {
  final isar = IsarService.instance;
  return isar.tracks
      .where()
      .watch(fireImmediately: true)
      .map((tracks) {
        final sorted = List<Track>.from(tracks);
        sorted.sort((a, b) => b.id.compareTo(a.id));
        return sorted.take(6).toList();
      });
});
