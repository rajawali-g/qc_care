import 'package:flutter/material.dart';
import '../services/quota_preferences.dart';
import '../services/network_service.dart';
import 'widget_guide_dialog.dart';

class SettingsScreen extends StatefulWidget {
  final VoidCallback onSaved;

  const SettingsScreen({super.key, required this.onSaved});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _quotaController = TextEditingController();
  int _resetDay = 1;
  int _warningPercent = 20;
  bool _isLoading = true;

  final List<double> _presetQuotas = [5.0, 10.0, 15.0, 25.0, 50.0, 100.0];

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  @override
  void dispose() {
    _quotaController.dispose();
    super.dispose();
  }

  Future<void> _loadSettings() async {
    final quota = await QuotaPreferences.getTotalQuotaGb();
    final day = await QuotaPreferences.getCycleResetDay();
    final warn = await QuotaPreferences.getWarningThresholdPercent();

    setState(() {
      _quotaController.text = quota.toStringAsFixed(1);
      _resetDay = day;
      _warningPercent = warn;
      _isLoading = false;
    });
  }

  Future<void> _saveSettings() async {
    final parsedQuota = double.tryParse(_quotaController.text.trim()) ?? 15.0;

    await QuotaPreferences.setTotalQuotaGb(parsedQuota);
    await QuotaPreferences.setCycleResetDay(_resetDay);
    await QuotaPreferences.setWarningThresholdPercent(_warningPercent);

    final cycleStart = QuotaPreferences.getCycleStartDate(_resetDay);
    final usage = await NetworkService.fetchNetworkUsage(cycleStart);
    await NetworkService.syncHomeScreenWidget(
      totalQuotaGb: parsedQuota,
      cycleUsedGb: usage.cycleMobileGb,
      todayUsedMb: usage.todayMobileMb,
    );

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            '>> [SYS_CONFIG_UPDATED] PARAMETER DISIMPAN KE EEPROM/STORAGE',
            style: TextStyle(fontFamily: 'monospace', fontSize: 11),
          ),
          backgroundColor: Color(0xFF00FF88),
          behavior: SnackBarBehavior.floating,
        ),
      );
      widget.onSaved();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Color(0xFF07090E),
        body: Center(child: CircularProgressIndicator(color: Color(0xFF00E5FF))),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFF07090E),
      appBar: AppBar(
        backgroundColor: const Color(0xFF090D15),
        title: const Text(
          'SYS_CONFIG // QUOTA_PARAMETERS',
          style: TextStyle(fontFamily: 'monospace', color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
        ),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.save_rounded, color: Color(0xFF00E5FF), size: 20),
            tooltip: 'Commit Changes',
            onPressed: _saveSettings,
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: const Color(0xFF1B2333)),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Quota Parameter Box
            _buildCyberConfigCard(
              tag: 'PARAM_01 // BANDWIDTH_ALLOCATION',
              icon: Icons.data_usage_rounded,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Tentukan batas kuota total data (GB):',
                    style: TextStyle(color: Color(0xFF90A4AE), fontSize: 11),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _quotaController,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          style: const TextStyle(fontFamily: 'monospace', color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                          decoration: InputDecoration(
                            filled: true,
                            fillColor: const Color(0xFF0F1523),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: const BorderSide(color: Color(0xFF1D283E)),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: const BorderSide(color: Color(0xFF1D283E)),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: const BorderSide(color: Color(0xFF00E5FF)),
                            ),
                            suffixText: 'GIGABYTES (GB)',
                            suffixStyle: const TextStyle(fontFamily: 'monospace', color: Color(0xFF00E5FF), fontSize: 11),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  const Text('PRESETS:', style: TextStyle(fontFamily: 'monospace', color: Color(0xFF78909C), fontSize: 10)),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 8,
                    children: _presetQuotas.map((q) {
                      return ActionChip(
                        label: Text('${q.toInt()} GB', style: const TextStyle(fontFamily: 'monospace', fontSize: 11)),
                        backgroundColor: const Color(0xFF0E1422),
                        side: const BorderSide(color: Color(0xFF1C273D)),
                        labelStyle: const TextStyle(color: Color(0xFF80D8FF)),
                        onPressed: () {
                          setState(() {
                            _quotaController.text = q.toStringAsFixed(1);
                          });
                        },
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // Reset Cycle Box
            _buildCyberConfigCard(
              tag: 'PARAM_02 // BILLING_CYCLE_OFFSET',
              icon: Icons.update_rounded,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Pilih hari pergantian siklus reset bulanan:',
                    style: TextStyle(color: Color(0xFF90A4AE), fontSize: 11),
                  ),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0F1523),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFF1D283E)),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<int>(
                        value: _resetDay,
                        isExpanded: true,
                        dropdownColor: const Color(0xFF0F1523),
                        style: const TextStyle(fontFamily: 'monospace', color: Colors.white, fontSize: 13),
                        items: List.generate(28, (index) => index + 1).map((day) {
                          return DropdownMenuItem<int>(
                            value: day,
                            child: Text('TANGGAL $day TIAP BULAN (00:00 WIB)'),
                          );
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) {
                            setState(() => _resetDay = val);
                          }
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // Warning Threshold Box
            _buildCyberConfigCard(
              tag: 'PARAM_03 // CRITICAL_THRESHOLD',
              icon: Icons.crisis_alert_rounded,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Ambang batas peringatan kuota:',
                        style: TextStyle(color: Color(0xFF90A4AE), fontSize: 11),
                      ),
                      Text(
                        '$_warningPercent% REMAINING',
                        style: const TextStyle(fontFamily: 'monospace', color: Color(0xFFFFB300), fontWeight: FontWeight.bold, fontSize: 11),
                      ),
                    ],
                  ),
                  Slider(
                    value: _warningPercent.toDouble(),
                    min: 5,
                    max: 40,
                    divisions: 7,
                    activeColor: const Color(0xFFFFB300),
                    inactiveColor: const Color(0xFF1D283E),
                    onChanged: (val) {
                      setState(() => _warningPercent = val.round());
                    },
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // Homescreen Widget Deployment Box
            _buildCyberConfigCard(
              tag: 'MODULE // HOMESCREEN_WIDGET',
              icon: Icons.developer_board_rounded,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Aktifkan modul widget Android di layar utama ponsel:',
                    style: TextStyle(color: Color(0xFF90A4AE), fontSize: 11),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.info_outline_rounded, size: 16),
                      label: const Text('BACA PANDUAN DEPLOY WIDGET', style: TextStyle(fontFamily: 'monospace', fontSize: 11, fontWeight: FontWeight.bold)),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF00E5FF),
                        side: const BorderSide(color: Color(0xFF00E5FF)),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (context) => const WidgetGuideDialog(),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Save CTA
            SizedBox(
              width: double.infinity,
              height: 48,
              child: FilledButton.icon(
                icon: const Icon(Icons.bolt_rounded, size: 18),
                label: const Text('APPLY_PARAMETERS // COMMIT', style: TextStyle(fontFamily: 'monospace', fontSize: 13, fontWeight: FontWeight.w900)),
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF00E5FF),
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                onPressed: _saveSettings,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCyberConfigCard({
    required String tag,
    required IconData icon,
    required Widget child,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF0B0F19),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF182236)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: const Color(0xFF00E5FF), size: 16),
              const SizedBox(width: 8),
              Text(
                tag,
                style: const TextStyle(
                  fontFamily: 'monospace',
                  color: Color(0xFF80D8FF),
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }
}
