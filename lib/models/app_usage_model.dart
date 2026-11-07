import 'network_usage_model.dart';

class AppUsageInfo {
  final int uid;
  final String appName;
  final String packageName;
  final int mobileBytes;
  final int wifiBytes;
  final bool isLive;
  final double currentSpeedKbps; // Kecepatan transfer saat ini dalam KB/s (Kilobytes/sec)

  AppUsageInfo({
    required this.uid,
    required this.appName,
    required this.packageName,
    required this.mobileBytes,
    required this.wifiBytes,
    this.isLive = true,
    this.currentSpeedKbps = 0.0,
  });

  factory AppUsageInfo.fromMap(Map<dynamic, dynamic> map) {
    return AppUsageInfo(
      uid: (map['uid'] as num?)?.toInt() ?? 0,
      appName: (map['appName'] as String?) ?? 'Unknown Process',
      packageName: (map['packageName'] as String?) ?? 'unknown',
      mobileBytes: (map['mobileBytes'] as num?)?.toInt() ?? 0,
      wifiBytes: (map['wifiBytes'] as num?)?.toInt() ?? 0,
      isLive: (map['isLive'] as bool?) ?? true,
      currentSpeedKbps: ((map['currentSpeedKbps'] as num?)?.toDouble()) ?? 0.0,
    );
  }

  int get totalBytes => mobileBytes + wifiBytes;

  String get mobileFormatted => NetworkUsageData.formatBytes(mobileBytes);
  String get wifiFormatted => NetworkUsageData.formatBytes(wifiBytes);
  String get totalFormatted => NetworkUsageData.formatBytes(totalBytes);

  /// Menampilkan kecepatan transfer detik ini (KB/s atau MB/s)
  String get speedFormatted {
    if (!isLive || currentSpeedKbps <= 0) return 'IDLE 0 KB/s';
    if (currentSpeedKbps >= 1024) {
      return '⚡ ${(currentSpeedKbps / 1024).toStringAsFixed(1)} MB/s';
    }
    return '⚡ ${currentSpeedKbps.toStringAsFixed(0)} KB/s';
  }

  double get mobileMb => mobileBytes / (1024 * 1024);
  double get wifiMb => wifiBytes / (1024 * 1024);
  double get totalMb => totalBytes / (1024 * 1024);
}
