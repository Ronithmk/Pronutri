import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../services/meal_plan_provider.dart';
import '../services/auth_provider.dart';
import '../theme/app_theme.dart';

class MealPlanScreen extends StatefulWidget {
  const MealPlanScreen({super.key});
  @override
  State<MealPlanScreen> createState() => _MealPlanScreenState();
}

class _MealPlanScreenState extends State<MealPlanScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabs;
  bool _showGrocery = false;

  final _days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
  final _fullDays = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 7, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final day = DateTime.now().weekday - 1;
      _tabs.animateTo(day.clamp(0, 6));
    });
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final mp = context.watch<MealPlanProvider>();
    final auth = context.read<AuthProvider>();
    final country = auth.currentUser?.country ?? 'India';
    final plan = mp.weekPlan;

    return Scaffold(
      backgroundColor: isDark ? AppColors.bgDark : AppColors.bg,
      appBar: AppBar(
        backgroundColor: isDark ? AppColors.surfDark : AppColors.surface,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        title: Text('Meal Planner',
            style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 18,
                color: isDark ? AppColors.textPriDark : AppColors.textPri)),
        actions: [
          TextButton.icon(
            onPressed: () => setState(() => _showGrocery = !_showGrocery),
            icon: Icon(_showGrocery ? Icons.calendar_today : Icons.shopping_cart_outlined,
                size: 18, color: AppColors.brandBlue),
            label: Text(_showGrocery ? 'Plan' : 'Grocery',
                style: GoogleFonts.inter(color: AppColors.brandBlue, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
      body: plan.isEmpty
          ? _EmptyPlan(country: country)
          : _showGrocery
              ? _GroceryList(mp: mp)
              : Column(children: [
                  _DayTabs(tabs: _tabs, days: _days),
                  Expanded(
                    child: TabBarView(
                      controller: _tabs,
                      children: List.generate(7, (i) {
                        final dayPlan = plan[_fullDays[i]] ?? {};
                        return _DayView(
                          day: _fullDays[i],
                          meals: dayPlan,
                          country: country,
                          mp: mp,
                        );
                      }),
                    ),
                  ),
                ]),
      floatingActionButton: plan.isEmpty ? null : null,
    );
  }
}

class _EmptyPlan extends StatefulWidget {
  final String country;
  const _EmptyPlan({required this.country});
  @override
  State<_EmptyPlan> createState() => _EmptyPlanState();
}

class _EmptyPlanState extends State<_EmptyPlan> {
  bool _loading = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final mp = context.read<MealPlanProvider>();

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Container(
            width: 100, height: 100,
            decoration: BoxDecoration(
              color: AppColors.brandGreen.withOpacity(0.12),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.restaurant_menu, size: 48, color: AppColors.brandGreen),
          ),
          const SizedBox(height: 24),
          Text('No Meal Plan Yet',
              style: GoogleFonts.inter(fontSize: 22, fontWeight: FontWeight.w700,
                  color: isDark ? AppColors.textPriDark : AppColors.textPri)),
          const SizedBox(height: 8),
          Text('Generate a personalized weekly meal plan based on your region.',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(fontSize: 14, color: isDark ? AppColors.textSecDark : AppColors.textSec)),
          const SizedBox(height: 32),
          _loading
              ? const CircularProgressIndicator(color: AppColors.brandGreen)
              : ElevatedButton.icon(
                  onPressed: () async {
                    setState(() => _loading = true);
                    await mp.generatePlan(widget.country);
                    if (mounted) setState(() => _loading = false);
                  },
                  icon: const Icon(Icons.auto_awesome, size: 18),
                  label: Text('Generate This Week\'s Plan',
                      style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.brandGreen,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                ),
        ]),
      ),
    );
  }
}

class _DayTabs extends StatelessWidget {
  final TabController tabs;
  final List<String> days;
  const _DayTabs({required this.tabs, required this.days});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      color: isDark ? AppColors.surfDark : AppColors.surface,
      child: TabBar(
        controller: tabs,
        isScrollable: true,
        tabAlignment: TabAlignment.start,
        indicatorColor: AppColors.brandGreen,
        labelColor: AppColors.brandGreen,
        unselectedLabelColor: isDark ? AppColors.textSecDark : AppColors.textSec,
        labelStyle: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 13),
        unselectedLabelStyle: GoogleFonts.inter(fontWeight: FontWeight.w500, fontSize: 13),
        tabs: days.map((d) => Tab(text: d)).toList(),
      ),
    );
  }
}

