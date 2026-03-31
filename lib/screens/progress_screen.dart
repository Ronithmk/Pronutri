import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../services/nutrition_provider.dart';
import '../theme/app_theme.dart';

class ProgressScreen extends StatelessWidget {
  const ProgressScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final p = Provider.of<NutritionProvider>(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final data = p.weeklyCalories;
    final maxVal = data.reduce((a, b) => a > b ? a : b).clamp(100.0, double.infinity);

    return Scaffold(
      backgroundColor: isDark ? AppColors.bgDark : AppColors.bg,
      appBar: AppBar(title: Text('My Progress', style: GoogleFonts.inter(fontWeight: FontWeight.w700)), leading: IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.arrow_back_ios, size: 18)), backgroundColor: isDark ? AppColors.surfaceDark : AppColors.surface),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        // Summary grid
        GridView.count(shrinkWrap: true, physics: const NeverScrollableScrollPhysics(), crossAxisCount: 2, crossAxisSpacing: 10, mainAxisSpacing: 10, childAspectRatio: 1.6,
          children: [
            _sCard('Today', '${p.todayCalories.toInt()} kcal', '🔥', AppColors.accentLight, AppColors.accent),
            _sCard('Streak', '${p.currentStreak} days', '🔥', AppColors.amberLight, AppColors.amber),
            _sCard('Protein', '${p.todayProtein.toInt()}g', '💪', AppColors.primaryLight, AppColors.primary),
            _sCard('Water', '${(p.todayWaterMl/1000).toStringAsFixed(1)}L', '💧', AppColors.blueLight, AppColors.blue),
          ]),
        const SizedBox(height: 16),
        // Weekly chart
        Container(padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: isDark ? AppColors.surfaceDark : AppColors.surface, borderRadius: BorderRadius.circular(16), border: Border.all(color: isDark ? AppColors.borderDark : AppColors.border)),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Weekly Calories', style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w700, color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary)),
            const SizedBox(height: 4),
            Text('Goal: ${p.calorieGoal.toInt()} kcal/day', style: GoogleFonts.inter(fontSize: 12, color: AppColors.textSecondary)),
            const SizedBox(height: 20),
            SizedBox(height: 160, child: Row(crossAxisAlignment: CrossAxisAlignment.end, children: List.generate(7, (i) {
              final h = data[i] > 0 ? (data[i] / maxVal) * 130 : 4.0;
              final isToday = i == 6;
              final over = data[i] > p.calorieGoal;
              return Expanded(child: Column(mainAxisAlignment: MainAxisAlignment.end, children: [
                if (data[i] > 0) Text('${data[i].toInt()}', style: TextStyle(fontSize: 8, fontWeight: FontWeight.w600, color: over ? AppColors.accent : AppColors.primary)),
                const SizedBox(height: 3),
                Container(height: h, margin: const EdgeInsets.symmetric(horizontal: 4), decoration: BoxDecoration(color: over ? AppColors.accent : isToday ? AppColors.primary : AppColors.primary.withOpacity(0.35), borderRadius: BorderRadius.circular(6))),
                const SizedBox(height: 6),
                Text(days[i], style: TextStyle(fontSize: 10, color: isToday ? AppColors.primary : AppColors.textSecondary, fontWeight: isToday ? FontWeight.w700 : FontWeight.w400)),
              ]));
            }))),
          ])),
        const SizedBox(height: 16),
        // Macros
        Container(padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: isDark ? AppColors.surfaceDark : AppColors.surface, borderRadius: BorderRadius.circular(16), border: Border.all(color: isDark ? AppColors.borderDark : AppColors.border)),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text("Today's Macros", style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w700, color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary)),
            const SizedBox(height: 16),
            _macroBar('Protein', p.todayProtein, p.proteinGoal, 'g', AppColors.primary),
            const SizedBox(height: 10),
            _macroBar('Carbohydrates', p.todayCarbs, p.carbsGoal, 'g', AppColors.amber),
            const SizedBox(height: 10),
            _macroBar('Fat', p.todayFat, p.fatGoal, 'g', AppColors.accent),
            const SizedBox(height: 10),
            _macroBar('Calories', p.todayCalories, p.calorieGoal, ' kcal', AppColors.blue),
            const SizedBox(height: 10),
            _macroBar('Water', p.todayWaterMl, p.waterGoal, ' ml', AppColors.purple),
          ])),
        const SizedBox(height: 40),
      ]),
    );
  }

  Widget _sCard(String label, String val, String emoji, Color bg, Color color) => Container(padding: const EdgeInsets.all(14), decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(14)), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Text(emoji, style: const TextStyle(fontSize: 22)), const Spacer(),
    Text(val, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: color, fontFamily: 'Inter')),
    Text(label, style: TextStyle(fontSize: 11, color: color.withOpacity(0.7), fontWeight: FontWeight.w500)),
  ]));

  Widget _macroBar(String label, double val, double goal, String unit, Color color) {
    final over = val > goal;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Expanded(child: Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500))),
        Text('${val.toInt()} / ${goal.toInt()}$unit', style: TextStyle(fontSize: 12, color: over ? AppColors.accent : color, fontWeight: FontWeight.w600)),
      ]),
      const SizedBox(height: 5),
      ClipRRect(borderRadius: BorderRadius.circular(4), child: LinearProgressIndicator(value: (val/goal).clamp(0, 1), minHeight: 8, backgroundColor: color.withOpacity(0.12), valueColor: AlwaysStoppedAnimation(over ? AppColors.accent : color))),
    ]);
  }
}
