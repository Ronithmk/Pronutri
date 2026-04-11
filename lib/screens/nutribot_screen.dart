import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../services/claude_service.dart';
import '../services/nutrition_provider.dart';
import '../services/auth_provider.dart';
import '../services/credit_service.dart';
import '../screens/paywall_screen.dart';
import '../theme/app_theme.dart';

class NutriBotScreen extends StatefulWidget {
  const NutriBotScreen({super.key});
  @override
  State<NutriBotScreen> createState() => _NutriBotScreenState();
}

class _NutriBotScreenState extends State<NutriBotScreen> {
  final _ctrl = TextEditingController();
  final _scroll = ScrollController();
  final List<_Msg> _msgs = [];
  final List<Map<String, String>> _history = [];
  bool _loading = false;

  final _chips = const [
    '🍽 Dinner ideas?',
    '💪 Protein goals?',
    '⚡ Pre-workout foods?',
    '🔥 Burn more fat?',
    '🥗 Healthy snack?',
    '💧 Water intake?'
  ];

  @override
  void initState() {
    super.initState();
    final p = Provider.of<NutritionProvider>(context, listen: false);
    _msgs.add(_Msg(
        text:
            'Hey! 👋 I\'m NutriBot, your AI nutrition coach powered by Claude.\n\nYou\'ve had ${p.todayCalories.toInt()} kcal today with ${p.todayProtein.toInt()}g protein. How can I help? 🌟',
        isBot: true));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _scroll.dispose();
    super.dispose();
  }

  String _ctx(NutritionProvider p, AuthProvider auth) {
    final u = auth.currentUser;
    return '''You are NutriBot, an expert nutrition AI in the ProNutri app. Be warm, concise (under 130 words), use emojis naturally.
USER: ${u?.name ?? 'User'}, ${u?.age ?? 25}y, ${u?.weight ?? 70}kg, goal: ${u?.goal ?? 'maintain'}
TODAY: ${p.todayCalories.toInt()}/${p.calorieGoal.toInt()} kcal, ${p.todayProtein.toInt()}/${p.proteinGoal.toInt()}g protein, ${p.todayCarbs.toInt()}/${p.carbsGoal.toInt()}g carbs, ${p.todayFat.toInt()}/${p.fatGoal.toInt()}g fat, ${(p.todayWaterMl / 1000).toStringAsFixed(1)}/${(p.waterGoal / 1000).toStringAsFixed(1)}L water, streak: ${p.currentStreak} days''';
  }

