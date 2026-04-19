import 'package:isar/isar.dart';

part 'youtube_search_cache.g.dart';

@Collection()
class YoutubeSearchCache {
  Id id = Isar.autoIncrement;

  @Index(unique: true, replace: true)
  late String query;

  late String videoId;

  late DateTime createdAt;

  YoutubeSearchCache();
}
