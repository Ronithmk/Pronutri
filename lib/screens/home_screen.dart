import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../services/nutrition_provider.dart';
import '../services/auth_provider.dart';
import '../services/theme_provider.dart';
import '../services/habit_provider.dart';
import '../models/meal_log.dart';
import '../data/app_data.dart';
import '../data/country_meal_data.dart';
import '../theme/app_theme.dart';
import 'settings_screen.dart';
import 'progress_screen.dart';
import 'exercise_screen.dart';
import 'paywall_screen.dart';
import 'habits_screen.dart';
import 'meal_plan_screen.dart';
import 'challenges_screen.dart';
import 'video_library_screen.dart';
import 'health_report_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final p    = Provider.of<NutritionProvider>(context);
    final auth = Provider.of<AuthProvider>(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.bgDark : AppColors.bg,
      body: CustomScrollView(slivers: [
        _appBar(context, auth, isDark),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
          sliver: SliverList(delegate: SliverChildListDelegate([
            _statusBanner(context, auth, isDark),
            _calorieHero(context, p, isDark),
            const SizedBox(height: 16),
            _macroRow(context, p, isDark),
            const SizedBox(height: 16),
            _waterCard(context, p, isDark),
            const SizedBox(height: 16),
            _streakCard(context, p, isDark),
            const SizedBox(height: 16),
            _habitsCard(context, isDark),
            const SizedBox(height: 16),
            _featuresSection(context, isDark),
            const SizedBox(height: 16),
            _weeklyChart(context, p, isDark),
            const SizedBox(height: 16),
            _mealsCard(context, p, isDark),
            const SizedBox(height: 16),
            _countryMealsSection(context, auth, isDark),
            const SizedBox(height: 16),
            _workoutBanner(context, isDark),
          ])),
        ),
      ]),
    );
  }

  // ── App Bar ───────────────────────────────────────────────────────────────
  SliverAppBar _appBar(BuildContext context, AuthProvider auth, bool isDark) {
    final tp = Provider.of<ThemeProvider>(context);
    final u  = auth.currentUser;
    return SliverAppBar(
      floating: true, snap: true,
      backgroundColor: isDark ? AppColors.surfDark : AppColors.surface,
      elevation: 0, surfaceTintColor: Colors.transparent,
      title: Row(children: [
        Container(
          width: 34, height: 34,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            boxShadow: [BoxShadow(color: AppColors.brandBlue.withOpacity(0.25), blurRadius: 10, offset: const Offset(0, 4))],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Image.asset('assets/images/logo.png', fit: BoxFit.contain),
          ),
        ),
        const SizedBox(width: 10),
        Text.rich(TextSpan(children: [
          TextSpan(text: 'Pro', style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.w900, color: AppColors.brandBlue)),
          TextSpan(text: 'Nutri', style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.w900, color: AppColors.brandGreen)),
        ])),
      ]),
      actions: [
        IconButton(
          onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ProgressScreen())),
          icon: Icon(Icons.bar_chart_rounded, color: isDark ? AppColors.textPriDark : AppColors.textPri),
        ),
        IconButton(
          onPressed: tp.toggleTheme,
          icon: Icon(tp.isDark ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
              color: isDark ? AppColors.textPriDark : AppColors.textPri),
        ),
        GestureDetector(
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsScreen())),
          child: Container(
            margin: const EdgeInsets.only(right: 14),
            child: Container(
              width: 36, height: 36,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  colors: [AppColors.brandBlue, AppColors.brandGreen],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(color: AppColors.brandBlue.withOpacity(0.35), blurRadius: 10, offset: const Offset(0, 4)),
                ],
              ),
              child: Center(
                child: Text(
                  (u != null && u.name.isNotEmpty) ? u.name[0].toUpperCase() : 'U',
                  style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w800, color: Colors.white),
                ),
              ),
            ),
          ),
        ),
      ],
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Container(height: 1, color: (isDark ? AppColors.borderDark : AppColors.border).withOpacity(0.5)),
      ),
    );
  }

  // ── Status Banner (trial / credits) ──────────────────────────────────────
  Widget _statusBanner(BuildContext context, AuthProvider auth, bool isDark) {
    final u = auth.currentUser;
    if (u == null) return const SizedBox.shrink();

    final credits   = u.credits;
    final isPro     = u.subscriptionActive;
    final isTrial   = u.isTrialActive;
    final daysLeft  = u.trialDaysLeft;
    final hasAccess = u.hasAccess;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: Clay.card(isDark: isDark, radius: 22),
      child: Row(children: [
        // Credits pill
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: Clay.pill(color: credits > 10 ? AppColors.brandGreen : AppColors.accent, opacity: 0.15),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            const Text('⚡', style: TextStyle(fontSize: 12)),
            const SizedBox(width: 4),
            Text('$credits credits',
              style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w700,
                color: credits > 10 ? AppColors.brandGreen : AppColors.accent)),
          ]),
        ),
        const SizedBox(width: 8),
        // Plan pill
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: Clay.pill(
            color: isPro ? AppColors.brandBlue : isTrial ? AppColors.amber : AppColors.accent,
            opacity: 0.15,
          ),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Text(isPro ? '👑' : isTrial ? '⏳' : '🔒', style: const TextStyle(fontSize: 12)),
            const SizedBox(width: 4),
            Text(
              isPro ? 'Pro' : isTrial ? '$daysLeft days left' : 'Trial ended',
              style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w700,
                color: isPro ? AppColors.brandBlue : isTrial ? AppColors.amber : AppColors.accent)),
          ]),
        ),
        const Spacer(),
        if (!hasAccess || credits == 0)
          GestureDetector(
            onTap: () => Navigator.push(context, MaterialPageRoute(
              builder: (_) => PaywallScreen(reason: credits == 0 ? 'no_credits' : 'trial_expired'))),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [AppColors.brandBlue, AppColors.brandGreen]),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [BoxShadow(color: AppColors.brandBlue.withOpacity(0.35), blurRadius: 10, offset: const Offset(0, 4))],
              ),
              child: Text('Upgrade', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.white)),
            ),
          ),
      ]),
    );
  }

  // ── Calorie Hero Card ─────────────────────────────────────────────────────
  Widget _calorieHero(BuildContext context, NutritionProvider p, bool isDark) {
    final remaining = (p.calorieGoal - p.todayCalories).clamp(0, p.calorieGoal);

    return Container(
      padding: const EdgeInsets.all(22),
      decoration: Clay.gradientCard(
        isDark: isDark,
        colors: isDark
          ? [const Color(0xFF0D1F3C), const Color(0xFF0A2A1A)]
          : [const Color(0xFFE8F2FF), const Color(0xFFDFF5EA)],
        radius: 30,
        shadowColor: AppColors.brandBlue,
      ),
      child: Row(children: [
        // Circular progress
        SizedBox(width: 124, height: 124, child: Stack(alignment: Alignment.center, children: [
          Container(
            width: 124, height: 124,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(color: AppColors.brandBlue.withOpacity(0.2), blurRadius: 20, offset: const Offset(0, 8)),
                BoxShadow(color: Colors.white.withOpacity(isDark ? 0.04 : 0.6), blurRadius: 6, offset: const Offset(-2, -2)),
              ],
            ),
          ),
          SizedBox(width: 124, height: 124, child: CircularProgressIndicator(
            value: p.calorieProgress,
            strokeWidth: 11,
            backgroundColor: AppColors.brandBlue.withOpacity(0.10),
            valueColor: const AlwaysStoppedAnimation(AppColors.brandBlue),
            strokeCap: StrokeCap.round,
          )),
          Column(mainAxisSize: MainAxisSize.min, children: [
            Text(p.todayCalories.toInt().toString(),
              style: GoogleFonts.inter(fontSize: 24, fontWeight: FontWeight.w900,
                color: isDark ? AppColors.textPriDark : AppColors.textPri)),
            Text('/ ${p.calorieGoal.toInt()}',
              style: GoogleFonts.inter(fontSize: 10, color: AppColors.textSec)),
            Text('kcal', style: GoogleFonts.inter(fontSize: 10, color: AppColors.brandBlue, fontWeight: FontWeight.w700)),
          ]),
        ])),
        const SizedBox(width: 18),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text("Today's Calories",
            style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w700,
              color: isDark ? AppColors.textPriDark : AppColors.textPri)),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: Clay.pill(
              color: remaining == 0 ? AppColors.brandGreen : AppColors.brandBlue,
              opacity: 0.15,
            ),
            child: Text('${remaining.toInt()} kcal left',
              style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600,
                color: remaining == 0 ? AppColors.brandGreen : AppColors.brandBlue)),
          ),
          const SizedBox(height: 16),
          _miniBar('Protein', p.proteinProgress, p.todayProtein, p.proteinGoal, 'g', AppColors.brandGreen),
          const SizedBox(height: 8),
          _miniBar('Carbs',   p.carbsProgress,   p.todayCarbs,   p.carbsGoal,   'g', AppColors.amber),
          const SizedBox(height: 8),
          _miniBar('Fat',     p.fatProgress,      p.todayFat,     p.fatGoal,     'g', AppColors.accent),
        ])),
      ]),
    );
  }

  Widget _miniBar(String label, double progress, double val, double goal, String unit, Color color) {
    return Row(children: [
      SizedBox(width: 46, child: Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: AppColors.textSec))),
      Expanded(child: Container(
        height: 7,
        decoration: BoxDecoration(
          color: color.withOpacity(0.12),
          borderRadius: BorderRadius.circular(6),
        ),
        child: FractionallySizedBox(
          alignment: Alignment.centerLeft,
          widthFactor: progress.clamp(0.0, 1.0),
          child: Container(
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(6),
              boxShadow: [BoxShadow(color: color.withOpacity(0.4), blurRadius: 4, offset: const Offset(0, 2))],
            ),
          ),
        ),
      )),
      const SizedBox(width: 6),
      Text('${val.toInt()}$unit', style: TextStyle(fontSize: 10, color: color, fontWeight: FontWeight.w700)),
    ]);
  }

  // ── Macro Pills Row ───────────────────────────────────────────────────────
  Widget _macroRow(BuildContext context, NutritionProvider p, bool isDark) {
    return Row(children: [
      _macroPill('💪', 'Protein', p.todayProtein, 'g', AppColors.brandGreen, isDark),
      const SizedBox(width: 10),
      _macroPill('🌾', 'Carbs',   p.todayCarbs,   'g', AppColors.amber,      isDark),
      const SizedBox(width: 10),
      _macroPill('🧈', 'Fat',     p.todayFat,     'g', AppColors.accent,     isDark),
      const SizedBox(width: 10),
      _macroPill('💧', 'Water',   p.todayWaterMl / 1000, 'L', AppColors.brandBlue, isDark),
    ]);
  }

  Widget _macroPill(String emoji, String label, double val, String unit, Color color, bool isDark) {
    return Expanded(child: Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfDark : color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(isDark ? 0.2 : 0.14),
            blurRadius: 18,
            spreadRadius: -3,
            offset: const Offset(0, 8),
          ),
          BoxShadow(
            color: Colors.white.withOpacity(isDark ? 0.04 : 0.8),
            blurRadius: 4,
            spreadRadius: -1,
            offset: const Offset(-1, -1),
          ),
        ],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(emoji, style: const TextStyle(fontSize: 22)),
        const SizedBox(height: 8),
        Text(
          val >= 10 ? '${val.toStringAsFixed(0)}$unit' : '${val.toStringAsFixed(1)}$unit',
          style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w800, color: color),
        ),
        Text(label, style: GoogleFonts.inter(fontSize: 10, color: AppColors.textSec, fontWeight: FontWeight.w500)),
      ]),
    ));
  }

  // ── Water Tracker ─────────────────────────────────────────────────────────
  Widget _waterCard(BuildContext context, NutritionProvider p, bool isDark) {
    final glasses   = (p.todayWaterMl / 250).floor().clamp(0, 8);
    final totalL    = (p.todayWaterMl / 1000).toStringAsFixed(1);
    final goalL     = (p.waterGoal    / 1000).toStringAsFixed(1);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: Clay.card(isDark: isDark, radius: 28),
      child: Column(children: [
        Row(children: [
          Container(
            width: 40, height: 40,
            decoration: Clay.icon(color: AppColors.brandBlue, radius: 14, isDark: isDark),
            child: const Center(child: Text('💧', style: TextStyle(fontSize: 20))),
          ),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Water Intake', style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w700,
              color: isDark ? AppColors.textPriDark : AppColors.textPri)),
            Text('$totalL / ${goalL}L today', style: GoogleFonts.inter(fontSize: 11, color: AppColors.brandBlue, fontWeight: FontWeight.w600)),
          ])),
          Row(mainAxisSize: MainAxisSize.min, children: [
            // Undo last glass — 48px tap target
            Semantics(
              label: 'Undo last water glass',
              button: true,
              child: InkWell(
                onTap: () async {
                  final removed = await Provider.of<NutritionProvider>(context, listen: false).undoLastWater();
                  if (removed && context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      content: const Text('Last glass removed'),
                      backgroundColor: AppColors.brandBlue,
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      duration: const Duration(seconds: 2),
                    ));
                  }
                },
                borderRadius: BorderRadius.circular(18),
                child: Container(
                  width: 48, height: 48,
                  margin: const EdgeInsets.only(right: 6),
                  decoration: BoxDecoration(
                    border: Border.all(color: AppColors.brandBlue.withOpacity(0.35)),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: const Icon(Icons.undo_rounded, color: AppColors.brandBlue, size: 18),
                ),
              ),
            ),
            // Add 250ml
            GestureDetector(
              onTap: () => Provider.of<NutritionProvider>(context, listen: false).addWater(250),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [AppColors.brandBlue, Color(0xFF2590E8)]),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [BoxShadow(color: AppColors.brandBlue.withOpacity(0.35), blurRadius: 12, offset: const Offset(0, 5))],
                ),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  const Icon(Icons.add, color: Colors.white, size: 14),
                  const SizedBox(width: 4),
                  Text('250ml', style: GoogleFonts.inter(fontSize: 12, color: Colors.white, fontWeight: FontWeight.w600)),
                ]),
              ),
            ),
          ]),
        ]),
        const SizedBox(height: 18),
        // Progress bar
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: LinearProgressIndicator(
            value: p.waterProgress.clamp(0.0, 1.0),
            minHeight: 10,
            backgroundColor: AppColors.brandBlue.withOpacity(0.1),
            valueColor: const AlwaysStoppedAnimation(AppColors.brandBlue),
          ),
        ),
        const SizedBox(height: 16),
        // Glass indicators — tapping an empty glass adds 250ml, tapping filled does nothing
        Row(children: [
          ...List.generate(8, (i) {
            final filled = i < glasses;
            return Expanded(child: Semantics(
              label: filled ? 'Glass ${i + 1} filled' : 'Tap to add glass ${i + 1}',
              button: !filled,
              child: InkWell(
                onTap: filled ? null : () => Provider.of<NutritionProvider>(context, listen: false).addWater(250),
                borderRadius: BorderRadius.circular(12),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  height: 44,
                  decoration: BoxDecoration(
                    gradient: filled
                      ? const LinearGradient(colors: [AppColors.brandBlue, Color(0xFF56CCF2)], begin: Alignment.topLeft, end: Alignment.bottomRight)
                      : null,
                    color: filled ? null : (isDark ? AppColors.surfVarDark : AppColors.blueBg.withOpacity(0.6)),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: filled
                      ? [BoxShadow(color: AppColors.brandBlue.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 4))]
                      : [BoxShadow(color: AppColors.brandBlue.withOpacity(0.08), blurRadius: 4, offset: const Offset(0, 2))],
                  ),
                  child: Center(child: Icon(
                    filled ? Icons.water_drop : Icons.water_drop_outlined,
                    size: 18,
                    color: filled ? Colors.white : AppColors.brandBlue.withOpacity(0.4),
                  )),
                ),
              ),
            ));
          }),
        ]),
        const SizedBox(height: 10),
        Text('Tap an empty glass or + 250ml to log water', style: GoogleFonts.inter(fontSize: 10, color: AppColors.textSec)),
      ]),
    );
  }

  // ── Streak Card ───────────────────────────────────────────────────────────
  Widget _streakCard(BuildContext context, NutritionProvider p, bool isDark) {
    final days       = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
    final todayIndex = DateTime.now().weekday - 1; // 0=Mon, 6=Sun
    final weekly     = p.weeklyCalories; // last 7 days ending today (index 6 = today)

    // Map weeklyCalories (index 0 = 6 days ago) to weekday index
    // today is weekday-1; day i in weeklyCalories was (6-i) days ago
    // weekday index for weekly[i] = (todayIndex - (6 - i) + 7) % 7
    bool loggedOnWeekday(int weekdayIdx) {
      for (int i = 0; i < 7; i++) {
        final wdIdx = (todayIndex - (6 - i) + 7) % 7;
        if (wdIdx == weekdayIdx) return weekly[i] > 0;
      }
      return false;
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: Clay.card(isDark: isDark, radius: 28),
      child: Column(children: [
        Row(children: [
          Container(
            width: 40, height: 40,
            decoration: Clay.icon(color: AppColors.amber, radius: 14, isDark: isDark),
            child: const Center(child: Text('🔥', style: TextStyle(fontSize: 20))),
          ),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('${p.currentStreak}-Day Streak', style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w700,
              color: isDark ? AppColors.textPriDark : AppColors.textPri)),
            Text(p.currentStreak > 0 ? 'You\'re on fire! Keep going 💪' : 'Log a meal to start your streak',
              style: GoogleFonts.inter(fontSize: 11, color: AppColors.textSec)),
          ])),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
            decoration: Clay.pill(color: AppColors.amber, opacity: 0.18),
            child: Text('${p.currentStreak} 🔥', style: GoogleFonts.inter(fontSize: 13, color: AppColors.amber, fontWeight: FontWeight.w700)),
          ),
        ]),
        const SizedBox(height: 18),
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: List.generate(7, (i) {
          final isToday = i == todayIndex;
          final done    = loggedOnWeekday(i) && !isToday;
          final todayLogged = isToday && loggedOnWeekday(i);
          return Column(children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              width: 40, height: 40,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: done || todayLogged
                  ? const LinearGradient(colors: [AppColors.brandBlue, AppColors.brandGreen], begin: Alignment.topLeft, end: Alignment.bottomRight)
                  : null,
                color: (done || todayLogged) ? null : isToday
                  ? AppColors.amber.withOpacity(0.18)
                  : isDark ? AppColors.surfVarDark : AppColors.surfaceVar,
                border: isToday && !todayLogged ? Border.all(color: AppColors.amber, width: 2.5) : null,
                boxShadow: done || todayLogged
                  ? [BoxShadow(color: AppColors.brandBlue.withOpacity(0.35), blurRadius: 10, offset: const Offset(0, 4))]
                  : isToday
                    ? [BoxShadow(color: AppColors.amber.withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 4))]
                    : null,
              ),
              child: Center(child: done || todayLogged
                ? const Icon(Icons.check_rounded, color: Colors.white, size: 18)
                : Text(days[i], style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700,
                    color: isToday ? AppColors.amber : isDark ? AppColors.textSecDark : AppColors.textSec))),
            ),
            const SizedBox(height: 4),
            Text(days[i], style: GoogleFonts.inter(fontSize: 9, color: AppColors.textSec)),
          ]);
        })),
      ]),
    );
  }

  // ── Habits Preview Card ───────────────────────────────────────────────────
  Widget _habitsCard(BuildContext context, bool isDark) {
    final h = Provider.of<HabitProvider>(context);
    final done = h.completedToday;
    final mood = h.moodToday;
    const moodEmojis = ['', '😔', '😕', '😐', '🙂', '😄'];

    return GestureDetector(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const HabitsScreen())),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: Clay.card(isDark: isDark, radius: 28),
        child: Column(children: [
          Row(children: [
            Container(
              width: 40, height: 40,
              decoration: Clay.icon(color: AppColors.purple, radius: 14, isDark: isDark),
              child: const Center(child: Text('🏆', style: TextStyle(fontSize: 20))),
            ),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Daily Habits', style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w700,
                color: isDark ? AppColors.textPriDark : AppColors.textPri)),
              Text('$done/5 completed today',
                style: GoogleFonts.inter(fontSize: 11,
                  color: done == 5 ? AppColors.brandGreen : AppColors.textSec)),
            ])),
            if (mood != null)
              Text(moodEmojis[mood], style: const TextStyle(fontSize: 24)),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: Clay.pill(color: AppColors.purple, opacity: 0.12),
              child: Text('View →', style: GoogleFonts.inter(fontSize: 12, color: AppColors.purple, fontWeight: FontWeight.w600)),
            ),
          ]),
          const SizedBox(height: 14),
          Row(children: [
            _habitDot('💧', h.waterDone),
            const SizedBox(width: 8),
            _habitDot('😴', h.sleepDone),
            const SizedBox(width: 8),
            _habitDot('🚶', h.stepsDone),
            const SizedBox(width: 8),
            _habitDot('🥗', h.junkFreeDone),
            const SizedBox(width: 8),
            _habitDot('🍽', h.mealDone),
            const Spacer(),
            if (h.currentStreak > 0)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: Clay.pill(color: AppColors.amber, opacity: 0.15),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  const Text('🔥', style: TextStyle(fontSize: 11)),
                  const SizedBox(width: 4),
                  Text('${h.currentStreak} day streak',
                    style: GoogleFonts.inter(fontSize: 11, color: AppColors.amber, fontWeight: FontWeight.w700)),
                ]),
              ),
          ]),
        ]),
      ),
    );
  }

  Widget _habitDot(String emoji, bool done) => Container(
    width: 38, height: 38,
    decoration: BoxDecoration(
      color: done ? AppColors.brandGreen.withOpacity(0.12) : AppColors.surfaceVar,
      shape: BoxShape.circle,
      border: done ? Border.all(color: AppColors.brandGreen.withOpacity(0.4)) : null,
    ),
    child: Center(child: Text(emoji, style: TextStyle(fontSize: 18, color: done ? null : const Color(0xFFCCCCCC)))),
  );

  // ── Weekly Chart ──────────────────────────────────────────────────────────
  Widget _weeklyChart(BuildContext context, NutritionProvider p, bool isDark) {
    final data   = p.weeklyCalories;
    final maxVal = data.reduce((a, b) => a > b ? a : b).clamp(100.0, double.infinity);
    final days   = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: Clay.card(isDark: isDark, radius: 28),
      child: Column(children: [
        Row(children: [
          Container(width: 40, height: 40, decoration: Clay.icon(color: AppColors.brandGreen, radius: 14, isDark: isDark), child: const Center(child: Text('📊', style: TextStyle(fontSize: 20)))),
          const SizedBox(width: 12),
          Expanded(child: Text('Weekly Calories', style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w700, color: isDark ? AppColors.textPriDark : AppColors.textPri))),
          GestureDetector(
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ProgressScreen())),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: Clay.pill(color: AppColors.brandBlue, opacity: 0.12),
              child: Text('View all →', style: GoogleFonts.inter(fontSize: 12, color: AppColors.brandBlue, fontWeight: FontWeight.w600)),
            ),
          ),
        ]),
        const SizedBox(height: 18),
        SizedBox(height: 96, child: Row(crossAxisAlignment: CrossAxisAlignment.end, children: List.generate(7, (i) {
          final h       = data[i] > 0 ? (data[i] / maxVal) * 76 : 5.0;
          final isToday = i == 6;
          final over    = data[i] > p.calorieGoal;
          final color   = over ? AppColors.accent : isToday ? AppColors.brandBlue : AppColors.brandBlue.withOpacity(0.3);
          return Expanded(child: Column(mainAxisAlignment: MainAxisAlignment.end, children: [
            if (data[i] > 0 && isToday)
              Text('${data[i].toInt()}', style: TextStyle(fontSize: 8, fontWeight: FontWeight.w700, color: color)),
            const SizedBox(height: 2),
            Container(
              height: h,
              margin: const EdgeInsets.symmetric(horizontal: 4),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                gradient: isToday
                  ? const LinearGradient(colors: [AppColors.brandBlue, AppColors.brandGreen], begin: Alignment.bottomCenter, end: Alignment.topCenter)
                  : null,
                color: isToday ? null : color,
                boxShadow: isToday
                  ? [BoxShadow(color: AppColors.brandBlue.withOpacity(0.35), blurRadius: 8, offset: const Offset(0, 4))]
                  : data[i] > 0
                    ? [BoxShadow(color: color.withOpacity(0.25), blurRadius: 6, offset: const Offset(0, 3))]
                    : null,
              ),
            ),
            const SizedBox(height: 6),
            Text(days[i], style: TextStyle(fontSize: 10, color: isToday ? AppColors.brandBlue : AppColors.textSec, fontWeight: isToday ? FontWeight.w700 : FontWeight.w400)),
          ]));
        }))),
      ]),
    );
  }

  // ── Meals Card ────────────────────────────────────────────────────────────
  Widget _mealsCard(BuildContext context, NutritionProvider p, bool isDark) {
    final meals = p.todayMeals;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: Clay.card(isDark: isDark, radius: 28),
      child: Column(children: [
        Row(children: [
          Container(width: 40, height: 40, decoration: Clay.icon(color: AppColors.brandGreen, radius: 14, isDark: isDark), child: const Center(child: Text('🍽', style: TextStyle(fontSize: 20)))),
          const SizedBox(width: 12),
          Expanded(child: Text("Today's Meals", style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w700, color: isDark ? AppColors.textPriDark : AppColors.textPri))),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: Clay.pill(color: AppColors.brandGreen, opacity: 0.15),
            child: Text('${meals.length} logged', style: GoogleFonts.inter(fontSize: 11, color: AppColors.brandGreen, fontWeight: FontWeight.w600)),
          ),
        ]),
        const SizedBox(height: 16),
        if (meals.isEmpty)
          _emptyMeals(isDark)
        else ...[
          ...meals.take(4).map((m) => _mealTile(context, m, p, isDark)),
          if (meals.length > 4)
            GestureDetector(
              onTap: () => _showAllMeals(context, meals, p, isDark),
              child: Container(
                margin: const EdgeInsets.only(top: 4),
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: AppColors.brandGreen.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Center(child: Text(
                  'See all ${meals.length} meals →',
                  style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.brandGreen),
                )),
              ),
            ),
        ],
      ]),
    );
  }

  void _showAllMeals(BuildContext context, List<MealLog> meals, NutritionProvider p, bool isDark) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.92,
        minChildSize: 0.4,
        builder: (_, ctrl) => Container(
          decoration: BoxDecoration(
            color: isDark ? AppColors.surfDark : AppColors.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: Column(children: [
            const SizedBox(height: 12),
            Container(width: 40, height: 4, decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(children: [
                Text("Today's Meals", style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700,
                  color: isDark ? AppColors.textPriDark : AppColors.textPri)),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: Clay.pill(color: AppColors.brandGreen, opacity: 0.15),
                  child: Text('${meals.length} logged', style: GoogleFonts.inter(fontSize: 11, color: AppColors.brandGreen, fontWeight: FontWeight.w600)),
                ),
              ]),
            ),
            const SizedBox(height: 12),
            Expanded(child: ListView.builder(
              controller: ctrl,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              itemCount: meals.length,
              itemBuilder: (_, i) => _mealTile(context, meals[i], p, isDark),
            )),
          ]),
        ),
      ),
    );
  }

  Widget _emptyMeals(bool isDark) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 24),
    child: Column(children: [
      Container(
        width: 70, height: 70,
        decoration: BoxDecoration(
          color: AppColors.brandGreen.withOpacity(0.10),
          shape: BoxShape.circle,
          boxShadow: [BoxShadow(color: AppColors.brandGreen.withOpacity(0.15), blurRadius: 16, offset: const Offset(0, 6))],
        ),
        child: const Center(child: Text('🌱', style: TextStyle(fontSize: 32))),
      ),
      const SizedBox(height: 14),
      Text('No meals logged yet', style: GoogleFonts.inter(color: AppColors.textSec, fontSize: 14, fontWeight: FontWeight.w500)),
      const SizedBox(height: 4),
      Text('Tap "Log" in the menu below to start', style: GoogleFonts.inter(color: AppColors.textSec.withOpacity(0.6), fontSize: 12)),
    ]),
  );

  Widget _mealTile(BuildContext context, MealLog m, NutritionProvider p, bool isDark) {
    final bgMap  = {'Breakfast': AppColors.greenBg, 'Lunch': AppColors.amberBg, 'Dinner': AppColors.accentBg, 'Snack': AppColors.blueBg};
    final colMap = {'Breakfast': AppColors.brandGreen, 'Lunch': AppColors.amber, 'Dinner': AppColors.accent, 'Snack': AppColors.brandBlue};
    final bg  = bgMap[m.mealType] ?? AppColors.surfaceVar;
    final col = colMap[m.mealType] ?? AppColors.brandBlue;

    return Dismissible(
      key: Key(m.key.toString()),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(color: AppColors.accent.withOpacity(0.12), borderRadius: BorderRadius.circular(18)),
        child: const Icon(Icons.delete_outline, color: AppColors.accent),
      ),
      onDismissed: (_) => p.deleteMeal(m),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(13),
        decoration: BoxDecoration(
          color: isDark ? AppColors.surfVarDark : AppColors.bg,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: col.withOpacity(isDark ? 0.12 : 0.08),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(children: [
          Container(
            width: 46, height: 46,
            decoration: BoxDecoration(
              color: isDark ? AppColors.surfDark : bg,
              borderRadius: BorderRadius.circular(14),
              boxShadow: [BoxShadow(color: col.withOpacity(0.18), blurRadius: 8, offset: const Offset(0, 3))],
            ),
            child: Center(child: Text(m.emoji, style: const TextStyle(fontSize: 22))),
          ),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(m.foodName, style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w700, color: isDark ? AppColors.textPriDark : AppColors.textPri)),
            const SizedBox(height: 3),
            Row(children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(color: col.withOpacity(0.12), borderRadius: BorderRadius.circular(8)),
                child: Text(m.mealType, style: GoogleFonts.inter(fontSize: 10, color: col, fontWeight: FontWeight.w600)),
              ),
              const SizedBox(width: 6),
              Text(DateFormat('h:mm a').format(m.loggedAt), style: GoogleFonts.inter(fontSize: 10, color: AppColors.textSec)),
            ]),
            const SizedBox(height: 5),
            // Macro breakdown
            Row(children: [
              _macroTag('P', (m.protein * m.quantity).toInt(), AppColors.brandGreen),
              const SizedBox(width: 5),
              _macroTag('C', (m.carbs * m.quantity).toInt(), AppColors.amber),
              const SizedBox(width: 5),
              _macroTag('F', (m.fat * m.quantity).toInt(), AppColors.accent),
            ]),
          ])),
          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Text('${(m.calories * m.quantity).toInt()}', style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w800, color: AppColors.brandBlue)),
            Text('kcal', style: GoogleFonts.inter(fontSize: 10, color: AppColors.textSec)),
          ]),
        ]),
      ),
    );
  }

  // ── Workout Banner ────────────────────────────────────────────────────────
  Widget _workoutBanner(BuildContext context, bool isDark) {
    // Pick an exercise based on the day of week so it rotates daily
    const exercises = AppData.exercises;
    final exercise  = exercises[DateTime.now().weekday % exercises.length];

    return GestureDetector(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ExerciseScreen())),
      child: Container(
        padding: const EdgeInsets.all(22),
        decoration: Clay.gradientCard(
          isDark: isDark,
          colors: [AppColors.brandDark, AppColors.brandBlue, const Color(0xFF1BA874)],
          radius: 30,
          shadowColor: AppColors.brandBlue,
        ),
        child: Row(children: [
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.18),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text("Today's Workout", style: GoogleFonts.inter(fontSize: 11, color: Colors.white70, fontWeight: FontWeight.w600)),
            ),
            const SizedBox(height: 12),
            Text(exercise.name, style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w800, color: Colors.white)),
            const SizedBox(height: 6),
            Row(children: [
              _wTag(Icons.timer_outlined, exercise.duration),
              const SizedBox(width: 8),
              _wTag(Icons.local_fire_department_outlined, '${exercise.caloriesBurned} kcal'),
            ]),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(22),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.15), blurRadius: 10, offset: const Offset(0, 4))],
              ),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Text('Start Workout', style: GoogleFonts.inter(color: AppColors.brandBlue, fontSize: 13, fontWeight: FontWeight.w700)),
                const SizedBox(width: 6),
                const Icon(Icons.arrow_forward_rounded, color: AppColors.brandBlue, size: 14),
              ]),
            ),
          ])),
          Text(exercise.emoji, style: const TextStyle(fontSize: 60)),
        ]),
      ),
    );
  }

  // ── Features Grid ─────────────────────────────────────────────────────────
  Widget _featuresSection(BuildContext context, bool isDark) {
    final features = [
      (
        '🗓', 'Meal Planner', 'Weekly plan + grocery list',
        AppColors.brandGreen,
        () => Navigator.push(context, MaterialPageRoute(builder: (_) => const MealPlanScreen())),
      ),
      (
        '🏆', 'Challenges', 'Track your fitness goals',
        AppColors.amber,
        () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ChallengesScreen())),
      ),
      (
        '▶️', 'Video Library', 'Workout videos on demand',
        AppColors.brandBlue,
        () => Navigator.push(context, MaterialPageRoute(builder: (_) => const VideoLibraryScreen())),
      ),
      (
        '📄', 'Health Report', 'Export your progress as PDF',
        AppColors.purple,
        () => Navigator.push(context, MaterialPageRoute(builder: (_) => const HealthReportScreen())),
      ),
    ];

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('Quick Access',
          style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w700,
              color: isDark ? AppColors.textPriDark : AppColors.textPri)),
      const SizedBox(height: 10),
      GridView.count(
        crossAxisCount: 2,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: 2.0,
        children: features.map((f) {
          final (emoji, title, subtitle, color, onTap) = f;
          return GestureDetector(
            onTap: onTap,
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: isDark ? AppColors.surfDark : AppColors.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: isDark ? AppColors.borderDark : AppColors.border),
              ),
              child: Row(children: [
                Text(emoji, style: const TextStyle(fontSize: 26)),
                const SizedBox(width: 10),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center, children: [
                  Text(title, style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w700,
                      color: isDark ? AppColors.textPriDark : AppColors.textPri)),
                  Text(subtitle, maxLines: 1, overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(fontSize: 10,
                          color: isDark ? AppColors.textSecDark : AppColors.textSec)),
                ])),
              ]),
            ),
          );
        }).toList(),
      ),
    ]);
  }

  Widget _wTag(IconData icon, String label) => Row(mainAxisSize: MainAxisSize.min, children: [
    Icon(icon, color: Colors.white70, size: 13),
    const SizedBox(width: 3),
    Text(label, style: GoogleFonts.inter(fontSize: 12, color: Colors.white70, fontWeight: FontWeight.w500)),
  ]);

  Widget _macroTag(String label, int val, Color color) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
    decoration: BoxDecoration(
      color: color.withOpacity(0.12),
      borderRadius: BorderRadius.circular(6),
    ),
    child: Text('$label: ${val}g', style: GoogleFonts.inter(fontSize: 9, fontWeight: FontWeight.w600, color: color)),
  );

  // ── Country-based meal suggestions ────────────────────────────────────────
  Widget _countryMealsSection(BuildContext context, AuthProvider auth, bool isDark) {
    final country = auth.currentUser?.country ?? 'India';
    final cuisine = cuisineFor(country);

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      // Header
      Row(children: [
        Text(cuisine.flag, style: const TextStyle(fontSize: 18)),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            'Meals from Your Country',
            style: GoogleFonts.inter(
              fontSize: 16, fontWeight: FontWeight.w700,
              color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: AppColors.brandGreen.withOpacity(0.12),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            cuisine.cuisineName,
            style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.brandGreen),
          ),
        ),
      ]),
      const SizedBox(height: 12),
      SizedBox(
        height: 150,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: cuisine.meals.length,
          separatorBuilder: (_, __) => const SizedBox(width: 12),
          itemBuilder: (_, i) => _CountryMealCard(meal: cuisine.meals[i], isDark: isDark),
        ),
      ),
    ]);
  }
}

// ── Country meal card ─────────────────────────────────────────────────────────
class _CountryMealCard extends StatelessWidget {
  final CountryMeal meal;
  final bool isDark;
  const _CountryMealCard({required this.meal, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 140,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: isDark ? AppColors.borderDark : AppColors.border),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8, offset: const Offset(0, 3))],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(meal.emoji, style: const TextStyle(fontSize: 28)),
        const SizedBox(height: 6),
        Text(
          meal.name,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: GoogleFonts.inter(
            fontSize: 12, fontWeight: FontWeight.w600,
            color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
            height: 1.3,
          ),
        ),
        const Spacer(),
        Row(children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
            decoration: BoxDecoration(
              color: AppColors.accent.withOpacity(0.10),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text('${meal.calories} kcal',
                style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.accent)),
          ),
          const SizedBox(width: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.10),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text('${meal.protein}g P',
                style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.primary)),
          ),
        ]),
      ]),
    );
  }
}
