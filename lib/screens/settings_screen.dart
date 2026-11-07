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

    // Sync to widget
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
          content: Text('Pengaturan paket data berhasil disimpan!'),
          backgroundColor: Color(0xFF2E7D32),
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
        backgroundColor: Color(0xFF10131A),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFF10131A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF161B26),
        title: const Text('Pengaturan Paket Data', style: TextStyle(color: Colors.white, fontSize: 16)),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.check, color: Color(0xFF29B6F6)),
            tooltip: 'Simpan',
            onPressed: _saveSettings,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Card Quota
            _buildSectionCard(
              title: 'Besar Kuota Paket',
              icon: Icons.data_usage_rounded,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Masukkan batas total kuota data Anda:',
                    style: TextStyle(color: Color(0xFF90A4AE), fontSize: 12),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _quotaController,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                          decoration: InputDecoration(
                            filled: true,
                            fillColor: const Color(0xFF1E2638),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                            suffixText: 'GB',
                            suffixStyle: const TextStyle(color: Color(0xFF64B5F6), fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Text('Pilihan Cepat:', style: TextStyle(color: Color(0xFF8892B0), fontSize: 11)),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 8,
                    children: _presetQuotas.map((q) {
                      return ActionChip(
                        label: Text('${q.toInt()} GB'),
                        backgroundColor: const Color(0xFF1E2638),
                        labelStyle: const TextStyle(color: Color(0xFFE2E8F0), fontSize: 12),
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

            const SizedBox(height: 16),

            // Card Reset Day
            _buildSectionCard(
              title: 'Siklus Reset Kuota',
              icon: Icons.event_repeat_rounded,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Pilih tanggal reset kuota setiap bulannya:',
                    style: TextStyle(color: Color(0xFF90A4AE), fontSize: 12),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E2638),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<int>(
                        value: _resetDay,
                        isExpanded: true,
                        dropdownColor: const Color(0xFF1E2638),
                        style: const TextStyle(color: Colors.white, fontSize: 14),
                        items: List.generate(28, (index) => index + 1).map((day) {
                          return DropdownMenuItem<int>(
                            value: day,
                            child: Text('Tanggal $day setiap bulan'),
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

            const SizedBox(height: 16),

            // Card Warning Threshold
            _buildSectionCard(
              title: 'Batas Peringatan Kuota Menipis',
              icon: Icons.notification_important_outlined,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Peringatkan saat sisa kuota kurang dari $_warningPercent%:',
                    style: const TextStyle(color: Color(0xFF90A4AE), fontSize: 12),
                  ),
                  const SizedBox(height: 8),
                  Slider(
                    value: _warningPercent.toDouble(),
                    min: 5,
                    max: 40,
                    divisions: 7,
                    activeColor: const Color(0xFFFFA726),
                    inactiveColor: const Color(0xFF263248),
                    label: '$_warningPercent%',
                    onChanged: (val) {
                      setState(() => _warningPercent = val.round());
                    },
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Help & Guide Card
            _buildSectionCard(
              title: 'Layar Depan HP & Widget',
              icon: Icons.widgets_outlined,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Ingin menampilkan widget QC_MCE di layar depan ponsel?',
                    style: TextStyle(color: Color(0xFF90A4AE), fontSize: 12),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.help_outline_rounded, size: 18),
                      label: const Text('Buka Panduan Pasang Widget'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF64B5F6),
                        side: const BorderSide(color: Color(0xFF1976D2)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
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

            const SizedBox(height: 24),

            // Save Button
            SizedBox(
              width: double.infinity,
              height: 50,
              child: FilledButton.icon(
                icon: const Icon(Icons.save_outlined),
                label: const Text('Simpan Pengaturan', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF1976D2),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: _saveSettings,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required Widget child,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF181E2B),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF242C3F)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: const Color(0xFF64B5F6), size: 18),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

