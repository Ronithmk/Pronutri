import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive/hive.dart';
import 'package:provider/provider.dart';
import '../services/auth_provider.dart';
import '../services/nutrition_provider.dart';
import '../services/habit_provider.dart';
import '../theme/app_theme.dart';
import 'main_nav_screen.dart';
import 'trainer_dashboard_screen.dart';
import 'onboarding_screen.dart';
import 'auth/login_screen.dart';
import 'auth/trainer_pending_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});
  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  // Logo entrance
  late AnimationController _logoCtrl;
  late Animation<double>   _logoScale;
  late Animation<double>   _logoFade;
  late Animation<Offset>   _logoSlide;

  // Text fade
  late AnimationController _textCtrl;
  late Animation<double>   _textFade;

  // 3-dot pulse
  late AnimationController _dot1Ctrl;
  late AnimationController _dot2Ctrl;
  late AnimationController _dot3Ctrl;

  @override
  void initState() {
    super.initState();

    // ── Logo animation (elastic pop-in) ──────────────────────────
    _logoCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 900));
    _logoScale = Tween(begin: 0.4, end: 1.0).animate(
        CurvedAnimation(parent: _logoCtrl, curve: Curves.elasticOut));
    _logoFade = Tween(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(parent: _logoCtrl,
            curve: const Interval(0.0, 0.5, curve: Curves.easeOut)));
    _logoSlide = Tween(begin: const Offset(0, 0.15), end: Offset.zero).animate(
        CurvedAnimation(parent: _logoCtrl,
            curve: const Interval(0.0, 0.6, curve: Curves.easeOut)));

    // ── Text fade (delayed) ───────────────────────────────────────
    _textCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 600));
    _textFade = CurvedAnimation(parent: _textCtrl, curve: Curves.easeOut);

    // ── Staggered dot bouncers ────────────────────────────────────
    _dot1Ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 500))
      ..repeat(reverse: true);
    _dot2Ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 500))
      ..repeat(reverse: true);
    _dot3Ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 500))
      ..repeat(reverse: true);

    _runSequence();
  }

  Future<void> _runSequence() async {
    await Future.delayed(const Duration(milliseconds: 100));
    _logoCtrl.forward();
    await Future.delayed(const Duration(milliseconds: 500));
    _textCtrl.forward();
    // Stagger the dots
    Future.delayed(const Duration(milliseconds: 200), () => _dot2Ctrl.forward());
    Future.delayed(const Duration(milliseconds: 400), () => _dot3Ctrl.forward());
    await Future.delayed(const Duration(milliseconds: 2000));
    _navigate();
  }

  void _navigate() {
    if (!mounted) return;
    final auth     = context.read<AuthProvider>();
    final settings = Hive.box('settings');

    if (auth.isLoggedIn) {
      context.read<NutritionProvider>().setUser(auth.currentUser);
      context.read<HabitProvider>().setUser(auth.currentUser?.id ?? '');

      // Trainer pending → show review screen, not home
      if (auth.currentUser?.isTrainerPending == true) {
        Navigator.pushReplacement(context, _fade(const TrainerPendingScreen()));
        return;
      }

      if (auth.currentUser?.isTrainerApproved == true) {
        Navigator.pushReplacement(context, _fade(const TrainerDashboardScreen()));
        return;
      }

      Navigator.pushReplacement(context, _fade(const MainNavScreen()));
    } else if (settings.get('onboardingDone', defaultValue: false)) {
      Navigator.pushReplacement(context, _fade(const LoginScreen()));
    } else {
      Navigator.pushReplacement(context, _fade(const OnboardingScreen()));
    }
  }

  PageRoute _fade(Widget page) => PageRouteBuilder(
    pageBuilder:       (_, __, ___) => page,
    transitionsBuilder: (_, a, __, child) => FadeTransition(opacity: a, child: child),
    transitionDuration: const Duration(milliseconds: 500),
  );

  @override
  void dispose() {
    _logoCtrl.dispose();
    _textCtrl.dispose();
    _dot1Ctrl.dispose();
    _dot2Ctrl.dispose();
    _dot3Ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(children: [
        // ── Soft gradient background ──────────────────────────────────
        Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFFF0FFF8), Color(0xFFE8F5FF), Color(0xFFF8FFFE)],
            ),
          ),
        ),

        // ── Decorative blobs ──────────────────────────────────────────
        Positioned(top: -70, right: -70,
          child: FadeTransition(opacity: _logoFade,
            child: Container(width: 220, height: 220,
              decoration: BoxDecoration(shape: BoxShape.circle,
                color: AppColors.brandGreen.withOpacity(0.06))))),
        Positioned(bottom: -90, left: -90,
          child: FadeTransition(opacity: _logoFade,
            child: Container(width: 300, height: 300,
              decoration: BoxDecoration(shape: BoxShape.circle,
                color: AppColors.brandBlue.withOpacity(0.05))))),
        Positioned(top: 120, left: -30,
          child: FadeTransition(opacity: _logoFade,
            child: Container(width: 150, height: 150,
              decoration: BoxDecoration(shape: BoxShape.circle,
                color: AppColors.brandGreen.withOpacity(0.04))))),

        // ── Main content ──────────────────────────────────────────────
        Center(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            // Logo
            ScaleTransition(
              scale: _logoScale,
              child: FadeTransition(
                opacity: _logoFade,
                child: SlideTransition(
                  position: _logoSlide,
                  child: Container(
                    width: 160, height: 160,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(38),
                      boxShadow: [
                        BoxShadow(color: AppColors.brandGreen.withOpacity(0.18),
                            blurRadius: 40, offset: const Offset(0, 16)),
                        BoxShadow(color: AppColors.brandBlue.withOpacity(0.10),
                            blurRadius: 20, offset: const Offset(0, 8)),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(38),
                      child: Image.asset('assets/images/logo.png', fit: BoxFit.contain),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 28),

            // Brand name
            FadeTransition(
              opacity: _textFade,
              child: Column(children: [
                Text.rich(TextSpan(children: [
                  TextSpan(text: 'Pro',
                    style: GoogleFonts.inter(fontSize: 40, fontWeight: FontWeight.w900,
                        color: AppColors.brandBlue, letterSpacing: -1)),
                  TextSpan(text: 'Nutri',
                    style: GoogleFonts.inter(fontSize: 40, fontWeight: FontWeight.w900,
                        color: AppColors.brandGreen, letterSpacing: -1)),
                ])),
                const SizedBox(height: 4),
                Text('by ProtonCode',
                  style: GoogleFonts.inter(fontSize: 13,
                      color: const Color(0xFF9AA5B4),
                      fontWeight: FontWeight.w500, letterSpacing: 1.6)),
              ]),
            ),
            const SizedBox(height: 10),

            FadeTransition(
              opacity: _textFade,
              child: Column(children: [
                // AI badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF1E6EBD), Color(0xFF00C896)],
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                    ),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(color: AppColors.brandBlue.withOpacity(0.30), blurRadius: 12, offset: const Offset(0, 4)),
                    ],
                  ),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    const Text('✦', style: TextStyle(color: Colors.white, fontSize: 11)),
                    const SizedBox(width: 6),
                    Text('AI-Powered Nutrition App',
                      style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w700,
                          color: Colors.white, letterSpacing: 0.3)),
                  ]),
                ),
                const SizedBox(height: 10),
                Text('Smart Meals  ·  Smart Goals  ·  Real Results',
                  style: GoogleFonts.inter(fontSize: 12,
                      color: const Color(0xFFAAB8CC), fontWeight: FontWeight.w400, letterSpacing: 0.2)),
              ]),
            ),

            const SizedBox(height: 56),

            // ── Animated dot-pulse loader ─────────────────────────────
            FadeTransition(
              opacity: _textFade,
              child: _DotPulse(
                dot1: _dot1Ctrl,
                dot2: _dot2Ctrl,
                dot3: _dot3Ctrl,
              ),
            ),
          ]),
        ),

        // ── Version tag at bottom ─────────────────────────────────────
        Positioned(
          bottom: 28, left: 0, right: 0,
          child: FadeTransition(
            opacity: _textFade,
            child: Text('v2.0.0',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(fontSize: 11,
                  color: const Color(0xFFCCD6E0), fontWeight: FontWeight.w500)),
          ),
        ),
      ]),
    );
  }
}

