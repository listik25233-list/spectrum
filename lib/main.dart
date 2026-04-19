import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:spectrum/app.dart';
import 'package:spectrum/core/db/isar_service.dart';
import 'package:spectrum/features/player/spectrum_audio_handler.dart';
import 'package:spectrum/features/player/audio_player_service.dart';
import 'package:spectrum/features/settings/storage_service.dart';
import 'package:spectrum/core/network/notification_service.dart';
import 'package:spectrum/core/db/schemas/cache_settings.dart';
import 'package:audio_service/audio_service.dart';
import 'package:media_kit/media_kit.dart' hide Track;
import 'package:window_manager/window_manager.dart';
import 'package:spectrum/src/rust/frb_generated.dart';
import 'package:spectrum/src/rust/api/simple.dart';
import 'package:flutter_soloud/flutter_soloud.dart';

/// App-wide logging utility
void logToFile(String message) async {
  if (kDebugMode) {
    debugPrint(message);
    try {
      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/spectrum_debug.log');
      await file.writeAsString('${DateTime.now()}: $message\n', mode: FileMode.append);
    } catch (_) {}
  }
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Rust Core
  await RustLib.init();

  // Initialize Notifications
  try {
    await NotificationService().init();
  } catch (e) {
    debugPrint('[Main] Notification init failed: $e');
  }

  if (Platform.isLinux || Platform.isWindows || Platform.isMacOS) {
    await windowManager.ensureInitialized();
    
    // For Linux (Hyprland), we provide a hints but allow the WM to tile
    final windowOptions = WindowOptions(
      size: const Size(1000, 700),
      minimumSize: const Size(640, 480),
      center: !Platform.isLinux,
      backgroundColor: Colors.transparent,
      titleBarStyle: TitleBarStyle.hidden,
      title: 'Spectrum',
    );
    
    unawaited(windowManager.waitUntilReadyToShow(windowOptions, () async {
      await windowManager.show();
      await windowManager.focus();
      
      if (Platform.isLinux) {
        // Force unmaximize/unfullscreen to avoid Hyprland tiling issues
        await windowManager.unmaximize();
        await windowManager.setFullScreen(false);
      }
    }));
  }

  logToFile('APPLICATION STARTING...');
  runApp(const InitializationWrapper());
}

class InitializationWrapper extends StatefulWidget {
  const InitializationWrapper({super.key});

  @override
  State<InitializationWrapper> createState() => _InitializationWrapperState();
}

class _InitializationWrapperState extends State<InitializationWrapper> {
  bool _initialized = false;
  String? _error;
  SpectrumAudioHandler? _handler;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    try {
      logToFile('Initialization step: MediaKit');
      MediaKit.ensureInitialized();

      logToFile('Initialization step: AudioService');
      final player = Player(
        configuration: const PlayerConfiguration(
          title: 'Spectrum',
        ),
      );
      _handler = await AudioService.init(
        builder: () => SpectrumAudioHandler(player),
        config: const AudioServiceConfig(
          androidNotificationChannelId: 'com.spectrum.music.player',
          androidNotificationChannelName: 'Spectrum Music',
          androidNotificationOngoing: true,
          androidStopForegroundOnPause: true,
          androidNotificationIcon: 'mipmap/ic_launcher',
        ),
      );

      logToFile('Initialization step: Isar');
      await IsarService.init();

      logToFile('Initialization step: SoLoud (Visualization)');
      try {
        await SoLoud.instance.init();
      } catch (e) {
        logToFile('SoLoud init failed: $e');
      }

      logToFile('Initialization step: Storage Cleanup');
      unawaited(StorageService().autoCleanupCache());

      logToFile('Initialization complete.');
      if (mounted) {
        setState(() {
          _initialized = true;
        });
      }
    } catch (e, stack) {
      logToFile('CRITICAL ERROR: $e');
      logToFile('STACK: $stack');
      if (mounted) {
        setState(() {
          _error = e.toString();
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null) {
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: ThemeData.dark(),
        home: Scaffold(
          backgroundColor: const Color(0xFF0A0A0F),
          body: Center(
            child: Padding(
              padding: const EdgeInsets.all(32.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, color: Colors.redAccent, size: 64),
                  const SizedBox(height: 24),
                  const Text('Startup Failure', style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  Text(_error!, style: const TextStyle(color: Colors.white70), textAlign: TextAlign.center),
                  const SizedBox(height: 32),
                  const Text(
                    'Try restarting the application or check internet connection.',
                    style: TextStyle(color: Colors.white38, fontSize: 12), textAlign: TextAlign.center),
                ],
              ),
            ),
          ),
        ),
      );
    }

    if (!_initialized) {
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: ThemeData.dark(),
        home: const Scaffold(
          backgroundColor: Color(0xFF0A0A0F),
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(color: Color(0xFF7C3AED)),
                SizedBox(height: 24),
                Text('Loading Spectrum...', style: TextStyle(color: Colors.white, fontSize: 16)),
              ],
            ),
          ),
        ),
      );
    }

    return ProviderScope(
      overrides: [
        if (_handler != null)
          audioHandlerProvider.overrideWithValue(_handler!),
      ],
      child: const SpectrumApp(),
    );
  }
}
