import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/food_item.dart';
import '../../theme/app_theme.dart';

class ExerciseTimerScreen extends StatefulWidget {
  final Exercise exercise;
  const ExerciseTimerScreen({super.key, required this.exercise});
  @override
  State<ExerciseTimerScreen> createState() => _ExerciseTimerScreenState();
}

class _ExerciseTimerScreenState extends State<ExerciseTimerScreen> {
  Timer? _timer, _restTimer;
  int _seconds = 0, _totalSeconds = 0, _restSeconds = 90;
  bool _running = false, _finished = false, _resting = false;
  int _step = 0, _set = 1, _sets = 3;

  @override
  void dispose() { _timer?.cancel(); _restTimer?.cancel(); super.dispose(); }

  Color get _c { switch (widget.exercise.category) { case 'Strength': return AppColors.primary; case 'Cardio': return AppColors.amber; case 'HIIT': return AppColors.accent; case 'Yoga': return AppColors.purple; default: return AppColors.blue; } }

  void _toggle() {
    if (_running) { _timer?.cancel(); setState(() => _running = false); }
    else { setState(() { _running = true; _finished = false; }); _timer = Timer.periodic(const Duration(seconds: 1), (_) => setState(() { _seconds++; _totalSeconds++; })); }
  }

  void _reset() { _timer?.cancel(); setState(() { _seconds = 0; _running = false; _finished = false; _step = 0; _set = 1; _resting = false; }); }

  void _next() {
    if (_step < widget.exercise.steps.length - 1) { setState(() { _step++; _seconds = 0; }); }
    else if (_set < _sets) { _startRest(); }
    else { setState(() { _finished = true; _running = false; }); _timer?.cancel(); }
  }

