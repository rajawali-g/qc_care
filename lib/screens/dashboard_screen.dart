import 'package:flutter/material.dart';
import '../models/network_usage_model.dart';
import '../services/network_service.dart';
import '../services/quota_preferences.dart';
import 'widget_guide_dialog.dart';

class DashboardScreen extends StatefulWidget {
  final VoidCallback onOpenSettings;

  const DashboardScreen({super.key, required this.onOpenSettings});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> with WidgetsBindingObserver {
  bool _isLoading = true;
  bool _hasPermission = false;
  double _totalQuotaGb = 15.0;
  int _resetDay = 1;
  int _warningPercent = 20;
  NetworkUsageData _usageData = NetworkUsageData.empty();

  final List<String> _terminalLogs = [
    '[SYS_INIT] KERNEL_NETLINK_ESTABLISHED -> PID 3892',
    '[IFACE] rmnet_data0 -> STATUS_UP (LTE-A/5G)',
    '[DHCP] LEASE_ACQUIRED -> IP: 10.142.88.214/24',
    '[STAT] SYSTEM_USAGE_SYNC -> OK',
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _refreshAll();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _refreshAll();
    }
  }

  Future<void> _refreshAll() async {
    setState(() => _isLoading = true);

    final totalQuota = await QuotaPreferences.getTotalQuotaGb();
    final resetDay = await QuotaPreferences.getCycleResetDay();
    final warningPercent = await QuotaPreferences.getWarningThresholdPercent();
    final hasPerm = await NetworkService.checkUsagePermission();

    NetworkUsageData usage = NetworkUsageData.empty();
    if (hasPerm) {
      final cycleStart = QuotaPreferences.getCycleStartDate(resetDay);
      usage = await NetworkService.fetchNetworkUsage(cycleStart);

      await NetworkService.syncHomeScreenWidget(
        totalQuotaGb: totalQuota,
        cycleUsedGb: usage.cycleMobileGb,
        todayUsedMb: usage.todayMobileMb,
      );
    }

    if (mounted) {
      setState(() {
        _totalQuotaGb = totalQuota;
        _resetDay = resetDay;
        _warningPercent = warningPercent;
        _hasPermission = hasPerm;
        _usageData = usage;
        _isLoading = false;
        
        final now = DateTime.now();
        final timeStr = '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}:${now.second.toString().padLeft(2, '0')}';
        _terminalLogs.add('[$timeStr] TELEMETRY_REFRESH -> ${usage.cycleMobileGb.toStringAsFixed(2)}GB USED');
        if (_terminalLogs.length > 5) _terminalLogs.removeAt(0);
      });
    }
  }

