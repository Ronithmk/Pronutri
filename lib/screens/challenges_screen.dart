import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive/hive.dart';
import '../theme/app_theme.dart';

class ChallengesScreen extends StatefulWidget {
  const ChallengesScreen({super.key});
  @override
  State<ChallengesScreen> createState() => _ChallengesScreenState();
}

class _ChallengesScreenState extends State<ChallengesScreen> {
  late Box _box;
  bool _ready = false;

  final _challenges = const [
    _ChallengeData(
      id: 'streak_7', title: '7-Day Logging Streak', emoji: '🔥',
      desc: 'Log your meals every day for 7 days in a row.',
      target: 7, color: Color(0xFFFF6B35), unit: 'days',
    ),
    _ChallengeData(
      id: 'steps_10k', title: '10K Steps Champion', emoji: '👟',
      desc: 'Hit 10,000 steps in a single day.',
      target: 10000, color: AppColors.brandBlue, unit: 'steps',
    ),
    _ChallengeData(
      id: 'water_8', title: 'Hydration Hero', emoji: '💧',
      desc: 'Drink 8 glasses of water for 5 consecutive days.',
      target: 5, color: Color(0xFF29B6F6), unit: 'days',
    ),
    _ChallengeData(
      id: 'meals_21', title: 'Log 21 Meals', emoji: '🍽',
      desc: 'Log 21 meals total — one full week of tracking.',
      target: 21, color: AppColors.brandGreen, unit: 'meals',
    ),
    _ChallengeData(
      id: 'clean_week', title: 'Clean Week', emoji: '🥗',
      desc: 'Go 7 days without logging junk food.',
      target: 7, color: Color(0xFF66BB6A), unit: 'days',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _box = Hive.box('habits_data');
    setState(() => _ready = true);
  }

  int _progress(String id) {
    return (_box.get('challenge_$id') as int?) ?? 0;
  }

  bool _isComplete(String id, int target) => _progress(id) >= target;

  Future<void> _increment(String id, int target) async {
    final current = _progress(id);
    if (current < target) {
      await _box.put('challenge_$id', current + 1);
      setState(() {});
      if (current + 1 >= target && mounted) {
        _showComplete(id);
      }
    }
  }

  void _showComplete(String id) {
    final c = _challenges.firstWhere((c) => c.id == id);
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          Text(c.emoji, style: const TextStyle(fontSize: 60)),
          const SizedBox(height: 12),
          Text('Challenge Complete!',
              style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.w800)),
          const SizedBox(height: 8),
          Text('"${c.title}" completed! 🎉',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(fontSize: 14, color: AppColors.textSec)),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context),
              child: Text('Awesome!', style: GoogleFonts.inter(fontWeight: FontWeight.w700, color: AppColors.brandGreen))),
        ],
      ),
    );
  }

  Future<void> _reset(String id) async {
    await _box.put('challenge_$id', 0);
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.bgDark : AppColors.bg,
      appBar: AppBar(
        backgroundColor: isDark ? AppColors.surfDark : AppColors.surface,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        title: Text('Challenges',
            style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 18,
                color: isDark ? AppColors.textPriDark : AppColors.textPri)),
      ),
      body: !_ready
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
              children: [
                _headerBanner(isDark),
                const SizedBox(height: 16),
                ..._challenges.map((c) => _ChallengeCard(
                  data: c,
                  progress: _progress(c.id),
                  isDark: isDark,
                  onIncrement: () => _increment(c.id, c.target),
                  onReset: () => _reset(c.id),
                )),
              ],
            ),
    );
  }

  Widget _headerBanner(bool isDark) {
    final completed = _challenges.where((c) => _isComplete(c.id, c.target)).length;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.brandBlue, AppColors.brandGreen],
          begin: Alignment.topLeft, end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(children: [
        const Text('🏆', style: TextStyle(fontSize: 40)),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('$completed / ${_challenges.length} Complete',
              style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.w800, color: Colors.white)),
          Text('Keep going — you\'re building great habits!',
              style: GoogleFonts.inter(fontSize: 12, color: Colors.white.withOpacity(0.85))),
        ])),
      ]),
    );
  }
}

class _ChallengeCard extends StatelessWidget {
  final _ChallengeData data;
  final int progress;
  final bool isDark;
  final VoidCallback onIncrement;
  final VoidCallback onReset;
  const _ChallengeCard({
    required this.data, required this.progress, required this.isDark,
    required this.onIncrement, required this.onReset,
  });

  @override
  Widget build(BuildContext context) {
    final pct = (progress / data.target).clamp(0.0, 1.0);
    final complete = progress >= data.target;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfDark : AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: complete
              ? data.color.withOpacity(0.5)
              : isDark ? AppColors.borderDark : AppColors.border,
          width: complete ? 2 : 1,
        ),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Text(data.emoji, style: const TextStyle(fontSize: 28)),
          const SizedBox(width: 10),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Expanded(child: Text(data.title,
                  style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w700,
                      color: isDark ? AppColors.textPriDark : AppColors.textPri))),
              if (complete)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: data.color.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text('Done ✓',
                      style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w700, color: data.color)),
                ),
            ]),
            Text(data.desc,
                style: GoogleFonts.inter(fontSize: 12,
                    color: isDark ? AppColors.textSecDark : AppColors.textSec)),
          ])),
        ]),
        const SizedBox(height: 12),
        Row(children: [
          Expanded(child: ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: pct,
              minHeight: 7,
              backgroundColor: data.color.withOpacity(0.12),
              valueColor: AlwaysStoppedAnimation(data.color),
            ),
          )),
          const SizedBox(width: 10),
          Text('$progress / ${data.target} ${data.unit}',
              style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600,
                  color: isDark ? AppColors.textSecDark : AppColors.textSec)),
        ]),
        const SizedBox(height: 12),
        Row(mainAxisAlignment: MainAxisAlignment.end, children: [
          if (complete)
            TextButton.icon(
              onPressed: onReset,
              icon: const Icon(Icons.replay, size: 15, color: AppColors.textHint),
              label: Text('Restart',
                  style: GoogleFonts.inter(fontSize: 12, color: AppColors.textHint)),
            )
          else
            ElevatedButton.icon(
              onPressed: onIncrement,
              icon: const Icon(Icons.add, size: 16),
              label: Text('Log Progress',
                  style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600)),
              style: ElevatedButton.styleFrom(
                backgroundColor: data.color,
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
        ]),
      ]),
    );
  }
}

class _ChallengeData {
  final String id, title, emoji, desc, unit;
  final int target;
  final Color color;
  const _ChallengeData({
    required this.id, required this.title, required this.emoji,
    required this.desc, required this.target, required this.color, required this.unit,
  });
}
