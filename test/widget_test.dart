import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spectrum/features/auth/login_screen.dart';

void main() {
  testWidgets('login screen renders Spectrum CTA', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: LoginScreen(),
        ),
      ),
    );

    expect(find.text('Spectrum'), findsOneWidget);
    expect(find.text('Войти через Spotify'), findsOneWidget);
  });
}
