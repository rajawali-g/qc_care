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
      // Re-check permission and update data when user returns from settings
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

      // Auto update the home screen widget
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
      });
    }
  }

  Future<void> _askPermission() async {
    await NetworkService.requestUsagePermission();
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
                ? 'Widget di layar depan berhasil disinkronkan!'
                : 'Gagal memperbarui widget',
          ),
          backgroundColor: success ? const Color(0xFF2E7D32) : Colors.redAccent,
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
    final percentUsed = 100.0 - percentRemaining;

    final daysRemaining = QuotaPreferences.getDaysUntilNextReset(_resetDay);

    Color statusColor;
    if (percentRemaining <= 10) {
      statusColor = const Color(0xFFEF5350); // Red
    } else if (percentRemaining <= _warningPercent) {
      statusColor = const Color(0xFFFFA726); // Orange
    } else {
      statusColor = const Color(0xFF26A69A); // Teal / Green
    }

    return Scaffold(
      backgroundColor: const Color(0xFF10131A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF161B26),
        elevation: 0,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFF1976D2),
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Text(
                'QC_MCE',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
              ),
            ),
            const SizedBox(width: 10),
            const Text(
              'Pemantau Kuota',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: Colors.white70),
            tooltip: 'Segarkan data',
            onPressed: _refreshAll,
          ),
          IconButton(
            icon: const Icon(Icons.settings_outlined, color: Colors.white70),
            tooltip: 'Pengaturan Paket',
            onPressed: widget.onOpenSettings,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF29B6F6)),
            )
          : RefreshIndicator(
              onRefresh: _refreshAll,
              color: const Color(0xFF29B6F6),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (!_hasPermission) ...[
                _buildPermissionAlert(),
                const SizedBox(height: 16),
              ],

              // Main Quota Gauge Card
              _buildMainQuotaCard(
                remainingGb: remainingGb,
                percentRemaining: percentRemaining,
                percentUsed: percentUsed,
                usedGb: usedGb,
                daysRemaining: daysRemaining,
                statusColor: statusColor,
              ),

              const SizedBox(height: 16),

              // Widget Action Bar
              _buildWidgetActionPill(),

              const SizedBox(height: 20),

              // Breakdown Header
              const Text(
                'Rincian Penggunaan Internet',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),

              // 2x2 Grid of detailed usage
              Row(
                children: [
                  Expanded(
                    child: _buildUsageItemCard(
                      title: 'Data Seluler Hari Ini',
                      value: NetworkUsageData.formatBytes(_usageData.todayMobileBytes),
                      icon: Icons.calendar_today_rounded,
                      iconColor: const Color(0xFF42A5F5),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildUsageItemCard(
                      title: 'Total Seluler Siklus Ini',
                      value: NetworkUsageData.formatBytes(_usageData.cycleMobileBytes),
                      icon: Icons.data_usage_rounded,
                      iconColor: const Color(0xFF66BB6A),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _buildUsageItemCard(
                      title: 'WiFi Hari Ini',
                      value: NetworkUsageData.formatBytes(_usageData.todayWifiBytes),
                      icon: Icons.wifi_rounded,
                      iconColor: const Color(0xFFAB47BC),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildUsageItemCard(
                      title: 'Total WiFi Siklus Ini',
                      value: NetworkUsageData.formatBytes(_usageData.cycleWifiBytes),
                      icon: Icons.network_check_rounded,
                      iconColor: const Color(0xFFFF7043),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // Tips info card
              _buildTipsCard(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPermissionAlert() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF2C2216),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFFF9800).withOpacity(0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: Color(0xFFFFB74D), size: 24),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Izin Akses Penggunaan Diperlukan',
                  style: TextStyle(
                    color: Color(0xFFFFE082),
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          const Text(
            'Agar QC_MCE dapat membaca pemakaian kuota data Anda dari sistem Android secara langsung, aktifkan izin "Akses Penggunaan" untuk aplikasi ini.',
            style: TextStyle(color: Color(0xFFFFECB3), fontSize: 12, height: 1.3),
          ),
          const SizedBox(height: 10),
          Align(
            alignment: Alignment.centerRight,
            child: FilledButton.tonal(
              onPressed: _askPermission,
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFFFF9800),
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              ),
              child: const Text('Buka Pengaturan Izin', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMainQuotaCard({
    required double remainingGb,
    required double percentRemaining,
    required double percentUsed,
    required double usedGb,
    required int daysRemaining,
    required Color statusColor,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1B2233), Color(0xFF141926)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF263248)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.4),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(Icons.sim_card_outlined, color: statusColor, size: 20),
                  const SizedBox(width: 8),
                  const Text(
                    'Sisa Kuota Paket Data',
                    style: TextStyle(color: Color(0xFF90CAF9), fontSize: 13, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: statusColor.withOpacity(0.4)),
                ),
                child: Text(
                  '${percentRemaining.toStringAsFixed(0)}% Sisa',
                  style: TextStyle(color: statusColor, fontSize: 12, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                remainingGb.toStringAsFixed(2),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 38,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(width: 6),
              const Text(
                'GB',
                style: TextStyle(
                  color: Color(0xFF64B5F6),
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              Text(
                'dari ${_totalQuotaGb.toStringAsFixed(1)} GB',
                style: const TextStyle(color: Color(0xFF8892B0), fontSize: 13),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Linear Progress Bar
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: (percentRemaining / 100).clamp(0.0, 1.0),
              backgroundColor: const Color(0xFF283149),
              color: statusColor,
              minHeight: 10,
            ),
          ),
          const SizedBox(height: 14),

          // Footnotes (Terpakai & Sisa Hari)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Terpakai: ${usedGb.toStringAsFixed(2)} GB',
                style: const TextStyle(color: Color(0xFFB0BEC5), fontSize: 12),
              ),
              Row(
                children: [
                  const Icon(Icons.timer_outlined, color: Color(0xFF90A4AE), size: 14),
                  const SizedBox(width: 4),
                  Text(
                    'Reset: $daysRemaining hari lagi',
                    style: const TextStyle(color: Color(0xFFB0BEC5), fontSize: 12),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildWidgetActionPill() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF161E2E),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF222E46)),
      ),
      child: Row(
        children: [
          const Icon(Icons.home_outlined, color: Color(0xFF4FC3F7), size: 22),
          const SizedBox(width: 10),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Widget Layar Depan HP',
                  style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                ),
                Text(
                  'Tampil real-time di layar depan Anda',
                  style: TextStyle(color: Color(0xFF90A4AE), fontSize: 11),
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
              padding: const EdgeInsets.symmetric(horizontal: 10),
              foregroundColor: const Color(0xFF81D4FA),
            ),
            child: const Text('Cara Pasang', style: TextStyle(fontSize: 12)),
          ),
          FilledButton.tonal(
            onPressed: _manualSyncWidget,
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF0288D1),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            ),
            child: const Text('Sync', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildUsageItemCard({
    required String title,
    required String value,
    required IconData icon,
    required Color iconColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF181E2B),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF242C3F)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: iconColor.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: iconColor, size: 16),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    color: Color(0xFF90A4AE),
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTipsCard() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF141924),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF1F2738)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.lightbulb_outline_rounded, color: Color(0xFFFFCA28), size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Tips: Setelah menambahkan Widget QC_MCE ke layar depan HP, Anda cukup mengetuk widget untuk membuka aplikasi atau melihat pembaruan seketika.',
              style: TextStyle(
                color: Colors.grey.shade400,
                fontSize: 11,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

