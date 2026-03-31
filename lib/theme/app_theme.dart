import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  // ── ProNutri Brand Colors (from logo) ──────────────────────────
  static const brandGreen  = Color(0xFF2ECC71);
  static const brandBlue   = Color(0xFF1E6EBD);
  static const brandDark   = Color(0xFF155A9A);
  static const brandLight  = Color(0xFF4DD68C);

  // ── Semantic ───────────────────────────────────────────────────
  static const primary     = brandBlue;
  static const secondary   = brandGreen;
  static const accent      = Color(0xFFFF6B6B);
  static const amber       = Color(0xFFFFB830);
  static const purple      = Color(0xFF9B6DFF);

  // ── Light surfaces ─────────────────────────────────────────────
  static const bg          = Color(0xFFF4F7FC);
  static const surface     = Color(0xFFFFFFFF);
  static const surfaceVar  = Color(0xFFEEF3FA);
  static const border      = Color(0xFFDDE4F0);
  static const textPri     = Color(0xFF0D1B2A);
  static const textSec     = Color(0xFF5A6A7E);
  static const textHint    = Color(0xFFAAB8CC);

  // ── Tinted backgrounds ─────────────────────────────────────────
  static const greenBg     = Color(0xFFEAFAF1);
  static const blueBg      = Color(0xFFE8F0FB);
  static const amberBg     = Color(0xFFFFF8E7);
  static const accentBg    = Color(0xFFFFEEEE);
  static const purpleBg    = Color(0xFFF3EEFF);

  // ── Dark surfaces ──────────────────────────────────────────────
  static const bgDark      = Color(0xFF0A0F1A);
  static const surfDark    = Color(0xFF111827);
  static const surfVarDark = Color(0xFF1A2335);
  static const borderDark  = Color(0xFF253147);
  static const textPriDark = Color(0xFFF0F6FC);
  static const textSecDark = Color(0xFF8BA3BF);

  // ── Backward-compatibility aliases (used by all other screens) ─
  static const primaryLight        = blueBg;
  static const primaryDark         = brandDark;
  static const blue                = brandBlue;
  static const blueLight           = blueBg;
  static const accentLight         = accentBg;
  static const amberLight          = amberBg;
  static const purpleLight         = purpleBg;
  static const surfaceVariant      = surfaceVar;
  static const surfaceDark         = surfDark;
  static const surfaceVariantDark  = surfVarDark;
  static const textPrimary         = textPri;
  static const textPrimaryDark     = textPriDark;
  static const textSecondary       = textSec;
}

class AppTheme {
  static ThemeData light() => _build(Brightness.light);
  static ThemeData dark()  => _build(Brightness.dark);

  static ThemeData _build(Brightness b) {
    final isDark = b == Brightness.dark;
    final bg      = isDark ? AppColors.bgDark    : AppColors.bg;
    final surf    = isDark ? AppColors.surfDark  : AppColors.surface;
    final textPri = isDark ? AppColors.textPriDark : AppColors.textPri;
    final bord    = isDark ? AppColors.borderDark  : AppColors.border;

    return ThemeData(
      useMaterial3: true,
      brightness: b,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.brandBlue,
        brightness: b,
        primary:   AppColors.brandBlue,
        secondary: AppColors.brandGreen,
        background: bg,
        surface:   surf,
        onPrimary: Colors.white,
      ),
      scaffoldBackgroundColor: bg,
      textTheme: _txt(textPri),
      appBarTheme: AppBarTheme(
        backgroundColor: surf,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        centerTitle: false,
        titleTextStyle: GoogleFonts.inter(
          fontSize: 18, fontWeight: FontWeight.w800,
          color: textPri, letterSpacing: -0.3,
        ),
        iconTheme: IconThemeData(color: textPri),
      ),
      cardTheme: CardTheme(
        color: surf, elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: bord, width: 1),
        ),
        margin: EdgeInsets.zero,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: isDark ? AppColors.surfVarDark : AppColors.surfaceVar,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: bord, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.brandBlue, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.accent, width: 1),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.accent, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        hintStyle: GoogleFonts.inter(color: AppColors.textHint, fontSize: 14),
        labelStyle: GoogleFonts.inter(color: AppColors.textSec, fontSize: 14),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.brandBlue,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          padding: const EdgeInsets.symmetric(vertical: 16),
          textStyle: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w700),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.brandBlue,
          side: const BorderSide(color: AppColors.brandBlue, width: 1.5),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          padding: const EdgeInsets.symmetric(vertical: 16),
          textStyle: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w600),
        ),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: surf,
        selectedItemColor: AppColors.brandBlue,
        unselectedItemColor: isDark ? AppColors.textSecDark : AppColors.textHint,
        elevation: 0,
        type: BottomNavigationBarType.fixed,
      ),
      dividerTheme: DividerThemeData(color: bord, thickness: 1, space: 1),
      switchTheme: SwitchThemeData(
        thumbColor: MaterialStateProperty.resolveWith(
          (s) => s.contains(MaterialState.selected) ? AppColors.brandBlue : Colors.white,
        ),
        trackColor: MaterialStateProperty.resolveWith(
          (s) => s.contains(MaterialState.selected)
              ? AppColors.brandBlue.withOpacity(0.4)
              : bord,
        ),
      ),
    );
  }

  static TextTheme _txt(Color c) => TextTheme(
    displayLarge:   GoogleFonts.inter(fontSize: 32, fontWeight: FontWeight.w800, color: c, letterSpacing: -1),
    displayMedium:  GoogleFonts.inter(fontSize: 28, fontWeight: FontWeight.w700, color: c, letterSpacing: -0.5),
    headlineLarge:  GoogleFonts.inter(fontSize: 24, fontWeight: FontWeight.w700, color: c, letterSpacing: -0.5),
    headlineMedium: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.w600, color: c, letterSpacing: -0.3),
    titleLarge:     GoogleFonts.inter(fontSize: 17, fontWeight: FontWeight.w700, color: c),
    titleMedium:    GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w600, color: c),
    titleSmall:     GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: c),
    bodyLarge:      GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w400, color: c),
    bodyMedium:     GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w400, color: c),
    bodySmall:      GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w400, color: c),
    labelLarge:     GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: c),
    labelSmall:     GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w500, color: c),
  );
}