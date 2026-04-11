import 'dart:async';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'step_tracking_service.dart';

class ActivityBadge {
  final String id;
  final String emoji;
  final String title;
  final String description;
  bool earned;

  ActivityBadge({
    required this.id,
    required this.emoji,
    required this.title,
    required this.description,
    this.earned = false,
  });
}

class ActivityProvider extends ChangeNotifier {
  int       _todaySteps      = 0;
  double    _todayDistanceKm = 0;
  double    _todayCalsBurned = 0;
  List<int> _weeklySteps     = List.filled(7, 0);
  bool      _loading         = false;
  bool      _isTracking      = false;
  bool      _permDenied      = false;
  final Map<String, DateTime> _badgeUnlockedAt = {};
  final Map<String, Timer> _badgeCelebrationTimers = {};

  int       get todaySteps      => _todaySteps;
  double    get todayDistanceKm => _todayDistanceKm;
  double    get todayCalsBurned => _todayCalsBurned;
  List<int> get weeklySteps     => _weeklySteps;
  bool      get loading         => _loading;
  bool      get hasPermission   => _isTracking;
  bool      get permDenied      => _permDenied; // true = user permanently denied
  String    get pedestrianStatus => StepTrackingService.status;

  static const int stepGoal = 10000;
  static const Duration badgeCelebrationDuration = Duration(minutes: 5);
  double get stepProgress => (_todaySteps / stepGoal).clamp(0.0, 1.0);

  // ── Badges ────────────────────────────────────────────────────────────────
  final List<ActivityBadge> badges = [
    ActivityBadge(id: 'first_steps',   emoji: '👟', title: 'First Steps',   description: '100 steps in a day'),
    ActivityBadge(id: 'walker',        emoji: '🚶', title: 'Walker',        description: '5,000 steps in a day'),
    ActivityBadge(id: 'daily_hero',    emoji: '🏃', title: 'Daily Hero',    description: '10,000 steps today'),
    ActivityBadge(id: 'speed_demon',   emoji: '⚡', title: 'Speed Demon',   description: '15,000 steps today'),
    ActivityBadge(id: '1km_club',      emoji: '📍', title: '1KM Club',      description: '1 km walked/ran'),
    ActivityBadge(id: '5km_run',       emoji: '🏅', title: '5KM Run',       description: '5 km in a day'),
    ActivityBadge(id: '10km_hero',     emoji: '🎽', title: '10KM Hero',     description: '10 km in a day'),
    ActivityBadge(id: 'half_marathon', emoji: '🏆', title: 'Half Marathon', description: '21 km in a day'),
    ActivityBadge(id: 'week_warrior',  emoji: '🗓️', title: 'Week Warrior',  description: '5k+ steps 7 days in a row'),
  ];

  void _evaluateBadges() {
    for (final b in badges) {
      final wasEarned = b.earned;
      final reachedNow = _isMilestoneReached(b.id);

      // Badges stay unlocked once earned.
      if (!wasEarned && reachedNow) {
        b.earned = true;
        _startBadgeCelebration(b.id);
      }
    }
  }

  bool _isMilestoneReached(String badgeId) {
    switch (badgeId) {
      case 'first_steps':
        return _todaySteps >= 100;
      case 'walker':
        return _todaySteps >= 5000;
      case 'daily_hero':
        return _todaySteps >= 10000;
      case 'speed_demon':
        return _todaySteps >= 15000;
      case '1km_club':
        return _todayDistanceKm >= 1;
      case '5km_run':
        return _todayDistanceKm >= 5;
      case '10km_hero':
        return _todayDistanceKm >= 10;
      case 'half_marathon':
        return _todayDistanceKm >= 21;
      case 'week_warrior':
        return _weeklySteps.length == 7 && _weeklySteps.every((s) => s >= 5000);
      default:
        return false;
    }
  }

  void _startBadgeCelebration(String badgeId) {
    _badgeUnlockedAt[badgeId] = DateTime.now();
    _badgeCelebrationTimers[badgeId]?.cancel();
    _badgeCelebrationTimers[badgeId] = Timer(
      badgeCelebrationDuration,
      () {
        _badgeUnlockedAt.remove(badgeId);
        _badgeCelebrationTimers.remove(badgeId);
        notifyListeners();
      },
    );
  }

  bool isBadgeCelebrating(String badgeId) {
    final unlockedAt = _badgeUnlockedAt[badgeId];
    if (unlockedAt == null) return false;
    final age = DateTime.now().difference(unlockedAt);
    return age < badgeCelebrationDuration;
  }

  double badgeCelebrationProgress(String badgeId) {
    final unlockedAt = _badgeUnlockedAt[badgeId];
    if (unlockedAt == null) return 0.0;
    final elapsedMs = DateTime.now().difference(unlockedAt).inMilliseconds;
    final totalMs = badgeCelebrationDuration.inMilliseconds;
    return (elapsedMs / totalMs).clamp(0.0, 1.0);
  }

  Future<void> _persistEarnedBadges() async {
    final prefs = await SharedPreferences.getInstance();
    for (final b in badges) {
      if (b.earned) await prefs.setBool('badge_${b.id}', true);
    }
  }

  Future<void> _loadPersistedBadges() async {
    final prefs = await SharedPreferences.getInstance();
    for (final b in badges) {
      if (prefs.getBool('badge_${b.id}') == true) b.earned = true;
    }
  }

  // ── Public API ────────────────────────────────────────────────────────────
  Future<void> init() async {
    if (_isTracking) return; // already streaming

    await _loadPersistedBadges();
    _loading = true;
    _permDenied = false;
    notifyListeners();

    final granted = await StepTrackingService.requestPermission();
    if (!granted) {
      _permDenied = await Permission.activityRecognition.isPermanentlyDenied;
      _loading = false;
      notifyListeners();
      return;
    }

    try {
      await StepTrackingService.start((steps) {
        _todaySteps      = steps;
        _todayDistanceKm = StepTrackingService.distanceKm;
        _todayCalsBurned = StepTrackingService.caloriesBurned;
        _weeklySteps[6]  = steps;
        _evaluateBadges();
        _persistEarnedBadges();
        notifyListeners();
      });

      _isTracking      = true;
      _todaySteps      = StepTrackingService.todaySteps;
      _todayDistanceKm = StepTrackingService.distanceKm;
      _todayCalsBurned = StepTrackingService.caloriesBurned;
      _weeklySteps     = await StepTrackingService.getWeeklySteps();
      _evaluateBadges();
    } catch (_) {
      _isTracking = false;
    }

    _loading = false;
    notifyListeners();
  }

  /// Manual refresh — re-reads weekly history from SharedPreferences.
  Future<void> refresh() async {
    if (!_isTracking) { await init(); return; }
    _weeklySteps = await StepTrackingService.getWeeklySteps();
    _evaluateBadges();
    notifyListeners();
    await StepTrackingService.syncToBackend();
  }

  @override
  void dispose() {
    for (final t in _badgeCelebrationTimers.values) {
      t.cancel();
    }
    _badgeCelebrationTimers.clear();
    StepTrackingService.stop();
    super.dispose();
  }
}
