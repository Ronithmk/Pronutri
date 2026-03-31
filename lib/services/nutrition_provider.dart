import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import '../models/meal_log.dart';
import '../models/water_log.dart';
import '../models/user_model.dart';

class NutritionProvider extends ChangeNotifier {
  late Box<MealLog> _mealBox;
  late Box<WaterLog> _waterBox;
  String _userId = '';

  double calorieGoal = 2200;
  double proteinGoal = 150;
  double carbsGoal = 250;
  double fatGoal = 70;
  double waterGoal = 2500;

  NutritionProvider() {
    _mealBox = Hive.box<MealLog>('meal_logs');
    _waterBox = Hive.box<WaterLog>('water_logs');
  }

  void setUser(UserModel? user) {
    if (user != null) {
      _userId = user.id;
      calorieGoal = user.dailyCalorieGoal;
      proteinGoal = user.proteinGoal;
      carbsGoal = user.carbsGoal;
      fatGoal = user.fatGoal;
      waterGoal = user.waterGoal;
    } else {
      _userId = '';
    }
    notifyListeners();
  }

  List<MealLog> get todayMeals {
    final now = DateTime.now();
    return _mealBox.values.where((m) =>
      m.userId == _userId &&
      m.loggedAt.year == now.year &&
      m.loggedAt.month == now.month &&
      m.loggedAt.day == now.day
    ).toList()..sort((a, b) => b.loggedAt.compareTo(a.loggedAt));
  }

  List<WaterLog> get todayWater {
    final now = DateTime.now();
    return _waterBox.values.where((w) =>
      w.userId == _userId &&
      w.loggedAt.year == now.year &&
      w.loggedAt.month == now.month &&
      w.loggedAt.day == now.day
    ).toList();
  }

  double get todayCalories => todayMeals.fold(0, (s, m) => s + m.calories * m.quantity);
  double get todayProtein => todayMeals.fold(0, (s, m) => s + m.protein * m.quantity);
  double get todayCarbs => todayMeals.fold(0, (s, m) => s + m.carbs * m.quantity);
  double get todayFat => todayMeals.fold(0, (s, m) => s + m.fat * m.quantity);
  double get todayWaterMl => todayWater.fold(0, (s, w) => s + w.amount);

  double get calorieProgress => (todayCalories / calorieGoal).clamp(0, 1);
  double get proteinProgress => (todayProtein / proteinGoal).clamp(0, 1);
  double get carbsProgress => (todayCarbs / carbsGoal).clamp(0, 1);
  double get fatProgress => (todayFat / fatGoal).clamp(0, 1);
  double get waterProgress => (todayWaterMl / waterGoal).clamp(0, 1);

  Future<void> addMeal(MealLog meal) async { await _mealBox.add(meal); notifyListeners(); }
  Future<void> deleteMeal(MealLog meal) async { await meal.delete(); notifyListeners(); }
  Future<void> addWater(double ml) async { await _waterBox.add(WaterLog(amount: ml, loggedAt: DateTime.now(), userId: _userId)); notifyListeners(); }

  int get currentStreak {
    int streak = 0;
    final now = DateTime.now();
    for (int i = 0; i < 30; i++) {
      final day = now.subtract(Duration(days: i));
      final meals = _mealBox.values.where((m) => m.userId == _userId && m.loggedAt.year == day.year && m.loggedAt.month == day.month && m.loggedAt.day == day.day);
      if (meals.isNotEmpty) streak++; else if (i > 0) break;
    }
    return streak;
  }

  List<double> get weeklyCalories {
    final now = DateTime.now();
    return List.generate(7, (i) {
      final day = now.subtract(Duration(days: 6 - i));
      return _mealBox.values.where((m) => m.userId == _userId && m.loggedAt.year == day.year && m.loggedAt.month == day.month && m.loggedAt.day == day.day).fold(0.0, (s, m) => s + m.calories * m.quantity);
    });
  }
}
