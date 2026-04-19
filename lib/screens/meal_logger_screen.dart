import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../data/app_data.dart';
import '../models/food_item.dart';
import '../models/meal_log.dart';
import '../services/auth_provider.dart';
import '../services/food_recognition_service.dart';
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
  bool _scanning = false;

  final _mealTypes = ['Breakfast', 'Lunch', 'Dinner', 'Snack'];
  final _categories = ['All', 'Protein', 'Carbs', 'Dairy', 'Fruits', 'Vegetables', 'Fats', 'Snacks', 'Supplements', 'Breakfast'];

  @override
  void initState() {
    super.initState();
    _searchCtrl.addListener(_filter);
    // Populate list after the first frame so the provider is available
    WidgetsBinding.instance.addPostFrameCallback((_) => _filter());
  }
  @override
  void dispose() { _searchCtrl.dispose(); super.dispose(); }

  void _filter() {
    final p = Provider.of<NutritionProvider>(context, listen: false);
    final allFoods = [...p.customFoods, ...AppData.foods];
    final q = _searchCtrl.text.toLowerCase();
    setState(() {
      _filtered = allFoods.where((f) {
        final ms = q.isEmpty || f.name.toLowerCase().contains(q) || f.category.toLowerCase().contains(q);
        final mc = _category == 'All' || f.category == _category;
        return ms && mc;
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    final p = Provider.of<NutritionProvider>(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: isDark ? AppColors.bgDark : AppColors.bg,
      appBar: AppBar(
        title: Text('Log a Meal', style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
        automaticallyImplyLeading: false,
        backgroundColor: isDark ? AppColors.surfaceDark : AppColors.surface,
        actions: [
          _scanning
            ? const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)),
              )
            : IconButton(
                tooltip: 'Scan meal photo',
                icon: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(colors: [AppColors.primary, AppColors.brandGreen]),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.camera_alt_rounded, color: Colors.white, size: 18),
                ),
                onPressed: () => _scanMeal(p),
              ),
        ],
      ),
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
        // Food list (with recent section when not searching)
        Expanded(child: _filtered.isEmpty
          ? Center(child: Column(mainAxisSize: MainAxisSize.min, children: [const Text('🔍', style: TextStyle(fontSize: 36)), const SizedBox(height: 8), Text('No foods found', style: GoogleFonts.inter(color: AppColors.textSecondary))]))
          : ListView.builder(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 100),
              itemCount: _filtered.length + (_showRecent(p) ? 1 : 0),
              itemBuilder: (_, i) {
                if (_showRecent(p) && i == 0) return _recentSection(p, context, isDark);
                final food = _filtered[i - (_showRecent(p) ? 1 : 0)];
                return _foodTile(food, p, context, isDark);
              },
            )),
      ]),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showCreateFoodSheet(context, p),
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.add, color: Colors.white),
        label: Text('Create Food', style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: Colors.white)),
      ),
    );
  }

  bool _showRecent(NutritionProvider p) =>
      _searchCtrl.text.isEmpty && p.recentFoods.isNotEmpty;

  Widget _recentSection(NutritionProvider p, BuildContext context, bool isDark) {
    final recents = p.recentFoods;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(4, 4, 4, 10),
        child: Text('Recently Logged', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w700, color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary)),
      ),
      SizedBox(
        height: 100,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          itemCount: recents.length,
          itemBuilder: (_, i) {
            final f = recents[i];
            return GestureDetector(
              onTap: () => _quickAdd(context, f, p),
              child: Container(
                width: 88,
                margin: const EdgeInsets.only(right: 10),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.surfaceDark : AppColors.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: isDark ? AppColors.borderDark : AppColors.border),
                ),
                child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Text(f.emoji, style: const TextStyle(fontSize: 26)),
                  const SizedBox(height: 5),
                  Text(f.name, style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w600, color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary), maxLines: 1, overflow: TextOverflow.ellipsis, textAlign: TextAlign.center),
                  Text('${f.calories.toInt()} kcal', style: GoogleFonts.inter(fontSize: 9, color: AppColors.primary)),
                ]),
              ),
            );
          },
        ),
      ),
      const Padding(
        padding: EdgeInsets.only(top: 14, bottom: 8, left: 4),
        child: Divider(height: 1),
      ),
      Padding(
        padding: const EdgeInsets.fromLTRB(4, 0, 4, 10),
        child: Text('All Foods', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w700, color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary)),
      ),
    ]);
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

  Future<void> _scanMeal(NutritionProvider p) async {
    // Capture context-dependent objects before any await
    final messenger = ScaffoldMessenger.of(context);
    final isDark    = Theme.of(context).brightness == Brightness.dark;

    // 1 — ask the user: camera or gallery
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        decoration: BoxDecoration(
          color: isDark ? AppColors.surfaceDark : AppColors.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 36),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(width: 40, height: 4, decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(2))),
          const SizedBox(height: 20),
          Text('Scan Your Meal', style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700,
            color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary)),
          const SizedBox(height: 6),
          Text('AI will estimate calories & macros from the photo',
            style: GoogleFonts.inter(fontSize: 12, color: AppColors.textSecondary), textAlign: TextAlign.center),
          const SizedBox(height: 24),
          Row(children: [
            Expanded(child: _sourceBtn(Icons.camera_alt_rounded,    'Camera',  AppColors.primary,    () => Navigator.pop(context, ImageSource.camera))),
            const SizedBox(width: 14),
            Expanded(child: _sourceBtn(Icons.photo_library_rounded, 'Gallery', AppColors.brandGreen, () => Navigator.pop(context, ImageSource.gallery))),
          ]),
        ]),
      ),
    );
    if (source == null || !mounted) return;

    // 2 — pick the image
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: source, imageQuality: 80, maxWidth: 1024);
    if (picked == null || !mounted) return;

    // 3 — analyse with Claude vision
    setState(() => _scanning = true);
    final result = await FoodRecognitionService.analyzeFoodImage(picked.path);
    if (!mounted) return;
    setState(() => _scanning = false);

    if (result == null) {
      messenger.showSnackBar(SnackBar(
        content: const Text('Could not detect food. Try a clearer photo with good lighting.'),
        backgroundColor: AppColors.accent,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ));
      return;
    }

    // 4 — show confirmation sheet
    _showScanResult(result, p);
  }

  Widget _sourceBtn(IconData icon, String label, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 18),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 8),
          Text(label, style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: color)),
        ]),
      ),
    );
  }

  void _showScanResult(Map<String, dynamic> result, NutritionProvider p) {
    String mealType = _mealType;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => StatefulBuilder(builder: (ctx, set) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        final calories = (result['calories'] as num?)?.toInt() ?? 0;
        final protein  = (result['protein']  as num?)?.toInt() ?? 0;
        final carbs    = (result['carbs']    as num?)?.toInt() ?? 0;
        final fat      = (result['fat']      as num?)?.toInt() ?? 0;
        return Container(
          padding: EdgeInsets.fromLTRB(24, 16, 24, MediaQuery.of(context).viewInsets.bottom + 32),
          decoration: BoxDecoration(
            color: isDark ? AppColors.surfaceDark : AppColors.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Container(width: 40, height: 4, decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 16),
            // AI badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [AppColors.primary, AppColors.brandGreen]),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                const Icon(Icons.auto_awesome, color: Colors.white, size: 13),
                const SizedBox(width: 5),
                Text('On-Device AI', style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.white)),
              ]),
            ),
            const SizedBox(height: 14),
            Text(result['emoji']?.toString() ?? '🍽️', style: const TextStyle(fontSize: 56)),
            const SizedBox(height: 6),
            Text(result['name']?.toString() ?? 'Unknown food',
              style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.w800,
                color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary),
              textAlign: TextAlign.center),
            const SizedBox(height: 4),
            Text(result['serving']?.toString() ?? '1 serving',
              style: GoogleFonts.inter(fontSize: 12, color: AppColors.textSecondary)),
            const SizedBox(height: 20),
            // Macro pills
            Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
              _scanMacro('$calories', 'kcal',    AppColors.blue),
              _scanMacro('${protein}g', 'Protein', AppColors.primary),
              _scanMacro('${carbs}g',   'Carbs',   AppColors.amber),
              _scanMacro('${fat}g',     'Fat',      AppColors.accent),
            ]),
            const SizedBox(height: 20),
            // Meal type selector
            Text('Add to', style: GoogleFonts.inter(fontSize: 12, color: AppColors.textSecondary)),
            const SizedBox(height: 8),
            Row(children: _mealTypes.map((t) {
              final active = mealType == t;
              return Expanded(child: GestureDetector(
                onTap: () => set(() => mealType = t),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  margin: const EdgeInsets.only(right: 6),
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  decoration: BoxDecoration(
                    color: active ? AppColors.primary : Colors.transparent,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: active ? AppColors.primary : isDark ? AppColors.borderDark : AppColors.border),
                  ),
                  child: Center(child: Text(t,
                    style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600,
                      color: active ? Colors.white : AppColors.textSecondary))),
                ),
              ));
            }).toList()),
            const SizedBox(height: 20),
            SizedBox(width: double.infinity, child: ElevatedButton(
              onPressed: () {
                final messenger = ScaffoldMessenger.of(context);
                final userId = Provider.of<AuthProvider>(context, listen: false).currentUser?.id ?? '';
                Navigator.pop(ctx);
                p.addMeal(MealLog(
                  foodName: result['name']?.toString() ?? 'Unknown food',
                  emoji:    result['emoji']?.toString() ?? '🍽️',
                  calories: (result['calories'] as num?)?.toDouble() ?? 0,
                  protein:  (result['protein']  as num?)?.toDouble() ?? 0,
                  carbs:    (result['carbs']    as num?)?.toDouble() ?? 0,
                  fat:      (result['fat']      as num?)?.toDouble() ?? 0,
                  loggedAt: DateTime.now(),
                  mealType: mealType,
                  quantity: 1,
                  serving:  result['serving']?.toString() ?? '1 serving',
                  userId:   userId,
                ));
                messenger.showSnackBar(SnackBar(
                  content: Text('${result['emoji']} ${result['name']} logged! +$calories kcal'),
                  backgroundColor: AppColors.primary,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  duration: const Duration(seconds: 2),
                ));
              },
              child: Text('Add to $mealType', style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
            )),
          ]),
        );
      }),
    );
  }

  Widget _scanMacro(String val, String label, Color color) => Column(children: [
    Text(val,   style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w800, color: color)),
    Text(label, style: GoogleFonts.inter(fontSize: 10, color: AppColors.textSecondary)),
  ]);

  void _showCreateFoodSheet(BuildContext context, NutritionProvider p) {
    final nameCtrl  = TextEditingController();
    final calCtrl   = TextEditingController();
    final proCtrl   = TextEditingController();
    final carbCtrl  = TextEditingController();
    final fatCtrl   = TextEditingController();
    final servCtrl  = TextEditingController();
    String emoji    = '🍽';
    final formKey   = GlobalKey<FormState>();

    final emojiOptions = ['🍽','🥗','🥩','🍗','🥚','🧀','🥛','🍞','🌾','🥦','🍎','🍌','🥑','🫙','🍜','🍛','🥘','🫕','🥫','🌮'];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(builder: (ctx, set) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
          child: Container(
            decoration: BoxDecoration(
              color: isDark ? AppColors.surfaceDark : AppColors.surface,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            ),
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
              child: Form(
                key: formKey,
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(2)))),
                  const SizedBox(height: 16),
                  Center(child: Text('Create Custom Food', style: GoogleFonts.inter(fontSize: 17, fontWeight: FontWeight.w700, color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary))),
                  const SizedBox(height: 20),
                  // Emoji picker
                  Text('Emoji', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 44,
                    child: ListView(scrollDirection: Axis.horizontal, children: emojiOptions.map((e) =>
                      GestureDetector(
                        onTap: () => set(() => emoji = e),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 150),
                          width: 44, height: 44,
                          margin: const EdgeInsets.only(right: 8),
                          decoration: BoxDecoration(
                            color: emoji == e ? AppColors.primary.withOpacity(0.15) : Colors.transparent,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: emoji == e ? AppColors.primary : isDark ? AppColors.borderDark : AppColors.border),
                          ),
                          child: Center(child: Text(e, style: const TextStyle(fontSize: 22))),
                        ),
                      ),
                    ).toList()),
                  ),
                  const SizedBox(height: 16),
                  _createField(nameCtrl, 'Food Name', isDark, required: true),
                  const SizedBox(height: 12),
                  _createField(servCtrl, 'Serving Size (e.g. 100g)', isDark),
                  const SizedBox(height: 12),
                  Row(children: [
                    Expanded(child: _createField(calCtrl, 'Calories', isDark, numeric: true, required: true)),
                    const SizedBox(width: 10),
                    Expanded(child: _createField(proCtrl, 'Protein (g)', isDark, numeric: true)),
                  ]),
                  const SizedBox(height: 12),
                  Row(children: [
                    Expanded(child: _createField(carbCtrl, 'Carbs (g)', isDark, numeric: true)),
                    const SizedBox(width: 10),
                    Expanded(child: _createField(fatCtrl, 'Fat (g)', isDark, numeric: true)),
                  ]),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        if (!formKey.currentState!.validate()) return;
                        final food = FoodItem(
                          name: nameCtrl.text.trim(),
                          emoji: emoji,
                          calories: double.tryParse(calCtrl.text) ?? 0,
                          protein: double.tryParse(proCtrl.text) ?? 0,
                          carbs: double.tryParse(carbCtrl.text) ?? 0,
                          fat: double.tryParse(fatCtrl.text) ?? 0,
                          serving: servCtrl.text.trim().isEmpty ? '1 serving' : servCtrl.text.trim(),
                          category: 'Custom',
                        );
                        p.addCustomFood(food);
                        // Refresh food list to include the new custom food
                        setState(_filter);
                        Navigator.pop(ctx);
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                          content: Text('$emoji ${food.name} saved!'),
                          backgroundColor: AppColors.primary,
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ));
                      },
                      child: Text('Save Food', style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
                    ),
                  ),
                ]),
              ),
            ),
          ),
        );
      }),
    );
  }

  Widget _createField(TextEditingController ctrl, String hint, bool isDark, {bool numeric = false, bool required = false}) {
    return TextFormField(
      controller: ctrl,
      keyboardType: numeric ? const TextInputType.numberWithOptions(decimal: true) : TextInputType.text,
      style: GoogleFonts.inter(fontSize: 14, color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary),
      decoration: InputDecoration(hintText: hint),
      validator: required ? (v) => (v == null || v.trim().isEmpty) ? 'Required' : null : null,
    );
  }

  Future<void> _antiCheatCheck(BuildContext context, double mealCals, NutritionProvider p, VoidCallback onConfirm) async {
    final dailyTotal = p.todayCalories;
    final singleHigh = mealCals > 3000;
    final dailyHigh = dailyTotal + mealCals > 8000;
    if (!singleHigh && !dailyHigh) { onConfirm(); return; }
    final msg = singleHigh
        ? 'This meal is ${mealCals.toInt()} kcal — unusually high for a single meal. Are you sure?'
        : 'Adding this would bring your daily total to ${(dailyTotal + mealCals).toInt()} kcal. That\'s very high — are you sure?';
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Row(children: [Text('⚠️ '), Text('High Calorie Warning')]),
        content: Text(msg),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFF6B6B)),
            child: const Text('Log Anyway'),
          ),
        ],
      ),
    );
    if (ok == true) onConfirm();
  }

  void _quickAdd(BuildContext context, FoodItem food, NutritionProvider p) {
    final userId = Provider.of<AuthProvider>(context, listen: false).currentUser?.id ?? '';
    _antiCheatCheck(context, food.calories, p, () {
      p.addMeal(MealLog(foodName: food.name, emoji: food.emoji, calories: food.calories, protein: food.protein, carbs: food.carbs, fat: food.fat, loggedAt: DateTime.now(), mealType: _mealType, quantity: 1, serving: food.serving, userId: userId));
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${food.emoji} ${food.name} added! +${food.calories.toInt()} kcal'), backgroundColor: AppColors.primary, behavior: SnackBarBehavior.floating, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), duration: const Duration(seconds: 2)));
    });
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
                _antiCheatCheck(context, food.calories * qty, p, () {
                  p.addMeal(MealLog(foodName: food.name, emoji: food.emoji, calories: food.calories, protein: food.protein, carbs: food.carbs, fat: food.fat, loggedAt: DateTime.now(), mealType: _mealType, quantity: qty, serving: food.serving, userId: userId));
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('✓ Added $qty× ${food.name}'), backgroundColor: AppColors.primary, behavior: SnackBarBehavior.floating, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))));
                });
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
