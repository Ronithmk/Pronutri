import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/api_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_text_field.dart';

// Three steps: enter email → verify OTP → set new password
class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  int _step = 0; // 0 = email, 1 = otp, 2 = new password

  // Step 0
  final _emailCtrl = TextEditingController();
  final _emailFormKey = GlobalKey<FormState>();

  // Step 1 — OTP
  final List<TextEditingController> _otpControllers =
      List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(6, (_) => FocusNode());
  String? _devOtp;

  // Step 2
  final _passCtrl    = TextEditingController();
  final _confirmCtrl = TextEditingController();
  bool _obscurePass    = true;
  bool _obscureConfirm = true;

  bool _loading = false;
  String? _error;

  String get _otpValue => _otpControllers.map((c) => c.text).join();
  bool get _otpComplete => _otpValue.length == 6;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    _confirmCtrl.dispose();
    for (final c in _otpControllers) { c.dispose(); }
    for (final n in _focusNodes) { n.dispose(); }
    super.dispose();
  }

  // ── Step 0: send OTP ──────────────────────────────────────────────────────
  Future<void> _sendOtp() async {
    if (!_emailFormKey.currentState!.validate()) return;
    setState(() { _loading = true; _error = null; });

    final res = await ApiService.post('/auth/forgot-password', {
      'email': _emailCtrl.text.trim(),
    });

    if (!mounted) return;
    setState(() => _loading = false);

    if (res.containsKey('error')) {
      setState(() => _error = res['error'] as String?);
      return;
    }

    setState(() {
      _devOtp = res['otp'] as String?;
      _step = 1;
      _error = null;
    });
  }

  // ── Step 1: verify OTP ────────────────────────────────────────────────────
  void _onOtpChanged(int index, String value) {
    if (value.isEmpty && index > 0) {
      _focusNodes[index - 1].requestFocus();
    } else if (value.isNotEmpty && index < 5) {
      _focusNodes[index + 1].requestFocus();
    } else if (value.isNotEmpty) {
      _focusNodes[index].unfocus();
    }
  }

  void _confirmOtp() {
    if (!_otpComplete) {
      setState(() => _error = 'Please enter all 6 digits');
      return;
    }
    setState(() { _step = 2; _error = null; });
  }

  // ── Step 2: reset password ────────────────────────────────────────────────
  Future<void> _resetPassword() async {
    final pass    = _passCtrl.text;
    final confirm = _confirmCtrl.text;

    if (pass.length < 8) {
      setState(() => _error = 'Password must be at least 8 characters');
      return;
    }
    if (pass != confirm) {
      setState(() => _error = 'Passwords do not match');
      return;
    }

    setState(() { _loading = true; _error = null; });

    final res = await ApiService.post('/auth/reset-password', {
      'email':       _emailCtrl.text.trim(),
      'otp':         _otpValue,
      'newPassword': pass,
    });

    if (!mounted) return;
    setState(() => _loading = false);

    if (res.containsKey('error')) {
      setState(() => _error = res['error'] as String?);
      return;
    }

    // Success — pop back to login
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Password reset successfully! Please sign in.',
            style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
        backgroundColor: AppColors.brandGreen,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        margin: const EdgeInsets.all(16),
      ));
      Navigator.pop(context);
    }
  }

  // ── Resend OTP ────────────────────────────────────────────────────────────
  int _resendCountdown = 0;

  Future<void> _resendOtp() async {
    setState(() { _resendCountdown = 60; _error = null; });
    await ApiService.post('/auth/forgot-password', {
      'email': _emailCtrl.text.trim(),
    });
    for (int i = 59; i >= 0; i--) {
      await Future.delayed(const Duration(seconds: 1));
      if (mounted) setState(() => _resendCountdown = i);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.bgDark : AppColors.bg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, size: 18),
          onPressed: () {
            if (_step > 0) {
              setState(() { _step--; _error = null; });
            } else {
              Navigator.pop(context);
            }
          },
          style: IconButton.styleFrom(
            backgroundColor: isDark ? AppColors.surfaceVariantDark : AppColors.surfaceVariant,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            transitionBuilder: (child, anim) => FadeTransition(
              opacity: anim,
              child: SlideTransition(
                position: Tween(begin: const Offset(0.05, 0), end: Offset.zero).animate(anim),
                child: child,
              ),
            ),
            child: KeyedSubtree(
              key: ValueKey(_step),
              child: _buildStep(isDark),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStep(bool isDark) {
    switch (_step) {
      case 0:  return _buildEmailStep(isDark);
      case 1:  return _buildOtpStep(isDark);
      default: return _buildNewPasswordStep(isDark);
    }
  }

  // ── Step 0 UI ─────────────────────────────────────────────────────────────
  Widget _buildEmailStep(bool isDark) {
    return Form(
      key: _emailFormKey,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const SizedBox(height: 24),
        _stepIcon('🔑', AppColors.brandBlue),
        const SizedBox(height: 24),
        Text('Forgot password?', style: GoogleFonts.inter(
          fontSize: 28, fontWeight: FontWeight.w800, letterSpacing: -0.5,
          color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
        )),
        const SizedBox(height: 8),
        Text("Enter your email and we'll send a verification code.",
          style: GoogleFonts.inter(fontSize: 14, color: AppColors.textSecondary, height: 1.5)),
        const SizedBox(height: 32),
        _stepIndicator(0),
        const SizedBox(height: 28),
        AppTextField(
          controller: _emailCtrl,
          label: 'Email address',
          hint: 'you@example.com',
          icon: Icons.email_outlined,
          keyboardType: TextInputType.emailAddress,
          validator: (v) {
            if (v == null || v.isEmpty) return 'Enter your email';
            if (!RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(v.trim())) {
              return 'Enter a valid email';
            }
            return null;
          },
        ),
        if (_error != null) ...[
          const SizedBox(height: 12),
          _errorBox(_error!),
        ],
        const SizedBox(height: 24),
        AppButton(label: 'Send Code', onTap: _sendOtp, loading: _loading),
        const SizedBox(height: 32),
      ]),
    );
  }

  // ── Step 1 UI ─────────────────────────────────────────────────────────────
  Widget _buildOtpStep(bool isDark) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const SizedBox(height: 24),
      _stepIcon('📧', AppColors.amber),
      const SizedBox(height: 24),
      Text('Check your email', style: GoogleFonts.inter(
        fontSize: 28, fontWeight: FontWeight.w800, letterSpacing: -0.5,
        color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
      )),
      const SizedBox(height: 8),
      Text('We sent a 6-digit code to\n${_emailCtrl.text.trim()}',
        style: GoogleFonts.inter(fontSize: 14, color: AppColors.textSecondary, height: 1.5)),
      const SizedBox(height: 32),
      _stepIndicator(1),
      const SizedBox(height: 28),

      // OTP boxes
      Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(6, (i) => Padding(
          padding: const EdgeInsets.symmetric(horizontal: 5),
          child: SizedBox(
            width: 46, height: 54,
            child: TextField(
              controller: _otpControllers[i],
              focusNode: _focusNodes[i],
              textAlign: TextAlign.center,
              keyboardType: TextInputType.number,
              maxLength: 1,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              style: GoogleFonts.inter(fontSize: 22, fontWeight: FontWeight.w700),
              decoration: InputDecoration(
                counterText: '',
                filled: true,
                fillColor: isDark ? AppColors.surfaceDark : AppColors.surface,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: isDark ? AppColors.borderDark : AppColors.border),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: isDark ? AppColors.borderDark : AppColors.border),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.brandBlue, width: 2),
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 14),
              ),
              onChanged: (v) {
                _onOtpChanged(i, v);
                setState(() {});
              },
            ),
          ),
        )),
      ),

      if (_devOtp != null) ...[
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.amber.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.amber.withOpacity(0.3)),
          ),
          child: Row(children: [
            const Icon(Icons.info_outline, color: AppColors.amber, size: 16),
            const SizedBox(width: 8),
            Text('Dev code: ', style: GoogleFonts.inter(fontSize: 13, color: AppColors.amber)),
            Text(_devOtp!, style: GoogleFonts.inter(
              fontSize: 13, fontWeight: FontWeight.w800, color: AppColors.amber, letterSpacing: 2)),
          ]),
        ),
      ],

      if (_error != null) ...[
        const SizedBox(height: 12),
        _errorBox(_error!),
      ],
      const SizedBox(height: 24),

      AppButton(
        label: 'Continue',
        onTap: _otpComplete ? _confirmOtp : null,
        loading: false,
      ),
      const SizedBox(height: 16),

      // Resend
      Center(child: Row(mainAxisSize: MainAxisSize.min, children: [
        Text("Didn't get it? ", style: GoogleFonts.inter(
          color: AppColors.textSecondary, fontSize: 14)),
        if (_resendCountdown > 0)
          Text('Resend in ${_resendCountdown}s', style: GoogleFonts.inter(
            color: AppColors.textSecondary, fontSize: 14))
        else
          GestureDetector(
            onTap: _resendOtp,
            child: Text('Resend', style: GoogleFonts.inter(
              color: AppColors.brandBlue, fontSize: 14, fontWeight: FontWeight.w700)),
          ),
      ])),
      const SizedBox(height: 32),
    ]);
  }

  // ── Step 2 UI ─────────────────────────────────────────────────────────────
  Widget _buildNewPasswordStep(bool isDark) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const SizedBox(height: 24),
      _stepIcon('🔒', AppColors.brandGreen),
      const SizedBox(height: 24),
      Text('New password', style: GoogleFonts.inter(
        fontSize: 28, fontWeight: FontWeight.w800, letterSpacing: -0.5,
        color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
      )),
      const SizedBox(height: 8),
      Text('Choose a strong password for your account.',
        style: GoogleFonts.inter(fontSize: 14, color: AppColors.textSecondary, height: 1.5)),
      const SizedBox(height: 32),
      _stepIndicator(2),
      const SizedBox(height: 28),

      AppTextField(
        controller: _passCtrl,
        label: 'New password',
        hint: '••••••••',
        icon: Icons.lock_outline,
        obscure: _obscurePass,
        suffix: IconButton(
          onPressed: () => setState(() => _obscurePass = !_obscurePass),
          icon: Icon(_obscurePass ? Icons.visibility_outlined : Icons.visibility_off_outlined,
            color: AppColors.textSecondary, size: 20),
        ),
      ),
      const SizedBox(height: 14),
      AppTextField(
        controller: _confirmCtrl,
        label: 'Confirm password',
        hint: '••••••••',
        icon: Icons.lock_outline,
        obscure: _obscureConfirm,
        suffix: IconButton(
          onPressed: () => setState(() => _obscureConfirm = !_obscureConfirm),
          icon: Icon(_obscureConfirm ? Icons.visibility_outlined : Icons.visibility_off_outlined,
            color: AppColors.textSecondary, size: 20),
        ),
      ),

      if (_error != null) ...[
        const SizedBox(height: 12),
        _errorBox(_error!),
      ],
      const SizedBox(height: 24),

      AppButton(label: 'Reset Password', onTap: _resetPassword, loading: _loading),
      const SizedBox(height: 32),
    ]);
  }

  // ── Shared widgets ────────────────────────────────────────────────────────
  Widget _stepIcon(String emoji, Color color) => Container(
    width: 72, height: 72,
    decoration: BoxDecoration(
      color: color.withOpacity(0.12),
      shape: BoxShape.circle,
    ),
    child: Center(child: Text(emoji, style: const TextStyle(fontSize: 34))),
  );

  Widget _errorBox(String message) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
    decoration: BoxDecoration(
      color: AppColors.accent.withOpacity(0.08),
      borderRadius: BorderRadius.circular(10),
      border: Border.all(color: AppColors.accent.withOpacity(0.25)),
    ),
    child: Row(children: [
      const Icon(Icons.error_outline, color: AppColors.accent, size: 16),
      const SizedBox(width: 8),
      Expanded(child: Text(message, style: GoogleFonts.inter(
        fontSize: 13, color: AppColors.accent))),
    ]),
  );

  Widget _stepIndicator(int active) => Row(
    mainAxisAlignment: MainAxisAlignment.center,
    children: List.generate(3, (i) => AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      margin: const EdgeInsets.symmetric(horizontal: 4),
      width: i == active ? 24 : 8,
      height: 8,
      decoration: BoxDecoration(
        color: i == active
            ? AppColors.brandBlue
            : AppColors.brandBlue.withOpacity(0.25),
        borderRadius: BorderRadius.circular(4),
      ),
    )),
  );
}
