/// Unit system helper — all internal storage is metric (kg, cm).
/// This class handles display conversion and input parsing per country.
class UnitHelper {
  static const _imperialCountries = {'USA', 'Myanmar', 'Liberia'};

  static bool isImperial(String country) => _imperialCountries.contains(country);

  static String weightUnit(String country) => isImperial(country) ? 'lbs' : 'kg';
  static String heightUnit(String country) => isImperial(country) ? 'ft' : 'cm';
  static String distanceUnit(String country) => isImperial(country) ? 'miles' : 'km';

  // ── Conversions ──────────────────────────────────────────────────────────────
  static double kgToLbs(double kg) => kg * 2.20462;
  static double lbsToKg(double lbs) => lbs / 2.20462;
  static double cmToFt(double cm) => cm / 30.48;
  static double ftToCm(double ft) => ft * 30.48;

  // ── Display strings (internal metric → user-facing) ──────────────────────────
  static String displayWeight(double kg, String country) {
    if (isImperial(country)) return '${kgToLbs(kg).toStringAsFixed(1)} lbs';
    return '${kg.toStringAsFixed(1)} kg';
  }

  static String displayHeight(double cm, String country) {
    if (isImperial(country)) {
      final totalFt = cm / 30.48;
      final ft = totalFt.floor();
      final inches = ((totalFt - ft) * 12).round();
      return "$ft' $inches\"";
    }
    return '${cm.toStringAsFixed(0)} cm';
  }

  // ── Input field metadata ─────────────────────────────────────────────────────
  static String weightHint(String country) => isImperial(country) ? '154 lbs' : '70 kg';
  static String heightHint(String country) => isImperial(country) ? '5.7 ft' : '170 cm';
  static String weightLabel(String country) => 'Weight (${weightUnit(country)})';
  static String heightLabel(String country) => 'Height (${heightUnit(country)})';
  static String targetWeightLabel(String country) => 'Target Weight (${weightUnit(country)})';

  /// Returns value ready for text field (metric → display unit, no suffix).
  static String weightForField(double kg, String country) {
    if (isImperial(country)) return kgToLbs(kg).toStringAsFixed(1);
    return kg.toStringAsFixed(1);
  }

  static String heightForField(double cm, String country) {
    if (isImperial(country)) return (cm / 30.48).toStringAsFixed(1);
    return cm.toStringAsFixed(0);
  }

  // ── Parse user input → internal metric ──────────────────────────────────────
  static double parseWeightToKg(String input, String country, {double fallback = 70}) {
    final val = double.tryParse(input) ?? fallback;
    return isImperial(country) ? lbsToKg(val) : val;
  }

  static double parseHeightToCm(String input, String country, {double fallback = 170}) {
    final val = double.tryParse(input) ?? fallback;
    return isImperial(country) ? ftToCm(val) : val;
  }
}
