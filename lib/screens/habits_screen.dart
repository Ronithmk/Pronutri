import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../services/habit_provider.dart';
import '../theme/app_theme.dart';

class HabitsScreen extends StatelessWidget {
  const HabitsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final h = context.watch<HabitProvider>();

    return Scaffold(
      backgroundColor: isDark ? AppColors.bgDark : AppColors.bg,
      appBar: AppBar(
        title: Text('Daily Habits', style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back_ios, size: 18),
        ),
        backgroundColor: isDark ? AppColors.surfDark : AppColors.surface,
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.amber.withOpacity(0.15),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              const Text('🔥', style: TextStyle(fontSize: 13)),
              const SizedBox(width: 4),
              Text('${h.currentStreak} day streak',
                style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.amber)),
            ]),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _LevelCard(h: h, isDark: isDark),
          const SizedBox(height: 16),
          _TodayHabits(h: h, isDark: isDark),
          const SizedBox(height: 16),
          _MoodCheckIn(h: h, isDark: isDark),
          const SizedBox(height: 16),
          _WeekCalendar(h: h, isDark: isDark),
          const SizedBox(height: 16),
          _BadgesGrid(h: h, isDark: isDark),
          const SizedBox(height: 40),
        ],
      ),
    );
  }
}

// ── Level Card ────────────────────────────────────────────────────────────────
class _LevelCard extends StatelessWidget {
  final HabitProvider h;
  final bool isDark;
  const _LevelCard({required this.h, required this.isDark});

  Color get _levelColor {
    switch (h.levelName) {
      case 'Platinum': return const Color(0xFF67E8F9);
      case 'Gold':     return AppColors.amber;
      case 'Silver':   return const Color(0xFFB0BEC5);
      default:         return const Color(0xFFCD7F32);
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _levelColor;
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? [const Color(0xFF0D1F3C), const Color(0xFF0A2A1A)]
              : [const Color(0xFFE8F2FF), const Color(0xFFDFF5EA)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(color: color.withOpacity(0.2), blurRadius: 20, offset: const Offset(0, 8)),
        ],
      ),
      child: Row(children: [
        Container(
          width: 64, height: 64,
          decoration: BoxDecoration(
            color: color.withOpacity(0.15),
            shape: BoxShape.circle,
            border: Border.all(color: color.withOpacity(0.4), width: 2),
          ),
          child: Center(child: Text(h.levelEmoji, style: const TextStyle(fontSize: 30))),
        ),
        const SizedBox(width: 16),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(h.levelName,
            style: GoogleFonts.inter(fontSize: 22, fontWeight: FontWeight.w900, color: color)),
          const SizedBox(height: 4),
          Text(h.nextLevelDays == 0
            ? 'Max level reached! 🎉'
            : '${h.nextLevelDays} days to next level',
            style: GoogleFonts.inter(fontSize: 12, color: AppColors.textSec)),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: h.levelProgress,
              minHeight: 8,
              backgroundColor: color.withOpacity(0.15),
              valueColor: AlwaysStoppedAnimation(color),
            ),
          ),
        ])),
      ]),
    );
  }
}

