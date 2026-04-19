// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'theme_settings.dart';

// **************************************************************************
// IsarCollectionGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetThemeSettingsCollection on Isar {
  IsarCollection<ThemeSettings> get themeSettings => this.collection();
}

const ThemeSettingsSchema = CollectionSchema(
  name: r'ThemeSettings',
  id: 815540309993789807,
  properties: {
    r'accentColor': PropertySchema(
      id: 0,
      name: r'accentColor',
      type: IsarType.long,
    ),
    r'backgroundColor': PropertySchema(
      id: 1,
      name: r'backgroundColor',
      type: IsarType.long,
    ),
    r'borderColor': PropertySchema(
      id: 2,
      name: r'borderColor',
      type: IsarType.long,
    ),
    r'cardColor': PropertySchema(
      id: 3,
      name: r'cardColor',
      type: IsarType.long,
    ),
    r'surfaceColor': PropertySchema(
      id: 4,
      name: r'surfaceColor',
      type: IsarType.long,
    ),
    r'textPrimaryColor': PropertySchema(
      id: 5,
      name: r'textPrimaryColor',
      type: IsarType.long,
    ),
    r'textSecondaryColor': PropertySchema(
      id: 6,
      name: r'textSecondaryColor',
      type: IsarType.long,
    )
  },
  estimateSize: _themeSettingsEstimateSize,
  serialize: _themeSettingsSerialize,
  deserialize: _themeSettingsDeserialize,
  deserializeProp: _themeSettingsDeserializeProp,
  idName: r'id',
  indexes: {},
  links: {},
  embeddedSchemas: {},
  getId: _themeSettingsGetId,
  getLinks: _themeSettingsGetLinks,
  attach: _themeSettingsAttach,
  version: '3.1.0+1',
);

int _themeSettingsEstimateSize(
  ThemeSettings object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  return bytesCount;
}

void _themeSettingsSerialize(
  ThemeSettings object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeLong(offsets[0], object.accentColor);
  writer.writeLong(offsets[1], object.backgroundColor);
  writer.writeLong(offsets[2], object.borderColor);
  writer.writeLong(offsets[3], object.cardColor);
  writer.writeLong(offsets[4], object.surfaceColor);
  writer.writeLong(offsets[5], object.textPrimaryColor);
  writer.writeLong(offsets[6], object.textSecondaryColor);
}

ThemeSettings _themeSettingsDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = ThemeSettings();
  object.accentColor = reader.readLong(offsets[0]);
  object.backgroundColor = reader.readLong(offsets[1]);
  object.borderColor = reader.readLong(offsets[2]);
  object.cardColor = reader.readLong(offsets[3]);
  object.id = id;
  object.surfaceColor = reader.readLong(offsets[4]);
  object.textPrimaryColor = reader.readLong(offsets[5]);
  object.textSecondaryColor = reader.readLong(offsets[6]);
  return object;
}

