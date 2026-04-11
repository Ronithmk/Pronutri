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
  static const bg          = Color(0xFFEFF3FB);
  static const surface     = Color(0xFFFFFFFF);
  static const surfaceVar  = Color(0xFFE8EFFA);
  static const border      = Color(0xFFDDE4F0);
  static const textPri     = Color(0xFF0D1B2A);
  static const textSec     = Color(0xFF5A6A7E);
  static const textHint    = Color(0xFFAAB8CC);

  // ── Tinted backgrounds ─────────────────────────────────────────
  static const greenBg     = Color(0xFFE3FAF0);
  static const blueBg      = Color(0xFFE3EEF9);
  static const amberBg     = Color(0xFFFFF5E0);
  static const accentBg    = Color(0xFFFFECEC);
  static const purpleBg    = Color(0xFFF0EAFF);

  // ── Dark surfaces ──────────────────────────────────────────────
  static const bgDark      = Color(0xFF080E1A);
  static const surfDark    = Color(0xFF0F1826);
  static const surfVarDark = Color(0xFF172035);
  static const borderDark  = Color(0xFF223050);
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

// ── Claymorphism helpers ──────────────────────────────────────────────────────
class Clay {
  /// Standard clay card decoration
  static BoxDecoration card({
    required bool isDark,
    Color? color,
    double radius = 28,
    Color? shadowColor,
  }) {
    final base = color ?? (isDark ? AppColors.surfDark : AppColors.surface);
    final shadow = shadowColor ?? (isDark ? Colors.black : AppColors.brandBlue);
    return BoxDecoration(
      color: base,
      borderRadius: BorderRadius.circular(radius),
      boxShadow: [
        BoxShadow(
          color: shadow.withOpacity(isDark ? 0.5 : 0.10),
          blurRadius: 24,
          spreadRadius: -2,
          offset: const Offset(0, 10),
        ),
        BoxShadow(
          color: (isDark ? Colors.white : Colors.white).withOpacity(isDark ? 0.04 : 0.85),
          blurRadius: 6,
          spreadRadius: -2,
          offset: const Offset(-2, -2),
        ),
      ],
    );
  }

  /// Gradient clay card decoration (for hero / banner cards)
  static BoxDecoration gradientCard({
    required bool isDark,
    required List<Color> colors,
    double radius = 28,
    Color? shadowColor,
  }) {
    final shadow = shadowColor ?? colors.first;
    return BoxDecoration(
      gradient: LinearGradient(
        colors: colors,
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      borderRadius: BorderRadius.circular(radius),
      boxShadow: [
        BoxShadow(
          color: shadow.withOpacity(0.30),
          blurRadius: 28,
          spreadRadius: -4,
          offset: const Offset(0, 12),
        ),
        BoxShadow(
          color: Colors.white.withOpacity(isDark ? 0.04 : 0.25),
          blurRadius: 8,
          spreadRadius: -2,
          offset: const Offset(-2, -2),
        ),
      ],
    );
  }

  /// Small pill / chip decoration
  static BoxDecoration pill({
    required Color color,
    double opacity = 0.12,
    double radius = 20,
  }) {
    return BoxDecoration(
      color: color.withOpacity(opacity),
      borderRadius: BorderRadius.circular(radius),
      boxShadow: [
        BoxShadow(
          color: color.withOpacity(0.10),
          blurRadius: 6,
          offset: const Offset(0, 3),
        ),
      ],
    );
  }

  /// Icon container decoration
  static BoxDecoration icon({
    required Color color,
    double radius = 14,
    bool isDark = false,
  }) {
    return BoxDecoration(
      color: color.withOpacity(isDark ? 0.20 : 0.12),
      borderRadius: BorderRadius.circular(radius),
      boxShadow: [
        BoxShadow(
          color: color.withOpacity(0.15),
          blurRadius: 8,
          offset: const Offset(0, 4),
        ),
      ],
    );
  }
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
          borderRadius: BorderRadius.circular(28),
        ),
        margin: EdgeInsets.zero,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: isDark ? AppColors.surfVarDark : AppColors.surfaceVar,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(color: bord, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: AppColors.brandBlue, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: AppColors.accent, width: 1),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: AppColors.accent, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        hintStyle: GoogleFonts.inter(color: AppColors.textHint, fontSize: 14),
        labelStyle: GoogleFonts.inter(color: AppColors.textSec, fontSize: 14),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.brandBlue,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          padding: const EdgeInsets.symmetric(vertical: 16),
          textStyle: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w700),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.brandBlue,
          side: const BorderSide(color: AppColors.brandBlue, width: 1.5),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
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
        thumbColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected) ? AppColors.brandBlue : Colors.white,
        ),
        trackColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected)
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
