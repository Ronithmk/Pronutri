import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/material.dart';
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

  static Future<void> init() async {
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    final settings = await _fcm.requestPermission(
      alert: true, badge: true, sound: true,
    );
    if (settings.authorizationStatus == AuthorizationStatus.denied) return;

    const channel = AndroidNotificationChannel(
      _channelId, _channelName,
      description: _channelDesc,
      importance: Importance.high,
      playSound: true,
    );

    final androidPlugin = _local.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    await androidPlugin?.createNotificationChannel(channel);

    await _local.initialize(
      const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        iOS: DarwinInitializationSettings(),
      ),
      onDidReceiveNotificationResponse: (details) {
        // Tapped while app is open (foreground)
        _handleTap({});
      },
    );

    _fcm.onTokenRefresh.listen((token) => saveTokenToBackend(token));
    await saveTokenToBackend(null);
    FirebaseMessaging.onMessage.listen(_showLocal);

    // Tapped while app in background
    FirebaseMessaging.onMessageOpenedApp.listen((msg) {
      _handleTap(msg.data);
    });

    // App was fully closed — opened via notification tap
    final initial = await _fcm.getInitialMessage();
    if (initial != null) {
      _handleTap(initial.data);
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
    _local.show(
      msg.hashCode, n.title, n.body,
      const NotificationDetails(
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
      ),
    );
  }

  static void _handleTap(Map<String, dynamic> data) {
    // Opens app and navigates to home
    navigatorKey.currentState?.pushNamedAndRemoveUntil('/', (r) => false);
  }
}
