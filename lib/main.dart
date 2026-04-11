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
import 'services/notification_service.dart';
import 'services/live_session_provider.dart';
import 'theme/app_theme.dart';
import 'screens/splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase first
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  // Hive — only for meal logs and water logs
  await Hive.initFlutter();
  Hive.registerAdapter(MealLogAdapter());
  Hive.registerAdapter(WaterLogAdapter());
  await Hive.openBox<MealLog>('meal_logs');
  await Hive.openBox<WaterLog>('water_logs');
  await Hive.openBox('settings');

  // Restore login session if user was previously logged in
  final authProvider = AuthProvider();
  await authProvider.init();

  // Initialize push notifications
  await NotificationService.init();

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