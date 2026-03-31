import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../services/auth_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_text_field.dart';
import 'login_screen.dart';
import 'otp_verification_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});
  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _pageCtrl = PageController();
  int _step = 0;
  bool _loading = false;

  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  final _weightCtrl = TextEditingController();
  final _heightCtrl = TextEditingController();
  final _ageCtrl = TextEditingController();
  final _targetCtrl = TextEditingController();
  bool _obscure = true;
  String _gender = 'male';
  String _goal = 'maintain';
  String _activity = 'moderate';
  final _k1 = GlobalKey<FormState>();
  final _k2 = GlobalKey<FormState>();
  final _k3 = GlobalKey<FormState>();

  @override
  void dispose() {
    for (final c in [_nameCtrl, _emailCtrl, _passCtrl, _confirmCtrl, _weightCtrl, _heightCtrl, _ageCtrl, _targetCtrl]) c.dispose();
    _pageCtrl.dispose();
    super.dispose();
  }

  double get _bmi {
    final w = double.tryParse(_weightCtrl.text) ?? 0;
    final h = double.tryParse(_heightCtrl.text) ?? 1;
    return w == 0 || h == 0 ? 0 : w / ((h / 100) * (h / 100));
  }
  Color get _bmiColor => _bmi < 18.5 ? AppColors.blue : _bmi < 25 ? AppColors.primary : _bmi < 30 ? AppColors.amber : AppColors.accent;
  String get _bmiCat => _bmi == 0 ? '' : _bmi < 18.5 ? 'Underweight' : _bmi < 25 ? 'Normal' : _bmi < 30 ? 'Overweight' : 'Obese';

  void _next() {
    if (_step == 0 && !_k1.currentState!.validate()) return;
    if (_step == 1 && !_k2.currentState!.validate()) return;
    if (_step == 2) { _submit(); return; }
    setState(() => _step++);
    _pageCtrl.nextPage(duration: const Duration(milliseconds: 400), curve: Curves.easeInOut);
  }

  void _back() {
    if (_step > 0) {
      setState(() => _step--);
      _pageCtrl.previousPage(duration: const Duration(milliseconds: 400), curve: Curves.easeInOut);
    }
  }

  Future<void> _submit() async {
    setState(() => _loading = true);
    final result = await context.read<AuthProvider>().sendRegistrationOtp(
      name: _nameCtrl.text, email: _emailCtrl.text, password: _passCtrl.text,
      weight: double.tryParse(_weightCtrl.text) ?? 70,
      height: double.tryParse(_heightCtrl.text) ?? 170,
      age: int.tryParse(_ageCtrl.text) ?? 25,
      gender: _gender, goal: _goal, activityLevel: _activity,
      targetWeight: double.tryParse(_targetCtrl.text) ?? double.tryParse(_weightCtrl.text) ?? 70,
    );
    setState(() => _loading = false);
    if (!mounted) return;

    if (result == null) {
      // Email sent successfully
      Navigator.push(context, MaterialPageRoute(builder: (_) => OtpVerificationScreen(email: _emailCtrl.text.toLowerCase().trim())));
    } else if (result.startsWith('EMAIL_NOT_CONFIGURED:')) {
      // Dev mode — show OTP on screen
      final devOtp = result.split(':')[1];
      Navigator.push(context, MaterialPageRoute(builder: (_) => OtpVerificationScreen(email: _emailCtrl.text.toLowerCase().trim(), devOtp: devOtp)));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(result), backgroundColor: AppColors.accent,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: isDark ? AppColors.bgDark : AppColors.bg,
      body: SafeArea(child: Column(children: [
        // Header
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
          child: Row(children: [
            if (_step > 0)
              IconButton(onPressed: _back, icon: const Icon(Icons.arrow_back_ios, size: 18),
                style: IconButton.styleFrom(backgroundColor: isDark ? AppColors.surfaceVariantDark : AppColors.surfaceVariant, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))))
            else const SizedBox(width: 40),
            Expanded(child: Column(children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: (_step + 1) / 3, minHeight: 4,
                  backgroundColor: isDark ? AppColors.borderDark : AppColors.border,
                  valueColor: const AlwaysStoppedAnimation(AppColors.primary),
                ),
              ),
              const SizedBox(height: 6),
              Text('Step ${_step + 1} of 3', style: GoogleFonts.inter(fontSize: 12, color: AppColors.textSecondary)),
            ])),
            const SizedBox(width: 40),
          ]),
        ),
        Expanded(child: PageView(
          controller: _pageCtrl,
          physics: const NeverScrollableScrollPhysics(),
          children: [_step1(isDark), _step2(isDark), _step3(isDark)],
        )),
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
          child: Column(children: [
            AppButton(label: _step < 2 ? 'Continue' : 'Send Verification Code', onTap: _next, loading: _loading,
              icon: _step == 2 ? Icons.email_outlined : null),
            const SizedBox(height: 12),
            if (_step == 0)
              Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                Text('Already have an account? ', style: GoogleFonts.inter(color: AppColors.textSecondary, fontSize: 14)),
                GestureDetector(
                  onTap: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const LoginScreen())),
                  child: Text('Sign In', style: GoogleFonts.inter(color: AppColors.primary, fontSize: 14, fontWeight: FontWeight.w600)),
                ),
              ]),
          ]),
        ),
      ])),
    );
  }

  Widget _step1(bool isDark) => SingleChildScrollView(
    padding: const EdgeInsets.all(24),
    child: Form(key: _k1, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const SizedBox(height: 8),
      Text('Create Account', style: GoogleFonts.inter(fontSize: 28, fontWeight: FontWeight.w800, color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary, letterSpacing: -0.5)),
      const SizedBox(height: 6),
      Text('Join thousands reaching their health goals', style: GoogleFonts.inter(fontSize: 14, color: AppColors.textSecondary)),
      const SizedBox(height: 32),
      AppTextField(controller: _nameCtrl, label: 'Full Name', hint: 'Your name', icon: Icons.person_outline, validator: (v) => v!.trim().length < 2 ? 'Enter your name' : null),
      const SizedBox(height: 14),
      AppTextField(controller: _emailCtrl, label: 'Email address', hint: 'you@example.com', icon: Icons.email_outlined, keyboardType: TextInputType.emailAddress, validator: (v) => !v!.contains('@') ? 'Enter a valid email' : null),
      const SizedBox(height: 14),
      AppTextField(controller: _passCtrl, label: 'Password', hint: 'Min 6 characters', icon: Icons.lock_outline, obscure: _obscure,
        suffix: IconButton(onPressed: () => setState(() => _obscure = !_obscure), icon: Icon(_obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined, color: AppColors.textSecondary, size: 20)),
        validator: (v) => v!.length < 6 ? 'Minimum 6 characters' : null),
      const SizedBox(height: 14),
      AppTextField(controller: _confirmCtrl, label: 'Confirm Password', hint: 'Repeat password', icon: Icons.lock_outline, obscure: true, validator: (v) => v != _passCtrl.text ? 'Passwords do not match' : null),
    ])),
  );

  Widget _step2(bool isDark) => SingleChildScrollView(
    padding: const EdgeInsets.all(24),
    child: Form(key: _k2, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const SizedBox(height: 8),
      Text('Body Measurements', style: GoogleFonts.inter(fontSize: 28, fontWeight: FontWeight.w800, color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary, letterSpacing: -0.5)),
      const SizedBox(height: 6),
      Text('We use this to calculate your personalized calorie goal', style: GoogleFonts.inter(fontSize: 14, color: AppColors.textSecondary)),
      const SizedBox(height: 24),
      Row(children: [
        _genderBtn('male', '👨', 'Male', isDark),
        const SizedBox(width: 12),
        _genderBtn('female', '👩', 'Female', isDark),
      ]),
      const SizedBox(height: 16),
      Row(children: [
        Expanded(child: AppTextField(controller: _weightCtrl, label: 'Weight (kg)', hint: '70', icon: Icons.monitor_weight_outlined, keyboardType: TextInputType.number, onChanged: (_) => setState(() {}), validator: (v) => double.tryParse(v!) == null ? 'Invalid' : null)),
        const SizedBox(width: 12),
        Expanded(child: AppTextField(controller: _heightCtrl, label: 'Height (cm)', hint: '170', icon: Icons.height, keyboardType: TextInputType.number, onChanged: (_) => setState(() {}), validator: (v) => double.tryParse(v!) == null ? 'Invalid' : null)),
      ]),
      const SizedBox(height: 14),
      AppTextField(controller: _ageCtrl, label: 'Age', hint: '25', icon: Icons.cake_outlined, keyboardType: TextInputType.number, validator: (v) => int.tryParse(v!) == null ? 'Invalid age' : null),
      if (_bmi > 0) ...[
        const SizedBox(height: 20),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: _bmiColor.withOpacity(0.08), borderRadius: BorderRadius.circular(14), border: Border.all(color: _bmiColor.withOpacity(0.2))),
          child: Row(children: [
            Container(width: 48, height: 48, decoration: BoxDecoration(color: _bmiColor.withOpacity(0.15), shape: BoxShape.circle), child: const Center(child: Text('📊', style: TextStyle(fontSize: 22)))),
            const SizedBox(width: 12),
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Your BMI', style: GoogleFonts.inter(fontSize: 12, color: AppColors.textSecondary)),
              Text(_bmi.toStringAsFixed(1), style: GoogleFonts.inter(fontSize: 28, fontWeight: FontWeight.w800, color: _bmiColor)),
              Text(_bmiCat, style: GoogleFonts.inter(fontSize: 13, color: _bmiColor, fontWeight: FontWeight.w600)),
            ]),
          ]),
        ),
      ],
    ])),
  );

  Widget _step3(bool isDark) => SingleChildScrollView(
    padding: const EdgeInsets.all(24),
    child: Form(key: _k3, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const SizedBox(height: 8),
      Text('Set Your Goals', style: GoogleFonts.inter(fontSize: 28, fontWeight: FontWeight.w800, color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary, letterSpacing: -0.5)),
      const SizedBox(height: 6),
      Text("We'll create your personalized plan", style: GoogleFonts.inter(fontSize: 14, color: AppColors.textSecondary)),
      const SizedBox(height: 24),
      Text('Primary Goal', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
      const SizedBox(height: 10),
      ...[['lose','🔥','Lose Weight','Burn fat, feel lighter'],['maintain','⚖️','Stay Fit','Maintain current weight'],['gain','💪','Build Muscle','Gain strength & mass']].map((g) => _goalTile(g[0], g[1], g[2], g[3], isDark)),
      const SizedBox(height: 20),
      Text('Activity Level', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
      const SizedBox(height: 10),
      ...[['sedentary','Sedentary','Little or no exercise'],['light','Lightly Active','1-3 days/week'],['moderate','Moderately Active','3-5 days/week'],['active','Very Active','6-7 days/week']].map((a) => _activityTile(a[0], a[1], a[2], isDark)),
      const SizedBox(height: 16),
      AppTextField(controller: _targetCtrl, label: 'Target Weight (kg)', hint: '65', icon: Icons.flag_outlined, keyboardType: TextInputType.number),
      const SizedBox(height: 20),
      Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(color: AppColors.primaryLight, borderRadius: BorderRadius.circular(12)),
        child: Row(children: [
          const Text('📧', style: TextStyle(fontSize: 20)),
          const SizedBox(width: 10),
          Expanded(child: Text('A verification code will be sent to your email address to confirm your account.', style: GoogleFonts.inter(fontSize: 13, color: AppColors.primaryDark, height: 1.4))),
        ]),
      ),
    ])),
  );

  Widget _genderBtn(String value, String emoji, String label, bool isDark) {
    final sel = _gender == value;
    return Expanded(child: GestureDetector(
      onTap: () => setState(() => _gender = value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: sel ? AppColors.primaryLight : isDark ? AppColors.surfaceDark : AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: sel ? AppColors.primary : isDark ? AppColors.borderDark : AppColors.border, width: sel ? 1.5 : 1),
        ),
        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Text(emoji, style: const TextStyle(fontSize: 20)),
          const SizedBox(width: 8),
          Text(label, style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: sel ? AppColors.primary : AppColors.textSecondary)),
        ]),
      ),
    ));
  }

  Widget _goalTile(String value, String emoji, String title, String subtitle, bool isDark) {
    final sel = _goal == value;
    return GestureDetector(
      onTap: () => setState(() => _goal = value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: sel ? AppColors.primaryLight : isDark ? AppColors.surfaceDark : AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: sel ? AppColors.primary : isDark ? AppColors.borderDark : AppColors.border, width: sel ? 1.5 : 1),
        ),
        child: Row(children: [
          Text(emoji, style: const TextStyle(fontSize: 22)),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title, style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 14, color: sel ? AppColors.primary : isDark ? AppColors.textPrimaryDark : AppColors.textPrimary)),
            Text(subtitle, style: GoogleFonts.inter(fontSize: 12, color: AppColors.textSecondary)),
          ])),
          if (sel) const Icon(Icons.check_circle, color: AppColors.primary, size: 20),
        ]),
      ),
    );
  }

  Widget _activityTile(String value, String title, String subtitle, bool isDark) {
    final sel = _activity == value;
    return GestureDetector(
      onTap: () => setState(() => _activity = value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: sel ? AppColors.primaryLight : isDark ? AppColors.surfaceDark : AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: sel ? AppColors.primary : isDark ? AppColors.borderDark : AppColors.border, width: sel ? 1.5 : 1),
        ),
        child: Row(children: [
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title, style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 13, color: sel ? AppColors.primary : isDark ? AppColors.textPrimaryDark : AppColors.textPrimary)),
            Text(subtitle, style: GoogleFonts.inter(fontSize: 11, color: AppColors.textSecondary)),
          ])),
          if (sel) const Icon(Icons.check_circle, color: AppColors.primary, size: 18),
        ]),
      ),
    );
  }
}
