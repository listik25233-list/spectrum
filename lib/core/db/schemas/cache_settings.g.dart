// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'cache_settings.dart';

// **************************************************************************
// IsarCollectionGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetCacheSettingsCollection on Isar {
  IsarCollection<CacheSettings> get cacheSettings => this.collection();
}

const CacheSettingsSchema = CollectionSchema(
  name: r'CacheSettings',
  id: 6268064811627463717,
  properties: {
    r'lastCleanup': PropertySchema(
      id: 0,
      name: r'lastCleanup',
      type: IsarType.dateTime,
    ),
    r'maxCacheSizeGb': PropertySchema(
      id: 1,
      name: r'maxCacheSizeGb',
      type: IsarType.double,
    ),
    r'notificationsEnabled': PropertySchema(
      id: 2,
      name: r'notificationsEnabled',
      type: IsarType.bool,
    )
  },
  estimateSize: _cacheSettingsEstimateSize,
  serialize: _cacheSettingsSerialize,
  deserialize: _cacheSettingsDeserialize,
  deserializeProp: _cacheSettingsDeserializeProp,
  idName: r'id',
  indexes: {},
  links: {},
  embeddedSchemas: {},
  getId: _cacheSettingsGetId,
  getLinks: _cacheSettingsGetLinks,
  attach: _cacheSettingsAttach,
  version: '3.1.0+1',
);

int _cacheSettingsEstimateSize(
  CacheSettings object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  return bytesCount;
}

void _cacheSettingsSerialize(
  CacheSettings object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeDateTime(offsets[0], object.lastCleanup);
  writer.writeDouble(offsets[1], object.maxCacheSizeGb);
  writer.writeBool(offsets[2], object.notificationsEnabled);
}

CacheSettings _cacheSettingsDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = CacheSettings();
  object.id = id;
  object.lastCleanup = reader.readDateTimeOrNull(offsets[0]);
  object.maxCacheSizeGb = reader.readDouble(offsets[1]);
  object.notificationsEnabled = reader.readBool(offsets[2]);
  return object;
}

P _cacheSettingsDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readDateTimeOrNull(offset)) as P;
    case 1:
      return (reader.readDouble(offset)) as P;
    case 2:
      return (reader.readBool(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

Id _cacheSettingsGetId(CacheSettings object) {
  return object.id;
}

List<IsarLinkBase<dynamic>> _cacheSettingsGetLinks(CacheSettings object) {
  return [];
}

void _cacheSettingsAttach(
    IsarCollection<dynamic> col, Id id, CacheSettings object) {
  object.id = id;
}

extension CacheSettingsQueryWhereSort
    on QueryBuilder<CacheSettings, CacheSettings, QWhere> {
  QueryBuilder<CacheSettings, CacheSettings, QAfterWhere> anyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }
}

extension CacheSettingsQueryWhere
    on QueryBuilder<CacheSettings, CacheSettings, QWhereClause> {
  QueryBuilder<CacheSettings, CacheSettings, QAfterWhereClause> idEqualTo(
      Id id) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: id,
        upper: id,
      ));
    });
  }

  QueryBuilder<CacheSettings, CacheSettings, QAfterWhereClause> idNotEqualTo(
      Id id) {
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

  QueryBuilder<CacheSettings, CacheSettings, QAfterWhereClause> idGreaterThan(
      Id id,
      {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: id, includeLower: include),
      );
    });
  }

  QueryBuilder<CacheSettings, CacheSettings, QAfterWhereClause> idLessThan(
      Id id,
      {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: id, includeUpper: include),
      );
    });
  }

  QueryBuilder<CacheSettings, CacheSettings, QAfterWhereClause> idBetween(
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
}

extension CacheSettingsQueryFilter
    on QueryBuilder<CacheSettings, CacheSettings, QFilterCondition> {
  QueryBuilder<CacheSettings, CacheSettings, QAfterFilterCondition> idEqualTo(
      Id value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<CacheSettings, CacheSettings, QAfterFilterCondition>
      idGreaterThan(
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

  QueryBuilder<CacheSettings, CacheSettings, QAfterFilterCondition> idLessThan(
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

  QueryBuilder<CacheSettings, CacheSettings, QAfterFilterCondition> idBetween(
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

  QueryBuilder<CacheSettings, CacheSettings, QAfterFilterCondition>
      lastCleanupIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'lastCleanup',
      ));
    });
  }

  QueryBuilder<CacheSettings, CacheSettings, QAfterFilterCondition>
      lastCleanupIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'lastCleanup',
      ));
    });
  }

  QueryBuilder<CacheSettings, CacheSettings, QAfterFilterCondition>
      lastCleanupEqualTo(DateTime? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'lastCleanup',
        value: value,
      ));
    });
  }

  QueryBuilder<CacheSettings, CacheSettings, QAfterFilterCondition>
      lastCleanupGreaterThan(
    DateTime? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'lastCleanup',
        value: value,
      ));
    });
  }

  QueryBuilder<CacheSettings, CacheSettings, QAfterFilterCondition>
      lastCleanupLessThan(
    DateTime? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'lastCleanup',
        value: value,
      ));
    });
  }

  QueryBuilder<CacheSettings, CacheSettings, QAfterFilterCondition>
      lastCleanupBetween(
    DateTime? lower,
    DateTime? upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'lastCleanup',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<CacheSettings, CacheSettings, QAfterFilterCondition>
      maxCacheSizeGbEqualTo(
    double value, {
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'maxCacheSizeGb',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<CacheSettings, CacheSettings, QAfterFilterCondition>
      maxCacheSizeGbGreaterThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'maxCacheSizeGb',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<CacheSettings, CacheSettings, QAfterFilterCondition>
      maxCacheSizeGbLessThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'maxCacheSizeGb',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<CacheSettings, CacheSettings, QAfterFilterCondition>
      maxCacheSizeGbBetween(
    double lower,
    double upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'maxCacheSizeGb',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<CacheSettings, CacheSettings, QAfterFilterCondition>
      notificationsEnabledEqualTo(bool value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'notificationsEnabled',
        value: value,
      ));
    });
  }
}

