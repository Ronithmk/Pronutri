import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../services/nutrition_provider.dart';
import '../services/auth_provider.dart';
import '../services/habit_provider.dart';
import '../theme/app_theme.dart';

class ProgressScreen extends StatelessWidget {
  const ProgressScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final p      = Provider.of<NutritionProvider>(context);
    final auth   = Provider.of<AuthProvider>(context);
    final habits = Provider.of<HabitProvider>(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final days   = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final data   = p.weeklyCalories;
    final maxVal = data.reduce((a, b) => a > b ? a : b).clamp(100.0, double.infinity);

    return Scaffold(
      backgroundColor: isDark ? AppColors.bgDark : AppColors.bg,
      appBar: AppBar(
        title: Text('My Progress', style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
        leading: IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.arrow_back_ios, size: 18)),
        backgroundColor: isDark ? AppColors.surfaceDark : AppColors.surface,
      ),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        // Summary grid
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
          childAspectRatio: 1.6,
          children: [
            _sCard('Today',   '${p.todayCalories.toInt()} kcal', '🔥', AppColors.accentLight,  AppColors.accent),
            _sCard('Streak',  '${p.currentStreak} days',         '🔥', AppColors.amberLight,   AppColors.amber),
            _sCard('Protein', '${p.todayProtein.toInt()}g',      '💪', AppColors.primaryLight, AppColors.primary),
            _sCard('Water',   '${(p.todayWaterMl/1000).toStringAsFixed(1)}L', '💧', AppColors.blueLight, AppColors.blue),
          ],
        ),
        const SizedBox(height: 16),

        // ── Goal Prediction ──────────────────────────────────────────────────
        _GoalPredictionCard(p: p, auth: auth, isDark: isDark),
        const SizedBox(height: 16),

        _macroPieCard(p, isDark),
        const SizedBox(height: 16),

