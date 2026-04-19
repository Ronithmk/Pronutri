import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import '../data/recipe_data.dart';
import '../screens/recipes_screen.dart';

class MealPlanProvider extends ChangeNotifier {
  late Box _box;
  String _userId = '';
  final _rng = Random();

  MealPlanProvider() {
    _box = Hive.box('meal_plans');
  }

  void setUser(String userId) {
    _userId = userId;
    notifyListeners();
  }

  String _weekKey() {
    final now = DateTime.now();
    final weekOfYear = ((now.difference(DateTime(now.year, 1, 1)).inDays) / 7).floor();
    return '${_userId}_${now.year}_w$weekOfYear';
  }

  // ── Get current week's plan ────────────────────────────────────────────────
  Map<String, Map<String, String>> get weekPlan {
    final raw = _box.get(_weekKey());
    if (raw == null) return {};
    final outer = Map<String, dynamic>.from(raw as Map);
    return outer.map((day, meals) =>
        MapEntry(day, Map<String, String>.from(meals as Map)));
  }

  // ── Generate plan for current week ────────────────────────────────────────
  Future<void> generatePlan(String country) async {
    final cuisine = _defaultCuisine(country);
    final pool = kAllRecipes.where((r) =>
        cuisine == null || r.cuisine == cuisine || r.cuisine == 'Healthy').toList();
    if (pool.isEmpty) return;

    final days = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
    final plan = <String, Map<String, String>>{};

    for (final day in days) {
      final shuffled = List<AiRecipe>.from(pool)..shuffle(_rng);
      plan[day] = {
        'breakfast': shuffled.isNotEmpty ? shuffled[0].name : 'Oatmeal',
        'lunch':     shuffled.length > 1  ? shuffled[1].name : 'Salad',
        'dinner':    shuffled.length > 2  ? shuffled[2].name : 'Grilled Chicken',
      };
    }

    await _box.put(_weekKey(), plan);
    notifyListeners();
  }

  // ── Swap one meal slot ─────────────────────────────────────────────────────
  Future<void> swapMeal(String day, String slot, String country) async {
    final plan = Map<String, Map<String, String>>.from(weekPlan);
    final cuisine = _defaultCuisine(country);
    final pool = kAllRecipes.where((r) =>
        cuisine == null || r.cuisine == cuisine || r.cuisine == 'Healthy').toList()
      ..shuffle(_rng);
    if (pool.isNotEmpty) {
      plan[day] = Map<String, String>.from(plan[day] ?? {});
      plan[day]![slot] = pool.first.name;
    }
    await _box.put(_weekKey(), plan);
    notifyListeners();
  }

  // ── Grocery list from current week's plan ─────────────────────────────────
  List<String> get groceryList {
    final plan = weekPlan;
    final allIngredients = <String>{};
    for (final meals in plan.values) {
      for (final recipeName in meals.values) {
        final recipe = kAllRecipes.firstWhere(
          (r) => r.name == recipeName,
          orElse: () => kAllRecipes.first,
        );
        allIngredients.addAll(recipe.ingredients);
      }
    }
    return allIngredients.toList()..sort();
  }

  // ── Checked grocery items ─────────────────────────────────────────────────
  Set<String> get checkedItems {
    final raw = _box.get('${_userId}_grocery_checked');
    if (raw == null) return {};
    return Set<String>.from(raw as List);
  }

  Future<void> toggleGroceryItem(String item) async {
    final checked = Set<String>.from(checkedItems);
    if (checked.contains(item)) {
      checked.remove(item);
    } else {
      checked.add(item);
    }
    await _box.put('${_userId}_grocery_checked', checked.toList());
    notifyListeners();
  }

  Future<void> clearChecked() async {
    await _box.put('${_userId}_grocery_checked', []);
    notifyListeners();
  }

  String? _defaultCuisine(String country) {
    const map = {
      'India':          'North Indian',
      'Pakistan':       'South Asian',
      'Bangladesh':     'South Asian',
      'USA':            'American',
      'United Kingdom': 'British',
      'Mexico':         'Mexican',
      'China':          'East Asian',
      'Japan':          'East Asian',
      'Korea':          'East Asian',
    };
    return map[country];
  }
}
