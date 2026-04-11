import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../models/live_session.dart';
import '../../services/auth_provider.dart';
import '../../services/live_session_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/live_chat_widget.dart';

// ─────────────────────────────────────────────────────────────────────────────
// ViewerSessionScreen
//
// Full-screen live viewer experience. Trainer video as main view with
// chat panel, reactions, raise hand, and network quality indicator.
// ─────────────────────────────────────────────────────────────────────────────
class ViewerSessionScreen extends StatefulWidget {
  final LiveSession session;
  const ViewerSessionScreen({super.key, required this.session});

  @override
  State<ViewerSessionScreen> createState() => _ViewerSessionScreenState();
}

class _ViewerSessionScreenState extends State<ViewerSessionScreen>
    with TickerProviderStateMixin {
  bool _showControls = true;
  bool _showChat     = true;
  Timer? _hideControlsTimer;

  // Reaction picker
  bool _showReactionPicker = false;

  static const _emojis = ['❤️', '👏', '🔥', '😮', '😂', '💪', '🙌', '⭐'];

  late AnimationController _liveTagCtrl;
  late Animation<double>   _liveTagAnim;

  @override
  void initState() {
    super.initState();
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
      DeviceOrientation.portraitUp,
    ]);
    _liveTagCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 800))
      ..repeat(reverse: true);
    _liveTagAnim = Tween(begin: 0.5, end: 1.0).animate(_liveTagCtrl);
    _resetHideTimer();
  }

  @override
  void dispose() {
    _hideControlsTimer?.cancel();
    _liveTagCtrl.dispose();
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    super.dispose();
  }

  void _resetHideTimer() {
    _hideControlsTimer?.cancel();
    _hideControlsTimer = Timer(const Duration(seconds: 4), () {
      if (mounted) setState(() { _showControls = false; _showReactionPicker = false; });
    });
  }

  void _onTap() {
    setState(() => _showControls = !_showControls);
    if (_showControls) _resetHideTimer();
  }

  Future<void> _leaveSession(BuildContext context) async {
    await context.read<LiveSessionProvider>().leaveSession();
    if (context.mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<LiveSessionProvider>();
    final user     = context.watch<AuthProvider>().currentUser;
    final session  = provider.activeSession ?? widget.session;

    // Session ended by trainer
    if (session.isEnded) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _showEndedDialog(context));
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        onTap: _onTap,
        child: Stack(children: [
          // ── Trainer Video (main view) ─────────────────────────────────
          _TrainerVideoView(trainerName: session.trainerName),

          // ── Chat Panel ───────────────────────────────────────────────
          if (_showChat)
            Positioned(
              right: 0, top: 56, bottom: 80,
              width: 260,
              child: LiveChatWidget(
                sessionId: session.id,
                userId:    user?.id ?? '',
                userName:  user?.name ?? '',
                isTrainer: false,
              ),
            ),

          // ── Top Bar ──────────────────────────────────────────────────
          AnimatedOpacity(
            opacity: _showControls ? 1.0 : 0.0,
            duration: const Duration(milliseconds: 300),
            child: _ViewerTopBar(
              session:      session,
              pulseAnim:    _liveTagAnim,
              showChat:     _showChat,
              onToggleChat: () => setState(() => _showChat = !_showChat),
              onLeave:      () => _leaveSession(context),
              quality:      provider.networkQuality,
            ),
          ),

          // ── Bottom Controls ──────────────────────────────────────────
          AnimatedPositioned(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            bottom: _showControls ? 0 : -90,
            left: 0, right: _showChat ? 260 : 0,
            child: _ViewerBottomBar(
              hasRaisedHand:        provider.hasRaisedHand,
              showReactionPicker:   _showReactionPicker,
              onRaiseHand: () {
                provider.raiseHand(user?.id ?? '', user?.name ?? 'Viewer');
                _resetHideTimer();
              },
              onToggleReactions: () {
                setState(() => _showReactionPicker = !_showReactionPicker);
                _resetHideTimer();
              },
            ),
          ),

          // ── Reaction Picker ──────────────────────────────────────────
          if (_showReactionPicker)
            Positioned(
              bottom: 90,
              left: 24,
              child: _ReactionPicker(
                emojis: _emojis,
                onSelect: (emoji) {
                  provider.sendReaction(emoji, user?.id ?? '');
                  setState(() => _showReactionPicker = false);
                  _resetHideTimer();
                },
              ),
            ),

          // ── Floating Reactions ────────────────────────────────────────
          IgnorePointer(
            child: Stack(
              children: provider.reactions
                  .map((r) => _FloatingEmojiViewer(reaction: r))
                  .toList(),
            ),
          ),
        ]),
      ),
    );
  }

  Future<void> _showEndedDialog(BuildContext context) async {
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Session Ended', style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
        content: Text('The trainer has ended this live session.',
            style: GoogleFonts.inter(fontSize: 14)),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(context).pop();
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _TrainerVideoView  (Agora AgoraVideoView placeholder)
// ─────────────────────────────────────────────────────────────────────────────
class _TrainerVideoView extends StatefulWidget {
  final String trainerName;
  const _TrainerVideoView({required this.trainerName});
  @override
  State<_TrainerVideoView> createState() => _TrainerVideoViewState();
}

class _TrainerVideoViewState extends State<_TrainerVideoView>
    with SingleTickerProviderStateMixin {
  late AnimationController _shimmerCtrl;
  late Animation<double> _shimmerAnim;

  @override
  void initState() {
    super.initState();
    _shimmerCtrl = AnimationController(vsync: this, duration: const Duration(seconds: 2))
      ..repeat(reverse: true);
    _shimmerAnim = Tween(begin: -1.0, end: 2.0).animate(
        CurvedAnimation(parent: _shimmerCtrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() { _shimmerCtrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    // TODO(agora): Replace with:
    //   AgoraVideoView(controller: VideoViewController.remote(
    //     rtcEngine:   _engine,
    //     canvas:      VideoCanvas(uid: trainerUid),
    //     connection:  RtcConnection(channelId: channelName),
    //   ))
    return AnimatedBuilder(
      animation: _shimmerAnim,
      builder: (_, __) => Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: const [
              Color(0xFF0A1628),
              Color(0xFF0F2040),
              Color(0xFF0A1628),
            ],
            stops: [
              (_shimmerAnim.value - 0.3).clamp(0.0, 1.0),
              _shimmerAnim.value.clamp(0.0, 1.0),
              (_shimmerAnim.value + 0.3).clamp(0.0, 1.0),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Container(
            width: 100, height: 100,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withOpacity(0.08),
              border: Border.all(color: Colors.white12, width: 2),
            ),
            child: Center(child: Text(
              widget.trainerName.isNotEmpty ? widget.trainerName[0] : 'T',
              style: GoogleFonts.inter(
                color: Colors.white38, fontSize: 42, fontWeight: FontWeight.w700,
              ),
            )),
          ),
          const SizedBox(height: 14),
          Text(widget.trainerName, style: GoogleFonts.inter(
            color: Colors.white38, fontSize: 15, fontWeight: FontWeight.w600,
          )),
          const SizedBox(height: 4),
          Text('Connecting to stream...', style: GoogleFonts.inter(
            color: Colors.white24, fontSize: 12,
          )),
          const SizedBox(height: 8),
          Text('(Agora RTC — plug in AgoraVideoView)', style: GoogleFonts.inter(
            color: Colors.white12, fontSize: 10,
          )),
        ])),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _ViewerTopBar
// ─────────────────────────────────────────────────────────────────────────────
class _ViewerTopBar extends StatelessWidget {
  final LiveSession       session;
  final Animation<double> pulseAnim;
  final bool              showChat;
  final VoidCallback      onToggleChat;
  final VoidCallback      onLeave;
  final NetworkQuality    quality;

  const _ViewerTopBar({
    required this.session,
    required this.pulseAnim,
    required this.showChat,
    required this.onToggleChat,
    required this.onLeave,
    required this.quality,
  });

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.fromLTRB(16, 48, 16, 16),
    decoration: const BoxDecoration(
      gradient: LinearGradient(
        colors: [Colors.black87, Colors.transparent],
        begin: Alignment.topCenter, end: Alignment.bottomCenter,
      ),
    ),
    child: Row(children: [
      // Back
      GestureDetector(
        onTap: onLeave,
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(10)),
          child: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 16),
        ),
      ),
      const SizedBox(width: 12),

      // Session title + trainer
      Expanded(child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(session.title, maxLines: 1, overflow: TextOverflow.ellipsis,
              style: GoogleFonts.inter(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w700)),
          Text(session.trainerName, style: GoogleFonts.inter(color: Colors.white60, fontSize: 11)),
        ],
      )),

      // Live badge + viewer count
      AnimatedBuilder(
        animation: pulseAnim,
        builder: (_, __) => Container(
          margin: const EdgeInsets.only(right: 8),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: Color.lerp(const Color(0xFFCC0000), const Color(0xFFFF4040), pulseAnim.value),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Container(width: 6, height: 6, decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle)),
            const SizedBox(width: 4),
            Text('LIVE', style: GoogleFonts.inter(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 0.8)),
          ]),
        ),
      ),

      // Viewer count
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(8)),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          const Icon(Icons.remove_red_eye_outlined, color: Colors.white60, size: 12),
          const SizedBox(width: 4),
          Text('${session.viewerCount}', style: GoogleFonts.inter(
            color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600,
          )),
        ]),
      ),
      const SizedBox(width: 8),

      // Network quality dot
      _NetworkDot(quality: quality),
      const SizedBox(width: 8),

      // Chat toggle
      GestureDetector(
        onTap: onToggleChat,
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: showChat ? AppColors.brandBlue.withOpacity(0.8) : Colors.black54,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(showChat ? Icons.chat_bubble : Icons.chat_bubble_outline,
              color: Colors.white, size: 16),
        ),
      ),
    ]),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// _ViewerBottomBar
