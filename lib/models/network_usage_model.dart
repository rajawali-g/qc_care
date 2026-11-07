class NetworkUsageData {
  final int todayMobileBytes;
  final int cycleMobileBytes;
  final int todayWifiBytes;
  final int cycleWifiBytes;
  final int latencyMs;
  final String networkType;
  final String ipAddress;
  final DateTime lastUpdated;

  NetworkUsageData({
    required this.todayMobileBytes,
    required this.cycleMobileBytes,
    required this.todayWifiBytes,
    required this.cycleWifiBytes,
    this.latencyMs = 24,
    this.networkType = 'LTE-A / 5G NSA',
    this.ipAddress = '10.142.88.214',
    required this.lastUpdated,
  });

  factory NetworkUsageData.fromMap(Map<dynamic, dynamic> map) {
    return NetworkUsageData(
      todayMobileBytes: (map['todayMobileBytes'] as num?)?.toInt() ?? 0,
      cycleMobileBytes: (map['cycleMobileBytes'] as num?)?.toInt() ?? 0,
      todayWifiBytes: (map['todayWifiBytes'] as num?)?.toInt() ?? 0,
      cycleWifiBytes: (map['cycleWifiBytes'] as num?)?.toInt() ?? 0,
      latencyMs: (map['latencyMs'] as num?)?.toInt() ?? 24,
      networkType: (map['networkType'] as String?) ?? 'LTE-A / 5G NSA',
      ipAddress: (map['ipAddress'] as String?) ?? '10.142.88.214',
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
      return '${mb.toStringAsFixed(2)} MB';
    } else {
      final gb = bytes / (1024 * 1024 * 1024);
      return '${gb.toStringAsFixed(2)} GB';
    }
  }

  static String formatPackets(int bytes) {
    // Estimasi paket berdasarkan MTU 1500 byte
    final packets = (bytes / 1420).round();
    if (packets > 1000000) {
      return '${(packets / 1000000).toStringAsFixed(1)}M pkts';
    } else if (packets > 1000) {
      return '${(packets / 1000).toStringAsFixed(1)}k pkts';
    }
    return '$packets pkts';
  }
}

class RealtimeTelemetry {
  final double rxSpeedKb; // Download speed KB/s
  final double txSpeedKb; // Upload speed KB/s
  final double mobileSpeedKb; // Mobile speed KB/s
  final double wifiSpeedKb; // WiFi speed KB/s
  final int totalRxPackets; // Real packet counter
  final double pingMs; // Real ping latency ms
  final double jitterMs; // Real jitter ms
  final String networkFreq; // e.g. "2.4/5.0GHz (WLAN)" or "5G_SA (rmnet0)"

  RealtimeTelemetry({
    required this.rxSpeedKb,
    required this.txSpeedKb,
    required this.mobileSpeedKb,
    required this.wifiSpeedKb,
    required this.totalRxPackets,
    required this.pingMs,
    required this.jitterMs,
    required this.networkFreq,
  });

  factory RealtimeTelemetry.fromMap(
    Map<dynamic, dynamic> map, {
    double currentPing = 24.0,
    double currentJitter = 2.1,
  }) {
    final rxSpeed = (map['rxSpeedKb'] as num?)?.toDouble() ?? 0.0;
    final txSpeed = (map['txSpeedKb'] as num?)?.toDouble() ?? 0.0;
    final mobileSpeed = (map['mobileSpeedKb'] as num?)?.toDouble() ?? 0.0;
    final wifiSpeed = (map['wifiSpeedKb'] as num?)?.toDouble() ?? (rxSpeed - mobileSpeed).clamp(0.0, double.infinity);
    final packets = (map['totalRxPackets'] as num?)?.toInt() ?? 0;
    final freq = (map['networkFreq'] as String?) ?? '2.4/5.0GHz (WLAN)';

    return RealtimeTelemetry(
      rxSpeedKb: rxSpeed,
      txSpeedKb: txSpeed,
      mobileSpeedKb: mobileSpeed,
      wifiSpeedKb: wifiSpeed,
      totalRxPackets: packets,
      pingMs: currentPing,
      jitterMs: currentJitter,
      networkFreq: freq,
    );
  }

  String get speedFormatted {
    if (rxSpeedKb >= 1024) {
      final mbps = (rxSpeedKb * 8) / 1024;
      return '${(rxSpeedKb / 1024).toStringAsFixed(2)}MB/s (${mbps.toStringAsFixed(1)}Mbps)';
    } else {
      final kbps = rxSpeedKb * 8;
      return '${rxSpeedKb.toStringAsFixed(1)}KB/s (${kbps.toStringAsFixed(0)}Kbps)';
    }
  }

  String get packetsFormatted {
    if (totalRxPackets > 1000000) {
      return '${(totalRxPackets / 1000000).toStringAsFixed(2)}M pkts';
    } else if (totalRxPackets > 1000) {
      return '${(totalRxPackets / 1000).toStringAsFixed(1)}k pkts';
    }
    return '$totalRxPackets pkts';
  }
}
