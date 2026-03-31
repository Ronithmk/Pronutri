import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../services/auth_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_text_field.dart';
import '../main_nav_screen.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _obscure = true;
  bool _loading = false;

  @override
  void dispose() { _emailCtrl.dispose(); _passCtrl.dispose(); super.dispose(); }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    await Future.delayed(const Duration(milliseconds: 600));
    if (!mounted) return;
    final error = context.read<AuthProvider>().login(email: _emailCtrl.text, password: _passCtrl.text);
    setState(() => _loading = false);
    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(error), backgroundColor: AppColors.accent,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ));
    } else {
      Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => const MainNavScreen()), (r) => false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: isDark ? AppColors.bgDark : AppColors.bg,
      body: SafeArea(child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(key: _formKey, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const SizedBox(height: 24),
          // Logo + Brand
          Center(child: Column(children: [
            Container(
              width: 90, height: 90,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(22),
                boxShadow: [BoxShadow(color: const Color(0xFF00C896).withOpacity(0.2), blurRadius: 20, offset: const Offset(0, 8))],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(22),
                child: Image.asset('assets/images/logo.png', fit: BoxFit.contain),
              ),
            ),
            const SizedBox(height: 14),
            Text.rich(TextSpan(children: [
              TextSpan(text: 'Pro', style: GoogleFonts.inter(fontSize: 26, fontWeight: FontWeight.w900, color: const Color(0xFF1E6EBD))),
              TextSpan(text: 'Nutri', style: GoogleFonts.inter(fontSize: 26, fontWeight: FontWeight.w900, color: const Color(0xFF2ECC71))),
            ])),
            Text('by ProtonCode', style: GoogleFonts.inter(fontSize: 11, color: AppColors.textSecondary, letterSpacing: 1.2)),
          ])),
          const SizedBox(height: 36),
          Text('Welcome back 👋', style: GoogleFonts.inter(fontSize: 26, fontWeight: FontWeight.w800, color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary, letterSpacing: -0.5)),
          const SizedBox(height: 6),
          Text('Sign in to continue your health journey', style: GoogleFonts.inter(fontSize: 14, color: AppColors.textSecondary)),
          const SizedBox(height: 32),
          AppTextField(controller: _emailCtrl, label: 'Email address', hint: 'you@example.com', icon: Icons.email_outlined, keyboardType: TextInputType.emailAddress, validator: (v) => v!.isEmpty ? 'Enter your email' : null),
          const SizedBox(height: 16),
          AppTextField(controller: _passCtrl, label: 'Password', hint: '••••••••', icon: Icons.lock_outline, obscure: _obscure,
            suffix: IconButton(onPressed: () => setState(() => _obscure = !_obscure), icon: Icon(_obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined, color: AppColors.textSecondary, size: 20)),
            validator: (v) => v!.isEmpty ? 'Enter your password' : null),
          const SizedBox(height: 8),
          Align(alignment: Alignment.centerRight, child: TextButton(onPressed: () {}, child: Text('Forgot password?', style: GoogleFonts.inter(color: AppColors.primary, fontSize: 13, fontWeight: FontWeight.w500)))),
          const SizedBox(height: 20),
          AppButton(label: 'Sign In', onTap: _login, loading: _loading),
          const SizedBox(height: 20),
          Row(children: [const Expanded(child: Divider()), Padding(padding: const EdgeInsets.symmetric(horizontal: 12), child: Text('or', style: GoogleFonts.inter(color: AppColors.textHint, fontSize: 13))), const Expanded(child: Divider())]),
          const SizedBox(height: 20),
          OutlinedButton(
            onPressed: () { _emailCtrl.text = 'demo@pronutri.com'; _passCtrl.text = 'demo123'; _login(); },
            style: OutlinedButton.styleFrom(minimumSize: const Size(double.infinity, 52), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
            child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              const Text('🎮', style: TextStyle(fontSize: 18)),
              const SizedBox(width: 8),
              Text('Try Demo Account', style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: AppColors.primary)),
            ]),
          ),
          const SizedBox(height: 28),
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            Text("Don't have an account? ", style: GoogleFonts.inter(color: AppColors.textSecondary, fontSize: 14)),
            GestureDetector(onTap: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const RegisterScreen())), child: Text('Sign Up', style: GoogleFonts.inter(color: AppColors.primary, fontSize: 14, fontWeight: FontWeight.w600))),
          ]),
        ])),
      )),
    );
  }
}
