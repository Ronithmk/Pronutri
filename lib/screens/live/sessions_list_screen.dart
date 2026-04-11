import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../models/live_session.dart';
import '../../services/auth_provider.dart';
import '../../services/live_session_provider.dart';
import '../../theme/app_theme.dart';
import 'trainer_broadcast_screen.dart';
import 'viewer_session_screen.dart';
import 'schedule_session_screen.dart';

// ── Constants ─────────────────────────────────────────────────────────────────
const _categories = ['All', 'Nutrition', 'Workout', 'Yoga', 'Cardio', 'Mindfulness'];

// ─────────────────────────────────────────────────────────────────────────────
// SessionsListScreen
// ─────────────────────────────────────────────────────────────────────────────
class SessionsListScreen extends StatefulWidget {
  const SessionsListScreen({super.key});
  @override
  State<SessionsListScreen> createState() => _SessionsListScreenState();
}

class _SessionsListScreenState extends State<SessionsListScreen>
    with AutomaticKeepAliveClientMixin {
  String _selectedCategory = 'All';

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<LiveSessionProvider>().fetchSessions();
    });
  }

  @override
  void dispose() {
    super.dispose();
  }

  // ── Filter ─────────────────────────────────────────────────────────────────
  List<LiveSession> _filtered(List<LiveSession> all) {
    if (_selectedCategory == 'All') return all;
    return all.where((s) =>
        s.category.toLowerCase() == _selectedCategory.toLowerCase()).toList();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final isDark    = Theme.of(context).brightness == Brightness.dark;
    final provider  = context.watch<LiveSessionProvider>();
    final user      = context.watch<AuthProvider>().currentUser;

    final isTrainer = user?.isTrainerApproved ?? false;

    final liveSessions     = _filtered(provider.liveSessions);
    final upcomingSessions = _filtered(provider.upcomingSessions);

    return Scaffold(
      backgroundColor: isDark ? AppColors.bgDark : AppColors.bg,
      body: RefreshIndicator(
        color: AppColors.brandBlue,
        onRefresh: provider.fetchSessions,
        child: CustomScrollView(
          slivers: [
            _buildAppBar(isDark, isTrainer),
            SliverToBoxAdapter(child: _buildCategoryFilter(isDark)),

            if (provider.isLoading)
              const SliverFillRemaining(child: Center(child: CircularProgressIndicator()))
            else ...[
              // ── Live Now ─────────────────────────────────────────────────
              if (liveSessions.isNotEmpty) ...[
                _sectionHeader('LIVE NOW', AppColors.accent, Icons.circle, isDark),
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (ctx, i) => _LiveSessionCard(session: liveSessions[i], isTrainer: isTrainer),
                      childCount: liveSessions.length,
                    ),
                  ),
                ),
              ],

              // ── Upcoming ─────────────────────────────────────────────────
              if (upcomingSessions.isNotEmpty) ...[
                _sectionHeader('UPCOMING', AppColors.brandBlue, Icons.calendar_today_outlined, isDark),
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (ctx, i) => _UpcomingSessionCard(session: upcomingSessions[i]),
                      childCount: upcomingSessions.length,
                    ),
                  ),
                ),
              ],

              if (liveSessions.isEmpty && upcomingSessions.isEmpty)
                SliverFillRemaining(child: _EmptyState(isTrainer: isTrainer)),

              const SliverToBoxAdapter(child: SizedBox(height: 100)),
            ],
          ],
        ),
      ),
      floatingActionButton: isTrainer ? _buildTrainerFab(context) : null,
    );
  }

  // ── App Bar ───────────────────────────────────────────────────────────────
  Widget _buildAppBar(bool isDark, bool isTrainer) => SliverAppBar(
    pinned: true,
    backgroundColor: isDark ? AppColors.surfDark : AppColors.surface,
    elevation: 0,
    scrolledUnderElevation: 0,
    expandedHeight: 100,
    flexibleSpace: FlexibleSpaceBar(
      titlePadding: const EdgeInsets.only(left: 20, bottom: 16),
      title: Row(children: [
        Container(
          width: 28, height: 28,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFFFF4040), Color(0xFFFF8080)],
              begin: Alignment.topLeft, end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(Icons.live_tv, color: Colors.white, size: 16),
        ),
        const SizedBox(width: 10),
        Text('Live Sessions', style: GoogleFonts.inter(
          fontSize: 18, fontWeight: FontWeight.w800,
          color: isDark ? AppColors.textPriDark : AppColors.textPri,
        )),
      ]),
    ),
    actions: [
      if (isTrainer)
        Padding(
          padding: const EdgeInsets.only(right: 8),
          child: TextButton.icon(
            onPressed: () => Navigator.push(context,
              MaterialPageRoute(builder: (_) => const ScheduleSessionScreen())),
            icon: const Icon(Icons.add, size: 16),
            label: Text('Schedule', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600)),
            style: TextButton.styleFrom(foregroundColor: AppColors.brandBlue),
          ),
        ),
    ],
  );

  // ── Category Filter ───────────────────────────────────────────────────────
  Widget _buildCategoryFilter(bool isDark) => SizedBox(
    height: 48,
    child: ListView.separated(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      separatorBuilder: (_, __) => const SizedBox(width: 8),
      itemCount: _categories.length,
      itemBuilder: (ctx, i) {
        final cat    = _categories[i];
        final active = _selectedCategory == cat;
        return GestureDetector(
          onTap: () => setState(() => _selectedCategory = cat),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            decoration: BoxDecoration(
              color: active ? AppColors.brandBlue : (isDark ? AppColors.surfVarDark : AppColors.surfaceVar),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: active ? AppColors.brandBlue : (isDark ? AppColors.borderDark : AppColors.border),
              ),
            ),
            child: Text(cat, style: GoogleFonts.inter(
              fontSize: 12, fontWeight: FontWeight.w600,
              color: active ? Colors.white : (isDark ? AppColors.textSecDark : AppColors.textSec),
            )),
          ),
        );
      },
    ),
  );

  // ── Section Header ────────────────────────────────────────────────────────
  Widget _sectionHeader(String title, Color color, IconData icon, bool isDark) =>
    SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
        child: Row(children: [
          Icon(icon, color: color, size: 14),
          const SizedBox(width: 6),
          Text(title, style: GoogleFonts.inter(
            fontSize: 11, fontWeight: FontWeight.w800,
            color: color, letterSpacing: 1.5,
          )),
        ]),
      ),
    );

  // ── Trainer FAB ───────────────────────────────────────────────────────────
  Widget _buildTrainerFab(BuildContext context) {
    final user    = context.read<AuthProvider>().currentUser;
    return FloatingActionButton.extended(
      onPressed: () async {
        if (user == null) return;
        final error = await context.read<LiveSessionProvider>().goLive(
          trainerId:   user.id,
          trainerName: user.name,
          title:       'Instant Live Session',
          category:    'Workout',
        );
        if (error != null && context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error)));
          return;
        }
        if (context.mounted) {
          Navigator.push(context, MaterialPageRoute(
            builder: (_) => const TrainerBroadcastScreen(),
          ));
        }
      },
      backgroundColor: const Color(0xFFFF4040),
      icon: const Icon(Icons.live_tv, color: Colors.white),
      label: Text('Go Live', style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w700)),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _LiveSessionCard
