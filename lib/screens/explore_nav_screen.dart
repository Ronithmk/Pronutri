import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import 'recipes_screen.dart';
import 'ai_coach_screen.dart';

class ExploreNavScreen extends StatelessWidget {
  const ExploreNavScreen({super.key});

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
            'Explore',
            style: GoogleFonts.inter(fontWeight: FontWeight.w800, fontSize: 18,
                color: isDark ? AppColors.textPriDark : AppColors.textPri),
          ),
          bottom: TabBar(
            labelStyle: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w700),
            unselectedLabelStyle: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w500),
            labelColor: AppColors.brandGreen,
            unselectedLabelColor: isDark ? AppColors.textSecDark : AppColors.textSec,
            indicatorColor: AppColors.brandGreen,
            indicatorWeight: 2.5,
            indicatorSize: TabBarIndicatorSize.label,
            tabs: const [
              Tab(icon: Icon(Icons.restaurant_menu_rounded, size: 18), text: 'Recipes'),
              Tab(icon: Icon(Icons.sports_gymnastics_rounded, size: 18), text: 'AI Coach'),
            ],
          ),
        ),
        body: const TabBarView(
          physics: NeverScrollableScrollPhysics(),
          children: [
            RecipesScreen(),
            AiCoachScreen(),
          ],
        ),
      ),
    );
  }
}
