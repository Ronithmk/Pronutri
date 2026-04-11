import 'dart:math';
import 'api_service.dart';

class OtpService {
  // In-memory fallback store for when backend is unavailable
  static final Map<String, _OtpEntry> _localStore = {};

  /// Send OTP via backend. Returns:
  ///   null                       → email sent successfully
  ///   'EMAIL_NOT_CONFIGURED:$otp' → dev mode (show OTP on screen)
  ///   'some error'               → failure
  static Future<String?> sendOtp(String email) async {
    try {
      final res = await ApiService.post('/auth/send-otp', {'email': email});

      if (res.containsKey('error')) {
        // Backend returned a real error — try local fallback
        return _localFallback(email);
      }

      // Dev mode: backend couldn't send email, gave us the OTP
      if (res['otp'] != null) {
        // Also store locally in case verify-otp endpoint is missing too
        _localStore[email.toLowerCase()] = _OtpEntry(
          otp: res['otp'].toString(),
          expiresAt: DateTime.now().add(const Duration(minutes: 10)),
        );
        return 'EMAIL_NOT_CONFIGURED:${res['otp']}';
      }

      return null; // success — email sent to user
    } catch (_) {
      // Backend unreachable (not redeployed, network issue, etc.)
      return _localFallback(email);
    }
  }

  /// Verify OTP — tries backend first, falls back to local store.
  static Future<bool> verifyOtp(String email, String otp) async {
    final key = email.toLowerCase();

    try {
      final res = await ApiService.post('/auth/verify-otp', {
        'email': key,
        'otp': otp.trim(),
      });

      if (res['valid'] == true) return true;

      // Backend returned invalid — also check local fallback store
      return _checkLocal(key, otp);
    } catch (_) {
      // Backend unreachable — check local store
      return _checkLocal(key, otp);
    }
  }

  // ── Local fallback (when backend not redeployed) ────────────────────────
  static String _localFallback(String email) {
    final otp = _generateOtp();
    _localStore[email.toLowerCase()] = _OtpEntry(
      otp: otp,
      expiresAt: DateTime.now().add(const Duration(minutes: 10)),
    );
    return 'EMAIL_NOT_CONFIGURED:$otp';
  }

  static bool _checkLocal(String email, String otp) {
    final entry = _localStore[email];
    if (entry == null) return false;
    if (DateTime.now().isAfter(entry.expiresAt)) {
      _localStore.remove(email);
      return false;
    }
    if (entry.otp == otp.trim()) {
      _localStore.remove(email);
      return true;
    }
    return false;
  }

  static String _generateOtp() {
    final rng = Random.secure();
    return (rng.nextInt(900000) + 100000).toString();
  }
}

class _OtpEntry {
  final String otp;
  final DateTime expiresAt;
  _OtpEntry({required this.otp, required this.expiresAt});
}