// ─────────────────────────────────────────────────────────────────────────────
class _LiveSessionCard extends StatelessWidget {
  final LiveSession session;
  final bool isTrainer;
  const _LiveSessionCard({required this.session, required this.isTrainer});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final user   = context.read<AuthProvider>().currentUser;

    return GestureDetector(
      onTap: () {
        if (isTrainer && session.trainerId == user?.id) {
          Navigator.push(context, MaterialPageRoute(
            builder: (_) => const TrainerBroadcastScreen(),
          ));
        } else {
          Navigator.push(context, MaterialPageRoute(
            builder: (_) => ViewerSessionScreen(session: session),
          ));
        }
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: isDark ? AppColors.surfDark : AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isDark ? AppColors.borderDark : AppColors.border,
          ),
          boxShadow: isDark ? [] : [
            BoxShadow(color: AppColors.accent.withOpacity(0.08), blurRadius: 16, offset: const Offset(0, 4)),
          ],
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // Thumbnail / Preview area
          _buildThumbnail(isDark),

          // Session info
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              // Category & Live badge
              Row(children: [
                _CategoryChip(category: session.category, color: session.categoryColor),
                const Spacer(),
                _LiveBadge(),
              ]),
              const SizedBox(height: 10),
              Text(session.title, style: GoogleFonts.inter(
                fontSize: 16, fontWeight: FontWeight.w700,
                color: isDark ? AppColors.textPriDark : AppColors.textPri,
              )),
              const SizedBox(height: 6),
              Row(children: [
                CircleAvatar(radius: 10, backgroundColor: AppColors.brandBlue.withOpacity(0.15),
                  child: Text(session.trainerName[0], style: GoogleFonts.inter(fontSize: 10, color: AppColors.brandBlue, fontWeight: FontWeight.w700)),
                ),
                const SizedBox(width: 6),
                Text(session.trainerName, style: GoogleFonts.inter(
                  fontSize: 12, fontWeight: FontWeight.w500,
                  color: isDark ? AppColors.textSecDark : AppColors.textSec,
                )),
                const Spacer(),
                Icon(Icons.remove_red_eye_outlined, size: 14,
                    color: isDark ? AppColors.textSecDark : AppColors.textSec),
                const SizedBox(width: 4),
                Text('${session.viewerCount}', style: GoogleFonts.inter(
                  fontSize: 12, fontWeight: FontWeight.w600,
                  color: isDark ? AppColors.textSecDark : AppColors.textSec,
                )),
                const SizedBox(width: 12),
                Icon(Icons.timer_outlined, size: 14,
                    color: isDark ? AppColors.textSecDark : AppColors.textSec),
                const SizedBox(width: 4),
                _LiveDurationTicker(startedAt: session.startedAt),
              ]),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => _joinSession(context, user),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFF4040),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                    const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 18),
                    const SizedBox(width: 6),
                    Text('Join Live', style: GoogleFonts.inter(
                      color: Colors.white, fontWeight: FontWeight.w700, fontSize: 14,
                    )),
                  ]),
                ),
              ),
            ]),
          ),
        ]),
      ),
    );
  }

  Widget _buildThumbnail(bool isDark) {
    return Container(
      height: 160,
      decoration: BoxDecoration(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        gradient: LinearGradient(
          colors: [
            session.categoryColor.withOpacity(0.8),
            session.categoryColor.withOpacity(0.4),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Stack(children: [
        Center(child: Icon(_categoryIcon(), color: Colors.white.withOpacity(0.3), size: 80)),
        Positioned(top: 12, left: 12, child: _LiveBadge()),
        Positioned(top: 12, right: 12, child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.5),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            const Icon(Icons.remove_red_eye_outlined, color: Colors.white, size: 12),
            const SizedBox(width: 4),
            Text('${session.viewerCount}', style: GoogleFonts.inter(
              color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600,
            )),
          ]),
        )),
      ]),
    );
  }

  IconData _categoryIcon() {
    switch (session.category.toLowerCase()) {
      case 'nutrition':   return Icons.restaurant_menu;
      case 'workout':     return Icons.fitness_center;
      case 'yoga':        return Icons.self_improvement;
      case 'cardio':      return Icons.directions_run;
      case 'mindfulness': return Icons.spa;
      default:            return Icons.live_tv;
    }
  }

  void _joinSession(BuildContext context, user) async {
    if (user == null) return;
    final error = await context.read<LiveSessionProvider>().joinSession(session, user.id);
    if (error != null && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error)));
      return;
    }
    if (context.mounted) {
      Navigator.push(context, MaterialPageRoute(
        builder: (_) => ViewerSessionScreen(session: session),
      ));
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _UpcomingSessionCard
// ─────────────────────────────────────────────────────────────────────────────
class _UpcomingSessionCard extends StatelessWidget {
  final LiveSession session;
  const _UpcomingSessionCard({required this.session});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final timeUntil = session.scheduledAt.difference(DateTime.now());
    final isToday = timeUntil.inDays == 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfDark : AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? AppColors.borderDark : AppColors.border),
      ),
      child: Row(children: [
        // Color accent bar
        Container(
          width: 4, height: 60,
          decoration: BoxDecoration(
            color: session.categoryColor,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(width: 14),

        // Time column
        Column(crossAxisAlignment: CrossAxisAlignment.center, children: [
          Text(
            isToday ? 'TODAY' : _dayLabel(),
            style: GoogleFonts.inter(
              fontSize: 9, fontWeight: FontWeight.w800, letterSpacing: 1,
              color: session.categoryColor,
            ),
          ),
          Text(
            _timeLabel(),
            style: GoogleFonts.inter(
              fontSize: 16, fontWeight: FontWeight.w800,
              color: isDark ? AppColors.textPriDark : AppColors.textPri,
            ),
          ),
          Text(
            _countdown(timeUntil),
            style: GoogleFonts.inter(fontSize: 9, color: isDark ? AppColors.textSecDark : AppColors.textSec),
          ),
        ]),
        const SizedBox(width: 14),

        const VerticalDivider(width: 1),
        const SizedBox(width: 14),

        // Details
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            _CategoryChip(category: session.category, color: session.categoryColor, small: true),
            if (session.isRecorded) ...[
              const SizedBox(width: 6),
              _RecordedBadge(),
            ],
          ]),
          const SizedBox(height: 6),
          Text(session.title,
            maxLines: 2, overflow: TextOverflow.ellipsis,
            style: GoogleFonts.inter(
              fontSize: 13, fontWeight: FontWeight.w700,
              color: isDark ? AppColors.textPriDark : AppColors.textPri,
            ),
          ),
          const SizedBox(height: 4),
          Text(session.trainerName, style: GoogleFonts.inter(
            fontSize: 11, color: isDark ? AppColors.textSecDark : AppColors.textSec,
          )),
        ])),

        // Reminder button
        IconButton(
          onPressed: () => _setReminder(context),
          icon: const Icon(Icons.notifications_outlined, size: 20),
          color: isDark ? AppColors.textSecDark : AppColors.textSec,
          tooltip: 'Set reminder',
        ),
      ]),
    );
  }

  String _dayLabel() {
    final diff = session.scheduledAt.difference(DateTime.now()).inDays;
    if (diff == 1) return 'TOMORROW';
    return '${session.scheduledAt.day}/${session.scheduledAt.month}';
  }

  String _timeLabel() {
    final h = session.scheduledAt.hour.toString().padLeft(2, '0');
    final m = session.scheduledAt.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  String _countdown(Duration d) {
    if (d.inDays > 0)    return 'in ${d.inDays}d ${d.inHours.remainder(24)}h';
    if (d.inHours > 0)   return 'in ${d.inHours}h ${d.inMinutes.remainder(60)}m';
    if (d.inMinutes > 0) return 'in ${d.inMinutes}m';
    return 'Starting soon';
  }

  void _setReminder(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
      content: Text('Reminder set! We\'ll notify you 10 minutes before.'),
      duration: Duration(seconds: 2),
    ));
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Helper Widgets
// ─────────────────────────────────────────────────────────────────────────────

