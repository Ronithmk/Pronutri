import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../services/auth_provider.dart';
import '../services/nutrition_provider.dart';
import '../services/theme_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/app_button.dart';
import '../widgets/app_text_field.dart';
import 'auth/login_screen.dart';

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
    _nameCtrl = TextEditingController(text: u?.name ?? '');
    _weightCtrl = TextEditingController(text: u?.weight.toString() ?? '');
    _heightCtrl = TextEditingController(text: u?.height.toString() ?? '');
    _ageCtrl = TextEditingController(text: u?.age.toString() ?? '');
    _targetCtrl = TextEditingController(text: u?.targetWeight.toString() ?? '');
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
    auth.updateProfile(
      name: _nameCtrl.text,
      weight: double.tryParse(_weightCtrl.text),
      height: double.tryParse(_heightCtrl.text),
      age: int.tryParse(_ageCtrl.text),
      targetWeight: double.tryParse(_targetCtrl.text),
    );
    nutrition.setUser(auth.currentUser);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: const Text('Profile saved!'),
      backgroundColor: AppColors.primary,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ));
    Navigator.pop(context);
  }

  void _logout() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Sign Out', style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
        content: Text('Are you sure you want to sign out?', style: GoogleFonts.inter()),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              Provider.of<AuthProvider>(context, listen: false).logout();
              Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => const LoginScreen()), (r) => false);
            },
            child: Text('Sign Out', style: TextStyle(color: AppColors.accent)),
          ),
        ],
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
        title: Text('Settings', style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
        leading: IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.arrow_back_ios, size: 18)),
        backgroundColor: isDark ? AppColors.surfaceDark : AppColors.surface,
        actions: [
          TextButton(onPressed: _save, child: Text('Save', style: GoogleFonts.inter(color: AppColors.primary, fontWeight: FontWeight.w700))),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildProfileHeader(u, isDark),
          const SizedBox(height: 20),
          _section('Profile'),
          _buildProfileForm(isDark),
          const SizedBox(height: 20),
          _section('Daily Goals'),
          _buildGoalsCard(u, isDark),
          const SizedBox(height: 20),
          _section('Appearance'),
          _buildAppearanceCard(themeProvider, isDark),
          const SizedBox(height: 20),
          _section('About'),
          _buildAboutCard(isDark),
          const SizedBox(height: 20),
          AppButton(label: 'Sign Out', onTap: _logout, color: AppColors.accent),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildProfileHeader(user, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: AppColors.primaryLight, borderRadius: BorderRadius.circular(16)),
      child: Row(
        children: [
          Container(
            width: 56, height: 56,
            decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
            child: Center(child: Text(
              user?.name.isNotEmpty == true ? user!.name[0].toUpperCase() : 'U',
              style: GoogleFonts.inter(fontSize: 24, fontWeight: FontWeight.w800, color: Colors.white),
            )),
          ),
          const SizedBox(width: 14),
          Expanded(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(user?.name ?? 'User', style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.primaryDark)),
              Text(user?.email ?? '', style: GoogleFonts.inter(fontSize: 13, color: AppColors.primaryDark.withOpacity(0.7))),
              if (user?.emailVerified == true)
                Row(children: [
                  const Icon(Icons.verified, size: 14, color: AppColors.primary),
                  const SizedBox(width: 4),
                  Text('Verified', style: GoogleFonts.inter(fontSize: 11, color: AppColors.primary, fontWeight: FontWeight.w600)),
                ]),
            ],
          )),
        ],
      ),
    );
  }

  Widget _buildProfileForm(bool isDark) {
    return _card(isDark, Column(children: [
      AppTextField(controller: _nameCtrl, label: 'Name', hint: 'Your name', icon: Icons.person_outline),
      const SizedBox(height: 12),
      Row(children: [
        Expanded(child: AppTextField(controller: _weightCtrl, label: 'Weight (kg)', hint: '70', icon: Icons.monitor_weight_outlined, keyboardType: TextInputType.number)),
        const SizedBox(width: 12),
        Expanded(child: AppTextField(controller: _heightCtrl, label: 'Height (cm)', hint: '170', icon: Icons.height, keyboardType: TextInputType.number)),
      ]),
      const SizedBox(height: 12),
      Row(children: [
        Expanded(child: AppTextField(controller: _ageCtrl, label: 'Age', hint: '25', icon: Icons.cake_outlined, keyboardType: TextInputType.number)),
        const SizedBox(width: 12),
        Expanded(child: AppTextField(controller: _targetCtrl, label: 'Target (kg)', hint: '65', icon: Icons.flag_outlined, keyboardType: TextInputType.number)),
      ]),
    ]));
  }

  Widget _buildGoalsCard(user, bool isDark) {
    return _card(isDark, Column(children: [
      _infoRow('Daily Calories', '${user?.dailyCalorieGoal.toInt() ?? 2200} kcal', '🔥'),
      Divider(height: 16, color: AppColors.border.withOpacity(0.5)),
      _infoRow('Protein', '${user?.proteinGoal.toInt() ?? 150}g', '💪'),
      Divider(height: 16, color: AppColors.border.withOpacity(0.5)),
      _infoRow('Carbs', '${user?.carbsGoal.toInt() ?? 250}g', '🌾'),
      Divider(height: 16, color: AppColors.border.withOpacity(0.5)),
      _infoRow('Fat', '${user?.fatGoal.toInt() ?? 70}g', '🧈'),
      Divider(height: 16, color: AppColors.border.withOpacity(0.5)),
      _infoRow('Water', '${((user?.waterGoal ?? 2500) / 1000).toStringAsFixed(1)}L', '💧'),
    ]));
  }

  Widget _buildAppearanceCard(ThemeProvider tp, bool isDark) {
    return _card(isDark, Row(children: [
      Text(tp.isDark ? '🌙' : '☀️', style: const TextStyle(fontSize: 20)),
      const SizedBox(width: 12),
      Expanded(child: Text(tp.isDark ? 'Dark Mode' : 'Light Mode', style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w500))),
      Switch(value: tp.isDark, onChanged: (_) => tp.toggleTheme(), activeColor: AppColors.primary),
    ]));
  }

  Widget _buildAboutCard(bool isDark) {
    return _card(isDark, Row(children: [
      Container(width: 44, height: 44, decoration: BoxDecoration(color: AppColors.primaryLight, borderRadius: BorderRadius.circular(12)), child: const Center(child: Text('🥗', style: TextStyle(fontSize: 24)))),
      const SizedBox(width: 12),
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text.rich(TextSpan(children: [
          TextSpan(text: 'Pro', style: GoogleFonts.inter(fontWeight: FontWeight.w800, color: AppColors.primary)),
          TextSpan(text: 'Nutri', style: GoogleFonts.inter(fontWeight: FontWeight.w800)),
        ])),
        Text('Version 2.0.0', style: GoogleFonts.inter(fontSize: 11, color: AppColors.textSecondary)),
      ]),
    ]));
  }

  Widget _section(String title) => Padding(
    padding: const EdgeInsets.only(bottom: 8, left: 4),
    child: Text(title, style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.textSecondary, letterSpacing: 0.5)),
  );

  Widget _card(bool isDark, Widget child) => Container(
    padding: const EdgeInsets.all(16),
    margin: const EdgeInsets.only(bottom: 4),
    decoration: BoxDecoration(
      color: isDark ? AppColors.surfaceDark : AppColors.surface,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: isDark ? AppColors.borderDark : AppColors.border),
    ),
    child: child,
  );

  Widget _infoRow(String label, String val, String emoji) => Row(children: [
    Text(emoji, style: const TextStyle(fontSize: 18)),
    const SizedBox(width: 10),
    Expanded(child: Text(label, style: GoogleFonts.inter(fontSize: 14, color: AppColors.textSecondary))),
    Text(val, style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.primary)),
  ]);
}