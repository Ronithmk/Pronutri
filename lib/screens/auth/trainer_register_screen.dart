import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../services/auth_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_text_field.dart';
import 'login_screen.dart';
import 'trainer_otp_screen.dart';

// ─────────────────────────────────────────────────────────────────────────────
// TrainerRegisterScreen  — 3 steps
//   Step 1 : Account credentials (name, email, password)
//   Step 2 : Professional profile (specializations, experience, bio)
//   Step 3 : Document upload (certificate / experience letter)
// ─────────────────────────────────────────────────────────────────────────────

const _specializations = [
  'Nutrition', 'Weight Loss', 'Muscle Gain', 'Yoga',
  'HIIT', 'Cardio', 'Mindfulness', 'Strength Training',
  'Pilates', 'Sports Nutrition',
];

class TrainerRegisterScreen extends StatefulWidget {
  const TrainerRegisterScreen({super.key});
  @override
  State<TrainerRegisterScreen> createState() => _TrainerRegisterScreenState();
}

class _TrainerRegisterScreenState extends State<TrainerRegisterScreen> {
  final _pageCtrl = PageController();
  int  _step      = 0;
  bool _loading   = false;

  // Step 1 — credentials
  final _nameCtrl   = TextEditingController();
  final _emailCtrl  = TextEditingController();
  final _passCtrl   = TextEditingController();
  final _confirmCtrl = TextEditingController();
  bool _obscure     = true;
  final _k1         = GlobalKey<FormState>();

  // Step 2 — professional profile
  final Set<String> _selectedSpecs = {};
  int    _years   = 1;
  final  _bioCtrl = TextEditingController();
  final  _k2      = GlobalKey<FormState>();

  // Step 3 — document
  File?   _docFile;
  String  _docType = 'certificate'; // 'certificate' | 'experience_letter' | 'linkedin'

  @override
  void dispose() {
    _pageCtrl.dispose();
    _nameCtrl.dispose(); _emailCtrl.dispose();
    _passCtrl.dispose(); _confirmCtrl.dispose();
    _bioCtrl.dispose();
    super.dispose();
  }

