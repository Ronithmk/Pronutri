import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../models/live_session.dart';
import '../services/live_session_provider.dart';
import '../theme/app_theme.dart';

// ─────────────────────────────────────────────────────────────────────────────
// LiveChatWidget
//
// Shared between TrainerBroadcastScreen (side panel) and
// ViewerSessionScreen (bottom sheet / side panel).
// ─────────────────────────────────────────────────────────────────────────────
class LiveChatWidget extends StatefulWidget {
  final String sessionId;
  final String userId;
  final String userName;
  final bool   isTrainer;
  final List<RaisedHand> raisedHands;
  final void Function(String uid)? onDismissHand;

  const LiveChatWidget({
    super.key,
    required this.sessionId,
    required this.userId,
    required this.userName,
    this.isTrainer    = false,
    this.raisedHands  = const [],
    this.onDismissHand,
  });

  @override
  State<LiveChatWidget> createState() => _LiveChatWidgetState();
}

class _LiveChatWidgetState extends State<LiveChatWidget> {
  final _controller  = TextEditingController();
  final _scrollCtrl  = ScrollController();
  final _focusNode   = FocusNode();
  bool _isSending    = false;

  @override
  void dispose() {
    _controller.dispose();
    _scrollCtrl.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _send() async {
    final text = _controller.text.trim();
    if (text.isEmpty || _isSending) return;

    setState(() => _isSending = true);
    _controller.clear();

    await context.read<LiveSessionProvider>().sendMessage(
      sessionId: widget.sessionId,
      userId:    widget.userId,
      userName:  widget.userName,
      text:      text,
      isTrainer: widget.isTrainer,
    );

    setState(() => _isSending = false);
    _scrollToBottom();
  }

  @override
  Widget build(BuildContext context) {
    final messages = context.watch<LiveSessionProvider>().messages;
    _scrollToBottom();

    return Container(
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.75),
        border: const Border(left: BorderSide(color: Colors.white12)),
      ),
      child: Column(children: [
        // ── Header ──────────────────────────────────────────────────────
        _ChatHeader(
          messageCount: messages.length,
          raisedHands:  widget.raisedHands,
          isTrainer:    widget.isTrainer,
          onDismissHand: widget.onDismissHand,
        ),

        // ── Raised Hands Banner (trainer only) ───────────────────────
        if (widget.isTrainer && widget.raisedHands.isNotEmpty)
          _RaisedHandBanner(
            hands:         widget.raisedHands,
            onDismissHand: widget.onDismissHand,
          ),

        // ── Messages ─────────────────────────────────────────────────
        Expanded(
          child: messages.isEmpty
              ? _EmptyChat()
              : ListView.builder(
                  controller: _scrollCtrl,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  itemCount: messages.length,
                  itemBuilder: (ctx, i) {
                    final msg = messages[i];
                    final isMe = msg.userId == widget.userId;
                    return _ChatBubble(message: msg, isMe: isMe);
                  },
                ),
        ),

        // ── Input ─────────────────────────────────────────────────────
        _ChatInput(
          controller:  _controller,
          focusNode:   _focusNode,
          isSending:   _isSending,
          onSend:      _send,
          isTrainer:   widget.isTrainer,
        ),
      ]),
    );
  }
}

// ── Header ────────────────────────────────────────────────────────────────────
class _ChatHeader extends StatelessWidget {
  final int messageCount;
  final List<RaisedHand> raisedHands;
  final bool isTrainer;
  final void Function(String)? onDismissHand;

  const _ChatHeader({
    required this.messageCount,
    required this.raisedHands,
    required this.isTrainer,
    this.onDismissHand,
  });

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
    decoration: const BoxDecoration(
      border: Border(bottom: BorderSide(color: Colors.white12)),
    ),
    child: Row(children: [
      const Icon(Icons.chat_bubble_outline, color: Colors.white70, size: 14),
      const SizedBox(width: 6),
      Text('Live Chat', style: GoogleFonts.inter(
        color: Colors.white, fontSize: 13, fontWeight: FontWeight.w700,
      )),
      const SizedBox(width: 6),
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: Colors.white12,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text('$messageCount', style: GoogleFonts.inter(
          color: Colors.white70, fontSize: 10, fontWeight: FontWeight.w600,
        )),
      ),
      if (isTrainer && raisedHands.isNotEmpty) ...[
        const Spacer(),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: AppColors.amber.withOpacity(0.25),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.amber.withOpacity(0.5)),
          ),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            const Text('✋', style: TextStyle(fontSize: 10)),
            const SizedBox(width: 4),
            Text('${raisedHands.length}', style: GoogleFonts.inter(
              color: AppColors.amber, fontSize: 11, fontWeight: FontWeight.w700,
            )),
          ]),
        ),
      ],
    ]),
  );
}

// ── Raised Hand Banner ────────────────────────────────────────────────────────
class _RaisedHandBanner extends StatelessWidget {
  final List<RaisedHand> hands;
  final void Function(String)? onDismissHand;

