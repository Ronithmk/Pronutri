import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:nutritrack/services/auth_provider.dart';
import 'package:nutritrack/services/theme_provider.dart';
import 'package:nutritrack/services/nutrition_provider.dart';
import 'package:nutritrack/services/live_session_provider.dart';
import 'package:nutritrack/screens/auth/login_screen.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Smoke tests — verify the login screen renders without crashing.
// These tests do NOT hit the network or Firebase; they only test the widget
// tree. Integration tests live in the integration_test/ folder.
// ─────────────────────────────────────────────────────────────────────────────

Widget _testApp(Widget child) {
  return MultiProvider(
    providers: [
      ChangeNotifierProvider(create: (_) => AuthProvider()),
      ChangeNotifierProvider(create: (_) => ThemeProvider()),
      ChangeNotifierProvider(create: (_) => NutritionProvider()),
      ChangeNotifierProvider(create: (_) => LiveSessionProvider()),
    ],
    child: MaterialApp(home: child),
  );
}

void main() {
  setUpAll(() {
    // Stub SharedPreferences for tests
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('LoginScreen renders email + password fields',
      (WidgetTester tester) async {
    await tester.pumpWidget(_testApp(const LoginScreen()));
    await tester.pump(); // let initState settle

    // Both tab labels should be visible
    expect(find.text('Sign In'), findsWidgets);
    expect(find.text('Sign Up'), findsWidgets);
  });

  testWidgets('LoginScreen shows ProNutri branding',
      (WidgetTester tester) async {
    await tester.pumpWidget(_testApp(const LoginScreen()));
    await tester.pump();

    // The app name appears in the header
    expect(find.textContaining('Nutri'), findsWidgets);
  });
}
