import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../services/auth_provider.dart';
import '../../services/live_session_provider.dart';
import '../../theme/app_theme.dart';

// ─────────────────────────────────────────────────────────────────────────────
// ScheduleSessionScreen
// ─────────────────────────────────────────────────────────────────────────────
class ScheduleSessionScreen extends StatefulWidget {
  const ScheduleSessionScreen({super.key});

  @override
  State<ScheduleSessionScreen> createState() => _ScheduleSessionScreenState();
}

class _ScheduleSessionScreenState extends State<ScheduleSessionScreen> {
  final _formKey     = GlobalKey<FormState>();
  final _titleCtrl   = TextEditingController();
  final _descCtrl    = TextEditingController();

  String   _category   = 'Workout';
  DateTime _scheduledAt = DateTime.now().add(const Duration(hours: 1));
  bool     _isRecorded = true;
  bool     _isSaving   = false;

  final _tags       = <String>[];
  final _tagCtrl    = TextEditingController();

  static const _categories = [
    'Workout', 'Nutrition', 'Yoga', 'Cardio', 'Mindfulness',
  ];

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    _tagCtrl.dispose();
    super.dispose();
  }

  // ── Pick date + time ───────────────────────────────────────────────────────
  Future<void> _pickDateTime() async {
    final date = await showDatePicker(
      context:      context,
      initialDate:  _scheduledAt,
      firstDate:    DateTime.now(),
      lastDate:     DateTime.now().add(const Duration(days: 90)),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.light(primary: AppColors.brandBlue),
        ),
        child: child!,
      ),
    );
    if (date == null || !mounted) return;

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_scheduledAt),
    );
    if (time == null) return;

    setState(() {
      _scheduledAt = DateTime(date.year, date.month, date.day, time.hour, time.minute);
    });
  }

  // ── Save ──────────────────────────────────────────────────────────────────
  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final user = context.read<AuthProvider>().currentUser;
    if (user == null) return;

    setState(() => _isSaving = true);

    final error = await context.read<LiveSessionProvider>().scheduleSession(
      trainerId:   user.id,
      trainerName: user.name,
      title:       _titleCtrl.text.trim(),
      description: _descCtrl.text.trim(),
      category:    _category,
      scheduledAt: _scheduledAt,
      isRecorded:  _isRecorded,
      tags:        List.from(_tags),
    );

    setState(() => _isSaving = false);

    if (!mounted) return;
    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error)));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Session scheduled! Participants will be notified.')),
      );
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.bgDark : AppColors.bg,
      appBar: AppBar(
        title: const Text('Schedule a Session'),
        actions: [
          TextButton(
            onPressed: _isSaving ? null : _save,
            child: _isSaving
                ? const SizedBox(width: 18, height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2))
                : Text('Save', style: GoogleFonts.inter(
                    color: AppColors.brandBlue, fontWeight: FontWeight.w700, fontSize: 15)),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            // ── Title ────────────────────────────────────────────────────
            const _SectionLabel('Session Title'),
            TextFormField(
              controller: _titleCtrl,
              maxLength:  80,
              decoration: const InputDecoration(
                hintText: 'e.g. Morning Metabolism Boost',
                counterText: '',
              ),
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Title is required' : null,
            ),
            const SizedBox(height: 20),

            // ── Description ──────────────────────────────────────────────
            const _SectionLabel('Description'),
            TextFormField(
              controller: _descCtrl,
              maxLines:   3,
              maxLength:  300,
              decoration: const InputDecoration(
                hintText: 'What will viewers learn or experience?',
                counterText: '',
              ),
            ),
            const SizedBox(height: 20),

            // ── Category ─────────────────────────────────────────────────
            const _SectionLabel('Category'),
            _CategoryPicker(
              selected:  _category,
              options:   _categories,
              onChanged: (c) => setState(() => _category = c),
            ),
            const SizedBox(height: 20),

            // ── Scheduled Date/Time ───────────────────────────────────────
            const _SectionLabel('Scheduled Date & Time'),
            GestureDetector(
              onTap: _pickDateTime,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.surfVarDark : AppColors.surfaceVar,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: isDark ? AppColors.borderDark : AppColors.border),
                ),
                child: Row(children: [
                  const Icon(Icons.calendar_today_outlined,
                      color: AppColors.brandBlue, size: 18),
                  const SizedBox(width: 12),
                  Expanded(child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(_formatDate(_scheduledAt), style: GoogleFonts.inter(
                        fontSize: 15, fontWeight: FontWeight.w700,
                        color: isDark ? AppColors.textPriDark : AppColors.textPri,
                      )),
                      Text(_formatTime(_scheduledAt), style: GoogleFonts.inter(
                        fontSize: 12, color: isDark ? AppColors.textSecDark : AppColors.textSec,
                      )),
                    ],
                  )),
                  Text(_countdown(_scheduledAt), style: GoogleFonts.inter(
                    fontSize: 12, color: AppColors.brandBlue, fontWeight: FontWeight.w600,
                  )),
                  const SizedBox(width: 8),
                  Icon(Icons.edit_outlined, color: isDark ? AppColors.textSecDark : AppColors.textSec, size: 16),
                ]),
              ),
            ),
            const SizedBox(height: 20),

            // ── Tags ─────────────────────────────────────────────────────
            const _SectionLabel('Tags (optional)'),
            Row(children: [
              Expanded(child: TextFormField(
                controller: _tagCtrl,
                decoration: InputDecoration(
                  hintText: 'e.g. beginner, fat-loss',
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.add_circle_outline, color: AppColors.brandBlue),
                    onPressed: _addTag,
                  ),
                ),
                onFieldSubmitted: (_) => _addTag(),
              )),
            ]),
            if (_tags.isNotEmpty) ...[
              const SizedBox(height: 10),
              Wrap(
                spacing: 8, runSpacing: 6,
                children: _tags.map((tag) => Chip(
                  label: Text(tag, style: GoogleFonts.inter(fontSize: 12)),
                  deleteIcon: const Icon(Icons.close, size: 14),
                  onDeleted: () => setState(() => _tags.remove(tag)),
                  backgroundColor: AppColors.brandBlue.withOpacity(0.1),
                  side: const BorderSide(color: AppColors.brandBlue, width: 0.5),
                )).toList(),
              ),
            ],
            const SizedBox(height: 20),

            // ── Recording toggle ─────────────────────────────────────────
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: isDark ? AppColors.surfDark : AppColors.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: isDark ? AppColors.borderDark : AppColors.border),
              ),
              child: Row(children: [
                Container(
                  width: 36, height: 36,
                  decoration: BoxDecoration(
                    color: _isRecorded
                        ? AppColors.accent.withOpacity(0.12)
                        : (isDark ? AppColors.surfVarDark : AppColors.surfaceVar),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(Icons.fiber_manual_record,
                      color: _isRecorded ? AppColors.accent : AppColors.textSec, size: 18),
                ),
                const SizedBox(width: 14),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Record Session', style: GoogleFonts.inter(
                    fontSize: 14, fontWeight: FontWeight.w700,
                    color: isDark ? AppColors.textPriDark : AppColors.textPri,
                  )),
                  Text('Viewers can replay after the session ends', style: GoogleFonts.inter(
                    fontSize: 12, color: isDark ? AppColors.textSecDark : AppColors.textSec,
                  )),
                ])),
                Switch(
                  value: _isRecorded,
                  onChanged: (v) => setState(() => _isRecorded = v),
                ),
              ]),
            ),
            const SizedBox(height: 32),

            // ── Info card ────────────────────────────────────────────────
            _InfoCard(isDark: isDark),
            const SizedBox(height: 32),

            // ── Save button ──────────────────────────────────────────────
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isSaving ? null : _save,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: _isSaving
                    ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : Text('Schedule Session', style: GoogleFonts.inter(
                        fontSize: 15, fontWeight: FontWeight.w700, color: Colors.white)),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  void _addTag() {
    final tag = _tagCtrl.text.trim().toLowerCase().replaceAll(' ', '-');
    if (tag.isEmpty || _tags.contains(tag) || _tags.length >= 5) return;
    setState(() { _tags.add(tag); _tagCtrl.clear(); });
  }

  String _formatDate(DateTime dt) {
    const months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
    const days   = ['Mon','Tue','Wed','Thu','Fri','Sat','Sun'];
    return '${days[dt.weekday - 1]}, ${dt.day} ${months[dt.month - 1]} ${dt.year}';
  }

  String _formatTime(DateTime dt) {
    final m    = dt.minute.toString().padLeft(2, '0');
    final ampm = dt.hour < 12 ? 'AM' : 'PM';
    final h12  = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
    return '$h12:$m $ampm';
  }

  String _countdown(DateTime dt) {
    final diff = dt.difference(DateTime.now());
    if (diff.inDays > 0)    return 'in ${diff.inDays}d ${diff.inHours.remainder(24)}h';
    if (diff.inHours > 0)   return 'in ${diff.inHours}h ${diff.inMinutes.remainder(60)}m';
    if (diff.inMinutes > 0) return 'in ${diff.inMinutes}m';
    return 'Now';
  }
}