extension CacheSettingsQueryObject
    on QueryBuilder<CacheSettings, CacheSettings, QFilterCondition> {}

extension CacheSettingsQueryLinks
    on QueryBuilder<CacheSettings, CacheSettings, QFilterCondition> {}

extension CacheSettingsQuerySortBy
    on QueryBuilder<CacheSettings, CacheSettings, QSortBy> {
  QueryBuilder<CacheSettings, CacheSettings, QAfterSortBy> sortByLastCleanup() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastCleanup', Sort.asc);
    });
  }

  QueryBuilder<CacheSettings, CacheSettings, QAfterSortBy>
      sortByLastCleanupDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastCleanup', Sort.desc);
    });
  }

  QueryBuilder<CacheSettings, CacheSettings, QAfterSortBy>
      sortByMaxCacheSizeGb() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'maxCacheSizeGb', Sort.asc);
    });
  }

  QueryBuilder<CacheSettings, CacheSettings, QAfterSortBy>
      sortByMaxCacheSizeGbDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'maxCacheSizeGb', Sort.desc);
    });
  }

  QueryBuilder<CacheSettings, CacheSettings, QAfterSortBy>
      sortByNotificationsEnabled() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'notificationsEnabled', Sort.asc);
    });
  }

  QueryBuilder<CacheSettings, CacheSettings, QAfterSortBy>
      sortByNotificationsEnabledDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'notificationsEnabled', Sort.desc);
    });
  }
}

extension CacheSettingsQuerySortThenBy
    on QueryBuilder<CacheSettings, CacheSettings, QSortThenBy> {
  QueryBuilder<CacheSettings, CacheSettings, QAfterSortBy> thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<CacheSettings, CacheSettings, QAfterSortBy> thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<CacheSettings, CacheSettings, QAfterSortBy> thenByLastCleanup() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastCleanup', Sort.asc);
    });
  }

  QueryBuilder<CacheSettings, CacheSettings, QAfterSortBy>
      thenByLastCleanupDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastCleanup', Sort.desc);
    });
  }

  QueryBuilder<CacheSettings, CacheSettings, QAfterSortBy>
      thenByMaxCacheSizeGb() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'maxCacheSizeGb', Sort.asc);
    });
  }

  QueryBuilder<CacheSettings, CacheSettings, QAfterSortBy>
      thenByMaxCacheSizeGbDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'maxCacheSizeGb', Sort.desc);
    });
  }

  QueryBuilder<CacheSettings, CacheSettings, QAfterSortBy>
      thenByNotificationsEnabled() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'notificationsEnabled', Sort.asc);
    });
  }

  QueryBuilder<CacheSettings, CacheSettings, QAfterSortBy>
      thenByNotificationsEnabledDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'notificationsEnabled', Sort.desc);
    });
  }
}

extension CacheSettingsQueryWhereDistinct
    on QueryBuilder<CacheSettings, CacheSettings, QDistinct> {
  QueryBuilder<CacheSettings, CacheSettings, QDistinct>
      distinctByLastCleanup() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'lastCleanup');
    });
  }

  QueryBuilder<CacheSettings, CacheSettings, QDistinct>
      distinctByMaxCacheSizeGb() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'maxCacheSizeGb');
    });
  }

  QueryBuilder<CacheSettings, CacheSettings, QDistinct>
      distinctByNotificationsEnabled() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'notificationsEnabled');
    });
  }
}

extension CacheSettingsQueryProperty
    on QueryBuilder<CacheSettings, CacheSettings, QQueryProperty> {
  QueryBuilder<CacheSettings, int, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<CacheSettings, DateTime?, QQueryOperations>
      lastCleanupProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'lastCleanup');
    });
  }

  QueryBuilder<CacheSettings, double, QQueryOperations>
      maxCacheSizeGbProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'maxCacheSizeGb');
    });
  }

  QueryBuilder<CacheSettings, bool, QQueryOperations>
      notificationsEnabledProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'notificationsEnabled');
    });
  }
}
