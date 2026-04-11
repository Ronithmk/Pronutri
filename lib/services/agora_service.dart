// ─────────────────────────────────────────────────────────────────────────────
// AgoraService — no-op stub until agora_rtc_engine is added to pubspec.
//
// To activate real video:
//   1. Get App ID + Certificate from console.agora.io
//   2. Set AGORA_APP_ID + AGORA_APP_CERT in pronutri-backend/.env
//   3. Uncomment agora_rtc_engine: ^6.5.3 in pubspec.yaml, run flutter pub get
//   4. Replace this file with the full implementation in agora_service_full.dart
//
// Until then every call is a no-op — the app builds lean (~25 MB) and the
// live session UI works via Firestore chat + mock video placeholders.
// ─────────────────────────────────────────────────────────────────────────────

typedef NetworkQualityCallback = void Function(int quality);

class AgoraService {
  static NetworkQualityCallback? onNetworkQuality;

  static Future<void> joinAsBroadcaster(
    String channelName, String? token, String appId) async {}

  static Future<void> joinAsAudience(
    String channelName, String? token, String appId, int uid) async {}

  static Future<void> leaveChannel()            async {}
  static Future<void> muteLocalAudio(bool mute) async {}
  static Future<void> muteLocalVideo(bool mute) async {}
  static Future<void> switchCamera()            async {}
}
