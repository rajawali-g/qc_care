import 'network_usage_model.dart';

class AppUsageInfo {
  final int uid;
  final String appName;
  final String packageName;
  final int mobileBytes;
  final int wifiBytes;

  AppUsageInfo({
    required this.uid,
    required this.appName,
    required this.packageName,
    required this.mobileBytes,
    required this.wifiBytes,
  });

  factory AppUsageInfo.fromMap(Map<dynamic, dynamic> map) {
    return AppUsageInfo(
      uid: (map['uid'] as num?)?.toInt() ?? 0,
      appName: (map['appName'] as String?) ?? 'Unknown Process',
      packageName: (map['packageName'] as String?) ?? 'unknown',
      mobileBytes: (map['mobileBytes'] as num?)?.toInt() ?? 0,
      wifiBytes: (map['wifiBytes'] as num?)?.toInt() ?? 0,
    );
  }

  int get totalBytes => mobileBytes + wifiBytes;

  String get mobileFormatted => NetworkUsageData.formatBytes(mobileBytes);
  String get wifiFormatted => NetworkUsageData.formatBytes(wifiBytes);
  String get totalFormatted => NetworkUsageData.formatBytes(totalBytes);

  double get mobileMb => mobileBytes / (1024 * 1024);
  double get wifiMb => wifiBytes / (1024 * 1024);
  double get totalMb => totalBytes / (1024 * 1024);
}
