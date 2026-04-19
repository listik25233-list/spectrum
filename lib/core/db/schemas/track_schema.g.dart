// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'track_schema.dart';

// **************************************************************************
// IsarCollectionGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetTrackCollection on Isar {
  IsarCollection<Track> get tracks => this.collection();
}

const TrackSchema = CollectionSchema(
  name: r'Track',
  id: 6244076704169336260,
  properties: {
    r'album': PropertySchema(
      id: 0,
      name: r'album',
      type: IsarType.string,
    ),
    r'albumArtUrl': PropertySchema(
      id: 1,
      name: r'albumArtUrl',
      type: IsarType.string,
    ),
    r'appleMusicId': PropertySchema(
      id: 2,
      name: r'appleMusicId',
      type: IsarType.string,
    ),
    r'artist': PropertySchema(
      id: 3,
      name: r'artist',
      type: IsarType.string,
    ),
    r'artworkUrl': PropertySchema(
      id: 4,
      name: r'artworkUrl',
      type: IsarType.string,
    ),
    r'blurHashPath': PropertySchema(
      id: 5,
      name: r'blurHashPath',
      type: IsarType.string,
    ),
    r'dominantColor': PropertySchema(
      id: 6,
      name: r'dominantColor',
      type: IsarType.string,
    ),
    r'durationMs': PropertySchema(
      id: 7,
      name: r'durationMs',
      type: IsarType.long,
    ),
    r'inLibrary': PropertySchema(
      id: 8,
      name: r'inLibrary',
      type: IsarType.bool,
    ),
    r'isFavorite': PropertySchema(
      id: 9,
      name: r'isFavorite',
      type: IsarType.bool,
    ),
    r'isrc': PropertySchema(
      id: 10,
      name: r'isrc',
      type: IsarType.string,
    ),
    r'localPath': PropertySchema(
      id: 11,
      name: r'localPath',
      type: IsarType.string,
    ),
    r'lyrics': PropertySchema(
      id: 12,
      name: r'lyrics',
      type: IsarType.string,
    ),
    r'previewUrl': PropertySchema(
      id: 13,
      name: r'previewUrl',
      type: IsarType.string,
    ),
    r'replayGain': PropertySchema(
      id: 14,
      name: r'replayGain',
      type: IsarType.double,
    ),
    r'soundcloudId': PropertySchema(
      id: 15,
      name: r'soundcloudId',
      type: IsarType.string,
    ),
    r'spotifyId': PropertySchema(
      id: 16,
      name: r'spotifyId',
      type: IsarType.string,
    ),
    r'title': PropertySchema(
      id: 17,
      name: r'title',
      type: IsarType.string,
    ),
    r'youtubeId': PropertySchema(
      id: 18,
      name: r'youtubeId',
      type: IsarType.string,
    )
  },
  estimateSize: _trackEstimateSize,
  serialize: _trackSerialize,
  deserialize: _trackDeserialize,
  deserializeProp: _trackDeserializeProp,
  idName: r'id',
  indexes: {
    r'spotifyId': IndexSchema(
      id: 7104577019864935629,
      name: r'spotifyId',
      unique: false,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'spotifyId',
          type: IndexType.hash,
          caseSensitive: true,
        )
      ],
    ),
    r'appleMusicId': IndexSchema(
      id: -8053108071038541889,
      name: r'appleMusicId',
      unique: false,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'appleMusicId',
          type: IndexType.hash,
          caseSensitive: true,
        )
      ],
    ),
    r'youtubeId': IndexSchema(
      id: -1747439737491472548,
      name: r'youtubeId',
      unique: false,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'youtubeId',
          type: IndexType.hash,
          caseSensitive: true,
        )
      ],
    ),
    r'isrc': IndexSchema(
      id: -1927634739440935338,
      name: r'isrc',
      unique: false,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'isrc',
          type: IndexType.hash,
          caseSensitive: true,
        )
      ],
    ),
    r'title': IndexSchema(
      id: -7636685945352118059,
      name: r'title',
      unique: false,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'title',
          type: IndexType.value,
          caseSensitive: false,
        )
      ],
    ),
    r'artist': IndexSchema(
      id: 5842945185359817302,
      name: r'artist',
      unique: false,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'artist',
          type: IndexType.value,
          caseSensitive: false,
        )
      ],
    ),
    r'artworkUrl': IndexSchema(
      id: -4569562292177228156,
      name: r'artworkUrl',
      unique: false,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'artworkUrl',
          type: IndexType.hash,
          caseSensitive: true,
        )
      ],
    )
  },
  links: {},
  embeddedSchemas: {},
  getId: _trackGetId,
  getLinks: _trackGetLinks,
  attach: _trackAttach,
  version: '3.1.0+1',
);

