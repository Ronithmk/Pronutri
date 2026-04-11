import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../services/auth_provider.dart';
import '../../services/api_service.dart';
import '../../theme/app_theme.dart';
import '../auth/login_screen.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Admin Dashboard — Trainer Application Review
//
// Access: only accounts with role == 'admin' in Firestore reach this screen.
// Navigate here from SettingsScreen (admin-only section).
// ─────────────────────────────────────────────────────────────────────────────

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;
  Map<String, dynamic>? _stats;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 3, vsync: this);
    _loadStats();
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadStats() async {
    try {
      final res = await ApiService.get('/trainer/admin/stats');
      setState(() => _stats = res);
    } catch (_) {}
  }

  Future<void> _logout() async {
    final shouldLogout = await _confirmDialog(
      context,
      title: 'Sign Out',
      message: 'Do you want to log out from the admin dashboard?',
      confirmLabel: 'Sign Out',
      confirmColor: AppColors.accent,
    );
    if (shouldLogout != true || !mounted) return;

    await context.read<AuthProvider>().logout();
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.bgDark : AppColors.bg,
      appBar: AppBar(
        title: Row(children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: AppColors.accent.withOpacity(0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.admin_panel_settings,
                color: AppColors.accent, size: 16),
          ),
          const SizedBox(width: 10),
          const Text('Admin — Trainer Review'),
        ]),
        actions: [
          IconButton(
            onPressed: _logout,
            tooltip: 'Sign Out',
            icon: const Icon(Icons.logout_rounded),
            color: AppColors.accent,
          ),
          const SizedBox(width: 6),
        ],
        bottom: TabBar(
          controller: _tabCtrl,
          labelStyle:
              GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 13),
          unselectedLabelStyle:
              GoogleFonts.inter(fontWeight: FontWeight.w500, fontSize: 13),
          labelColor: AppColors.brandBlue,
          unselectedLabelColor:
              isDark ? AppColors.textSecDark : AppColors.textSec,
          indicatorColor: AppColors.brandBlue,
          tabs: [
            _Tab('Pending', _stats?['pending'], AppColors.amber),
            _Tab('Approved', _stats?['approved'], AppColors.brandGreen),
            _Tab('Rejected', _stats?['rejected'], AppColors.accent),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabCtrl,
        children: [
          _ApplicationList(status: 'pending', onAction: _loadStats),
          _ApplicationList(status: 'approved', onAction: _loadStats),
          _ApplicationList(status: 'rejected', onAction: _loadStats),
        ],
      ),
    );
  }
}

class _Tab extends StatelessWidget {
  final String label;
  final int? count;
  final Color color;
  const _Tab(this.label, this.count, this.color);

  @override
  Widget build(BuildContext context) => Tab(
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Text(label),
          if (count != null && count! > 0) ...[
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
              decoration: BoxDecoration(
                color: color.withOpacity(0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text('$count',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: color,
                  )),
            ),
          ],
        ]),
      );
}

// ─────────────────────────────────────────────────────────────────────────────
// _ApplicationList — fetches and displays applications by status
// ─────────────────────────────────────────────────────────────────────────────
class _ApplicationList extends StatefulWidget {
  final String status;
  final VoidCallback onAction;
  const _ApplicationList({required this.status, required this.onAction});

  @override
  State<_ApplicationList> createState() => _ApplicationListState();
}

