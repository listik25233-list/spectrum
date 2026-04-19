import 'package:isar/isar.dart';

part 'auth_token_schema.g.dart';

@Collection()
class AuthToken {
  Id id = Isar.autoIncrement;

  @Index(unique: true)
  late String service;

  late String accessToken;
  String? refreshToken;
  late DateTime expiresAt;

  bool get isExpired => DateTime.now().isAfter(expiresAt);
  bool get needsRefresh =>
      DateTime.now().isAfter(expiresAt.subtract(const Duration(minutes: 5)));
}
