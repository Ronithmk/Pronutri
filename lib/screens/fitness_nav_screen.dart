import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import 'activity_screen.dart';
import 'exercise_screen.dart';

class FitnessNavScreen extends StatelessWidget {
  const FitnessNavScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: isDark ? AppColors.bgDark : AppColors.bg,
        appBar: AppBar(
          automaticallyImplyLeading: false,
          backgroundColor: isDark ? AppColors.surfDark : AppColors.surface,
          elevation: 0,
          surfaceTintColor: Colors.transparent,
          title: Text(
            'Fitness',
            style: GoogleFonts.inter(fontWeight: FontWeight.w800, fontSize: 18,
                color: isDark ? AppColors.textPriDark : AppColors.textPri),
          ),
          bottom: TabBar(
            labelStyle: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w700),
            unselectedLabelStyle: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w500),
            labelColor: AppColors.brandBlue,
            unselectedLabelColor: isDark ? AppColors.textSecDark : AppColors.textSec,
            indicatorColor: AppColors.brandBlue,
            indicatorWeight: 2.5,
            indicatorSize: TabBarIndicatorSize.label,
            tabs: const [
              Tab(icon: Icon(Icons.directions_walk_rounded, size: 18), text: 'Steps'),
              Tab(icon: Icon(Icons.fitness_center_rounded, size: 18), text: 'Workouts'),
            ],
          ),
        ),
        body: const TabBarView(
          physics: NeverScrollableScrollPhysics(),
          children: [
            _ActivityBody(),
            _ExerciseBody(),
          ],
        ),
      ),
    );
  }
}

// Wrap ActivityScreen/ExerciseScreen content without their own AppBar
class _ActivityBody extends StatelessWidget {
  const _ActivityBody();
  @override
  Widget build(BuildContext context) => const ActivityScreen();
}

class _ExerciseBody extends StatelessWidget {
  const _ExerciseBody();
  @override
  Widget build(BuildContext context) => const ExerciseScreen();
}