class _ApplicationListState extends State<_ApplicationList>
    with AutomaticKeepAliveClientMixin {
  List<Map<String, dynamic>> _apps = [];
  bool _loading = true;
  String? _error;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final res = await ApiService.get(
          '/trainer/admin/applications?status=${widget.status}');
      setState(() {
        _apps = List<Map<String, dynamic>>.from(res['applications'] ?? []);
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_error != null) return _ErrorView(error: _error!, onRetry: _load);
    if (_apps.isEmpty) return _EmptyView(status: widget.status);

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: _apps.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (_, i) => _ApplicationCard(
          application: _apps[i],
          onApprove:
              widget.status == 'pending' ? () => _approve(_apps[i]) : null,
          onReject: widget.status == 'pending' ? () => _reject(_apps[i]) : null,
          onViewDoc: () => _viewDoc(_apps[i]),
        ),
      ),
    );
  }

  Future<void> _approve(Map<String, dynamic> app) async {
    final confirm = await _confirmDialog(
      context,
      title: 'Approve Trainer',
      message:
          'Approve ${app['trainer_name'] ?? app['email']} as a trainer?\n\nThey will be notified by email and push notification.',
      confirmLabel: 'Approve',
      confirmColor: AppColors.brandGreen,
    );
    if (confirm != true || !mounted) return;

    try {
      await ApiService.post('/trainer/admin/approve/${app['trainer_id']}', {});
      _showSnack('✅ ${app['trainer_name'] ?? 'Trainer'} approved!',
          AppColors.brandGreen);
      widget.onAction();
      _load();
    } catch (e) {
      _showSnack('Error: $e', AppColors.accent);
    }
  }

  Future<void> _reject(Map<String, dynamic> app) async {
    final reason = await _reasonDialog(context, app);
    if (reason == null || !mounted) return;

    try {
      await ApiService.post(
          '/trainer/admin/reject/${app['trainer_id']}', {'reason': reason});
      _showSnack('Application rejected.', AppColors.textSec);
      widget.onAction();
      _load();
    } catch (e) {
      _showSnack('Error: $e', AppColors.accent);
    }
  }

  void _viewDoc(Map<String, dynamic> app) {
    final docUrl = app['doc_url'] as String?;
    if (docUrl == null) return;
    Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => _DocViewerScreen(
            docUrl: ApiService.absoluteUrl(docUrl),
            trainerName: app['trainer_name'] ?? app['email'],
          ),
        ));
  }

  void _showSnack(String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg, style: GoogleFonts.inter(color: Colors.white)),
      backgroundColor: color,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ));
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _ApplicationCard
// ─────────────────────────────────────────────────────────────────────────────
class _ApplicationCard extends StatelessWidget {
  final Map<String, dynamic> application;
  final VoidCallback? onApprove;
  final VoidCallback? onReject;
  final VoidCallback onViewDoc;

  const _ApplicationCard({
    required this.application,
    this.onApprove,
    this.onReject,
    required this.onViewDoc,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final status = application['status'] as String? ?? 'pending';
    final specs =
        (application['specializations'] as List?)?.cast<String>() ?? [];
    final years = application['years_experience'] as int? ?? 0;
    final bio = application['bio'] as String? ?? '';
    final docType = application['doc_type'] as String? ?? 'certificate';
    final date = application['submitted_at'] as String?;
    final reason = application['rejection_reason'] as String?;

    final (statusColor, statusLabel, statusIcon) = switch (status) {
      'approved' => (AppColors.brandGreen, 'Approved', Icons.verified),
      'rejected' => (AppColors.accent, 'Rejected', Icons.cancel),
      _ => (AppColors.amber, 'Pending Review', Icons.hourglass_top),
    };

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfDark : AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isDark ? AppColors.borderDark : AppColors.border,
        ),
      ),
      child: Column(children: [
        // ── Header ──────────────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
          child: Row(children: [
            // Avatar
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: statusColor.withOpacity(0.12),
                shape: BoxShape.circle,
              ),
              child: Center(
                  child: Text(
                (application['trainer_name'] as String? ?? '?')[0]
                    .toUpperCase(),
                style: GoogleFonts.inter(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: statusColor,
                ),
              )),
            ),
            const SizedBox(width: 12),
            Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  Text(
                    application['trainer_name'] as String? ?? 'Unknown',
                    style: GoogleFonts.inter(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: isDark ? AppColors.textPriDark : AppColors.textPri,
                    ),
                  ),
                  Text(
                    application['email'] as String? ?? '',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: isDark ? AppColors.textSecDark : AppColors.textSec,
                    ),
                  ),
                ])),
            // Status badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: statusColor.withOpacity(0.12),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Icon(statusIcon, color: statusColor, size: 12),
                const SizedBox(width: 5),
                Text(statusLabel,
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: statusColor,
                    )),
              ]),
            ),
          ]),
        ),

        // ── Details ──────────────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.all(16),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            // Specs
            if (specs.isNotEmpty) ...[
              Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: specs
                      .map((s) => Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: AppColors.brandBlue.withOpacity(0.08),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(s,
                                style: GoogleFonts.inter(
                                  fontSize: 11,
                                  color: AppColors.brandBlue,
                                  fontWeight: FontWeight.w600,
                                )),
                          ))
                      .toList()),
              const SizedBox(height: 10),
            ],

            // Experience + doc type
            Row(children: [
              _InfoChip(Icons.workspace_premium_outlined,
                  '$years yr${years != 1 ? "s" : ""} exp', isDark),
              const SizedBox(width: 8),
              _InfoChip(_docIcon(docType), _docLabel(docType), isDark),
              if (date != null) ...[
                const SizedBox(width: 8),
                _InfoChip(
                    Icons.calendar_today_outlined, _formatDate(date), isDark),
              ],
            ]),

            // Bio
            if (bio.isNotEmpty) ...[
              const SizedBox(height: 10),
              Text(
                bio.length > 140 ? '${bio.substring(0, 140)}…' : bio,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  height: 1.5,
                  color: isDark ? AppColors.textSecDark : AppColors.textSec,
                ),
              ),
            ],

            // Rejection reason
            if (reason != null && reason.isNotEmpty) ...[
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.accent.withOpacity(0.07),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.accent.withOpacity(0.25)),
                ),
                child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.info_outline,
                          color: AppColors.accent, size: 15),
                      const SizedBox(width: 8),
                      Expanded(
                          child: Text(reason,
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                color: AppColors.accent,
                                height: 1.5,
                              ))),
                    ]),
              ),
            ],
          ]),
        ),

        // ── Actions ──────────────────────────────────────────────────
        Container(
          padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
          child: Row(children: [
            // View document
            Expanded(
                child: OutlinedButton.icon(
              onPressed: onViewDoc,
              icon: Icon(_docIcon(docType), size: 15),
              label: Text('View Document',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  )),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 10),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            )),

            if (onApprove != null) ...[
              const SizedBox(width: 8),
              // Reject
              IconButton(
                onPressed: onReject,
                icon:
                    const Icon(Icons.close, color: AppColors.accent, size: 20),
                tooltip: 'Reject',
                style: IconButton.styleFrom(
                  backgroundColor: AppColors.accent.withOpacity(0.1),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
              ),
              const SizedBox(width: 6),
              // Approve
              ElevatedButton.icon(
                onPressed: onApprove,
                icon: const Icon(Icons.check, size: 15),
                label: Text('Approve',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    )),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.brandGreen,
                  foregroundColor: Colors.white,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
              ),
            ],
          ]),
        ),
      ]),
    );
  }

  IconData _docIcon(String type) {
    switch (type) {
      case 'experience_letter':
        return Icons.description_outlined;
      case 'linkedin':
        return Icons.business_center_outlined;
      default:
        return Icons.workspace_premium_outlined;
    }
  }

  String _docLabel(String type) {
    switch (type) {
      case 'experience_letter':
        return 'Exp. Letter';
      case 'linkedin':
        return 'LinkedIn';
      default:
        return 'Certificate';
    }
  }

  String _formatDate(String iso) {
    try {
      final dt = DateTime.parse(iso).toLocal();
      return '${dt.day}/${dt.month}/${dt.year}';
    } catch (_) {
      return '';
    }
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isDark;
  const _InfoChip(this.icon, this.label, this.isDark);

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: isDark ? AppColors.surfVarDark : AppColors.surfaceVar,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
              color: isDark ? AppColors.borderDark : AppColors.border),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon,
              size: 12,
              color: isDark ? AppColors.textSecDark : AppColors.textSec),
          const SizedBox(width: 4),
          Text(label,
              style: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: isDark ? AppColors.textSecDark : AppColors.textSec,
              )),
        ]),
      );
}