// ─────────────────────────────────────────────────────────────────────────────
class _ViewerBottomBar extends StatelessWidget {
  final bool hasRaisedHand;
  final bool showReactionPicker;
  final VoidCallback onRaiseHand;
  final VoidCallback onToggleReactions;

  const _ViewerBottomBar({
    required this.hasRaisedHand,
    required this.showReactionPicker,
    required this.onRaiseHand,
    required this.onToggleReactions,
  });

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.fromLTRB(24, 12, 24, 28),
    decoration: const BoxDecoration(
      gradient: LinearGradient(
        colors: [Colors.transparent, Colors.black87],
        begin: Alignment.topCenter, end: Alignment.bottomCenter,
      ),
    ),
    child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
      // Reaction button
      _BottomBtn(
        icon:    Icons.add_reaction_outlined,
        label:   'React',
        active:  showReactionPicker,
        onTap:   onToggleReactions,
      ),
      const SizedBox(width: 32),

      // Raise hand
      _BottomBtn(
        icon:    hasRaisedHand ? Icons.back_hand : Icons.back_hand_outlined,
        label:   hasRaisedHand ? 'Hand Down' : 'Raise Hand',
        active:  hasRaisedHand,
        activeColor: AppColors.amber,
        onTap:   onRaiseHand,
      ),
      const SizedBox(width: 32),

