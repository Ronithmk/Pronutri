import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../services/live_session_provider.dart';
import '../theme/app_theme.dart';
import 'home_screen.dart';
import 'recipes_screen.dart';
import 'nutribot_screen.dart';
import 'live/sessions_list_screen.dart';

class TrainerDashboardScreen extends StatefulWidget {
  final int initialIndex;
  const TrainerDashboardScreen({super.key, this.initialIndex = 0});

  @override
  State<TrainerDashboardScreen> createState() => _TrainerDashboardScreenState();
}

class _TrainerDashboardScreenState extends State<TrainerDashboardScreen> {
  late int _idx;

  final _screens = const [
    SessionsListScreen(),
    HomeScreen(),
    RecipesScreen(),
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
          borderRadius: const BorderRadius.vertical(top: Radius.circular(26)),
          boxShadow: [
            BoxShadow(
              color: isDark
                  ? Colors.black.withOpacity(0.45)
                  : AppColors.brandBlue.withOpacity(0.10),
              blurRadius: 22,
              spreadRadius: -4,
              offset: const Offset(0, -7),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(26)),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              child: Row(
                children: [
                  _navItem(
                    0,
                    Icons.live_tv_outlined,
                    Icons.live_tv,
                    'Live',
                    useLiveIndicator: true,
                  ),
                  _navItem(1, Icons.home_outlined, Icons.home_rounded, 'Home'),
                  _navItem(
                    2,
                    Icons.restaurant_menu_outlined,
                    Icons.restaurant_menu,
                    'Recipes',
                  ),
                  _navItem(
                    3,
                    Icons.smart_toy_outlined,
                    Icons.smart_toy,
                    'AI Coach',
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _navItem(
    int idx,
    IconData icon,
    IconData activeIcon,
    String label, {
    bool useLiveIndicator = false,
  }) {
    final active = _idx == idx;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _idx = idx),
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          padding: const EdgeInsets.symmetric(vertical: 6),
          decoration: BoxDecoration(
            color: active
                ? AppColors.brandBlue.withOpacity(isDark ? 0.18 : 0.10)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              useLiveIndicator
                  ? _LiveNavIcon(
                      icon: icon,
                      activeIcon: activeIcon,
                      active: active,
                      isDark: isDark,
                    )
                  : Icon(
                      active ? activeIcon : icon,
                      size: 21,
                      color: active
                          ? AppColors.brandBlue
                          : isDark
                              ? AppColors.textSecDark
                              : AppColors.textHint,
                    ),
              const SizedBox(height: 3),
              Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 10,
                  fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                  color: active
                      ? AppColors.brandBlue
                      : isDark
                          ? AppColors.textSecDark
                          : AppColors.textHint,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LiveNavIcon extends StatefulWidget {
  final IconData icon;
  final IconData activeIcon;
  final bool active;
  final bool isDark;

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
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl =
        AnimationController(vsync: this, duration: const Duration(milliseconds: 700))
          ..repeat(reverse: true);
    _anim = Tween(begin: 0.4, end: 1.0).animate(_ctrl);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final hasLive = context.watch<LiveSessionProvider>().liveSessions.isNotEmpty;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        Icon(
          widget.active ? widget.activeIcon : widget.icon,
          size: 21,
          color: widget.active
              ? AppColors.brandBlue
              : widget.isDark
                  ? AppColors.textSecDark
                  : AppColors.textHint,
        ),
        if (hasLive)
          Positioned(
            right: -3,
            top: -2,
            child: AnimatedBuilder(
              animation: _anim,
              builder: (_, __) => Container(
                width: 7,
                height: 7,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Color.lerp(
                    const Color(0xFFCC0000),
                    const Color(0xFFFF5555),
                    _anim.value,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
