// This is a widget test for the actual app splash screen.
// It validates that the splash screen renders the app title and loading state.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:veritask/screens/auth/splash_screen.dart';

void main() {
  testWidgets('Splash screen shows app title and loading indicator',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: SplashScreen(autoNavigate: false)),
    );
    await tester.pump();

    expect(find.text('VeriTask'), findsOneWidget);
    expect(find.text('Secure. Verify. Complete.'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });
}
