import 'package:isar/isar.dart';

part 'track_schema.g.dart';

@Collection()
class Track {
  Id id = Isar.autoIncrement;

  @Index()
  String? spotifyId;

  @Index()
  String? appleMusicId;

  @Index()
  String? youtubeId;

  @Index()
  String? isrc;

  late String title;
  late String artist;
  String? album;
  late int durationMs;

  String? previewUrl;

  String? albumArtUrl;

  /// true if added by user to spectrum library
  bool inLibrary = true;

  /// E.g. /home/user/Music/Spectrum/...
  String? localPath;

  /// Plain text lyrics for fullscreen mode.
  String? lyrics;
}
