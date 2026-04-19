import 'package:isar/isar.dart';

part 'playlist_schema.g.dart';

@Collection()
class Playlist {
  Id id = Isar.autoIncrement;

  late String name;

  @Index()
  late String source;

  @Index()
  late String sourceId;

  /// Spotify IDs of tracks in this playlist (ordered)
  List<String> trackSpotifyIds = [];

  String? artworkUrl;
  late DateTime updatedAt;
}
