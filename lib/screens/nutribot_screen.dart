import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../services/claude_service.dart';
import '../services/nutrition_provider.dart';
import '../services/auth_provider.dart';
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

  final _chips = const ['🍽 Dinner ideas?', '💪 Protein goals?', '⚡ Pre-workout foods?', '🔥 Burn more fat?', '🥗 Healthy snack?', '💧 Water intake?'];

  @override
  void initState() {
    super.initState();
    final p = Provider.of<NutritionProvider>(context, listen: false);
    _msgs.add(_Msg(text: 'Hey! 👋 I\'m NutriBot, your AI nutrition coach powered by Claude.\n\nYou\'ve had **${p.todayCalories.toInt()} kcal** today with **${p.todayProtein.toInt()}g protein**. How can I help? 🌟', isBot: true));
  }

  @override
  void dispose() { _ctrl.dispose(); _scroll.dispose(); super.dispose(); }

  String _ctx(NutritionProvider p, AuthProvider auth) {
    final u = auth.currentUser;
    return '''You are NutriBot, an expert nutrition AI in the ProNutri app. Be warm, concise (under 130 words), use emojis naturally.
USER: ${u?.name ?? 'User'}, ${u?.age ?? 25}y, ${u?.weight ?? 70}kg, goal: ${u?.goal ?? 'maintain'}
TODAY: ${p.todayCalories.toInt()}/${p.calorieGoal.toInt()} kcal, ${p.todayProtein.toInt()}/${p.proteinGoal.toInt()}g protein, ${p.todayCarbs.toInt()}/${p.carbsGoal.toInt()}g carbs, ${p.todayFat.toInt()}/${p.fatGoal.toInt()}g fat, ${(p.todayWaterMl/1000).toStringAsFixed(1)}/${(p.waterGoal/1000).toStringAsFixed(1)}L water, streak: ${p.currentStreak} days''';
  }

  Future<void> _send(String text) async {
    if (text.trim().isEmpty || _loading) return;
    _ctrl.clear();
    setState(() { _msgs.add(_Msg(text: text, isBot: false)); _loading = true; });
    _scrollDown();
    final p = Provider.of<NutritionProvider>(context, listen: false);
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final reply = await ClaudeService.chat(userMessage: text, history: List.from(_history), systemContext: _ctx(p, auth));
    _history.addAll([{'role': 'user', 'content': text}, {'role': 'assistant', 'content': reply}]);
    if (_history.length > 20) _history.removeRange(0, 2);
    setState(() { _msgs.add(_Msg(text: reply, isBot: true)); _loading = false; });
    _scrollDown();
  }

  void _scrollDown() => Future.delayed(const Duration(milliseconds: 100), () { if (_scroll.hasClients) _scroll.animateTo(_scroll.position.maxScrollExtent, duration: const Duration(milliseconds: 300), curve: Curves.easeOut); });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: isDark ? AppColors.bgDark : AppColors.bg,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: isDark ? AppColors.surfaceDark : AppColors.surface,
        title: Row(children: [
          Container(width: 36, height: 36, decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle), child: const Center(child: Text('🤖', style: TextStyle(fontSize: 18)))),
          const SizedBox(width: 10),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Text('NutriBot', style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w700, color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary)),
              const SizedBox(width: 6),
              Container(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2), decoration: BoxDecoration(color: AppColors.purpleLight, borderRadius: BorderRadius.circular(6)), child: Text('AI', style: GoogleFonts.inter(fontSize: 9, color: AppColors.purple, fontWeight: FontWeight.w700))),
            ]),
            Text('● Powered by Claude', style: GoogleFonts.inter(fontSize: 10, color: AppColors.primary, fontWeight: FontWeight.w500)),
          ]),
        ]),
        actions: [IconButton(onPressed: () => setState(() { _msgs.clear(); _history.clear(); _msgs.add(_Msg(text: 'Chat cleared! How can I help? 🌱', isBot: true)); }), icon: const Icon(Icons.delete_outline))],
      ),
      body: Column(children: [
        // Quick chips
        Container(color: isDark ? AppColors.surfaceDark : AppColors.surface, height: 48,
          child: ListView(scrollDirection: Axis.horizontal, padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            children: _chips.map((c) => GestureDetector(onTap: () => _send(c.substring(2).trim()),
              child: Container(margin: const EdgeInsets.only(right: 8), padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5), decoration: BoxDecoration(border: Border.all(color: AppColors.primary), borderRadius: BorderRadius.circular(20), color: isDark ? AppColors.surfaceDark : AppColors.surface),
                child: Text(c, style: GoogleFonts.inter(fontSize: 11, color: AppColors.primary, fontWeight: FontWeight.w500))))).toList())),
        Divider(height: 1, color: isDark ? AppColors.borderDark : AppColors.border),
        // Messages
        Expanded(child: ListView.builder(controller: _scroll, padding: const EdgeInsets.all(16), itemCount: _msgs.length + (_loading ? 1 : 0),
          itemBuilder: (_, i) {
            if (i == _msgs.length && _loading) return _buildTyping(isDark);
            return _buildBubble(_msgs[i], isDark);
          })),
        // Input
        Container(padding: const EdgeInsets.fromLTRB(12, 8, 12, 12), decoration: BoxDecoration(color: isDark ? AppColors.surfaceDark : AppColors.surface, border: Border(top: BorderSide(color: isDark ? AppColors.borderDark : AppColors.border))),
          child: SafeArea(child: Row(children: [
            Expanded(child: TextField(controller: _ctrl, maxLines: 3, minLines: 1, textInputAction: TextInputAction.send, onSubmitted: _send,
              style: GoogleFonts.inter(fontSize: 14, color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary),
              decoration: InputDecoration(hintText: 'Ask anything about nutrition...', filled: true, fillColor: isDark ? AppColors.surfaceVariantDark : AppColors.surfaceVariant,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(22), borderSide: BorderSide.none),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(22), borderSide: const BorderSide(color: AppColors.primary, width: 1.5)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10)))),
            const SizedBox(width: 8),
            GestureDetector(onTap: () => _send(_ctrl.text), child: AnimatedContainer(duration: const Duration(milliseconds: 200), width: 44, height: 44, decoration: BoxDecoration(color: _loading ? AppColors.textHint : AppColors.primary, shape: BoxShape.circle),
              child: Center(child: _loading ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : const Icon(Icons.send_rounded, color: Colors.white, size: 20)))),
          ]))),
      ]),
    );
  }

  Widget _buildBubble(_Msg msg, bool isDark) {
    return Padding(padding: const EdgeInsets.only(bottom: 12), child: Row(
      mainAxisAlignment: msg.isBot ? MainAxisAlignment.start : MainAxisAlignment.end,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        if (msg.isBot) ...[Container(width: 28, height: 28, decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle), child: const Center(child: Text('🤖', style: TextStyle(fontSize: 14)))), const SizedBox(width: 8)],
        Flexible(child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: msg.isBot ? (isDark ? AppColors.surfaceDark : AppColors.surface) : AppColors.primary,
            borderRadius: BorderRadius.only(topLeft: const Radius.circular(16), topRight: const Radius.circular(16), bottomLeft: Radius.circular(msg.isBot ? 4 : 16), bottomRight: Radius.circular(msg.isBot ? 16 : 4)),
            border: msg.isBot ? Border.all(color: isDark ? AppColors.borderDark : AppColors.border) : null,
          ),
          child: _richText(msg.text, msg.isBot, isDark),
        )),
        if (!msg.isBot) ...[const SizedBox(width: 8), Container(width: 28, height: 28, decoration: BoxDecoration(color: isDark ? AppColors.surfaceVariantDark : AppColors.surfaceVariant, shape: BoxShape.circle), child: const Center(child: Text('👤', style: TextStyle(fontSize: 14))))],
      ],
    ));
  }

  Widget _richText(String text, bool isBot, bool isDark) {
    final parts = text.split('**');
    final spans = <TextSpan>[];
    for (int i = 0; i < parts.length; i++) {
      spans.add(TextSpan(text: parts[i], style: TextStyle(fontWeight: i.isOdd ? FontWeight.w700 : FontWeight.w400, fontSize: 14, height: 1.5, color: isBot ? (isDark ? AppColors.textPrimaryDark : AppColors.textPrimary) : Colors.white, fontFamily: GoogleFonts.inter().fontFamily)));
    }
    return RichText(text: TextSpan(children: spans));
  }

  Widget _buildTyping(bool isDark) => Padding(padding: const EdgeInsets.only(bottom: 12), child: Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
    Container(width: 28, height: 28, decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle), child: const Center(child: Text('🤖', style: TextStyle(fontSize: 14)))),
    const SizedBox(width: 8),
    Container(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12), decoration: BoxDecoration(color: isDark ? AppColors.surfaceDark : AppColors.surface, borderRadius: const BorderRadius.only(topLeft: Radius.circular(16), topRight: Radius.circular(16), bottomRight: Radius.circular(16), bottomLeft: Radius.circular(4)), border: Border.all(color: isDark ? AppColors.borderDark : AppColors.border)),
      child: Row(mainAxisSize: MainAxisSize.min, children: List.generate(3, (i) => TweenAnimationBuilder<double>(tween: Tween(begin: 0, end: 1), duration: Duration(milliseconds: 600 + i * 200),
        builder: (_, v, __) => Container(width: 8, height: 8, margin: const EdgeInsets.symmetric(horizontal: 2), decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.3 + v * 0.7), shape: BoxShape.circle)))))),
  ]));
}

class _Msg { final String text; final bool isBot; _Msg({required this.text, required this.isBot}); }
