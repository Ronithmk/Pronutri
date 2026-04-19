import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import '../services/nutrition_provider.dart';
import '../services/auth_provider.dart';
import '../services/habit_provider.dart';
import '../theme/app_theme.dart';

class HealthReportScreen extends StatefulWidget {
  const HealthReportScreen({super.key});
  @override
  State<HealthReportScreen> createState() => _HealthReportScreenState();
}

class _HealthReportScreenState extends State<HealthReportScreen> {
  bool _generating = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final nutrition = context.watch<NutritionProvider>();
    final auth = context.read<AuthProvider>();
    final habits = context.read<HabitProvider>();
    final user = auth.currentUser;

    final avgCals = nutrition.weeklyCalories.isEmpty
        ? 0.0
        : nutrition.weeklyCalories.reduce((a, b) => a + b) / nutrition.weeklyCalories.length;
    final avgProtein = nutrition.todayProtein;
    final calorieGoal = user?.dailyCalorieGoal ?? 2000;
    final streak = habits.currentStreak;
    final level = habits.levelName;

    return Scaffold(
      backgroundColor: isDark ? AppColors.bgDark : AppColors.bg,
      appBar: AppBar(
        backgroundColor: isDark ? AppColors.surfDark : AppColors.surface,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        title: Text('Health Report',
            style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 18,
                color: isDark ? AppColors.textPriDark : AppColors.textPri)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _ReportPreviewCard(
            isDark: isDark,
            userName: user?.name ?? 'User',
            avgCals: avgCals,
            calorieGoal: calorieGoal.toDouble(),
            avgProtein: avgProtein,
            streak: streak,
            level: level,
            weeklyData: nutrition.weeklyCalories,
          ),
          const SizedBox(height: 20),
          _generating
              ? const Center(child: Padding(
                  padding: EdgeInsets.all(24),
                  child: CircularProgressIndicator(color: AppColors.brandBlue),
                ))
              : Column(children: [
                  _ActionButton(
                    label: 'Export PDF',
                    icon: Icons.picture_as_pdf_rounded,
                    color: AppColors.accent,
                    onTap: () => _exportPdf(context, nutrition, auth, habits),
                  ),
                  const SizedBox(height: 12),
                  _ActionButton(
                    label: 'Share Report',
                    icon: Icons.share_rounded,
                    color: AppColors.brandGreen,
                    onTap: () => _shareReport(context, nutrition, auth, habits),
                  ),
                  const SizedBox(height: 12),
                  _ActionButton(
                    label: 'Print Report',
                    icon: Icons.print_rounded,
                    color: AppColors.brandBlue,
                    onTap: () => _printReport(context, nutrition, auth, habits),
                  ),
                ]),
        ],
      ),
    );
  }

  Future<pw.Document> _buildPdf(
    NutritionProvider nutrition,
    AuthProvider auth,
    HabitProvider habits,
  ) async {
    final pdf = pw.Document();
    final user = auth.currentUser;
    final now = DateTime.now();

    final avgCals = nutrition.weeklyCalories.isEmpty
        ? 0.0
        : nutrition.weeklyCalories.reduce((a, b) => a + b) / nutrition.weeklyCalories.length;

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context ctx) => [
          pw.Header(
            level: 0,
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
                  pw.Text('ProNutri Health Report',
                      style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold,
                          color: PdfColor.fromHex('1E6EBD'))),
                  pw.Text('Generated: ${now.day}/${now.month}/${now.year}',
                      style: pw.TextStyle(fontSize: 10, color: PdfColor.fromHex('5A6A7E'))),
                ]),
                pw.Text(user?.name ?? 'User',
                    style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
              ],
            ),
          ),
          pw.SizedBox(height: 16),
          pw.Divider(),
          pw.SizedBox(height: 12),

          pw.Text('Nutrition Summary (This Week)',
              style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 8),
          pw.Table.fromTextArray(
            headers: ['Metric', 'Value'],
            data: [
              ['Avg Daily Calories', '${avgCals.toInt()} kcal'],
              ['Calorie Goal', '${user?.dailyCalorieGoal ?? 2000} kcal'],
              ['Today\'s Protein', '${nutrition.todayProtein.toInt()}g'],
              ['Today\'s Carbs', '${nutrition.todayCarbs.toInt()}g'],
              ['Today\'s Fat', '${nutrition.todayFat.toInt()}g'],
              ['Water Today', '${nutrition.todayWater} glasses'],
            ],
            cellStyle: const pw.TextStyle(fontSize: 11),
            headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 11,
                color: PdfColors.white),
            headerDecoration: const pw.BoxDecoration(color: PdfColor.fromInt(0xFF1E6EBD)),
            rowDecoration: const pw.BoxDecoration(
                border: pw.TableBorder(bottom: pw.BorderSide(color: PdfColors.grey300))),
          ),

          pw.SizedBox(height: 20),
          pw.Text('Weekly Calorie Chart',
              style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 8),
          if (nutrition.weeklyCalories.isNotEmpty)
            pw.Chart(
              left: pw.Container(
                alignment: pw.Alignment.topRight,
                margin: const pw.EdgeInsets.only(right: 5, top: 10),
                child: pw.Text('kcal', style: const pw.TextStyle(fontSize: 8)),
              ),
              grid: pw.CartesianGrid(
                xAxis: pw.FixedAxis.fromStrings(
                  List.generate(nutrition.weeklyCalories.length,
                      (i) => ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'][i % 7]),
                ),
                yAxis: pw.FixedAxis([0, 500, 1000, 1500, 2000, 2500, 3000],
                    format: (v) => '$v'),
              ),
              datasets: [
                pw.BarDataSet(
                  color: PdfColor.fromHex('2ECC71'),
                  width: 15,
                  data: nutrition.weeklyCalories.asMap().entries
                      .map((e) => pw.PointChartValue(e.key.toDouble(), e.value))
                      .toList(),
                ),
              ],
            ),

          pw.SizedBox(height: 20),
          pw.Text('Habit & Wellness',
              style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 8),
          pw.Table.fromTextArray(
            headers: ['Metric', 'Value'],
            data: [
              ['Current Streak', '${habits.currentStreak} days'],
              ['Level', habits.levelName],
              ['Badges Earned', '${habits.badges.length}'],
            ],
            cellStyle: const pw.TextStyle(fontSize: 11),
            headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 11,
                color: PdfColors.white),
            headerDecoration: const pw.BoxDecoration(color: PdfColor.fromInt(0xFF2ECC71)),
            rowDecoration: const pw.BoxDecoration(
                border: pw.TableBorder(bottom: pw.BorderSide(color: PdfColors.grey300))),
          ),

          pw.SizedBox(height: 24),
          pw.Divider(),
          pw.Text('Generated by ProNutri — Your Personal Nutrition & Fitness Companion',
              style: pw.TextStyle(fontSize: 8, color: PdfColor.fromHex('AAB8CC'))),
        ],
      ),
    );

    return pdf;
  }

  Future<void> _exportPdf(BuildContext context, NutritionProvider n, AuthProvider a, HabitProvider h) async {
    setState(() => _generating = true);
    try {
      final pdf = await _buildPdf(n, a, h);
      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/pronutri_report.pdf');
      await file.writeAsBytes(await pdf.save());
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('PDF saved to ${file.path}',
              style: GoogleFonts.inter(fontSize: 13)), backgroundColor: AppColors.brandGreen),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.accent),
        );
      }
    } finally {
      if (mounted) setState(() => _generating = false);
    }
  }

  Future<void> _shareReport(BuildContext context, NutritionProvider n, AuthProvider a, HabitProvider h) async {
    setState(() => _generating = true);
    try {
      final pdf = await _buildPdf(n, a, h);
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/pronutri_report.pdf');
      await file.writeAsBytes(await pdf.save());
      await Share.shareXFiles([XFile(file.path)], text: 'My ProNutri Health Report');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.accent),
        );
      }
    } finally {
      if (mounted) setState(() => _generating = false);
    }
  }

  Future<void> _printReport(BuildContext context, NutritionProvider n, AuthProvider a, HabitProvider h) async {
    setState(() => _generating = true);
    try {
      final pdf = await _buildPdf(n, a, h);
      await Printing.layoutPdf(onLayout: (_) async => pdf.save());
    } finally {
      if (mounted) setState(() => _generating = false);
    }
  }
}