P _themeSettingsDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readLong(offset)) as P;
    case 1:
      return (reader.readLong(offset)) as P;
    case 2:
      return (reader.readLong(offset)) as P;
    case 3:
      return (reader.readLong(offset)) as P;
    case 4:
      return (reader.readLong(offset)) as P;
    case 5:
      return (reader.readLong(offset)) as P;
    case 6:
      return (reader.readLong(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

Id _themeSettingsGetId(ThemeSettings object) {
  return object.id;
}

List<IsarLinkBase<dynamic>> _themeSettingsGetLinks(ThemeSettings object) {
  return [];
}

void _themeSettingsAttach(
    IsarCollection<dynamic> col, Id id, ThemeSettings object) {
  object.id = id;
}

extension ThemeSettingsQueryWhereSort
    on QueryBuilder<ThemeSettings, ThemeSettings, QWhere> {
  QueryBuilder<ThemeSettings, ThemeSettings, QAfterWhere> anyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }
}

extension ThemeSettingsQueryWhere
    on QueryBuilder<ThemeSettings, ThemeSettings, QWhereClause> {
  QueryBuilder<ThemeSettings, ThemeSettings, QAfterWhereClause> idEqualTo(
      Id id) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: id,
        upper: id,
      ));
    });
  }

  QueryBuilder<ThemeSettings, ThemeSettings, QAfterWhereClause> idNotEqualTo(
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

  QueryBuilder<ThemeSettings, ThemeSettings, QAfterWhereClause> idGreaterThan(
      Id id,
      {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: id, includeLower: include),
      );
    });
  }

  QueryBuilder<ThemeSettings, ThemeSettings, QAfterWhereClause> idLessThan(
      Id id,
      {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: id, includeUpper: include),
      );
    });
  }

  QueryBuilder<ThemeSettings, ThemeSettings, QAfterWhereClause> idBetween(
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

extension ThemeSettingsQueryFilter
    on QueryBuilder<ThemeSettings, ThemeSettings, QFilterCondition> {
  QueryBuilder<ThemeSettings, ThemeSettings, QAfterFilterCondition>
      accentColorEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'accentColor',
        value: value,
      ));
    });
  }

  QueryBuilder<ThemeSettings, ThemeSettings, QAfterFilterCondition>
      accentColorGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'accentColor',
        value: value,
      ));
    });
  }

  QueryBuilder<ThemeSettings, ThemeSettings, QAfterFilterCondition>
      accentColorLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'accentColor',
        value: value,
      ));
    });
  }

  QueryBuilder<ThemeSettings, ThemeSettings, QAfterFilterCondition>
      accentColorBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'accentColor',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<ThemeSettings, ThemeSettings, QAfterFilterCondition>
      backgroundColorEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'backgroundColor',
        value: value,
      ));
    });
  }

  QueryBuilder<ThemeSettings, ThemeSettings, QAfterFilterCondition>
      backgroundColorGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'backgroundColor',
        value: value,
      ));
    });
  }

  QueryBuilder<ThemeSettings, ThemeSettings, QAfterFilterCondition>
      backgroundColorLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'backgroundColor',
        value: value,
      ));
    });
  }

  QueryBuilder<ThemeSettings, ThemeSettings, QAfterFilterCondition>
      backgroundColorBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'backgroundColor',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<ThemeSettings, ThemeSettings, QAfterFilterCondition>
      borderColorEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'borderColor',
        value: value,
      ));
    });
  }

  QueryBuilder<ThemeSettings, ThemeSettings, QAfterFilterCondition>
      borderColorGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'borderColor',
        value: value,
      ));
    });
  }

  QueryBuilder<ThemeSettings, ThemeSettings, QAfterFilterCondition>
      borderColorLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'borderColor',
        value: value,
      ));
    });
  }

  QueryBuilder<ThemeSettings, ThemeSettings, QAfterFilterCondition>
      borderColorBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'borderColor',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<ThemeSettings, ThemeSettings, QAfterFilterCondition>
      cardColorEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'cardColor',
        value: value,
      ));
    });
  }

  QueryBuilder<ThemeSettings, ThemeSettings, QAfterFilterCondition>
      cardColorGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'cardColor',
        value: value,
      ));
    });
  }

  QueryBuilder<ThemeSettings, ThemeSettings, QAfterFilterCondition>
      cardColorLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'cardColor',
        value: value,
      ));
    });
  }

  QueryBuilder<ThemeSettings, ThemeSettings, QAfterFilterCondition>
      cardColorBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'cardColor',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<ThemeSettings, ThemeSettings, QAfterFilterCondition> idEqualTo(
      Id value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<ThemeSettings, ThemeSettings, QAfterFilterCondition>
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

  QueryBuilder<ThemeSettings, ThemeSettings, QAfterFilterCondition> idLessThan(
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

  QueryBuilder<ThemeSettings, ThemeSettings, QAfterFilterCondition> idBetween(
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

  QueryBuilder<ThemeSettings, ThemeSettings, QAfterFilterCondition>
      surfaceColorEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'surfaceColor',
        value: value,
      ));
    });
  }

  QueryBuilder<ThemeSettings, ThemeSettings, QAfterFilterCondition>
      surfaceColorGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'surfaceColor',
        value: value,
      ));
    });
  }

  QueryBuilder<ThemeSettings, ThemeSettings, QAfterFilterCondition>
      surfaceColorLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'surfaceColor',
        value: value,
      ));
    });
  }

  QueryBuilder<ThemeSettings, ThemeSettings, QAfterFilterCondition>
      surfaceColorBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'surfaceColor',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<ThemeSettings, ThemeSettings, QAfterFilterCondition>
      textPrimaryColorEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'textPrimaryColor',
        value: value,
      ));
    });
  }

  QueryBuilder<ThemeSettings, ThemeSettings, QAfterFilterCondition>
      textPrimaryColorGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'textPrimaryColor',
        value: value,
      ));
    });
  }

  QueryBuilder<ThemeSettings, ThemeSettings, QAfterFilterCondition>
      textPrimaryColorLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'textPrimaryColor',
        value: value,
      ));
    });
  }

  QueryBuilder<ThemeSettings, ThemeSettings, QAfterFilterCondition>
      textPrimaryColorBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'textPrimaryColor',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<ThemeSettings, ThemeSettings, QAfterFilterCondition>
      textSecondaryColorEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'textSecondaryColor',
        value: value,
      ));
    });
  }

  QueryBuilder<ThemeSettings, ThemeSettings, QAfterFilterCondition>
      textSecondaryColorGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'textSecondaryColor',
        value: value,
      ));
    });
  }

  QueryBuilder<ThemeSettings, ThemeSettings, QAfterFilterCondition>
      textSecondaryColorLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'textSecondaryColor',
        value: value,
      ));
    });
  }

  QueryBuilder<ThemeSettings, ThemeSettings, QAfterFilterCondition>
      textSecondaryColorBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'textSecondaryColor',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }
}

