import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../data/app_data.dart';
import '../models/food_item.dart';
import '../theme/app_theme.dart';

class RecipesScreen extends StatefulWidget {
  const RecipesScreen({super.key});
  @override
  State<RecipesScreen> createState() => _RecipesScreenState();
}

class _RecipesScreenState extends State<RecipesScreen> {
  final Set<String> _sel = {};
  List<Recipe>? _matched;

  void _search() {
    if (_sel.isEmpty) { ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: const Text('Select at least one ingredient'), backgroundColor: AppColors.accent, behavior: SnackBarBehavior.floating, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)))); return; }
    final matched = AppData.recipes.where((r) => r.ingredients.any((ing) => _sel.any((s) => ing.toLowerCase().contains(s.toLowerCase()) || s.toLowerCase().contains(ing.toLowerCase().split(' ')[0])))).toList();
    setState(() => _matched = matched);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: isDark ? AppColors.bgDark : AppColors.bg,
      appBar: AppBar(title: Text('Meal Recommendations', style: GoogleFonts.inter(fontWeight: FontWeight.w700)), automaticallyImplyLeading: false, backgroundColor: isDark ? AppColors.surfaceDark : AppColors.surface),
      body: SingleChildScrollView(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text("What's in your kitchen?", style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700, color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary)),
        const SizedBox(height: 4),
        Text('Tap ingredients you have at home', style: GoogleFonts.inter(fontSize: 13, color: AppColors.textSecondary)),
        const SizedBox(height: 14),
        Wrap(spacing: 8, runSpacing: 8, children: AppData.ingredients.map((ing) {
          final sel = _sel.contains(ing);
          return GestureDetector(
            onTap: () => setState(() => sel ? _sel.remove(ing) : _sel.add(ing)),
            child: AnimatedContainer(duration: const Duration(milliseconds: 200), padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
              decoration: BoxDecoration(color: sel ? AppColors.primary : isDark ? AppColors.surfaceDark : AppColors.surface, borderRadius: BorderRadius.circular(24), border: Border.all(color: sel ? AppColors.primary : isDark ? AppColors.borderDark : AppColors.border, width: sel ? 1.5 : 1)),
              child: Text(ing, style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w500, color: sel ? Colors.white : isDark ? AppColors.textPrimaryDark : AppColors.textPrimary))),
          );
        }).toList()),
        if (_sel.isNotEmpty) ...[const SizedBox(height: 12), Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8), decoration: BoxDecoration(color: AppColors.primaryLight, borderRadius: BorderRadius.circular(10)), child: Text('${_sel.length} ingredient${_sel.length > 1 ? 's' : ''} selected', style: GoogleFonts.inter(fontSize: 12, color: AppColors.primaryDark, fontWeight: FontWeight.w600)))],
        const SizedBox(height: 16),
        SizedBox(width: double.infinity, child: ElevatedButton.icon(onPressed: _search, icon: const Text('✨', style: TextStyle(fontSize: 16)), label: const Text('Get AI Recipes'))),
        if (_matched != null) ...[
          const SizedBox(height: 20),
          if (_matched!.isEmpty) Center(child: Column(children: [const SizedBox(height: 20), const Text('🫙', style: TextStyle(fontSize: 48)), const SizedBox(height: 8), Text('No recipes found', style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600, color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary)), const SizedBox(height: 4), Text('Try adding more ingredients', style: GoogleFonts.inter(fontSize: 13, color: AppColors.textSecondary))]))
          else ...[
            Text('✨ ${_matched!.length} recipes found!', style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.primary)),
            const SizedBox(height: 12),
            ..._matched!.map((r) => GestureDetector(onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => RecipeDetailScreen(recipe: r))), child: _recipeCard(r, isDark))),
          ],
        ],
        const SizedBox(height: 40),
      ])),
    );
  }

  Widget _recipeCard(Recipe r, bool isDark) => Container(
    margin: const EdgeInsets.only(bottom: 12),
    decoration: BoxDecoration(color: isDark ? AppColors.surfaceDark : AppColors.surface, borderRadius: BorderRadius.circular(16), border: Border.all(color: isDark ? AppColors.borderDark : AppColors.border)),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Container(height: 90, decoration: BoxDecoration(color: isDark ? AppColors.surfaceVariantDark : AppColors.surfaceVariant, borderRadius: const BorderRadius.vertical(top: Radius.circular(16))), child: Center(child: Text(r.emoji, style: const TextStyle(fontSize: 48)))),
      Padding(padding: const EdgeInsets.all(14), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [Expanded(child: Text(r.name, style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w700, color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary))), Icon(Icons.arrow_forward_ios, size: 14, color: AppColors.textSecondary)]),
        const SizedBox(height: 8),
        Wrap(spacing: 6, runSpacing: 4, children: [
          _tag('🔥 ${r.calories} kcal'), _tag('💪 ${r.protein}g'), _tag('⏱ ${r.cookTime}'), _tag('👨‍🍳 ${r.difficulty}'),
        ]),
        const SizedBox(height: 8),
        Text(r.description, style: GoogleFonts.inter(fontSize: 12, color: AppColors.textSecondary, height: 1.4)),
      ])),
    ]),
  );

  Widget _tag(String l) => Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), decoration: BoxDecoration(color: AppColors.surfaceVariant, borderRadius: BorderRadius.circular(10)), child: Text(l, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary, fontWeight: FontWeight.w500)));
}