  void _startRest() {
    _timer?.cancel();
    setState(() { _resting = true; _restSeconds = 90; _running = false; });
    _restTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_restSeconds > 0) { setState(() => _restSeconds--); }
      else { _restTimer?.cancel(); setState(() { _resting = false; _set++; _step = 0; _seconds = 0; }); }
    });
  }

  String _fmt(int s) => '${(s ~/ 60).toString().padLeft(2, '0')}:${(s % 60).toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final ex = widget.exercise;
    return Scaffold(
      backgroundColor: isDark ? AppColors.bgDark : AppColors.bg,
      appBar: AppBar(leading: IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.arrow_back_ios, size: 18)), title: Text(ex.name, style: GoogleFonts.inter(fontWeight: FontWeight.w700)), backgroundColor: isDark ? AppColors.surfaceDark : AppColors.surface,
        actions: [Container(margin: const EdgeInsets.only(right: 16), padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4), decoration: BoxDecoration(color: _c.withOpacity(0.1), borderRadius: BorderRadius.circular(20)), child: Text(ex.category, style: GoogleFonts.inter(fontSize: 12, color: _c, fontWeight: FontWeight.w600)))]),
      body: _finished ? _buildDone(isDark) : _resting ? _buildRest(isDark) : _buildMain(isDark),
    );
  }

  Widget _buildMain(bool isDark) {
    final ex = widget.exercise;
    return Column(children: [
      Container(color: isDark ? AppColors.surfaceDark : AppColors.surface, padding: const EdgeInsets.all(24), child: Column(children: [
        Row(mainAxisAlignment: MainAxisAlignment.center, children: List.generate(_sets, (i) => Container(width: 36, height: 4, margin: const EdgeInsets.symmetric(horizontal: 3), decoration: BoxDecoration(color: i < _set ? _c : _c.withOpacity(0.2), borderRadius: BorderRadius.circular(2))))),
        const SizedBox(height: 6),
        Text('Set $_set of $_sets', style: GoogleFonts.inter(fontSize: 12, color: AppColors.textSecondary)),
        const SizedBox(height: 20),
        Stack(alignment: Alignment.center, children: [
          SizedBox(width: 160, height: 160, child: CircularProgressIndicator(value: (_seconds % 60) / 60, strokeWidth: 8, backgroundColor: _c.withOpacity(0.1), valueColor: AlwaysStoppedAnimation(_c), strokeCap: StrokeCap.round)),
          Column(mainAxisSize: MainAxisSize.min, children: [
            Text(_fmt(_seconds), style: GoogleFonts.inter(fontSize: 36, fontWeight: FontWeight.w800, color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary)),
            Text('elapsed', style: GoogleFonts.inter(fontSize: 12, color: AppColors.textSecondary)),
          ]),
        ]),
        const SizedBox(height: 20),
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          _btn(Icons.refresh, _reset, isDark),
          const SizedBox(width: 16),
          GestureDetector(onTap: _toggle, child: Container(width: 64, height: 64, decoration: BoxDecoration(color: _c, shape: BoxShape.circle), child: Icon(_running ? Icons.pause : Icons.play_arrow, color: Colors.white, size: 32))),
          const SizedBox(width: 16),
          _btn(Icons.skip_next, _next, isDark),
        ]),
      ])),
      const SizedBox(height: 8),
      Expanded(child: ListView(padding: const EdgeInsets.all(16), children: [
        Text('Steps', style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w700, color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary)),
        const SizedBox(height: 12),
        ...ex.steps.asMap().entries.map((e) {
          final i = e.key; final done = i < _step; final active = i == _step;
          return GestureDetector(onTap: () { if (_running) setState(() => _step = i); }, child: AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            margin: const EdgeInsets.only(bottom: 8), padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(color: active ? _c.withOpacity(0.08) : isDark ? AppColors.surfaceDark : AppColors.surface, borderRadius: BorderRadius.circular(12), border: Border.all(color: active ? _c : isDark ? AppColors.borderDark : AppColors.border, width: active ? 1.5 : 1)),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Container(width: 26, height: 26, decoration: BoxDecoration(color: done ? AppColors.primary : active ? _c : _c.withOpacity(0.1), shape: BoxShape.circle), child: Center(child: Text(done ? '✓' : '${i+1}', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: done || active ? Colors.white : _c)))),
              const SizedBox(width: 10),
              Expanded(child: Text(e.value, style: GoogleFonts.inter(fontSize: 13, height: 1.5, color: done ? AppColors.textSecondary : isDark ? AppColors.textPrimaryDark : AppColors.textPrimary))),
            ]),
          ));
        }),
        if (_running && _step < ex.steps.length - 1) ...[
          const SizedBox(height: 8),
          OutlinedButton(onPressed: _next, child: Text('Next Step (${_step+1}/${ex.steps.length}) →')),
        ],
      ])),
    ]);
  }

  Widget _buildRest(bool isDark) => Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
    const Text('😮‍💨', style: TextStyle(fontSize: 64)),
    const SizedBox(height: 16),
    Text('Rest Time', style: GoogleFonts.inter(fontSize: 24, fontWeight: FontWeight.w700, color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary)),
    const SizedBox(height: 8),
    Text(_fmt(_restSeconds), style: GoogleFonts.inter(fontSize: 64, fontWeight: FontWeight.w800, color: AppColors.primary)),
    const SizedBox(height: 8),
    Text('Next: Set ${_set + 1} of $_sets', style: GoogleFonts.inter(fontSize: 14, color: AppColors.textSecondary)),
    const SizedBox(height: 32),
    OutlinedButton(onPressed: () { _restTimer?.cancel(); setState(() { _resting = false; _set++; _step = 0; _seconds = 0; }); }, child: const Text('Skip Rest')),
  ]));

  Widget _buildDone(bool isDark) => Center(child: Padding(padding: const EdgeInsets.all(32), child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
    const Text('🏆', style: TextStyle(fontSize: 72)),
    const SizedBox(height: 16),
    Text('Workout Complete!', style: GoogleFonts.inter(fontSize: 26, fontWeight: FontWeight.w800, color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary)),
    const SizedBox(height: 8),
    Text('Great job finishing ${widget.exercise.name}', style: GoogleFonts.inter(fontSize: 15, color: AppColors.textSecondary), textAlign: TextAlign.center),
    const SizedBox(height: 32),
    Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
      _stat('⏱', _fmt(_totalSeconds), 'Duration'),
      _stat('🔥', '${widget.exercise.caloriesBurned}', 'Calories'),
      _stat('💪', '$_sets', 'Sets'),
    ]),
    const SizedBox(height: 40),
    SizedBox(width: double.infinity, child: ElevatedButton(onPressed: () => Navigator.pop(context), child: const Text('Done'))),
  ])));

  Widget _btn(IconData icon, VoidCallback onTap, bool isDark) => GestureDetector(onTap: onTap, child: Container(width: 48, height: 48, decoration: BoxDecoration(color: isDark ? AppColors.surfaceVariantDark : AppColors.surfaceVariant, shape: BoxShape.circle), child: Icon(icon, size: 22, color: AppColors.textSecondary)));
  Widget _stat(String emoji, String val, String label) => Column(children: [Text(emoji, style: const TextStyle(fontSize: 24)), const SizedBox(height: 4), Text(val, style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.primary)), Text(label, style: GoogleFonts.inter(fontSize: 11, color: AppColors.textSecondary))]);
}