class _LiveBadge extends StatefulWidget {
  @override
  State<_LiveBadge> createState() => _LiveBadgeState();
}

class _LiveBadgeState extends State<_LiveBadge> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 800))
      ..repeat(reverse: true);
    _anim = Tween(begin: 0.4, end: 1.0).animate(_ctrl);
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: _anim,
    builder: (_, __) => Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: Color.lerp(const Color(0xFFFF4040), const Color(0xFFFF8080), _anim.value),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Container(width: 6, height: 6, decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle)),
        const SizedBox(width: 4),
        Text('LIVE', style: GoogleFonts.inter(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 1)),
      ]),
    ),
  );
}

class _CategoryChip extends StatelessWidget {
  final String category;
  final Color  color;
  final bool   small;
  const _CategoryChip({required this.category, required this.color, this.small = false});

  @override
  Widget build(BuildContext context) => Container(
    padding: EdgeInsets.symmetric(horizontal: small ? 8 : 10, vertical: small ? 3 : 4),
    decoration: BoxDecoration(
      color: color.withOpacity(0.12),
      borderRadius: BorderRadius.circular(20),
    ),
    child: Text(category, style: GoogleFonts.inter(
      fontSize: small ? 10 : 11, fontWeight: FontWeight.w600, color: color,
    )),
  );
}

