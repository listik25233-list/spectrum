import 'package:flutter_web_auth_2/flutter_web_auth_2.dart';
import 'package:isar/isar.dart';
import 'package:spectrum/core/db/isar_service.dart';
import 'package:spectrum/core/db/schemas/auth_token_schema.dart';
import 'package:spectrum/core/network/spotify_api.dart';
import 'package:dio/dio.dart';
import 'dart:math';
import 'dart:convert';
import 'package:crypto/crypto.dart';

/// Handles Spotify OAuth 2.0 PKCE flow.
/// After successful auth, saves the token to Isar.
class SpotifyAuthService {
  static const _tokenUrl = 'https://accounts.spotify.com/api/token';
  static const _authUrl = 'https://accounts.spotify.com/authorize';

  Future<void> authenticate() async {
    try {
      print('[SpotifyAuthService] Starting authentication flow...');
      final codeVerifier = _generateCodeVerifier();
      final codeChallenge = _generateCodeChallenge(codeVerifier);
      final state = _generateState();

      final authUri = Uri.parse(_authUrl).replace(queryParameters: {
        'client_id': SpotifyApi.clientId,
        'response_type': 'code',
        'redirect_uri': SpotifyApi.redirectUri,
        'scope': SpotifyApi.scopes.join(' '),
        'code_challenge_method': 'S256',
        'code_challenge': codeChallenge,
        'state': state,
      });

      print('[SpotifyAuthService] Authorizing via: $authUri');
      final result = await FlutterWebAuth2.authenticate(
        url: authUri.toString(),
        callbackUrlScheme: 'http://127.0.0.1:8888',
      );

      print('[SpotifyAuthService] Received callback result: $result');
      final code = Uri.parse(result).queryParameters['code'];
      if (code == null) throw Exception('Authorization code not received');

      print('[SpotifyAuthService] Exchanging code for token...');
      final response = await Dio().post(
        _tokenUrl,
        data: {
          'grant_type': 'authorization_code',
          'code': code,
          'redirect_uri': SpotifyApi.redirectUri,
          'client_id': SpotifyApi.clientId,
          'code_verifier': codeVerifier,
        },
        options: Options(contentType: Headers.formUrlEncodedContentType),
      );

      print('[SpotifyAuthService] Token response received.');
      final isar = IsarService.instance;
      await isar.writeTxn(() async {
        final existingToken =
            await isar.authTokens.filter().serviceEqualTo('spotify').findFirst();

        final token = AuthToken()
          ..id = existingToken?.id ?? Isar.autoIncrement
          ..service = 'spotify'
          ..accessToken = response.data['access_token']
          ..refreshToken = response.data['refresh_token']
          ..expiresAt = DateTime.now()
              .add(Duration(seconds: response.data['expires_in']));

        await isar.authTokens.put(token);
      });
      print('[SpotifyAuthService] Auth successful! Token saved to Isar.');
    } catch (e, stack) {
      print('[SpotifyAuthService] ERROR during auth: $e');
      print(stack);
      rethrow;
    }
  }

  // PKCE helpers
  String _generateCodeVerifier() {
    final random = Random.secure();
    final values = List<int>.generate(64, (_) => random.nextInt(256));
    return base64UrlEncode(values).replaceAll('=', '');
  }

  String _generateCodeChallenge(String verifier) {
    final bytes = utf8.encode(verifier);
    final digest = sha256.convert(bytes);
    return base64UrlEncode(digest.bytes).replaceAll('=', '');
  }

  String _generateState() {
    final random = Random.secure();
    final values = List<int>.generate(16, (_) => random.nextInt(256));
    return base64UrlEncode(values).replaceAll('=', '');
  }
}