class _ReportPreviewCard extends StatelessWidget {
  final bool isDark;
  final String userName, level;
  final double avgCals, calorieGoal, avgProtein;
  final int streak;
  final List<double> weeklyData;

  const _ReportPreviewCard({
    required this.isDark, required this.userName, required this.level,
    required this.avgCals, required this.calorieGoal, required this.avgProtein,
    required this.streak, required this.weeklyData,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfDark : AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isDark ? AppColors.borderDark : AppColors.border),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.brandBlue.withOpacity(0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.description_outlined, color: AppColors.brandBlue, size: 22),
          ),
          const SizedBox(width: 10),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Weekly Health Report',
                style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700,
                    color: isDark ? AppColors.textPriDark : AppColors.textPri)),
            Text(userName,
                style: GoogleFonts.inter(fontSize: 12,
                    color: isDark ? AppColors.textSecDark : AppColors.textSec)),
          ]),
        ]),
        const SizedBox(height: 16),
        const Divider(),
        const SizedBox(height: 12),
        _statRow('Avg Calories', '${avgCals.toInt()} kcal', AppColors.accent, isDark),
        _statRow('Calorie Goal', '${calorieGoal.toInt()} kcal', AppColors.brandBlue, isDark),
        _statRow('Avg Protein', '${avgProtein.toInt()}g', AppColors.brandGreen, isDark),
        _statRow('Habit Streak', '$streak days 🔥', AppColors.amber, isDark),
        _statRow('Level', level, AppColors.purple, isDark),
        const SizedBox(height: 4),
        if (weeklyData.isNotEmpty) _miniChart(weeklyData, isDark),
      ]),
    );
  }

  Widget _statRow(String label, String value, Color color, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(children: [
        Container(width: 4, height: 16, decoration: BoxDecoration(
            color: color, borderRadius: BorderRadius.circular(2))),
        const SizedBox(width: 8),
        Expanded(child: Text(label,
            style: GoogleFonts.inter(fontSize: 13,
                color: isDark ? AppColors.textSecDark : AppColors.textSec))),
        Text(value,
            style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w700,
                color: isDark ? AppColors.textPriDark : AppColors.textPri)),
      ]),
    );
  }

  Widget _miniChart(List<double> data, bool isDark) {
    final max = data.reduce((a, b) => a > b ? a : b);
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const SizedBox(height: 8),
      Text('This Week', style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600,
          color: isDark ? AppColors.textSecDark : AppColors.textSec)),
      const SizedBox(height: 6),
      SizedBox(
        height: 50,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: data.map((v) {
            final pct = max > 0 ? (v / max) : 0.0;
            return Expanded(child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2),
              child: Column(mainAxisAlignment: MainAxisAlignment.end, children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 400),
                  height: (pct * 40).clamp(3, 40),
                  decoration: BoxDecoration(
                    color: AppColors.brandGreen.withOpacity(0.7),
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ]),
            ));
          }).toList(),
        ),
      ),
    ]);
  }
}

class _ActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  const _ActionButton({required this.label, required this.icon, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 20),
      label: Text(label, style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w700)),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        elevation: 0,
        minimumSize: const Size(double.infinity, 52),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    );
  }
}