int _trackEstimateSize(
  Track object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  {
    final value = object.album;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  {
    final value = object.albumArtUrl;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  {
    final value = object.appleMusicId;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  bytesCount += 3 + object.artist.length * 3;
  {
    final value = object.artworkUrl;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  {
    final value = object.blurHashPath;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  {
    final value = object.dominantColor;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  {
    final value = object.isrc;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  {
    final value = object.localPath;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  {
    final value = object.lyrics;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  {
    final value = object.previewUrl;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  {
    final value = object.soundcloudId;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  {
    final value = object.spotifyId;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  bytesCount += 3 + object.title.length * 3;
  {
    final value = object.youtubeId;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  return bytesCount;
}

void _trackSerialize(
  Track object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeString(offsets[0], object.album);
  writer.writeString(offsets[1], object.albumArtUrl);
  writer.writeString(offsets[2], object.appleMusicId);
  writer.writeString(offsets[3], object.artist);
  writer.writeString(offsets[4], object.artworkUrl);
  writer.writeString(offsets[5], object.blurHashPath);
  writer.writeString(offsets[6], object.dominantColor);
  writer.writeLong(offsets[7], object.durationMs);
  writer.writeBool(offsets[8], object.inLibrary);
  writer.writeBool(offsets[9], object.isFavorite);
  writer.writeString(offsets[10], object.isrc);
  writer.writeString(offsets[11], object.localPath);
  writer.writeString(offsets[12], object.lyrics);
  writer.writeString(offsets[13], object.previewUrl);
  writer.writeDouble(offsets[14], object.replayGain);
  writer.writeString(offsets[15], object.soundcloudId);
  writer.writeString(offsets[16], object.spotifyId);
  writer.writeString(offsets[17], object.title);
  writer.writeString(offsets[18], object.youtubeId);
}

Track _trackDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = Track();
  object.album = reader.readStringOrNull(offsets[0]);
  object.albumArtUrl = reader.readStringOrNull(offsets[1]);
  object.appleMusicId = reader.readStringOrNull(offsets[2]);
  object.artist = reader.readString(offsets[3]);
  object.artworkUrl = reader.readStringOrNull(offsets[4]);
  object.blurHashPath = reader.readStringOrNull(offsets[5]);
  object.dominantColor = reader.readStringOrNull(offsets[6]);
  object.durationMs = reader.readLong(offsets[7]);
  object.id = id;
  object.inLibrary = reader.readBool(offsets[8]);
  object.isFavorite = reader.readBool(offsets[9]);
  object.isrc = reader.readStringOrNull(offsets[10]);
  object.localPath = reader.readStringOrNull(offsets[11]);
  object.lyrics = reader.readStringOrNull(offsets[12]);
  object.previewUrl = reader.readStringOrNull(offsets[13]);
  object.replayGain = reader.readDoubleOrNull(offsets[14]);
  object.soundcloudId = reader.readStringOrNull(offsets[15]);
  object.spotifyId = reader.readStringOrNull(offsets[16]);
  object.title = reader.readString(offsets[17]);
  object.youtubeId = reader.readStringOrNull(offsets[18]);
  return object;
}

P _trackDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readStringOrNull(offset)) as P;
    case 1:
      return (reader.readStringOrNull(offset)) as P;
    case 2:
      return (reader.readStringOrNull(offset)) as P;
    case 3:
      return (reader.readString(offset)) as P;
    case 4:
      return (reader.readStringOrNull(offset)) as P;
    case 5:
      return (reader.readStringOrNull(offset)) as P;
    case 6:
      return (reader.readStringOrNull(offset)) as P;
    case 7:
      return (reader.readLong(offset)) as P;
    case 8:
      return (reader.readBool(offset)) as P;
    case 9:
      return (reader.readBool(offset)) as P;
    case 10:
      return (reader.readStringOrNull(offset)) as P;
    case 11:
      return (reader.readStringOrNull(offset)) as P;
    case 12:
      return (reader.readStringOrNull(offset)) as P;
    case 13:
      return (reader.readStringOrNull(offset)) as P;
    case 14:
      return (reader.readDoubleOrNull(offset)) as P;
    case 15:
      return (reader.readStringOrNull(offset)) as P;
    case 16:
      return (reader.readStringOrNull(offset)) as P;
    case 17:
      return (reader.readString(offset)) as P;
    case 18:
      return (reader.readStringOrNull(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

Id _trackGetId(Track object) {
  return object.id;
}

List<IsarLinkBase<dynamic>> _trackGetLinks(Track object) {
  return [];
}

void _trackAttach(IsarCollection<dynamic> col, Id id, Track object) {
  object.id = id;
}

extension TrackQueryWhereSort on QueryBuilder<Track, Track, QWhere> {
  QueryBuilder<Track, Track, QAfterWhere> anyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }

  QueryBuilder<Track, Track, QAfterWhere> anyTitle() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        const IndexWhereClause.any(indexName: r'title'),
      );
    });
  }

  QueryBuilder<Track, Track, QAfterWhere> anyArtist() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        const IndexWhereClause.any(indexName: r'artist'),
      );
    });
  }
}

extension TrackQueryWhere on QueryBuilder<Track, Track, QWhereClause> {
  QueryBuilder<Track, Track, QAfterWhereClause> idEqualTo(Id id) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: id,
        upper: id,
      ));
    });
  }

  QueryBuilder<Track, Track, QAfterWhereClause> idNotEqualTo(Id id) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(
              IdWhereClause.lessThan(upper: id, includeUpper: false),
            )
            .addWhereClause(
              IdWhereClause.greaterThan(lower: id, includeLower: false),
            );
      } else {
        return query
            .addWhereClause(
              IdWhereClause.greaterThan(lower: id, includeLower: false),
            )
            .addWhereClause(
              IdWhereClause.lessThan(upper: id, includeUpper: false),
            );
      }
    });
  }

  QueryBuilder<Track, Track, QAfterWhereClause> idGreaterThan(Id id,
      {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: id, includeLower: include),
      );
    });
  }

  QueryBuilder<Track, Track, QAfterWhereClause> idLessThan(Id id,
      {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: id, includeUpper: include),
      );
    });
  }

  QueryBuilder<Track, Track, QAfterWhereClause> idBetween(
    Id lowerId,
    Id upperId, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: lowerId,
        includeLower: includeLower,
        upper: upperId,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<Track, Track, QAfterWhereClause> spotifyIdIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'spotifyId',
        value: [null],
      ));
    });
  }

  QueryBuilder<Track, Track, QAfterWhereClause> spotifyIdIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'spotifyId',
        lower: [null],
        includeLower: false,
        upper: [],
      ));
    });
  }

  QueryBuilder<Track, Track, QAfterWhereClause> spotifyIdEqualTo(
      String? spotifyId) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'spotifyId',
        value: [spotifyId],
      ));
    });
  }

  QueryBuilder<Track, Track, QAfterWhereClause> spotifyIdNotEqualTo(
      String? spotifyId) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'spotifyId',
              lower: [],
              upper: [spotifyId],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'spotifyId',
              lower: [spotifyId],
              includeLower: false,
              upper: [],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'spotifyId',
              lower: [spotifyId],
              includeLower: false,
              upper: [],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'spotifyId',
              lower: [],
              upper: [spotifyId],
              includeUpper: false,
            ));
      }
    });
  }

  QueryBuilder<Track, Track, QAfterWhereClause> appleMusicIdIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'appleMusicId',
        value: [null],
      ));
    });
  }

  QueryBuilder<Track, Track, QAfterWhereClause> appleMusicIdIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'appleMusicId',
        lower: [null],
        includeLower: false,
        upper: [],
      ));
    });
  }

  QueryBuilder<Track, Track, QAfterWhereClause> appleMusicIdEqualTo(
      String? appleMusicId) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'appleMusicId',
        value: [appleMusicId],
      ));
    });
  }

  QueryBuilder<Track, Track, QAfterWhereClause> appleMusicIdNotEqualTo(
      String? appleMusicId) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'appleMusicId',
              lower: [],
              upper: [appleMusicId],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'appleMusicId',
              lower: [appleMusicId],
              includeLower: false,
              upper: [],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'appleMusicId',
              lower: [appleMusicId],
              includeLower: false,
              upper: [],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'appleMusicId',
              lower: [],
              upper: [appleMusicId],
              includeUpper: false,
            ));
      }
    });
  }

  QueryBuilder<Track, Track, QAfterWhereClause> youtubeIdIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'youtubeId',
        value: [null],
      ));
    });
  }

  QueryBuilder<Track, Track, QAfterWhereClause> youtubeIdIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'youtubeId',
        lower: [null],
        includeLower: false,
        upper: [],
      ));
    });
  }

  QueryBuilder<Track, Track, QAfterWhereClause> youtubeIdEqualTo(
      String? youtubeId) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'youtubeId',
        value: [youtubeId],
      ));
    });
  }

  QueryBuilder<Track, Track, QAfterWhereClause> youtubeIdNotEqualTo(
      String? youtubeId) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'youtubeId',
              lower: [],
              upper: [youtubeId],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'youtubeId',
              lower: [youtubeId],
              includeLower: false,
              upper: [],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'youtubeId',
              lower: [youtubeId],
              includeLower: false,
              upper: [],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'youtubeId',
              lower: [],
              upper: [youtubeId],
              includeUpper: false,
            ));
      }
    });
  }

  QueryBuilder<Track, Track, QAfterWhereClause> isrcIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'isrc',
        value: [null],
      ));
    });
  }

  QueryBuilder<Track, Track, QAfterWhereClause> isrcIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'isrc',
        lower: [null],
        includeLower: false,
        upper: [],
      ));
    });
  }

  QueryBuilder<Track, Track, QAfterWhereClause> isrcEqualTo(String? isrc) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'isrc',
        value: [isrc],
      ));
    });
  }

  QueryBuilder<Track, Track, QAfterWhereClause> isrcNotEqualTo(String? isrc) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'isrc',
              lower: [],
              upper: [isrc],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'isrc',
              lower: [isrc],
              includeLower: false,
              upper: [],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'isrc',
              lower: [isrc],
              includeLower: false,
              upper: [],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'isrc',
              lower: [],
              upper: [isrc],
              includeUpper: false,
            ));
      }
    });
  }

  QueryBuilder<Track, Track, QAfterWhereClause> titleEqualTo(String title) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'title',
        value: [title],
      ));
    });
  }

  QueryBuilder<Track, Track, QAfterWhereClause> titleNotEqualTo(String title) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'title',
              lower: [],
              upper: [title],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'title',
              lower: [title],
              includeLower: false,
              upper: [],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'title',
              lower: [title],
              includeLower: false,
              upper: [],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'title',
              lower: [],
              upper: [title],
              includeUpper: false,
            ));
      }
    });
  }

  QueryBuilder<Track, Track, QAfterWhereClause> titleGreaterThan(
    String title, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'title',
        lower: [title],
        includeLower: include,
        upper: [],
      ));
    });
  }

  QueryBuilder<Track, Track, QAfterWhereClause> titleLessThan(
    String title, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'title',
        lower: [],
        upper: [title],
        includeUpper: include,
      ));
    });
  }

  QueryBuilder<Track, Track, QAfterWhereClause> titleBetween(
    String lowerTitle,
    String upperTitle, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'title',
        lower: [lowerTitle],
        includeLower: includeLower,
        upper: [upperTitle],
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<Track, Track, QAfterWhereClause> titleStartsWith(
      String TitlePrefix) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'title',
        lower: [TitlePrefix],
        upper: ['$TitlePrefix\u{FFFFF}'],
      ));
    });
  }

  QueryBuilder<Track, Track, QAfterWhereClause> titleIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'title',
        value: [''],
      ));
    });
  }

  QueryBuilder<Track, Track, QAfterWhereClause> titleIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.lessThan(
              indexName: r'title',
              upper: [''],
            ))
            .addWhereClause(IndexWhereClause.greaterThan(
              indexName: r'title',
              lower: [''],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.greaterThan(
              indexName: r'title',
              lower: [''],
            ))
            .addWhereClause(IndexWhereClause.lessThan(
              indexName: r'title',
              upper: [''],
            ));
      }
    });
  }

  QueryBuilder<Track, Track, QAfterWhereClause> artistEqualTo(String artist) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'artist',
        value: [artist],
      ));
    });
  }

  QueryBuilder<Track, Track, QAfterWhereClause> artistNotEqualTo(
      String artist) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'artist',
              lower: [],
              upper: [artist],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'artist',
              lower: [artist],
              includeLower: false,
              upper: [],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'artist',
              lower: [artist],
              includeLower: false,
              upper: [],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'artist',
              lower: [],
              upper: [artist],
              includeUpper: false,
            ));
      }
    });
  }

  QueryBuilder<Track, Track, QAfterWhereClause> artistGreaterThan(
    String artist, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'artist',
        lower: [artist],
        includeLower: include,
        upper: [],
      ));
    });
  }

  QueryBuilder<Track, Track, QAfterWhereClause> artistLessThan(
    String artist, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'artist',
        lower: [],
        upper: [artist],
        includeUpper: include,
      ));
    });
  }

  QueryBuilder<Track, Track, QAfterWhereClause> artistBetween(
    String lowerArtist,
    String upperArtist, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'artist',
        lower: [lowerArtist],
        includeLower: includeLower,
        upper: [upperArtist],
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<Track, Track, QAfterWhereClause> artistStartsWith(
      String ArtistPrefix) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'artist',
        lower: [ArtistPrefix],
        upper: ['$ArtistPrefix\u{FFFFF}'],
      ));
    });
  }

  QueryBuilder<Track, Track, QAfterWhereClause> artistIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'artist',
        value: [''],
      ));
    });
  }

  QueryBuilder<Track, Track, QAfterWhereClause> artistIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.lessThan(
              indexName: r'artist',
              upper: [''],
            ))
            .addWhereClause(IndexWhereClause.greaterThan(
              indexName: r'artist',
              lower: [''],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.greaterThan(
              indexName: r'artist',
              lower: [''],
            ))
            .addWhereClause(IndexWhereClause.lessThan(
              indexName: r'artist',
              upper: [''],
            ));
      }
    });
  }

  QueryBuilder<Track, Track, QAfterWhereClause> artworkUrlIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'artworkUrl',
        value: [null],
      ));
    });
  }

  QueryBuilder<Track, Track, QAfterWhereClause> artworkUrlIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'artworkUrl',
        lower: [null],
        includeLower: false,
        upper: [],
      ));
    });
  }

  QueryBuilder<Track, Track, QAfterWhereClause> artworkUrlEqualTo(
      String? artworkUrl) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'artworkUrl',
        value: [artworkUrl],
      ));
    });
  }

  QueryBuilder<Track, Track, QAfterWhereClause> artworkUrlNotEqualTo(
      String? artworkUrl) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'artworkUrl',
              lower: [],
              upper: [artworkUrl],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'artworkUrl',
              lower: [artworkUrl],
              includeLower: false,
              upper: [],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'artworkUrl',
              lower: [artworkUrl],
              includeLower: false,
              upper: [],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'artworkUrl',
              lower: [],
              upper: [artworkUrl],
              includeUpper: false,
            ));
      }
    });
  }
}

