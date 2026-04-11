import 'dart:async';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:pedometer/pedometer.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'api_service.dart';

/// Tracks steps with robust fallback:
/// 1) Primary: hardware STEP_COUNTER (pedometer plugin)
/// 2) Fallback on Android: native STEP_DETECTOR stream (1 event per step)
class StepTrackingService {
  static const EventChannel _stepDetectorRawChannel =
      EventChannel('pronutri/step_detector_raw');

  static StreamSubscription<StepCount>? _stepSub;
  static StreamSubscription<PedestrianStatus>? _statusSub;
  static StreamSubscription<dynamic>? _detectorSub;
  static Timer? _counterAvailabilityTimer;

  static int _todaySteps = 0;
  static String _status = 'stopped'; // walking | stopped | unsupported

  static bool _usingStepCounter = false;
  static bool _usingStepDetectorFallback = false;

  static int get todaySteps => _todaySteps;
  static String get status => _status;
  static double get distanceKm => _todaySteps * 0.000762;
  static double get caloriesBurned => _todaySteps * 0.04;

  static Future<bool> requestPermission() async {
    if (Platform.isAndroid || Platform.isIOS) {
      final st = await Permission.activityRecognition.request();
      return st.isGranted;
    }
    return true;
  }

  static Future<bool> get hasPermission async {
    if (Platform.isAndroid || Platform.isIOS) {
      return Permission.activityRecognition.isGranted;
    }
    return true;
  }

  /// Call once. [onUpdate] fires whenever visible step count changes.
  static Future<void> start(void Function(int steps) onUpdate) async {
    _counterAvailabilityTimer?.cancel();
    await _detectorSub?.cancel();
    _detectorSub = null;

    final prefs = await SharedPreferences.getInstance();
    final today = _dateKey(DateTime.now());
    _todaySteps = prefs.getInt('steps_$today') ?? 0;
    onUpdate(_todaySteps);

    _usingStepCounter = false;
    _usingStepDetectorFallback = false;

    await _startPedestrianStatus();
    await _startStepCounter(onUpdate);
  }

  static Future<void> _startPedestrianStatus() async {
    _statusSub?.cancel();
    _statusSub = Pedometer.pedestrianStatusStream.listen(
      (event) => _status = event.status,
      onError: (_) {
        // Keep previous status; counting can still work.
      },
      cancelOnError: false,
    );
  }

  static Future<void> _startStepCounter(void Function(int steps) onUpdate) async {
    _stepSub?.cancel();
    _counterAvailabilityTimer?.cancel();

    _stepSub = Pedometer.stepCountStream.listen(
      (event) async {
        final prefs = await SharedPreferences.getInstance();
        final today = _dateKey(DateTime.now());

        // If fallback was active and STEP_COUNTER becomes available later,
        // align baseline so counts continue smoothly.
        if (!_usingStepCounter) {
          if (_usingStepDetectorFallback) {
            await prefs.setString('step_date', today);
            await prefs.setInt('step_baseline', event.steps - _todaySteps);
            await _stopStepDetectorFallback();
          }
          _usingStepCounter = true;
          _counterAvailabilityTimer?.cancel();
        }

        await _onRawStep(event.steps, onUpdate);
      },
      onError: (_) async {
        await _activateFallback(onUpdate);
      },
      cancelOnError: false,
    );

    // Some devices never emit STEP_COUNTER events even with permission.
    // If no event arrives shortly after start, switch to fallback.
    _counterAvailabilityTimer = Timer(const Duration(seconds: 8), () async {
      if (!_usingStepCounter) {
        await _activateFallback(onUpdate);
      }
    });
  }

  static Future<void> _activateFallback(void Function(int steps) onUpdate) async {
    if (!Platform.isAndroid || _usingStepDetectorFallback) {
      return;
    }

    _usingStepDetectorFallback = true;

    _detectorSub?.cancel();
    _detectorSub = _stepDetectorRawChannel.receiveBroadcastStream().listen(
      (dynamic event) async {
        final delta = event is int ? event : int.tryParse('$event') ?? 0;
        if (delta <= 0) return;
        await _onDetectedStep(delta, onUpdate);
      },
      onError: (_) {
        _status = 'unsupported';
      },
      cancelOnError: false,
    );
  }

  static Future<void> _stopStepDetectorFallback() async {
    _usingStepDetectorFallback = false;
    await _detectorSub?.cancel();
    _detectorSub = null;
  }

  static void stop() {
    _counterAvailabilityTimer?.cancel();
    _stepSub?.cancel();
    _statusSub?.cancel();
    _detectorSub?.cancel();
    _usingStepCounter = false;
    _usingStepDetectorFallback = false;
  }

  static Future<void> _onRawStep(
    int rawSteps,
    void Function(int steps) onUpdate,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    final today = _dateKey(DateTime.now());
    final lastDate = prefs.getString('step_date') ?? '';
    final baseline = prefs.getInt('step_baseline') ?? rawSteps;

    if (lastDate != today) {
      if (lastDate.isNotEmpty) {
        await prefs.setInt('steps_$lastDate', _todaySteps);
      }
      await prefs.setString('step_date', today);
      await prefs.setInt('step_baseline', rawSteps);
      _todaySteps = 0;
    } else {
      _todaySteps = rawSteps - baseline;
      if (_todaySteps < 0) {
        await prefs.setInt('step_baseline', rawSteps);
        _todaySteps = 0;
      }
    }

    await prefs.setInt('steps_$today', _todaySteps);
    onUpdate(_todaySteps);
  }

  static Future<void> _onDetectedStep(
    int delta,
    void Function(int steps) onUpdate,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    final today = _dateKey(DateTime.now());
    final lastDate = prefs.getString('step_date') ?? '';

    if (lastDate != today) {
      if (lastDate.isNotEmpty) {
        await prefs.setInt('steps_$lastDate', _todaySteps);
      }
      await prefs.setString('step_date', today);
      _todaySteps = 0;
    }

    _todaySteps += delta;
    await prefs.setInt('steps_$today', _todaySteps);
    onUpdate(_todaySteps);
  }

  /// Returns step counts for the last 7 days, index 0 = 6 days ago, 6 = today.
  static Future<List<int>> getWeeklySteps() async {
    final prefs = await SharedPreferences.getInstance();
    final now = DateTime.now();
    return List.generate(7, (i) {
      if (i == 6) return _todaySteps;
      final date = _dateKey(now.subtract(Duration(days: 6 - i)));
      return prefs.getInt('steps_$date') ?? 0;
    });
  }

  static Future<void> syncToBackend() async {
    try {
      await ApiService.post('/activity/sync', {
        'steps': _todaySteps,
        'distance_km': distanceKm,
        'calories_burned': caloriesBurned,
        'date': _dateKey(DateTime.now()),
      });
    } catch (_) {}
  }

  static String _dateKey(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
}
