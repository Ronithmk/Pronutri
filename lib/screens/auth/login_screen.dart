import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../services/auth_provider.dart';
import '../../services/nutrition_provider.dart';
import '../../services/habit_provider.dart';
import '../../services/meal_plan_provider.dart';
import '../../theme/app_theme.dart';
import '../main_nav_screen.dart';
import '../trainer_dashboard_screen.dart';
import '../admin/admin_login_screen.dart';
import 'forgot_password_screen.dart';
import 'role_selection_screen.dart';
import 'trainer_pending_screen.dart';
import '../../services/notification_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with TickerProviderStateMixin {
  final _emailCtrl = TextEditingController();
  final _passCtrl  = TextEditingController();
  final _formKey   = GlobalKey<FormState>();
  bool _obscure    = true;
  bool _loading    = false;

  late AnimationController _fadeCtrl;
  late AnimationController _slideCtrl;
  late Animation<double>   _fadeAnim;
  late Animation<Offset>   _slideAnim;

  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 800));
    _slideCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 700));
    _fadeAnim  = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);
    _slideAnim = Tween(begin: const Offset(0, 0.06), end: Offset.zero)
        .animate(CurvedAnimation(parent: _slideCtrl, curve: Curves.easeOut));
    _fadeCtrl.forward();
    _slideCtrl.forward();
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    _fadeCtrl.dispose();
    _slideCtrl.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (_formKey.currentState?.validate() != true) return;
    setState(() => _loading = true);
    final auth = context.read<AuthProvider>();

    final error = await auth.loginWithBackend(
        email: _emailCtrl.text.trim(), password: _passCtrl.text);
    if (!mounted) return;
    setState(() => _loading = false);
    if (error != null) { _showError(error); return; }
    context.read<NutritionProvider>().setUser(auth.currentUser);
    context.read<HabitProvider>().setUser(auth.currentUser?.id ?? '');
    context.read<MealPlanProvider>().setUser(auth.currentUser?.id ?? '');
    _goHome();
  }

  void _goHome() {
    NotificationService.saveTokenToBackend(null);
    final user   = context.read<AuthProvider>().currentUser;
    final role   = user?.role ?? 'learner';
    final status = user?.trainerStatus ?? '';
    Widget dest;
    if (role == 'trainer') {
      dest = status == 'approved'
          ? const TrainerDashboardScreen()
          : const TrainerPendingScreen();
    } else {
      dest = const MainNavScreen();
    }
    Navigator.pushAndRemoveUntil(
        context, MaterialPageRoute(builder: (_) => dest), (r) => false);
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg, style: GoogleFonts.inter(fontWeight: FontWeight.w500)),
      backgroundColor: AppColors.accent,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      margin: const EdgeInsets.all(16),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final size   = MediaQuery.of(context).size;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (_, __) async {
        final shouldExit = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Exit App?'),
            content: const Text('Do you want to exit ProNutri?'),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('No')),
              TextButton(onPressed: () => Navigator.pop(ctx, true),  child: const Text('Exit')),
            ],
          ),
        );
        if (shouldExit == true && context.mounted) {
          Navigator.of(context).pop();
        }
      },
      child: Scaffold(
        backgroundColor: isDark ? const Color(0xFF0A0E1A) : const Color(0xFF0D1B2A),
        body: Stack(children: [

        // ── Animated background orbs ────────────────────────────────
        _Orb(top: -80, left: -80, size: 260, color: AppColors.brandBlue.withOpacity(0.18)),
        _Orb(top: size.height * 0.25, right: -60, size: 200, color: AppColors.brandGreen.withOpacity(0.12)),
        _Orb(bottom: -60, left: size.width * 0.2, size: 220, color: AppColors.brandBlue.withOpacity(0.10)),

        // ── Grid lines (subtle) ─────────────────────────────────────
        CustomPaint(size: Size(size.width, size.height), painter: _GridPainter()),

        // ── Content ─────────────────────────────────────────────────
        SafeArea(
          child: FadeTransition(
            opacity: _fadeAnim,
            child: SlideTransition(
              position: _slideAnim,
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Form(key: _formKey, child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 16),

                    // Admin button
                    Align(
                      alignment: Alignment.centerRight,
                      child: GestureDetector(
                        onTap: () => Navigator.push(context,
                            MaterialPageRoute(builder: (_) => const AdminLoginScreen())),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.07),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: Colors.white.withOpacity(0.12)),
                          ),
                          child: Row(mainAxisSize: MainAxisSize.min, children: [
                            Icon(Icons.admin_panel_settings, size: 14,
                                color: AppColors.accent.withOpacity(0.9)),
                            const SizedBox(width: 5),
                            Text('Admin', style: GoogleFonts.inter(
                                fontSize: 12, fontWeight: FontWeight.w600,
                                color: AppColors.accent.withOpacity(0.9))),
                          ]),
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // ── Logo + brand ─────────────────────────────────
                    Center(child: Column(children: [
                      // Logo with glow
                      Container(
                        width: 88, height: 88,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [
                            BoxShadow(color: AppColors.brandGreen.withOpacity(0.40),
                                blurRadius: 32, offset: const Offset(0, 10)),
                            BoxShadow(color: AppColors.brandBlue.withOpacity(0.20),
                                blurRadius: 18, offset: const Offset(0, 6)),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(24),
                          child: Image.asset('assets/images/logo.png', fit: BoxFit.contain),
                        ),
                      ),
                      const SizedBox(height: 14),

                      // Brand name
                      Text.rich(TextSpan(children: [
                        TextSpan(text: 'Pro', style: GoogleFonts.inter(
                            fontSize: 30, fontWeight: FontWeight.w900,
                            color: AppColors.brandBlue, letterSpacing: -0.5)),
                        TextSpan(text: 'Nutri', style: GoogleFonts.inter(
                            fontSize: 30, fontWeight: FontWeight.w900,
                            color: AppColors.brandGreen, letterSpacing: -0.5)),
                      ])),
                      const SizedBox(height: 6),

                      // AI badge
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [AppColors.brandBlue.withOpacity(0.30),
                              AppColors.brandGreen.withOpacity(0.25)],
                          ),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.white.withOpacity(0.15)),
                        ),
                        child: Row(mainAxisSize: MainAxisSize.min, children: [
                          const Text('✦', style: TextStyle(fontSize: 9, color: Colors.white70)),
                          const SizedBox(width: 5),
                          Text('AI-Powered Nutrition', style: GoogleFonts.inter(
                              fontSize: 11, fontWeight: FontWeight.w600,
                              color: Colors.white70, letterSpacing: 0.3)),
                        ]),
                      ),
                    ])),

                    const SizedBox(height: 28),

                    // ── Feature pills ────────────────────────────────
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(children: [
                        _FeaturePill(icon: '🤖', label: 'AI Meal Plans'),
                        const SizedBox(width: 8),
                        _FeaturePill(icon: '📊', label: 'Smart Tracking'),
                        const SizedBox(width: 8),
                        _FeaturePill(icon: '🍛', label: '50+ Recipes'),
                        const SizedBox(width: 8),
                        _FeaturePill(icon: '🔥', label: 'Calorie Goals'),
                      ]),
                    ),

                    const SizedBox(height: 28),

                    // ── Form card ────────────────────────────────────
                    Container(
                      padding: const EdgeInsets.all(22),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(isDark ? 0.05 : 0.08),
                        borderRadius: BorderRadius.circular(28),
                        border: Border.all(color: Colors.white.withOpacity(0.12)),
                        boxShadow: [
                          BoxShadow(color: Colors.black.withOpacity(0.20),
                              blurRadius: 30, offset: const Offset(0, 10)),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Welcome back 👋', style: GoogleFonts.inter(
                            fontSize: 22, fontWeight: FontWeight.w800,
                            color: Colors.white, letterSpacing: -0.4,
                          )),
                          const SizedBox(height: 4),
                          Text('Sign in to continue your journey',
                            style: GoogleFonts.inter(fontSize: 13,
                                color: Colors.white.withOpacity(0.55))),
                          const SizedBox(height: 22),

                          _DarkTextField(
                            controller: _emailCtrl,
                            label: 'Email address',
                            hint: 'you@example.com',
                            icon: Icons.email_outlined,
                            keyboardType: TextInputType.emailAddress,
                            validator: (v) => v!.isEmpty ? 'Enter your email' : null,
                          ),
                          const SizedBox(height: 14),
                          _DarkTextField(
                            controller: _passCtrl,
                            label: 'Password',
                            hint: '••••••••',
                            icon: Icons.lock_outline,
                            obscure: _obscure,
                            suffix: IconButton(
                              onPressed: () => setState(() => _obscure = !_obscure),
                              icon: Icon(
                                _obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                                color: Colors.white38, size: 20),
                            ),
                            validator: (v) => v!.isEmpty ? 'Enter your password' : null,
                          ),
                          const SizedBox(height: 10),

                          Align(
                            alignment: Alignment.centerRight,
                            child: GestureDetector(
                              onTap: () => Navigator.push(context,
                                  MaterialPageRoute(builder: (_) => const ForgotPasswordScreen())),
                              child: Text('Forgot password?', style: GoogleFonts.inter(
                                fontSize: 13, fontWeight: FontWeight.w600,
                                color: AppColors.brandGreen,
                              )),
                            ),
                          ),
                          const SizedBox(height: 20),

                          // Sign In button
                          _GradientButton(
                            label: 'Sign In',
                            loading: _loading,
                            onTap: _login,
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    // ── Divider ──────────────────────────────────────
                    Row(children: [
                      Expanded(child: Divider(color: Colors.white.withOpacity(0.12))),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                        child: Text('or', style: GoogleFonts.inter(
                            fontSize: 13, color: Colors.white38)),
                      ),
                      Expanded(child: Divider(color: Colors.white.withOpacity(0.12))),
                    ]),

                    const SizedBox(height: 20),

                    // ── Demo button ──────────────────────────────────
                    GestureDetector(
                      onTap: () {
                        _emailCtrl.text = 'demo@pronutri.com';
                        _passCtrl.text  = 'demo123';
                        _login();
                      },
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.06),
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(color: Colors.white.withOpacity(0.14)),
                        ),
                        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                          const Text('🎮', style: TextStyle(fontSize: 18)),
                          const SizedBox(width: 10),
                          Text('Try Demo Account',
                            style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w700,
                                color: Colors.white70)),
                        ]),
                      ),
                    ),

                    const SizedBox(height: 28),

                    // ── Sign up link ─────────────────────────────────
                    Center(child: Row(mainAxisSize: MainAxisSize.min, children: [
                      Text("Don't have an account? ",
                          style: GoogleFonts.inter(color: Colors.white38, fontSize: 14)),
                      GestureDetector(
                        onTap: () => Navigator.push(context,
                            MaterialPageRoute(builder: (_) => const RoleSelectionScreen())),
                        child: Text('Sign Up', style: GoogleFonts.inter(
                            color: AppColors.brandGreen, fontSize: 14,
                            fontWeight: FontWeight.w700)),
                      ),
                    ])),

                    const SizedBox(height: 32),
                  ],
                )),
              ),
            ),
          ),
        ),
        ]),
      ),
    );
  }
}

