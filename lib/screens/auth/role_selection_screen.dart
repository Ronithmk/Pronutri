import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme/app_theme.dart';
import 'register_screen.dart';
import 'trainer_register_screen.dart';

// ─────────────────────────────────────────────────────────────────────────────
// RoleSelectionScreen
//
// First stop after tapping "Sign Up" — user picks Learner or Trainer.
// Learner → existing RegisterScreen
// Trainer → TrainerRegisterScreen (multi-step + doc upload)
// ─────────────────────────────────────────────────────────────────────────────
class RoleSelectionScreen extends StatefulWidget {
  const RoleSelectionScreen({super.key});
  @override
  State<RoleSelectionScreen> createState() => _RoleSelectionScreenState();
}

class _RoleSelectionScreenState extends State<RoleSelectionScreen>
    with SingleTickerProviderStateMixin {
  String? _selected; // 'learner' | 'trainer'
  late AnimationController _ctrl;
  late Animation<double> _fade;
  late Animation<Offset>  _slide;

  @override
  void initState() {
    super.initState();
    _ctrl  = AnimationController(vsync: this, duration: const Duration(milliseconds: 500));
    _fade  = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _slide = Tween(begin: const Offset(0, 0.08), end: Offset.zero)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
    _ctrl.forward();
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  void _proceed() {
    if (_selected == null) return;
    if (_selected == 'learner') {
      Navigator.push(context, MaterialPageRoute(builder: (_) => const RegisterScreen()));
    } else {
      Navigator.push(context, MaterialPageRoute(builder: (_) => const TrainerRegisterScreen()));
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
        leading: GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Container(
            margin: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: isDark ? AppColors.surfVarDark : Colors.white,
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(color: AppColors.brandBlue.withOpacity(0.10), blurRadius: 10, offset: const Offset(0, 4)),
                BoxShadow(color: Colors.white.withOpacity(isDark ? 0.04 : 0.9), blurRadius: 4, offset: const Offset(-1, -1)),
              ],
            ),
            child: const Icon(Icons.arrow_back_ios_new_rounded, size: 16),
          ),
        ),
      ),
      body: SafeArea(
        child: FadeTransition(
          opacity: _fade,
          child: SlideTransition(
            position: _slide,
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Header ─────────────────────────────────────────────
                  Text('Join ProNutri',
                    style: GoogleFonts.inter(
                      fontSize: 30, fontWeight: FontWeight.w800, letterSpacing: -0.5,
                      color: isDark ? AppColors.textPriDark : AppColors.textPri,
                    )),
                  const SizedBox(height: 6),
                  Text('Tell us who you are so we can personalise your experience.',
                    style: GoogleFonts.inter(
                      fontSize: 14, color: isDark ? AppColors.textSecDark : AppColors.textSec,
                    )),
                  const SizedBox(height: 36),

                  // ── Learner card ────────────────────────────────────────
                  _RoleCard(
                    selected:    _selected == 'learner',
                    isDark:      isDark,
                    role:        'learner',
                    emoji:       '🎓',
                    title:       "I'm a Learner",
                    subtitle:    'Track nutrition, join live classes, and reach your health goals.',
                    bullets: const [
                      'Personalised calorie & macro tracking',
                      'Join trainer-led live sessions',
                      'AI nutrition coach (NutriBot)',
                      '₹100 welcome credits + 30-day trial',
                    ],
                    accentColor: AppColors.brandBlue,
                    onTap: () => setState(() => _selected = 'learner'),
                  ),
                  const SizedBox(height: 16),

                  // ── Trainer card ────────────────────────────────────────
                  _RoleCard(
                    selected:    _selected == 'trainer',
                    isDark:      isDark,
                    role:        'trainer',
                    emoji:       '🏋️',
                    title:       "I'm a Trainer",
                    subtitle:    'Host live sessions, build your audience, and monetize your expertise.',
                    bullets: const [
                      'Host live video sessions for 1,000+ viewers',
                      'Schedule & manage your sessions',
                      'Get paid for your expertise',
                      'Verified trainer badge after approval',
                    ],
                    accentColor: AppColors.brandGreen,
                    onTap: () => setState(() => _selected = 'trainer'),
                  ),

                  const SizedBox(height: 24),

                  // ── Verification note for trainer ───────────────────────
                  AnimatedSize(
                    duration: const Duration(milliseconds: 250),
                    curve: Curves.easeInOut,
                    child: _selected == 'trainer'
                        ? Container(
                            margin: const EdgeInsets.only(bottom: 16),
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: AppColors.amber.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: AppColors.amber.withOpacity(0.3)),
                            ),
                            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              const Text('📋', style: TextStyle(fontSize: 18)),
                              const SizedBox(width: 10),
                              Expanded(child: Text(
                                'Trainer accounts require verification. '
                                'You\'ll upload a certificate or experience letter — '
                                'we review and approve within 1 business days.',
                                style: GoogleFonts.inter(
                                  fontSize: 12, height: 1.5,
                                  color: isDark ? AppColors.amber : const Color(0xFF8B6400),
                                ),
                              )),
                            ]),
                          )
                        : const SizedBox.shrink(),
                  ),

                  // ── Continue button ─────────────────────────────────────
                  AnimatedOpacity(
                    opacity: _selected != null ? 1.0 : 0.4,
                    duration: const Duration(milliseconds: 200),
                    child: GestureDetector(
                      onTap: _selected != null ? _proceed : null,
                      child: Container(
                        width: double.infinity, height: 58,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: _selected == 'trainer'
                                ? [AppColors.brandGreen, const Color(0xFF1BA874)]
                                : [AppColors.brandBlue, const Color(0xFF2590E8)],
                          ),
                          borderRadius: BorderRadius.circular(22),
                          boxShadow: _selected != null ? [
                            BoxShadow(
                              color: (_selected == 'trainer' ? AppColors.brandGreen : AppColors.brandBlue).withOpacity(0.38),
                              blurRadius: 20, offset: const Offset(0, 8),
                            ),
                            BoxShadow(color: Colors.white.withOpacity(0.20), blurRadius: 6, offset: const Offset(-2, -2)),
                          ] : [],
                        ),
                        child: Center(child: Text(
                          _selected == 'trainer'
                              ? 'Continue as Trainer →'
                              : 'Continue as Learner →',
                          style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w700, color: Colors.white, letterSpacing: 0.2),
                        )),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _RoleCard
