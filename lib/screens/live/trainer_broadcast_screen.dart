import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../models/live_session.dart';
import '../../services/auth_provider.dart';
import '../../services/agora_service.dart';
import '../../services/live_session_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/live_chat_widget.dart';

// ─────────────────────────────────────────────────────────────────────────────
// TrainerBroadcastScreen
//
// Full-screen live broadcast UI for the trainer (host).
// Video area is a placeholder; swap with Agora's AgoraVideoView for production.
// ─────────────────────────────────────────────────────────────────────────────
class TrainerBroadcastScreen extends StatefulWidget {
  const TrainerBroadcastScreen({super.key});

  @override
  State<TrainerBroadcastScreen> createState() => _TrainerBroadcastScreenState();
}

class _TrainerBroadcastScreenState extends State<TrainerBroadcastScreen>
    with TickerProviderStateMixin {
  bool _showControls = true;
  bool _showChat     = true;
  Timer? _hideControlsTimer;

  late AnimationController _pulseCtrl;
  late Animation<double>   _pulseAnim;

  @override
  void initState() {
    super.initState();

    // Force landscape for broadcast
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
      DeviceOrientation.portraitUp,
    ]);

    // Live pulse animation for recording dot
    _pulseCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 900))
      ..repeat(reverse: true);
    _pulseAnim = Tween(begin: 0.5, end: 1.0).animate(_pulseCtrl);

    _resetHideTimer();
  }

  @override
  void dispose() {
    _hideControlsTimer?.cancel();
    _pulseCtrl.dispose();
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    super.dispose();
  }

  void _resetHideTimer() {
    _hideControlsTimer?.cancel();
    _hideControlsTimer = Timer(const Duration(seconds: 5), () {
      if (mounted) setState(() => _showControls = false);
    });
  }

  void _onTap() {
    setState(() => _showControls = !_showControls);
    if (_showControls) _resetHideTimer();
  }

  // ── End session confirmation ───────────────────────────────────────────────
  Future<void> _confirmEnd(BuildContext context) async {
    final provider  = context.read<LiveSessionProvider>();
    final navigator = Navigator.of(context);

    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('End Session?', style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
        content: Text('All viewers will be disconnected. The session will end for everyone.',
            style: GoogleFonts.inter(fontSize: 14)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.accent),
            child: Text('End Session', style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
    if (confirm == true && mounted) {
      await provider.endSession();
      if (mounted) navigator.popUntil((r) => r.isFirst);
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<LiveSessionProvider>();
    final session  = provider.activeSession;
    final user     = context.watch<AuthProvider>().currentUser;

    if (session == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        onTap: _onTap,
        child: Stack(children: [
          // ── Video Area (Agora AgoraVideoView goes here) ────────────────
          _MockCameraView(isVideoOff: provider.isVideoOff),

          // ── Chat Panel (right side) ────────────────────────────────────
          if (_showChat)
            Positioned(
              right: 0, top: 60, bottom: 80,
              width: 280,
              child: LiveChatWidget(
                sessionId:  session.id,
                userId:     user?.id ?? '',
                userName:   user?.name ?? '',
                isTrainer:  true,
                raisedHands: provider.raisedHands,
                onDismissHand: (uid) => provider.dismissRaisedHand(uid),
              ),
            ),

          // ── Top Bar ────────────────────────────────────────────────────
          _TopBar(
            session:      session,
            showControls: _showControls,
            pulseAnim:    _pulseAnim,
            showChat:     _showChat,
            onToggleChat: () => setState(() => _showChat = !_showChat),
            onEnd:        () => _confirmEnd(context),
          ),

          // ── Bottom Controls ────────────────────────────────────────────
          AnimatedPositioned(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            bottom: _showControls ? 0 : -100,
            left: 0, right: _showChat ? 280 : 0,
            child: _BottomControls(
              isAudioMuted: provider.isAudioMuted,
              isVideoOff:   provider.isVideoOff,
              onToggleAudio: provider.toggleAudio,
              onToggleVideo: provider.toggleVideo,
              onFlipCamera:  _flipCamera,
            ),
          ),

          // ── Floating Reactions ─────────────────────────────────────────
          _FloatingReactionsOverlay(reactions: provider.reactions),

          // ── Network Quality ────────────────────────────────────────────
          Positioned(
            top: 60, left: 12,
            child: _NetworkQualityBadge(quality: provider.networkQuality),
          ),
        ]),
      ),
    );
  }

  void _flipCamera() {
    AgoraService.switchCamera();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Camera flipped'), duration: Duration(milliseconds: 800)),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _MockCameraView
// Replace this widget with AgoraVideoView in production.
// ─────────────────────────────────────────────────────────────────────────────
class _MockCameraView extends StatelessWidget {
  final bool isVideoOff;
  const _MockCameraView({required this.isVideoOff});

  @override
  Widget build(BuildContext context) {
    if (isVideoOff) {
      return Container(
        color: const Color(0xFF0A0F1A),
        child: Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          const Icon(Icons.videocam_off, color: Colors.white54, size: 64),
          const SizedBox(height: 12),
          Text('Camera Off', style: GoogleFonts.inter(color: Colors.white54, fontSize: 16)),
        ])),
      );
    }

    // TODO(agora): Replace with:
    //   AgoraVideoView(controller: VideoViewController(
    //     rtcEngine:   _engine,
    //     canvas:      const VideoCanvas(uid: 0), // 0 = local
    //   ))
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF0A2342), Color(0xFF1E6EBD), Color(0xFF0A2342)],
          begin: Alignment.topLeft, end: Alignment.bottomRight,
        ),
      ),
      child: Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Container(
          width: 120, height: 120,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white.withOpacity(0.1),
            border: Border.all(color: Colors.white24, width: 2),
          ),
          child: const Icon(Icons.videocam, color: Colors.white38, size: 48),
        ),
        const SizedBox(height: 16),
        Text('Camera Preview', style: GoogleFonts.inter(color: Colors.white38, fontSize: 14)),
        const SizedBox(height: 4),
        Text('(Agora RTC — plug in AgoraVideoView)', style: GoogleFonts.inter(color: Colors.white24, fontSize: 11)),
      ])),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _TopBar