extension ThemeSettingsQueryObject
    on QueryBuilder<ThemeSettings, ThemeSettings, QFilterCondition> {}

extension ThemeSettingsQueryLinks
    on QueryBuilder<ThemeSettings, ThemeSettings, QFilterCondition> {}

extension ThemeSettingsQuerySortBy
    on QueryBuilder<ThemeSettings, ThemeSettings, QSortBy> {
  QueryBuilder<ThemeSettings, ThemeSettings, QAfterSortBy> sortByAccentColor() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'accentColor', Sort.asc);
    });
  }

  QueryBuilder<ThemeSettings, ThemeSettings, QAfterSortBy>
      sortByAccentColorDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'accentColor', Sort.desc);
    });
  }

  QueryBuilder<ThemeSettings, ThemeSettings, QAfterSortBy>
      sortByBackgroundColor() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'backgroundColor', Sort.asc);
    });
  }

  QueryBuilder<ThemeSettings, ThemeSettings, QAfterSortBy>
      sortByBackgroundColorDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'backgroundColor', Sort.desc);
    });
  }

  QueryBuilder<ThemeSettings, ThemeSettings, QAfterSortBy> sortByBorderColor() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'borderColor', Sort.asc);
    });
  }

  QueryBuilder<ThemeSettings, ThemeSettings, QAfterSortBy>
      sortByBorderColorDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'borderColor', Sort.desc);
    });
  }

  QueryBuilder<ThemeSettings, ThemeSettings, QAfterSortBy> sortByCardColor() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'cardColor', Sort.asc);
    });
  }

  QueryBuilder<ThemeSettings, ThemeSettings, QAfterSortBy>
      sortByCardColorDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'cardColor', Sort.desc);
    });
  }

  QueryBuilder<ThemeSettings, ThemeSettings, QAfterSortBy>
      sortBySurfaceColor() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'surfaceColor', Sort.asc);
    });
  }

  QueryBuilder<ThemeSettings, ThemeSettings, QAfterSortBy>
      sortBySurfaceColorDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'surfaceColor', Sort.desc);
    });
  }

  QueryBuilder<ThemeSettings, ThemeSettings, QAfterSortBy>
      sortByTextPrimaryColor() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'textPrimaryColor', Sort.asc);
    });
  }

  QueryBuilder<ThemeSettings, ThemeSettings, QAfterSortBy>
      sortByTextPrimaryColorDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'textPrimaryColor', Sort.desc);
    });
  }

  QueryBuilder<ThemeSettings, ThemeSettings, QAfterSortBy>
      sortByTextSecondaryColor() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'textSecondaryColor', Sort.asc);
    });
  }

  QueryBuilder<ThemeSettings, ThemeSettings, QAfterSortBy>
      sortByTextSecondaryColorDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'textSecondaryColor', Sort.desc);
    });
  }
}

