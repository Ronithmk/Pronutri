class UserModel {
  final String id;
  final String name;
  final String email;
  final String password;
  final double weight;
  final double height;
  final int age;
  final String gender;
  final String goal;
  final String activityLevel;
  final double targetWeight;
  final bool emailVerified;
  final int credits;
  final DateTime trialEnd;
  final bool subscriptionActive;

  // ── Role & Trainer fields ────────────────────────────────────────────────
  /// 'learner' | 'trainer'
  final String role;

  /// '' (learner) | 'pending' | 'approved' | 'rejected'
  final String trainerStatus;

  /// Trainer's specialization categories
  final List<String> specializations;

  /// Years of professional experience (trainers only)
  final int yearsExperience;

  /// Short professional bio (trainers only)
  final String bio;

  UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.password,
    required this.weight,
    required this.height,
    required this.age,
    required this.gender,
    required this.goal,
    required this.activityLevel,
    required this.targetWeight,
    this.emailVerified      = false,
    this.credits            = 100,
    DateTime? trialEnd,
    this.subscriptionActive = false,
    this.role               = 'learner',
    this.trainerStatus      = '',
    this.specializations    = const [],
    this.yearsExperience    = 0,
    this.bio                = '',
  }) : trialEnd = trialEnd ?? DateTime.now().add(const Duration(days: 30));

  // ── Role helpers ──────────────────────────────────────────────────────────
  bool get isTrainer          => role == 'trainer';
  bool get isLearner          => role == 'learner';
  bool get isTrainerPending   => role == 'trainer' && trainerStatus == 'pending';
  bool get isTrainerApproved  => role == 'trainer' && trainerStatus == 'approved';
  bool get isTrainerRejected  => role == 'trainer' && trainerStatus == 'rejected';

  // ── Calorie goal using Mifflin-St Jeor ────────────────────────────────────
  double get dailyCalorieGoal {
    double bmr = gender == 'male'
        ? 10 * weight + 6.25 * height - 5 * age + 5
        : 10 * weight + 6.25 * height - 5 * age - 161;
    double factor = activityLevel == 'sedentary'   ? 1.2
                  : activityLevel == 'light'        ? 1.375
                  : activityLevel == 'moderate'     ? 1.55
                  : activityLevel == 'active'       ? 1.725
                  : 1.9;
    double tdee = bmr * factor;
    if (goal == 'lose')  return tdee - 500;
    if (goal == 'gain')  return tdee + 300;
    return tdee;
  }

  double get proteinGoal  => weight * 2.0;
  double get carbsGoal    => (dailyCalorieGoal * 0.45) / 4;
  double get fatGoal      => (dailyCalorieGoal * 0.25) / 9;
  double get waterGoal    => weight * 35;
  double get bmi          => weight / ((height / 100) * (height / 100));
  String get bmiCategory  => bmi < 18.5 ? 'Underweight'
                           : bmi < 25   ? 'Normal'
                           : bmi < 30   ? 'Overweight'
                           : 'Obese';

  // ── Subscription helpers ──────────────────────────────────────────────────
  bool get isTrialActive    => DateTime.now().isBefore(trialEnd);
  int  get trialDaysLeft    => trialEnd.difference(DateTime.now()).inDays.clamp(0, 30);
  bool get hasAccess        => isTrialActive || subscriptionActive;
  bool get hasCredits       => credits > 0;

  UserModel copyWith({
    String? id,
    String? name,
    String? email,
    String? password,
    double? weight,
    double? height,
    int? age,
    String? gender,
    String? goal,
    String? activityLevel,
    double? targetWeight,
    bool? emailVerified,
    int? credits,
    DateTime? trialEnd,
    bool? subscriptionActive,
    String? role,
    String? trainerStatus,
    List<String>? specializations,
    int? yearsExperience,
    String? bio,
  }) => UserModel(
    id:                 id                ?? this.id,
    name:               name              ?? this.name,
    email:              email             ?? this.email,
    password:           password          ?? this.password,
    weight:             weight            ?? this.weight,
    height:             height            ?? this.height,
    age:                age               ?? this.age,
    gender:             gender            ?? this.gender,
    goal:               goal              ?? this.goal,
    activityLevel:      activityLevel     ?? this.activityLevel,
    targetWeight:       targetWeight      ?? this.targetWeight,
    emailVerified:      emailVerified     ?? this.emailVerified,
    credits:            credits           ?? this.credits,
    trialEnd:           trialEnd          ?? this.trialEnd,
    subscriptionActive: subscriptionActive ?? this.subscriptionActive,
    role:               role              ?? this.role,
    trainerStatus:      trainerStatus     ?? this.trainerStatus,
    specializations:    specializations   ?? this.specializations,
    yearsExperience:    yearsExperience   ?? this.yearsExperience,
    bio:                bio               ?? this.bio,
  );
}