  // ── Navigation ─────────────────────────────────────────────────────────────
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
    if (_step == 1 && _selectedSpecs.isEmpty) {
      _showSnack('Please select at least one specialization.');
      return;
    }
    if (_step == 2) { _submit(); return; }
    _pageCtrl.nextPage(duration: const Duration(milliseconds: 380), curve: Curves.easeInOut);
    setState(() => _step++);
  }

  void _back() {
    if (_step > 0) {
      setState(() => _step--);
      _pageCtrl.previousPage(duration: const Duration(milliseconds: 380), curve: Curves.easeInOut);
    }
  }

  // ── Pick document ──────────────────────────────────────────────────────────
  Future<void> _pickDocument() async {
    final picker = ImagePicker();
    final source = await _showPickerSource();
    if (source == null) return;

    final XFile? file = await picker.pickImage(
      source:      source,
      imageQuality: 85,
      maxWidth:    1600,
    );
    if (file != null) setState(() => _docFile = File(file.path));
  }

  Future<ImageSource?> _showPickerSource() => showModalBottomSheet<ImageSource>(
    context: context,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
    builder: (_) => SafeArea(
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        const SizedBox(height: 8),
        Container(width: 36, height: 4, decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(2))),
        const SizedBox(height: 16),
        ListTile(
          leading: const Icon(Icons.camera_alt_outlined, color: AppColors.brandBlue),
          title: Text('Take a photo', style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
          onTap: () => Navigator.pop(context, ImageSource.camera),
        ),
        ListTile(
          leading: const Icon(Icons.photo_library_outlined, color: AppColors.brandBlue),
          title: Text('Choose from gallery', style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
          onTap: () => Navigator.pop(context, ImageSource.gallery),
        ),
        const SizedBox(height: 8),
      ]),
    ),
  );

  // ── Submit — send OTP ──────────────────────────────────────────────────────
  Future<void> _submit() async {
    if (_docFile == null) {
      _showSnack('Please upload your certificate or experience letter.');
      return;
    }

    setState(() => _loading = true);

    final result = await context.read<AuthProvider>().sendTrainerRegistrationOtp(
      name:             _nameCtrl.text.trim(),
      email:            _emailCtrl.text.trim(),
      password:         _passCtrl.text,
      specializations:  _selectedSpecs.toList(),
      yearsExperience:  _years,
      bio:              _bioCtrl.text.trim(),
      documentPath:     _docFile!.path,
    );

    setState(() => _loading = false);
    if (!mounted) return;

    if (result == null) {
      Navigator.push(context, MaterialPageRoute(
        builder: (_) => TrainerOtpScreen(email: _emailCtrl.text.trim()),
      ));
    } else if (result.startsWith('EMAIL_NOT_CONFIGURED:')) {
      final devOtp = result.split(':')[1];
      Navigator.push(context, MaterialPageRoute(
        builder: (_) => TrainerOtpScreen(
          email:  _emailCtrl.text.trim(),
          devOtp: devOtp,
        ),
      ));
    } else {
      _showSnack(result);
    }
  }

  void _showSnack(String msg) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(
    content: Text(msg), backgroundColor: AppColors.accent,
    behavior: SnackBarBehavior.floating,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
  ));

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.bgDark : AppColors.bg,
      body: SafeArea(child: Column(children: [
        // ── Header / progress ────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
          child: Row(children: [
            if (_step > 0)
              IconButton(
                onPressed: _back,
                icon: const Icon(Icons.arrow_back_ios, size: 18),
                style: IconButton.styleFrom(
                  backgroundColor: isDark ? AppColors.surfVarDark : AppColors.surfaceVar,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              )
            else
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.arrow_back_ios, size: 18),
                style: IconButton.styleFrom(
                  backgroundColor: isDark ? AppColors.surfVarDark : AppColors.surfaceVar,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            Expanded(child: Column(children: [
              // Step dots
              Row(mainAxisAlignment: MainAxisAlignment.center, children: List.generate(3, (i) {
                final done   = i < _step;
                final active = i == _step;
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width:  active ? 24 : 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: done || active
                        ? AppColors.brandGreen
                        : (isDark ? AppColors.borderDark : AppColors.border),
                    borderRadius: BorderRadius.circular(4),
                  ),
                );
              })),
              const SizedBox(height: 5),
              Text('Step ${_step + 1} of 3', style: GoogleFonts.inter(
                fontSize: 11, color: isDark ? AppColors.textSecDark : AppColors.textSec,
              )),
            ])),
            // Trainer badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: AppColors.brandGreen.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.brandGreen.withOpacity(0.3)),
              ),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                const Text('🏋️', style: TextStyle(fontSize: 12)),
                const SizedBox(width: 4),
                Text('Trainer', style: GoogleFonts.inter(
                  fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.brandGreen,
                )),
              ]),
            ),
          ]),
        ),

        // ── Pages ────────────────────────────────────────────────────
        Expanded(child: PageView(
          controller: _pageCtrl,
          physics: const NeverScrollableScrollPhysics(),
          children: [
            _step1(isDark),
            _step2(isDark),
            _step3(isDark),
          ],
        )),

        // ── Bottom CTA ────────────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
          child: Column(children: [
            AppButton(
              label:   _step == 2 ? 'Send Verification Code' : 'Continue',
              onTap:   _next,
              loading: _loading,
              color:   AppColors.brandGreen,
              icon:    _step == 2 ? Icons.email_outlined : null,
            ),
            if (_step == 0) ...[
              const SizedBox(height: 12),
              Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                Text('Already have an account? ',
                  style: GoogleFonts.inter(color: AppColors.textSec, fontSize: 14)),
                GestureDetector(
                  onTap: () => Navigator.pushReplacement(context,
                    MaterialPageRoute(builder: (_) => const LoginScreen())),
                  child: Text('Sign In', style: GoogleFonts.inter(
                    color: AppColors.brandGreen, fontSize: 14, fontWeight: FontWeight.w600)),
                ),
              ]),
            ],
          ]),
        ),
      ])),
    );
  }

  // ── Step 1: Account credentials ────────────────────────────────────────────
  Widget _step1(bool isDark) => SingleChildScrollView(
    padding: const EdgeInsets.all(24),
    child: Form(key: _k1, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const SizedBox(height: 4),
      Text('Create Trainer Account', style: GoogleFonts.inter(
        fontSize: 26, fontWeight: FontWeight.w800, letterSpacing: -0.5,
        color: isDark ? AppColors.textPriDark : AppColors.textPri,
      )),
      const SizedBox(height: 6),
      Text('Your credentials to log into ProNutri', style: GoogleFonts.inter(
        fontSize: 14, color: isDark ? AppColors.textSecDark : AppColors.textSec,
      )),
      const SizedBox(height: 20),

      // Trainer benefit banner
      Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF1B8A4D), Color(0xFF2ECC71)],
            begin: Alignment.centerLeft, end: Alignment.centerRight,
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(children: [
          const Text('💰', style: TextStyle(fontSize: 28)),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Earn with ProNutri!', style: GoogleFonts.inter(
              fontSize: 13, fontWeight: FontWeight.w800, color: Colors.white)),
            const SizedBox(height: 2),
            Text('Host sessions · Build audience · Get paid', style: GoogleFonts.inter(
              fontSize: 11, color: Colors.white.withOpacity(0.85))),
          ])),
        ]),
      ),
      const SizedBox(height: 20),

      AppTextField(
        controller: _nameCtrl, label: 'Full Name', hint: 'Your legal name',
        icon: Icons.person_outline,
        validator: (v) => v!.trim().length < 2 ? 'Enter your full name' : null,
      ),
      const SizedBox(height: 14),
      AppTextField(
        controller: _emailCtrl, label: 'Email address', hint: 'you@example.com',
        icon: Icons.email_outlined, keyboardType: TextInputType.emailAddress,
        validator: (v) => !v!.contains('@') ? 'Enter a valid email' : null,
      ),
      const SizedBox(height: 14),
      AppTextField(
        controller: _passCtrl, label: 'Password', hint: 'Min 6 chars, 1 number, 1 symbol',
        icon: Icons.lock_outline, obscure: _obscure,
        suffix: IconButton(
          onPressed: () => setState(() => _obscure = !_obscure),
          icon: Icon(_obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined,
              color: AppColors.textSec, size: 20),
        ),
        validator: _validatePassword,
      ),
      const SizedBox(height: 14),
      AppTextField(
        controller: _confirmCtrl, label: 'Confirm Password', hint: 'Repeat password',
        icon: Icons.lock_outline, obscure: true,
        validator: (v) => v != _passCtrl.text ? 'Passwords do not match' : null,
      ),
    ])),
  );

  // ── Step 2: Professional profile ───────────────────────────────────────────
  Widget _step2(bool isDark) => SingleChildScrollView(
    padding: const EdgeInsets.all(24),
    child: Form(key: _k2, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const SizedBox(height: 4),
      Text('Professional Profile', style: GoogleFonts.inter(
        fontSize: 26, fontWeight: FontWeight.w800, letterSpacing: -0.5,
        color: isDark ? AppColors.textPriDark : AppColors.textPri,
      )),
      const SizedBox(height: 6),
      Text('Help learners understand your expertise', style: GoogleFonts.inter(
        fontSize: 14, color: isDark ? AppColors.textSecDark : AppColors.textSec,
      )),
      const SizedBox(height: 24),

      // Specializations
      Text('Specializations', style: GoogleFonts.inter(
        fontSize: 13, fontWeight: FontWeight.w700,
        color: isDark ? AppColors.textSecDark : AppColors.textSec,
      )),
      const SizedBox(height: 2),
      Text('Select all that apply (at least 1)', style: GoogleFonts.inter(
        fontSize: 11, color: isDark ? AppColors.textSecDark : AppColors.textHint,
      )),
      const SizedBox(height: 10),
      Wrap(spacing: 8, runSpacing: 8, children: _specializations.map((spec) {
        final sel = _selectedSpecs.contains(spec);
        return GestureDetector(
          onTap: () => setState(() {
            if (sel) {
              _selectedSpecs.remove(spec);
            } else {
              _selectedSpecs.add(spec);
            }
          }),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: sel
                  ? AppColors.brandGreen.withOpacity(0.12)
                  : (isDark ? AppColors.surfVarDark : AppColors.surfaceVar),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: sel ? AppColors.brandGreen : (isDark ? AppColors.borderDark : AppColors.border),
                width: sel ? 1.5 : 1,
              ),
            ),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              if (sel) ...[
                const Icon(Icons.check_circle, color: AppColors.brandGreen, size: 13),
                const SizedBox(width: 5),
              ],
              Text(spec, style: GoogleFonts.inter(
                fontSize: 12, fontWeight: FontWeight.w600,
                color: sel ? AppColors.brandGreen : (isDark ? AppColors.textSecDark : AppColors.textSec),
              )),
            ]),
          ),
        );
      }).toList()),
      const SizedBox(height: 24),

      // Years of experience
      Text('Years of Experience', style: GoogleFonts.inter(
        fontSize: 13, fontWeight: FontWeight.w700,
        color: isDark ? AppColors.textSecDark : AppColors.textSec,
      )),
      const SizedBox(height: 12),
      _YearSlider(
        value:    _years,
        isDark:   isDark,
        onChange: (v) => setState(() => _years = v),
      ),
      const SizedBox(height: 24),

      // Bio
      Text('Short Bio', style: GoogleFonts.inter(
        fontSize: 13, fontWeight: FontWeight.w700,
        color: isDark ? AppColors.textSecDark : AppColors.textSec,
      )),
      const SizedBox(height: 8),
      TextFormField(
        controller: _bioCtrl,
        maxLines: 4, maxLength: 300,
        decoration: InputDecoration(
          hintText: 'Tell learners about your background, certifications and teaching style…',
          hintStyle: GoogleFonts.inter(fontSize: 13, color: AppColors.textHint),
          filled: true,
          fillColor: isDark ? AppColors.surfVarDark : AppColors.surfaceVar,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(color: isDark ? AppColors.borderDark : AppColors.border),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(color: isDark ? AppColors.borderDark : AppColors.border),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: AppColors.brandGreen, width: 1.5),
          ),
          counterStyle: GoogleFonts.inter(fontSize: 11, color: AppColors.textSec),
        ),
        style: GoogleFonts.inter(fontSize: 14),
        validator: (v) => (v == null || v.trim().length < 20) ? 'Write at least 20 characters' : null,
      ),
    ])),
  );

  // ── Step 3: Document upload ────────────────────────────────────────────────
  Widget _step3(bool isDark) => SingleChildScrollView(
    padding: const EdgeInsets.all(24),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const SizedBox(height: 4),
      Text('Verify Your Expertise', style: GoogleFonts.inter(
        fontSize: 26, fontWeight: FontWeight.w800, letterSpacing: -0.5,
        color: isDark ? AppColors.textPriDark : AppColors.textPri,
      )),
      const SizedBox(height: 6),
      Text('Upload proof of your qualifications — we review it manually within 1–2 business days.',
        style: GoogleFonts.inter(fontSize: 14,
            color: isDark ? AppColors.textSecDark : AppColors.textSec, height: 1.5)),
      const SizedBox(height: 28),

      // Doc type selector
      Text('Document Type', style: GoogleFonts.inter(
        fontSize: 13, fontWeight: FontWeight.w700,
        color: isDark ? AppColors.textSecDark : AppColors.textSec,
      )),
      const SizedBox(height: 10),
      _DocTypeSelector(
        selected: _docType,
        isDark:   isDark,
        onChanged: (t) => setState(() => _docType = t),
      ),
      const SizedBox(height: 24),

      // Upload area
      Text('Upload Document', style: GoogleFonts.inter(
        fontSize: 13, fontWeight: FontWeight.w700,
        color: isDark ? AppColors.textSecDark : AppColors.textSec,
      )),
      const SizedBox(height: 10),
      GestureDetector(
        onTap: _pickDocument,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: double.infinity,
          height: _docFile != null ? 200 : 150,
          decoration: BoxDecoration(
            color: _docFile != null
                ? AppColors.brandGreen.withOpacity(0.05)
                : (isDark ? AppColors.surfVarDark : AppColors.surfaceVar),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: _docFile != null
                  ? AppColors.brandGreen
                  : (isDark ? AppColors.borderDark : AppColors.border),
              width: _docFile != null ? 2 : 1,
              style: _docFile != null ? BorderStyle.solid : BorderStyle.solid,
            ),
          ),
          child: _docFile != null
              ? Stack(children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: Image.file(_docFile!, width: double.infinity,
                        height: double.infinity, fit: BoxFit.cover),
                  ),
                  // Change overlay
                  Positioned.fill(child: Container(
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.35),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                      const Icon(Icons.edit, color: Colors.white, size: 28),
                      const SizedBox(height: 6),
                      Text('Tap to change', style: GoogleFonts.inter(
                          color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
                    ]),
                  )),
                  // Verified tick
                  Positioned(top: 10, right: 10, child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: const BoxDecoration(
                        color: AppColors.brandGreen, shape: BoxShape.circle),
                    child: const Icon(Icons.check, color: Colors.white, size: 16),
                  )),
                ])
              : Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Container(
                    width: 52, height: 52,
                    decoration: BoxDecoration(
                      color: AppColors.brandBlue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(Icons.cloud_upload_outlined,
                        color: AppColors.brandBlue, size: 28),
                  ),
                  const SizedBox(height: 10),
                  Text('Tap to upload document', style: GoogleFonts.inter(
                    fontSize: 14, fontWeight: FontWeight.w600,
                    color: isDark ? AppColors.textPriDark : AppColors.textPri,
                  )),
                  const SizedBox(height: 4),
                  Text('Photo, PDF scan — max 10 MB', style: GoogleFonts.inter(
                    fontSize: 12, color: isDark ? AppColors.textSecDark : AppColors.textSec,
                  )),
                ]),
        ),
      ),
      const SizedBox(height: 24),

      // What's accepted
      _AcceptedDocsCard(isDark: isDark),
      const SizedBox(height: 20),

      // Privacy note
      Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.brandBlue.withOpacity(0.06),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.brandBlue.withOpacity(0.15)),
        ),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Icon(Icons.security_outlined, color: AppColors.brandBlue, size: 16),
          const SizedBox(width: 10),
          Expanded(child: Text(
            'Your document is stored securely and only used for verification. '
            'It is never shared with learners.',
            style: GoogleFonts.inter(
              fontSize: 12, color: AppColors.brandBlue, height: 1.5),
          )),
        ]),
      ),
    ]),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// _YearSlider
