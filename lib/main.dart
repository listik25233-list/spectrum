import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:media_kit/media_kit.dart';
import 'package:path_provider/path_provider.dart';
import 'package:spectrum/app.dart';
import 'package:spectrum/core/db/isar_service.dart';

// Simple file logger to help debug Windows/Wine issues
void logToFile(String message) async {
  try {
    print(message);
    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/spectrum_debug.log');
    await file.writeAsString('${DateTime.now()}: $message\n', mode: FileMode.append);
  } catch (_) {}
}

void main() {
  // 1. Initialize binding immediately
  WidgetsFlutterBinding.ensureInitialized();
  
  logToFile("APPLICATION STARTING...");

  // 2. Show the window IMMEDIATELY
  runApp(const ProviderScope(child: InitializationWrapper()));
}

class InitializationWrapper extends StatefulWidget {
  const InitializationWrapper({super.key});

  @override
  State<InitializationWrapper> createState() => _InitializationWrapperState();
}

class _InitializationWrapperState extends State<InitializationWrapper> {
  bool _initialized = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    try {
      logToFile("Initialzation step: MediaKit");
      MediaKit.ensureInitialized();
      
      logToFile("Initialzation step: Isar");
      await IsarService.init();
      
      logToFile("Initialization complete.");
      setState(() {
        _initialized = true;
      });
    } catch (e, stack) {
      logToFile("CRITICAL ERROR: $e");
      logToFile("STACK: $stack");
      setState(() {
        _error = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null) {
      return MaterialApp(
        debugShowCheckedModeBanner: false,
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
                  const Text("Startup Failure", style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  Text(_error!, style: const TextStyle(color: Colors.white70), textAlign: TextAlign.center),
                  const SizedBox(height: 32),
                  const Text("Check if isar.dll and mpv-1.dll are present.\nAlso ensure VC++ Redistributable is installed.", 
                    style: TextStyle(color: Colors.white38, fontSize: 12), textAlign: TextAlign.center),
                ],
              ),
            ),
          ),
        ),
      );
    }

    if (!_initialized) {
      return const MaterialApp(
        debugShowCheckedModeBanner: false,
        home: Scaffold(
          backgroundColor: const Color(0xFF0A0A0F),
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(color: Color(0xFF7C3AED)),
                SizedBox(height: 24),
                Text("Loading Spectrum...", style: TextStyle(color: Colors.white, fontSize: 16)),
              ],
            ),
          ),
        ),
      );
    }

    return const SpectrumApp();
  }
}