// ── Today's Habits ────────────────────────────────────────────────────────────
class _TodayHabits extends StatelessWidget {
  final HabitProvider h;
  final bool isDark;
  const _TodayHabits({required this.h, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfDark : AppColors.surface,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(isDark ? 0.3 : 0.06), blurRadius: 16, offset: const Offset(0, 6))],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Text("Today's Habits",
            style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700,
              color: isDark ? AppColors.textPriDark : AppColors.textPri)),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
            decoration: BoxDecoration(
              color: AppColors.brandGreen.withOpacity(0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Text('${h.completedToday}/5 done',
              style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.brandGreen)),
          ),
        ]),
        const SizedBox(height: 4),
        Text(DateFormat('EEEE, MMM d').format(DateTime.now()),
          style: GoogleFonts.inter(fontSize: 12, color: AppColors.textSec)),
        const SizedBox(height: 18),
        _HabitTile(
          emoji: '💧', label: 'Drink 8 glasses of water',
          done: h.waterDone, isDark: isDark,
          onTap: () => context.read<HabitProvider>().toggleHabit('water'),
        ),
        _HabitTile(
          emoji: '😴', label: 'Sleep 7–8 hours',
          done: h.sleepDone, isDark: isDark,
          subtitle: h.sleepHours > 0 ? '${h.sleepHours.toStringAsFixed(1)} hrs logged' : 'Tap to log',
          onTap: () => _showSleepDialog(context, h),
        ),
        _HabitTile(
          emoji: '🚶', label: 'Walk 10,000 steps',
          done: h.stepsDone, isDark: isDark,
          onTap: () => context.read<HabitProvider>().toggleHabit('steps'),
        ),
        _HabitTile(
          emoji: '🥗', label: 'No junk food today',
          done: h.junkFreeDone, isDark: isDark,
          onTap: () => context.read<HabitProvider>().toggleHabit('junk_free'),
        ),
        _HabitTile(
          emoji: '🍽', label: 'Log all your meals',
          done: h.mealDone, isDark: isDark,
          onTap: () => context.read<HabitProvider>().toggleHabit('meal'),
        ),
        if (h.allDoneToday) ...[
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [AppColors.brandBlue, AppColors.brandGreen]),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              const Text('🎉', style: TextStyle(fontSize: 18)),
              const SizedBox(width: 8),
              Text('All habits done today!',
                style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w700, color: Colors.white)),
            ]),
          ),
        ],
      ]),
    );
  }

  void _showSleepDialog(BuildContext context, HabitProvider h) {
    double hours = h.sleepHours > 0 ? h.sleepHours : 7.0;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _SleepSheet(initial: hours),
    );
  }
}

class _HabitTile extends StatelessWidget {
  final String emoji;
  final String label;
  final bool done;
  final bool isDark;
  final String? subtitle;
  final VoidCallback onTap;

  const _HabitTile({
    required this.emoji, required this.label,
    required this.done, required this.isDark,
    required this.onTap, this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
        decoration: BoxDecoration(
          color: done
              ? AppColors.brandGreen.withOpacity(isDark ? 0.15 : 0.08)
              : isDark ? AppColors.surfVarDark : AppColors.surfaceVar,
          borderRadius: BorderRadius.circular(16),
          border: done ? Border.all(color: AppColors.brandGreen.withOpacity(0.3)) : null,
        ),
        child: Row(children: [
          Text(emoji, style: const TextStyle(fontSize: 20)),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(label,
              style: GoogleFonts.inter(
                fontSize: 13, fontWeight: FontWeight.w600,
                color: done
                    ? AppColors.brandGreen
                    : isDark ? AppColors.textPriDark : AppColors.textPri,
                decoration: done ? TextDecoration.lineThrough : null,
              )),
            if (subtitle != null) ...[
              const SizedBox(height: 2),
              Text(subtitle!, style: GoogleFonts.inter(fontSize: 11, color: AppColors.textSec)),
            ],
          ])),
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 28, height: 28,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: done ? AppColors.brandGreen : Colors.transparent,
              border: done ? null : Border.all(color: AppColors.textHint, width: 1.5),
            ),
            child: done ? const Icon(Icons.check, color: Colors.white, size: 16) : null,
          ),
        ]),
      ),
    );
  }
}

class _SleepSheet extends StatefulWidget {
  final double initial;
  const _SleepSheet({required this.initial});
  @override
  State<_SleepSheet> createState() => _SleepSheetState();
}

