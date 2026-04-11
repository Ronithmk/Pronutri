import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../services/live_session_provider.dart';
import 'home_screen.dart';
import 'meal_logger_screen.dart';
import 'activity_screen.dart';
import 'exercise_screen.dart';
import 'recipes_screen.dart';
import 'nutribot_screen.dart';
import 'live/sessions_list_screen.dart';

class MainNavScreen extends StatefulWidget {
  final int initialIndex;
  const MainNavScreen({super.key, this.initialIndex = 0});
  @override
  State<MainNavScreen> createState() => _MainNavScreenState();
}

class _MainNavScreenState extends State<MainNavScreen> {
  late int _idx;

  final _screens = const [
    HomeScreen(),
    MealLoggerScreen(),
    ActivityScreen(),
    ExerciseScreen(),
    RecipesScreen(),
    SessionsListScreen(),
    NutriBotScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _idx = widget.initialIndex.clamp(0, _screens.length - 1).toInt();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: IndexedStack(index: _idx, children: _screens),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: isDark ? AppColors.surfDark : AppColors.surface,
          boxShadow: [
            BoxShadow(
              color: isDark
                  ? Colors.black.withOpacity(0.5)
                  : AppColors.brandBlue.withOpacity(0.10),
              blurRadius: 28,
              spreadRadius: -4,
              offset: const Offset(0, -8),
            ),
            BoxShadow(
              color: Colors.white.withOpacity(isDark ? 0.03 : 0.8),
              blurRadius: 6,
              offset: const Offset(0, -1),
            ),
          ],
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
              child: Row(children: [
                _navItem(0, Icons.home_outlined,            Icons.home_rounded,          'Home'),
                _navItem(1, Icons.add_circle_outline,       Icons.add_circle,            'Log'),
                _navItem(2, Icons.directions_walk_outlined, Icons.directions_walk,       'Activity'),
                _navItem(3, Icons.fitness_center_outlined,  Icons.fitness_center,        'Exercise'),
                _navItem(4, Icons.restaurant_menu_outlined, Icons.restaurant_menu,       'Recipes'),
                _navItem(5, Icons.live_tv_outlined,         Icons.live_tv,               'Live'),
                _navItem(6, Icons.smart_toy_outlined,       Icons.smart_toy,             'AI Coach'),
              ]),
            ),
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
          color: active
              ? AppColors.brandBlue.withOpacity(isDark ? 0.18 : 0.10)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          boxShadow: active
              ? [BoxShadow(color: AppColors.brandBlue.withOpacity(0.15), blurRadius: 10, offset: const Offset(0, 3))]
              : null,
        ),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          idx == 1
            ? Container(
                width: 38, height: 38,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppColors.brandBlue, AppColors.brandGreen],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(color: AppColors.brandBlue.withOpacity(0.40), blurRadius: 12, offset: const Offset(0, 5)),
                  ],
                ),
                child: Icon(active ? activeIcon : icon, color: Colors.white, size: 20),
              )
            : idx == 5
              ? _LiveNavIcon(icon: icon, activeIcon: activeIcon, active: active, isDark: isDark)
              : AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: EdgeInsets.all(active ? 6 : 4),
                  decoration: active
                    ? BoxDecoration(
                        color: AppColors.brandBlue.withOpacity(0.14),
                        borderRadius: BorderRadius.circular(10),
                      )
                    : null,
                  child: Icon(
                    active ? activeIcon : icon,
                    size: 20,
                    color: active
                        ? AppColors.brandBlue
                        : isDark ? AppColors.textSecDark : AppColors.textHint,
                  ),
                ),
          const SizedBox(height: 2),
          AnimatedDefaultTextStyle(
            duration: const Duration(milliseconds: 200),
            style: GoogleFonts.inter(
              fontSize: 9,
              fontWeight: active ? FontWeight.w700 : FontWeight.w400,
              color: active
                  ? AppColors.brandBlue
                  : isDark ? AppColors.textSecDark : AppColors.textHint,
            ),
            child: Text(label),
          ),
        ]),
      ),
    ));
  }
}

// ── Live nav icon with pulsing red dot when sessions are live ─────────────────
class _LiveNavIcon extends StatefulWidget {
  final IconData icon;
  final IconData activeIcon;
  final bool     active;
  final bool     isDark;
  const _LiveNavIcon({
    required this.icon,
    required this.activeIcon,
    required this.active,
    required this.isDark,
  });
  @override
  State<_LiveNavIcon> createState() => _LiveNavIconState();
}

class _LiveNavIconState extends State<_LiveNavIcon>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double>   _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 700))
      ..repeat(reverse: true);
    _anim = Tween(begin: 0.4, end: 1.0).animate(_ctrl);
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final hasLive = context.watch<LiveSessionProvider>().liveSessions.isNotEmpty;
    return Stack(clipBehavior: Clip.none, children: [
      Icon(
        widget.active ? widget.activeIcon : widget.icon,
        size: 20,
        color: widget.active
            ? AppColors.brandBlue
            : widget.isDark ? AppColors.textSecDark : AppColors.textHint,
      ),
      if (hasLive)
        Positioned(
          right: -3, top: -2,
          child: AnimatedBuilder(
            animation: _anim,
            builder: (_, __) => Container(
              width: 7, height: 7,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Color.lerp(const Color(0xFFCC0000), const Color(0xFFFF5555), _anim.value),
              ),
            ),
          ),
        ),
    ]);
  }
}