class _RecordedBadge extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
    decoration: BoxDecoration(
      color: AppColors.brandBlue.withOpacity(0.1),
      borderRadius: BorderRadius.circular(6),
    ),
    child: Row(mainAxisSize: MainAxisSize.min, children: [
      const Icon(Icons.fiber_manual_record, color: AppColors.brandBlue, size: 8),
      const SizedBox(width: 3),
      Text('REC', style: GoogleFonts.inter(fontSize: 9, fontWeight: FontWeight.w700, color: AppColors.brandBlue, letterSpacing: 0.5)),
    ]),
  );
}

class _LiveDurationTicker extends StatefulWidget {
  final DateTime? startedAt;
  const _LiveDurationTicker({this.startedAt});
  @override
  State<_LiveDurationTicker> createState() => _LiveDurationTickerState();
}

class _LiveDurationTickerState extends State<_LiveDurationTicker> {
  late Timer _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) { if (mounted) setState(() {}); });
  }

  @override
  void dispose() { _timer.cancel(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    if (widget.startedAt == null) return const SizedBox.shrink();
    final d = DateTime.now().difference(widget.startedAt!);
    final m = d.inMinutes.toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Text('$m:$s', style: GoogleFonts.inter(
      fontSize: 12, fontWeight: FontWeight.w600,
      color: isDark ? AppColors.textSecDark : AppColors.textSec,
    ));
  }
}

class _EmptyState extends StatelessWidget {
  final bool isTrainer;
  const _EmptyState({required this.isTrainer});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Center(child: Padding(
      padding: const EdgeInsets.all(40),
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(Icons.live_tv_outlined, size: 64,
            color: isDark ? AppColors.textSecDark : AppColors.textHint),
        const SizedBox(height: 20),
        Text('No sessions yet', style: GoogleFonts.inter(
          fontSize: 18, fontWeight: FontWeight.w700,
          color: isDark ? AppColors.textPriDark : AppColors.textPri,
        )),
        const SizedBox(height: 8),
        Text(
          isTrainer
            ? 'Tap the Go Live button to start streaming!'
            : 'Check back soon — trainers will go live here.',
          textAlign: TextAlign.center,
          style: GoogleFonts.inter(fontSize: 14, color: isDark ? AppColors.textSecDark : AppColors.textSec),
        ),
      ]),
    ));
  }
}