        // Weekly chart
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark ? AppColors.surfaceDark : AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: isDark ? AppColors.borderDark : AppColors.border),
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Weekly Calories', style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w700, color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary)),
            const SizedBox(height: 4),
            Text('Goal: ${p.calorieGoal.toInt()} kcal/day', style: GoogleFonts.inter(fontSize: 12, color: AppColors.textSecondary)),
            const SizedBox(height: 20),
            SizedBox(height: 160, child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: List.generate(7, (i) {
                final h      = data[i] > 0 ? (data[i] / maxVal) * 130 : 4.0;
                final isToday = i == 6;
                final over   = data[i] > p.calorieGoal;
                return Expanded(child: Column(mainAxisAlignment: MainAxisAlignment.end, children: [
                  if (data[i] > 0)
                    Text('${data[i].toInt()}', style: TextStyle(fontSize: 8, fontWeight: FontWeight.w600,
                      color: over ? AppColors.accent : AppColors.primary)),
                  const SizedBox(height: 3),
                  Container(height: h, margin: const EdgeInsets.symmetric(horizontal: 4),
                    decoration: BoxDecoration(
                      color: over ? AppColors.accent : isToday ? AppColors.primary : AppColors.primary.withOpacity(0.35),
                      borderRadius: BorderRadius.circular(6),
                    )),
                  const SizedBox(height: 6),
                  Text(days[i], style: TextStyle(fontSize: 10,
                    color: isToday ? AppColors.primary : AppColors.textSecondary,
                    fontWeight: isToday ? FontWeight.w700 : FontWeight.w400)),
                ]));
              }),
            )),
          ]),
        ),
        const SizedBox(height: 16),

        // Macros
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark ? AppColors.surfaceDark : AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: isDark ? AppColors.borderDark : AppColors.border),
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text("Today's Macros", style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w700, color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary)),
            const SizedBox(height: 16),
            _macroBar('Protein',       p.todayProtein,   p.proteinGoal, 'g',    AppColors.primary),
            const SizedBox(height: 10),
            _macroBar('Carbohydrates', p.todayCarbs,     p.carbsGoal,   'g',    AppColors.amber),
            const SizedBox(height: 10),
            _macroBar('Fat',           p.todayFat,       p.fatGoal,     'g',    AppColors.accent),
            const SizedBox(height: 10),
            _macroBar('Calories',      p.todayCalories,  p.calorieGoal, ' kcal',AppColors.blue),
            const SizedBox(height: 10),
            _macroBar('Water',         p.todayWaterMl,   p.waterGoal,   ' ml',  AppColors.purple),
          ]),
        ),
        const SizedBox(height: 16),

        // ── Mood History ─────────────────────────────────────────────────────
        _MoodHistoryCard(habits: habits, isDark: isDark),
        const SizedBox(height: 40),
      ]),
    );
  }

  Widget _macroPieCard(NutritionProvider p, bool isDark) {
    final proteinKcal = p.todayProtein * 4;
    final carbsKcal   = p.todayCarbs   * 4;
    final fatKcal     = p.todayFat     * 9;
    final total       = proteinKcal + carbsKcal + fatKcal;

    if (total == 0) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isDark ? AppColors.surfaceDark : AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: isDark ? AppColors.borderDark : AppColors.border),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text("Macro Split", style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w700, color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary)),
          const SizedBox(height: 32),
          Center(child: Text('Log meals to see your macro split', style: GoogleFonts.inter(fontSize: 13, color: AppColors.textSecondary))),
          const SizedBox(height: 32),
        ]),
      );
    }

    final pPct = (proteinKcal / total * 100).round();
    final cPct = (carbsKcal   / total * 100).round();
    final fPct = (fatKcal     / total * 100).round();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? AppColors.borderDark : AppColors.border),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text("Macro Split", style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w700, color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary)),
        const SizedBox(height: 4),
        Text('Based on calories from protein, carbs & fat', style: GoogleFonts.inter(fontSize: 12, color: AppColors.textSecondary)),
        const SizedBox(height: 20),
        Row(children: [
          SizedBox(
            width: 140, height: 140,
            child: PieChart(PieChartData(
              sectionsSpace: 3,
              centerSpaceRadius: 44,
              sections: [
                PieChartSectionData(value: proteinKcal, color: AppColors.primary, radius: 22, title: '', showTitle: false),
                PieChartSectionData(value: carbsKcal,   color: AppColors.amber,   radius: 22, title: '', showTitle: false),
                PieChartSectionData(value: fatKcal,     color: AppColors.accent,  radius: 22, title: '', showTitle: false),
              ],
              borderData: FlBorderData(show: false),
            )),
          ),
          const SizedBox(width: 24),
          Expanded(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            _pieLegend('Protein', '${p.todayProtein.toInt()}g', '$pPct%', AppColors.primary,  isDark),
            const SizedBox(height: 12),
            _pieLegend('Carbs',   '${p.todayCarbs.toInt()}g',   '$cPct%', AppColors.amber,    isDark),
            const SizedBox(height: 12),
            _pieLegend('Fat',     '${p.todayFat.toInt()}g',     '$fPct%', AppColors.accent,   isDark),
          ])),
        ]),
      ]),
    );
  }

  Widget _pieLegend(String label, String grams, String pct, Color color, bool isDark) {
    return Row(children: [
      Container(width: 12, height: 12, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
      const SizedBox(width: 8),
      Expanded(child: Text(label, style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w500, color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary))),
      Text(grams, style: GoogleFonts.inter(fontSize: 12, color: AppColors.textSecondary)),
      const SizedBox(width: 8),
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(8)),
        child: Text(pct, style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w700, color: color)),
      ),
    ]);
  }

  Widget _sCard(String label, String val, String emoji, Color bg, Color color) =>
    Container(padding: const EdgeInsets.all(14), decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(14)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(emoji, style: const TextStyle(fontSize: 22)), const Spacer(),
        Text(val,   style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: color, fontFamily: 'Inter')),
        Text(label, style: TextStyle(fontSize: 11, color: color.withOpacity(0.7), fontWeight: FontWeight.w500)),
      ]));

  Widget _macroBar(String label, double val, double goal, String unit, Color color) {
    final over = val > goal;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Expanded(child: Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500))),
        Text('${val.toInt()} / ${goal.toInt()}$unit',
          style: TextStyle(fontSize: 12, color: over ? AppColors.accent : color, fontWeight: FontWeight.w600)),
      ]),
      const SizedBox(height: 5),
      ClipRRect(
        borderRadius: BorderRadius.circular(4),
        child: LinearProgressIndicator(
          value: (val / goal).clamp(0, 1), minHeight: 8,
          backgroundColor: color.withOpacity(0.12),
          valueColor: AlwaysStoppedAnimation(over ? AppColors.accent : color),
        ),
      ),
    ]);
  }
}