// ── Staggered bouncing dots ────────────────────────────────────────────────────
class _DotPulse extends StatelessWidget {
  final AnimationController dot1;
  final AnimationController dot2;
  final AnimationController dot3;

  const _DotPulse({
    required this.dot1,
    required this.dot2,
    required this.dot3,
  });

  @override
  Widget build(BuildContext context) {
    return Row(mainAxisSize: MainAxisSize.min, children: [
      _Dot(ctrl: dot1, color: AppColors.brandBlue),
      const SizedBox(width: 10),
      _Dot(ctrl: dot2, color: AppColors.brandGreen),
      const SizedBox(width: 10),
      _Dot(ctrl: dot3, color: AppColors.brandBlue.withOpacity(0.5)),
    ]);
  }
}

class _Dot extends StatelessWidget {
  final AnimationController ctrl;
  final Color color;
  const _Dot({required this.ctrl, required this.color});

  @override
  Widget build(BuildContext context) {
    final bounce = Tween(begin: 0.0, end: -10.0).animate(
        CurvedAnimation(parent: ctrl, curve: Curves.easeInOut));
    return AnimatedBuilder(
      animation: ctrl,
      builder: (_, __) => Transform.translate(
        offset: Offset(0, bounce.value),
        child: Container(
          width: 9, height: 9,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            boxShadow: [BoxShadow(color: color.withOpacity(0.35), blurRadius: 6, offset: const Offset(0, 3))],
          ),
        ),
      ),
    );
  }
}
