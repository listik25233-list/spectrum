import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:spectrum/core/db/isar_service.dart';
import 'package:spectrum/core/db/schemas/auth_token_schema.dart';
import 'package:spectrum/features/auth/spotify_auth_service.dart';

final authServiceProvider = Provider((ref) => AuthService());

class AuthService {
  Future<void> loginWithSpotify() async {
    await SpotifyAuthService().authenticate();
  }

  Future<void> logout() async {
    final isar = IsarService.instance;
    await isar.writeTxn(() async {
      await isar.authTokens.clear();
    });
  }
}
