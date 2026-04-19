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

  @Index(type: IndexType.value, caseSensitive: false)
  String title = '';

  @Index(type: IndexType.value, caseSensitive: false)
  String artist = '';
  String? album;
  int durationMs = 0;

  String? previewUrl;

  @Index()
  String? artworkUrl;

  String? albumArtUrl;

  /// true if added by user to spectrum library
  bool inLibrary = true;

  /// E.g. /home/user/Music/Spectrum/...
  String? localPath;

  /// Plain text lyrics for fullscreen mode.
  String? lyrics;

  /// ReplayGain offset in dB (e.g., -3.5)
  double? replayGain;

  bool isFavorite = false;
  String? soundcloudId;
  String? dominantColor; // Hex string e.g. #ff00ea
  String? blurHashPath; // Path to blurred small webp

  Track();

  Map<String, dynamic> toJson() => {
        'spotifyId': spotifyId,
        'title': title,
        'artist': artist,
        'durationMs': durationMs,
        'albumArtUrl': albumArtUrl,
        'soundcloudId': soundcloudId,
        'replayGain': replayGain,
      };

  factory Track.fromJson(Map<String, dynamic> json) {
    final track = Track();
    track.spotifyId = json['spotifyId']?.toString();
    track.title = json['title']?.toString() ?? 'Unknown Title';
    track.artist = json['artist']?.toString() ?? 'Unknown Artist';
    track.durationMs = (json['durationMs'] as num?)?.toInt() ?? 0;
    track.albumArtUrl = json['albumArtUrl']?.toString();
    track.soundcloudId = json['soundcloudId']?.toString();
    track.replayGain = (json['replayGain'] as num?)?.toDouble();
    return track;
  }
}
