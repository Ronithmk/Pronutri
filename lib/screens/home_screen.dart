import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../services/nutrition_provider.dart';
import '../services/auth_provider.dart';
import '../services/theme_provider.dart';
import '../models/meal_log.dart';
import '../theme/app_theme.dart';
import 'settings_screen.dart';
import 'progress_screen.dart';
import 'exercise_screen.dart';

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
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
          sliver: SliverList(delegate: SliverChildListDelegate([
            _calorieHero(context, p, isDark),
            const SizedBox(height: 14),
            _macroRow(context, p, isDark),
            const SizedBox(height: 14),
            _waterCard(context, p, isDark),
            const SizedBox(height: 14),
            _streakCard(context, p, isDark),
            const SizedBox(height: 14),
            _weeklyChart(context, p, isDark),
            const SizedBox(height: 14),
            _mealsCard(context, p, isDark),
            const SizedBox(height: 14),
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
          width: 32, height: 32,
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(8)),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.asset('assets/images/logo.png', fit: BoxFit.contain),
          ),
        ),
        const SizedBox(width: 8),
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
            child: CircleAvatar(
              radius: 17,
              backgroundColor: AppColors.brandBlue.withOpacity(0.12),
              child: Text(
                u?.name.isNotEmpty == true ? u!.name[0].toUpperCase() : 'U',
                style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.brandBlue),
              ),
            ),
          ),
        ),
      ],
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Divider(height: 1, color: isDark ? AppColors.borderDark : AppColors.border),
      ),
    );
  }

  // ── Calorie Hero Card ─────────────────────────────────────────────────────
  Widget _calorieHero(BuildContext context, NutritionProvider p, bool isDark) {
    final remaining = (p.calorieGoal - p.todayCalories).clamp(0, p.calorieGoal);
    final pct = (p.calorieProgress * 100).toInt();

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
        border: Border.all(color: AppColors.brandBlue.withOpacity(0.15), width: 1),
      ),
      child: Row(children: [
        // Circular progress
        SizedBox(width: 120, height: 120, child: Stack(alignment: Alignment.center, children: [
          SizedBox(width: 120, height: 120, child: CircularProgressIndicator(
            value: p.calorieProgress,
            strokeWidth: 10,
            backgroundColor: AppColors.brandBlue.withOpacity(0.12),
            valueColor: AlwaysStoppedAnimation(AppColors.brandBlue),
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
          const SizedBox(height: 4),
          Row(children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: remaining == 0 ? AppColors.brandGreen.withOpacity(0.15) : AppColors.brandBlue.withOpacity(0.12),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text('${remaining.toInt()} kcal left',
                style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600,
                  color: remaining == 0 ? AppColors.brandGreen : AppColors.brandBlue)),
            ),
          ]),
          const SizedBox(height: 14),
          _miniBar('Protein', p.proteinProgress, p.todayProtein, p.proteinGoal, 'g', AppColors.brandGreen),
          const SizedBox(height: 6),
          _miniBar('Carbs',   p.carbsProgress,   p.todayCarbs,   p.carbsGoal,   'g', AppColors.amber),
          const SizedBox(height: 6),
          _miniBar('Fat',     p.fatProgress,      p.todayFat,     p.fatGoal,     'g', AppColors.accent),
        ])),
      ]),
    );
  }

  Widget _miniBar(String label, double progress, double val, double goal, String unit, Color color) {
    return Row(children: [
      SizedBox(width: 46, child: Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: AppColors.textSec))),
      Expanded(child: ClipRRect(
        borderRadius: BorderRadius.circular(4),
        child: LinearProgressIndicator(value: progress, minHeight: 6, backgroundColor: color.withOpacity(0.12), valueColor: AlwaysStoppedAnimation(color)),
      )),
      const SizedBox(width: 6),
      Text('${val.toInt()}$unit', style: TextStyle(fontSize: 10, color: color, fontWeight: FontWeight.w700)),
    ]);
  }

  // ── Macro Pills Row ───────────────────────────────────────────────────────
  Widget _macroRow(BuildContext context, NutritionProvider p, bool isDark) {
    return Row(children: [
      _macroPill('💪', 'Protein', p.todayProtein, 'g', AppColors.brandGreen, AppColors.greenBg, isDark),
      const SizedBox(width: 8),
      _macroPill('🌾', 'Carbs',   p.todayCarbs,   'g', AppColors.amber,      AppColors.amberBg, isDark),
      const SizedBox(width: 8),
      _macroPill('🧈', 'Fat',     p.todayFat,     'g', AppColors.accent,     AppColors.accentBg, isDark),
      const SizedBox(width: 8),
      _macroPill('💧', 'Water',   p.todayWaterMl / 1000, 'L', AppColors.brandBlue, AppColors.blueBg, isDark),
    ]);
  }

  Widget _macroPill(String emoji, String label, double val, String unit, Color color, Color bg, bool isDark) {
    return Expanded(child: Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfDark : bg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(isDark ? 0.25 : 0.2), width: 1),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(emoji, style: const TextStyle(fontSize: 20)),
        const SizedBox(height: 8),
        Text(
          val >= 10 ? val.toStringAsFixed(0) + unit : val.toStringAsFixed(1) + unit,
          style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w800, color: color),
        ),
        Text(label, style: GoogleFonts.inter(fontSize: 10, color: AppColors.textSec, fontWeight: FontWeight.w500)),
      ]),
    ));
  }

  // ── Water Tracker (FIXED) ─────────────────────────────────────────────────
  Widget _waterCard(BuildContext context, NutritionProvider p, bool isDark) {
    final glasses   = (p.todayWaterMl / 250).floor().clamp(0, 8);
    final totalL    = (p.todayWaterMl / 1000).toStringAsFixed(1);
    final goalL     = (p.waterGoal    / 1000).toStringAsFixed(1);

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
            decoration: BoxDecoration(color: AppColors.brandBlue.withOpacity(0.12), borderRadius: BorderRadius.circular(10)),
            child: const Center(child: Text('💧', style: TextStyle(fontSize: 18))),
          ),
          const SizedBox(width: 10),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Water Intake', style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w700,
              color: isDark ? AppColors.textPriDark : AppColors.textPri)),
            Text('$totalL / ${goalL}L today', style: GoogleFonts.inter(fontSize: 11, color: AppColors.brandBlue, fontWeight: FontWeight.w600)),
          ])),
          GestureDetector(
            onTap: () => Provider.of<NutritionProvider>(context, listen: false).addWater(250),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(color: AppColors.brandBlue, borderRadius: BorderRadius.circular(20)),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                const Icon(Icons.add, color: Colors.white, size: 14),
                const SizedBox(width: 4),
                Text('250ml', style: GoogleFonts.inter(fontSize: 12, color: Colors.white, fontWeight: FontWeight.w600)),
              ]),
            ),
          ),
        ]),
        const SizedBox(height: 16),

        // Progress bar
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: LinearProgressIndicator(
            value: p.waterProgress, minHeight: 8,
            backgroundColor: AppColors.brandBlue.withOpacity(0.1),
            valueColor: const AlwaysStoppedAnimation(AppColors.brandBlue),
          ),
        ),
        const SizedBox(height: 14),

        // Glass indicators — FIXED with proper filled icons
        Row(children: [
          ...List.generate(8, (i) {
            final filled = i < glasses;
            return Expanded(child: GestureDetector(
              onTap: () => Provider.of<NutritionProvider>(context, listen: false).addWater(250),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                margin: const EdgeInsets.symmetric(horizontal: 3),
                height: 40,
                decoration: BoxDecoration(
                  color: filled ? AppColors.brandBlue : (isDark ? AppColors.surfVarDark : AppColors.blueBg),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: filled ? AppColors.brandBlue : AppColors.brandBlue.withOpacity(0.25),
                    width: 1.5,
                  ),
                ),
                child: Center(child: Icon(
                  filled ? Icons.water_drop : Icons.water_drop_outlined,
                  size: 18,
                  color: filled ? Colors.white : AppColors.brandBlue.withOpacity(0.4),
                )),
              ),
            ));
          }),
        ]),
        const SizedBox(height: 8),
        Text('Tap a glass or + 250ml button to log', style: GoogleFonts.inter(fontSize: 10, color: AppColors.textSec)),
      ]),
    );
  }

  // ── Streak Card ───────────────────────────────────────────────────────────
  Widget _streakCard(BuildContext context, NutritionProvider p, bool isDark) {
    final days    = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
    final today   = DateTime.now().weekday - 1;

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
            decoration: BoxDecoration(color: AppColors.amber.withOpacity(0.12), borderRadius: BorderRadius.circular(10)),
            child: const Center(child: Text('🔥', style: TextStyle(fontSize: 18))),
          ),
          const SizedBox(width: 10),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('${p.currentStreak}-Day Streak', style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w700,
              color: isDark ? AppColors.textPriDark : AppColors.textPri)),
            Text(p.currentStreak > 0 ? 'You\'re on fire! Keep going 💪' : 'Log a meal to start your streak',
              style: GoogleFonts.inter(fontSize: 11, color: AppColors.textSec)),
          ])),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(color: AppColors.amberBg, borderRadius: BorderRadius.circular(20)),
            child: Text('${p.currentStreak} 🔥', style: GoogleFonts.inter(fontSize: 13, color: AppColors.amber, fontWeight: FontWeight.w700)),
          ),
        ]),
        const SizedBox(height: 16),
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: List.generate(7, (i) {
          final done    = i < today;
          final isToday = i == today;
          return Column(children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              width: 38, height: 38,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: done
                  ? const LinearGradient(colors: [AppColors.brandBlue, AppColors.brandGreen], begin: Alignment.topLeft, end: Alignment.bottomRight)
                  : null,
                color: done ? null : isToday
                  ? AppColors.amber.withOpacity(0.15)
                  : isDark ? AppColors.surfVarDark : AppColors.surfaceVar,
                border: isToday ? Border.all(color: AppColors.amber, width: 2) : null,
              ),
              child: Center(child: done
                ? const Icon(Icons.check, color: Colors.white, size: 16)
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

  // ── Weekly Chart ──────────────────────────────────────────────────────────
  Widget _weeklyChart(BuildContext context, NutritionProvider p, bool isDark) {
    final data   = p.weeklyCalories;
    final maxVal = data.reduce((a, b) => a > b ? a : b).clamp(100.0, double.infinity);
    final days   = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfDark : AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isDark ? AppColors.borderDark : AppColors.border),
      ),
      child: Column(children: [
        Row(children: [
          Container(width: 36, height: 36, decoration: BoxDecoration(color: AppColors.brandGreen.withOpacity(0.12), borderRadius: BorderRadius.circular(10)), child: const Center(child: Text('📊', style: TextStyle(fontSize: 18)))),
          const SizedBox(width: 10),
          Expanded(child: Text('Weekly Calories', style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w700, color: isDark ? AppColors.textPriDark : AppColors.textPri))),
          GestureDetector(
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ProgressScreen())),
            child: Text('View all →', style: GoogleFonts.inter(fontSize: 12, color: AppColors.brandBlue, fontWeight: FontWeight.w600)),
          ),
        ]),
        const SizedBox(height: 16),
        SizedBox(height: 90, child: Row(crossAxisAlignment: CrossAxisAlignment.end, children: List.generate(7, (i) {
          final h       = data[i] > 0 ? (data[i] / maxVal) * 72 : 4.0;
          final isToday = i == 6;
          final over    = data[i] > p.calorieGoal;
          final color   = over ? AppColors.accent : isToday ? AppColors.brandBlue : AppColors.brandBlue.withOpacity(0.3);
          return Expanded(child: Column(mainAxisAlignment: MainAxisAlignment.end, children: [
            if (data[i] > 0 && isToday)
              Text('${data[i].toInt()}', style: TextStyle(fontSize: 8, fontWeight: FontWeight.w700, color: color)),
            const SizedBox(height: 2),
            Container(height: h, margin: const EdgeInsets.symmetric(horizontal: 4),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(6),
                gradient: isToday
                  ? const LinearGradient(colors: [AppColors.brandBlue, AppColors.brandGreen], begin: Alignment.bottomCenter, end: Alignment.topCenter)
                  : null,
                color: isToday ? null : color,
              )),
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
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfDark : AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isDark ? AppColors.borderDark : AppColors.border),
      ),
      child: Column(children: [
        Row(children: [
          Container(width: 36, height: 36, decoration: BoxDecoration(color: AppColors.brandGreen.withOpacity(0.12), borderRadius: BorderRadius.circular(10)), child: const Center(child: Text('🍽', style: TextStyle(fontSize: 18)))),
          const SizedBox(width: 10),
          Expanded(child: Text("Today's Meals", style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w700, color: isDark ? AppColors.textPriDark : AppColors.textPri))),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(color: AppColors.brandGreen.withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
            child: Text('${meals.length} logged', style: GoogleFonts.inter(fontSize: 11, color: AppColors.brandGreen, fontWeight: FontWeight.w600)),
          ),
        ]),
        const SizedBox(height: 14),
        if (meals.isEmpty)
          _emptyMeals(isDark)
        else
          ...meals.take(4).map((m) => _mealTile(context, m, p, isDark)),
      ]),
    );
  }

  Widget _emptyMeals(bool isDark) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 24),
    child: Column(children: [
      Container(
        width: 64, height: 64,
        decoration: BoxDecoration(color: AppColors.brandGreen.withOpacity(0.08), shape: BoxShape.circle),
        child: const Center(child: Text('🌱', style: TextStyle(fontSize: 30))),
      ),
      const SizedBox(height: 12),
      Text('No meals logged yet', style: GoogleFonts.inter(color: AppColors.textSec, fontSize: 14, fontWeight: FontWeight.w500)),
      const SizedBox(height: 4),
      Text('Tap "Log" in the menu below to start', style: GoogleFonts.inter(color: AppColors.textSec.withOpacity(0.6), fontSize: 12)),
    ]),
  );

  Widget _mealTile(BuildContext context, MealLog m, NutritionProvider p, bool isDark) {
    final bgMap = {'Breakfast': AppColors.greenBg, 'Lunch': AppColors.amberBg, 'Dinner': AppColors.accentBg, 'Snack': AppColors.blueBg};
    final colMap = {'Breakfast': AppColors.brandGreen, 'Lunch': AppColors.amber, 'Dinner': AppColors.accent, 'Snack': AppColors.brandBlue};
    final bg  = bgMap[m.mealType] ?? AppColors.surfaceVar;
    final col = colMap[m.mealType] ?? AppColors.brandBlue;

    return Dismissible(
      key: Key(m.key.toString()),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 16),
        decoration: BoxDecoration(color: AppColors.accent.withOpacity(0.1), borderRadius: BorderRadius.circular(14)),
        child: const Icon(Icons.delete_outline, color: AppColors.accent),
      ),
      onDismissed: (_) => p.deleteMeal(m),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isDark ? AppColors.surfVarDark : AppColors.bg,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: isDark ? AppColors.borderDark : AppColors.border),
        ),
        child: Row(children: [
          Container(
            width: 44, height: 44,
            decoration: BoxDecoration(color: isDark ? AppColors.surfDark : bg, borderRadius: BorderRadius.circular(12)),
            child: Center(child: Text(m.emoji, style: const TextStyle(fontSize: 22))),
          ),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(m.foodName, style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w700, color: isDark ? AppColors.textPriDark : AppColors.textPri)),
            const SizedBox(height: 2),
            Row(children: [
              Container(padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2), decoration: BoxDecoration(color: col.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                child: Text(m.mealType, style: GoogleFonts.inter(fontSize: 10, color: col, fontWeight: FontWeight.w600))),
              const SizedBox(width: 6),
              Text(DateFormat('h:mm a').format(m.loggedAt), style: GoogleFonts.inter(fontSize: 10, color: AppColors.textSec)),
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
    return GestureDetector(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ExerciseScreen())),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [AppColors.brandDark, AppColors.brandBlue, AppColors.brandGreen],
            begin: Alignment.topLeft, end: Alignment.bottomRight,
            stops: [0.0, 0.5, 1.0],
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [BoxShadow(color: AppColors.brandBlue.withOpacity(0.3), blurRadius: 16, offset: const Offset(0, 6))],
        ),
        child: Row(children: [
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(color: Colors.white.withOpacity(0.15), borderRadius: BorderRadius.circular(20)),
              child: Text("Today's Workout", style: GoogleFonts.inter(fontSize: 11, color: Colors.white70, fontWeight: FontWeight.w600)),
            ),
            const SizedBox(height: 10),
            Text('Upper Body Strength', style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w800, color: Colors.white)),
            const SizedBox(height: 4),
            Row(children: [
              _wTag(Icons.timer_outlined, '45 min'),
              const SizedBox(width: 8),
              _wTag(Icons.local_fire_department_outlined, '320 kcal'),
            ]),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Text('Start Workout', style: GoogleFonts.inter(color: AppColors.brandBlue, fontSize: 13, fontWeight: FontWeight.w700)),
                const SizedBox(width: 6),
                const Icon(Icons.arrow_forward, color: AppColors.brandBlue, size: 14),
              ]),
            ),
          ])),
          const Text('🏋️', style: TextStyle(fontSize: 56)),
        ]),
      ),
    );
  }

  Widget _wTag(IconData icon, String label) => Row(mainAxisSize: MainAxisSize.min, children: [
    Icon(icon, color: Colors.white70, size: 13),
    const SizedBox(width: 3),
    Text(label, style: GoogleFonts.inter(fontSize: 12, color: Colors.white70, fontWeight: FontWeight.w500)),
  ]);
}
