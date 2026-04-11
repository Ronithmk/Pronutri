import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../services/auth_provider.dart';
import '../../services/api_service.dart';
import '../../theme/app_theme.dart';
import '../trainer_dashboard_screen.dart';
import 'login_screen.dart';

// ─────────────────────────────────────────────────────────────────────────────
// TrainerPendingScreen
//
// Shown to a trainer after registration + document upload, while our team
// manually verifies their credentials. Also shown on app launch if a trainer
// is still in 'pending' state.
// ─────────────────────────────────────────────────────────────────────────────
class TrainerPendingScreen extends StatefulWidget {
  const TrainerPendingScreen({super.key});
  @override
  State<TrainerPendingScreen> createState() => _TrainerPendingScreenState();
}

class _TrainerPendingScreenState extends State<TrainerPendingScreen>
    with TickerProviderStateMixin {
  // Entrance animation
  late AnimationController _enterCtrl;
  late Animation<double>   _enterFade;
  late Animation<Offset>   _enterSlide;

  // Pulsing review icon
  late AnimationController _pulseCtrl;
  late Animation<double>   _pulseScale;

  // Orbiting dots around the icon
  late AnimationController _orbitCtrl;

  @override
  void initState() {
    super.initState();

    _enterCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 700));
    _enterFade = CurvedAnimation(parent: _enterCtrl, curve: Curves.easeOut);
    _enterSlide = Tween(begin: const Offset(0, 0.06), end: Offset.zero)
        .animate(CurvedAnimation(parent: _enterCtrl, curve: Curves.easeOut));

    _pulseCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1800))
      ..repeat(reverse: true);
    _pulseScale = Tween(begin: 0.92, end: 1.08).animate(
        CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut));

    _orbitCtrl = AnimationController(
        vsync: this, duration: const Duration(seconds: 4))
      ..repeat();

    _enterCtrl.forward();

    // Attach a listener so navigation happens the moment the status flips
    // to 'approved' — regardless of what triggered the change.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<AuthProvider>().addListener(_onAuthChanged);
      _checkStatus();
    });
    _startStatusPolling();
  }

  /// Called whenever AuthProvider notifies. If the trainer is now approved,
  /// navigate immediately to the dashboard.
  void _onAuthChanged() {
    if (!mounted) return;
    final user = context.read<AuthProvider>().currentUser;
    if (user?.isTrainerApproved == true) {
      _pollTimer?.cancel();
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const TrainerDashboardScreen()),
        (r) => false,
      );
    }
  }

  Timer? _pollTimer;
  bool _checking = false;

  Future<void> _checkStatus() async {
    if (!mounted || _checking) return;
    setState(() => _checking = true);
    try {
      final res = await ApiService.get('/auth/trainer-status');
      if (!mounted) return;

      if (res.containsKey('error')) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(res['error'] as String? ?? 'Failed to check status.'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: Colors.redAccent,
          ),
        );
      } else {
        final status = (res['trainer_status'] as String? ?? '').trim().toLowerCase();
        if (status == 'approved') {
          // Update the auth provider — _onAuthChanged will handle navigation.
          await context.read<AuthProvider>().refreshTrainerStatus('approved');
          // _onAuthChanged fires from notifyListeners and navigates — return early.
          return;
        }
        // Still pending or rejected — no action needed beyond resetting button.
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Network error. Check your connection and try again.'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
    if (mounted) setState(() => _checking = false);
  }

  void _startStatusPolling() {
    _pollTimer = Timer.periodic(const Duration(seconds: 30), (_) => _checkStatus());
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    // Safe remove: provider may already be disposed on logout
    try { context.read<AuthProvider>().removeListener(_onAuthChanged); } catch (_) {}
    _enterCtrl.dispose();
    _pulseCtrl.dispose();
    _orbitCtrl.dispose();
    super.dispose();
  }

  Future<void> _logout(BuildContext ctx) async {
    await ctx.read<AuthProvider>().logout();
    if (!ctx.mounted) return;
    Navigator.pushAndRemoveUntil(ctx,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (r) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final user   = context.watch<AuthProvider>().currentUser;

    return Scaffold(
      backgroundColor: isDark ? AppColors.bgDark : AppColors.bg,
      body: SafeArea(
        child: FadeTransition(
          opacity: _enterFade,
          child: SlideTransition(
            position: _enterSlide,
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(children: [
                const SizedBox(height: 20),

                // ── Top bar ────────────────────────────────────────────
                Row(children: [
                  // ProNutri brand mark
                  Text.rich(TextSpan(children: [
                    TextSpan(text: 'Pro', style: GoogleFonts.inter(
                      fontSize: 18, fontWeight: FontWeight.w900,
                      color: AppColors.brandBlue)),
                    TextSpan(text: 'Nutri', style: GoogleFonts.inter(
                      fontSize: 18, fontWeight: FontWeight.w900,
                      color: AppColors.brandGreen)),
                  ])),
                  const Spacer(),
                  // Sign out
                  TextButton.icon(
                    onPressed: () => _logout(context),
                    icon: const Icon(Icons.logout, size: 15),
                    label: Text('Sign out', style: GoogleFonts.inter(
                      fontSize: 13, fontWeight: FontWeight.w600)),
                    style: TextButton.styleFrom(
                        foregroundColor: isDark ? AppColors.textSecDark : AppColors.textSec),
                  ),
                ]),

                const SizedBox(height: 32),

                // ── Animated review graphic ────────────────────────────
                SizedBox(
                  width: 180, height: 180,
                  child: Stack(alignment: Alignment.center, children: [
                    // Orbiting dots
                    AnimatedBuilder(
                      animation: _orbitCtrl,
                      builder: (_, __) {
                        final angle = _orbitCtrl.value * 2 * 3.14159;
                        return Stack(alignment: Alignment.center, children: [
                          _OrbitDot(angle: angle,             radius: 76, color: AppColors.brandGreen),
                          _OrbitDot(angle: angle + 2.094,     radius: 76, color: AppColors.amber),
                          _OrbitDot(angle: angle + 4.189,     radius: 76, color: AppColors.brandBlue),
                        ]);
                      },
                    ),

                    // Pulsing background circle
                    ScaleTransition(
                      scale: _pulseScale,
                      child: Container(
                        width: 120, height: 120,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.amber.withOpacity(0.12),
                          border: Border.all(
                              color: AppColors.amber.withOpacity(0.3), width: 2),
                        ),
                      ),
                    ),

                    // Center icon
                    Container(
                      width: 88, height: 88,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.amber.withOpacity(0.18),
                      ),
                      child: const Center(
                        child: Text('📋', style: TextStyle(fontSize: 40)),
                      ),
                    ),
                  ]),
                ),
                const SizedBox(height: 36),

                // ── Status badge ───────────────────────────────────────
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                  decoration: BoxDecoration(
                    color: AppColors.amber.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.amber.withOpacity(0.4)),
                  ),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Container(
                      width: 8, height: 8,
                      decoration: const BoxDecoration(
                          color: AppColors.amber, shape: BoxShape.circle),
                    ),
                    const SizedBox(width: 7),
                    Text('Application Under Review', style: GoogleFonts.inter(
                      fontSize: 12, fontWeight: FontWeight.w700,
                      color: AppColors.amber,
                    )),
                  ]),
                ),
                const SizedBox(height: 20),

                // ── Headline ───────────────────────────────────────────
                Text(
                  'Almost there,\n${user?.name.split(' ').first ?? 'Trainer'}! 👋',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    fontSize: 28, fontWeight: FontWeight.w800, letterSpacing: -0.5,
                    height: 1.2,
                    color: isDark ? AppColors.textPriDark : AppColors.textPri,
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  'Our team is verifying your credentials. '
                  'You\'ll receive an email notification once approved — '
                  'usually within 1–2 business days.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    fontSize: 14, height: 1.6,
                    color: isDark ? AppColors.textSecDark : AppColors.textSec,
                  ),
                ),
                const SizedBox(height: 32),

                // ── Timeline steps ─────────────────────────────────────
                _ReviewTimeline(isDark: isDark),
                const SizedBox(height: 32),

                // ── What to do while waiting ───────────────────────────
                _WaitingCard(isDark: isDark),

                const SizedBox(height: 32),

                // ── Manual check button ────────────────────────────────
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: _checking ? null : _checkStatus,
                      icon: _checking
                          ? const SizedBox(width: 14, height: 14,
                              child: CircularProgressIndicator(strokeWidth: 2))
                          : const Icon(Icons.refresh, size: 16),
                      label: Text(
                        _checking ? 'Checking…' : 'Check Approval Status',
                        style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600),
                      ),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        foregroundColor: AppColors.brandBlue,
                        side: const BorderSide(color: AppColors.brandBlue),
                      ),
                    ),
                  ),
                ),

                // ── Contact support ────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.only(bottom: 24),
                  child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                    Icon(Icons.help_outline,
                        size: 14,
                        color: isDark ? AppColors.textSecDark : AppColors.textSec),
                    const SizedBox(width: 6),
                    Text('Questions? ', style: GoogleFonts.inter(
                      fontSize: 13,
                      color: isDark ? AppColors.textSecDark : AppColors.textSec,
                    )),
                    GestureDetector(
                      onTap: () {},
                      child: Text('Contact support', style: GoogleFonts.inter(
                        fontSize: 13, fontWeight: FontWeight.w700,
                        color: AppColors.brandBlue,
                        decoration: TextDecoration.underline,
                      )),
                    ),
                  ]),
                ),
              ]),
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _OrbitDot  — one dot that orbits the center icon
// ─────────────────────────────────────────────────────────────────────────────
class _OrbitDot extends StatelessWidget {
  final double angle;
  final double radius;
  final Color  color;
  const _OrbitDot({required this.angle, required this.radius, required this.color});