// ─────────────────────────────────────────────────────────────────────────────
class _YearSlider extends StatelessWidget {
  final int    value;
  final bool   isDark;
  final void Function(int) onChange;

  const _YearSlider({
    required this.value,
    required this.isDark,
    required this.onChange,
  });

  String get _label {
    if (value == 1)  return '< 1 year';
    if (value >= 15) return '15+ years';
    return '$value years';
  }

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Row(children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
          decoration: BoxDecoration(
            color: AppColors.brandGreen.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(_label, style: GoogleFonts.inter(
            fontSize: 15, fontWeight: FontWeight.w800, color: AppColors.brandGreen,
          )),
        ),
      ]),
      Slider(
        value:     value.toDouble(),
        min:       1, max: 15, divisions: 14,
        activeColor:   AppColors.brandGreen,
        inactiveColor: isDark ? AppColors.borderDark : AppColors.border,
        label:     _label,
        onChanged: (v) => onChange(v.round()),
      ),
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text('< 1 yr', style: GoogleFonts.inter(fontSize: 10, color: AppColors.textSec)),
        Text('15+ yrs', style: GoogleFonts.inter(fontSize: 10, color: AppColors.textSec)),
      ]),
    ],
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// _DocTypeSelector
// ─────────────────────────────────────────────────────────────────────────────
class _DocTypeSelector extends StatelessWidget {
  final String   selected;
  final bool     isDark;
  final void Function(String) onChanged;