// ─────────────────────────────────────────────────────────────────────────────
class _RoleCard extends StatelessWidget {
  final bool     selected;
  final bool     isDark;
  final String   role;
  final String   emoji;
  final String   title;
  final String   subtitle;
  final List<String> bullets;
  final Color    accentColor;
  final VoidCallback onTap;

  const _RoleCard({
    required this.selected,
    required this.isDark,
    required this.role,
    required this.emoji,
    required this.title,
    required this.subtitle,
    required this.bullets,
    required this.accentColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: selected
              ? accentColor.withOpacity(0.08)
              : (isDark ? AppColors.surfDark : Colors.white),
          borderRadius: BorderRadius.circular(28),
          border: selected ? Border.all(color: accentColor, width: 2) : null,
          boxShadow: [
            BoxShadow(
              color: selected ? accentColor.withOpacity(0.22) : (isDark ? Colors.black.withOpacity(0.30) : AppColors.brandBlue.withOpacity(0.09)),
              blurRadius: selected ? 24 : 18,
              spreadRadius: -3,
              offset: const Offset(0, 10),
            ),
            BoxShadow(color: Colors.white.withOpacity(isDark ? 0.04 : 0.85), blurRadius: 6, spreadRadius: -2, offset: const Offset(-2, -2)),
          ],
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            // Emoji badge
            Container(
              width: 56, height: 56,
              decoration: BoxDecoration(
                color: accentColor.withOpacity(selected ? 0.18 : 0.10),
                borderRadius: BorderRadius.circular(18),
                boxShadow: [BoxShadow(color: accentColor.withOpacity(0.18), blurRadius: 12, offset: const Offset(0, 5))],
              ),
              child: Center(child: Text(emoji, style: const TextStyle(fontSize: 28))),
            ),
            const SizedBox(width: 14),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(title, style: GoogleFonts.inter(
                fontSize: 17, fontWeight: FontWeight.w800,
                color: selected ? accentColor : (isDark ? AppColors.textPriDark : AppColors.textPri),
              )),
              const SizedBox(height: 3),
              Text(subtitle, style: GoogleFonts.inter(
                fontSize: 12, color: isDark ? AppColors.textSecDark : AppColors.textSec,
                height: 1.4,
              )),
            ])),
            // Selection indicator
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 22, height: 22,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: selected ? accentColor : Colors.transparent,
                border: Border.all(
                  color: selected ? accentColor : (isDark ? AppColors.borderDark : AppColors.border),
                  width: 2,
                ),
              ),
              child: selected
                  ? const Icon(Icons.check, color: Colors.white, size: 13)
                  : null,
            ),
          ]),

          // Bullets (expanded when selected)
          AnimatedCrossFade(
            duration: const Duration(milliseconds: 250),
            crossFadeState: selected ? CrossFadeState.showSecond : CrossFadeState.showFirst,
            firstChild: const SizedBox.shrink(),
            secondChild: Padding(
              padding: const EdgeInsets.only(top: 16),
              child: Column(
                children: bullets.map((b) => Padding(
                  padding: const EdgeInsets.only(bottom: 7),
                  child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Container(
                      width: 18, height: 18, margin: const EdgeInsets.only(right: 10, top: 1),
                      decoration: BoxDecoration(
                        color: accentColor.withOpacity(0.12),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.check, color: accentColor, size: 11),
                    ),
                    Expanded(child: Text(b, style: GoogleFonts.inter(
                      fontSize: 13, color: isDark ? AppColors.textSecDark : AppColors.textSec,
                      height: 1.4,
                    ))),
                  ]),
                )).toList(),
              ),
            ),
          ),
        ]),
      ),
    );
  }
}
