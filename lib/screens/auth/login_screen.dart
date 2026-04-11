import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../services/auth_provider.dart';
import '../../services/nutrition_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_text_field.dart';
import '../main_nav_screen.dart';
import '../trainer_dashboard_screen.dart';
import '../admin/admin_login_screen.dart';
import 'role_selection_screen.dart';
import 'trainer_pending_screen.dart';
import '../../services/notification_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailCtrl = TextEditingController();
  final _passCtrl  = TextEditingController();
  final _formKey   = GlobalKey<FormState>();
  bool _obscure    = true;
  bool _loading    = false;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);

    final auth = context.read<AuthProvider>();

    // Demo account — local login
    if (_emailCtrl.text.trim() == 'demo@pronutri.com') {
      final error = auth.login(
        email: _emailCtrl.text.trim(),
        password: _passCtrl.text,
      );
      setState(() => _loading = false);
      if (error != null) {
        _showError(error);
        return;
      }
      context.read<NutritionProvider>().setUser(auth.currentUser);
      _goHome();
      return;
    }

    // Real account — backend login
    final error = await auth.loginWithBackend(
      email:    _emailCtrl.text.trim(),
      password: _passCtrl.text,
    );

    setState(() => _loading = false);

    if (error != null) {
      _showError(error);
      return;
    }

    if (!mounted) return;
    context.read<NutritionProvider>().setUser(auth.currentUser);
    _goHome();
  }

  void _goHome() {
    NotificationService.saveTokenToBackend(null);
    final user = context.read<AuthProvider>().currentUser;
    final role = user?.role ?? 'learner';
    final trainerStatus = user?.trainerStatus ?? '';

    Widget destination;
    if (role == 'trainer') {
      if (trainerStatus == 'approved') {
        destination = const TrainerDashboardScreen();
      } else {
        destination = const TrainerPendingScreen();
      }
    } else {
      destination = const MainNavScreen();
    }

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => destination),
      (r) => false,
    );
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: AppColors.accent,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      margin: const EdgeInsets.all(16),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: isDark ? AppColors.bgDark : AppColors.bg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: false,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 14, top: 8),
            child: GestureDetector(
              onTap: () => Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const AdminLoginScreen())),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.surfVarDark : AppColors.surface,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(color: AppColors.accent.withOpacity(0.15), blurRadius: 10, offset: const Offset(0, 4)),
                    BoxShadow(color: Colors.white.withOpacity(isDark ? 0.04 : 0.9), blurRadius: 4, offset: const Offset(-1, -1)),
                  ],
                ),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  const Icon(Icons.admin_panel_settings, size: 15, color: AppColors.accent),
                  const SizedBox(width: 6),
                  Text('Admin', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.accent)),
                ]),
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(key: _formKey, child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 20),

            // Logo + brand
            Center(child: Column(children: [
              Container(
                width: 96, height: 96,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(26),
                  boxShadow: [
                    BoxShadow(color: AppColors.brandBlue.withOpacity(0.30), blurRadius: 28, offset: const Offset(0, 12)),
                    BoxShadow(color: AppColors.brandGreen.withOpacity(0.15), blurRadius: 16, offset: const Offset(4, 4)),
                    BoxShadow(color: Colors.white.withOpacity(isDark ? 0.04 : 0.8), blurRadius: 6, offset: const Offset(-2, -2)),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(26),
                  child: Image.asset('assets/images/logo.png', fit: BoxFit.contain),
                ),
              ),
              const SizedBox(height: 16),
              Text.rich(TextSpan(children: [
                TextSpan(text: 'Pro', style: GoogleFonts.inter(fontSize: 28, fontWeight: FontWeight.w900, color: AppColors.brandBlue)),
                TextSpan(text: 'Nutri', style: GoogleFonts.inter(fontSize: 28, fontWeight: FontWeight.w900, color: AppColors.brandGreen)),
              ])),
              const SizedBox(height: 4),
              Text('by ProtonCode', style: GoogleFonts.inter(fontSize: 11, color: AppColors.textSecondary, letterSpacing: 1.4)),
            ])),
            const SizedBox(height: 40),

            Text('Welcome back 👋', style: GoogleFonts.inter(fontSize: 26, fontWeight: FontWeight.w800,
              color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary, letterSpacing: -0.5)),
            const SizedBox(height: 6),
            Text('Sign in to continue your health journey',
              style: GoogleFonts.inter(fontSize: 14, color: AppColors.textSecondary)),
            const SizedBox(height: 32),

            AppTextField(
              controller: _emailCtrl,
              label: 'Email address',
              hint: 'you@example.com',
              icon: Icons.email_outlined,
              keyboardType: TextInputType.emailAddress,
              validator: (v) => v!.isEmpty ? 'Enter your email' : null,
            ),
            const SizedBox(height: 16),
            AppTextField(
              controller: _passCtrl,
              label: 'Password',
              hint: '••••••••',
              icon: Icons.lock_outline,
              obscure: _obscure,
              suffix: IconButton(
                onPressed: () => setState(() => _obscure = !_obscure),
                icon: Icon(_obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                  color: AppColors.textSecondary, size: 20),
              ),
              validator: (v) => v!.isEmpty ? 'Enter your password' : null,
            ),
            const SizedBox(height: 28),

            AppButton(label: 'Sign In', onTap: _login, loading: _loading),
            const SizedBox(height: 22),

            Row(children: [
              Expanded(child: Divider(color: (isDark ? AppColors.borderDark : AppColors.border).withOpacity(0.7))),
              Padding(padding: const EdgeInsets.symmetric(horizontal: 14),
                child: Text('or', style: GoogleFonts.inter(color: AppColors.textSecondary, fontSize: 13))),
              Expanded(child: Divider(color: (isDark ? AppColors.borderDark : AppColors.border).withOpacity(0.7))),
            ]),
            const SizedBox(height: 22),

            // Demo account button — clay style
            GestureDetector(
              onTap: () {
                _emailCtrl.text = 'demo@pronutri.com';
                _passCtrl.text  = 'demo123';
                _login();
              },
              child: Container(
                width: double.infinity, height: 56,
                decoration: BoxDecoration(
                  color: isDark ? AppColors.surfDark : AppColors.surface,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.brandBlue.withOpacity(0.25), width: 1.5),
                  boxShadow: [
                    BoxShadow(color: AppColors.brandBlue.withOpacity(0.10), blurRadius: 18, offset: const Offset(0, 7)),
                    BoxShadow(color: Colors.white.withOpacity(isDark ? 0.04 : 0.9), blurRadius: 4, offset: const Offset(-1, -1)),
                  ],
                ),
                child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  const Text('🎮', style: TextStyle(fontSize: 20)),
                  const SizedBox(width: 10),
                  Text('Try Demo Account', style: GoogleFonts.inter(
                    fontWeight: FontWeight.w700, fontSize: 15, color: AppColors.brandBlue)),
                ]),
              ),
            ),
            const SizedBox(height: 30),

            Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              Text("Don't have an account? ",
                style: GoogleFonts.inter(color: AppColors.textSecondary, fontSize: 14)),
              GestureDetector(
                onTap: () => Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const RoleSelectionScreen())),
                child: Text('Sign Up', style: GoogleFonts.inter(
                  color: AppColors.brandBlue, fontSize: 14, fontWeight: FontWeight.w700)),
              ),
            ]),
          ],
        )),
      )),
    );
  }
}