  const _RaisedHandBanner({required this.hands, this.onDismissHand});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
    color: AppColors.amber.withOpacity(0.12),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: hands.map((h) => Row(children: [
        const Text('✋', style: TextStyle(fontSize: 12)),
        const SizedBox(width: 6),
        Expanded(child: Text(h.userName, style: GoogleFonts.inter(
          color: AppColors.amber, fontSize: 11, fontWeight: FontWeight.w600,
        ))),
        GestureDetector(
          onTap: () => onDismissHand?.call(h.userId),
          child: const Icon(Icons.close, color: Colors.white54, size: 14),
        ),
      ])).toList(),
    ),
  );
}

// ── Chat Bubble ───────────────────────────────────────────────────────────────
class _ChatBubble extends StatelessWidget {
  final ChatMessage message;
  final bool        isMe;
  const _ChatBubble({required this.message, required this.isMe});

  @override
  Widget build(BuildContext context) {
    if (message.type == MessageType.system) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Center(child: Text(message.text, style: GoogleFonts.inter(
          color: Colors.white38, fontSize: 11, fontStyle: FontStyle.italic,
        ))),
      );
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Avatar
          Container(
            width: 24, height: 24,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: message.isTrainer
                  ? AppColors.brandBlue.withOpacity(0.8)
                  : Colors.white.withOpacity(0.15),
            ),
            child: Center(child: Text(
              message.userName.isNotEmpty ? message.userName[0].toUpperCase() : '?',
              style: GoogleFonts.inter(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w700),
            )),
          ),
          const SizedBox(width: 8),

          // Content
          Expanded(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                Text(
                  message.isTrainer ? '${message.userName} (Trainer)' : message.userName,
                  style: GoogleFonts.inter(
                    fontSize: 10, fontWeight: FontWeight.w700,
                    color: message.isTrainer ? AppColors.brandGreen : Colors.white70,
                  ),
                ),
                if (message.isTrainer) ...[
                  const SizedBox(width: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                    decoration: BoxDecoration(
                      color: AppColors.brandBlue.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text('HOST', style: GoogleFonts.inter(
                      color: AppColors.brandBlue, fontSize: 8, fontWeight: FontWeight.w800, letterSpacing: 0.5,
                    )),
                  ),
                ],
              ]),
              const SizedBox(height: 2),
              Text(message.text, style: GoogleFonts.inter(
                color: Colors.white, fontSize: 13,
              )),
            ],
          )),

          // Timestamp
          Text(_formatTime(message.timestamp), style: GoogleFonts.inter(
            color: Colors.white30, fontSize: 9,
          )),
        ],
      ),
    );
  }

  String _formatTime(DateTime dt) {
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }
}

// ── Empty Chat ────────────────────────────────────────────────────────────────
class _EmptyChat extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Center(child: Column(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      const Icon(Icons.chat_bubble_outline, color: Colors.white24, size: 36),
      const SizedBox(height: 8),
      Text('Be the first to say hi!', style: GoogleFonts.inter(
        color: Colors.white30, fontSize: 12,
      )),
    ],
  ));
}

// ── Chat Input ────────────────────────────────────────────────────────────────
class _ChatInput extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode             focusNode;
  final bool                  isSending;
  final bool                  isTrainer;
  final VoidCallback          onSend;

  const _ChatInput({
    required this.controller,
    required this.focusNode,
    required this.isSending,
    required this.isTrainer,
    required this.onSend,
  });

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
    decoration: const BoxDecoration(
      border: Border(top: BorderSide(color: Colors.white12)),
    ),
    child: Row(children: [
      Expanded(
        child: TextField(
          controller:  controller,
          focusNode:   focusNode,
          style: GoogleFonts.inter(color: Colors.white, fontSize: 13),
          maxLength:   200,
          maxLines:    2,
          minLines:    1,
          textInputAction: TextInputAction.send,
          onSubmitted:  (_) => onSend(),
          decoration: InputDecoration(
            hintText:    isTrainer ? 'Say something to your audience...' : 'Say something...',
            hintStyle:   GoogleFonts.inter(color: Colors.white30, fontSize: 13),
            filled:      true,
            fillColor:   Colors.white.withOpacity(0.08),
            counterText: '',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          ),
        ),
      ),
      const SizedBox(width: 8),
      GestureDetector(
        onTap: isSending ? null : onSend,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: 40, height: 40,
          decoration: BoxDecoration(
            color: isSending
                ? Colors.white12
                : (isTrainer ? AppColors.brandGreen : AppColors.brandBlue),
            shape: BoxShape.circle,
          ),
          child: isSending
              ? const Padding(
                  padding: EdgeInsets.all(10),
                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                )
              : const Icon(Icons.send_rounded, color: Colors.white, size: 18),
        ),
      ),
    ]),
  );
}