class _SleepSheetState extends State<_SleepSheet> {
  late double _hours;
  @override
  void initState() { super.initState(); _hours = widget.initial; }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfDark : AppColors.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Container(width: 40, height: 4, decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(2))),
        const SizedBox(height: 20),
        Text('How many hours did you sleep?',
          style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700,
            color: isDark ? AppColors.textPriDark : AppColors.textPri)),
        const SizedBox(height: 24),
        Text('${_hours.toStringAsFixed(1)} hrs',
          style: GoogleFonts.inter(fontSize: 36, fontWeight: FontWeight.w900, color: AppColors.brandBlue)),
        Slider(
          value: _hours,
          min: 2, max: 14, divisions: 24,
          activeColor: AppColors.brandBlue,
          onChanged: (v) => setState(() => _hours = v),
        ),
        Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
          Text('2h', style: GoogleFonts.inter(color: AppColors.textSec, fontSize: 12)),
          Text('Recommended: 7–9h', style: GoogleFonts.inter(color: AppColors.textSec, fontSize: 12)),
          Text('14h', style: GoogleFonts.inter(color: AppColors.textSec, fontSize: 12)),
        ]),
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.brandBlue,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
            onPressed: () {
              context.read<HabitProvider>().setSleepHours(_hours);
              Navigator.pop(context);
            },
            child: Text('Save', style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w700, color: Colors.white)),
          ),
        ),
        const SizedBox(height: 8),
      ]),
    );
  }
}

// ── Mood Check-In ─────────────────────────────────────────────────────────────
class _MoodCheckIn extends StatelessWidget {
  final HabitProvider h;
  final bool isDark;
  const _MoodCheckIn({required this.h, required this.isDark});

  static const _moods = ['😔', '😕', '😐', '🙂', '😄'];
  static const _labels = ['Terrible', 'Bad', 'Okay', 'Good', 'Great'];
  static const _tips = [
    'Try a light walk or breathing exercise 🌬️',
    'Drink some water and take a short break 💧',
    'You\'re doing okay! Log your meals to stay on track 🍽️',
    'Great energy! Keep up your habits today 💪',
    'You\'re on fire! Perfect day to crush your goals 🔥',
  ];

  @override
  Widget build(BuildContext context) {
    final mood = h.moodToday;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfDark : AppColors.surface,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(isDark ? 0.3 : 0.06), blurRadius: 16, offset: const Offset(0, 6))],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(
            width: 40, height: 40,
            decoration: BoxDecoration(
              color: AppColors.purple.withOpacity(0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Center(child: Text('🧠', style: TextStyle(fontSize: 20))),
          ),
          const SizedBox(width: 12),
          Text('Mental Wellness',
            style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700,
              color: isDark ? AppColors.textPriDark : AppColors.textPri)),
        ]),
        const SizedBox(height: 16),
        if (mood == null) ...[
          Text('How are you feeling today?',
            style: GoogleFonts.inter(fontSize: 13, color: AppColors.textSec)),
          const SizedBox(height: 14),
          Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: List.generate(5, (i) =>
            GestureDetector(
              onTap: () => context.read<HabitProvider>().setMood(i + 1),
              child: Column(children: [
                Text(_moods[i], style: const TextStyle(fontSize: 32)),
                const SizedBox(height: 4),
                Text(_labels[i], style: GoogleFonts.inter(fontSize: 9, color: AppColors.textSec)),
              ]),
            ),
          )),
        ] else ...[
          Row(children: [
            Text(_moods[mood - 1], style: const TextStyle(fontSize: 36)),
            const SizedBox(width: 14),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Feeling ${_labels[mood - 1].toLowerCase()} today',
                style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w700,
                  color: isDark ? AppColors.textPriDark : AppColors.textPri)),
              const SizedBox(height: 6),
              Text(_tips[mood - 1],
                style: GoogleFonts.inter(fontSize: 12, color: AppColors.textSec, height: 1.4)),
            ])),
          ]),
          const SizedBox(height: 12),
          GestureDetector(
            onTap: () => context.read<HabitProvider>().setMood(0),
            child: Text('Change mood →',
              style: GoogleFonts.inter(fontSize: 12, color: AppColors.brandBlue, fontWeight: FontWeight.w600)),
          ),
        ],
      ]),
    );
  }
}

