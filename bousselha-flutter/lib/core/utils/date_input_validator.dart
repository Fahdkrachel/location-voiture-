class DateInputValidator {
  DateInputValidator._();

  static const String dateFormatHint = 'AAAA-MM-JJ';
  static const String dateTimeGridHint = 'jour, mois, annee, heure et minute';

  static bool isValidIsoDate(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) return true;
    final match = RegExp(r'^(\d{4})-(\d{2})-(\d{2})$').firstMatch(trimmed);
    if (match == null) return false;

    final year = int.tryParse(match.group(1)!);
    final month = int.tryParse(match.group(2)!);
    final day = int.tryParse(match.group(3)!);
    if (year == null || month == null || day == null) return false;

    final parsed = DateTime(year, month, day);
    return parsed.year == year && parsed.month == month && parsed.day == day;
  }

  static String? validateOptionalIsoDate(String? value, String label) {
    final trimmed = value?.trim() ?? '';
    if (trimmed.isEmpty) return null;
    if (isValidIsoDate(trimmed)) return null;
    return '$label invalide. Utilisez le format $dateFormatHint, exemple 2026-06-11.';
  }

  static String? firstInvalidIsoDate(Map<String, String> fields) {
    for (final entry in fields.entries) {
      final error = validateOptionalIsoDate(entry.value, entry.key);
      if (error != null) return error;
    }
    return null;
  }
}