// ── Dark-themed text field used only in LoginScreen ──────────────────────────
class _DarkTextField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String hint;
  final IconData icon;
  final TextInputType? keyboardType;
  final bool obscure;
  final Widget? suffix;
  final String? Function(String?)? validator;

  const _DarkTextField({
    required this.controller,
    required this.label,
    required this.hint,
    required this.icon,
    this.keyboardType,
    this.obscure = false,
    this.suffix,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: GoogleFonts.inter(
          fontSize: 12, fontWeight: FontWeight.w600, color: Colors.white54)),
      const SizedBox(height: 7),
      TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        obscureText: obscure,
        style: GoogleFonts.inter(fontSize: 15, color: Colors.white),
        validator: validator,
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: GoogleFonts.inter(fontSize: 14, color: Colors.white24),
          prefixIcon: Icon(icon, color: Colors.white30, size: 20),
          suffixIcon: suffix,
          filled: true,
          fillColor: Colors.white.withOpacity(0.07),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(color: Colors.white.withOpacity(0.12)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(color: Colors.white.withOpacity(0.12)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(color: AppColors.brandGreen.withOpacity(0.7), width: 1.5),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: AppColors.accent),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: AppColors.accent),
          ),
          errorStyle: GoogleFonts.inter(fontSize: 11, color: AppColors.accent),
        ),
      ),
    ]);
  }
}