class _DayView extends StatelessWidget {
  final String day;
  final Map<String, String> meals;
  final String country;
  final MealPlanProvider mp;
  const _DayView({required this.day, required this.meals, required this.country, required this.mp});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final slots = [
      ('breakfast', '🌅', 'Breakfast', const Color(0xFFFF9A3C)),
      ('lunch',     '☀️', 'Lunch',     AppColors.brandGreen),
      ('dinner',    '🌙', 'Dinner',    AppColors.brandBlue),
    ];

    return ListView(padding: const EdgeInsets.all(16), children: [
      Text(day, style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.w800,
          color: isDark ? AppColors.textPriDark : AppColors.textPri)),
      const SizedBox(height: 12),
      ...slots.map((slot) {
        final (key, emoji, label, color) = slot;
        final recipeName = meals[key] ?? '–';
        return _MealSlotCard(
          emoji: emoji, label: label, recipeName: recipeName,
          color: color, isDark: isDark,
          onSwap: () => mp.swapMeal(day, key, country),
        );
      }),
    ]);
  }
}

class _MealSlotCard extends StatefulWidget {
  final String emoji, label, recipeName;
  final Color color;
  final bool isDark;
  final Future<void> Function() onSwap;
  const _MealSlotCard({
    required this.emoji, required this.label, required this.recipeName,
    required this.color, required this.isDark, required this.onSwap,
  });
  @override
  State<_MealSlotCard> createState() => _MealSlotCardState();
}

class _MealSlotCardState extends State<_MealSlotCard> {
  bool _loading = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: widget.isDark ? AppColors.surfDark : AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: widget.isDark ? AppColors.borderDark : AppColors.border),
      ),
      child: Row(children: [
        Container(
          width: 44, height: 44,
          decoration: BoxDecoration(
            color: widget.color.withOpacity(0.12),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Center(child: Text(widget.emoji, style: const TextStyle(fontSize: 22))),
        ),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(widget.label,
              style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600,
                  color: widget.color)),
          const SizedBox(height: 2),
          Text(widget.recipeName,
              style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600,
                  color: widget.isDark ? AppColors.textPriDark : AppColors.textPri)),
        ])),
        _loading
            ? const SizedBox(width: 20, height: 20,
                child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.brandBlue))
            : IconButton(
                icon: const Icon(Icons.refresh_rounded, size: 20, color: AppColors.brandBlue),
                tooltip: 'Swap meal',
                onPressed: () async {
                  setState(() => _loading = true);
                  await widget.onSwap();
                  if (mounted) setState(() => _loading = false);
                },
              ),
      ]),
    );
  }
}

class _GroceryList extends StatelessWidget {
  final MealPlanProvider mp;
  const _GroceryList({required this.mp});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final items = mp.groceryList;
    final checked = mp.checkedItems;
    final remaining = items.where((i) => !checked.contains(i)).length;

    return Column(children: [
      Container(
        color: isDark ? AppColors.surfDark : AppColors.surface,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(children: [
          Text('$remaining items left',
              style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600,
                  color: isDark ? AppColors.textSecDark : AppColors.textSec)),
          const Spacer(),
          if (checked.isNotEmpty)
            TextButton(
              onPressed: mp.clearChecked,
              child: Text('Clear checked',
                  style: GoogleFonts.inter(fontSize: 12, color: AppColors.accent)),
            ),
        ]),
      ),
      Expanded(
        child: ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          itemCount: items.length,
          itemBuilder: (context, i) {
            final item = items[i];
            final done = checked.contains(item);
            return InkWell(
              onTap: () => mp.toggleGroceryItem(item),
              borderRadius: BorderRadius.circular(10),
              child: Container(
                margin: const EdgeInsets.only(bottom: 6),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: done
                      ? (isDark ? AppColors.borderDark : AppColors.border).withOpacity(0.5)
                      : isDark ? AppColors.surfDark : AppColors.surface,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                      color: done
                          ? Colors.transparent
                          : isDark ? AppColors.borderDark : AppColors.border),
                ),
                child: Row(children: [
                  Icon(
                    done ? Icons.check_circle : Icons.radio_button_unchecked,
                    size: 20,
                    color: done ? AppColors.brandGreen : isDark ? AppColors.textSecDark : AppColors.textHint,
                  ),
                  const SizedBox(width: 10),
                  Expanded(child: Text(
                    item,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: done
                          ? isDark ? AppColors.textSecDark : AppColors.textHint
                          : isDark ? AppColors.textPriDark : AppColors.textPri,
                      decoration: done ? TextDecoration.lineThrough : null,
                    ),
                  )),
                ]),
              ),
            );
          },
        ),
      ),
    ]);
  }
}