// ─────────────────────────────────────────────────────────────────────────────
class _TopBar extends StatefulWidget {
  final LiveSession session;
  final bool showControls;
  final Animation<double> pulseAnim;
  final bool showChat;
  final VoidCallback onToggleChat;
  final VoidCallback onEnd;

  const _TopBar({
    required this.session,
    required this.showControls,
    required this.pulseAnim,
    required this.showChat,
    required this.onToggleChat,
    required this.onEnd,
  });

  @override
  State<_TopBar> createState() => _TopBarState();
}

class _TopBarState extends State<_TopBar> {
  Timer? _timer;
  Duration _elapsed = Duration.zero;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() {
        _elapsed = widget.session.startedAt != null
            ? DateTime.now().difference(widget.session.startedAt!)
            : _elapsed + const Duration(seconds: 1);
      });
    });
  }

  @override
  void dispose() { _timer?.cancel(); super.dispose(); }

  String get _durationStr {
    final h = _elapsed.inHours;
    final m = _elapsed.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = _elapsed.inSeconds.remainder(60).toString().padLeft(2, '0');
    return h > 0 ? '$h:$m:$s' : '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      opacity: widget.showControls ? 1.0 : 0.0,
      duration: const Duration(milliseconds: 300),
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 48, 16, 16),
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.black87, Colors.transparent],
            begin: Alignment.topCenter, end: Alignment.bottomCenter,
          ),
        ),
        child: Row(children: [
          // Live badge + timer
          AnimatedBuilder(
            animation: widget.pulseAnim,
            builder: (_, __) => Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: Color.lerp(const Color(0xFFCC0000), const Color(0xFFFF4040), widget.pulseAnim.value),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Container(width: 7, height: 7, decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle)),
                const SizedBox(width: 5),
                Text('LIVE  $_durationStr', style: GoogleFonts.inter(
                  color: Colors.white, fontSize: 12, fontWeight: FontWeight.w800, letterSpacing: 0.5,
                )),
              ]),
            ),
          ),
          const SizedBox(width: 12),

          // Viewer count
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: Colors.black54,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              const Icon(Icons.remove_red_eye_outlined, color: Colors.white70, size: 14),
              const SizedBox(width: 5),
              Text('${widget.session.viewerCount}', style: GoogleFonts.inter(
                color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700,
              )),
            ]),
          ),

          const Spacer(),

          // Toggle chat panel
          GestureDetector(
            onTap: widget.onToggleChat,
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: widget.showChat ? AppColors.brandBlue.withOpacity(0.8) : Colors.black54,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(widget.showChat ? Icons.chat_bubble : Icons.chat_bubble_outline,
                  color: Colors.white, size: 18),
            ),
          ),
          const SizedBox(width: 10),

          // End session
          GestureDetector(
            onTap: widget.onEnd,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.accent,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text('End', style: GoogleFonts.inter(
                color: Colors.white, fontWeight: FontWeight.w800, fontSize: 13,
              )),
            ),
          ),
        ]),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _BottomControls
// ─────────────────────────────────────────────────────────────────────────────
class _BottomControls extends StatelessWidget {
  final bool isAudioMuted;
  final bool isVideoOff;
  final VoidCallback onToggleAudio;
  final VoidCallback onToggleVideo;
  final VoidCallback onFlipCamera;

