import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';
import 'models/meal_log.dart';
import 'models/water_log.dart';
import 'models/user_model.dart';
import 'services/nutrition_provider.dart';
import 'services/theme_provider.dart';
import 'services/auth_provider.dart';
import 'theme/app_theme.dart';
import 'screens/splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Hive.initFlutter();
  Hive.registerAdapter(MealLogAdapter());
  Hive.registerAdapter(WaterLogAdapter());
  Hive.registerAdapter(UserModelAdapter());
  await Hive.openBox<MealLog>('meal_logs');
  await Hive.openBox<WaterLog>('water_logs');
  await Hive.openBox<UserModel>('users');
  await Hive.openBox('settings');

  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp, DeviceOrientation.portraitDown]);
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(statusBarColor: Colors.transparent, statusBarIconBrightness: Brightness.dark));

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => NutritionProvider()),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
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
      themeMode: themeProvider.themeMode,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      home: const SplashScreen(),
    );
  }
}
