import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'models/meal_log.dart';
import 'models/water_log.dart';
import 'services/nutrition_provider.dart';
import 'services/theme_provider.dart';
import 'services/auth_provider.dart';
import 'services/activity_provider.dart';
import 'services/habit_provider.dart';
import 'services/meal_plan_provider.dart';
import 'services/notification_service.dart';
import 'services/live_session_provider.dart';
import 'theme/app_theme.dart';
import 'screens/splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Global error handler — ensures runApp always runs even if init partially fails
  FlutterError.onError = (details) {
    FlutterError.presentError(details);
  };

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (_) {}

  try {
    await Hive.initFlutter();
    Hive.registerAdapter(MealLogAdapter());
    Hive.registerAdapter(WaterLogAdapter());
    await Hive.openBox<MealLog>('meal_logs');
    await Hive.openBox<WaterLog>('water_logs');
    await Hive.openBox('settings');
    await Hive.openBox('custom_foods');
    await Hive.openBox('habits_data');
    await Hive.openBox('meal_plans');
  } catch (_) {}

  final authProvider = AuthProvider();
  try {
    await authProvider.init();
  } catch (_) {}

  // Notifications are non-critical — never block app startup
  try {
    await NotificationService.init();
    await NotificationService.scheduleDailyReminders();
  } catch (_) {}

  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.dark,
  ));

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: authProvider),
        ChangeNotifierProvider(create: (_) => NutritionProvider()),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => ActivityProvider()),
        ChangeNotifierProvider(create: (_) => HabitProvider()),
        ChangeNotifierProvider(create: (_) => MealPlanProvider()),
        ChangeNotifierProvider(create: (_) => LiveSessionProvider()),
      ],
      child: const ProNutriApp(),
    ),
  );
}

class ProNutriApp extends StatelessWidget {
  const ProNutriApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    return MaterialApp(
      title: 'ProNutri',
      debugShowCheckedModeBanner: false,
      navigatorKey: navigatorKey,
      themeMode: themeProvider.themeMode,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      home: const SplashScreen(),
    );
  }
}