// ── Goal Prediction Card ──────────────────────────────────────────────────────
class _GoalPredictionCard extends StatelessWidget {
  final NutritionProvider p;
  final AuthProvider auth;
  final bool isDark;
  const _GoalPredictionCard({required this.p, required this.auth, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final user = auth.currentUser;
    if (user == null) return const SizedBox.shrink();

    final currentWeight = user.weight;
    final targetWeight  = user.targetWeight;
    final weightDiff    = (currentWeight - targetWeight).abs();
    final isLosing      = currentWeight > targetWeight;
    final isGaining     = currentWeight < targetWeight;

    // 7-day average
    final weekly = p.weeklyCalories;
    final daysWithData = weekly.where((c) => c > 0).toList();
    final avgIntake = daysWithData.isEmpty
        ? p.calorieGoal
        : daysWithData.reduce((a, b) => a + b) / daysWithData.length;

    final avgDeficit  = p.calorieGoal - avgIntake;
    final weeklyDeficit = avgDeficit * 7;

    // 1 kg of fat ≈ 7700 kcal
    final weeklyWeightChange = weeklyDeficit / 7700;

    // Plateau detection: variance of last 5 days with data
    final last5 = daysWithData.take(5).toList();
    bool plateau = false;
    if (last5.length >= 4) {
      final avg5 = last5.reduce((a, b) => a + b) / last5.length;
      final variance = last5.map((c) => (c - avg5).abs()).reduce((a, b) => a + b) / last5.length;
      plateau = variance < 100 && avgDeficit.abs() < 100;
    }

    // Days to goal
    String predictionText;
    Color predColor;
    if ((isLosing && weeklyWeightChange > 0) || (isGaining && weeklyWeightChange < 0)) {
      final weeksToGoal = weightDiff / weeklyWeightChange.abs();
      final daysToGoal  = (weeksToGoal * 7).round();
      if (daysToGoal <= 0) {
        predictionText = 'You\'ve reached your goal! 🎉';
        predColor = AppColors.brandGreen;
      } else if (daysToGoal > 365) {
        predictionText = 'Increase your deficit to reach your goal faster';
        predColor = AppColors.amber;
      } else {
        predictionText = 'At this rate, you\'ll reach your goal in ~$daysToGoal days';
        predColor = AppColors.brandBlue;
      }
    } else if (weightDiff < 0.5) {
      predictionText = 'You\'re at your goal weight! Keep it up 🎉';
      predColor = AppColors.brandGreen;
    } else {
      predictionText = isLosing
          ? 'Eating above goal — increase deficit to lose weight'
          : 'Eating below goal — increase intake to gain weight';
      predColor = AppColors.accent;
    }

    // Weekly performance %
    final weeklyGoal = p.calorieGoal * daysWithData.length;
    final weeklyActual = daysWithData.isEmpty ? 0.0 : daysWithData.reduce((a, b) => a + b);
    final performancePct = weeklyGoal > 0
        ? ((weeklyActual / weeklyGoal) * 100).round()
        : 100;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? [const Color(0xFF0D1F3C), const Color(0xFF0A2A1A)]
              : [const Color(0xFFE8F2FF), const Color(0xFFDFF5EA)],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: predColor.withOpacity(0.3)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(
            width: 40, height: 40,
            decoration: BoxDecoration(color: predColor.withOpacity(0.12), borderRadius: BorderRadius.circular(14)),
            child: const Center(child: Text('🎯', style: TextStyle(fontSize: 20))),
          ),
          const SizedBox(width: 12),
          Text('Goal Prediction', style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w700,
            color: isDark ? AppColors.textPriDark : AppColors.textPri)),
        ]),
        const SizedBox(height: 14),

        // Prediction text
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: predColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: predColor.withOpacity(0.25)),
          ),
          child: Text(predictionText,
            style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: predColor, height: 1.4)),
        ),
        const SizedBox(height: 14),

        // Stats row
        Row(children: [
          _statChip('Current', '${currentWeight.toStringAsFixed(1)} ${user.weightUnit}', AppColors.brandBlue),
          const SizedBox(width: 8),
          _statChip('Target', '${targetWeight.toStringAsFixed(1)} ${user.weightUnit}', AppColors.brandGreen),
          const SizedBox(width: 8),
          _statChip('This week', '$performancePct% on track',
            performancePct >= 90 ? AppColors.brandGreen : performancePct >= 70 ? AppColors.amber : AppColors.accent),
        ]),

        // Plateau warning
        if (plateau) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.amber.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.amber.withOpacity(0.3)),
            ),
            child: Row(children: [
              const Text('⚠️', style: TextStyle(fontSize: 16)),
              const SizedBox(width: 8),
              Expanded(child: Text('Plateau detected — try varying meal types or increasing workout intensity',
                style: GoogleFonts.inter(fontSize: 12, color: AppColors.amber, height: 1.4))),
            ]),
          ),
        ],
      ]),
    );
  }

  Widget _statChip(String label, String val, Color color) => Expanded(child: Container(
    padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
    decoration: BoxDecoration(
      color: color.withOpacity(0.1),
      borderRadius: BorderRadius.circular(12),
    ),
    child: Column(children: [
      Text(val,   style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w700, color: color)),
      const SizedBox(height: 2),
      Text(label, style: GoogleFonts.inter(fontSize: 9,  color: AppColors.textSec)),
    ]),
  ));
}