extension TrackQueryFilter on QueryBuilder<Track, Track, QFilterCondition> {
  QueryBuilder<Track, Track, QAfterFilterCondition> albumIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'album',
      ));
    });
  }

  QueryBuilder<Track, Track, QAfterFilterCondition> albumIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'album',
      ));
    });
  }

  QueryBuilder<Track, Track, QAfterFilterCondition> albumEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'album',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Track, Track, QAfterFilterCondition> albumGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'album',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Track, Track, QAfterFilterCondition> albumLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'album',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Track, Track, QAfterFilterCondition> albumBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'album',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Track, Track, QAfterFilterCondition> albumStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'album',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Track, Track, QAfterFilterCondition> albumEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'album',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Track, Track, QAfterFilterCondition> albumContains(String value,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'album',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Track, Track, QAfterFilterCondition> albumMatches(String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'album',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Track, Track, QAfterFilterCondition> albumIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'album',
        value: '',
      ));
    });
  }

  QueryBuilder<Track, Track, QAfterFilterCondition> albumIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'album',
        value: '',
      ));
    });
  }

  QueryBuilder<Track, Track, QAfterFilterCondition> albumArtUrlIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'albumArtUrl',
      ));
    });
  }

  QueryBuilder<Track, Track, QAfterFilterCondition> albumArtUrlIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'albumArtUrl',
      ));
    });
  }

  QueryBuilder<Track, Track, QAfterFilterCondition> albumArtUrlEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'albumArtUrl',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Track, Track, QAfterFilterCondition> albumArtUrlGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'albumArtUrl',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Track, Track, QAfterFilterCondition> albumArtUrlLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'albumArtUrl',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Track, Track, QAfterFilterCondition> albumArtUrlBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'albumArtUrl',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Track, Track, QAfterFilterCondition> albumArtUrlStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'albumArtUrl',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Track, Track, QAfterFilterCondition> albumArtUrlEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'albumArtUrl',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Track, Track, QAfterFilterCondition> albumArtUrlContains(
      String value,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'albumArtUrl',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Track, Track, QAfterFilterCondition> albumArtUrlMatches(
      String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'albumArtUrl',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Track, Track, QAfterFilterCondition> albumArtUrlIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'albumArtUrl',
        value: '',
      ));
    });
  }

  QueryBuilder<Track, Track, QAfterFilterCondition> albumArtUrlIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'albumArtUrl',
        value: '',
      ));
    });
  }

  QueryBuilder<Track, Track, QAfterFilterCondition> appleMusicIdIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'appleMusicId',
      ));
    });
  }

  QueryBuilder<Track, Track, QAfterFilterCondition> appleMusicIdIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'appleMusicId',
      ));
    });
  }

  QueryBuilder<Track, Track, QAfterFilterCondition> appleMusicIdEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'appleMusicId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Track, Track, QAfterFilterCondition> appleMusicIdGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'appleMusicId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Track, Track, QAfterFilterCondition> appleMusicIdLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'appleMusicId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Track, Track, QAfterFilterCondition> appleMusicIdBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'appleMusicId',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Track, Track, QAfterFilterCondition> appleMusicIdStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'appleMusicId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Track, Track, QAfterFilterCondition> appleMusicIdEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'appleMusicId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Track, Track, QAfterFilterCondition> appleMusicIdContains(
      String value,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'appleMusicId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Track, Track, QAfterFilterCondition> appleMusicIdMatches(
      String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'appleMusicId',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Track, Track, QAfterFilterCondition> appleMusicIdIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'appleMusicId',
        value: '',
      ));
    });
  }

  QueryBuilder<Track, Track, QAfterFilterCondition> appleMusicIdIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'appleMusicId',
        value: '',
      ));
    });
  }

  QueryBuilder<Track, Track, QAfterFilterCondition> artistEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'artist',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Track, Track, QAfterFilterCondition> artistGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'artist',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Track, Track, QAfterFilterCondition> artistLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'artist',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Track, Track, QAfterFilterCondition> artistBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'artist',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Track, Track, QAfterFilterCondition> artistStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'artist',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Track, Track, QAfterFilterCondition> artistEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'artist',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Track, Track, QAfterFilterCondition> artistContains(String value,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'artist',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Track, Track, QAfterFilterCondition> artistMatches(
      String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'artist',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Track, Track, QAfterFilterCondition> artistIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'artist',
        value: '',
      ));
    });
  }

  QueryBuilder<Track, Track, QAfterFilterCondition> artistIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'artist',
        value: '',
      ));
    });
  }

  QueryBuilder<Track, Track, QAfterFilterCondition> artworkUrlIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'artworkUrl',
      ));
    });
  }

  QueryBuilder<Track, Track, QAfterFilterCondition> artworkUrlIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'artworkUrl',
      ));
    });
  }

  QueryBuilder<Track, Track, QAfterFilterCondition> artworkUrlEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'artworkUrl',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Track, Track, QAfterFilterCondition> artworkUrlGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'artworkUrl',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Track, Track, QAfterFilterCondition> artworkUrlLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'artworkUrl',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Track, Track, QAfterFilterCondition> artworkUrlBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'artworkUrl',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Track, Track, QAfterFilterCondition> artworkUrlStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'artworkUrl',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Track, Track, QAfterFilterCondition> artworkUrlEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'artworkUrl',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Track, Track, QAfterFilterCondition> artworkUrlContains(
      String value,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'artworkUrl',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Track, Track, QAfterFilterCondition> artworkUrlMatches(
      String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'artworkUrl',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Track, Track, QAfterFilterCondition> artworkUrlIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'artworkUrl',
        value: '',
      ));
    });
  }

  QueryBuilder<Track, Track, QAfterFilterCondition> artworkUrlIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'artworkUrl',
        value: '',
      ));
    });
  }

  QueryBuilder<Track, Track, QAfterFilterCondition> blurHashPathIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'blurHashPath',
      ));
    });
  }

  QueryBuilder<Track, Track, QAfterFilterCondition> blurHashPathIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'blurHashPath',
      ));
    });
  }

  QueryBuilder<Track, Track, QAfterFilterCondition> blurHashPathEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'blurHashPath',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Track, Track, QAfterFilterCondition> blurHashPathGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'blurHashPath',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Track, Track, QAfterFilterCondition> blurHashPathLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'blurHashPath',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Track, Track, QAfterFilterCondition> blurHashPathBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'blurHashPath',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Track, Track, QAfterFilterCondition> blurHashPathStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'blurHashPath',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Track, Track, QAfterFilterCondition> blurHashPathEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'blurHashPath',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Track, Track, QAfterFilterCondition> blurHashPathContains(
      String value,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'blurHashPath',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Track, Track, QAfterFilterCondition> blurHashPathMatches(
      String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'blurHashPath',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Track, Track, QAfterFilterCondition> blurHashPathIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'blurHashPath',
        value: '',
      ));
    });
  }

  QueryBuilder<Track, Track, QAfterFilterCondition> blurHashPathIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'blurHashPath',
        value: '',
      ));
    });
  }

  QueryBuilder<Track, Track, QAfterFilterCondition> dominantColorIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'dominantColor',
      ));
    });
  }

  QueryBuilder<Track, Track, QAfterFilterCondition> dominantColorIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'dominantColor',
      ));
    });
  }

  QueryBuilder<Track, Track, QAfterFilterCondition> dominantColorEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'dominantColor',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Track, Track, QAfterFilterCondition> dominantColorGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'dominantColor',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Track, Track, QAfterFilterCondition> dominantColorLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'dominantColor',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Track, Track, QAfterFilterCondition> dominantColorBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'dominantColor',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Track, Track, QAfterFilterCondition> dominantColorStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'dominantColor',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Track, Track, QAfterFilterCondition> dominantColorEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'dominantColor',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Track, Track, QAfterFilterCondition> dominantColorContains(
      String value,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'dominantColor',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Track, Track, QAfterFilterCondition> dominantColorMatches(
      String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'dominantColor',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Track, Track, QAfterFilterCondition> dominantColorIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'dominantColor',
        value: '',
      ));
    });
  }

  QueryBuilder<Track, Track, QAfterFilterCondition> dominantColorIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'dominantColor',
        value: '',
      ));
    });
  }

  QueryBuilder<Track, Track, QAfterFilterCondition> durationMsEqualTo(
      int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'durationMs',
        value: value,
      ));
    });
  }

  QueryBuilder<Track, Track, QAfterFilterCondition> durationMsGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'durationMs',
        value: value,
      ));
    });
  }

  QueryBuilder<Track, Track, QAfterFilterCondition> durationMsLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'durationMs',
        value: value,
      ));
    });
  }

  QueryBuilder<Track, Track, QAfterFilterCondition> durationMsBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'durationMs',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<Track, Track, QAfterFilterCondition> idEqualTo(Id value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<Track, Track, QAfterFilterCondition> idGreaterThan(
    Id value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<Track, Track, QAfterFilterCondition> idLessThan(
    Id value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<Track, Track, QAfterFilterCondition> idBetween(
    Id lower,
    Id upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'id',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<Track, Track, QAfterFilterCondition> inLibraryEqualTo(
      bool value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'inLibrary',
        value: value,
      ));
    });
  }

  QueryBuilder<Track, Track, QAfterFilterCondition> isFavoriteEqualTo(
      bool value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'isFavorite',
        value: value,
      ));
    });
  }

  QueryBuilder<Track, Track, QAfterFilterCondition> isrcIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'isrc',
      ));
    });
  }

  QueryBuilder<Track, Track, QAfterFilterCondition> isrcIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'isrc',
      ));
    });
  }

  QueryBuilder<Track, Track, QAfterFilterCondition> isrcEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'isrc',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Track, Track, QAfterFilterCondition> isrcGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'isrc',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Track, Track, QAfterFilterCondition> isrcLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'isrc',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Track, Track, QAfterFilterCondition> isrcBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'isrc',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Track, Track, QAfterFilterCondition> isrcStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'isrc',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Track, Track, QAfterFilterCondition> isrcEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'isrc',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Track, Track, QAfterFilterCondition> isrcContains(String value,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'isrc',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Track, Track, QAfterFilterCondition> isrcMatches(String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'isrc',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Track, Track, QAfterFilterCondition> isrcIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'isrc',
        value: '',
      ));
    });
  }

  QueryBuilder<Track, Track, QAfterFilterCondition> isrcIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'isrc',
        value: '',
      ));
    });
  }

  QueryBuilder<Track, Track, QAfterFilterCondition> localPathIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'localPath',
      ));
    });
  }

  QueryBuilder<Track, Track, QAfterFilterCondition> localPathIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'localPath',
      ));
    });
  }

  QueryBuilder<Track, Track, QAfterFilterCondition> localPathEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'localPath',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Track, Track, QAfterFilterCondition> localPathGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'localPath',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Track, Track, QAfterFilterCondition> localPathLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'localPath',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Track, Track, QAfterFilterCondition> localPathBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'localPath',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Track, Track, QAfterFilterCondition> localPathStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'localPath',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Track, Track, QAfterFilterCondition> localPathEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'localPath',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Track, Track, QAfterFilterCondition> localPathContains(
      String value,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'localPath',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Track, Track, QAfterFilterCondition> localPathMatches(
      String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'localPath',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Track, Track, QAfterFilterCondition> localPathIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'localPath',
        value: '',
      ));
    });
  }

  QueryBuilder<Track, Track, QAfterFilterCondition> localPathIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'localPath',
        value: '',
      ));
    });
  }

  QueryBuilder<Track, Track, QAfterFilterCondition> lyricsIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'lyrics',
      ));
    });
  }

  QueryBuilder<Track, Track, QAfterFilterCondition> lyricsIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'lyrics',
      ));
    });
  }

  QueryBuilder<Track, Track, QAfterFilterCondition> lyricsEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'lyrics',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Track, Track, QAfterFilterCondition> lyricsGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'lyrics',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Track, Track, QAfterFilterCondition> lyricsLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'lyrics',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Track, Track, QAfterFilterCondition> lyricsBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'lyrics',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Track, Track, QAfterFilterCondition> lyricsStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'lyrics',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Track, Track, QAfterFilterCondition> lyricsEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'lyrics',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Track, Track, QAfterFilterCondition> lyricsContains(String value,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'lyrics',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Track, Track, QAfterFilterCondition> lyricsMatches(
      String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'lyrics',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Track, Track, QAfterFilterCondition> lyricsIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'lyrics',
        value: '',
      ));
    });
  }

  QueryBuilder<Track, Track, QAfterFilterCondition> lyricsIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'lyrics',
        value: '',
      ));
    });
  }

  QueryBuilder<Track, Track, QAfterFilterCondition> previewUrlIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'previewUrl',
      ));
    });
  }

  QueryBuilder<Track, Track, QAfterFilterCondition> previewUrlIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'previewUrl',
      ));
    });
  }

  QueryBuilder<Track, Track, QAfterFilterCondition> previewUrlEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'previewUrl',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Track, Track, QAfterFilterCondition> previewUrlGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'previewUrl',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Track, Track, QAfterFilterCondition> previewUrlLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'previewUrl',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Track, Track, QAfterFilterCondition> previewUrlBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'previewUrl',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Track, Track, QAfterFilterCondition> previewUrlStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'previewUrl',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Track, Track, QAfterFilterCondition> previewUrlEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'previewUrl',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Track, Track, QAfterFilterCondition> previewUrlContains(
      String value,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'previewUrl',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Track, Track, QAfterFilterCondition> previewUrlMatches(
      String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'previewUrl',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Track, Track, QAfterFilterCondition> previewUrlIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'previewUrl',
        value: '',
      ));
    });
  }

  QueryBuilder<Track, Track, QAfterFilterCondition> previewUrlIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'previewUrl',
        value: '',
      ));
    });
  }

  QueryBuilder<Track, Track, QAfterFilterCondition> replayGainIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'replayGain',
      ));
    });
  }

  QueryBuilder<Track, Track, QAfterFilterCondition> replayGainIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'replayGain',
      ));
    });
  }

  QueryBuilder<Track, Track, QAfterFilterCondition> replayGainEqualTo(
    double? value, {
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'replayGain',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<Track, Track, QAfterFilterCondition> replayGainGreaterThan(
    double? value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'replayGain',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<Track, Track, QAfterFilterCondition> replayGainLessThan(
    double? value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'replayGain',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<Track, Track, QAfterFilterCondition> replayGainBetween(
    double? lower,
    double? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'replayGain',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<Track, Track, QAfterFilterCondition> soundcloudIdIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'soundcloudId',
      ));
    });
  }

  QueryBuilder<Track, Track, QAfterFilterCondition> soundcloudIdIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'soundcloudId',
      ));
    });
  }

  QueryBuilder<Track, Track, QAfterFilterCondition> soundcloudIdEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'soundcloudId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Track, Track, QAfterFilterCondition> soundcloudIdGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'soundcloudId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Track, Track, QAfterFilterCondition> soundcloudIdLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'soundcloudId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Track, Track, QAfterFilterCondition> soundcloudIdBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'soundcloudId',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Track, Track, QAfterFilterCondition> soundcloudIdStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'soundcloudId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Track, Track, QAfterFilterCondition> soundcloudIdEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'soundcloudId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Track, Track, QAfterFilterCondition> soundcloudIdContains(
      String value,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'soundcloudId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Track, Track, QAfterFilterCondition> soundcloudIdMatches(
      String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'soundcloudId',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Track, Track, QAfterFilterCondition> soundcloudIdIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'soundcloudId',
        value: '',
      ));
    });
  }

  QueryBuilder<Track, Track, QAfterFilterCondition> soundcloudIdIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'soundcloudId',
        value: '',
      ));
    });
  }

  QueryBuilder<Track, Track, QAfterFilterCondition> spotifyIdIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'spotifyId',
      ));
    });
  }

  QueryBuilder<Track, Track, QAfterFilterCondition> spotifyIdIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'spotifyId',
      ));
    });
  }

  QueryBuilder<Track, Track, QAfterFilterCondition> spotifyIdEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'spotifyId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Track, Track, QAfterFilterCondition> spotifyIdGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'spotifyId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Track, Track, QAfterFilterCondition> spotifyIdLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'spotifyId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Track, Track, QAfterFilterCondition> spotifyIdBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'spotifyId',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Track, Track, QAfterFilterCondition> spotifyIdStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'spotifyId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Track, Track, QAfterFilterCondition> spotifyIdEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'spotifyId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Track, Track, QAfterFilterCondition> spotifyIdContains(
      String value,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'spotifyId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Track, Track, QAfterFilterCondition> spotifyIdMatches(
      String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'spotifyId',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Track, Track, QAfterFilterCondition> spotifyIdIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'spotifyId',
        value: '',
      ));
    });
  }

  QueryBuilder<Track, Track, QAfterFilterCondition> spotifyIdIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'spotifyId',
        value: '',
      ));
    });
  }

  QueryBuilder<Track, Track, QAfterFilterCondition> titleEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'title',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Track, Track, QAfterFilterCondition> titleGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'title',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Track, Track, QAfterFilterCondition> titleLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'title',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Track, Track, QAfterFilterCondition> titleBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'title',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Track, Track, QAfterFilterCondition> titleStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'title',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Track, Track, QAfterFilterCondition> titleEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'title',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Track, Track, QAfterFilterCondition> titleContains(String value,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'title',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Track, Track, QAfterFilterCondition> titleMatches(String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'title',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Track, Track, QAfterFilterCondition> titleIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'title',
        value: '',
      ));
    });
  }

  QueryBuilder<Track, Track, QAfterFilterCondition> titleIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'title',
        value: '',
      ));
    });
  }

  QueryBuilder<Track, Track, QAfterFilterCondition> youtubeIdIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'youtubeId',
      ));
    });
  }

  QueryBuilder<Track, Track, QAfterFilterCondition> youtubeIdIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'youtubeId',
      ));
    });
  }

  QueryBuilder<Track, Track, QAfterFilterCondition> youtubeIdEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'youtubeId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Track, Track, QAfterFilterCondition> youtubeIdGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'youtubeId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Track, Track, QAfterFilterCondition> youtubeIdLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'youtubeId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Track, Track, QAfterFilterCondition> youtubeIdBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'youtubeId',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Track, Track, QAfterFilterCondition> youtubeIdStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'youtubeId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Track, Track, QAfterFilterCondition> youtubeIdEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'youtubeId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Track, Track, QAfterFilterCondition> youtubeIdContains(
      String value,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'youtubeId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Track, Track, QAfterFilterCondition> youtubeIdMatches(
      String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'youtubeId',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Track, Track, QAfterFilterCondition> youtubeIdIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'youtubeId',
        value: '',
      ));
    });
  }

  QueryBuilder<Track, Track, QAfterFilterCondition> youtubeIdIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'youtubeId',
        value: '',
      ));
    });
  }
}