// ── Gradient CTA button ───────────────────────────────────────────────────────
class _GradientButton extends StatelessWidget {
  final String label;
  final bool loading;
  final VoidCallback? onTap;
  const _GradientButton({required this.label, required this.loading, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: loading ? null : onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: double.infinity,
        height: 54,
        decoration: BoxDecoration(
          gradient: loading
              ? null
              : const LinearGradient(
                  colors: [Color(0xFF1E6EBD), Color(0xFF00C896)],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
          color: loading ? Colors.white10 : null,
          borderRadius: BorderRadius.circular(16),
          boxShadow: loading ? null : [
            BoxShadow(color: AppColors.brandGreen.withOpacity(0.35),
                blurRadius: 18, offset: const Offset(0, 6)),
          ],
        ),
        child: Center(
          child: loading
              ? const SizedBox(width: 22, height: 22,
                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
              : Text(label, style: GoogleFonts.inter(
                  fontSize: 15, fontWeight: FontWeight.w800,
                  color: Colors.white, letterSpacing: 0.2)),
        ),
      ),
    );
  }
}

// ── Feature pill chip ─────────────────────────────────────────────────────────
class _FeaturePill extends StatelessWidget {
  final String icon;
  final String label;
  const _FeaturePill({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.07),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.12)),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Text(icon, style: const TextStyle(fontSize: 13)),
        const SizedBox(width: 5),
        Text(label, style: GoogleFonts.inter(
            fontSize: 12, fontWeight: FontWeight.w600, color: Colors.white60)),
      ]),
    );
  }
}

// ── Decorative orb ────────────────────────────────────────────────────────────
class _Orb extends StatelessWidget {
  final double? top, bottom, left, right, size;
  final Color color;
  const _Orb({this.top, this.bottom, this.left, this.right,
    required this.size, required this.color});

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: top, bottom: bottom, left: left, right: right,
      child: Container(
        width: size, height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: color,
        ),
      ),
    );
  }
}

// ── Subtle grid background painter ───────────────────────────────────────────
class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.025)
      ..strokeWidth = 0.5;
    const step = 50.0;
    for (double x = 0; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(_) => false;
}

