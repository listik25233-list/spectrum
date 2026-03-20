import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:spectrum/features/auth/auth_guard.dart';

class SpectrumApp extends StatelessWidget {
  const SpectrumApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Spectrum',
      debugShowCheckedModeBanner: false,
      theme: _buildTheme(),
      home: const AuthGuard(),
    );
  }

  ThemeData _buildTheme() {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFF7C3AED), // purple
        brightness: Brightness.dark,
      ),
      scaffoldBackgroundColor: const Color(0xFF0A0A0F),
      fontFamily: 'Inter',
    );
  }
}
