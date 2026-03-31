import 'package:hive/hive.dart';
part 'meal_log.g.dart';

@HiveType(typeId: 0)
class MealLog extends HiveObject {
  @HiveField(0) late String foodName;
  @HiveField(1) late String emoji;
  @HiveField(2) late double calories;
  @HiveField(3) late double protein;
  @HiveField(4) late double carbs;
  @HiveField(5) late double fat;
  @HiveField(6) late DateTime loggedAt;
  @HiveField(7) late String mealType;
  @HiveField(8) late double quantity;
  @HiveField(9) late String serving;
  @HiveField(10) late String userId;

  MealLog({
    required this.foodName, required this.emoji,
    required this.calories, required this.protein,
    required this.carbs, required this.fat,
    required this.loggedAt, required this.mealType,
    required this.quantity, required this.serving,
    required this.userId,
  });
}
