import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../services/auth_provider.dart';
import '../../services/otp_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_button.dart';
import 'trainer_pending_screen.dart';

// ─────────────────────────────────────────────────────────────────────────────
// TrainerOtpScreen
//
// Identical UX to OtpVerificationScreen but after successful verification
// routes to TrainerPendingScreen instead of MainNavScreen.
// ─────────────────────────────────────────────────────────────────────────────
class TrainerOtpScreen extends StatefulWidget {
  final String  email;
  final String? devOtp;

  const TrainerOtpScreen({super.key, required this.email, this.devOtp});

  @override
  State<TrainerOtpScreen> createState() => _TrainerOtpScreenState();
}

class _TrainerOtpScreenState extends State<TrainerOtpScreen> {
  final _ctrls   = List.generate(6, (_) => TextEditingController());
  final _nodes   = List.generate(6, (_) => FocusNode());
  bool  _loading = false;
  String? _error;
  int   _countdown = 0;

  @override
  void dispose() {
    for (final c in _ctrls) {
      c.dispose();
    }
    for (final n in _nodes) {
      n.dispose();
    }
    super.dispose();
  }

  String get _otp        => _ctrls.map((c) => c.text).join();
  bool   get _isComplete => _otp.length == 6;

  void _onChanged(int i, String v) {
    if (v.isEmpty && i > 0) {
      _nodes[i - 1].requestFocus();
    } else if (v.isNotEmpty && i < 5) {
      _nodes[i + 1].requestFocus();
    } else if (v.isNotEmpty) {
      _nodes[i].unfocus();
    }
    setState(() {});
  }

  Future<void> _verify() async {
    if (!_isComplete) { setState(() => _error = 'Enter all 6 digits'); return; }
    setState(() { _loading = true; _error = null; });

    final valid = await OtpService.verifyOtp(widget.email, _otp);
    if (!mounted) return;
    if (!valid) {
      setState(() { _loading = false; _error = 'Invalid or expired code. Try again.'; });
      return;
    }

    final err = await context.read<AuthProvider>().completeTrainerRegistrationAfterOtp(widget.email);
    if (!mounted) return;

    if (err == null) {
      // Trainer is now registered but pending — go to pending screen
      Navigator.pushAndRemoveUntil(context,
        MaterialPageRoute(builder: (_) => const TrainerPendingScreen()),
        (r) => false,
      );
    } else {
      setState(() { _loading = false; _error = err; });
    }
  }