// ── Week Calendar ─────────────────────────────────────────────────────────────
class _WeekCalendar extends StatelessWidget {
  final HabitProvider h;
  final bool isDark;
  const _WeekCalendar({required this.h, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final completion = h.last7DaysCompletion;
    final days = List.generate(7, (i) {
      final d = DateTime.now().subtract(Duration(days: 6 - i));
      return DateFormat('E').format(d).substring(0, 1);
    });

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfDark : AppColors.surface,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(isDark ? 0.3 : 0.06), blurRadius: 16, offset: const Offset(0, 6))],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('This Week', style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700,
          color: isDark ? AppColors.textPriDark : AppColors.textPri)),
        const SizedBox(height: 16),
        Row(children: List.generate(7, (i) {
          final isToday = i == 6;
          final done = completion[i];
          return Expanded(child: Column(children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              width: 38, height: 38,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: done
                    ? const LinearGradient(colors: [AppColors.brandBlue, AppColors.brandGreen])
                    : null,
                color: done ? null : isToday
                    ? AppColors.amber.withOpacity(0.15)
                    : isDark ? AppColors.surfVarDark : AppColors.surfaceVar,
                border: isToday && !done ? Border.all(color: AppColors.amber, width: 2) : null,
                boxShadow: done ? [BoxShadow(color: AppColors.brandBlue.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 4))] : null,
              ),
              child: Center(child: done
                ? const Icon(Icons.check_rounded, color: Colors.white, size: 16)
                : Text(days[i], style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700,
                    color: isToday ? AppColors.amber : isDark ? AppColors.textSecDark : AppColors.textSec)),
              ),
            ),
            const SizedBox(height: 5),
            Text(days[i], style: GoogleFonts.inter(fontSize: 9, color: AppColors.textSec)),
          ]));
        })),
        const SizedBox(height: 12),
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Text(
            '${completion.where((b) => b).length}/7 days completed',
            style: GoogleFonts.inter(fontSize: 13, color: AppColors.textSec, fontWeight: FontWeight.w500),
          ),
        ]),
      ]),
    );
  }
}

// ── Badges Grid ───────────────────────────────────────────────────────────────
class _BadgesGrid extends StatelessWidget {
  final HabitProvider h;
  final bool isDark;
  const _BadgesGrid({required this.h, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final badges = h.badges;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfDark : AppColors.surface,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(isDark ? 0.3 : 0.06), blurRadius: 16, offset: const Offset(0, 6))],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Text('Badges', style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700,
            color: isDark ? AppColors.textPriDark : AppColors.textPri)),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.amber.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text('${badges.where((b) => b.earned).length}/${badges.length}',
              style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.amber)),
          ),
        ]),
        const SizedBox(height: 16),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 4,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 0.75,
          ),
          itemCount: badges.length,
          itemBuilder: (_, i) => _BadgeTile(badge: badges[i], isDark: isDark),
        ),
      ]),
    );
  }
}

class _BadgeTile extends StatelessWidget {
  final HabitBadge badge;
  final bool isDark;
  const _BadgeTile({required this.badge, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(badge.earned ? '${badge.title}: ${badge.description}' : 'Locked: ${badge.description}'),
          backgroundColor: badge.earned ? AppColors.brandGreen : AppColors.textSec,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          duration: const Duration(seconds: 2),
        ));
      },
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 300),
        opacity: badge.earned ? 1.0 : 0.35,
        child: Column(children: [
          Container(
            width: 52, height: 52,
            decoration: BoxDecoration(
              color: badge.earned
                  ? AppColors.amber.withOpacity(0.15)
                  : isDark ? AppColors.surfVarDark : AppColors.surfaceVar,
              shape: BoxShape.circle,
              border: badge.earned ? Border.all(color: AppColors.amber.withOpacity(0.4), width: 2) : null,
              boxShadow: badge.earned
                  ? [BoxShadow(color: AppColors.amber.withOpacity(0.25), blurRadius: 10, offset: const Offset(0, 4))]
                  : null,
            ),
            child: Center(child: Text(badge.emoji, style: const TextStyle(fontSize: 24))),
          ),
          const SizedBox(height: 6),
          Text(badge.title,
            textAlign: TextAlign.center,
            maxLines: 2,
            style: GoogleFonts.inter(
              fontSize: 9.5,
              fontWeight: badge.earned ? FontWeight.w700 : FontWeight.w400,
              color: badge.earned
                  ? (isDark ? AppColors.textPriDark : AppColors.textPri)
                  : AppColors.textSec,
              height: 1.2,
            )),
        ]),
      ),
    );
  }
}