  @override
  Widget build(BuildContext context) {
    return Transform.translate(
      offset: Offset(
        radius * _cos(angle),
        radius * _sin(angle),
      ),
      child: Container(
        width: 10, height: 10,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          boxShadow: [BoxShadow(color: color.withOpacity(0.4), blurRadius: 6)],
        ),
      ),
    );
  }

  double _cos(double a) {
    // Simple cos approximation via Dart math (import-free)
    const pi = 3.14159265358979;
    a = a % (2 * pi);
    double result = 1;
    double term   = 1;
    for (int i = 1; i <= 8; i++) {
      term *= -(a * a) / ((2 * i - 1) * (2 * i));
      result += term;
    }
    return result;
  }

  double _sin(double a) {
    const pi = 3.14159265358979;
    a = a % (2 * pi);
    double result = a;
    double term   = a;
    for (int i = 1; i <= 8; i++) {
      term *= -(a * a) / ((2 * i) * (2 * i + 1));
      result += term;
    }
    return result;
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _ReviewTimeline
// ─────────────────────────────────────────────────────────────────────────────
class _ReviewTimeline extends StatelessWidget {
  final bool isDark;
  const _ReviewTimeline({required this.isDark});

  @override
  Widget build(BuildContext context) {
    final steps = [
      (Icons.check_circle,        AppColors.brandGreen, 'Email Verified',           'Done'),
      (Icons.hourglass_top,       AppColors.amber,      'Document Under Review',    'In progress'),
      (Icons.verified_user,       AppColors.border,     'Account Approved',         'Pending'),
      (Icons.live_tv,             AppColors.border,     'Start Hosting Sessions',   'Soon'),
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfDark : AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: isDark ? AppColors.borderDark : AppColors.border),
      ),
      child: Column(
        children: List.generate(steps.length, (i) {
          final (icon, color, label, status) = steps[i];
          final isLast = i == steps.length - 1;
          return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            // Icon + connector line
            Column(children: [
              Container(
                width: 32, height: 32,
                decoration: BoxDecoration(
                  color: color.withOpacity(color == AppColors.border ? 0.08 : 0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 16),
              ),
              if (!isLast)
                Container(
                  width: 2, height: 28,
                  color: color == AppColors.border
                      ? (isDark ? AppColors.borderDark : AppColors.border)
                      : color.withOpacity(0.3),
                ),
            ]),
            const SizedBox(width: 14),
            Expanded(child: Padding(
              padding: const EdgeInsets.only(top: 5),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(label, style: GoogleFonts.inter(
                  fontSize: 13, fontWeight: FontWeight.w700,
                  color: color == AppColors.border
                      ? (isDark ? AppColors.textSecDark : AppColors.textSec)
                      : (isDark ? AppColors.textPriDark : AppColors.textPri),
                )),
                Text(status, style: GoogleFonts.inter(
                  fontSize: 11, color: color == AppColors.border
                      ? (isDark ? AppColors.textSecDark : AppColors.textHint)
                      : color,
                )),
                if (!isLast) const SizedBox(height: 16),
              ]),
            )),
          ]);
        }),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _WaitingCard  — suggestions while waiting for approval
// ─────────────────────────────────────────────────────────────────────────────
class _WaitingCard extends StatelessWidget {
  final bool isDark;
  const _WaitingCard({required this.isDark});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: AppColors.brandBlue.withOpacity(0.06),
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: AppColors.brandBlue.withOpacity(0.15)),
    ),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('While you wait…', style: GoogleFonts.inter(
        fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.brandBlue,
      )),
      const SizedBox(height: 10),
      ...[
        (Icons.edit_note_outlined,     'Prepare your first session topic & agenda'),
        (Icons.photo_camera_outlined,  'Set up good lighting for your video setup'),
        (Icons.people_outline,         'Think about your target audience & goals'),
        (Icons.notifications_outlined, 'We\'ll email you when your account is approved'),
      ].map(((IconData ic, String text) item) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Icon(item.$1, color: AppColors.brandBlue, size: 16),
          const SizedBox(width: 10),
          Expanded(child: Text(item.$2, style: GoogleFonts.inter(
            fontSize: 12, color: isDark ? AppColors.textSecDark : AppColors.textSec,
            height: 1.4,
          ))),
        ]),
      )),
    ]),
  );
}
