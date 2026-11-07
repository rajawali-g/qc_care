class NetworkUsageData {
  final int todayMobileBytes;
  final int cycleMobileBytes;
  final int todayWifiBytes;
  final int cycleWifiBytes;
  final DateTime lastUpdated;

  NetworkUsageData({
    required this.todayMobileBytes,
    required this.cycleMobileBytes,
    required this.todayWifiBytes,
    required this.cycleWifiBytes,
    required this.lastUpdated,
  });

  factory NetworkUsageData.fromMap(Map<dynamic, dynamic> map) {
    return NetworkUsageData(
      todayMobileBytes: (map['todayMobileBytes'] as num?)?.toInt() ?? 0,
      cycleMobileBytes: (map['cycleMobileBytes'] as num?)?.toInt() ?? 0,
      todayWifiBytes: (map['todayWifiBytes'] as num?)?.toInt() ?? 0,
      cycleWifiBytes: (map['cycleWifiBytes'] as num?)?.toInt() ?? 0,
      lastUpdated: DateTime.now(),
    );
  }

  factory NetworkUsageData.empty() {
    return NetworkUsageData(
      todayMobileBytes: 0,
      cycleMobileBytes: 0,
      todayWifiBytes: 0,
      cycleWifiBytes: 0,
      lastUpdated: DateTime.now(),
    );
  }

  double get todayMobileGb => todayMobileBytes / (1024 * 1024 * 1024);
  double get todayMobileMb => todayMobileBytes / (1024 * 1024);

  double get cycleMobileGb => cycleMobileBytes / (1024 * 1024 * 1024);
  double get cycleMobileMb => cycleMobileBytes / (1024 * 1024);

  double get todayWifiGb => todayWifiBytes / (1024 * 1024 * 1024);
  double get todayWifiMb => todayWifiBytes / (1024 * 1024);

  double get cycleWifiGb => cycleWifiBytes / (1024 * 1024 * 1024);
  double get cycleWifiMb => cycleWifiBytes / (1024 * 1024);

  static String formatBytes(int bytes) {
    if (bytes < 1024) {
      return '$bytes B';
    } else if (bytes < 1024 * 1024) {
      final kb = bytes / 1024;
      return '${kb.toStringAsFixed(1)} KB';
    } else if (bytes < 1024 * 1024 * 1024) {
      final mb = bytes / (1024 * 1024);
      return '${mb.toStringAsFixed(1)} MB';
    } else {
      final gb = bytes / (1024 * 1024 * 1024);
      return '${gb.toStringAsFixed(2)} GB';
    }
  }
}

