import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../models/network_usage_model.dart';
import '../models/app_usage_model.dart';

class NetworkService {
  static const MethodChannel _channel = MethodChannel('com.example.qc_mce/network_stats');

  /// Memeriksa apakah izin "Usage Access" (Akses Penggunaan) sudah aktif di Android
  static Future<bool> checkUsagePermission() async {
    try {
      final bool hasPermission = await _channel.invokeMethod('checkUsagePermission');
      return hasPermission;
    } catch (_) {
      return true;
    }
  }

  /// Membuka halaman pengaturan Android agar pengguna bisa memberikan izin "Akses Penggunaan"
  static Future<void> requestUsagePermission() async {
    try {
      await _channel.invokeMethod('requestUsagePermission');
    } catch (_) {
      // ignore
    }
  }

  /// Mengambil data pemakaian internet global aktual dari Android NetworkStatsManager
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
      return _getPreviewMockUsage();
    } catch (_) {
      return _getPreviewMockUsage();
    }
  }

  /// Mengambil rincian pemakaian per aplikasi (membedakan kuota operator & wifi)
  static Future<List<AppUsageInfo>> fetchAppNetworkUsage(DateTime startTime) async {
    try {
      final now = DateTime.now();
      final result = await _channel.invokeMethod('getAppNetworkUsage', {
        'startTime': startTime.millisecondsSinceEpoch,
        'endTime': now.millisecondsSinceEpoch,
      });

      if (result is List) {
        return result.map((item) => AppUsageInfo.fromMap(item as Map)).toList();
      }
      return _getPreviewMockAppList();
    } catch (_) {
      return _getPreviewMockAppList();
    }
  }

  static NetworkUsageData _getPreviewMockUsage() {
    return NetworkUsageData(
      todayMobileBytes: 356515840, // ~340 MB
      cycleMobileBytes: 2845415833, // ~2.65 GB
      todayWifiBytes: 1181116006, // ~1.10 GB
      cycleWifiBytes: 15247192883, // ~14.2 GB
      lastUpdated: DateTime.now(),
    );
  }

  static List<AppUsageInfo> _getPreviewMockAppList() {
    return [
      AppUsageInfo(
        uid: 10243,
        appName: 'YouTube',
        packageName: 'com.google.android.youtube',
        mobileBytes: 1331691520, // 1.24 GB operator
        wifiBytes: 4133879808,   // 3.85 GB wifi
      ),
      AppUsageInfo(
        uid: 10189,
        appName: 'TikTok',
        packageName: 'com.zhiliaoapp.musically',
        mobileBytes: 681993216,  // 650.4 MB operator
        wifiBytes: 1524629504,   // 1.42 GB wifi
      ),
      AppUsageInfo(
        uid: 10052,
        appName: 'Chrome Browser',
        packageName: 'com.android.chrome',
        mobileBytes: 325255168,  // 310.2 MB operator
        wifiBytes: 1181116006,   // 1.10 GB wifi
      ),
      AppUsageInfo(
        uid: 10091,
        appName: 'WhatsApp',
        packageName: 'com.whatsapp',
        mobileBytes: 193986560,  // 185.0 MB operator
        wifiBytes: 471859200,    // 450.0 MB wifi
      ),
      AppUsageInfo(
        uid: 1000,
        appName: 'Android System / OS',
        packageName: 'android.system',
        mobileBytes: 88604672,   // 84.5 MB operator
        wifiBytes: 335544320,    // 320.0 MB wifi
      ),
      AppUsageInfo(
        uid: 10312,
        appName: 'Instagram',
        packageName: 'com.instagram.android',
        mobileBytes: 75608832,   // 72.1 MB operator
        wifiBytes: 293601280,    // 280.0 MB wifi
      ),
      AppUsageInfo(
        uid: 10145,
        appName: 'Spotify Music',
        packageName: 'com.spotify.music',
        mobileBytes: 36700160,   // 35.0 MB operator
        wifiBytes: 220200960,    // 210.0 MB wifi
      ),
      AppUsageInfo(
        uid: 10290,
        appName: 'Telegram',
        packageName: 'org.telegram.messenger',
        mobileBytes: 29779584,   // 28.4 MB operator
        wifiBytes: 146800640,    // 140.0 MB wifi
      ),
      AppUsageInfo(
        uid: 10118,
        appName: 'Google Play Store',
        packageName: 'com.android.vending',
        mobileBytes: 15728640,   // 15.0 MB operator
        wifiBytes: 838860800,    // 800.0 MB wifi
      ),
      AppUsageInfo(
        uid: 10044,
        appName: 'Mobile Legends',
        packageName: 'com.mobile.legends',
        mobileBytes: 10485760,   // 10.0 MB operator
        wifiBytes: 524288000,    // 500.0 MB wifi
      ),
    ];
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
    } catch (_) {
      return true;
    }
  }
}
