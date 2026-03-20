import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:media_kit/media_kit.dart';
import 'package:spectrum/app.dart';
import 'package:spectrum/core/db/isar_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  MediaKit.ensureInitialized();
  await IsarService.init();
  runApp(const ProviderScope(child: SpectrumApp()));
}