// ─────────────────────────────────────────────────────────────────────────────
// _DocViewerScreen — shows the uploaded document.
// Uses ApiService.getBytes so the JWT header is sent (endpoint is admin-only).
// ─────────────────────────────────────────────────────────────────────────────
class _DocViewerScreen extends StatefulWidget {
  final String docUrl;
  final String trainerName;
  const _DocViewerScreen({required this.docUrl, required this.trainerName});

  @override
  State<_DocViewerScreen> createState() => _DocViewerScreenState();
}

class _DocViewerScreenState extends State<_DocViewerScreen> {
  bool get _isImage {
    final lower = widget.docUrl.toLowerCase();
    return lower.endsWith('.jpg') ||
        lower.endsWith('.jpeg') ||
        lower.endsWith('.png') ||
        lower.endsWith('.webp');
  }

  late Future<dynamic> _future;

  @override
  void initState() {
    super.initState();
    _future =
        _isImage ? ApiService.getBytes(widget.docUrl) : Future.value(null);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: Text(widget.trainerName,
            style: GoogleFonts.inter(color: Colors.white, fontSize: 15)),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: _isImage
          ? FutureBuilder(
              future: _future,
              builder: (_, snap) {
                if (snap.connectionState != ConnectionState.done) {
                  return const Center(
                    child: CircularProgressIndicator(color: Colors.white),
                  );
                }
                if (snap.data == null) {
                  return _ErrorView(
                    error: 'Could not load document. Check your connection.',
                    onRetry: () => setState(() {
                      _future = ApiService.getBytes(widget.docUrl);
                    }),
                  );
                }
                return InteractiveViewer(
                  minScale: 0.5,
                  maxScale: 5.0,
                  child: Center(
                    child: Image.memory(
                      snap.data!,
                      errorBuilder: (_, __, ___) => const Center(
                        child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.broken_image,
                                  color: Colors.white54, size: 64),
                              SizedBox(height: 12),
                              Text('Could not decode image.',
                                  style: TextStyle(
                                      color: Colors.white54, fontSize: 14)),
                            ]),
                      ),
                    ),
                  ),
                );
              },
            )
          : Center(
              child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.picture_as_pdf,
                    color: Colors.white54, size: 64),
                const SizedBox(height: 16),
                Text('PDF Document',
                    style: GoogleFonts.inter(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    )),
                const SizedBox(height: 8),
                Text('Download via the admin portal URL below.',
                    style:
                        GoogleFonts.inter(color: Colors.white54, fontSize: 13)),
                const SizedBox(height: 12),
                SelectableText(
                  widget.docUrl,
                  style: GoogleFonts.inter(color: Colors.white38, fontSize: 11),
                  textAlign: TextAlign.center,
                ),
              ],
            )),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Dialogs
