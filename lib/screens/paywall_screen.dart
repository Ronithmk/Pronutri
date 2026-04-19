import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/payment_service.dart';
import '../theme/app_theme.dart';

class PaywallScreen extends StatefulWidget {
  final String reason; // 'trial_expired' or 'no_credits'
  const PaywallScreen({super.key, required this.reason});
  @override State<PaywallScreen> createState() => _PaywallScreenState();
}

class _PaywallScreenState extends State<PaywallScreen> {
  late PaymentService _payment;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _payment = PaymentService(
      onSuccess: (_) {
        setState(() => _loading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Payment successful! Access restored.'),
            backgroundColor: AppColors.brandGreen));
        Navigator.pop(context, true);
      },
      onFailed: (e) {
        setState(() => _loading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Payment failed: $e'),
            backgroundColor: AppColors.accent));
      },
    );
  }

  @override
  void dispose() { _payment.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final isCredits = widget.reason == 'no_credits';
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(child: SingleChildScrollView(child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Text(isCredits ? '🤖' : '🔓', style: const TextStyle(fontSize: 72)),
          const SizedBox(height: 24),
          Text(isCredits ? 'AI Credits Used Up' : 'Free Trial Ended',
            style: GoogleFonts.inter(fontSize: 26, fontWeight: FontWeight.w800,
              color: AppColors.textPrimary)),
          const SizedBox(height: 12),
          Text(
            isCredits
              ? 'You\'ve used all your AI chat credits.\nTop up ₹100 to get 50 more messages.'
              : 'Your 30-day free trial has ended.\nSubscribe for ₹100/month to continue.',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(fontSize: 15, color: AppColors.textSecondary, height: 1.6)),
          const SizedBox(height: 40),
          // Feature list
          ...['Full app access', 'Unlimited meal logging',
              isCredits ? '50 AI chat messages' : 'Exercise tracking',
              'Progress insights'].map((f) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Row(children: [
              const Icon(Icons.check_circle, color: AppColors.brandGreen, size: 20),
              const SizedBox(width: 10),
              Text(f, style: GoogleFonts.inter(fontSize: 14)),
            ]),
          )),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _loading ? null : () {
                setState(() => _loading = true);
                _payment.startPayment(isCredits ? 'credits' : 'subscription');
              },
              child: _loading
                ? const SizedBox(width: 20, height: 20,
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : Text('Pay ₹100 via UPI / Card',
                    style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w700)),
            ),
          ),
          const SizedBox(height: 12),
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Maybe later',
              style: GoogleFonts.inter(color: AppColors.textSecondary))),
        ]),
      ))),
    );
  }
}