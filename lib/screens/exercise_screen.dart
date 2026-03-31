import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../data/app_data.dart';
import '../models/food_item.dart';
import '../theme/app_theme.dart';
import 'features/exercise_timer_screen.dart';

class ExerciseScreen extends StatefulWidget {
  const ExerciseScreen({super.key});
  @override
  State<ExerciseScreen> createState() => _ExerciseScreenState();
}

class _ExerciseScreenState extends State<ExerciseScreen> {
  String _cat = 'All';
  List<Exercise> get _list => _cat == 'All' ? AppData.exercises : AppData.exercises.where((e) => e.category == _cat).toList();

  Color _color(String cat) { switch (cat) { case 'Strength': return AppColors.primary; case 'Cardio': return AppColors.amber; case 'HIIT': return AppColors.accent; case 'Yoga': return AppColors.purple; default: return AppColors.blue; } }
  Color _bg(String cat) { switch (cat) { case 'Strength': return AppColors.primaryLight; case 'Cardio': return AppColors.amberLight; case 'HIIT': return AppColors.accentLight; case 'Yoga': return AppColors.purpleLight; default: return AppColors.blueLight; } }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: isDark ? AppColors.bgDark : AppColors.bg,
      appBar: AppBar(title: Text('Exercise Library', style: GoogleFonts.inter(fontWeight: FontWeight.w700)), automaticallyImplyLeading: false, backgroundColor: isDark ? AppColors.surfaceDark : AppColors.surface),
      body: Column(children: [
        Container(color: isDark ? AppColors.surfaceDark : AppColors.surface, height: 50,
          child: ListView(scrollDirection: Axis.horizontal, padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            children: AppData.exerciseCategories.map((c) {
              final active = _cat == c;
              return GestureDetector(onTap: () => setState(() => _cat = c), child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.only(right: 8),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                decoration: BoxDecoration(color: active ? _color(c) : Colors.transparent, borderRadius: BorderRadius.circular(20), border: Border.all(color: active ? _color(c) : isDark ? AppColors.borderDark : AppColors.border)),
                child: Text(c, style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: active ? Colors.white : AppColors.textSecondary)),
              ));
            }).toList())),
        Divider(height: 1, color: isDark ? AppColors.borderDark : AppColors.border),
        Expanded(child: ListView.builder(padding: const EdgeInsets.all(12), itemCount: _list.length, itemBuilder: (_, i) {
          final ex = _list[i];
          return GestureDetector(
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ExerciseTimerScreen(exercise: ex))),
            child: Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(color: isDark ? AppColors.surfaceDark : AppColors.surface, borderRadius: BorderRadius.circular(16), border: Border.all(color: isDark ? AppColors.borderDark : AppColors.border)),
              child: Row(children: [
                Container(width: 52, height: 52, decoration: BoxDecoration(color: isDark ? AppColors.surfaceVariantDark : _bg(ex.category), borderRadius: BorderRadius.circular(14)), child: Center(child: Text(ex.emoji, style: const TextStyle(fontSize: 26)))),
                const SizedBox(width: 12),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(ex.name, style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w700, color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary)),
                  const SizedBox(height: 3),
                  Text('${ex.duration} · ${ex.category} · ${ex.difficulty}', style: GoogleFonts.inter(fontSize: 11, color: AppColors.textSecondary)),
                  const SizedBox(height: 6),
                  Wrap(spacing: 4, children: ex.muscleGroups.map((m) => Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3), decoration: BoxDecoration(color: isDark ? AppColors.surfaceVariantDark : _bg(ex.category), borderRadius: BorderRadius.circular(10)), child: Text(m, style: TextStyle(fontSize: 10, color: _color(ex.category), fontWeight: FontWeight.w600)))).toList()),
                ])),
                Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                  Text('${ex.caloriesBurned}', style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.accent)),
                  Text('kcal', style: GoogleFonts.inter(fontSize: 10, color: AppColors.textSecondary)),
                  const SizedBox(height: 4),
                  Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(10)), child: Text('Start', style: GoogleFonts.inter(fontSize: 10, color: Colors.white, fontWeight: FontWeight.w600))),
                ]),
              ]),
            ),
          );
        })),
      ]),
    );
  }
}
