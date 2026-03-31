import 'dart:math';
import 'package:mailer/mailer.dart';
import 'package:mailer/smtp_server.dart';

class OtpService {
  // ─── CONFIGURE YOUR EMAIL HERE ───────────────────────────────────────────
  // Use a Gmail account with App Password (NOT your regular password)
  // Steps to get App Password:
  // 1. Go to myaccount.google.com
  // 2. Security → 2-Step Verification → App passwords
  // 3. Generate password for "Mail" on "Windows Computer"
  // 4. Copy the 16-character password here
  static const String _senderEmail = 'your.app.email@gmail.com';
  static const String _appPassword = 'your_16_char_app_password';
  static const String _senderName = 'ProNutri';
  // ─────────────────────────────────────────────────────────────────────────

  static final Map<String, _OtpEntry> _otpStore = {};

  /// Generate a 6-digit OTP
  static String _generateOtp() {
    final rand = Random.secure();
    return List.generate(6, (_) => rand.nextInt(10)).join();
  }

  /// Send OTP to email, returns error string or null on success
  static Future<String?> sendOtp(String email) async {
    final otp = _generateOtp();
    _otpStore[email.toLowerCase()] = _OtpEntry(
      otp: otp,
      expiresAt: DateTime.now().add(const Duration(minutes: 10)),
    );

    try {
      final smtpServer = gmail(_senderEmail, _appPassword);
      final message = Message()
        ..from = Address(_senderEmail, _senderName)
        ..recipients.add(email)
        ..subject = 'ProNutri - Your Verification Code'
        ..html = _buildEmailHtml(otp);

      await send(message, smtpServer);
      return null; // success
    } catch (e) {
      // If email fails (no config), return the OTP for testing
      if (_senderEmail == 'your.app.email@gmail.com') {
        return 'EMAIL_NOT_CONFIGURED:$otp';
      }
      return 'Failed to send email. Check your connection.';
    }
  }

  /// Verify OTP — returns true if valid
  static bool verifyOtp(String email, String otp) {
    final entry = _otpStore[email.toLowerCase()];
    if (entry == null) return false;
    if (DateTime.now().isAfter(entry.expiresAt)) {
      _otpStore.remove(email.toLowerCase());
      return false;
    }
    if (entry.otp == otp.trim()) {
      _otpStore.remove(email.toLowerCase());
      return true;
    }
    return false;
  }

  static String _buildEmailHtml(String otp) => '''
<!DOCTYPE html>
<html>
<head><meta charset="UTF-8"></head>
<body style="margin:0;padding:0;background:#f8f9fa;font-family:'Segoe UI',Arial,sans-serif;">
  <table width="100%" cellpadding="0" cellspacing="0" style="background:#f8f9fa;padding:40px 0;">
    <tr><td align="center">
      <table width="480" cellpadding="0" cellspacing="0" style="background:#ffffff;border-radius:20px;overflow:hidden;box-shadow:0 4px 24px rgba(0,0,0,0.08);">
        <!-- Header -->
        <tr><td style="background:linear-gradient(135deg,#00C896,#00A07A);padding:40px;text-align:center;">
          <div style="font-size:48px;margin-bottom:12px;">🥗</div>
          <h1 style="color:#ffffff;font-size:28px;font-weight:800;margin:0;letter-spacing:-0.5px;">ProNutri</h1>
          <p style="color:rgba(255,255,255,0.8);margin:8px 0 0;font-size:14px;">Your Personal Nutrition Coach</p>
        </td></tr>
        <!-- Body -->
        <tr><td style="padding:40px;">
          <h2 style="color:#0D1117;font-size:22px;font-weight:700;margin:0 0 8px;">Verify your email 👋</h2>
          <p style="color:#6B7280;font-size:15px;line-height:1.6;margin:0 0 32px;">Enter this 6-digit code in the ProNutri app to complete your registration. The code expires in <strong>10 minutes</strong>.</p>
          <!-- OTP Box -->
          <div style="background:#F2F4F7;border-radius:16px;padding:28px;text-align:center;margin-bottom:32px;">
            <p style="color:#6B7280;font-size:12px;font-weight:600;text-transform:uppercase;letter-spacing:1px;margin:0 0 12px;">Verification Code</p>
            <div style="font-size:48px;font-weight:800;letter-spacing:12px;color:#00C896;font-family:monospace;">$otp</div>
          </div>
          <p style="color:#B0B8C4;font-size:13px;margin:0;">If you didn't request this, you can safely ignore this email.</p>
        </td></tr>
        <!-- Footer -->
        <tr><td style="background:#F8F9FA;padding:20px;text-align:center;border-top:1px solid #E8ECF0;">
          <p style="color:#B0B8C4;font-size:12px;margin:0;">© 2024 ProNutri. All rights reserved.</p>
        </td></tr>
      </table>
    </td></tr>
  </table>
</body>
</html>
  ''';
}

class _OtpEntry {
  final String otp;
  final DateTime expiresAt;
  _OtpEntry({required this.otp, required this.expiresAt});
}