  Future<void> _resend() async {
    setState(() => _countdown = 60);
    for (int i = 60; i > 0; i--) {
      await Future.delayed(const Duration(seconds: 1));
      if (mounted) setState(() => _countdown = i - 1);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.bgDark : AppColors.bg,
      appBar: AppBar(
        backgroundColor: Colors.transparent, elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, size: 18),
          onPressed: () => Navigator.pop(context),
          style: IconButton.styleFrom(
            backgroundColor: isDark ? AppColors.surfVarDark : AppColors.surfaceVar,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        ),
      ),
      body: SafeArea(child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(children: [
          const SizedBox(height: 24),

          // Icon
          Container(
            width: 80, height: 80,
            decoration: BoxDecoration(
              color: AppColors.brandGreen.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Center(child: Text('📧', style: TextStyle(fontSize: 40))),
          ),
          const SizedBox(height: 24),

          Text('Verify your email', style: GoogleFonts.inter(
            fontSize: 26, fontWeight: FontWeight.w800,
            color: isDark ? AppColors.textPriDark : AppColors.textPri,
          )),
          const SizedBox(height: 8),
          Text('We sent a 6-digit code to\n${widget.email}',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(fontSize: 14,
                color: isDark ? AppColors.textSecDark : AppColors.textSec, height: 1.5)),
          const SizedBox(height: 32),

          // OTP boxes
          Row(mainAxisAlignment: MainAxisAlignment.center, children: List.generate(6, (i) =>
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 5),
              child: SizedBox(width: 46, height: 54,
                child: TextField(
                  controller:  _ctrls[i],
                  focusNode:   _nodes[i],
                  textAlign:   TextAlign.center,
                  keyboardType: TextInputType.number,
                  maxLength:   1,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  onChanged:   (v) => _onChanged(i, v),
                  style: GoogleFonts.inter(fontSize: 22, fontWeight: FontWeight.w700),
                  decoration: InputDecoration(
                    counterText: '',
                    filled:      true,
                    fillColor:   isDark ? AppColors.surfDark : AppColors.surface,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: isDark ? AppColors.borderDark : AppColors.border),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: isDark ? AppColors.borderDark : AppColors.border),
                    ),
                    focusedBorder: const OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(12)),
                      borderSide: BorderSide(color: AppColors.brandGreen, width: 2),
                    ),
                  ),
                ),
              ),
            ),
          )),
          const SizedBox(height: 20),

          // Error
          if (_error != null)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.accent.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.accent.withOpacity(0.3)),
              ),
              child: Row(children: [
                const Icon(Icons.error_outline, color: AppColors.accent, size: 18),
                const SizedBox(width: 8),
                Expanded(child: Text(_error!, style: GoogleFonts.inter(
                  fontSize: 13, color: AppColors.accent))),
              ]),
            ),

          // Dev OTP
          if (widget.devOtp != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.amber.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.amber.withOpacity(0.3)),
              ),
              child: Column(children: [
                Text('Dev Mode — Test Code:', style: GoogleFonts.inter(fontSize: 12, color: AppColors.amber)),
                const SizedBox(height: 4),
                Text(widget.devOtp!, style: GoogleFonts.inter(
                  fontSize: 22, fontWeight: FontWeight.w800, color: AppColors.amber, letterSpacing: 4)),
              ]),
            ),
          ],
          const SizedBox(height: 28),

          AppButton(
            label:   'Verify & Submit Application',
            onTap:   _isComplete ? _verify : null,
            loading: _loading,
            color:   AppColors.brandGreen,
          ),
          const SizedBox(height: 16),

          // Resend
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            Text("Didn't receive the code? ",
              style: GoogleFonts.inter(color: AppColors.textSec, fontSize: 13)),
            _countdown > 0
                ? Text('Resend in ${_countdown}s', style: GoogleFonts.inter(
                    color: AppColors.textSec, fontSize: 13))
                : GestureDetector(
                    onTap: _resend,
                    child: Text('Resend', style: GoogleFonts.inter(
                      color: AppColors.brandGreen, fontSize: 13, fontWeight: FontWeight.w700)),
                  ),
          ]),
          const SizedBox(height: 28),

          // What happens next
          _WhatHappensNext(),
        ]),
      )),
    );
  }
}

class _WhatHappensNext extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.brandGreen.withOpacity(0.07),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.brandGreen.withOpacity(0.2)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          const Icon(Icons.info_outline, color: AppColors.brandGreen, size: 16),
          const SizedBox(width: 8),
          Text('What happens next?', style: GoogleFonts.inter(
            fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.brandGreen,
          )),
        ]),
        const SizedBox(height: 10),
        ...[
          ('1.', 'Your email gets verified now'),
          ('2.', 'Our team reviews your document (1–2 days)'),
          ('3.', 'You get notified once approved'),
          ('4.', 'Start hosting sessions and earning!'),
        ].map(((String n, String t) step) => Padding(
          padding: const EdgeInsets.only(bottom: 7),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(step.$1, style: GoogleFonts.inter(
              fontSize: 12, fontWeight: FontWeight.w800, color: AppColors.brandGreen,
            )),
            const SizedBox(width: 8),
            Expanded(child: Text(step.$2, style: GoogleFonts.inter(
              fontSize: 12, color: isDark ? AppColors.textSecDark : AppColors.textSec,
            ))),
          ]),
        )),
      ]),
    );
  }
}