extension TrackQueryObject on QueryBuilder<Track, Track, QFilterCondition> {}

extension TrackQueryLinks on QueryBuilder<Track, Track, QFilterCondition> {}

extension TrackQuerySortBy on QueryBuilder<Track, Track, QSortBy> {
  QueryBuilder<Track, Track, QAfterSortBy> sortByAlbum() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'album', Sort.asc);
    });
  }

  QueryBuilder<Track, Track, QAfterSortBy> sortByAlbumDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'album', Sort.desc);
    });
  }

  QueryBuilder<Track, Track, QAfterSortBy> sortByAlbumArtUrl() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'albumArtUrl', Sort.asc);
    });
  }

  QueryBuilder<Track, Track, QAfterSortBy> sortByAlbumArtUrlDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'albumArtUrl', Sort.desc);
    });
  }

  QueryBuilder<Track, Track, QAfterSortBy> sortByAppleMusicId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'appleMusicId', Sort.asc);
    });
  }

  QueryBuilder<Track, Track, QAfterSortBy> sortByAppleMusicIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'appleMusicId', Sort.desc);
    });
  }

  QueryBuilder<Track, Track, QAfterSortBy> sortByArtist() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'artist', Sort.asc);
    });
  }

  QueryBuilder<Track, Track, QAfterSortBy> sortByArtistDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'artist', Sort.desc);
    });
  }

  QueryBuilder<Track, Track, QAfterSortBy> sortByArtworkUrl() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'artworkUrl', Sort.asc);
    });
  }

  QueryBuilder<Track, Track, QAfterSortBy> sortByArtworkUrlDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'artworkUrl', Sort.desc);
    });
  }

  QueryBuilder<Track, Track, QAfterSortBy> sortByBlurHashPath() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'blurHashPath', Sort.asc);
    });
  }

  QueryBuilder<Track, Track, QAfterSortBy> sortByBlurHashPathDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'blurHashPath', Sort.desc);
    });
  }

  QueryBuilder<Track, Track, QAfterSortBy> sortByDominantColor() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'dominantColor', Sort.asc);
    });
  }

  QueryBuilder<Track, Track, QAfterSortBy> sortByDominantColorDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'dominantColor', Sort.desc);
    });
  }

  QueryBuilder<Track, Track, QAfterSortBy> sortByDurationMs() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'durationMs', Sort.asc);
    });
  }

  QueryBuilder<Track, Track, QAfterSortBy> sortByDurationMsDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'durationMs', Sort.desc);
    });
  }

  QueryBuilder<Track, Track, QAfterSortBy> sortByInLibrary() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'inLibrary', Sort.asc);
    });
  }

  QueryBuilder<Track, Track, QAfterSortBy> sortByInLibraryDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'inLibrary', Sort.desc);
    });
  }

  QueryBuilder<Track, Track, QAfterSortBy> sortByIsFavorite() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isFavorite', Sort.asc);
    });
  }

  QueryBuilder<Track, Track, QAfterSortBy> sortByIsFavoriteDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isFavorite', Sort.desc);
    });
  }

  QueryBuilder<Track, Track, QAfterSortBy> sortByIsrc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isrc', Sort.asc);
    });
  }

  QueryBuilder<Track, Track, QAfterSortBy> sortByIsrcDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isrc', Sort.desc);
    });
  }

  QueryBuilder<Track, Track, QAfterSortBy> sortByLocalPath() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'localPath', Sort.asc);
    });
  }

  QueryBuilder<Track, Track, QAfterSortBy> sortByLocalPathDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'localPath', Sort.desc);
    });
  }

  QueryBuilder<Track, Track, QAfterSortBy> sortByLyrics() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lyrics', Sort.asc);
    });
  }

  QueryBuilder<Track, Track, QAfterSortBy> sortByLyricsDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lyrics', Sort.desc);
    });
  }

  QueryBuilder<Track, Track, QAfterSortBy> sortByPreviewUrl() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'previewUrl', Sort.asc);
    });
  }

  QueryBuilder<Track, Track, QAfterSortBy> sortByPreviewUrlDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'previewUrl', Sort.desc);
    });
  }

  QueryBuilder<Track, Track, QAfterSortBy> sortByReplayGain() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'replayGain', Sort.asc);
    });
  }

  QueryBuilder<Track, Track, QAfterSortBy> sortByReplayGainDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'replayGain', Sort.desc);
    });
  }

  QueryBuilder<Track, Track, QAfterSortBy> sortBySoundcloudId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'soundcloudId', Sort.asc);
    });
  }

  QueryBuilder<Track, Track, QAfterSortBy> sortBySoundcloudIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'soundcloudId', Sort.desc);
    });
  }

  QueryBuilder<Track, Track, QAfterSortBy> sortBySpotifyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'spotifyId', Sort.asc);
    });
  }

  QueryBuilder<Track, Track, QAfterSortBy> sortBySpotifyIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'spotifyId', Sort.desc);
    });
  }

  QueryBuilder<Track, Track, QAfterSortBy> sortByTitle() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'title', Sort.asc);
    });
  }

  QueryBuilder<Track, Track, QAfterSortBy> sortByTitleDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'title', Sort.desc);
    });
  }

  QueryBuilder<Track, Track, QAfterSortBy> sortByYoutubeId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'youtubeId', Sort.asc);
    });
  }

  QueryBuilder<Track, Track, QAfterSortBy> sortByYoutubeIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'youtubeId', Sort.desc);
    });
  }
}

