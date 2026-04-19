import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../services/auth_provider.dart';
import '../services/nutrition_provider.dart';
import '../services/habit_provider.dart';
import '../services/meal_plan_provider.dart';
import '../utils/unit_helper.dart';
import '../services/theme_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/app_button.dart';
import '../widgets/app_text_field.dart';
import 'admin/admin_dashboard_screen.dart';
import 'auth/login_screen.dart';
import 'paywall_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});
  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late TextEditingController _nameCtrl;
  late TextEditingController _weightCtrl;
  late TextEditingController _heightCtrl;
  late TextEditingController _ageCtrl;
  late TextEditingController _targetCtrl;

  @override
  void initState() {
    super.initState();
    final u = Provider.of<AuthProvider>(context, listen: false).currentUser;
    final country = u?.country ?? 'India';
    _nameCtrl = TextEditingController(text: u?.name ?? '');
    _weightCtrl = TextEditingController(text: UnitHelper.weightForField(u?.weight ?? 70, country));
    _heightCtrl = TextEditingController(text: UnitHelper.heightForField(u?.height ?? 170, country));
    _ageCtrl = TextEditingController(text: u?.age.toString() ?? '');
    _targetCtrl = TextEditingController(text: UnitHelper.weightForField(u?.targetWeight ?? 70, country));
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _weightCtrl.dispose();
    _heightCtrl.dispose();
    _ageCtrl.dispose();
    _targetCtrl.dispose();
    super.dispose();
  }

  void _save() {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final nutrition = Provider.of<NutritionProvider>(context, listen: false);
    final country = auth.currentUser?.country ?? 'India';
    auth.updateProfile(
      name: _nameCtrl.text,
      weight: UnitHelper.parseWeightToKg(_weightCtrl.text, country),
      height: UnitHelper.parseHeightToCm(_heightCtrl.text, country),
      age: int.tryParse(_ageCtrl.text),
      targetWeight: UnitHelper.parseWeightToKg(_targetCtrl.text, country),
    );
    nutrition.setUser(auth.currentUser);
    context.read<HabitProvider>().setUser(auth.currentUser?.id ?? '');
    context.read<MealPlanProvider>().setUser(auth.currentUser?.id ?? '');
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: const Text('Profile saved!'),
      backgroundColor: AppColors.primary,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    ));
    Navigator.pop(context);
  }

  void _logout() {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Container(
              width: 56, height: 56,
              decoration: BoxDecoration(
                color: AppColors.accent.withOpacity(0.12),
                shape: BoxShape.circle,
                boxShadow: [BoxShadow(color: AppColors.accent.withOpacity(0.2), blurRadius: 16, offset: const Offset(0, 6))],
              ),
              child: const Icon(Icons.logout_rounded, color: AppColors.accent, size: 26),
            ),
            const SizedBox(height: 16),
            Text('Sign Out', style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w800)),
            const SizedBox(height: 8),
            Text('Are you sure you want to sign out?',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(fontSize: 14, color: AppColors.textSec)),
            const SizedBox(height: 24),
            Row(children: [
              Expanded(child: OutlinedButton(
                onPressed: () => Navigator.pop(context),
                style: OutlinedButton.styleFrom(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: Text('Cancel', style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
              )),
              const SizedBox(width: 12),
              Expanded(child: ElevatedButton(
                onPressed: () {
                  Provider.of<AuthProvider>(context, listen: false).logout();
                  Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => const LoginScreen()), (r) => false);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.accent,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  elevation: 0,
                ),
                child: Text('Sign Out', style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w700)),
              )),
            ]),
          ]),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final themeProvider = Provider.of<ThemeProvider>(context);
    final auth = Provider.of<AuthProvider>(context);
    final u = auth.currentUser;

    return Scaffold(
      backgroundColor: isDark ? AppColors.bgDark : AppColors.bg,
      appBar: AppBar(
        title: Text('Settings', style: GoogleFonts.inter(fontWeight: FontWeight.w800)),
        leading: GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Container(
            margin: const EdgeInsets.all(10),
            decoration: Clay.card(isDark: isDark, radius: 14),
            child: const Icon(Icons.arrow_back_ios_new_rounded, size: 16),
          ),
        ),
        backgroundColor: isDark ? AppColors.surfDark : AppColors.bg,
        elevation: 0,
        scrolledUnderElevation: 0,
        actions: [
          GestureDetector(
            onTap: _save,
            child: Container(
              margin: const EdgeInsets.only(right: 16, top: 10, bottom: 10),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [AppColors.brandBlue, AppColors.brandGreen]),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [BoxShadow(color: AppColors.brandBlue.withOpacity(0.35), blurRadius: 10, offset: const Offset(0, 4))],
              ),
              child: Text('Save', style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 13)),
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildProfileHeader(u, isDark),
          const SizedBox(height: 22),
          _section('Profile'),
          _buildProfileForm(isDark),
          const SizedBox(height: 22),
          _section('Daily Goals'),
          _buildGoalsCard(u, isDark),
          const SizedBox(height: 22),
          _section('Subscription'),
          _buildSubscriptionCard(u, isDark),
          const SizedBox(height: 22),
          _section('Appearance'),
          _buildAppearanceCard(themeProvider, isDark),
          const SizedBox(height: 22),
          _section('About'),
          _buildAboutCard(isDark),
          if (u?.role == 'admin') ...[
            const SizedBox(height: 22),
            _section('Admin'),
            _buildAdminCard(isDark),
          ],
          const SizedBox(height: 22),
          AppButton(label: 'Sign Out', onTap: _logout, color: AppColors.accent),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildProfileHeader(user, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: Clay.gradientCard(
        isDark: isDark,
        colors: isDark
          ? [const Color(0xFF0D1F3C), const Color(0xFF0A2A1A)]
          : [AppColors.blueBg, AppColors.greenBg],
        radius: 28,
        shadowColor: AppColors.brandBlue,
      ),
      child: Row(children: [
        Container(
          width: 60, height: 60,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const LinearGradient(
              colors: [AppColors.brandBlue, AppColors.brandGreen],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [BoxShadow(color: AppColors.brandBlue.withOpacity(0.40), blurRadius: 14, offset: const Offset(0, 6))],
          ),
          child: Center(child: Text(
            (user != null && user.name.isNotEmpty) ? user.name[0].toUpperCase() : 'U',
            style: GoogleFonts.inter(fontSize: 26, fontWeight: FontWeight.w800, color: Colors.white),
          )),
        ),
        const SizedBox(width: 16),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(user?.name ?? 'User', style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700,
            color: isDark ? AppColors.textPriDark : AppColors.textPri)),
          const SizedBox(height: 2),
          Text(user?.email ?? '', style: GoogleFonts.inter(fontSize: 13,
            color: isDark ? AppColors.textSecDark : AppColors.textSec)),
          if (user?.emailVerified == true)
            Row(children: [
              const Icon(Icons.verified_rounded, size: 14, color: AppColors.brandBlue),
              const SizedBox(width: 4),
              Text('Verified', style: GoogleFonts.inter(fontSize: 11, color: AppColors.brandBlue, fontWeight: FontWeight.w600)),
            ]),
        ])),
      ]),
    );
  }

  Widget _buildProfileForm(bool isDark) {
    final country = Provider.of<AuthProvider>(context, listen: false).currentUser?.country ?? 'India';
    return _card(isDark, Column(children: [
      AppTextField(controller: _nameCtrl, label: 'Name', hint: 'Your name', icon: Icons.person_outline),
      const SizedBox(height: 14),
      Row(children: [
        Expanded(child: AppTextField(controller: _weightCtrl, label: UnitHelper.weightLabel(country), hint: UnitHelper.isImperial(country) ? '154' : '70', icon: Icons.monitor_weight_outlined, keyboardType: TextInputType.number)),
        const SizedBox(width: 12),
        Expanded(child: AppTextField(controller: _heightCtrl, label: UnitHelper.heightLabel(country), hint: UnitHelper.isImperial(country) ? '5.7' : '170', icon: Icons.height, keyboardType: TextInputType.number)),
      ]),
      const SizedBox(height: 14),
      Row(children: [
        Expanded(child: AppTextField(controller: _ageCtrl, label: 'Age', hint: '25', icon: Icons.cake_outlined, keyboardType: TextInputType.number)),
        const SizedBox(width: 12),
        Expanded(child: AppTextField(controller: _targetCtrl, label: UnitHelper.targetWeightLabel(country), hint: UnitHelper.isImperial(country) ? '140' : '65', icon: Icons.flag_outlined, keyboardType: TextInputType.number)),
      ]),
    ]));
  }

  Widget _buildSubscriptionCard(user, bool isDark) {
    if (user == null) return const SizedBox.shrink();
    final isPro    = user.subscriptionActive == true;
    final isTrial  = user.isTrialActive == true;
    final daysLeft = user.trialDaysLeft as int? ?? 0;
    final credits  = user.credits as int? ?? 0;

    return _card(isDark, Column(children: [
      Row(children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: Clay.pill(
            color: isPro ? AppColors.brandBlue : isTrial ? AppColors.amber : AppColors.accent,
            opacity: 0.16,
          ),
          child: Text(
            isPro ? '👑  Pro' : isTrial ? '⏳  Free Trial' : '🔒  Trial Ended',
            style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w700,
              color: isPro ? AppColors.brandBlue : isTrial ? AppColors.amber : AppColors.accent),
          ),
        ),
        const Spacer(),
        if (!isPro)
          GestureDetector(
            onTap: () => Navigator.push(context, MaterialPageRoute(
              builder: (_) => PaywallScreen(reason: isTrial ? 'no_credits' : 'trial_expired'))),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [AppColors.brandBlue, AppColors.brandGreen]),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [BoxShadow(color: AppColors.brandBlue.withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 4))],
              ),
              child: Text('Upgrade →', style: GoogleFonts.inter(fontSize: 12, color: Colors.white, fontWeight: FontWeight.w700)),
            ),
          ),
      ]),
      const SizedBox(height: 14),
      _infoRow('AI Credits', '$credits remaining', '⚡'),
      if (!isPro) ...[
        Divider(height: 16, color: AppColors.border.withOpacity(0.4)),
        _infoRow('Trial Days Left', '$daysLeft days', '📅'),
      ],
    ]));
  }

  Widget _buildGoalsCard(user, bool isDark) {
    return _card(isDark, Column(children: [
      _infoRow('Daily Calories', '${user?.dailyCalorieGoal.toInt() ?? 2200} kcal', '🔥'),
      Divider(height: 16, color: AppColors.border.withOpacity(0.4)),
      _infoRow('Protein', '${user?.proteinGoal.toInt() ?? 150}g', '💪'),
      Divider(height: 16, color: AppColors.border.withOpacity(0.4)),
      _infoRow('Carbs', '${user?.carbsGoal.toInt() ?? 250}g', '🌾'),
      Divider(height: 16, color: AppColors.border.withOpacity(0.4)),
      _infoRow('Fat', '${user?.fatGoal.toInt() ?? 70}g', '🧈'),
      Divider(height: 16, color: AppColors.border.withOpacity(0.4)),
      _infoRow('Water', '${((user?.waterGoal ?? 2500) / 1000).toStringAsFixed(1)}L', '💧'),
    ]));
  }

  Widget _buildAppearanceCard(ThemeProvider tp, bool isDark) {
    return _card(isDark, Row(children: [
      Container(
        width: 40, height: 40,
        decoration: Clay.icon(color: tp.isDark ? AppColors.purple : AppColors.amber, radius: 12, isDark: isDark),
        child: Center(child: Text(tp.isDark ? '🌙' : '☀️', style: const TextStyle(fontSize: 20))),
      ),
      const SizedBox(width: 14),
      Expanded(child: Text(tp.isDark ? 'Dark Mode' : 'Light Mode',
        style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600,
          color: isDark ? AppColors.textPriDark : AppColors.textPri))),
      Switch(value: tp.isDark, onChanged: (_) => tp.toggleTheme(), activeColor: AppColors.primary),
    ]));
  }

  Widget _buildAboutCard(bool isDark) {
    return _card(isDark, Row(children: [
      Container(
        width: 46, height: 46,
        decoration: Clay.icon(color: AppColors.brandGreen, radius: 14, isDark: isDark),
        child: const Center(child: Text('🥗', style: TextStyle(fontSize: 24))),
      ),
      const SizedBox(width: 14),
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text.rich(TextSpan(children: [
          TextSpan(text: 'Pro', style: GoogleFonts.inter(fontWeight: FontWeight.w800, color: AppColors.brandBlue)),
          TextSpan(text: 'Nutri', style: GoogleFonts.inter(fontWeight: FontWeight.w800, color: AppColors.brandGreen)),
        ])),
        Text('Version 2.0.0', style: GoogleFonts.inter(fontSize: 11, color: AppColors.textSecondary)),
      ]),
    ]));
  }

  Widget _section(String title) => Padding(
    padding: const EdgeInsets.only(bottom: 10, left: 6),
    child: Text(title, style: GoogleFonts.inter(
      fontSize: 12, fontWeight: FontWeight.w800,
      color: AppColors.textSecondary, letterSpacing: 0.8,
    )),
  );

  Widget _card(bool isDark, Widget child) => Container(
    padding: const EdgeInsets.all(18),
    margin: const EdgeInsets.only(bottom: 4),
    decoration: Clay.card(isDark: isDark, radius: 24),
    child: child,
  );

  Widget _infoRow(String label, String val, String emoji) => Row(children: [
    Text(emoji, style: const TextStyle(fontSize: 18)),
    const SizedBox(width: 12),
    Expanded(child: Text(label, style: GoogleFonts.inter(fontSize: 14, color: AppColors.textSecondary))),
    Text(val, style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.primary)),
  ]);

  Widget _buildAdminCard(bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : AppColors.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.accent.withOpacity(0.25)),
        boxShadow: [
          BoxShadow(color: AppColors.accent.withOpacity(0.12), blurRadius: 16, offset: const Offset(0, 6)),
          BoxShadow(color: Colors.white.withOpacity(isDark ? 0.04 : 0.8), blurRadius: 4, offset: const Offset(-1, -1)),
        ],
      ),
      child: ListTile(
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminDashboardScreen())),
        leading: Container(
          width: 40, height: 40,
          decoration: Clay.icon(color: AppColors.accent, radius: 12, isDark: isDark),
          child: const Icon(Icons.admin_panel_settings, color: AppColors.accent, size: 20),
        ),
        title: Text('Trainer Applications',
            style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600,
                color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary)),
        subtitle: Text('Review & approve trainer accounts',
            style: GoogleFonts.inter(fontSize: 12, color: AppColors.textSecondary)),
        trailing: Container(
          width: 28, height: 28,
          decoration: Clay.icon(color: AppColors.accent, radius: 8, isDark: isDark),
          child: const Icon(Icons.chevron_right, size: 16, color: AppColors.accent),
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      ),
    );
  }
}
