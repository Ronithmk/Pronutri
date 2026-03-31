import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive/hive.dart';
import 'package:provider/provider.dart';
import '../services/auth_provider.dart';
import '../services/nutrition_provider.dart';
import '../theme/app_theme.dart';
import 'main_nav_screen.dart';
import 'onboarding_screen.dart';
import 'auth/login_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});
  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _fade;
  late Animation<double> _scale;
  late Animation<double> _logoScale;
  late Animation<Offset> _logoSlide;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1400));
    _fade = Tween<double>(begin: 0, end: 1).animate(CurvedAnimation(parent: _ctrl, curve: const Interval(0.0, 0.6, curve: Curves.easeOut)));
    _scale = Tween<double>(begin: 0.7, end: 1).animate(CurvedAnimation(parent: _ctrl, curve: const Interval(0.0, 0.7, curve: Curves.elasticOut)));
    _logoScale = Tween<double>(begin: 0.5, end: 1).animate(CurvedAnimation(parent: _ctrl, curve: const Interval(0.1, 0.8, curve: Curves.elasticOut)));
    _logoSlide = Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero).animate(CurvedAnimation(parent: _ctrl, curve: const Interval(0.1, 0.7, curve: Curves.easeOut)));
    _ctrl.forward();
    Future.delayed(const Duration(milliseconds: 2500), _navigate);
  }

  void _navigate() {
    if (!mounted) return;
    final auth = context.read<AuthProvider>();
    final settings = Hive.box('settings');
    if (auth.isLoggedIn) {
      context.read<NutritionProvider>().setUser(auth.currentUser);
      Navigator.pushReplacement(context, _fadeRoute(const MainNavScreen()));
    } else if (settings.get('onboardingDone', defaultValue: false)) {
      Navigator.pushReplacement(context, _fadeRoute(const LoginScreen()));
    } else {
      Navigator.pushReplacement(context, _fadeRoute(const OnboardingScreen()));
    }
  }

  PageRoute _fadeRoute(Widget page) => PageRouteBuilder(
    pageBuilder: (_, __, ___) => page,
    transitionsBuilder: (_, a, __, child) => FadeTransition(opacity: a, child: child),
    transitionDuration: const Duration(milliseconds: 600),
  );

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // Background gradient
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFFF0FFF8), Color(0xFFE8F5FF), Color(0xFFF8FFFE)],
              ),
            ),
          ),
          // Decorative circles
          Positioned(top: -60, right: -60, child: FadeTransition(opacity: _fade, child: Container(width: 200, height: 200, decoration: BoxDecoration(shape: BoxShape.circle, color: const Color(0xFF00C896).withOpacity(0.06))))),
          Positioned(bottom: -80, left: -80, child: FadeTransition(opacity: _fade, child: Container(width: 280, height: 280, decoration: BoxDecoration(shape: BoxShape.circle, color: const Color(0xFF1E6EBD).withOpacity(0.05))))),
          Positioned(top: 100, left: -40, child: FadeTransition(opacity: _fade, child: Container(width: 140, height: 140, decoration: BoxDecoration(shape: BoxShape.circle, color: const Color(0xFF2ECC71).withOpacity(0.04))))),

          // Main content
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Logo image
                ScaleTransition(
                  scale: _logoScale,
                  child: SlideTransition(
                    position: _logoSlide,
                    child: Container(
                      width: 180, height: 180,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(40),
                        boxShadow: [
                          BoxShadow(color: const Color(0xFF00C896).withOpacity(0.15), blurRadius: 40, offset: const Offset(0, 16)),
                          BoxShadow(color: const Color(0xFF1E6EBD).withOpacity(0.08), blurRadius: 20, offset: const Offset(0, 8)),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(40),
                        child: Image.asset('assets/images/logo.png', fit: BoxFit.contain),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 28),

                // App name
                FadeTransition(
                  opacity: _fade,
                  child: ScaleTransition(
                    scale: _scale,
                    child: Column(children: [
                      Text.rich(TextSpan(children: [
                        TextSpan(text: 'Pro', style: GoogleFonts.inter(fontSize: 42, fontWeight: FontWeight.w900, color: const Color(0xFF1E6EBD), letterSpacing: -1)),
                        TextSpan(text: 'Nutri', style: GoogleFonts.inter(fontSize: 42, fontWeight: FontWeight.w900, color: const Color(0xFF2ECC71), letterSpacing: -1)),
                      ])),
                      const SizedBox(height: 4),
                      Text('by ProtonCode', style: GoogleFonts.inter(fontSize: 14, color: const Color(0xFF888888), fontWeight: FontWeight.w500, letterSpacing: 1.5)),
                    ]),
                  ),
                ),
                const SizedBox(height: 12),

                FadeTransition(
                  opacity: _fade,
                  child: Text('Your Personal Nutrition Coach', style: GoogleFonts.inter(fontSize: 14, color: const Color(0xFF888888), fontWeight: FontWeight.w400)),
                ),
                const SizedBox(height: 64),

                // Loading indicator
                FadeTransition(
                  opacity: _fade,
                  child: SizedBox(
                    width: 36, height: 36,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      valueColor: AlwaysStoppedAnimation<Color>(const Color(0xFF00C896).withOpacity(0.7)),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
