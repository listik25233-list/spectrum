import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar/isar.dart';
import 'package:spectrum/core/db/isar_service.dart';
import 'package:spectrum/core/db/schemas/playlist_schema.dart';

final playlistsProvider = StreamProvider<List<Playlist>>((ref) {
  final isar = IsarService.instance;
  return isar.playlists.where().watch(fireImmediately: true);
});