  Future<void> _manualSyncWidget() async {
    final success = await NetworkService.syncHomeScreenWidget(
      totalQuotaGb: _totalQuotaGb,
      cycleUsedGb: _usageData.cycleMobileGb,
      todayUsedMb: _usageData.todayMobileMb,
    );

    if (mounted) {
      final now = DateTime.now();
      final timeStr = '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}:${now.second.toString().padLeft(2, '0')}';
      setState(() {
        _terminalLogs.add('[$timeStr] WIDGET_RPC_SYNC -> ${success ? "ACK_SUCCESS" : "ERROR"}');
        if (_terminalLogs.length > 5) _terminalLogs.removeAt(0);
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            success
                ? '>> [SUCCESS] WIDGET LAYAR DEPAN TELAH DISINKRONKAN'
                : '>> [ERR] GAGAL MEMPERBARUI WIDGET',
            style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
          ),
          backgroundColor: success ? const Color(0xFF00FF88).withOpacity(0.9) : const Color(0xFFFF2E63),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final usedGb = _usageData.cycleMobileGb;
    final remainingGb = (_totalQuotaGb - usedGb).clamp(0.0, _totalQuotaGb);
    final percentRemaining = _totalQuotaGb > 0
        ? ((remainingGb / _totalQuotaGb) * 100).clamp(0.0, 100.0)
        : 0.0;

    final daysRemaining = QuotaPreferences.getDaysUntilNextReset(_resetDay);

    Color neonColor;
    if (percentRemaining <= 10) {
      neonColor = const Color(0xFFFF2E63); // Cyber Red
    } else if (percentRemaining <= _warningPercent) {
      neonColor = const Color(0xFFFFB300); // Warning Amber
    } else {
      neonColor = const Color(0xFF00E5FF); // Neon Cyan
    }

    return Scaffold(
      backgroundColor: const Color(0xFF07090E),
      appBar: _buildTechAppBar(),
      body: _isLoading
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: Color(0xFF00E5FF)),
                  SizedBox(height: 12),
                  Text(
                    'ACQUIRING_NETWORK_TELEMETRY...',
                    style: TextStyle(fontFamily: 'monospace', color: Color(0xFF00E5FF), fontSize: 12),
                  ),
                ],
              ),
            )
          : RefreshIndicator(
              onRefresh: _refreshAll,
              color: const Color(0xFF00E5FF),
              backgroundColor: const Color(0xFF0F1523),
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // System Status Strip
                    _buildSystemStatusStrip(),

                    const SizedBox(height: 12),

                    if (!_hasPermission) ...[
                      _buildTechPermissionAlert(),
                      const SizedBox(height: 12),
                    ],

                    // Main HUD Cyber Card
                    _buildCyberHudCard(
                      remainingGb: remainingGb,
                      percentRemaining: percentRemaining,
                      usedGb: usedGb,
                      daysRemaining: daysRemaining,
                      neonColor: neonColor,
                    ),

                    const SizedBox(height: 14),

                    // Home Screen Widget Controller Bar
                    _buildWidgetCyberPill(),

                    const SizedBox(height: 16),

                    // Section Title
                    Row(
                      children: [
                        Container(width: 3, height: 14, color: const Color(0xFF00E5FF)),
                        const SizedBox(width: 8),
                        const Text(
                          'TELEMETRY_PACKETS_BREAKDOWN',
                          style: TextStyle(
                            fontFamily: 'monospace',
                            color: Color(0xFF90CAF9),
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.0,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 10),

                    // 2x2 Tech Matrix
                    Row(
                      children: [
                        Expanded(
                          child: _buildCyberMetricCard(
                            tag: 'RX // CELLULAR_TODAY',
                            value: NetworkUsageData.formatBytes(_usageData.todayMobileBytes),
                            subtitle: NetworkUsageData.formatPackets(_usageData.todayMobileBytes),
                            accentColor: const Color(0xFF00E5FF),
                            icon: Icons.download_rounded,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _buildCyberMetricCard(
                            tag: 'TOTAL // CELLULAR_CYCLE',
                            value: NetworkUsageData.formatBytes(_usageData.cycleMobileBytes),
                            subtitle: 'Limit: ${_totalQuotaGb.toStringAsFixed(1)} GB',
                            accentColor: const Color(0xFF00FF88),
                            icon: Icons.pie_chart_outline_rounded,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: _buildCyberMetricCard(
                            tag: 'WLAN // 802.11 TODAY',
                            value: NetworkUsageData.formatBytes(_usageData.todayWifiBytes),
                            subtitle: NetworkUsageData.formatPackets(_usageData.todayWifiBytes),
                            accentColor: const Color(0xFFB388FF),
                            icon: Icons.wifi_tethering_rounded,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _buildCyberMetricCard(
                            tag: 'TOTAL // WLAN_PAYLOAD',
                            value: NetworkUsageData.formatBytes(_usageData.cycleWifiBytes),
                            subtitle: 'Unmetered Interface',
                            accentColor: const Color(0xFFFFB300),
                            icon: Icons.lan_rounded,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    // Terminal Live Feed
                    _buildTerminalConsole(),
                  ],
                ),
              ),
            ),
    );
  }

  PreferredSizeWidget _buildTechAppBar() {
    return AppBar(
      backgroundColor: const Color(0xFF090D15),
      elevation: 0,
      titleSpacing: 14,
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFF00E5FF).withOpacity(0.12),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: const Color(0xFF00E5FF).withOpacity(0.4)),
            ),
            child: const Text(
              'QC_MCE',
              style: TextStyle(
                fontFamily: 'monospace',
                fontSize: 13,
                fontWeight: FontWeight.w900,
                color: Color(0xFF00E5FF),
                letterSpacing: 1.2,
              ),
            ),
          ),
          const SizedBox(width: 10),
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'NET_OPERATIONS_CENTER',
                style: TextStyle(fontFamily: 'monospace', fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white),
              ),
              Text(
                'SYSTEM_METRICS // v1.0.2',
                style: TextStyle(fontFamily: 'monospace', fontSize: 9, color: Color(0xFF546E7A)),
              ),
            ],
          ),
        ],
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.refresh_rounded, color: Color(0xFF00E5FF), size: 20),
          tooltip: 'Sync Data',
          onPressed: _refreshAll,
        ),
        IconButton(
          icon: const Icon(Icons.tune_rounded, color: Color(0xFF90A4AE), size: 20),
          tooltip: 'Configure',
          onPressed: widget.onOpenSettings,
        ),
      ],
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Container(
          height: 1,
          color: const Color(0xFF1B2333),
        ),
      ),
    );
  }

  Widget _buildSystemStatusStrip() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF0D121D),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFF1B2438)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                width: 7,
                height: 7,
                decoration: const BoxDecoration(
                  color: Color(0xFF00FF88),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(color: Color(0xFF00FF88), blurRadius: 6, spreadRadius: 1),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'LINK: ONLINE [${_usageData.networkType}]',
                style: const TextStyle(fontFamily: 'monospace', color: Color(0xFF00FF88), fontSize: 10, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          Row(
            children: [
              const Icon(Icons.speed_rounded, color: Color(0xFF00E5FF), size: 12),
              const SizedBox(width: 4),
              Text(
                'LATENCY: ${_usageData.latencyMs}ms',
                style: const TextStyle(fontFamily: 'monospace', color: Color(0xFF80D8FF), fontSize: 10),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCyberHudCard({
    required double remainingGb,
    required double percentRemaining,
    required double usedGb,
    required int daysRemaining,
    required Color neonColor,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF0C101A),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: neonColor.withOpacity(0.35), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: neonColor.withOpacity(0.08),
            blurRadius: 20,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(Icons.radar_rounded, color: neonColor, size: 18),
                  const SizedBox(width: 8),
                  const Text(
                    'PAYLOAD // QUOTA_REMAINING',
                    style: TextStyle(
                      fontFamily: 'monospace',
                      color: Color(0xFFCFD8DC),
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.8,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: neonColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: neonColor.withOpacity(0.5)),
                ),
                child: Text(
                  '${percentRemaining.toStringAsFixed(0)}% CAPACITY',
                  style: TextStyle(
                    fontFamily: 'monospace',
                    color: neonColor,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          // Big Tech Readout
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                remainingGb.toStringAsFixed(2),
                style: TextStyle(
                  fontFamily: 'monospace',
                  color: Colors.white,
                  fontSize: 42,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -1.0,
                  shadows: [
                    Shadow(color: neonColor.withOpacity(0.6), blurRadius: 10),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              Text(
                'GB',
                style: TextStyle(
                  fontFamily: 'monospace',
                  color: neonColor,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'TOTAL: ${_totalQuotaGb.toStringAsFixed(1)} GB',
                    style: const TextStyle(fontFamily: 'monospace', color: Color(0xFF90A4AE), fontSize: 11),
                  ),
                  Text(
                    'CONSUMED: ${usedGb.toStringAsFixed(2)} GB',
                    style: TextStyle(fontFamily: 'monospace', color: neonColor.withOpacity(0.8), fontSize: 11),
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 14),

          // Cyber Segmented Progress Bar
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: (percentRemaining / 100).clamp(0.0, 1.0),
                  backgroundColor: const Color(0xFF161F30),
                  color: neonColor,
                  minHeight: 8,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'CYCLE_EXPIRE: T-$daysRemaining DAYS',
                    style: const TextStyle(fontFamily: 'monospace', color: Color(0xFF78909C), fontSize: 10),
                  ),
                  Text(
                    'STATUS: ${percentRemaining <= 10 ? "CRITICAL" : (percentRemaining <= 20 ? "ALERT" : "NOMINAL")}',
                    style: TextStyle(fontFamily: 'monospace', color: neonColor, fontSize: 10, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildWidgetCyberPill() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF0C101A),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF1A2338)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color: const Color(0xFF00E5FF).withOpacity(0.12),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFF00E5FF).withOpacity(0.3)),
            ),
            child: const Icon(Icons.widgets_rounded, color: Color(0xFF00E5FF), size: 18),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'ANDROID_HOMESCREEN_WIDGET',
                  style: TextStyle(fontFamily: 'monospace', color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                ),
                Text(
                  'Active background provider & telemetric sync',
                  style: TextStyle(color: Color(0xFF78909C), fontSize: 10),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => const WidgetGuideDialog(),
              );
            },
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              foregroundColor: const Color(0xFF80D8FF),
            ),
            child: const Text('GUIDE', style: TextStyle(fontFamily: 'monospace', fontSize: 11, fontWeight: FontWeight.bold)),
          ),
          FilledButton(
            onPressed: _manualSyncWidget,
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF00E5FF),
              foregroundColor: Colors.black,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
            ),
            child: const Text('SYNC', style: TextStyle(fontFamily: 'monospace', fontSize: 11, fontWeight: FontWeight.w900)),
          ),
        ],
      ),
    );
  }

  Widget _buildCyberMetricCard({
    required String tag,
    required String value,
    required String subtitle,
    required Color accentColor,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF0A0E18),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF182236)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                tag,
                style: const TextStyle(
                  fontFamily: 'monospace',
                  color: Color(0xFF78909C),
                  fontSize: 9,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
              Icon(icon, color: accentColor, size: 14),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontFamily: 'monospace',
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w800,
              shadows: [
                Shadow(color: accentColor.withOpacity(0.3), blurRadius: 4),
              ],
            ),
          ),
          const SizedBox(height: 3),
          Text(
            subtitle,
            style: TextStyle(
              fontFamily: 'monospace',
              color: accentColor.withOpacity(0.8),
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTerminalConsole() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF05080D),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFF162030)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.terminal_rounded, color: Color(0xFF00FF88), size: 14),
              SizedBox(width: 6),
              Text(
                'CONSOLE_OUTPUT // LIVE_EVENT_LOG',
                style: TextStyle(
                  fontFamily: 'monospace',
                  color: Color(0xFF00FF88),
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ..._terminalLogs.map(
            (log) => Padding(
              padding: const EdgeInsets.only(bottom: 3),
              child: Text(
                '>> $log',
                style: const TextStyle(
                  fontFamily: 'monospace',
                  color: Color(0xFF90A4AE),
                  fontSize: 10,
                  height: 1.3,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTechPermissionAlert() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1308),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFFFB300).withOpacity(0.5)),
      ),
      child: Row(
        children: [
          const Icon(Icons.warning_amber_rounded, color: Color(0xFFFFB300), size: 22),
          const SizedBox(width: 10),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'PERM_DENIED: PACKAGE_USAGE_STATS',
                  style: TextStyle(fontFamily: 'monospace', color: Color(0xFFFFE082), fontWeight: FontWeight.bold, fontSize: 11),
                ),
                Text(
                  'Aktifkan akses penggunaan agar pembacaan byte data akurat.',
                  style: TextStyle(color: Color(0xFFFFD54F), fontSize: 10),
                ),
              ],
            ),
          ),
          FilledButton(
            onPressed: () => NetworkService.requestUsagePermission(),
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFFFB300),
              foregroundColor: Colors.black,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
            ),
            child: const Text('GRANT', style: TextStyle(fontFamily: 'monospace', fontWeight: FontWeight.bold, fontSize: 11)),
          ),
        ],
      ),
    );
  }
}
