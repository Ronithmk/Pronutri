import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/material.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'api_service.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {}

// Global navigator key — allows navigation from anywhere
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

class NotificationService {
  static final _local = FlutterLocalNotificationsPlugin();
  static final _fcm   = FirebaseMessaging.instance;

  static const _channelId   = 'pronutri_reminders';
  static const _channelName = 'ProNutri Reminders';
  static const _channelDesc = 'Health & nutrition reminders';

  static const _notifDetails = NotificationDetails(
    android: AndroidNotificationDetails(
      _channelId, _channelName,
      channelDescription: _channelDesc,
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
      color: Color(0xFF1E6EBD),
      playSound: true,
    ),
    iOS: DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    ),
  );

  static Future<void> init() async {
    // Timezone init — must come before any zonedSchedule calls
    tz_data.initializeTimeZones();
    _setLocalTimezone();

    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    final settings = await _fcm.requestPermission(
      alert: true, badge: true, sound: true,
    );
    if (settings.authorizationStatus == AuthorizationStatus.denied) return;

    final androidPlugin = _local.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    await androidPlugin?.createNotificationChannel(const AndroidNotificationChannel(
      _channelId, _channelName,
      description: _channelDesc,
      importance: Importance.high,
      playSound: true,
    ));

    await _local.initialize(
      const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        iOS: DarwinInitializationSettings(),
      ),
      onDidReceiveNotificationResponse: (_) => _handleTap({}),
    );

    _fcm.onTokenRefresh.listen((token) => saveTokenToBackend(token));
    await saveTokenToBackend(null);
    FirebaseMessaging.onMessage.listen(_showLocal);
    FirebaseMessaging.onMessageOpenedApp.listen((msg) => _handleTap(msg.data));

    final initial = await _fcm.getInitialMessage();
    if (initial != null) _handleTap(initial.data);
  }

  // ── Schedule daily smart reminders ─────────────────────────────────────────
  static Future<void> scheduleDailyReminders() async {
    await cancelAllScheduled();

    // Meal reminders
    await _scheduleDailyAt(id: 10, hour: 8,  minute: 0,  title: 'Good morning! 🍳', body: 'Start your day right — log your breakfast');
    await _scheduleDailyAt(id: 11, hour: 12, minute: 30, title: 'Lunch time! 🥗',   body: 'Don\'t forget to log your lunch');
    await _scheduleDailyAt(id: 12, hour: 19, minute: 0,  title: 'Dinner reminder 🌙', body: 'Log your dinner and review today\'s nutrition');

    // Water reminders
    await _scheduleDailyAt(id: 20, hour: 10, minute: 0,  title: 'Hydration check 💧', body: 'Have you had water today? Stay hydrated!');
    await _scheduleDailyAt(id: 21, hour: 14, minute: 0,  title: 'Drink water 💧',     body: 'You\'re halfway through the day — keep drinking water');
    await _scheduleDailyAt(id: 22, hour: 17, minute: 0,  title: 'Water reminder 💧',  body: 'Almost evening — top up your water intake');

    // Workout reminder
    await _scheduleDailyAt(id: 30, hour: 18, minute: 30, title: 'Workout time! 💪',   body: 'Have you exercised today? A short workout goes a long way');

    // Habit check reminder
    await _scheduleDailyAt(id: 40, hour: 21, minute: 0,  title: 'Daily habits check 🏆', body: 'Check your habit progress before bed — how many did you complete?');
  }

  static Future<void> _scheduleDailyAt({
    required int id,
    required int hour,
    required int minute,
    required String title,
    required String body,
  }) async {
    try {
      await _local.zonedSchedule(
        id, title, body,
        _nextInstanceOfTime(hour, minute),
        _notifDetails,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.time,
      );
    } catch (e) {
      debugPrint('Notification schedule failed (id=$id): $e');
    }
  }

  static tz.TZDateTime _nextInstanceOfTime(int hour, int minute) {
    final now = tz.TZDateTime.now(tz.local);
    var scheduled = tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);
    if (scheduled.isBefore(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }
    return scheduled;
  }

  static void _setLocalTimezone() {
    try {
      final offset = DateTime.now().timeZoneOffset;
      final hours  = offset.inHours;
      final mins   = offset.inMinutes.remainder(60);
      // IANA Etc/GMT uses inverted sign convention
      if (mins == 0) {
        final name = hours == 0 ? 'UTC' : 'Etc/GMT${hours > 0 ? '-' : '+'}${hours.abs()}';
        tz.setLocalLocation(tz.getLocation(name));
      } else {
        // Half-hour offset (e.g. India UTC+5:30) — find nearest whole-hour
        final name = 'Etc/GMT${hours > 0 ? '-' : '+'}${hours.abs()}';
        tz.setLocalLocation(tz.getLocation(name));
      }
    } catch (_) {
      tz.setLocalLocation(tz.UTC);
    }
  }

  // ── Show a one-off local notification (e.g. live session alert) ────────────
  static Future<void> showImmediate({
    required int id,
    required String title,
    required String body,
  }) async {
    await _local.show(id, title, body, _notifDetails);
  }

  static Future<void> cancelAllScheduled() async {
    for (final id in [10, 11, 12, 20, 21, 22, 30, 40]) {
      await _local.cancel(id);
    }
  }

  static Future<void> saveTokenToBackend(String? token) async {
    try {
      token ??= await _fcm.getToken();
      if (token == null) return;
      await ApiService.post('/notifications/register-token', {'token': token});
    } catch (e) {
      debugPrint('FCM token save failed: $e');
    }
  }

  static void _showLocal(RemoteMessage msg) {
    final n = msg.notification;
    if (n == null) return;
    _local.show(msg.hashCode, n.title, n.body, _notifDetails);
  }

  static void _handleTap(Map<String, dynamic> data) {
    navigatorKey.currentState?.pushNamedAndRemoveUntil('/', (r) => false);
  }
}
