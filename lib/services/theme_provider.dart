import 'package:flutter/material.dart';
import 'package:hive/hive.dart';

class ThemeProvider extends ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.light;
  ThemeMode get themeMode => _themeMode;
  bool get isDark => _themeMode == ThemeMode.dark;

  ThemeProvider() {
    final box = Hive.box('settings');
    _themeMode = box.get('darkMode', defaultValue: false) ? ThemeMode.dark : ThemeMode.light;
  }

  void toggleTheme() {
    _themeMode = isDark ? ThemeMode.light : ThemeMode.dark;
    Hive.box('settings').put('darkMode', isDark);
    notifyListeners();
  }
}