  Future<void> _send(String text) async {
    if (text.trim().isEmpty || _loading) return;

    final auth = Provider.of<AuthProvider>(context, listen: false);

    final user = auth.currentUser;
    if (user != null && !user.hasAccess) {
      final result = await Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const PaywallScreen(reason: 'trial_expired')),
      );
      if (result != true) return;
    }

    final allowed = await CreditService.deductForAI();
    if (!mounted) return;
    if (!allowed) {
      final result = await Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const PaywallScreen(reason: 'no_credits')),
      );
      if (!mounted) return;
      if (result != true) return;
    }

    _ctrl.clear();
    setState(() {
      _msgs.add(_Msg(text: text, isBot: false));
      _loading = true;
    });

    _scrollDown();

    final p = Provider.of<NutritionProvider>(context, listen: false);

    final rawReply = await ClaudeService.chat(
      userMessage: text,
      history: List.from(_history),
      systemContext: _ctx(p, auth),
    );
    final reply = _stripMarkdown(rawReply);

    auth.refreshCredits();

    _history.addAll([
      {'role': 'user', 'content': text},
      {'role': 'assistant', 'content': reply}
    ]);

    if (_history.length > 20) _history.removeRange(0, 2);

    setState(() {
      _msgs.add(_Msg(text: reply, isBot: true));
      _loading = false;
    });

    _scrollDown();
  }

  String _stripMarkdown(String text) => text
      .replaceAll(RegExp(r'\*\*(.+?)\*\*'), r'$1')
      .replaceAll(RegExp(r'\*(.+?)\*'), r'$1')
      .replaceAll(RegExp(r'__(.+?)__'), r'$1')
      .replaceAll(RegExp(r'_(.+?)_'), r'$1')
      .replaceAll(RegExp(r'#{1,6}\s*'), '')
      .replaceAll(RegExp(r'^\s*[-*]\s+', multiLine: true), '• ')
      .trim();

  void _scrollDown() => Future.delayed(const Duration(milliseconds: 100), () {
        if (_scroll.hasClients) {
          _scroll.animateTo(
            _scroll.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.bgDark : AppColors.bg,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: isDark ? AppColors.surfDark : AppColors.surface,
        elevation: 0,
        title: Row(children: [
          Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [BoxShadow(color: AppColors.purple.withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 4))],
            ),
            child: ClipOval(child: Image.asset('assets/images/nutribot.png', width: 38, height: 38, fit: BoxFit.cover)),
          ),
          const SizedBox(width: 12),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Text('NutriBot', style: GoogleFonts.inter(
                  fontSize: 15, fontWeight: FontWeight.w800,
                  color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary)),
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [AppColors.purple, Color(0xFFBD93F9)]),
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [BoxShadow(color: AppColors.purple.withOpacity(0.3), blurRadius: 6, offset: const Offset(0, 2))],
                ),
                child: Text('AI', style: GoogleFonts.inter(fontSize: 9, color: Colors.white, fontWeight: FontWeight.w800)),
              ),
            ]),
            Text('● Powered by Claude', style: GoogleFonts.inter(fontSize: 10, color: AppColors.primary, fontWeight: FontWeight.w500)),
          ]),
        ]),
        actions: [
          GestureDetector(
            onTap: () => setState(() {
              _msgs.clear();
              _history.clear();
              _msgs.add(_Msg(text: 'Chat cleared! How can I help? 🌱', isBot: true));
            }),
            child: Container(
              margin: const EdgeInsets.only(right: 14),
              width: 36, height: 36,
              decoration: Clay.icon(color: AppColors.accent, radius: 12, isDark: isDark),
              child: const Icon(Icons.delete_outline, color: AppColors.accent, size: 18),
            ),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: (isDark ? AppColors.borderDark : AppColors.border).withOpacity(0.5)),
        ),
      ),
      body: Column(children: [
        // Quick chips
        Container(
          color: isDark ? AppColors.surfDark : AppColors.surface,
          height: 54,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
            children: _chips.map((c) => GestureDetector(
              onTap: () => _send(c.substring(2).trim()),
              child: Container(
                margin: const EdgeInsets.only(right: 8),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.surfVarDark : AppColors.blueBg,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.primary.withOpacity(0.25)),
                  boxShadow: [BoxShadow(color: AppColors.brandBlue.withOpacity(0.10), blurRadius: 8, offset: const Offset(0, 3))],
                ),
                child: Text(c, style: GoogleFonts.inter(fontSize: 11, color: AppColors.primary, fontWeight: FontWeight.w600)),
              ),
            )).toList(),
          ),
        ),
        Container(height: 1, color: (isDark ? AppColors.borderDark : AppColors.border).withOpacity(0.4)),

        // Messages
        Expanded(
          child: ListView.builder(
            controller: _scroll,
            padding: const EdgeInsets.all(16),
            itemCount: _msgs.length + (_loading ? 1 : 0),
            itemBuilder: (_, i) {
              if (i == _msgs.length && _loading) return _buildTyping(isDark);
              return _buildBubble(_msgs[i], isDark);
            },
          ),
        ),

        // Input box
        Container(
          padding: const EdgeInsets.fromLTRB(14, 10, 14, 14),
          decoration: BoxDecoration(
            color: isDark ? AppColors.surfDark : AppColors.surface,
            boxShadow: [
              BoxShadow(
                color: isDark ? Colors.black.withOpacity(0.3) : AppColors.brandBlue.withOpacity(0.08),
                blurRadius: 20,
                offset: const Offset(0, -6),
              ),
            ],
          ),
          child: SafeArea(
            child: Row(children: [
              Expanded(
                child: Container(
                  decoration: Clay.card(isDark: isDark, radius: 22),
                  child: TextField(
                    controller: _ctrl,
                    maxLines: 3,
                    minLines: 1,
                    textInputAction: TextInputAction.send,
                    onSubmitted: _send,
                    style: GoogleFonts.inter(fontSize: 14, color: isDark ? AppColors.textPriDark : AppColors.textPri),
                    decoration: InputDecoration(
                      hintText: 'Ask NutriBot anything…',
                      hintStyle: GoogleFonts.inter(fontSize: 14, color: AppColors.textHint),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              GestureDetector(
                onTap: () => _send(_ctrl.text),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 48, height: 48,
                  decoration: BoxDecoration(
                    gradient: _loading
                      ? null
                      : const LinearGradient(colors: [AppColors.brandBlue, AppColors.brandGreen], begin: Alignment.topLeft, end: Alignment.bottomRight),
                    color: _loading ? AppColors.textHint : null,
                    shape: BoxShape.circle,
                    boxShadow: _loading ? [] : [
                      BoxShadow(color: AppColors.brandBlue.withOpacity(0.40), blurRadius: 14, offset: const Offset(0, 6)),
                    ],
                  ),
                  child: const Icon(Icons.send_rounded, color: Colors.white, size: 20),
                ),
              ),
            ]),
          ),
        ),
      ]),
    );
  }

  Widget _buildBubble(_Msg msg, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        mainAxisAlignment: msg.isBot ? MainAxisAlignment.start : MainAxisAlignment.end,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (msg.isBot) ...[
            Container(
              width: 30, height: 30,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(colors: [AppColors.purple, Color(0xFFBD93F9)]),
                boxShadow: [BoxShadow(color: AppColors.purple.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 3))],
              ),
              child: ClipOval(child: Image.asset('assets/images/nutribot.png', fit: BoxFit.cover)),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: msg.isBot
                    ? (isDark ? AppColors.surfDark : AppColors.surface)
                    : null,
                gradient: msg.isBot ? null : const LinearGradient(
                  colors: [AppColors.brandBlue, Color(0xFF2590E8)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(20),
                  topRight: const Radius.circular(20),
                  bottomLeft: Radius.circular(msg.isBot ? 4 : 20),
                  bottomRight: Radius.circular(msg.isBot ? 20 : 4),
                ),
                boxShadow: [
                  BoxShadow(
                    color: msg.isBot
                        ? (isDark ? Colors.black.withOpacity(0.25) : AppColors.brandBlue.withOpacity(0.07))
                        : AppColors.brandBlue.withOpacity(0.30),
                    blurRadius: 14,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Text(
                msg.text,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: msg.isBot
                      ? (isDark ? AppColors.textPrimaryDark : AppColors.textPrimary)
                      : Colors.white,
                  height: 1.5,
                ),
              ),
            ),
          ),
          if (!msg.isBot) const SizedBox(width: 4),
        ],
      ),
    );
  }

  Widget _buildTyping(bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
        Container(
          width: 30, height: 30,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(colors: [AppColors.purple, Color(0xFFBD93F9)]),
          ),
          child: ClipOval(child: Image.asset('assets/images/nutribot.png', fit: BoxFit.cover)),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          decoration: BoxDecoration(
            color: isDark ? AppColors.surfDark : AppColors.surface,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
              bottomRight: Radius.circular(20),
              bottomLeft: Radius.circular(4),
            ),
            boxShadow: [BoxShadow(color: AppColors.brandBlue.withOpacity(0.07), blurRadius: 14, offset: const Offset(0, 5))],
          ),
          child: _TypingDots(),
        ),
      ]),
    );
  }
}

class _TypingDots extends StatefulWidget {
  @override
  State<_TypingDots> createState() => _TypingDotsState();
}

class _TypingDotsState extends State<_TypingDots> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 900))..repeat();
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, __) {
        return Row(mainAxisSize: MainAxisSize.min, children: List.generate(3, (i) {
          final t = ((_ctrl.value - i * 0.2) % 1.0).clamp(0.0, 1.0);
          final scale = 0.6 + 0.4 * (t < 0.5 ? t * 2 : (1 - t) * 2);
          return Container(
            margin: const EdgeInsets.symmetric(horizontal: 3),
            width: 7 * scale, height: 7 * scale,
            decoration: BoxDecoration(
              color: AppColors.brandBlue.withOpacity(0.5 + 0.5 * scale),
              shape: BoxShape.circle,
            ),
          );
        }));
      },
    );
  }
}

class _Msg {
  final String text;
  final bool isBot;
  _Msg({required this.text, required this.isBot});
}
