import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../data/app_data.dart';
import '../models/food_item.dart';
import '../models/meal_log.dart';
import '../services/auth_provider.dart';
import '../services/nutrition_provider.dart';
import '../theme/app_theme.dart';

class MealLoggerScreen extends StatefulWidget {
  const MealLoggerScreen({super.key});
  @override
  State<MealLoggerScreen> createState() => _MealLoggerScreenState();
}

class _MealLoggerScreenState extends State<MealLoggerScreen> {
  final _searchCtrl = TextEditingController();
  String _mealType = 'Breakfast';
  String _category = 'All';
  List<FoodItem> _filtered = AppData.foods;

  final _mealTypes = ['Breakfast', 'Lunch', 'Dinner', 'Snack'];
  final _categories = ['All', 'Protein', 'Carbs', 'Dairy', 'Fruits', 'Vegetables', 'Fats', 'Snacks', 'Supplements', 'Breakfast'];

  @override
  void initState() { super.initState(); _searchCtrl.addListener(_filter); }
  @override
  void dispose() { _searchCtrl.dispose(); super.dispose(); }

  void _filter() {
    final q = _searchCtrl.text.toLowerCase();
    setState(() { _filtered = AppData.foods.where((f) {
      final ms = q.isEmpty || f.name.toLowerCase().contains(q) || f.category.toLowerCase().contains(q);
      final mc = _category == 'All' || f.category == _category;
      return ms && mc;
    }).toList(); });
  }

