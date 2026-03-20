import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import 'package:isar/isar.dart';
import 'package:spectrum/core/db/isar_service.dart';
import 'package:spectrum/core/db/schemas/auth_token_schema.dart';
import 'package:logger/logger.dart';

/// Returns list of connected service names, e.g. ['spotify', 'youtube']
final authProvider = StreamProvider<List<String>>((ref) {
  final isar = IsarService.instance;
  return isar.authTokens.where().watch(fireImmediately: true).map(
        (tokens) => tokens
            .where((t) => !t.isExpired || t.refreshToken != null)
            .map((t) => t.service)
            .toList(),
      );
});

/// Watch a specific service's auth token
final serviceTokenProvider =
    FutureProvider.family<AuthToken?, String>((ref, service) async {
  final isar = IsarService.instance;
  return isar.authTokens.where().serviceEqualTo(service).findFirst();
});
