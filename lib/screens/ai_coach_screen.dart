import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../services/claude_service.dart';
import '../services/nutrition_provider.dart';
import '../services/auth_provider.dart';
import '../services/habit_provider.dart';
import '../services/credit_service.dart';
import '../screens/paywall_screen.dart';
import '../theme/app_theme.dart';

class AiCoachScreen extends StatefulWidget {
  const AiCoachScreen({super.key});
  @override
  State<AiCoachScreen> createState() => _AiCoachScreenState();
}

class _AiCoachScreenState extends State<AiCoachScreen> {
  final _ctrl = TextEditingController();
  final _scroll = ScrollController();
  final List<_Msg> _msgs = [];
  final List<Map<String, String>> _history = [];
  bool _loading = false;

  final _chips = const [
    '🏋️ Today\'s workout?',
    '🥗 Meal prep tips?',
    '💪 Protein target?',
    '🔥 Burn more fat?',
    '😴 Recovery advice?',
    '📈 Progress insight?',
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _sendGreeting());
  }

  void _sendGreeting() {
    final p = Provider.of<NutritionProvider>(context, listen: false);
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final habits = Provider.of<HabitProvider>(context, listen: false);
    final name = auth.currentUser?.name.split(' ').first ?? 'there';
    final streak = habits.currentStreak;
    final cals = p.todayCalories.toInt();
    final goal = p.calorieGoal.toInt();
    final diff = goal - cals;

    var msg = 'Hey $name! 👋 I\'m your AI Coach.\n\n';
    if (streak > 0) msg += '🔥 $streak-day streak — keep it up!\n';
    msg += '📊 $cals kcal logged today';
    msg += diff > 0 ? ' · $diff kcal remaining.\n' : ' · Goal hit! 🎯\n';
    msg += '\nWhat can I help you with?';

    setState(() => _msgs.add(_Msg(text: msg, isBot: true)));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _scroll.dispose();
    super.dispose();
  }

  String _ctx(NutritionProvider p, AuthProvider auth, HabitProvider habits) {
    final u = auth.currentUser;
    return '''You are ProCoach, a personal AI fitness and nutrition coach in the ProNutri app.
User: ${u?.name ?? 'User'}, ${u?.age ?? 25}y, ${u?.weight ?? 70}kg, goal: ${u?.goal ?? 'maintain'}
Today: ${p.todayCalories.toInt()}/${p.calorieGoal.toInt()} kcal, ${p.todayProtein.toInt()}g protein, ${p.todayWater} glasses water
Streak: ${habits.currentStreak} days | Level: ${habits.levelName}
Be concise (under 130 words), motivating and actionable. Use emojis naturally.''';
  }

  Future<void> _send(String text) async {
    if (text.trim().isEmpty || _loading) return;

    final auth = Provider.of<AuthProvider>(context, listen: false);
    final user = auth.currentUser;

    if (user != null && !user.hasAccess) {
      final result = await Navigator.push(context,
          MaterialPageRoute(builder: (_) => const PaywallScreen(reason: 'trial_expired')));
      if (result != true) return;
    }

    final allowed = await CreditService.deductForAI();
    if (!mounted) return;
    if (!allowed) {
      final result = await Navigator.push(context,
          MaterialPageRoute(builder: (_) => const PaywallScreen(reason: 'no_credits')));
      if (!mounted || result != true) return;
    }

    _ctrl.clear();
    setState(() {
      _msgs.add(_Msg(text: text, isBot: false));
      _loading = true;
    });
    _scrollBottom();

    final p = Provider.of<NutritionProvider>(context, listen: false);
    final habits = Provider.of<HabitProvider>(context, listen: false);

    final rawReply = await ClaudeService.chat(
      userMessage: text,
      history: List.from(_history),
      systemContext: _ctx(p, auth, habits),
    );
    final reply = _strip(rawReply);

    auth.refreshCredits();
    _history.addAll([
      {'role': 'user', 'content': text},
      {'role': 'assistant', 'content': reply},
    ]);
    if (_history.length > 20) _history.removeRange(0, 2);

    if (mounted) {
      setState(() {
        _msgs.add(_Msg(text: reply, isBot: true));
        _loading = false;
      });
      _scrollBottom();
    }
  }

  String _strip(String t) => t
      .replaceAll(RegExp(r'\*\*(.+?)\*\*'), r'$1')
      .replaceAll(RegExp(r'\*(.+?)\*'), r'$1')
      .replaceAll(RegExp(r'#{1,6}\s*'), '')
      .replaceAll(RegExp(r'^\s*[-*]\s+', multiLine: true), '• ')
      .trim();

  void _scrollBottom() => Future.delayed(const Duration(milliseconds: 100), () {
    if (_scroll.hasClients) {
      _scroll.animateTo(_scroll.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
    }
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.bgDark : AppColors.bg,
      appBar: AppBar(
        backgroundColor: isDark ? AppColors.surfDark : AppColors.surface,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        title: Row(children: [
          Container(
            width: 32, height: 32,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.brandBlue, AppColors.brandGreen],
                begin: Alignment.topLeft, end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.fitness_center_rounded, color: Colors.white, size: 18),
          ),
          const SizedBox(width: 10),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('AI Coach',
                style: GoogleFonts.inter(fontWeight: FontWeight.w800, fontSize: 16,
                    color: isDark ? AppColors.textPriDark : AppColors.textPri)),
            Text('Powered by Claude',
                style: GoogleFonts.inter(fontSize: 10,
                    color: isDark ? AppColors.textSecDark : AppColors.textSec)),
          ]),
        ]),
      ),
      body: Column(children: [
        Expanded(
          child: ListView.builder(
            controller: _scroll,
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            itemCount: _msgs.length + (_loading ? 1 : 0),
            itemBuilder: (context, i) {
              if (i == _msgs.length) return _TypingIndicator(isDark: isDark);
              return _BubbleWidget(msg: _msgs[i], isDark: isDark);
            },
          ),
        ),
        _QuickChips(chips: _chips, onTap: _send, isDark: isDark),
        _InputBar(ctrl: _ctrl, onSend: () => _send(_ctrl.text), isDark: isDark),
      ]),
    );
  }
}