extension TrackQuerySortThenBy on QueryBuilder<Track, Track, QSortThenBy> {
  QueryBuilder<Track, Track, QAfterSortBy> thenByAlbum() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'album', Sort.asc);
    });
  }

  QueryBuilder<Track, Track, QAfterSortBy> thenByAlbumDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'album', Sort.desc);
    });
  }

  QueryBuilder<Track, Track, QAfterSortBy> thenByAlbumArtUrl() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'albumArtUrl', Sort.asc);
    });
  }

  QueryBuilder<Track, Track, QAfterSortBy> thenByAlbumArtUrlDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'albumArtUrl', Sort.desc);
    });
  }

  QueryBuilder<Track, Track, QAfterSortBy> thenByAppleMusicId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'appleMusicId', Sort.asc);
    });
  }

  QueryBuilder<Track, Track, QAfterSortBy> thenByAppleMusicIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'appleMusicId', Sort.desc);
    });
  }

  QueryBuilder<Track, Track, QAfterSortBy> thenByArtist() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'artist', Sort.asc);
    });
  }

  QueryBuilder<Track, Track, QAfterSortBy> thenByArtistDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'artist', Sort.desc);
    });
  }

  QueryBuilder<Track, Track, QAfterSortBy> thenByArtworkUrl() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'artworkUrl', Sort.asc);
    });
  }

  QueryBuilder<Track, Track, QAfterSortBy> thenByArtworkUrlDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'artworkUrl', Sort.desc);
    });
  }

  QueryBuilder<Track, Track, QAfterSortBy> thenByBlurHashPath() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'blurHashPath', Sort.asc);
    });
  }

  QueryBuilder<Track, Track, QAfterSortBy> thenByBlurHashPathDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'blurHashPath', Sort.desc);
    });
  }

  QueryBuilder<Track, Track, QAfterSortBy> thenByDominantColor() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'dominantColor', Sort.asc);
    });
  }

  QueryBuilder<Track, Track, QAfterSortBy> thenByDominantColorDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'dominantColor', Sort.desc);
    });
  }

  QueryBuilder<Track, Track, QAfterSortBy> thenByDurationMs() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'durationMs', Sort.asc);
    });
  }

  QueryBuilder<Track, Track, QAfterSortBy> thenByDurationMsDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'durationMs', Sort.desc);
    });
  }

  QueryBuilder<Track, Track, QAfterSortBy> thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<Track, Track, QAfterSortBy> thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<Track, Track, QAfterSortBy> thenByInLibrary() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'inLibrary', Sort.asc);
    });
  }

  QueryBuilder<Track, Track, QAfterSortBy> thenByInLibraryDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'inLibrary', Sort.desc);
    });
  }

  QueryBuilder<Track, Track, QAfterSortBy> thenByIsFavorite() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isFavorite', Sort.asc);
    });
  }

  QueryBuilder<Track, Track, QAfterSortBy> thenByIsFavoriteDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isFavorite', Sort.desc);
    });
  }

  QueryBuilder<Track, Track, QAfterSortBy> thenByIsrc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isrc', Sort.asc);
    });
  }

  QueryBuilder<Track, Track, QAfterSortBy> thenByIsrcDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isrc', Sort.desc);
    });
  }

  QueryBuilder<Track, Track, QAfterSortBy> thenByLocalPath() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'localPath', Sort.asc);
    });
  }

  QueryBuilder<Track, Track, QAfterSortBy> thenByLocalPathDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'localPath', Sort.desc);
    });
  }

  QueryBuilder<Track, Track, QAfterSortBy> thenByLyrics() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lyrics', Sort.asc);
    });
  }

  QueryBuilder<Track, Track, QAfterSortBy> thenByLyricsDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lyrics', Sort.desc);
    });
  }

  QueryBuilder<Track, Track, QAfterSortBy> thenByPreviewUrl() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'previewUrl', Sort.asc);
    });
  }

  QueryBuilder<Track, Track, QAfterSortBy> thenByPreviewUrlDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'previewUrl', Sort.desc);
    });
  }

  QueryBuilder<Track, Track, QAfterSortBy> thenByReplayGain() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'replayGain', Sort.asc);
    });
  }

  QueryBuilder<Track, Track, QAfterSortBy> thenByReplayGainDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'replayGain', Sort.desc);
    });
  }

  QueryBuilder<Track, Track, QAfterSortBy> thenBySoundcloudId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'soundcloudId', Sort.asc);
    });
  }

  QueryBuilder<Track, Track, QAfterSortBy> thenBySoundcloudIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'soundcloudId', Sort.desc);
    });
  }

  QueryBuilder<Track, Track, QAfterSortBy> thenBySpotifyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'spotifyId', Sort.asc);
    });
  }

  QueryBuilder<Track, Track, QAfterSortBy> thenBySpotifyIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'spotifyId', Sort.desc);
    });
  }

  QueryBuilder<Track, Track, QAfterSortBy> thenByTitle() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'title', Sort.asc);
    });
  }

  QueryBuilder<Track, Track, QAfterSortBy> thenByTitleDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'title', Sort.desc);
    });
  }

  QueryBuilder<Track, Track, QAfterSortBy> thenByYoutubeId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'youtubeId', Sort.asc);
    });
  }

  QueryBuilder<Track, Track, QAfterSortBy> thenByYoutubeIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'youtubeId', Sort.desc);
    });
  }
}