  @override
  Widget build(BuildContext context) {
    final p = Provider.of<NutritionProvider>(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: isDark ? AppColors.bgDark : AppColors.bg,
      appBar: AppBar(title: Text('Log a Meal', style: GoogleFonts.inter(fontWeight: FontWeight.w700)), automaticallyImplyLeading: false, backgroundColor: isDark ? AppColors.surfaceDark : AppColors.surface),
      body: Column(children: [
        // Macro progress
        Container(color: isDark ? AppColors.surfaceDark : AppColors.surface, padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
          child: Column(children: [
            _macroRow('Protein', p.proteinProgress, p.todayProtein, p.proteinGoal, 'g', AppColors.primary),
            const SizedBox(height: 6),
            _macroRow('Carbs', p.carbsProgress, p.todayCarbs, p.carbsGoal, 'g', AppColors.amber),
            const SizedBox(height: 6),
            _macroRow('Fat', p.fatProgress, p.todayFat, p.fatGoal, 'g', AppColors.accent),
            const SizedBox(height: 6),
            _macroRow('Calories', p.calorieProgress, p.todayCalories, p.calorieGoal, '', AppColors.blue),
          ])),
        Divider(height: 1, color: isDark ? AppColors.borderDark : AppColors.border),
        // Meal type
        SizedBox(height: 44, child: ListView(scrollDirection: Axis.horizontal, padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          children: _mealTypes.map((t) {
            final active = _mealType == t;
            return GestureDetector(onTap: () => setState(() => _mealType = t), child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
              decoration: BoxDecoration(color: active ? AppColors.primary : Colors.transparent, borderRadius: BorderRadius.circular(20), border: Border.all(color: active ? AppColors.primary : isDark ? AppColors.borderDark : AppColors.border)),
              child: Text(t, style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: active ? Colors.white : AppColors.textSecondary)),
            ));
          }).toList())),
        // Search
        Padding(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8), child: TextField(controller: _searchCtrl,
          style: GoogleFonts.inter(fontSize: 14, color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary),
          decoration: InputDecoration(hintText: 'Search foods...', prefixIcon: const Icon(Icons.search, size: 20, color: AppColors.textSecondary),
            suffixIcon: _searchCtrl.text.isNotEmpty ? IconButton(onPressed: () { _searchCtrl.clear(); _filter(); }, icon: const Icon(Icons.clear, size: 18)) : null))),
        // Category chips
        SizedBox(height: 36, child: ListView(scrollDirection: Axis.horizontal, padding: const EdgeInsets.symmetric(horizontal: 12),
          children: _categories.map((c) {
            final active = _category == c;
            return GestureDetector(onTap: () { setState(() => _category = c); _filter(); }, child: Container(
              margin: const EdgeInsets.only(right: 6),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(color: active ? AppColors.primary.withOpacity(0.1) : Colors.transparent, borderRadius: BorderRadius.circular(16), border: Border.all(color: active ? AppColors.primary : isDark ? AppColors.borderDark : AppColors.border)),
              child: Text(c, style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w500, color: active ? AppColors.primary : AppColors.textSecondary)),
            ));
          }).toList())),
        const SizedBox(height: 6),
        // Food list
        Expanded(child: _filtered.isEmpty
          ? Center(child: Column(mainAxisSize: MainAxisSize.min, children: [const Text('🔍', style: TextStyle(fontSize: 36)), const SizedBox(height: 8), Text('No foods found', style: GoogleFonts.inter(color: AppColors.textSecondary))]))
          : ListView.builder(padding: const EdgeInsets.symmetric(horizontal: 12), itemCount: _filtered.length, itemBuilder: (_, i) => _foodTile(_filtered[i], p, context, isDark))),
      ]),
    );
  }

  Widget _macroRow(String label, double progress, double val, double goal, String unit, Color color) {
    return Row(children: [
      SizedBox(width: 56, child: Text(label, style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w600))),
      Expanded(child: ClipRRect(borderRadius: BorderRadius.circular(4), child: LinearProgressIndicator(value: progress, minHeight: 6, backgroundColor: color.withOpacity(0.12), valueColor: AlwaysStoppedAnimation(color)))),
      const SizedBox(width: 8),
      SizedBox(width: 80, child: Text('${val.toInt()} / ${goal.toInt()}$unit', style: TextStyle(fontSize: 10, color: color, fontWeight: FontWeight.w600), textAlign: TextAlign.right)),
    ]);
  }

  Widget _foodTile(FoodItem food, NutritionProvider p, BuildContext context, bool isDark) {
    return GestureDetector(
      onTap: () => _showModal(context, food, p),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: isDark ? AppColors.surfaceDark : AppColors.surface, borderRadius: BorderRadius.circular(14), border: Border.all(color: isDark ? AppColors.borderDark : AppColors.border)),
        child: Row(children: [
          Container(width: 44, height: 44, decoration: BoxDecoration(color: isDark ? AppColors.surfaceVariantDark : AppColors.surfaceVariant, borderRadius: BorderRadius.circular(10)), child: Center(child: Text(food.emoji, style: const TextStyle(fontSize: 22)))),
          const SizedBox(width: 10),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(food.name, style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary)),
            Text('P: ${food.protein}g · C: ${food.carbs}g · F: ${food.fat}g · ${food.serving}', style: GoogleFonts.inter(fontSize: 11, color: AppColors.textSecondary)),
          ])),
          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Text('${food.calories.toInt()}', style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.primary)),
            Text('kcal', style: GoogleFonts.inter(fontSize: 10, color: AppColors.textSecondary)),
          ]),
          const SizedBox(width: 8),
          GestureDetector(onTap: () => _quickAdd(context, food, p),
            child: Container(width: 32, height: 32, decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle), child: const Icon(Icons.add, color: Colors.white, size: 18))),
        ]),
      ),
    );
  }

  void _quickAdd(BuildContext context, FoodItem food, NutritionProvider p) {
    final userId = Provider.of<AuthProvider>(context, listen: false).currentUser?.id ?? '';
    p.addMeal(MealLog(foodName: food.name, emoji: food.emoji, calories: food.calories, protein: food.protein, carbs: food.carbs, fat: food.fat, loggedAt: DateTime.now(), mealType: _mealType, quantity: 1, serving: food.serving, userId: userId));
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${food.emoji} ${food.name} added! +${food.calories.toInt()} kcal'), backgroundColor: AppColors.primary, behavior: SnackBarBehavior.floating, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), duration: const Duration(seconds: 2)));
  }

  void _showModal(BuildContext context, FoodItem food, NutritionProvider p) {
    double qty = 1;
    showModalBottomSheet(context: context, isScrollControlled: true, backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(builder: (ctx, set) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return Container(
          padding: EdgeInsets.fromLTRB(24, 20, 24, MediaQuery.of(context).viewInsets.bottom + 24),
          decoration: BoxDecoration(color: isDark ? AppColors.surfaceDark : AppColors.surface, borderRadius: const BorderRadius.vertical(top: Radius.circular(24))),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Container(width: 40, height: 4, decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 16),
            Text(food.emoji, style: const TextStyle(fontSize: 48)),
            const SizedBox(height: 8),
            Text(food.name, style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.w700, color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary)),
            Text('${food.serving} · ${food.calories.toInt()} kcal', style: GoogleFonts.inter(fontSize: 13, color: AppColors.textSecondary)),
            const SizedBox(height: 16),
            Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
              _modalMacro('Protein', '${(food.protein * qty).toStringAsFixed(1)}g', AppColors.primary),
              _modalMacro('Carbs', '${(food.carbs * qty).toStringAsFixed(1)}g', AppColors.amber),
              _modalMacro('Fat', '${(food.fat * qty).toStringAsFixed(1)}g', AppColors.accent),
              _modalMacro('Calories', '${(food.calories * qty).toInt()}', AppColors.blue),
            ]),
            const SizedBox(height: 20),
            Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              _qtyBtn('-', () => set(() => qty = (qty - 0.5).clamp(0.5, 10)), isDark),
              const SizedBox(width: 20),
              Column(children: [Text(qty.toString(), style: GoogleFonts.inter(fontSize: 32, fontWeight: FontWeight.w800, color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary)), Text('servings', style: GoogleFonts.inter(fontSize: 11, color: AppColors.textSecondary))]),
              const SizedBox(width: 20),
              _qtyBtn('+', () => set(() => qty = (qty + 0.5).clamp(0.5, 10)), isDark),
            ]),
            const SizedBox(height: 20),
            SizedBox(width: double.infinity, child: ElevatedButton(
              onPressed: () {
                Navigator.pop(ctx);
                final userId = Provider.of<AuthProvider>(context, listen: false).currentUser?.id ?? '';
                p.addMeal(MealLog(foodName: food.name, emoji: food.emoji, calories: food.calories, protein: food.protein, carbs: food.carbs, fat: food.fat, loggedAt: DateTime.now(), mealType: _mealType, quantity: qty, serving: food.serving, userId: userId));
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('✓ Added $qty× ${food.name}'), backgroundColor: AppColors.primary, behavior: SnackBarBehavior.floating, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))));
              },
              child: Text('Add to $_mealType'),
            )),
          ]),
        );
      }),
    );
  }

  Widget _modalMacro(String label, String val, Color color) => Column(children: [
    Text(val, style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700, color: color)),
    Text(label, style: const TextStyle(fontSize: 10, color: AppColors.textSecondary)),
  ]);

  Widget _qtyBtn(String label, VoidCallback onTap, bool isDark) => GestureDetector(onTap: onTap, child: Container(
    width: 44, height: 44,
    decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: isDark ? AppColors.borderDark : AppColors.border), color: isDark ? AppColors.surfaceVariantDark : AppColors.surface),
    child: Center(child: Text(label, style: const TextStyle(fontSize: 22))),
  ));
}
