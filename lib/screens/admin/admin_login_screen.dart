import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../services/api_service.dart';
import '../../services/auth_provider.dart';
import '../../theme/app_theme.dart';
import 'admin_dashboard_screen.dart';

const _adminEmail = 'protoncodeai@gmail.com';

class AdminLoginScreen extends StatefulWidget {
  const AdminLoginScreen({super.key});
  @override
  State<AdminLoginScreen> createState() => _AdminLoginScreenState();
}

class _AdminLoginScreenState extends State<AdminLoginScreen>
    with SingleTickerProviderStateMixin {
  // OTP state
  final List<TextEditingController> _otpCtrl =
      List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _otpFocus = List.generate(6, (_) => FocusNode());

  bool _otpSent   = false;
  bool _loading   = false;
  String? _error;
  String? _devOtp;   // shown on screen in dev mode
  int _resendCountdown = 0;

  late AnimationController _shakeCtrl;
  late Animation<double>   _shakeAnim;

  @override
  void initState() {
    super.initState();
    _shakeCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 400));
    _shakeAnim = Tween(begin: 0.0, end: 1.0)
        .chain(CurveTween(curve: Curves.elasticIn))
        .animate(_shakeCtrl);
  }

  @override
  void dispose() {
    for (final c in _otpCtrl) { c.dispose(); }
    for (final f in _otpFocus) { f.dispose(); }
    _shakeCtrl.dispose();
    super.dispose();
  }

  String get _otp => _otpCtrl.map((c) => c.text).join();
  bool get _otpComplete => _otp.length == 6;

  // ── Step 1: Send OTP ───────────────────────────────────────────────────────
  Future<void> _sendOtp() async {
    setState(() { _loading = true; _error = null; _devOtp = null; });

    try {
      final res = await ApiService.post('/auth/admin-login', {'email': _adminEmail});

      if (res.containsKey('error')) {
        setState(() { _error = res['error']; _loading = false; });
        _shakeCtrl.forward(from: 0);
        return;
      }

      setState(() {
        _otpSent = true;
        _loading = false;
        _devOtp  = res['otp']?.toString(); // non-null only in dev mode
      });
      _startResendCountdown();
    } catch (_) {
      setState(() { _error = 'Network error. Check your connection.'; _loading = false; });
      _shakeCtrl.forward(from: 0);
    }
  }

  // ── Step 2: Verify OTP ────────────────────────────────────────────────────
  Future<void> _verifyOtp() async {
    if (!_otpComplete) return;
    setState(() { _loading = true; _error = null; });

    try {
      final res = await ApiService.post('/auth/admin-login', {
        'email': _adminEmail,
        'otp':   _otp,
      });

      if (res.containsKey('error')) {
        _shakeCtrl.forward(from: 0);
        setState(() { _error = res['error']; _loading = false; });
        return;
      }

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('jwt_token',  res['token']);
      await prefs.setString('uid',        res['uid']);
      await prefs.setString('user_name',  res['name']);
      await prefs.setString('user_email', res['email']);
      await prefs.setString('user_role',  'admin');

      if (!mounted) return;
      context.read<AuthProvider>().setAdminSession(
        uid:   res['uid'],
        name:  res['name'],
        email: res['email'],
        token: res['token'],
      );

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const AdminDashboardScreen()),
        (r) => false,
      );
    } catch (_) {
      setState(() { _error = 'Network error. Check your connection.'; _loading = false; });
      _shakeCtrl.forward(from: 0);
    }
  }

  void _startResendCountdown() async {
    setState(() => _resendCountdown = 60);
    for (int i = 60; i > 0; i--) {
      await Future.delayed(const Duration(seconds: 1));
      if (mounted) setState(() => _resendCountdown = i - 1);
    }
  }

  void _onOtpChanged(int index, String value) {
    if (value.isEmpty && index > 0) {
      _otpFocus[index - 1].requestFocus();
    } else if (value.isNotEmpty && index < 5) {
      _otpFocus[index + 1].requestFocus();
    } else if (value.isNotEmpty && index == 5) {
      _otpFocus[index].unfocus();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.bgDark : AppColors.bg,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(28),
            child: Column(children: [
              // ── Shield icon ───────────────────────────────────────────────
              Container(
                width: 90, height: 90,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.accent.withOpacity(0.10),
                  boxShadow: [
                    BoxShadow(color: AppColors.accent.withOpacity(0.28), blurRadius: 24, offset: const Offset(0, 10)),
                    BoxShadow(color: Colors.white.withOpacity(isDark ? 0.04 : 0.7), blurRadius: 6, offset: const Offset(-2, -2)),
                  ],
                ),
                child: const Center(
                  child: Icon(Icons.admin_panel_settings, color: AppColors.accent, size: 42),
                ),
              ),
              const SizedBox(height: 20),
              Text('Admin Portal', style: GoogleFonts.inter(
                fontSize: 26, fontWeight: FontWeight.w800,
                color: isDark ? AppColors.textPriDark : AppColors.textPri,
                letterSpacing: -0.5,
              )),
              const SizedBox(height: 6),
              Text('ProNutri internal access only',
                  style: GoogleFonts.inter(fontSize: 13,
                    color: isDark ? AppColors.textSecDark : AppColors.textSec)),
              const SizedBox(height: 32),

              // ── Error banner ──────────────────────────────────────────────
              AnimatedSize(
                duration: const Duration(milliseconds: 250),
                child: _error == null
                    ? const SizedBox.shrink()
                    : AnimatedBuilder(
                        animation: _shakeAnim,
                        builder: (_, child) => Transform.translate(
                          offset: Offset(
                            8 * (0.5 - _shakeAnim.value).abs() *
                                (_shakeAnim.value < 0.5 ? -1 : 1),
                            0,
                          ),
                          child: child,
                        ),
                        child: Container(
                          width: double.infinity,
                          margin: const EdgeInsets.only(bottom: 16),
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: AppColors.accent.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppColors.accent.withOpacity(0.3)),
                          ),
                          child: Row(children: [
                            const Icon(Icons.lock_outline,
                                color: AppColors.accent, size: 16),
                            const SizedBox(width: 10),
                            Expanded(child: Text(_error!,
                                style: GoogleFonts.inter(
                                    fontSize: 13, color: AppColors.accent))),
                          ]),
                        ),
                      ),
              ),

              // ── Locked email field ────────────────────────────────────────
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.surfVarDark : Colors.white,
                  borderRadius: BorderRadius.circular(22),
                  boxShadow: [
                    BoxShadow(color: isDark ? Colors.black.withOpacity(0.3) : AppColors.brandBlue.withOpacity(0.08), blurRadius: 16, offset: const Offset(0, 6)),
                    BoxShadow(color: Colors.white.withOpacity(isDark ? 0.04 : 0.9), blurRadius: 4, offset: const Offset(-1, -1)),
                  ],
                ),
                child: Row(children: [
                  const Icon(Icons.email_outlined,
                      color: AppColors.textSec, size: 18),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _adminEmail,
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: isDark ? AppColors.textPriDark : AppColors.textPri,
                      ),
                    ),
                  ),
                  const Icon(Icons.lock, color: AppColors.textSec, size: 16),
                ]),
              ),
              const SizedBox(height: 20),

              // ── OTP section (shown after Send OTP) ───────────────────────
              AnimatedSize(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOut,
                child: _otpSent ? _buildOtpSection(isDark) : const SizedBox.shrink(),
              ),

              // ── Dev OTP hint ──────────────────────────────────────────────
              if (_devOtp != null) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.amber.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.amber.withOpacity(0.3)),
                  ),
                  child: Column(children: [
                    Text('Dev Mode — OTP:', style: GoogleFonts.inter(fontSize: 12, color: AppColors.amber)),
                    const SizedBox(height: 4),
                    Text(_devOtp!, style: GoogleFonts.inter(
                      fontSize: 22, fontWeight: FontWeight.w800,
                      color: AppColors.amber, letterSpacing: 3,
                    )),
                  ]),
                ),
              ],

              const SizedBox(height: 24),

              // ── Primary button ────────────────────────────────────────────
              GestureDetector(
                onTap: _loading ? null : _otpSent ? (_otpComplete ? _verifyOtp : null) : _sendOtp,
                child: Container(
                  width: double.infinity, height: 56,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppColors.accent, Color(0xFFFF8E8E)],
                      begin: Alignment.topLeft, end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(22),
                    boxShadow: (_loading || (_otpSent && !_otpComplete)) ? [] : [
                      BoxShadow(color: AppColors.accent.withOpacity(0.38), blurRadius: 20, offset: const Offset(0, 8)),
                      BoxShadow(color: Colors.white.withOpacity(0.20), blurRadius: 6, offset: const Offset(-2, -2)),
                    ],
                  ),
                  child: Center(child: _loading
                    ? const SizedBox(width: 22, height: 22,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                    : Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                        Icon(_otpSent ? Icons.verified_user : Icons.send_rounded, color: Colors.white, size: 18),
                        const SizedBox(width: 8),
                        Text(
                          _otpSent ? 'Verify & Access Portal' : 'Send OTP to Admin Email',
                          style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w700, color: Colors.white),
                        ),
                      ])),
                ),
              ),

              // ── Resend row ────────────────────────────────────────────────
              if (_otpSent) ...[
                const SizedBox(height: 14),
                Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Text("Didn't receive it? ",
                      style: GoogleFonts.inter(
                          color: AppColors.textSec, fontSize: 13)),
                  if (_resendCountdown > 0)
                    Text('Resend in ${_resendCountdown}s',
                        style: GoogleFonts.inter(
                            color: AppColors.textSec,
                            fontSize: 13,
                            fontWeight: FontWeight.w500))
                  else
                    GestureDetector(
                      onTap: _sendOtp,
                      child: Text('Resend OTP',
                          style: GoogleFonts.inter(
                              color: AppColors.accent,
                              fontSize: 13,
                              fontWeight: FontWeight.w600)),
                    ),
                ]),
              ],

              const SizedBox(height: 16),

              // ── Back ──────────────────────────────────────────────────────
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('← Back to app',
                    style: GoogleFonts.inter(
                        color: isDark ? AppColors.textSecDark : AppColors.textSec,
                        fontSize: 13)),
              ),
              const SizedBox(height: 24),

              // ── Security note ─────────────────────────────────────────────
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.amber.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.amber.withOpacity(0.25)),
                ),
                child: Row(crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  const Icon(Icons.warning_amber_rounded,
                      color: AppColors.amber, size: 15),
                  const SizedBox(width: 8),
                  Expanded(child: Text(
                    'This portal is restricted to ProNutri administrators. '
                    'Unauthorised access attempts are logged.',
                    style: GoogleFonts.inter(
                        fontSize: 11, color: AppColors.amber, height: 1.5),
                  )),
                ]),
              ),
            ]),
          ),
        ),
      ),
    );
  }

  Widget _buildOtpSection(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          'Enter the 6-digit code sent to the admin email',
          textAlign: TextAlign.center,
          style: GoogleFonts.inter(fontSize: 13, color: AppColors.textSec),
        ),
        const SizedBox(height: 16),
        LayoutBuilder(builder: (ctx, constraints) {
          final boxSize = ((constraints.maxWidth - 60) / 6).clamp(40.0, 52.0);
          return Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(6, (i) => Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: SizedBox(
                width: boxSize,
                height: boxSize + 8,
                child: TextField(
                  controller: _otpCtrl[i],
                  focusNode: _otpFocus[i],
                  textAlign: TextAlign.center,
                  keyboardType: TextInputType.number,
                  maxLength: 1,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: InputDecoration(
                    counterText: '',
                    filled: true,
                    fillColor: isDark ? AppColors.surfDark : Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(18),
                      borderSide: BorderSide.none,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(18),
                      borderSide: BorderSide(
                        color: isDark ? AppColors.borderDark : AppColors.border,
                        width: 1,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(18),
                      borderSide: const BorderSide(color: AppColors.accent, width: 2.5),
                    ),
                    contentPadding: EdgeInsets.zero,
                  ),
                  style: GoogleFonts.inter(
                      fontSize: 20, fontWeight: FontWeight.w700),
                  onChanged: (v) {
                    _onOtpChanged(i, v);
                    setState(() {});
                  },
                ),
              ),
            )),
          );
        }),
        const SizedBox(height: 20),
      ],
    );
  }
}