  const _BottomControls({
    required this.isAudioMuted,
    required this.isVideoOff,
    required this.onToggleAudio,
    required this.onToggleVideo,
    required this.onFlipCamera,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.transparent, Colors.black87],
          begin: Alignment.topCenter, end: Alignment.bottomCenter,
        ),
      ),
      child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
        _ControlBtn(
          icon:    isAudioMuted ? Icons.mic_off : Icons.mic,
          label:   isAudioMuted ? 'Unmute' : 'Mute',
          active:  isAudioMuted,
          activeColor: AppColors.accent,
          onTap:   onToggleAudio,
        ),
        const SizedBox(width: 24),
        _ControlBtn(
          icon:    isVideoOff ? Icons.videocam_off : Icons.videocam,
          label:   isVideoOff ? 'Start Video' : 'Stop Video',
          active:  isVideoOff,
          activeColor: AppColors.accent,
          onTap:   onToggleVideo,
        ),
        const SizedBox(width: 24),
        _ControlBtn(
          icon:    Icons.flip_camera_ios,
          label:   'Flip',
          onTap:   onFlipCamera,
        ),
        const SizedBox(width: 24),
        _ControlBtn(
          icon:    Icons.screen_share_outlined,
          label:   'Share',
          onTap:   () {
            // TODO(agora): AgoraService.startScreenShare();
          },
        ),
      ]),
    );
  }
}

class _ControlBtn extends StatelessWidget {
  final IconData icon;
  final String   label;
  final bool     active;
  final Color    activeColor;
  final VoidCallback onTap;

  const _ControlBtn({
    required this.icon,
    required this.label,
    this.active = false,
    this.activeColor = Colors.white,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Column(mainAxisSize: MainAxisSize.min, children: [
      Container(
        width: 52, height: 52,
        decoration: BoxDecoration(
          color: active ? activeColor : Colors.white.withOpacity(0.15),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: Colors.white, size: 22),
      ),
      const SizedBox(height: 6),
      Text(label, style: GoogleFonts.inter(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.w500)),
    ]),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// _FloatingReactionsOverlay
// ─────────────────────────────────────────────────────────────────────────────
class _FloatingReactionsOverlay extends StatelessWidget {
  final List<FloatingReaction> reactions;
  const _FloatingReactionsOverlay({required this.reactions});

  @override
  Widget build(BuildContext context) => IgnorePointer(
    child: Stack(
      children: reactions.map((r) => _FloatingEmoji(reaction: r)).toList(),
    ),
  );
}

class _FloatingEmoji extends StatefulWidget {
  final FloatingReaction reaction;
  const _FloatingEmoji({required this.reaction});
  @override
  State<_FloatingEmoji> createState() => _FloatingEmojiState();
}

class _FloatingEmojiState extends State<_FloatingEmoji>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _y;
  late Animation<double> _opacity;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(seconds: 3))..forward();
    _y = Tween(begin: 0.0, end: -200.0).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
    _opacity = TweenSequence([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 1.0), weight: 15),
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.0), weight: 60),
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.0), weight: 25),
    ]).animate(_ctrl);
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final screenW = MediaQuery.of(context).size.width;
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, __) => Positioned(
        left:   widget.reaction.startX * screenW,
        bottom: 100 + _y.value,
        child: Opacity(
          opacity: _opacity.value,
          child: Text(widget.reaction.emoji, style: const TextStyle(fontSize: 32)),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _NetworkQualityBadge
// ─────────────────────────────────────────────────────────────────────────────
class _NetworkQualityBadge extends StatelessWidget {
  final NetworkQuality quality;
  const _NetworkQualityBadge({required this.quality});

  (Color, String, IconData) get _info {
    switch (quality) {
      case NetworkQuality.excellent: return (AppColors.brandGreen, 'Excellent', Icons.signal_wifi_4_bar);
      case NetworkQuality.good:      return (AppColors.brandGreen, 'Good',      Icons.network_wifi_3_bar);
      case NetworkQuality.fair:      return (AppColors.amber,      'Fair',      Icons.network_wifi_2_bar);
      case NetworkQuality.poor:      return (AppColors.accent,     'Poor',      Icons.network_wifi_1_bar);
      case NetworkQuality.veryBad:   return (AppColors.accent,     'Very Bad',  Icons.signal_wifi_bad);
      case NetworkQuality.down:      return (AppColors.accent,     'No Signal', Icons.signal_wifi_off);
      default:                       return (Colors.white54,       'Checking',  Icons.network_check);
    }
  }

  @override
  Widget build(BuildContext context) {
    final (color, label, icon) = _info;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.black54,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, color: color, size: 13),
        const SizedBox(width: 4),
        Text(label, style: GoogleFonts.inter(color: color, fontSize: 10, fontWeight: FontWeight.w600)),
      ]),
    );
  }
}