// ── Mood History Card ─────────────────────────────────────────────────────────
class _MoodHistoryCard extends StatelessWidget {
  final HabitProvider habits;
  final bool isDark;
  const _MoodHistoryCard({required this.habits, required this.isDark});

  static const _moodEmojis = ['', '😔', '😕', '😐', '🙂', '😄'];

  @override
  Widget build(BuildContext context) {
    final moods = habits.last7DaysMood;
    final hasMoods = moods.any((m) => m != null);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? AppColors.borderDark : AppColors.border),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Mood History', style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w700,
          color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary)),
        const SizedBox(height: 4),
        Text('Last 7 days', style: GoogleFonts.inter(fontSize: 12, color: AppColors.textSecondary)),
        const SizedBox(height: 16),
        if (!hasMoods)
          Center(child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Text('No mood data yet — check in daily from the Habits screen',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(fontSize: 13, color: AppColors.textSecondary)),
          ))
        else
          Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: List.generate(7, (i) {
            final mood = moods[i];
            final day  = DateTime.now().subtract(Duration(days: 6 - i));
            final dayLabel = ['M','T','W','T','F','S','S'][day.weekday - 1];
            return Column(children: [
              mood != null
                ? Text(_moodEmojis[mood], style: const TextStyle(fontSize: 24))
                : Container(width: 28, height: 28, decoration: BoxDecoration(
                    color: isDark ? AppColors.surfaceVariantDark : AppColors.surfaceVariant,
                    shape: BoxShape.circle,
                  )),
              const SizedBox(height: 4),
              Text(dayLabel, style: GoogleFonts.inter(fontSize: 10, color: AppColors.textSecondary)),
            ]);
          })),
      ]),
    );
  }
}