class RecipeDetailScreen extends StatelessWidget {
  final Recipe recipe;
  const RecipeDetailScreen({super.key, required this.recipe});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: isDark ? AppColors.bgDark : AppColors.bg,
      body: CustomScrollView(slivers: [
        SliverAppBar(expandedHeight: 200, pinned: true,
          leading: IconButton(onPressed: () => Navigator.pop(context), icon: Container(width: 36, height: 36, decoration: BoxDecoration(color: Colors.white.withOpacity(0.9), shape: BoxShape.circle), child: const Icon(Icons.arrow_back_ios, color: AppColors.textPrimary, size: 18))),
          flexibleSpace: FlexibleSpaceBar(background: Container(color: isDark ? AppColors.surfaceVariantDark : AppColors.surfaceVariant, child: Center(child: Text(recipe.emoji, style: const TextStyle(fontSize: 80)))))),
        SliverToBoxAdapter(child: Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(recipe.name, style: GoogleFonts.inter(fontSize: 26, fontWeight: FontWeight.w800, color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary)),
          const SizedBox(height: 8),
          Text(recipe.description, style: GoogleFonts.inter(fontSize: 14, color: AppColors.textSecondary, height: 1.5)),
          const SizedBox(height: 16),
          Row(children: [
            _info('🔥', '${recipe.calories}', 'kcal', AppColors.accentLight, AppColors.accent),
            const SizedBox(width: 10),
            _info('💪', '${recipe.protein}g', 'protein', AppColors.primaryLight, AppColors.primary),
            const SizedBox(width: 10),
            _info('⏱', recipe.cookTime, '', AppColors.amberLight, AppColors.amber),
            const SizedBox(width: 10),
            _info('👨‍🍳', recipe.difficulty, '', AppColors.purpleLight, AppColors.purple),
          ]),
          const SizedBox(height: 20),
          Text('Ingredients', style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700, color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary)),
          const SizedBox(height: 10),
          Wrap(spacing: 8, runSpacing: 8, children: recipe.ingredients.map((i) => Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6), decoration: BoxDecoration(color: AppColors.primaryLight, borderRadius: BorderRadius.circular(20)), child: Text(i, style: const TextStyle(fontSize: 12, color: AppColors.primaryDark, fontWeight: FontWeight.w500)))).toList()),
          const SizedBox(height: 20),
          Text('Instructions', style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700, color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary)),
          const SizedBox(height: 12),
          ...recipe.steps.asMap().entries.map((e) => Container(
            margin: const EdgeInsets.only(bottom: 10), padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(color: isDark ? AppColors.surfaceDark : AppColors.surface, borderRadius: BorderRadius.circular(12), border: Border.all(color: isDark ? AppColors.borderDark : AppColors.border)),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Container(width: 28, height: 28, decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle), child: Center(child: Text('${e.key+1}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 13)))),
              const SizedBox(width: 12),
              Expanded(child: Text(e.value, style: GoogleFonts.inter(fontSize: 14, height: 1.5, color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary))),
            ]),
          )),
          const SizedBox(height: 40),
        ]))),
      ]),
    );
  }

  Widget _info(String emoji, String val, String sub, Color bg, Color color) => Expanded(child: Container(padding: const EdgeInsets.symmetric(vertical: 10), decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(12)), child: Column(children: [Text(emoji, style: const TextStyle(fontSize: 16)), const SizedBox(height: 2), Text(val, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: color)), if (sub.isNotEmpty) Text(sub, style: TextStyle(fontSize: 9, color: color.withOpacity(0.7)))])));
}