extension ThemeSettingsQuerySortThenBy
    on QueryBuilder<ThemeSettings, ThemeSettings, QSortThenBy> {
  QueryBuilder<ThemeSettings, ThemeSettings, QAfterSortBy> thenByAccentColor() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'accentColor', Sort.asc);
    });
  }

  QueryBuilder<ThemeSettings, ThemeSettings, QAfterSortBy>
      thenByAccentColorDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'accentColor', Sort.desc);
    });
  }

  QueryBuilder<ThemeSettings, ThemeSettings, QAfterSortBy>
      thenByBackgroundColor() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'backgroundColor', Sort.asc);
    });
  }

  QueryBuilder<ThemeSettings, ThemeSettings, QAfterSortBy>
      thenByBackgroundColorDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'backgroundColor', Sort.desc);
    });
  }

  QueryBuilder<ThemeSettings, ThemeSettings, QAfterSortBy> thenByBorderColor() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'borderColor', Sort.asc);
    });
  }

  QueryBuilder<ThemeSettings, ThemeSettings, QAfterSortBy>
      thenByBorderColorDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'borderColor', Sort.desc);
    });
  }

  QueryBuilder<ThemeSettings, ThemeSettings, QAfterSortBy> thenByCardColor() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'cardColor', Sort.asc);
    });
  }

  QueryBuilder<ThemeSettings, ThemeSettings, QAfterSortBy>
      thenByCardColorDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'cardColor', Sort.desc);
    });
  }

  QueryBuilder<ThemeSettings, ThemeSettings, QAfterSortBy> thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<ThemeSettings, ThemeSettings, QAfterSortBy> thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<ThemeSettings, ThemeSettings, QAfterSortBy>
      thenBySurfaceColor() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'surfaceColor', Sort.asc);
    });
  }

  QueryBuilder<ThemeSettings, ThemeSettings, QAfterSortBy>
      thenBySurfaceColorDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'surfaceColor', Sort.desc);
    });
  }

  QueryBuilder<ThemeSettings, ThemeSettings, QAfterSortBy>
      thenByTextPrimaryColor() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'textPrimaryColor', Sort.asc);
    });
  }

  QueryBuilder<ThemeSettings, ThemeSettings, QAfterSortBy>
      thenByTextPrimaryColorDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'textPrimaryColor', Sort.desc);
    });
  }

  QueryBuilder<ThemeSettings, ThemeSettings, QAfterSortBy>
      thenByTextSecondaryColor() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'textSecondaryColor', Sort.asc);
    });
  }

  QueryBuilder<ThemeSettings, ThemeSettings, QAfterSortBy>
      thenByTextSecondaryColorDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'textSecondaryColor', Sort.desc);
    });
  }
}

extension ThemeSettingsQueryWhereDistinct
    on QueryBuilder<ThemeSettings, ThemeSettings, QDistinct> {
  QueryBuilder<ThemeSettings, ThemeSettings, QDistinct>
      distinctByAccentColor() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'accentColor');
    });
  }

  QueryBuilder<ThemeSettings, ThemeSettings, QDistinct>
      distinctByBackgroundColor() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'backgroundColor');
    });
  }

  QueryBuilder<ThemeSettings, ThemeSettings, QDistinct>
      distinctByBorderColor() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'borderColor');
    });
  }

  QueryBuilder<ThemeSettings, ThemeSettings, QDistinct> distinctByCardColor() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'cardColor');
    });
  }

  QueryBuilder<ThemeSettings, ThemeSettings, QDistinct>
      distinctBySurfaceColor() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'surfaceColor');
    });
  }

  QueryBuilder<ThemeSettings, ThemeSettings, QDistinct>
      distinctByTextPrimaryColor() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'textPrimaryColor');
    });
  }

  QueryBuilder<ThemeSettings, ThemeSettings, QDistinct>
      distinctByTextSecondaryColor() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'textSecondaryColor');
    });
  }
}

extension ThemeSettingsQueryProperty
    on QueryBuilder<ThemeSettings, ThemeSettings, QQueryProperty> {
  QueryBuilder<ThemeSettings, int, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<ThemeSettings, int, QQueryOperations> accentColorProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'accentColor');
    });
  }

  QueryBuilder<ThemeSettings, int, QQueryOperations> backgroundColorProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'backgroundColor');
    });
  }

  QueryBuilder<ThemeSettings, int, QQueryOperations> borderColorProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'borderColor');
    });
  }

  QueryBuilder<ThemeSettings, int, QQueryOperations> cardColorProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'cardColor');
    });
  }

  QueryBuilder<ThemeSettings, int, QQueryOperations> surfaceColorProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'surfaceColor');
    });
  }

  QueryBuilder<ThemeSettings, int, QQueryOperations>
      textPrimaryColorProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'textPrimaryColor');
    });
  }

  QueryBuilder<ThemeSettings, int, QQueryOperations>
      textSecondaryColorProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'textSecondaryColor');
    });
  }
}
