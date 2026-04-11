// ─────────────────────────────────────────────────────────────────────────────
// agora_service_full.dart  — FULL implementation with agora_rtc_engine SDK.
//
// HOW TO ACTIVATE:
//   1. In pubspec.yaml: uncomment  agora_rtc_engine: ^6.5.3
//   2. Run: flutter pub get
//   3. Replace lib/services/agora_service.dart with this file's content
//      (or just rename: agora_service.dart → _stub.dart, this → agora_service.dart)
//   4. Make sure backend .env has AGORA_APP_ID and AGORA_APP_CERT filled in.
// ─────────────────────────────────────────────────────────────────────────────

import 'package:agora_rtc_engine/agora_rtc_engine.dart';

typedef NetworkQualityCallback = void Function(int quality);

class AgoraService {
  static RtcEngine? _engine;
  static NetworkQualityCallback? onNetworkQuality;

  static Future<RtcEngine> _init(String appId) async {
    if (_engine != null) return _engine!;
    _engine = createAgoraRtcEngine();
    await _engine!.initialize(RtcEngineContext(
      appId:          appId,
      channelProfile: ChannelProfileType.channelProfileLiveBroadcasting,
    ));
    await _engine!.enableVideo();
    _engine!.registerEventHandler(RtcEngineEventHandler(
      onNetworkQuality: (_, __, txQuality, ___) {
        onNetworkQuality?.call(txQuality.index);
      },
    ));
    return _engine!;
  }

  static Future<void> joinAsBroadcaster(
    String channelName, String? token, String appId) async {
    if (appId.isEmpty) return;
    final engine = await _init(appId);
    await engine.setClientRole(role: ClientRoleType.clientRoleBroadcaster);
    await engine.startPreview();
    await engine.joinChannel(
      token:     token ?? '',
      channelId: channelName,
      uid:       1,
      options:   ChannelMediaOptions(
        clientRoleType:         ClientRoleType.clientRoleBroadcaster,
        channelProfile:         ChannelProfileType.channelProfileLiveBroadcasting,
        publishCameraTrack:     true,
        publishMicrophoneTrack: true,
        autoSubscribeAudio:     false,
        autoSubscribeVideo:     false,
      ),
    );
  }

  static Future<void> joinAsAudience(
    String channelName, String? token, String appId, int uid) async {
    if (appId.isEmpty) return;
    final engine = await _init(appId);
    await engine.setClientRole(role: ClientRoleType.clientRoleAudience);
    await engine.joinChannel(
      token:     token ?? '',
      channelId: channelName,
      uid:       uid,
      options:   ChannelMediaOptions(
        clientRoleType:         ClientRoleType.clientRoleAudience,
        channelProfile:         ChannelProfileType.channelProfileLiveBroadcasting,
        publishCameraTrack:     false,
        publishMicrophoneTrack: false,
        autoSubscribeAudio:     true,
        autoSubscribeVideo:     true,
      ),
    );
  }

  static Future<void> leaveChannel() async {
    if (_engine == null) return;
    await _engine!.leaveChannel();
    await _engine!.release();
    _engine          = null;
    onNetworkQuality = null;
  }

  static Future<void> muteLocalAudio(bool mute) async {
    await _engine?.muteLocalAudioStream(mute);
  }

  static Future<void> muteLocalVideo(bool mute) async {
    await _engine?.muteLocalVideoStream(mute);
  }

  static Future<void> switchCamera() async {
    await _engine?.switchCamera();
  }

  // Drop into TrainerBroadcastScreen to show trainer's own camera.
  // Must only be called after joinAsBroadcaster completes.
  static VideoViewController? localView() {
    if (_engine == null) return null;
    return VideoViewController(
      rtcEngine: _engine!,
      canvas:    const VideoCanvas(uid: 0),
    );
  }

  // Drop into ViewerSessionScreen to show the trainer's stream.
  // Must only be called after joinAsAudience completes.
  static VideoViewController? remoteView(String channelId) {
    if (_engine == null) return null;
    return VideoViewController.remote(
      rtcEngine:  _engine!,
      canvas:     const VideoCanvas(uid: 1),
      connection: RtcConnection(channelId: channelId),
    );
  }
}
