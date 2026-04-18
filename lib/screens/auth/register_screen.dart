import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../data/country_meal_data.dart';
import '../../services/auth_provider.dart';
import '../../theme/app_theme.dart';
import '../../utils/unit_helper.dart';
import 'otp_verification_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});
  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen>
    with TickerProviderStateMixin {
  final _pageCtrl = PageController();
  int _step = 0;
  bool _loading = false;

  final _nameCtrl    = TextEditingController();
  final _emailCtrl   = TextEditingController();
  final _passCtrl    = TextEditingController();
  final _confirmCtrl = TextEditingController();
  final _weightCtrl  = TextEditingController();
  final _heightCtrl  = TextEditingController();
  final _ageCtrl     = TextEditingController();
  final _targetCtrl  = TextEditingController();

  bool _obscure        = true;
  bool _obscureConfirm = true;
  String _gender   = 'male';
  String _goal     = 'maintain';
  String _activity = 'moderate';
  String _country  = 'India';

  final _k1 = GlobalKey<FormState>();
  final _k2 = GlobalKey<FormState>();
  final _k3 = GlobalKey<FormState>();

  late AnimationController _entranceCtrl;
  late Animation<double>   _entranceFade;
  late Animation<Offset>   _entranceSlide;

  @override
  void initState() {
    super.initState();
    _entranceCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 700));
    _entranceFade  = CurvedAnimation(parent: _entranceCtrl, curve: Curves.easeOut);
    _entranceSlide = Tween(begin: const Offset(0, 0.06), end: Offset.zero)
        .animate(CurvedAnimation(parent: _entranceCtrl, curve: Curves.easeOut));
    _entranceCtrl.forward();
  }

  @override
  void dispose() {
    for (final c in [_nameCtrl, _emailCtrl, _passCtrl, _confirmCtrl,
                     _weightCtrl, _heightCtrl, _ageCtrl, _targetCtrl]) {
      c.dispose();
    }
    _pageCtrl.dispose();
    _entranceCtrl.dispose();
    super.dispose();
  }

  double get _bmi {
    final w = double.tryParse(_weightCtrl.text) ?? 0;
    final h = double.tryParse(_heightCtrl.text) ?? 1;
    return w == 0 || h == 0 ? 0 : w / ((h / 100) * (h / 100));
  }

  Color get _bmiColor =>
      _bmi < 18.5 ? AppColors.brandBlue
      : _bmi < 25 ? AppColors.brandGreen
      : _bmi < 30 ? const Color(0xFFF59E0B)
      : const Color(0xFFEF4444);

  String get _bmiCat =>
      _bmi == 0   ? ''
      : _bmi < 18.5 ? 'Underweight'
      : _bmi < 25   ? 'Healthy'
      : _bmi < 30   ? 'Overweight'
      : 'Obese';

  String? _validatePassword(String? v) {
    if (v == null || v.isEmpty) return 'Enter a password';
    if (v.length < 6) return 'At least 6 characters required';
    if (!v.contains(RegExp(r'[0-9]'))) return 'Include at least 1 number';
    if (!v.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>_\-+=~`\[\]\\;/]'))) {
      return 'Include at least 1 special character (e.g. @, #, !)';
    }
    return null;
  }

  void _next() {
    if (_step == 0 && !_k1.currentState!.validate()) return;
    if (_step == 1 && !_k2.currentState!.validate()) return;
    if (_step == 2) { _submit(); return; }
    _pageCtrl.nextPage(
        duration: const Duration(milliseconds: 400), curve: Curves.easeInOut);
    setState(() => _step++);
  }

  void _back() {
    if (_step > 0) {
      setState(() => _step--);
      _pageCtrl.previousPage(
          duration: const Duration(milliseconds: 400), curve: Curves.easeInOut);
    }
  }

  Future<void> _submit() async {
    setState(() => _loading = true);
    final result = await context.read<AuthProvider>().sendRegistrationOtp(
      name:          _nameCtrl.text,
      email:         _emailCtrl.text,
      password:      _passCtrl.text,
      weight:        UnitHelper.parseWeightToKg(_weightCtrl.text, _country),
      height:        UnitHelper.parseHeightToCm(_heightCtrl.text, _country),
      age:           int.tryParse(_ageCtrl.text) ?? 25,
      gender:        _gender,
      goal:          _goal,
      activityLevel: _activity,
      targetWeight:  UnitHelper.parseWeightToKg(
                       _targetCtrl.text.isNotEmpty ? _targetCtrl.text : _weightCtrl.text,
                       _country),
      country:       _country,
    );
    if (!mounted) return;
    setState(() => _loading = false);

    if (result == null) {
      Navigator.push(context, MaterialPageRoute(builder: (_) =>
          OtpVerificationScreen(email: _emailCtrl.text.toLowerCase().trim())));
    } else if (result.startsWith('EMAIL_NOT_CONFIGURED:')) {
      final devOtp = result.split(':')[1];
      Navigator.push(context, MaterialPageRoute(builder: (_) =>
          OtpVerificationScreen(
              email: _emailCtrl.text.toLowerCase().trim(), devOtp: devOtp)));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(result),
        backgroundColor: const Color(0xFFEF4444),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        margin: const EdgeInsets.all(16),
      ));
    }
  }

  // ── Step labels ──────────────────────────────────────────────────────────────
  static const _stepLabels = ['Account', 'Body Stats', 'Goals'];
  static const _stepIcons  = [Icons.person_outline, Icons.monitor_weight_outlined, Icons.flag_outlined];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D1B2A),
      body: Stack(children: [
        // ── Background orbs ──────────────────────────────────────────────────
        const _Orb(top: -80, right: -80, size: 260, color: Color(0xFF1E6EBD), opacity: 0.12),
        const _Orb(bottom: -100, left: -60, size: 300, color: Color(0xFF00C896), opacity: 0.08),
        const _Orb(top: 220, left: -40, size: 180, color: Color(0xFF1E6EBD), opacity: 0.06),

        // ── Grid painter ─────────────────────────────────────────────────────
        Positioned.fill(child: CustomPaint(painter: _GridPainter())),

        SafeArea(
          child: FadeTransition(
            opacity: _entranceFade,
            child: SlideTransition(
              position: _entranceSlide,
              child: Column(children: [
                _buildHeader(),
                Expanded(child: PageView(
                  controller: _pageCtrl,
                  physics: const NeverScrollableScrollPhysics(),
                  children: [_step1(), _step2(), _step3()],
                )),
                _buildFooter(),
              ]),
            ),
          ),
        ),
      ]),
    );
  }

  // ── Header with step indicator ───────────────────────────────────────────────
  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Row(children: [
        // Back button
        GestureDetector(
          onTap: _step > 0
              ? _back
              : () => Navigator.popUntil(context, (r) => r.isFirst),
          child: Container(
            width: 42, height: 42,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.08),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.white.withOpacity(0.12)),
            ),
            child: const Icon(Icons.arrow_back_ios_new_rounded,
                color: Colors.white70, size: 16),
          ),
        ),
        const SizedBox(width: 16),

        // Step pills
        Expanded(child: Row(
          children: List.generate(5, (i) {
            // indices 0,2,4 = pills; 1,3 = chevrons
            if (i.isOdd) {
              final stepIndex = i ~/ 2;
              return Icon(Icons.chevron_right,
                  size: 13,
                  color: stepIndex < _step
                      ? Colors.white38
                      : Colors.white.withOpacity(0.15));
            }
            final si     = i ~/ 2;
            final active = si == _step;
            final done   = si < _step;
            return Expanded(child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              height: 34,
              decoration: BoxDecoration(
                gradient: active
                    ? const LinearGradient(
                        colors: [Color(0xFF1E6EBD), Color(0xFF00C896)],
                        begin: Alignment.centerLeft, end: Alignment.centerRight)
                    : null,
                color: active ? null
                    : done  ? Colors.white.withOpacity(0.12)
                    : Colors.white.withOpacity(0.05),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: active ? Colors.transparent
                      : done  ? Colors.white.withOpacity(0.18)
                      : Colors.white.withOpacity(0.08),
                ),
              ),
              child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                Icon(_stepIcons[si],
                    size: 13,
                    color: active ? Colors.white
                        : done  ? Colors.white70
                        : Colors.white30),
                const SizedBox(width: 4),
                Text(_stepLabels[si],
                  style: GoogleFonts.inter(
                    fontSize: 10.5,
                    fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                    color: active ? Colors.white
                        : done  ? Colors.white70
                        : Colors.white38,
                  )),
              ]),
            ));
          }),
        )),
        const SizedBox(width: 42), // matches back-button width for centered pills
      ]),
    );
  }

  // ── Footer: CTA button + sign-in link ────────────────────────────────────────
  Widget _buildFooter() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
      child: Column(children: [
        // Gradient CTA
        GestureDetector(
          onTap: _loading ? null : _next,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            height: 56,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF1E6EBD), Color(0xFF00C896)],
                begin: Alignment.centerLeft, end: Alignment.centerRight,
              ),
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(
                    color: const Color(0xFF1E6EBD).withOpacity(0.40),
                    blurRadius: 20, offset: const Offset(0, 8)),
              ],
            ),
            child: Center(
              child: _loading
                  ? const SizedBox(
                      width: 22, height: 22,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2.5))
                  : Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                      Text(
                        _step < 2 ? 'Continue' : 'Send Verification Code',
                        style: GoogleFonts.inter(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                            letterSpacing: 0.3),
                      ),
                      const SizedBox(width: 8),
                      Icon(
                        _step < 2 ? Icons.arrow_forward_rounded : Icons.email_outlined,
                        color: Colors.white, size: 18,
                      ),
                    ]),
            ),
          ),
        ),
        const SizedBox(height: 14),
        if (_step == 0)
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            Text('Already have an account? ',
                style: GoogleFonts.inter(
                    color: Colors.white38, fontSize: 14)),
            GestureDetector(
              onTap: () => Navigator.popUntil(context, (r) => r.isFirst),
              child: Text('Sign In',
                  style: GoogleFonts.inter(
                      color: AppColors.brandGreen,
                      fontSize: 14,
                      fontWeight: FontWeight.w700)),
            ),
          ]),
      ]),
    );
  }

  // ── Step 1: Account details ───────────────────────────────────────────────────
  Widget _step1() => SingleChildScrollView(
    padding: const EdgeInsets.fromLTRB(20, 24, 20, 8),
    child: Form(key: _k1, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('Create Account',
          style: GoogleFonts.inter(
              fontSize: 30, fontWeight: FontWeight.w800,
              color: Colors.white, letterSpacing: -0.8)),
      const SizedBox(height: 6),
      Text('Join thousands reaching their health goals',
          style: GoogleFonts.inter(fontSize: 14, color: Colors.white38)),
      const SizedBox(height: 20),

      // Welcome bonus banner
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF1E3A5F), Color(0xFF0D3D2E)],
            begin: Alignment.centerLeft, end: Alignment.centerRight,
          ),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFF00C896).withOpacity(0.25)),
        ),
        child: Row(children: [
          Container(
            width: 44, height: 44,
            decoration: BoxDecoration(
              color: const Color(0xFF00C896).withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: const Center(child: Text('🎁', style: TextStyle(fontSize: 22))),
          ),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Register & Get ₹100 Free Credits!',
                style: GoogleFonts.inter(
                    fontSize: 13, fontWeight: FontWeight.w800, color: Colors.white)),
            const SizedBox(height: 2),
            Text('+ 30-day free trial  ·  No credit card needed',
                style: GoogleFonts.inter(
                    fontSize: 11, color: Colors.white.withOpacity(0.55))),
          ])),
        ]),
      ),
      const SizedBox(height: 20),

      // Glass form card
      _glassCard(child: Column(children: [
        _DarkTextField(ctrl: _nameCtrl, label: 'Full Name', hint: 'Your full name',
            icon: Icons.person_outline,
            validator: (v) => (v?.trim().length ?? 0) < 2 ? 'Enter your name' : null),
        const SizedBox(height: 14),
        _DarkTextField(ctrl: _emailCtrl, label: 'Email Address', hint: 'you@example.com',
            icon: Icons.email_outlined,
            keyboardType: TextInputType.emailAddress,
            validator: (v) => (v == null || !v.contains('@')) ? 'Enter a valid email' : null),
        const SizedBox(height: 14),
        _DarkTextField(ctrl: _passCtrl, label: 'Password',
            hint: 'Min 6 chars, 1 number, 1 symbol',
            icon: Icons.lock_outline,
            obscure: _obscure,
            validator: _validatePassword,
            suffix: IconButton(
              onPressed: () => setState(() => _obscure = !_obscure),
              icon: Icon(
                _obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                color: Colors.white38, size: 20),
            )),
        const SizedBox(height: 14),
        _DarkTextField(ctrl: _confirmCtrl, label: 'Confirm Password',
            hint: 'Repeat password',
            icon: Icons.lock_outline,
            obscure: _obscureConfirm,
            validator: (v) => v != _passCtrl.text ? 'Passwords do not match' : null,
            suffix: IconButton(
              onPressed: () => setState(() => _obscureConfirm = !_obscureConfirm),
              icon: Icon(
                _obscureConfirm ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                color: Colors.white38, size: 20),
            )),
        const SizedBox(height: 14),
        // ── Country picker ───────────────────────────────────────
        GestureDetector(
          onTap: () => _pickCountry(),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.06),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.white.withOpacity(0.10)),
            ),
            child: Row(children: [
              const Icon(Icons.public, color: Colors.white38, size: 20),
              const SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Country',
                    style: GoogleFonts.inter(fontSize: 13, color: Colors.white38)),
                const SizedBox(height: 2),
                Text(
                  '${kCountryList.firstWhere((c) => c.$1 == _country, orElse: () => ('India', '🇮🇳', 'India')).$2}  $_country',
                  style: GoogleFonts.inter(fontSize: 14, color: Colors.white),
                ),
              ])),
              const Icon(Icons.keyboard_arrow_down_rounded, color: Colors.white38, size: 22),
            ]),
          ),
        ),
      ])),
    ])),
  );

  void _pickCountry() {
    final searchCtrl = TextEditingController();
    var filtered = kCountryList;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => StatefulBuilder(builder: (ctx, set) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.75,
          decoration: const BoxDecoration(
            color: Color(0xFF0D1B2A),
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(children: [
            const SizedBox(height: 12),
            Container(width: 40, height: 4,
                decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text('Select Your Country',
                  style: GoogleFonts.inter(fontSize: 17, fontWeight: FontWeight.w700, color: Colors.white)),
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: TextField(
                controller: searchCtrl,
                style: GoogleFonts.inter(color: Colors.white, fontSize: 14),
                onChanged: (q) => set(() {
                  filtered = q.isEmpty
                      ? kCountryList
                      : kCountryList.where((c) => c.$3.toLowerCase().contains(q.toLowerCase())).toList();
                }),
                decoration: InputDecoration(
                  hintText: 'Search country…',
                  hintStyle: GoogleFonts.inter(color: Colors.white38, fontSize: 13),
                  prefixIcon: const Icon(Icons.search, color: Colors.white38, size: 20),
                  filled: true,
                  fillColor: Colors.white.withOpacity(0.07),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none),
                  contentPadding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                itemCount: filtered.length,
                itemBuilder: (_, i) {
                  final c = filtered[i];
                  final selected = c.$1 == _country;
                  return ListTile(
                    leading: Text(c.$2, style: const TextStyle(fontSize: 24)),
                    title: Text(c.$3,
                        style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                            color: selected ? const Color(0xFF00C896) : Colors.white70)),
                    trailing: selected
                        ? const Icon(Icons.check_circle, color: Color(0xFF00C896), size: 20)
                        : null,
                    onTap: () {
                      setState(() => _country = c.$1);
                      Navigator.pop(context);
                    },
                  );
                },
              ),
            ),
          ]),
        );
      }),
    );
  }

  // ── Step 2: Body measurements ─────────────────────────────────────────────────
  Widget _step2() => SingleChildScrollView(
    padding: const EdgeInsets.fromLTRB(20, 24, 20, 8),
    child: Form(key: _k2, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('Body Stats',
          style: GoogleFonts.inter(
              fontSize: 30, fontWeight: FontWeight.w800,
              color: Colors.white, letterSpacing: -0.8)),
      const SizedBox(height: 6),
      Text('Used to calculate your personalized calorie goal',
          style: GoogleFonts.inter(fontSize: 14, color: Colors.white38)),
      const SizedBox(height: 20),

      // Gender selector
      Row(children: [
        _genderBtn('male',   '👨', 'Male'),
        const SizedBox(width: 12),
        _genderBtn('female', '👩', 'Female'),
      ]),
      const SizedBox(height: 16),

      _glassCard(child: Column(children: [
        Row(children: [
          Expanded(child: _DarkTextField(
              ctrl: _weightCtrl, label: UnitHelper.weightLabel(_country), hint: UnitHelper.weightHint(_country),
              icon: Icons.monitor_weight_outlined,
              keyboardType: TextInputType.number,
              onChanged: (_) => setState(() {}),
              validator: (v) => double.tryParse(v ?? '') == null ? 'Invalid' : null)),
          const SizedBox(width: 12),
          Expanded(child: _DarkTextField(
              ctrl: _heightCtrl, label: UnitHelper.heightLabel(_country), hint: UnitHelper.heightHint(_country),
              icon: Icons.height,
              keyboardType: TextInputType.number,
              onChanged: (_) => setState(() {}),
              validator: (v) => double.tryParse(v ?? '') == null ? 'Invalid' : null)),
        ]),
        const SizedBox(height: 14),
        _DarkTextField(ctrl: _ageCtrl, label: 'Age', hint: '25 years',
            icon: Icons.cake_outlined,
            keyboardType: TextInputType.number,
            validator: (v) => int.tryParse(v ?? '') == null ? 'Invalid age' : null),
      ])),

      // BMI card
      if (_bmi > 0) ...[
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: _bmiColor.withOpacity(0.08),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: _bmiColor.withOpacity(0.25)),
          ),
          child: Row(children: [
            Container(
              width: 52, height: 52,
              decoration: BoxDecoration(
                  color: _bmiColor.withOpacity(0.15), shape: BoxShape.circle),
              child: const Center(child: Text('📊', style: TextStyle(fontSize: 24))),
            ),
            const SizedBox(width: 14),
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Your BMI',
                  style: GoogleFonts.inter(fontSize: 12, color: Colors.white38)),
              Row(children: [
                Text(_bmi.toStringAsFixed(1),
                    style: GoogleFonts.inter(
                        fontSize: 30, fontWeight: FontWeight.w800,
                        color: _bmiColor)),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                  decoration: BoxDecoration(
                    color: _bmiColor.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(_bmiCat,
                      style: GoogleFonts.inter(
                          fontSize: 12, fontWeight: FontWeight.w700,
                          color: _bmiColor)),
                ),
              ]),
            ]),
          ]),
        ),
      ],
    ])),
  );

  // ── Step 3: Goals ─────────────────────────────────────────────────────────────
  Widget _step3() => SingleChildScrollView(
    padding: const EdgeInsets.fromLTRB(20, 24, 20, 8),
    child: Form(key: _k3, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('Your Goals',
          style: GoogleFonts.inter(
              fontSize: 30, fontWeight: FontWeight.w800,
              color: Colors.white, letterSpacing: -0.8)),
      const SizedBox(height: 6),
      Text("We'll build your personalized nutrition plan",
          style: GoogleFonts.inter(fontSize: 14, color: Colors.white38)),
      const SizedBox(height: 20),

      _sectionLabel('Primary Goal'),
      const SizedBox(height: 10),
      ...[
        ['lose',     '🔥', 'Lose Weight',   'Burn fat, feel lighter',      const Color(0xFFEF4444)],
        ['maintain', '⚖️', 'Stay Fit',       'Maintain current weight',     const Color(0xFF1E6EBD)],
        ['gain',     '💪', 'Build Muscle',   'Gain strength & mass',        const Color(0xFF00C896)],
      ].map((g) => _goalTile(g[0] as String, g[1] as String,
                             g[2] as String, g[3] as String, g[4] as Color)),

      const SizedBox(height: 20),
      _sectionLabel('Activity Level'),
      const SizedBox(height: 10),
      ...[
        ['sedentary', '🛋️', 'Sedentary',         'Little or no exercise'],
        ['light',     '🚶', 'Lightly Active',     '1–3 days/week'],
        ['moderate',  '🏃', 'Moderately Active',  '3–5 days/week'],
        ['active',    '🏋️', 'Very Active',        '6–7 days/week'],
      ].map((a) => _activityTile(a[0], a[1], a[2], a[3])),

      const SizedBox(height: 16),
      _glassCard(child: _DarkTextField(
          ctrl: _targetCtrl, label: UnitHelper.targetWeightLabel(_country), hint: UnitHelper.isImperial(_country) ? '140' : '65',
          icon: Icons.flag_outlined,
          keyboardType: TextInputType.number)),
      const SizedBox(height: 16),

      // Email verification note
      Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFF1E6EBD).withOpacity(0.08),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFF1E6EBD).withOpacity(0.20)),
        ),
        child: Row(children: [
          Container(
            width: 38, height: 38,
            decoration: BoxDecoration(
              color: const Color(0xFF1E6EBD).withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: const Center(child: Text('📧', style: TextStyle(fontSize: 18))),
          ),
          const SizedBox(width: 10),
          Expanded(child: Text(
              'A verification code will be sent to your email to confirm your account.',
              style: GoogleFonts.inter(
                  fontSize: 12, color: Colors.white54, height: 1.5))),
        ]),
      ),
    ])),
  );

  // ── Helpers ───────────────────────────────────────────────────────────────────

  Widget _glassCard({required Widget child}) => Container(
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(
      color: Colors.white.withOpacity(0.05),
      borderRadius: BorderRadius.circular(22),
      border: Border.all(color: Colors.white.withOpacity(0.09)),
    ),
    child: child,
  );

  Widget _sectionLabel(String text) => Text(text,
      style: GoogleFonts.inter(
          fontSize: 13, fontWeight: FontWeight.w600, color: Colors.white54,
          letterSpacing: 0.5));

  Widget _genderBtn(String value, String emoji, String label) {
    final sel = _gender == value;
    return Expanded(child: GestureDetector(
      onTap: () => setState(() => _gender = value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          gradient: sel
              ? const LinearGradient(
                  colors: [Color(0xFF1E3A5F), Color(0xFF0D4434)],
                  begin: Alignment.topLeft, end: Alignment.bottomRight)
              : null,
          color: sel ? null : Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: sel
                ? const Color(0xFF1E6EBD).withOpacity(0.5)
                : Colors.white.withOpacity(0.08),
            width: sel ? 1.5 : 1,
          ),
          boxShadow: sel ? [
            BoxShadow(color: const Color(0xFF1E6EBD).withOpacity(0.20),
                blurRadius: 16, offset: const Offset(0, 6)),
          ] : null,
        ),
        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Text(emoji, style: const TextStyle(fontSize: 22)),
          const SizedBox(width: 8),
          Text(label,
              style: GoogleFonts.inter(
                  fontWeight: FontWeight.w700,
                  color: sel ? Colors.white : Colors.white38)),
        ]),
      ),
    ));
  }

  Widget _goalTile(String value, String emoji, String title, String subtitle, Color accent) {
    final sel = _goal == value;
    return GestureDetector(
      onTap: () => setState(() => _goal = value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: sel ? accent.withOpacity(0.08) : Colors.white.withOpacity(0.04),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: sel ? accent.withOpacity(0.40) : Colors.white.withOpacity(0.07),
            width: sel ? 1.5 : 1,
          ),
          boxShadow: sel ? [
            BoxShadow(color: accent.withOpacity(0.15), blurRadius: 14, offset: const Offset(0, 6)),
          ] : null,
        ),
        child: Row(children: [
          Text(emoji, style: const TextStyle(fontSize: 24)),
          const SizedBox(width: 14),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title,
                style: GoogleFonts.inter(
                    fontWeight: FontWeight.w700, fontSize: 14,
                    color: sel ? accent : Colors.white70)),
            Text(subtitle,
                style: GoogleFonts.inter(fontSize: 12, color: Colors.white38)),
          ])),
          if (sel)
            Container(
              width: 24, height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle, color: accent,
                boxShadow: [BoxShadow(color: accent.withOpacity(0.35), blurRadius: 8, offset: const Offset(0, 3))],
              ),
              child: const Icon(Icons.check, color: Colors.white, size: 14),
            ),
        ]),
      ),
    );
  }

  Widget _activityTile(String value, String emoji, String title, String subtitle) {
    final sel = _activity == value;
    return GestureDetector(
      onTap: () => setState(() => _activity = value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: sel ? AppColors.brandGreen.withOpacity(0.08) : Colors.white.withOpacity(0.04),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: sel ? AppColors.brandGreen.withOpacity(0.35) : Colors.white.withOpacity(0.07),
            width: sel ? 1.5 : 1,
          ),
          boxShadow: sel ? [
            BoxShadow(color: AppColors.brandGreen.withOpacity(0.12),
                blurRadius: 12, offset: const Offset(0, 5)),
          ] : null,
        ),
        child: Row(children: [
          Text(emoji, style: const TextStyle(fontSize: 20)),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title,
                style: GoogleFonts.inter(
                    fontWeight: FontWeight.w700, fontSize: 13,
                    color: sel ? AppColors.brandGreen : Colors.white70)),
            Text(subtitle,
                style: GoogleFonts.inter(fontSize: 11, color: Colors.white38)),
          ])),
          if (sel)
            Container(
              width: 22, height: 22,
              decoration: BoxDecoration(
                shape: BoxShape.circle, color: AppColors.brandGreen,
                boxShadow: [BoxShadow(color: AppColors.brandGreen.withOpacity(0.35), blurRadius: 8, offset: const Offset(0, 3))],
              ),
              child: const Icon(Icons.check, color: Colors.white, size: 13),
            ),
        ]),
      ),
    );
  }
}

// ── Dark text field ────────────────────────────────────────────────────────────
class _DarkTextField extends StatelessWidget {
  final TextEditingController ctrl;
  final String label;
  final String hint;
  final IconData icon;
  final bool obscure;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;
  final Widget? suffix;
  final void Function(String)? onChanged;

  const _DarkTextField({
    required this.ctrl,
    required this.label,
    required this.hint,
    required this.icon,
    this.obscure = false,
    this.keyboardType,
    this.validator,
    this.suffix,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller:   ctrl,
      obscureText:  obscure,
      keyboardType: keyboardType,
      validator:    validator,
      onChanged:    onChanged,
      style: GoogleFonts.inter(color: Colors.white, fontSize: 14),
      decoration: InputDecoration(
        labelText:     label,
        hintText:      hint,
        labelStyle:    GoogleFonts.inter(color: Colors.white38, fontSize: 13),
        hintStyle:     GoogleFonts.inter(color: Colors.white24, fontSize: 13),
        prefixIcon:    Icon(icon, color: Colors.white38, size: 20),
        suffixIcon:    suffix,
        filled:        true,
        fillColor:     Colors.white.withOpacity(0.06),
        border:        OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(color: Colors.white.withOpacity(0.10))),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(color: Colors.white.withOpacity(0.10))),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: Color(0xFF00C896), width: 1.5)),
        errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: Color(0xFFEF4444))),
        focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: Color(0xFFEF4444), width: 1.5)),
        errorStyle: GoogleFonts.inter(color: const Color(0xFFEF4444), fontSize: 11),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
    );
  }
}

// ── Background orb ─────────────────────────────────────────────────────────────
class _Orb extends StatelessWidget {
  final double? top, bottom, left, right, size, opacity;
  final Color color;
  const _Orb({this.top, this.bottom, this.left, this.right,
              required this.size, required this.color, required this.opacity});

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: top, bottom: bottom, left: left, right: right,
      child: Container(
        width: size, height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(colors: [
            color.withOpacity(opacity!),
            color.withOpacity(0),
          ]),
        ),
      ),
    );
  }
}

// ── Grid painter ───────────────────────────────────────────────────────────────
class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.025)
      ..strokeWidth = 0.6;
    const spacing = 32.0;
    for (double x = 0; x < size.width; x += spacing) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += spacing) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
    // Diagonal accent lines
    final dp = Paint()
      ..color = Colors.white.withOpacity(0.012)
      ..strokeWidth = 0.5;
    for (double i = -size.height; i < size.width + size.height; i += 80) {
      canvas.drawLine(Offset(i, 0), Offset(i + size.height, size.height), dp);
    }
  }

  @override
  bool shouldRepaint(_) => false;
}
