import 'package:shared_preferences/shared_preferences.dart';
import 'api_service.dart';

class CreditService {
  /// Deducts 2 credits for an AI message.
  /// Returns true  → allowed (deducted OR network error — fail open)
  /// Returns false → explicitly INSUFFICIENT_CREDITS from backend
  static Future<bool> deductForAI() async {
    // Check local cache first — fast gate before hitting network
    final prefs   = await SharedPreferences.getInstance();
    final local   = prefs.getInt('user_credits') ?? 999;
    if (local <= 0) return false; // locally known to be empty

    try {
      final res = await ApiService.post('/credits/deduct', {});

      // Explicit insufficient credits from backend
      if (res['error'] == 'INSUFFICIENT_CREDITS') {
        await prefs.setInt('user_credits', 0);
        return false;
      }

      // Success — update local cache
      if (res.containsKey('remaining')) {
        final remaining = (res['remaining'] as num).toInt();
        await prefs.setInt('user_credits', remaining);
      }

      // Any other error (401, 500, network, etc.) → fail open
      // Don't punish the user for server issues
      return true;
    } catch (_) {
      return true; // network error → fail open
    }
  }

  static Future<int> getBalance() async {
    try {
      final res = await ApiService.get('/credits/balance');
      return (res['credits'] as num?)?.toInt() ?? 0;
    } catch (_) {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getInt('user_credits') ?? 0;
    }
  }

  static Future<List<dynamic>> getHistory() async {
    try {
      final res = await ApiService.get('/credits/history');
      if (res['history'] is List) return res['history'];
      if (res['data'] is List) return res['data'] as List;
      return [];
    } catch (_) {
      return [];
    }
  }
}
