import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:spectrum/features/auth/auth_provider.dart';
import 'package:spectrum/features/auth/login_screen.dart';
import 'package:spectrum/features/home/home_screen.dart';

/// Guards the app root: shows LibraryScreen if at least one service
/// is connected, otherwise shows LoginScreen.
class AuthGuard extends ConsumerWidget {
  const AuthGuard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);

    return authState.when(
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => Scaffold(
        body: Center(child: Text('Error: $e')),
      ),
      data: (connected) {
        if (connected.isEmpty) return const LoginScreen();
        return const HomeScreen();
      },
    );
  }
}