// ─────────────────────────────────────────────────────────────────────────────
Future<bool?> _confirmDialog(
  BuildContext context, {
  required String title,
  required String message,
  required String confirmLabel,
  required Color confirmColor,
}) =>
    showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title:
            Text(title, style: GoogleFonts.inter(fontWeight: FontWeight.w800)),
        content:
            Text(message, style: GoogleFonts.inter(fontSize: 14, height: 1.5)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel',
                style: GoogleFonts.inter(color: AppColors.textSec)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: confirmColor,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
              elevation: 0,
            ),
            child: Text(confirmLabel,
                style: GoogleFonts.inter(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                )),
          ),
        ],
      ),
    );

Future<String?> _reasonDialog(
    BuildContext context, Map<String, dynamic> app) async {
  final ctrl = TextEditingController();
  final formKey = GlobalKey<FormState>();

  final result = await showDialog<String>(
    context: context,
    builder: (_) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Text('Reject Application',
          style: GoogleFonts.inter(fontWeight: FontWeight.w800)),
      content: Form(
        key: formKey,
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Text(
            'Provide a reason so ${app['trainer_name'] ?? 'the applicant'} '
            'knows how to improve their application.',
            style: GoogleFonts.inter(
                fontSize: 13, color: AppColors.textSec, height: 1.5),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: ctrl,
            maxLines: 3,
            maxLength: 300,
            autofocus: true,
            decoration: InputDecoration(
              hintText:
                  'e.g. "Certificate not clearly visible. Please re-upload a higher quality scan."',
              hintStyle:
                  GoogleFonts.inter(fontSize: 12, color: AppColors.textHint),
              border:
                  OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
            validator: (v) => (v == null || v.trim().length < 5)
                ? 'Please write a reason'
                : null,
          ),
        ]),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('Cancel',
              style: GoogleFonts.inter(color: AppColors.textSec)),
        ),
        ElevatedButton(
          onPressed: () {
            if (formKey.currentState!.validate()) {
              Navigator.pop(context, ctrl.text.trim());
            }
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.accent,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            elevation: 0,
          ),
          child: Text('Reject',
              style: GoogleFonts.inter(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              )),
        ),
      ],
    ),
  );

  ctrl.dispose();
  return result;
}

// ─────────────────────────────────────────────────────────────────────────────
// Empty / Error views
// ─────────────────────────────────────────────────────────────────────────────
class _EmptyView extends StatelessWidget {
  final String status;
  const _EmptyView({required this.status});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final (emoji, msg) = switch (status) {
      'approved' => ('✅', 'No approved trainers yet'),
      'rejected' => ('❌', 'No rejected applications'),
      _ => ('📋', 'No pending applications — all caught up!'),
    };
    return Center(
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      Text(emoji, style: const TextStyle(fontSize: 56)),
      const SizedBox(height: 16),
      Text(msg,
          style: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: isDark ? AppColors.textSecDark : AppColors.textSec,
          )),
    ]));
  }
}

class _ErrorView extends StatelessWidget {
  final String error;
  final VoidCallback onRetry;
  const _ErrorView({required this.error, required this.onRetry});

  @override
  Widget build(BuildContext context) => Center(
          child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          const Icon(Icons.error_outline, color: AppColors.accent, size: 48),
          const SizedBox(height: 16),
          Text('Failed to load applications',
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w700,
              )),
          const SizedBox(height: 8),
          Text(error,
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 13,
                color: AppColors.textSec,
              )),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh),
            label: const Text('Retry'),
          ),
        ]),
      ));
}