extension TrackQueryWhereDistinct on QueryBuilder<Track, Track, QDistinct> {
  QueryBuilder<Track, Track, QDistinct> distinctByAlbum(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'album', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<Track, Track, QDistinct> distinctByAlbumArtUrl(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'albumArtUrl', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<Track, Track, QDistinct> distinctByAppleMusicId(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'appleMusicId', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<Track, Track, QDistinct> distinctByArtist(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'artist', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<Track, Track, QDistinct> distinctByArtworkUrl(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'artworkUrl', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<Track, Track, QDistinct> distinctByBlurHashPath(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'blurHashPath', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<Track, Track, QDistinct> distinctByDominantColor(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'dominantColor',
          caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<Track, Track, QDistinct> distinctByDurationMs() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'durationMs');
    });
  }

  QueryBuilder<Track, Track, QDistinct> distinctByInLibrary() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'inLibrary');
    });
  }

  QueryBuilder<Track, Track, QDistinct> distinctByIsFavorite() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'isFavorite');
    });
  }

  QueryBuilder<Track, Track, QDistinct> distinctByIsrc(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'isrc', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<Track, Track, QDistinct> distinctByLocalPath(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'localPath', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<Track, Track, QDistinct> distinctByLyrics(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'lyrics', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<Track, Track, QDistinct> distinctByPreviewUrl(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'previewUrl', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<Track, Track, QDistinct> distinctByReplayGain() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'replayGain');
    });
  }

  QueryBuilder<Track, Track, QDistinct> distinctBySoundcloudId(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'soundcloudId', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<Track, Track, QDistinct> distinctBySpotifyId(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'spotifyId', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<Track, Track, QDistinct> distinctByTitle(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'title', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<Track, Track, QDistinct> distinctByYoutubeId(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'youtubeId', caseSensitive: caseSensitive);
    });
  }
}