// ── Helpers ───────────────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(text, style: GoogleFonts.inter(
        fontSize: 13, fontWeight: FontWeight.w700,
        color: isDark ? AppColors.textSecDark : AppColors.textSec,
        letterSpacing: 0.2,
      )),
    );
  }
}

class _CategoryPicker extends StatelessWidget {
  final String           selected;
  final List<String>     options;
  final void Function(String) onChanged;

  const _CategoryPicker({
    required this.selected,
    required this.options,
    required this.onChanged,
  });

  Color _colorFor(String c) {
    switch (c.toLowerCase()) {
      case 'nutrition':   return AppColors.brandGreen;
      case 'workout':     return AppColors.accent;
      case 'yoga':        return AppColors.purple;
      case 'cardio':      return AppColors.amber;
      case 'mindfulness': return AppColors.brandBlue;
      default:            return AppColors.textSec;
    }
  }

  @override
  Widget build(BuildContext context) => Wrap(
    spacing: 8, runSpacing: 8,
    children: options.map((opt) {
      final active = opt == selected;
      final color  = _colorFor(opt);
      return GestureDetector(
        onTap: () => onChanged(opt),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: active ? color : color.withOpacity(0.08),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: active ? color : color.withOpacity(0.3)),
          ),
          child: Text(opt, style: GoogleFonts.inter(
            fontSize: 13, fontWeight: FontWeight.w600,
            color: active ? Colors.white : color,
          )),
        ),
      );
    }).toList(),
  );
}

class _InfoCard extends StatelessWidget {
  final bool isDark;
  const _InfoCard({required this.isDark});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: AppColors.brandBlue.withOpacity(0.07),
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: AppColors.brandBlue.withOpacity(0.2)),
    ),
    child: const Column(children: [
      _InfoRow(Icons.notifications_outlined, 'Subscribers get notified 10 min before'),
      SizedBox(height: 8),
      _InfoRow(Icons.people_outline,         'Supports 1,000+ concurrent viewers'),
      SizedBox(height: 8),
      _InfoRow(Icons.security_outlined,      'Sessions are end-to-end encrypted'),
      SizedBox(height: 8),
      _InfoRow(Icons.replay_outlined,        'Recordings available for 30 days'),
    ]),
  );
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String   text;
  const _InfoRow(this.icon, this.text);

  @override
  Widget build(BuildContext context) => Row(children: [
    Icon(icon, color: AppColors.brandBlue, size: 16),
    const SizedBox(width: 10),
    Text(text, style: GoogleFonts.inter(fontSize: 12, color: AppColors.brandBlue)),
  ]);
}
