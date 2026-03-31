import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pin_code_fields/pin_code_fields.dart';
import 'package:provider/provider.dart';
import '../../services/auth_provider.dart';
import '../../services/otp_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_button.dart';
import '../main_nav_screen.dart';

class OtpVerificationScreen extends StatefulWidget {
  final String email;
  final String? devOtp; // shown when email not configured

  const OtpVerificationScreen({super.key, required this.email, this.devOtp});
  @override
  State<OtpVerificationScreen> createState() => _OtpVerificationScreenState();
}

class _OtpVerificationScreenState extends State<OtpVerificationScreen> {
  final _otpCtrl = TextEditingController();
  bool _loading = false;
  bool _resending = false;
  int _countdown = 60;
  Timer? _timer;
  String _otp = '';

  @override
  void initState() {
    super.initState();
    _startCountdown();
  }

  void _startCountdown() {
    _countdown = 60;
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_countdown > 0) setState(() => _countdown--);
      else _timer?.cancel();
    });
  }

  @override
  void dispose() { _timer?.cancel(); _otpCtrl.dispose(); super.dispose(); }

  Future<void> _verify() async {
    if (_otp.length < 6) {
      _showError('Please enter the 6-digit code');
      return;
    }
    setState(() => _loading = true);
    await Future.delayed(const Duration(milliseconds: 500));
    if (!mounted) return;

    final error = context.read<AuthProvider>().verifyOtpAndRegister(widget.email, _otp);
    setState(() => _loading = false);

    if (error != null) {
      _showError(error);
    } else {
      Navigator.pushAndRemoveUntil(context,
        MaterialPageRoute(builder: (_) => const MainNavScreen()),
        (route) => false,
      );
    }
  }

  Future<void> _resend() async {
    setState(() => _resending = true);
    final result = await OtpService.sendOtp(widget.email);
    setState(() => _resending = false);
    _startCountdown();
    if (result == null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: const Text('New OTP sent to your email!'),
        backgroundColor: AppColors.primary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ));
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: AppColors.accent,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: isDark ? AppColors.bgDark : AppColors.bg,
      appBar: AppBar(
        leading: IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.arrow_back_ios, size: 18)),
        backgroundColor: isDark ? AppColors.surfaceDark : AppColors.surface,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const SizedBox(height: 16),
          // Icon
          Container(
            width: 64, height: 64,
            decoration: BoxDecoration(color: AppColors.primaryLight, borderRadius: BorderRadius.circular(20)),
            child: const Center(child: Text('📧', style: TextStyle(fontSize: 32))),
          ),
          const SizedBox(height: 24),
          Text('Check your email', style: GoogleFonts.inter(fontSize: 28, fontWeight: FontWeight.w800, color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary, letterSpacing: -0.5)),
          const SizedBox(height: 8),
          Text.rich(TextSpan(children: [
            TextSpan(text: 'We sent a 6-digit code to\n', style: GoogleFonts.inter(fontSize: 15, color: AppColors.textSecondary)),
            TextSpan(text: widget.email, style: GoogleFonts.inter(fontSize: 15, color: AppColors.primary, fontWeight: FontWeight.w600)),
          ])),

          // Dev mode OTP display
          if (widget.devOtp != null) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(color: AppColors.amberLight, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.amber.withOpacity(0.3))),
              child: Row(children: [
                const Text('⚠️', style: TextStyle(fontSize: 18)),
                const SizedBox(width: 10),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Dev Mode — Email not configured', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.amber)),
                  const SizedBox(height: 2),
                  Text.rich(TextSpan(children: [
                    TextSpan(text: 'Your OTP: ', style: GoogleFonts.inter(fontSize: 13, color: AppColors.textSecondary)),
                    TextSpan(text: widget.devOtp!, style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.textPrimary, letterSpacing: 4)),
                  ])),
                  const SizedBox(height: 4),
                  Text('See otp_service.dart to configure real email', style: GoogleFonts.inter(fontSize: 11, color: AppColors.textSecondary)),
                ])),
              ]),
            ),
          ],

          const SizedBox(height: 40),

          // OTP input
          PinCodeTextField(
            appContext: context,
            length: 6,
            controller: _otpCtrl,
            onChanged: (v) => setState(() => _otp = v),
            onCompleted: (_) => _verify(),
            keyboardType: TextInputType.number,
            animationType: AnimationType.scale,
            pinTheme: PinTheme(
              shape: PinCodeFieldShape.box,
              borderRadius: BorderRadius.circular(12),
              fieldHeight: 56,
              fieldWidth: 46,
              activeFillColor: isDark ? AppColors.surfaceVariantDark : AppColors.surfaceVariant,
              selectedFillColor: isDark ? AppColors.surfaceVariantDark : AppColors.surface,
              inactiveFillColor: isDark ? AppColors.surfaceVariantDark : AppColors.surfaceVariant,
              activeColor: AppColors.primary,
              selectedColor: AppColors.primary,
              inactiveColor: isDark ? AppColors.borderDark : AppColors.border,
            ),
            enableActiveFill: true,
            textStyle: GoogleFonts.inter(fontSize: 22, fontWeight: FontWeight.w800, color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary),
          ),

          const SizedBox(height: 32),
          AppButton(label: 'Verify Email', onTap: _verify, loading: _loading),
          const SizedBox(height: 24),

          // Resend
          Center(child: _countdown > 0
            ? Text.rich(TextSpan(children: [
                TextSpan(text: "Resend code in ", style: GoogleFonts.inter(color: AppColors.textSecondary, fontSize: 14)),
                TextSpan(text: "${_countdown}s", style: GoogleFonts.inter(color: AppColors.primary, fontSize: 14, fontWeight: FontWeight.w600)),
              ]))
            : _resending
              ? const CircularProgressIndicator()
              : GestureDetector(
                  onTap: _resend,
                  child: Text("Didn't receive it? Resend",
                    style: GoogleFonts.inter(color: AppColors.primary, fontSize: 14, fontWeight: FontWeight.w600,
                      decoration: TextDecoration.underline, decorationColor: AppColors.primary)),
                ),
          ),
        ]),
      ),
    );
  }
}
