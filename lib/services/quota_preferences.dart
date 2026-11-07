import 'package:shared_preferences/shared_preferences.dart';

class QuotaPreferences {
  static const String keyTotalQuotaGb = 'qc_total_quota_gb';
  static const String keyCycleResetDay = 'qc_cycle_reset_day';
  static const String keyWarningThreshold = 'qc_warning_threshold';

  static Future<double> getTotalQuotaGb() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getDouble(keyTotalQuotaGb) ?? 15.0;
  }

  static Future<void> setTotalQuotaGb(double value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(keyTotalQuotaGb, value);
  }

  static Future<int> getCycleResetDay() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(keyCycleResetDay) ?? 1;
  }

  static Future<void> setCycleResetDay(int day) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(keyCycleResetDay, day);
  }

  static Future<int> getWarningThresholdPercent() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(keyWarningThreshold) ?? 20;
  }

  static Future<void> setWarningThresholdPercent(int percent) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(keyWarningThreshold, percent);
  }

  /// Menghitung tanggal mulai siklus kuota berdasarkan hari reset
  static DateTime getCycleStartDate(int resetDay) {
    final now = DateTime.now();
    DateTime cycleStart;

    if (now.day >= resetDay) {
      cycleStart = DateTime(now.year, now.month, resetDay, 0, 0, 0);
    } else {
      // Siklus dimulai bulan lalu
      final lastMonth = now.month == 1 ? 12 : now.month - 1;
      final year = now.month == 1 ? now.year - 1 : now.year;
      cycleStart = DateTime(year, lastMonth, resetDay, 0, 0, 0);
    }

    return cycleStart;
  }

  /// Menghitung berapa hari lagi menuju siklus berikutnya
  static int getDaysUntilNextReset(int resetDay) {
    final now = DateTime.now();
    DateTime nextReset;

    if (now.day < resetDay) {
      nextReset = DateTime(now.year, now.month, resetDay);
    } else {
      final nextMonth = now.month == 12 ? 1 : now.month + 1;
      final year = now.month == 12 ? now.year + 1 : now.year;
      nextReset = DateTime(year, nextMonth, resetDay);
    }

    return nextReset.difference(now).inDays + 1;
  }
}

