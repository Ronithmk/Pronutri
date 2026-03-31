import 'package:hive/hive.dart';
part 'user_model.g.dart';

@HiveType(typeId: 2)
class UserModel extends HiveObject {
  @HiveField(0) late String id;
  @HiveField(1) late String name;
  @HiveField(2) late String email;
  @HiveField(3) late String password;
  @HiveField(4) late double weight;
  @HiveField(5) late double height;
  @HiveField(6) late int age;
  @HiveField(7) late String gender;
  @HiveField(8) late String goal;
  @HiveField(9) late String activityLevel;
  @HiveField(10) late DateTime createdAt;
  @HiveField(11) String? profileImagePath;
  @HiveField(12) late double targetWeight;
  @HiveField(13) late bool emailVerified;

  UserModel({
    required this.id, required this.name, required this.email,
    required this.password, required this.weight, required this.height,
    required this.age, required this.gender, required this.goal,
    required this.activityLevel, required this.createdAt,
    this.profileImagePath, required this.targetWeight,
    this.emailVerified = false,
  });

  double get bmi => weight / ((height / 100) * (height / 100));

  String get bmiCategory {
    if (bmi < 18.5) return 'Underweight';
    if (bmi < 25) return 'Normal';
    if (bmi < 30) return 'Overweight';
    return 'Obese';
  }

  double get dailyCalorieGoal {
    double bmr = gender == 'male'
        ? 10 * weight + 6.25 * height - 5 * age + 5
        : 10 * weight + 6.25 * height - 5 * age - 161;
    double mult;
    switch (activityLevel) {
      case 'sedentary': mult = 1.2; break;
      case 'light': mult = 1.375; break;
      case 'moderate': mult = 1.55; break;
      case 'active': mult = 1.725; break;
      default: mult = 1.55;
    }
    double tdee = bmr * mult;
    switch (goal) {
      case 'lose': return tdee - 500;
      case 'gain': return tdee + 300;
      default: return tdee;
    }
  }

  double get proteinGoal => weight * 1.8;
  double get carbsGoal => (dailyCalorieGoal * 0.45) / 4;
  double get fatGoal => (dailyCalorieGoal * 0.25) / 9;
  double get waterGoal => weight * 35;
}