  const _DocTypeSelector({
    required this.selected,
    required this.isDark,
    required this.onChanged,
  });

  static const _types = [
    ('certificate',       '🏅', 'Certificate',        'Fitness / nutrition cert'),
    ('experience_letter', '📄', 'Experience Letter',   'From employer / gym'),
    ('linkedin',          '💼', 'LinkedIn / Portfolio', 'Profile screenshot'),
  ];

  @override
  Widget build(BuildContext context) => Column(
    children: _types.map(((String id, String em, String title, String sub) t) {
      final active = selected == t.$1;
      return GestureDetector(
        onTap: () => onChanged(t.$1),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: active
                ? AppColors.brandGreen.withOpacity(0.08)
                : (isDark ? AppColors.surfDark : AppColors.surface),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: active ? AppColors.brandGreen : (isDark ? AppColors.borderDark : AppColors.border),
              width: active ? 1.5 : 1,
            ),
          ),
          child: Row(children: [
            Text(t.$2, style: const TextStyle(fontSize: 20)),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(t.$3, style: GoogleFonts.inter(
                fontSize: 13, fontWeight: FontWeight.w700,
                color: active ? AppColors.brandGreen : (isDark ? AppColors.textPriDark : AppColors.textPri),
              )),
              Text(t.$4, style: GoogleFonts.inter(
                fontSize: 11, color: isDark ? AppColors.textSecDark : AppColors.textSec,
              )),
            ])),
            AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              width: 20, height: 20,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color:  active ? AppColors.brandGreen : Colors.transparent,
                border: Border.all(
                  color: active ? AppColors.brandGreen : (isDark ? AppColors.borderDark : AppColors.border),
                  width: 2,
                ),
              ),
              child: active
                  ? const Icon(Icons.check, color: Colors.white, size: 12)
                  : null,
            ),
          ]),
        ),
      );
    }).toList(),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// _AcceptedDocsCard
// ─────────────────────────────────────────────────────────────────────────────
class _AcceptedDocsCard extends StatelessWidget {
  final bool isDark;
  const _AcceptedDocsCard({required this.isDark});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: isDark ? AppColors.surfDark : AppColors.surface,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: isDark ? AppColors.borderDark : AppColors.border),
    ),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('What we accept', style: GoogleFonts.inter(
        fontSize: 13, fontWeight: FontWeight.w700,
        color: isDark ? AppColors.textPriDark : AppColors.textPri,
      )),
      const SizedBox(height: 10),
      ...[
        '✅  ISSA, ACE, NASM, or equivalent fitness certification',
        '✅  Nutrition / dietetics degree or diploma',
        '✅  Experience letter from a gym or wellness centre',
        '✅  LinkedIn profile showing relevant experience (screenshot)',
        '❌  No personal photos or unrelated IDs',
      ].map((t) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Text(t, style: GoogleFonts.inter(
          fontSize: 12, color: isDark ? AppColors.textSecDark : AppColors.textSec, height: 1.4,
        )),
      )),
    ]),
  );
}
