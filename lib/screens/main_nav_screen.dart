import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import 'home_screen.dart';
import 'meal_logger_screen.dart';
import 'exercise_screen.dart';
import 'recipes_screen.dart';
import 'nutribot_screen.dart';

class MainNavScreen extends StatefulWidget {
  const MainNavScreen({super.key});
  @override
  State<MainNavScreen> createState() => _MainNavScreenState();
}

class _MainNavScreenState extends State<MainNavScreen> {
  int _idx = 0;

  final _screens = const [
    HomeScreen(),
    MealLoggerScreen(),
    ExerciseScreen(),
    RecipesScreen(),
    NutriBotScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: IndexedStack(index: _idx, children: _screens),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: isDark ? AppColors.surfDark : AppColors.surface,
          border: Border(top: BorderSide(color: isDark ? AppColors.borderDark : AppColors.border)),
          boxShadow: isDark ? [] : [BoxShadow(color: AppColors.brandBlue.withOpacity(0.06), blurRadius: 20, offset: const Offset(0, -4))],
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            child: Row(children: [
              _navItem(0, Icons.home_outlined,          Icons.home,             'Home'),
              _navItem(1, Icons.add_circle_outline,     Icons.add_circle,       'Log'),
              _navItem(2, Icons.fitness_center_outlined,Icons.fitness_center,   'Exercise'),
              _navItem(3, Icons.restaurant_menu_outlined,Icons.restaurant_menu, 'Recipes'),
              _navItem(4, Icons.smart_toy_outlined,     Icons.smart_toy,        'AI Coach'),
            ]),
          ),
        ),
      ),
    );
  }

  Widget _navItem(int idx, IconData icon, IconData activeIcon, String label) {
    final active = _idx == idx;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Expanded(child: GestureDetector(
      onTap: () => setState(() => _idx = idx),
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.symmetric(vertical: 6),
        decoration: BoxDecoration(
          color: active ? AppColors.brandBlue.withOpacity(0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          // Special center Log button
          idx == 1
            ? Container(
                width: 40, height: 40,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(colors: [AppColors.brandBlue, AppColors.brandGreen], begin: Alignment.topLeft, end: Alignment.bottomRight),
                  shape: BoxShape.circle,
                ),
                child: Icon(active ? activeIcon : icon, color: Colors.white, size: 22),
              )
            : Icon(
                active ? activeIcon : icon,
                size: 22,
                color: active ? AppColors.brandBlue : isDark ? AppColors.textSecDark : AppColors.textHint,
              ),
          const SizedBox(height: 3),
          Text(label, style: GoogleFonts.inter(
            fontSize: 10,
            fontWeight: active ? FontWeight.w700 : FontWeight.w400,
            color: active ? AppColors.brandBlue : isDark ? AppColors.textSecDark : AppColors.textHint,
          )),
        ]),
      ),
    ));
  }
}