extension TrackQueryProperty on QueryBuilder<Track, Track, QQueryProperty> {
  QueryBuilder<Track, int, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<Track, String?, QQueryOperations> albumProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'album');
    });
  }

  QueryBuilder<Track, String?, QQueryOperations> albumArtUrlProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'albumArtUrl');
    });
  }

  QueryBuilder<Track, String?, QQueryOperations> appleMusicIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'appleMusicId');
    });
  }

  QueryBuilder<Track, String, QQueryOperations> artistProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'artist');
    });
  }

  QueryBuilder<Track, String?, QQueryOperations> artworkUrlProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'artworkUrl');
    });
  }

  QueryBuilder<Track, String?, QQueryOperations> blurHashPathProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'blurHashPath');
    });
  }

  QueryBuilder<Track, String?, QQueryOperations> dominantColorProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'dominantColor');
    });
  }

  QueryBuilder<Track, int, QQueryOperations> durationMsProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'durationMs');
    });
  }

  QueryBuilder<Track, bool, QQueryOperations> inLibraryProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'inLibrary');
    });
  }

  QueryBuilder<Track, bool, QQueryOperations> isFavoriteProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'isFavorite');
    });
  }

  QueryBuilder<Track, String?, QQueryOperations> isrcProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'isrc');
    });
  }

  QueryBuilder<Track, String?, QQueryOperations> localPathProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'localPath');
    });
  }

  QueryBuilder<Track, String?, QQueryOperations> lyricsProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'lyrics');
    });
  }

  QueryBuilder<Track, String?, QQueryOperations> previewUrlProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'previewUrl');
    });
  }

  QueryBuilder<Track, double?, QQueryOperations> replayGainProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'replayGain');
    });
  }

  QueryBuilder<Track, String?, QQueryOperations> soundcloudIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'soundcloudId');
    });
  }

  QueryBuilder<Track, String?, QQueryOperations> spotifyIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'spotifyId');
    });
  }

  QueryBuilder<Track, String, QQueryOperations> titleProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'title');
    });
  }

  QueryBuilder<Track, String?, QQueryOperations> youtubeIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'youtubeId');
    });
  }
}
