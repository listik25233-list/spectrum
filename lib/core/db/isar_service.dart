// GENERATED CODE - DO NOT MODIFY BY HAND
// Run: flutter pub run build_runner build

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
    final dir = await getApplicationDocumentsDirectory();
    _isar = await Isar.open(
      [
        TrackSchema,
        PlaylistSchema,
        PendingActionSchema,
        AuthTokenSchema,
      ],
      directory: dir.path,
      name: 'spectrum_db',
    );
  }
}
