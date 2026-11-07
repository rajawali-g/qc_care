import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../models/network_usage_model.dart';
import '../models/app_usage_model.dart';
import '../services/network_service.dart';
import '../services/quota_preferences.dart';
import 'widget_guide_dialog.dart';

enum FilterMode { all, cellOnly, wifiOnly }

class DashboardScreen extends StatefulWidget {
  final VoidCallback onOpenSettings;

  const DashboardScreen({super.key, required this.onOpenSettings});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen>
    with TickerProviderStateMixin, WidgetsBindingObserver {
  bool _isLoading = true;
  bool _hasPermission = false;
  double _totalQuotaGb = 15.0;
  int _resetDay = 1;
  int _warningPercent = 20;
  NetworkUsageData _usageData = NetworkUsageData.empty();
  List<AppUsageInfo> _appList = [];
  FilterMode _filterMode = FilterMode.all;

  late AnimationController _waveController;
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2500),
    )..repeat();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);

    _refreshAll();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _waveController.dispose();
    _pulseController.dispose();
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

    final cycleStart = QuotaPreferences.getCycleStartDate(resetDay);
    final usage = await NetworkService.fetchNetworkUsage(cycleStart);
    final apps = await NetworkService.fetchAppNetworkUsage(cycleStart);

    await NetworkService.syncHomeScreenWidget(
      totalQuotaGb: totalQuota,
      cycleUsedGb: usage.cycleMobileGb,
      todayUsedMb: usage.todayMobileMb,
    );

    if (mounted) {
      setState(() {
        _totalQuotaGb = totalQuota;
        _resetDay = resetDay;
        _warningPercent = warningPercent;
        _hasPermission = hasPerm;
        _usageData = usage;
        _appList = apps;
        _isLoading = false;
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            success
                ? 'root@QC-MCE:~# [PACKET_INJECT] WIDGET_SYNC_ACKNOWLEDGED -> 0x00_SUCCESS'
                : 'root@QC-MCE:~# [ERR_INJECT] WIDGET_RPC_FAIL',
            style: const TextStyle(fontFamily: 'monospace', color: Color(0xFF00FF41)),
          ),
          backgroundColor: Colors.black,
          shape: Border.all(color: const Color(0xFF00FF41)),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  List<AppUsageInfo> get _filteredApps {
    var list = List<AppUsageInfo>.from(_appList);
    if (_filterMode == FilterMode.cellOnly) {
      list.sort((a, b) => b.mobileBytes.compareTo(a.mobileBytes));
    } else if (_filterMode == FilterMode.wifiOnly) {
      list.sort((a, b) => b.wifiBytes.compareTo(a.wifiBytes));
    } else {
      list.sort((a, b) => b.totalBytes.compareTo(a.totalBytes));
    }
    return list;
  }

  @override
  Widget build(BuildContext context) {
    final usedGb = _usageData.cycleMobileGb;
    final remainingGb = (_totalQuotaGb - usedGb).clamp(0.0, _totalQuotaGb);
    final percentRemaining = _totalQuotaGb > 0
        ? ((remainingGb / _totalQuotaGb) * 100).clamp(0.0, 100.0)
        : 0.0;
    final daysRemaining = QuotaPreferences.getDaysUntilNextReset(_resetDay);

    return Scaffold(
      backgroundColor: const Color(0xFF020402), // Pitch Hacker Black
      appBar: _buildHackerConsoleAppBar(),
      body: _isLoading
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: Color(0xFF00FF41)),
                  SizedBox(height: 14),
                  Text(
                    '>> INITIALIZING_PACKET_SNIFFER...',
                    style: TextStyle(fontFamily: 'monospace', color: Color(0xFF00FF41), fontSize: 12),
                  ),
                ],
              ),
            )
          : RefreshIndicator(
              onRefresh: _refreshAll,
              color: const Color(0xFF00FF41),
              backgroundColor: Colors.black,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Hacker Terminal Banner
                    _buildHackerBanner(),

                    if (!_hasPermission) ...[
                      const SizedBox(height: 10),
                      _buildHackerPermissionAlert(),
                    ],

                    const SizedBox(height: 10),

                    // ANIMATED OSCILLOSCOPE / QUOTA WAVEFORM GRAPH
                    _buildAnimatedTelemetryGraph(remainingGb, percentRemaining),

                    const SizedBox(height: 12),

                    // Quota Metrics HUD Box
                    _buildHackerQuotaHud(remainingGb, percentRemaining, usedGb, daysRemaining),

                    const SizedBox(height: 12),

                    // Filter Mode Switcher
                    _buildHackerFilterBar(),

                    const SizedBox(height: 12),

                    // Per-App Live Sniffer Table (Operator vs WiFi)
                    _buildHackerProcessTable(),

                    const SizedBox(height: 14),

                    // Hacker Prompt Footer
                    _buildTerminalPromptFooter(),
                  ],
                ),
              ),
            ),
    );
  }

  PreferredSizeWidget _buildHackerConsoleAppBar() {
    return AppBar(
      backgroundColor: const Color(0xFF050805),
      elevation: 0,
      titleSpacing: 10,
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.black,
              border: Border.all(color: const Color(0xFF00FF41)),
              borderRadius: BorderRadius.circular(4),
              boxShadow: [
                BoxShadow(color: const Color(0xFF00FF41).withOpacity(0.3), blurRadius: 6),
              ],
            ),
            child: const Text(
              'QC://ROOT',
              style: TextStyle(fontFamily: 'monospace', color: Color(0xFF00FF41), fontWeight: FontWeight.w900, fontSize: 11),
            ),
          ),
          const SizedBox(width: 8),
          const Expanded(
            child: Text(
              'TERMINAL // NETWORK_INTRUSION_MONITOR',
              style: TextStyle(fontFamily: 'monospace', fontSize: 11, color: Color(0xFF00FF41), fontWeight: FontWeight.bold),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.refresh, color: Color(0xFF00FF41), size: 18),
          tooltip: 'Sniff Reload',
          onPressed: _refreshAll,
        ),
        IconButton(
          icon: const Icon(Icons.widgets_outlined, color: Color(0xFF00FF41), size: 18),
          tooltip: 'Widget Guide',
          onPressed: () {
            showDialog(context: context, builder: (_) => const WidgetGuideDialog());
          },
        ),
        IconButton(
          icon: const Icon(Icons.tune, color: Color(0xFF008F11), size: 18),
          tooltip: 'Configuration',
          onPressed: widget.onOpenSettings,
        ),
      ],
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Container(height: 1, color: const Color(0xFF003B00)),
      ),
    );
  }

  Widget _buildHackerBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFF030703),
        border: Border.all(color: const Color(0xFF005500)),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              AnimatedBuilder(
                animation: _pulseController,
                builder: (context, child) {
                  return Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color(0xFF00FF41),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF00FF41).withOpacity(_pulseController.value),
                          blurRadius: 8,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                  );
                },
              ),
              const SizedBox(width: 8),
              const Text(
                'LIVE_SNIFFER: rmnet0 (CELLULAR) | wlan0 (WIFI) [ACTIVE]',
                style: TextStyle(fontFamily: 'monospace', color: Color(0xFF00FF41), fontSize: 10, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 4),
          const Text(
            'root@QC-MCE:~# tcpdump -i any -q --quota-operator --wifi-stream',
            style: TextStyle(fontFamily: 'monospace', color: Color(0xFF008F11), fontSize: 10),
          ),
        ],
      ),
    );
  }

  /// ANIMATED OSCILLOSCOPE GRAPH
  Widget _buildAnimatedTelemetryGraph(double remainingGb, double percentRemaining) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFF030803),
        border: Border.all(color: const Color(0xFF00FF41).withOpacity(0.6)),
        borderRadius: BorderRadius.circular(6),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF00FF41).withOpacity(0.08),
            blurRadius: 15,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                '>> [LIVE_BANDWIDTH_SPECTRUM // OSCILLOSCOPE]',
                style: TextStyle(fontFamily: 'monospace', color: Color(0xFF00FF41), fontSize: 10, fontWeight: FontWeight.bold),
              ),
              Row(
                children: [
                  Container(width: 8, height: 8, color: const Color(0xFF00FF41)),
                  const SizedBox(width: 4),
                  const Text('OPERATOR', style: TextStyle(fontFamily: 'monospace', color: Color(0xFF00FF41), fontSize: 9)),
                  const SizedBox(width: 8),
                  Container(width: 8, height: 8, color: const Color(0xFF00E5FF)),
                  const SizedBox(width: 4),
                  const Text('WIFI', style: TextStyle(fontFamily: 'monospace', color: Color(0xFF00E5FF), fontSize: 9)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Custom Oscilloscope Canvas
          SizedBox(
            height: 90,
            width: double.infinity,
            child: AnimatedBuilder(
              animation: _waveController,
              builder: (context, child) {
                return CustomPaint(
                  painter: _CyberWaveformPainter(
                    animationValue: _waveController.value,
                    cellLoadRatio: (_usageData.todayMobileMb / 1000).clamp(0.2, 1.0),
                    wifiLoadRatio: (_usageData.todayWifiMb / 2000).clamp(0.2, 1.0),
                  ),
                );
              },
            ),
          ),

          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'FREQ: 2.4/5.0GHz // RX_PACKETS: ${NetworkUsageData.formatPackets(_usageData.todayMobileBytes)}',
                style: const TextStyle(fontFamily: 'monospace', color: Color(0xFF008F11), fontSize: 9),
              ),
              const Text(
                'SPEED: 100Mbps // JITTER: 2.1ms',
                style: TextStyle(fontFamily: 'monospace', color: Color(0xFF00FF41), fontSize: 9),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHackerQuotaHud(
    double remainingGb,
    double percentRemaining,
    double usedGb,
    int daysRemaining,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF010401),
        border: Border.all(color: const Color(0xFF008F11)),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'QUOTA_STATUS: ${percentRemaining <= 10 ? "[CRITICAL_DEPLETION]" : (percentRemaining <= _warningPercent ? "[WARNING_THRESHOLD]" : "[OPTIMAL_INJECTION]")}',
                style: TextStyle(
                  fontFamily: 'monospace',
                  color: percentRemaining <= 10
                      ? const Color(0xFFFF2222)
                      : (percentRemaining <= _warningPercent ? const Color(0xFFFFB300) : const Color(0xFF00FF41)),
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                'RESET: T-$daysRemaining DAYS (DAY $_resetDay)',
                style: const TextStyle(fontFamily: 'monospace', color: Color(0xFF00E5FF), fontSize: 10),
              ),
            ],
          ),
          const SizedBox(height: 8),

          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                remainingGb.toStringAsFixed(2),
                style: TextStyle(
                  fontFamily: 'monospace',
                  color: const Color(0xFF00FF41),
                  fontSize: 34,
                  fontWeight: FontWeight.w900,
                  shadows: [
                    Shadow(color: const Color(0xFF00FF41).withOpacity(0.8), blurRadius: 10),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              const Text('GB_REMAINING', style: TextStyle(fontFamily: 'monospace', color: Color(0xFF008F11), fontSize: 13, fontWeight: FontWeight.bold)),
              const Spacer(),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('LIMIT: ${_totalQuotaGb.toStringAsFixed(1)} GB', style: const TextStyle(fontFamily: 'monospace', color: Color(0xFF558855), fontSize: 10)),
                  Text('CELL: ${usedGb.toStringAsFixed(2)} GB', style: const TextStyle(fontFamily: 'monospace', color: Color(0xFF00FF41), fontSize: 11, fontWeight: FontWeight.bold)),
                  Text('WIFI: ${_usageData.cycleWifiGb.toStringAsFixed(2)} GB', style: const TextStyle(fontFamily: 'monospace', color: Color(0xFF00E5FF), fontSize: 11, fontWeight: FontWeight.bold)),
                ],
              ),
            ],
          ),

          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(2),
            child: LinearProgressIndicator(
              value: (percentRemaining / 100).clamp(0.0, 1.0),
              backgroundColor: const Color(0xFF002200),
              color: percentRemaining <= 15 ? const Color(0xFFFF2222) : const Color(0xFF00FF41),
              minHeight: 6,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHackerFilterBar() {
    return Row(
      children: [
        _buildHackerFilterBtn('[-all] SEMUA', FilterMode.all, const Color(0xFF00FF41)),
        const SizedBox(width: 6),
        _buildHackerFilterBtn('[-cell] OPERATOR', FilterMode.cellOnly, const Color(0xFF00FF41)),
        const SizedBox(width: 6),
        _buildHackerFilterBtn('[-wifi] WIFI', FilterMode.wifiOnly, const Color(0xFF00E5FF)),
      ],
    );
  }

  Widget _buildHackerFilterBtn(String title, FilterMode mode, Color activeColor) {
    final isSelected = _filterMode == mode;
    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _filterMode = mode),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 6),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: isSelected ? activeColor.withOpacity(0.18) : const Color(0xFF040804),
            border: Border.all(color: isSelected ? activeColor : const Color(0xFF003800)),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            title,
            style: TextStyle(
              fontFamily: 'monospace',
              color: isSelected ? activeColor : const Color(0xFF008F11),
              fontSize: 10,
              fontWeight: isSelected ? FontWeight.w900 : FontWeight.normal,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHackerProcessTable() {
    final apps = _filteredApps;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFF020502),
        border: Border.all(color: const Color(0xFF004400)),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Hacker Table Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            color: const Color(0xFF081208),
            child: const Row(
              children: [
                Expanded(
                  flex: 5,
                  child: Text(
                    'PID // TARGET_PROCESS',
                    style: TextStyle(fontFamily: 'monospace', color: Color(0xFF00FF41), fontSize: 9, fontWeight: FontWeight.bold),
                  ),
                ),
                Expanded(
                  flex: 3,
                  child: Text(
                    'OPERATOR',
                    style: TextStyle(fontFamily: 'monospace', color: Color(0xFF00FF41), fontSize: 9, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.right,
                  ),
                ),
                Expanded(
                  flex: 3,
                  child: Text(
                    'WIFI',
                    style: TextStyle(fontFamily: 'monospace', color: Color(0xFF00E5FF), fontSize: 9, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.right,
                  ),
                ),
                Expanded(
                  flex: 3,
                  child: Text(
                    'AGGREGATE',
                    style: TextStyle(fontFamily: 'monospace', color: Color(0xFF39FF14), fontSize: 9, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.right,
                  ),
                ),
              ],
            ),
          ),

          // Process Rows
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: apps.length,
            separatorBuilder: (_, __) => const Divider(color: Color(0xFF002200), height: 1),
            itemBuilder: (context, index) {
              final app = apps[index];
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
                color: index % 2 == 0 ? Colors.transparent : const Color(0xFF040A04),
                child: Row(
                  children: [
                    // Process Name
                    Expanded(
                      flex: 5,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '> ${app.appName}',
                            style: const TextStyle(
                              fontFamily: 'monospace',
                              color: Color(0xFF00FF41),
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            '[${app.uid}] ${app.packageName}',
                            style: const TextStyle(
                              fontFamily: 'monospace',
                              color: Color(0xFF006600),
                              fontSize: 8,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),

                    // Operator
                    Expanded(
                      flex: 3,
                      child: Text(
                        app.mobileFormatted,
                        style: const TextStyle(
                          fontFamily: 'monospace',
                          color: Color(0xFF00FF41),
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.right,
                      ),
                    ),

                    // WiFi
                    Expanded(
                      flex: 3,
                      child: Text(
                        app.wifiFormatted,
                        style: const TextStyle(
                          fontFamily: 'monospace',
                          color: Color(0xFF00E5FF),
                          fontSize: 10,
                        ),
                        textAlign: TextAlign.right,
                      ),
                    ),

                    // Total
                    Expanded(
                      flex: 3,
                      child: Text(
                        app.totalFormatted,
                        style: const TextStyle(
                          fontFamily: 'monospace',
                          color: Color(0xFF39FF14),
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.right,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildTerminalPromptFooter() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFF030703),
        border: Border.all(color: const Color(0xFF005500)),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              const Text('root@QC-MCE:~# ', style: TextStyle(fontFamily: 'monospace', color: Color(0xFF008F11), fontSize: 10, fontWeight: FontWeight.bold)),
              const Text('sync_widget --target=homescreen', style: TextStyle(fontFamily: 'monospace', color: Color(0xFF00FF41), fontSize: 10)),
              const SizedBox(width: 4),
              Container(width: 6, height: 12, color: const Color(0xFF00FF41)),
            ],
          ),
          InkWell(
            onTap: _manualSyncWidget,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFF00FF41),
                borderRadius: BorderRadius.circular(2),
              ),
              child: const Text(
                'INJECT',
                style: TextStyle(fontFamily: 'monospace', color: Colors.black, fontSize: 9, fontWeight: FontWeight.w900),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHackerPermissionAlert() {
    return InkWell(
      onTap: () => NetworkService.requestUsagePermission(),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: const Color(0xFF220000),
          border: Border.all(color: const Color(0xFFFF2222)),
          borderRadius: BorderRadius.circular(4),
        ),
        child: const Text(
          '[ALERT] PERMISSION_DENIED: PACKAGE_USAGE_STATS. Click to elevate privileges.',
          style: TextStyle(fontFamily: 'monospace', color: Color(0xFFFF4444), fontSize: 10, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}

/// CUSTOM OSCILLOSCOPE PAINTER
class _CyberWaveformPainter extends CustomPainter {
  final double animationValue;
  final double cellLoadRatio;
  final double wifiLoadRatio;

  _CyberWaveformPainter({
    required this.animationValue,
    required this.cellLoadRatio,
    required this.wifiLoadRatio,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Background Grid
    final gridPaint = Paint()
      ..color = const Color(0xFF003300)
      ..strokeWidth = 0.5;

    for (double x = 0; x < size.width; x += 20) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
    }
    for (double y = 0; y < size.height; y += 15) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    // Center Zero-Line
    final centerPaint = Paint()
      ..color = const Color(0xFF005500)
      ..strokeWidth = 1.0;
    canvas.drawLine(Offset(0, size.height / 2), Offset(size.width, size.height / 2), centerPaint);

    // Stream 1: Operator Cellular (Green Pulse)
    final cellPath = Path();
    final cellPaint = Paint()
      ..color = const Color(0xFF00FF41)
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;

    final cellShadowPaint = Paint()
      ..color = const Color(0xFF00FF41).withOpacity(0.4)
      ..strokeWidth = 4.0
      ..style = PaintingStyle.stroke;

    // Stream 2: WiFi (Cyan Pulse)
    final wifiPath = Path();
    final wifiPaint = Paint()
      ..color = const Color(0xFF00E5FF)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    final width = size.width;
    final midY = size.height / 2;

    for (double x = 0; x <= width; x += 2) {
      final normX = x / width;
      final phaseCell = (normX * 6 * math.pi) - (animationValue * 4 * math.pi);
      final phaseWifi = (normX * 8 * math.pi) + (animationValue * 3 * math.pi);

      // Packet spikes
      final spike = (math.sin(normX * 12 * math.pi + animationValue * 10).abs() > 0.85) ? 12.0 : 0.0;

      final yCell = midY + (math.sin(phaseCell) * 22 * cellLoadRatio) + (spike * cellLoadRatio);
      final yWifi = midY + (math.cos(phaseWifi) * 16 * wifiLoadRatio);

      if (x == 0) {
        cellPath.moveTo(x, yCell);
        wifiPath.moveTo(x, yWifi);
      } else {
        cellPath.lineTo(x, yCell);
        wifiPath.lineTo(x, yWifi);
      }
    }

    canvas.drawPath(cellPath, cellShadowPaint);
    canvas.drawPath(cellPath, cellPaint);
    canvas.drawPath(wifiPath, wifiPaint);
  }

  @override
  bool shouldRepaint(covariant _CyberWaveformPainter oldDelegate) {
    return true;
  }
}