class _BubbleWidget extends StatelessWidget {
  final _Msg msg;
  final bool isDark;
  const _BubbleWidget({required this.msg, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final isBot = msg.isBot;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: isBot ? MainAxisAlignment.start : MainAxisAlignment.end,
        children: [
          if (isBot) ...[
            Container(
              width: 28, height: 28,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.brandBlue, AppColors.brandGreen],
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.fitness_center_rounded, color: Colors.white, size: 14),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: isBot
                    ? (isDark ? AppColors.surfDark : AppColors.surface)
                    : AppColors.brandBlue,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(18),
                  topRight: const Radius.circular(18),
                  bottomLeft: Radius.circular(isBot ? 4 : 18),
                  bottomRight: Radius.circular(isBot ? 18 : 4),
                ),
                border: isBot
                    ? Border.all(color: isDark ? AppColors.borderDark : AppColors.border)
                    : null,
                boxShadow: [
                  BoxShadow(
                    color: (isBot ? Colors.black : AppColors.brandBlue).withOpacity(0.06),
                    blurRadius: 8, offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Text(
                msg.text,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: isBot
                      ? (isDark ? AppColors.textPriDark : AppColors.textPri)
                      : Colors.white,
                  height: 1.4,
                ),
              ),
            ),
          ),
          if (!isBot) const SizedBox(width: 8),
        ],
      ),
    );
  }
}

class _TypingIndicator extends StatefulWidget {
  final bool isDark;
  const _TypingIndicator({required this.isDark});
  @override
  State<_TypingIndicator> createState() => _TypingIndicatorState();
}

class _TypingIndicatorState extends State<_TypingIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 600))
      ..repeat(reverse: true);
    _anim = Tween(begin: 0.4, end: 1.0).animate(_ctrl);
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(children: [
        Container(
          width: 28, height: 28,
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [AppColors.brandBlue, AppColors.brandGreen]),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(Icons.fitness_center_rounded, color: Colors.white, size: 14),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: widget.isDark ? AppColors.surfDark : AppColors.surface,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(18), topRight: Radius.circular(18),
              bottomRight: Radius.circular(18), bottomLeft: Radius.circular(4),
            ),
            border: Border.all(color: widget.isDark ? AppColors.borderDark : AppColors.border),
          ),
          child: AnimatedBuilder(
            animation: _anim,
            builder: (_, __) => Row(mainAxisSize: MainAxisSize.min, children: [
              ...List.generate(3, (i) => Container(
                width: 6, height: 6,
                margin: EdgeInsets.only(right: i < 2 ? 4 : 0),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.brandBlue.withOpacity(i == 1 ? _anim.value : 0.4),
                ),
              )),
            ]),
          ),
        ),
      ]),
    );
  }
}

class _QuickChips extends StatelessWidget {
  final List<String> chips;
  final void Function(String) onTap;
  final bool isDark;
  const _QuickChips({required this.chips, required this.onTap, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 38,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        itemCount: chips.length,
        itemBuilder: (_, i) => GestureDetector(
          onTap: () => onTap(chips[i]),
          child: Container(
            margin: const EdgeInsets.only(right: 8),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: isDark ? AppColors.surfVarDark : AppColors.surfaceVar,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: isDark ? AppColors.borderDark : AppColors.border),
            ),
            child: Text(chips[i],
                style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w500,
                    color: isDark ? AppColors.textPriDark : AppColors.textPri)),
          ),
        ),
      ),
    );
  }
}

class _InputBar extends StatelessWidget {
  final TextEditingController ctrl;
  final VoidCallback onSend;
  final bool isDark;
  const _InputBar({required this.ctrl, required this.onSend, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfDark : AppColors.surface,
        border: Border(top: BorderSide(color: isDark ? AppColors.borderDark : AppColors.border)),
      ),
      child: SafeArea(
        top: false,
        child: Row(children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: isDark ? AppColors.bgDark : AppColors.bg,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: isDark ? AppColors.borderDark : AppColors.border),
              ),
              child: TextField(
                controller: ctrl,
                onSubmitted: (_) => onSend(),
                textInputAction: TextInputAction.send,
                style: GoogleFonts.inter(fontSize: 14,
                    color: isDark ? AppColors.textPriDark : AppColors.textPri),
                decoration: InputDecoration(
                  hintText: 'Ask your coach...',
                  hintStyle: GoogleFonts.inter(fontSize: 14,
                      color: isDark ? AppColors.textSecDark : AppColors.textHint),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: onSend,
            child: Container(
              width: 42, height: 42,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.brandBlue, AppColors.brandGreen],
                  begin: Alignment.topLeft, end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(21),
                boxShadow: [
                  BoxShadow(color: AppColors.brandBlue.withOpacity(0.35),
                      blurRadius: 10, offset: const Offset(0, 4)),
                ],
              ),
              child: const Icon(Icons.send_rounded, color: Colors.white, size: 18),
            ),
          ),
        ]),
      ),
    );
  }
}

class _Msg {
  final String text;
  final bool isBot;
  const _Msg({required this.text, required this.isBot});
}
