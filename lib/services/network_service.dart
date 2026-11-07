import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../models/network_usage_model.dart';

class NetworkService {
  static const MethodChannel _channel = MethodChannel('com.example.qc_mce/network_stats');

  /// Memeriksa apakah izin "Usage Access" (Akses Penggunaan) sudah aktif di Android
  static Future<bool> checkUsagePermission() async {
    try {
      final bool hasPermission = await _channel.invokeMethod('checkUsagePermission');
      return hasPermission;
    } on PlatformException {
      return false;
    }
  }

  /// Membuka halaman pengaturan Android agar pengguna bisa memberikan izin "Akses Penggunaan"
  static Future<void> requestUsagePermission() async {
    try {
      await _channel.invokeMethod('requestUsagePermission');
    } on PlatformException {
      // ignore or log
    }
  }

  /// Mengambil data pemakaian internet aktual dari Android NetworkStatsManager
  static Future<NetworkUsageData> fetchNetworkUsage(DateTime cycleStart) async {
    try {
      final now = DateTime.now();
      final todayMidnight = DateTime(now.year, now.month, now.day, 0, 0, 0);

      final result = await _channel.invokeMethod('getNetworkUsage', {
        'startToday': todayMidnight.millisecondsSinceEpoch,
        'startCycle': cycleStart.millisecondsSinceEpoch,
        'endTime': now.millisecondsSinceEpoch,
      });

      if (result is Map) {
        return NetworkUsageData.fromMap(result);
      }
      return NetworkUsageData.empty();
    } on PlatformException {
      return NetworkUsageData.empty();
    }
  }

  /// Memperbarui Widget di Layar Depan HP (Home Screen Widget)
  static Future<bool> syncHomeScreenWidget({
    required double totalQuotaGb,
    required double cycleUsedGb,
    required double todayUsedMb,
  }) async {
    try {
      final remainingGb = (totalQuotaGb - cycleUsedGb).clamp(0.0, totalQuotaGb);
      final percentRemaining = totalQuotaGb > 0 
          ? ((remainingGb / totalQuotaGb) * 100).round()
          : 0;

      final now = DateTime.now();
      final timeFormatter = DateFormat('HH:mm');
      final updatedTime = 'Update: ${timeFormatter.format(now)}';

      final todayStr = todayUsedMb >= 1024 
          ? 'Hari ini: ${(todayUsedMb / 1024).toStringAsFixed(2)} GB'
          : 'Hari ini: ${todayUsedMb.toStringAsFixed(0)} MB';

      final cycleStr = 'Total: ${cycleUsedGb.toStringAsFixed(2)} / ${totalQuotaGb.toStringAsFixed(1)} GB';

      final success = await _channel.invokeMethod('updateWidget', {
        'remainingQuota': '${remainingGb.toStringAsFixed(2)} GB',
        'percent': percentRemaining,
        'todayUsage': todayStr,
        'cycleUsage': cycleStr,
        'lastUpdated': updatedTime,
      });

      return success == true;
    } on PlatformException {
      return false;
    }
  }
}

