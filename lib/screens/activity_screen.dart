import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import '../services/activity_provider.dart';
import '../theme/app_theme.dart';

class ActivityScreen extends StatefulWidget {
  const ActivityScreen({super.key});
  @override
  State<ActivityScreen> createState() => _ActivityScreenState();
}

class _ActivityScreenState extends State<ActivityScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _premiumCtrl;

  @override
  void initState() {
    super.initState();
    _premiumCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ActivityProvider>().init();
    });
  }

  @override
  void dispose() {
    _premiumCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final act    = context.watch<ActivityProvider>();

    return Scaffold(
      backgroundColor: isDark ? AppColors.bgDark : AppColors.bg,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: isDark ? AppColors.surfaceDark : AppColors.surface,
        title: Text('Activity', style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: act.refresh,
          ),
        ],
      ),
      body: act.loading && act.todaySteps == 0
          ? const Center(child: CircularProgressIndicator())
          : !act.hasPermission
              ? _noPermission(context, isDark)
              : RefreshIndicator(
                  onRefresh: act.refresh,
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                    children: [
                      _stepsCard(act, isDark),
                      const SizedBox(height: 14),
                      _activityRow(act, isDark),
                      const SizedBox(height: 14),
                      _weeklyChart(act, isDark),
                      const SizedBox(height: 14),
                      _badgesSection(act, isDark),
                    ],
                  ),
                ),
    );
  }

  // ── No Permission ─────────────────────────────────────────────────────────
  Widget _noPermission(BuildContext context, bool isDark) {
    final act = context.watch<ActivityProvider>();
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Text('🏃', style: TextStyle(fontSize: 64)),
          const SizedBox(height: 16),
          Text('Activity Permission Required',
              style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.w800,
                  color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary)),
          const SizedBox(height: 10),
          Text(
            act.permDenied
                ? 'Permission was denied. Please enable "Physical Activity" in app settings.'
                : 'ProNutri needs permission to count your steps using the phone\'s built-in sensor.',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(fontSize: 14, color: AppColors.textSecondary, height: 1.5),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () async {
              if (act.permDenied) {
                await openAppSettings(); // sends user to app settings
              } else {
                context.read<ActivityProvider>().init();
              }
            },
            icon: Icon(act.permDenied ? Icons.settings_outlined : Icons.health_and_safety_outlined),
            label: Text(act.permDenied ? 'Open Settings' : 'Grant Permission'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.brandBlue,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
          ),
        ]),
      ),
    );
  }

  // ── Steps Hero Card ───────────────────────────────────────────────────────
  Widget _stepsCard(ActivityProvider act, bool isDark) {
    final steps     = act.todaySteps;
    const goal      = ActivityProvider.stepGoal;
    final pct       = (act.stepProgress * 100).toInt();
    final remaining = (goal - steps).clamp(0, goal);
    final reached   = steps >= goal;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? [const Color(0xFF0D1F3C), const Color(0xFF0A2A1A)]
              : [AppColors.blueBg, AppColors.greenBg],
          begin: Alignment.topLeft, end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.brandBlue.withOpacity(0.15)),
      ),
      child: Row(children: [
        // Ring
        SizedBox(width: 120, height: 120, child: Stack(alignment: Alignment.center, children: [
          SizedBox(width: 120, height: 120, child: CircularProgressIndicator(
            value: act.stepProgress,
            strokeWidth: 10,
            backgroundColor: AppColors.brandBlue.withOpacity(0.12),
            valueColor: AlwaysStoppedAnimation(reached ? AppColors.brandGreen : AppColors.brandBlue),
            strokeCap: StrokeCap.round,
          )),
          Column(mainAxisSize: MainAxisSize.min, children: [
            Text(steps.toString(),
                style: GoogleFonts.inter(fontSize: 22, fontWeight: FontWeight.w900,
                    color: isDark ? AppColors.textPriDark : AppColors.textPri)),
            Text('steps', style: GoogleFonts.inter(fontSize: 10, color: AppColors.textSec)),
            Text('$pct%', style: GoogleFonts.inter(fontSize: 11,
                color: reached ? AppColors.brandGreen : AppColors.brandBlue,
                fontWeight: FontWeight.w700)),
          ]),
        ])),
        const SizedBox(width: 18),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text("Today's Steps",
              style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w700,
                  color: isDark ? AppColors.textPriDark : AppColors.textPri)),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: reached
                  ? AppColors.brandGreen.withOpacity(0.15)
                  : AppColors.brandBlue.withOpacity(0.12),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              reached ? '🎉 Goal reached!' : '$remaining steps left',
              style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600,
                  color: reached ? AppColors.brandGreen : AppColors.brandBlue),
            ),
          ),
          const SizedBox(height: 14),
          _miniRow('🎯', 'Goal', '$goal steps'),
          const SizedBox(height: 6),
          _miniRow('📍', 'Distance', '${act.todayDistanceKm.toStringAsFixed(2)} km'),
          const SizedBox(height: 6),
          _miniRow('🔥', 'Burned', '${act.todayCalsBurned.toInt()} kcal'),
        ])),
      ]),
    );
  }

  Widget _miniRow(String emoji, String label, String value) {
    return Row(children: [
      Text(emoji, style: const TextStyle(fontSize: 12)),
      const SizedBox(width: 4),
      Text(label, style: GoogleFonts.inter(fontSize: 11, color: AppColors.textSec)),
      const Spacer(),
      Text(value, style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w700,
          color: AppColors.textPri)),
    ]);
  }

  // ── Activity Type Row ─────────────────────────────────────────────────────
  Widget _activityRow(ActivityProvider act, bool isDark) {
    // Estimate: cadence < ~7 km/h → walking, rest → running
    // Simple heuristic: if pace < 7km/h assume 80% walk / 20% run
    final walkKm = act.todayDistanceKm * 0.8;
    final runKm  = act.todayDistanceKm * 0.2;
    final activeMins = act.todaySteps ~/ 100; // rough estimate

    return Row(children: [
      _actCard('🚶', 'Walking', '${walkKm.toStringAsFixed(2)} km',
          AppColors.brandBlue, AppColors.blueBg, isDark),
      const SizedBox(width: 10),
      _actCard('🏃', 'Running', '${runKm.toStringAsFixed(2)} km',
          AppColors.brandGreen, AppColors.greenBg, isDark),
      const SizedBox(width: 10),
      _actCard('⏱', 'Active', '$activeMins min',
          AppColors.amber, AppColors.amberBg, isDark),
    ]);
  }

  Widget _actCard(String emoji, String label, String value,
      Color color, Color bg, bool isDark) {
    return Expanded(child: Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfDark : bg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(isDark ? 0.25 : 0.2)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(emoji, style: const TextStyle(fontSize: 20)),
        const SizedBox(height: 8),
        Text(value,
            style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w800, color: color)),
        Text(label,
            style: GoogleFonts.inter(fontSize: 10, color: AppColors.textSec,
                fontWeight: FontWeight.w500)),
      ]),
    ));
  }

  // ── Weekly Steps Chart ────────────────────────────────────────────────────
  Widget _weeklyChart(ActivityProvider act, bool isDark) {
    final data   = act.weeklySteps;
    final maxVal = data.isEmpty
        ? ActivityProvider.stepGoal.toDouble()
        : data.reduce((a, b) => a > b ? a : b).toDouble().clamp(100.0, double.infinity);
    const days   = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfDark : AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isDark ? AppColors.borderDark : AppColors.border),
      ),
      child: Column(children: [
        Row(children: [
          Container(
            width: 36, height: 36,
            decoration: BoxDecoration(
                color: AppColors.brandBlue.withOpacity(0.12),
                borderRadius: BorderRadius.circular(10)),
            child: const Center(child: Text('📊', style: TextStyle(fontSize: 18))),
          ),
          const SizedBox(width: 10),
          Expanded(child: Text('Weekly Steps',
              style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w700,
                  color: isDark ? AppColors.textPriDark : AppColors.textPri))),
          Text('Goal: ${ActivityProvider.stepGoal}',
              style: GoogleFonts.inter(fontSize: 11, color: AppColors.textSec)),
        ]),
        const SizedBox(height: 16),
        SizedBox(
          height: 100,
          child: Row(crossAxisAlignment: CrossAxisAlignment.end,
            children: List.generate(7, (i) {
              final val     = i < data.length ? data[i].toDouble() : 0.0;
              final h       = val > 0 ? (val / maxVal) * 80 : 4.0;
              final isToday = i == 6;
              final reached = val >= ActivityProvider.stepGoal;
              final color   = reached
                  ? AppColors.brandGreen
                  : isToday
                      ? AppColors.brandBlue
                      : AppColors.brandBlue.withOpacity(0.3);
              return Expanded(child: Column(mainAxisAlignment: MainAxisAlignment.end, children: [
                if (isToday && val > 0)
                  Text(val.toInt().toString(),
                      style: TextStyle(fontSize: 8, fontWeight: FontWeight.w700, color: color)),
                if (reached && !isToday)
                  const Text('✓', style: TextStyle(fontSize: 8, color: AppColors.brandGreen)),
                const SizedBox(height: 2),
                Container(
                  height: h,
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(6),
                    gradient: isToday
                        ? const LinearGradient(
                            colors: [AppColors.brandBlue, AppColors.brandGreen],
                            begin: Alignment.bottomCenter, end: Alignment.topCenter)
                        : null,
                    color: isToday ? null : color,
                  ),
                ),
                const SizedBox(height: 6),
                Text(days[i],
                    style: TextStyle(
                        fontSize: 10,
                        color: isToday ? AppColors.brandBlue : AppColors.textSec,
                        fontWeight: isToday ? FontWeight.w700 : FontWeight.w400)),
              ]));
            }),
          ),
        ),
      ]),
    );
  }

  // ── Badges ────────────────────────────────────────────────────────────────
  Widget _badgesSection(ActivityProvider act, bool isDark) {
    final earned = act.badges.where((b) => b.earned).length;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfDark : AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isDark ? AppColors.borderDark : AppColors.border),
      ),
      child: Column(children: [
        Row(children: [
          Container(
            width: 36, height: 36,
            decoration: BoxDecoration(
                color: AppColors.amber.withOpacity(0.12),
                borderRadius: BorderRadius.circular(10)),
            child: const Center(child: Text('🏅', style: TextStyle(fontSize: 18))),
          ),
          const SizedBox(width: 10),
          Expanded(child: Text('Badges',
              style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w700,
                  color: isDark ? AppColors.textPriDark : AppColors.textPri))),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
                color: AppColors.amberBg, borderRadius: BorderRadius.circular(20)),
            child: Text('$earned / ${act.badges.length}',
                style: GoogleFonts.inter(fontSize: 12, color: AppColors.amber,
                    fontWeight: FontWeight.w700)),
          ),
        ]),
        const SizedBox(height: 16),
        GridView.count(
          crossAxisCount: 3,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
          childAspectRatio: 0.82,
          children: act.badges.map((b) => _badgeTile(b, act, isDark)).toList(),
        ),
      ]),
    );
  }

  Widget _badgeTile(ActivityBadge b, ActivityProvider act, bool isDark) {
    if (!b.earned) return _legacyBadgeTile(b, isDark);

    return AnimatedBuilder(
      animation: _premiumCtrl,
      builder: (_, __) {
        final celebrating = act.isBadgeCelebrating(b.id);
        if (!celebrating) return _legacyBadgeTile(b, isDark);
        return _premiumBadgeTile(b, act, isDark);
      },
    );
  }

  Widget _premiumBadgeTile(ActivityBadge b, ActivityProvider act, bool isDark) {
    final t = _premiumCtrl.value;
    final unlockProgress = act.badgeCelebrationProgress(b.id);
    final remaining = (1.0 - unlockProgress).clamp(0.0, 1.0);
    final wave = 0.5 + 0.5 * math.sin(t * 2 * math.pi);
    final shimmerCenter = -1.2 + (t * 2.4);
    final borderColor = Color.lerp(
      AppColors.amber,
      AppColors.brandBlue,
      0.5 + 0.5 * math.sin((t + 0.2) * 2 * math.pi),
    )!;

    return Transform.scale(
      scale: 1.0 + (0.02 * wave),
      child: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: borderColor.withOpacity(0.90),
                width: 1.8,
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.amber.withOpacity(0.22 * remaining),
                  blurRadius: 16 + (8 * wave),
                  spreadRadius: 0.6,
                ),
                BoxShadow(
                  color: AppColors.brandBlue.withOpacity(0.18 * remaining),
                  blurRadius: 18 + (8 * wave),
                  spreadRadius: 0.4,
                ),
              ],
            ),
            child: _legacyBadgeTile(b, isDark),
          ),
          Positioned.fill(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: ShaderMask(
                shaderCallback: (rect) => LinearGradient(
                  begin: Alignment(shimmerCenter - 1, -1),
                  end: Alignment(shimmerCenter + 1, 1),
                  colors: [
                    Colors.transparent,
                    Colors.white.withOpacity(0.38 * remaining),
                    Colors.transparent,
                  ],
                  stops: const [0.35, 0.5, 0.65],
                ).createShader(rect),
                blendMode: BlendMode.srcATop,
                child: Container(color: Colors.white.withOpacity(0.02)),
              ),
            ),
          ),
          Positioned(
            top: 6,
            right: 6,
            child: Opacity(
              opacity: 0.55 + (0.45 * wave),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.brandBlue.withOpacity(0.85),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  'NEW',
                  style: GoogleFonts.inter(
                    fontSize: 8,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    letterSpacing: 0.4,
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            left: 8,
            right: 8,
            bottom: 6,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(5),
              child: LinearProgressIndicator(
                value: remaining,
                minHeight: 3,
                backgroundColor: Colors.white.withOpacity(0.26),
                valueColor: AlwaysStoppedAnimation<Color>(
                  Color.lerp(AppColors.brandBlue, AppColors.amber, remaining)!,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _legacyBadgeTile(ActivityBadge b, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: b.earned
            ? (isDark ? AppColors.surfVarDark : AppColors.amberBg)
            : (isDark ? AppColors.surfDark : AppColors.bg),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: b.earned
              ? AppColors.amber.withOpacity(0.5)
              : (isDark ? AppColors.borderDark : AppColors.border),
          width: b.earned ? 1.5 : 1,
        ),
      ),
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Text(b.earned ? b.emoji : '🔒',
            style: TextStyle(
                fontSize: 26,
                color: b.earned ? null : Colors.grey.withOpacity(0.4))),
        const SizedBox(height: 6),
        Text(b.title,
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: b.earned
                    ? (isDark ? AppColors.textPriDark : AppColors.textPri)
                    : AppColors.textSec)),
        const SizedBox(height: 2),
        Text(b.description,
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(fontSize: 9, color: AppColors.textSec, height: 1.2)),
      ]),
    );
  }
}
