import 'package:shared_preferences/shared_preferences.dart';

class SubscriptionService {
  static Future<bool> isAccessAllowed() async {
    final prefs = await SharedPreferences.getInstance();
    final trialEnd = prefs.getString('trial_end');
    final subActive = prefs.getBool('subscription_active') ?? false;

    if (subActive) return true;
    if (trialEnd == null) return false;

    final end = DateTime.tryParse(trialEnd);
    return end != null && DateTime.now().isBefore(end);
  }

  static Future<int> trialDaysLeft() async {
    final prefs = await SharedPreferences.getInstance();
    final trialEnd = prefs.getString('trial_end');
    if (trialEnd == null) return 0;
    final end = DateTime.tryParse(trialEnd);
    if (end == null) return 0;
    return end.difference(DateTime.now()).inDays.clamp(0, 30);
  }
}