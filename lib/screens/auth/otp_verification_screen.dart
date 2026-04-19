import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../services/auth_provider.dart';
import '../../services/notification_service.dart'; // ✅ FIX: was missing
import '../../services/nutrition_provider.dart';
import '../../services/habit_provider.dart';
import '../../services/meal_plan_provider.dart';
import '../../services/otp_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_button.dart';
import '../main_nav_screen.dart';

class OtpVerificationScreen extends StatefulWidget {
  final String email;
  final String? devOtp;

  const OtpVerificationScreen({
    super.key,
    required this.email,
    this.devOtp,
  });

  @override
  State<OtpVerificationScreen> createState() => _OtpVerificationScreenState();
}

class _OtpVerificationScreenState extends State<OtpVerificationScreen> {
  final List<TextEditingController> _otpControllers =
      List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(6, (_) => FocusNode());
  bool _loading = false;
  String? _error;
  int _resendCountdown = 0;

  @override
  void dispose() {
    for (final ctrl in _otpControllers) {
      ctrl.dispose();
    }
    for (final node in _focusNodes) {
      node.dispose();
    }
    super.dispose();
  }

  String get _otp => _otpControllers.map((c) => c.text).join();
  bool get _isComplete => _otp.length == 6;

  void _onOtpChanged(int index, String value) {
    if (value.isEmpty && index > 0) {
      _focusNodes[index - 1].requestFocus();
    } else if (value.isNotEmpty) {
      if (index < 5) {
        _focusNodes[index + 1].requestFocus();
      } else {
        _focusNodes[index].unfocus();
      }
    }
  }

  Future<void> _verify() async {
    if (!_isComplete) {
      setState(() => _error = 'Please enter all 6 digits');
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    // Capture AuthProvider before the first await to avoid async-gap lint
    final authProvider = context.read<AuthProvider>();

    // Step 1 — Verify OTP via backend
    final isValid = await OtpService.verifyOtp(widget.email, _otp);

    if (!isValid) {
      setState(() {
        _loading = false;
        _error = 'Invalid or expired code. Try again.';
      });
      return;
    }

    // Step 2 — OTP verified, register with backend
    try {

      final result = await authProvider.completeRegistrationAfterOtp(widget.email);

      if (!mounted) return;

      if (result == null) {
        // Success — wire nutrition goals then navigate to MainNavScreen
        NotificationService.saveTokenToBackend(null);
        context.read<NutritionProvider>().setUser(authProvider.currentUser);
        context.read<HabitProvider>().setUser(authProvider.currentUser?.id ?? '');
        context.read<MealPlanProvider>().setUser(authProvider.currentUser?.id ?? '');
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const MainNavScreen()),
          (route) => false,
        );
      } else {
        setState(() {
          _loading = false;
          _error = result;
        });
      }
    } catch (e) {
      setState(() {
        _loading = false;
        _error = 'Registration failed. Please try again.';
      });
    }
  }

  Future<void> _resendOtp() async {
    setState(() => _resendCountdown = 60);
    for (int i = 60; i > 0; i--) {
      await Future.delayed(const Duration(seconds: 1));
      if (mounted) {
        setState(() => _resendCountdown = i - 1);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.bgDark : AppColors.bg,
      appBar: AppBar(
        backgroundColor: isDark ? AppColors.bgDark : AppColors.bg,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, size: 18),
          onPressed: () => Navigator.pop(context),
          style: IconButton.styleFrom(
            backgroundColor: isDark ? AppColors.surfaceVariantDark : AppColors.surfaceVariant,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 32),

              // Email icon
              Container(
                width: 80,
                height: 80,
                decoration: const BoxDecoration(
                  color: AppColors.primaryLight,
                  shape: BoxShape.circle,
                ),
                child: const Center(
                  child: Text('📧', style: TextStyle(fontSize: 44)),
                ),
              ),
              const SizedBox(height: 24),

              // Title
              Text(
                'Verify your email',
                style: GoogleFonts.inter(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),

              // Email display
              Text(
                'We sent a 6-digit code to ${widget.email}',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 32),

              // OTP Input boxes
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(6, (index) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 5),
                    child: SizedBox(
                      width: 46, height: 54,
                      child: TextField(
                        controller: _otpControllers[index],
                        focusNode: _focusNodes[index],
                        textAlign: TextAlign.center,
                        keyboardType: TextInputType.number,
                        maxLength: 1,
                        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
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
                            borderSide: const BorderSide(color: AppColors.primary, width: 2),
                          ),
                          contentPadding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        style: GoogleFonts.inter(fontSize: 22, fontWeight: FontWeight.w700),
                        onChanged: (value) {
                          _onOtpChanged(index, value);
                          setState(() {});
                        },
                      ),
                    ),
                  );
                }),
              ),
              const SizedBox(height: 24),

              // Error message
              if (_error != null)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.accent.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                        color: AppColors.accent.withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline,
                          color: AppColors.accent, size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _error!,
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            color: AppColors.accent,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 16),

              // Dev OTP display
              if (widget.devOtp != null)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.amber.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                        color: AppColors.amber.withOpacity(0.3)),
                  ),
                  child: Column(
                    children: [
                      Text(
                        'Dev Mode - Test Code:',
                        style: GoogleFonts.inter(
                            fontSize: 12, color: AppColors.amber),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        widget.devOtp!,
                        style: GoogleFonts.inter(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: AppColors.amber,
                          letterSpacing: 2,
                        ),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 32),

              // Verify button
              AppButton(
                label: 'Verify & Complete Registration',
                onTap: !_isComplete ? null : () { _verify(); },
                loading: _loading,
              ),
              const SizedBox(height: 16),

              // Resend OTP
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    "Didn't receive the code? ",
                    style: GoogleFonts.inter(
                        color: AppColors.textSecondary, fontSize: 14),
                  ),
                  if (_resendCountdown > 0)
                    Text(
                      'Resend in ${_resendCountdown}s',
                      style: GoogleFonts.inter(
                        color: AppColors.textSecondary,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    )
                  else
                    GestureDetector(
                      onTap: _resendOtp,
                      child: Text(
                        'Resend',
                        style: GoogleFonts.inter(
                          color: AppColors.primary,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 24),

              // Welcome bonus info card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.primaryLight,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color: AppColors.primary.withOpacity(0.2)),
                ),
                child: Row(
                  children: [
                    const Text('🎉', style: TextStyle(fontSize: 24)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Welcome bonus!',
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: AppColors.primaryDark,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '₹100 credits + 30-day free trial after verification',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              color: AppColors.primaryDark,
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}