      // Share session (deep link)
      _BottomBtn(
        icon:    Icons.share_outlined,
        label:   'Share',
        onTap:   () => _shareSession(context),
      ),
    ]),
  );

  void _shareSession(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Session link copied to clipboard!')),
    );
  }
}

class _BottomBtn extends StatelessWidget {
  final IconData icon;
  final String   label;
  final bool     active;
  final Color    activeColor;
  final VoidCallback onTap;

  const _BottomBtn({
    required this.icon,
    required this.label,
    this.active = false,
    this.activeColor = AppColors.brandBlue,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Column(mainAxisSize: MainAxisSize.min, children: [
      AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 48, height: 48,
        decoration: BoxDecoration(
          color: active ? activeColor.withOpacity(0.25) : Colors.white.withOpacity(0.12),
          shape: BoxShape.circle,
          border: Border.all(
            color: active ? activeColor : Colors.transparent,
            width: 1.5,
          ),
        ),
        child: Icon(icon, color: active ? activeColor : Colors.white70, size: 20),
      ),
      const SizedBox(height: 5),
      Text(label, style: GoogleFonts.inter(color: Colors.white54, fontSize: 10, fontWeight: FontWeight.w500)),
    ]),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// _ReactionPicker
// ─────────────────────────────────────────────────────────────────────────────
class _ReactionPicker extends StatelessWidget {
  final List<String> emojis;
  final void Function(String) onSelect;

  const _ReactionPicker({required this.emojis, required this.onSelect});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
    decoration: BoxDecoration(
      color: Colors.black.withOpacity(0.85),
      borderRadius: BorderRadius.circular(32),
      border: Border.all(color: Colors.white12),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: emojis.map((e) => GestureDetector(
        onTap: () => onSelect(e),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6),
          child: Text(e, style: const TextStyle(fontSize: 24)),
        ),
      )).toList(),
    ),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// _FloatingEmojiViewer  (viewer-side reactions)
// ─────────────────────────────────────────────────────────────────────────────
class _FloatingEmojiViewer extends StatefulWidget {
  final FloatingReaction reaction;
  const _FloatingEmojiViewer({required this.reaction});
  @override
  State<_FloatingEmojiViewer> createState() => _FloatingEmojiViewerState();
}

class _FloatingEmojiViewerState extends State<_FloatingEmojiViewer>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _y;
  late Animation<double> _opacity;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(seconds: 3))..forward();
    _y = Tween(begin: 0.0, end: -180.0).animate(
        CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
    _opacity = TweenSequence([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 1.0), weight: 10),
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.0), weight: 65),
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
        left:   widget.reaction.startX * (screenW - (260)), // avoid chat panel
        bottom: 90 + _y.value,
        child: Opacity(
          opacity: _opacity.value.clamp(0.0, 1.0),
          child: Text(widget.reaction.emoji, style: const TextStyle(fontSize: 30)),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _NetworkDot
// ─────────────────────────────────────────────────────────────────────────────
class _NetworkDot extends StatelessWidget {
  final NetworkQuality quality;
  const _NetworkDot({required this.quality});

  Color get _color {
    switch (quality) {
      case NetworkQuality.excellent:
      case NetworkQuality.good:      return AppColors.brandGreen;
      case NetworkQuality.fair:      return AppColors.amber;
      case NetworkQuality.poor:
      case NetworkQuality.veryBad:
      case NetworkQuality.down:      return AppColors.accent;
      default:                       return Colors.white38;
    }
  }

  @override
  Widget build(BuildContext context) => Tooltip(
    message: quality.name,
    child: Container(
      width: 8, height: 8,
      decoration: BoxDecoration(
        color: _color,
        shape: BoxShape.circle,
        boxShadow: [BoxShadow(color: _color.withOpacity(0.5), blurRadius: 4)],
      ),
    ),
  );
}
