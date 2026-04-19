import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';

class HabitBadge {
  final String id;
  final String emoji;
  final String title;
  final String description;
  final bool earned;
  const HabitBadge({
    required this.id,
    required this.emoji,
    required this.title,
    required this.description,
    required this.earned,
  });
}

class HabitProvider extends ChangeNotifier {
  late Box _box;
  String _userId = '';

  HabitProvider() {
    _box = Hive.box('habits_data');
  }

  void setUser(String userId) {
    _userId = userId;
    notifyListeners();
  }

  String _key(DateTime d) =>
      '${_userId}_${d.year}-${_pad(d.month)}-${_pad(d.day)}';

  String _pad(int n) => n.toString().padLeft(2, '0');

  Map<String, dynamic> _dataFor(DateTime date) {
    final raw = _box.get(_key(date));
    if (raw == null) return {};
    return Map<String, dynamic>.from(raw as Map);
  }

  Map<String, dynamic> get _today => _dataFor(DateTime.now());

  bool _getBool(String field) => (_today[field] as bool?) ?? false;
  double _getDouble(String field) => ((_today[field]) as num?)?.toDouble() ?? 0.0;

  bool get waterDone    => _getBool('water');
  bool get sleepDone    => _getBool('sleep');
  bool get stepsDone    => _getBool('steps');
  bool get junkFreeDone => _getBool('junk_free');
  bool get mealDone     => _getBool('meal');
  double get sleepHours => _getDouble('sleep_hours');
  int? get moodToday    => _today['mood'] as int?;

  int get completedToday =>
      [waterDone, sleepDone, stepsDone, junkFreeDone, mealDone].where((b) => b).length;

  bool get allDoneToday => completedToday == 5;

  Future<void> toggleHabit(String field) async {
    final data = Map<String, dynamic>.from(_today);
    data[field] = !(data[field] as bool? ?? false);
    await _box.put(_key(DateTime.now()), data);
    notifyListeners();
  }

  Future<void> setSleepHours(double hours) async {
    final data = Map<String, dynamic>.from(_today);
    data['sleep_hours'] = hours;
    data['sleep'] = hours >= 6.5;
    await _box.put(_key(DateTime.now()), data);
    notifyListeners();
  }

  Future<void> setMood(int level) async {
    final data = Map<String, dynamic>.from(_today);
    data['mood'] = level;
    await _box.put(_key(DateTime.now()), data);
    notifyListeners();
  }

  // ── Streak ──────────────────────────────────────────────────────────────────
  int get currentStreak {
    int streak = 0;
    var date = DateTime.now().subtract(const Duration(days: 1));
    for (int i = 0; i < 365; i++) {
      if (_allDone(_dataFor(date))) {
        streak++;
        date = date.subtract(const Duration(days: 1));
      } else {
        break;
      }
    }
    if (allDoneToday) streak++;
    return streak;
  }

  bool _allDone(Map<String, dynamic> d) =>
      d['water'] == true &&
      d['sleep'] == true &&
      d['steps'] == true &&
      d['junk_free'] == true &&
      d['meal'] == true;

  // ── Per-habit streak ────────────────────────────────────────────────────────
  int _habitStreak(String field) {
    int streak = 0;
    var date = DateTime.now();
    for (int i = 0; i < 365; i++) {
      if (_dataFor(date)[field] == true) {
        streak++;
        date = date.subtract(const Duration(days: 1));
      } else {
        break;
      }
    }
    return streak;
  }

  // ── Level ───────────────────────────────────────────────────────────────────
  String get levelName {
    final s = currentStreak;
    if (s >= 100) return 'Platinum';
    if (s >= 30)  return 'Gold';
    if (s >= 7)   return 'Silver';
    return 'Bronze';
  }

  String get levelEmoji {
    switch (levelName) {
      case 'Platinum': return '💎';
      case 'Gold':     return '🥇';
      case 'Silver':   return '🥈';
      default:         return '🥉';
    }
  }

  double get levelProgress {
    final s = currentStreak;
    if (s >= 100) return 1.0;
    if (s >= 30)  return (s - 30) / 70.0;
    if (s >= 7)   return (s - 7)  / 23.0;
    return s / 7.0;
  }

  int get nextLevelDays {
    final s = currentStreak;
    if (s >= 100) return 0;
    if (s >= 30)  return 100 - s;
    if (s >= 7)   return 30  - s;
    return 7 - s;
  }

  // ── Badges ──────────────────────────────────────────────────────────────────
  List<HabitBadge> get badges {
    final s      = currentStreak;
    final waterS = _habitStreak('water');
    final sleepS = _habitStreak('sleep');
    final junkS  = _habitStreak('junk_free');
    final stepsS = _habitStreak('steps');
    final mealS  = _habitStreak('meal');

    return [
      HabitBadge(id: 'first_day',    emoji: '🌟', title: 'First Step',     description: 'Complete your first habit day', earned: s >= 1),
      HabitBadge(id: 'week_streak',  emoji: '🔥', title: 'Week Warrior',   description: '7-day streak',                  earned: s >= 7),
      HabitBadge(id: 'month_streak', emoji: '💪', title: 'Month Master',   description: '30-day streak',                 earned: s >= 30),
      HabitBadge(id: 'water_hero',   emoji: '💧', title: 'Hydration Hero', description: 'Water 7 days in a row',         earned: waterS >= 7),
      HabitBadge(id: 'sleep_champ',  emoji: '😴', title: 'Sleep Champion', description: 'Sleep goal 7 days in a row',    earned: sleepS >= 7),
      HabitBadge(id: 'clean_eater',  emoji: '🥗', title: 'Clean Eater',    description: 'Junk-free for 14 days',         earned: junkS >= 14),
      HabitBadge(id: 'step_king',    emoji: '🚶', title: 'Step King',      description: 'Steps goal 7 days in a row',    earned: stepsS >= 7),
      HabitBadge(id: 'meal_planner', emoji: '🍽', title: 'Meal Planner',   description: 'Log meals 5 days in a row',     earned: mealS >= 5),
    ];
  }

  // ── Last 7 days for mini-calendar ───────────────────────────────────────────
  List<bool> get last7DaysCompletion => List.generate(7, (i) {
    final date = DateTime.now().subtract(Duration(days: 6 - i));
    return _allDone(_dataFor(date));
  });

  // ── Mood history (last 7 days) ──────────────────────────────────────────────
  List<int?> get last7DaysMood => List.generate(7, (i) {
    final date = DateTime.now().subtract(Duration(days: 6 - i));
    return _dataFor(date)['mood'] as int?;
  });
}
