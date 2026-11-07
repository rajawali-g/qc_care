import 'dart:async';
import 'package:flutter/material.dart';
import '../models/network_usage_model.dart';
import '../models/app_usage_model.dart';

class HackerWidgetView extends StatefulWidget {
  final double totalQuotaGb;
  final NetworkUsageData usageData;
  final List<AppUsageInfo> apps;
  final VoidCallback onOpenNetstat;

  const HackerWidgetView({
    super.key,
    required this.totalQuotaGb,
    required this.usageData,
    required this.apps,
    required this.onOpenNetstat,
  });

  @override
  State<HackerWidgetView> createState() => _HackerWidgetViewState();
}

class _HackerWidgetViewState extends State<HackerWidgetView> {
  late Timer _clockTimer;
  DateTime _currentTime = DateTime.now();

  @override
  void initState() {
    super.initState();
    _clockTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          _currentTime = DateTime.now();
        });
      }
    });
  }

  @override
  void dispose() {
    _clockTimer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final usedGb = widget.usageData.cycleMobileGb;
    final remainingGb = (widget.totalQuotaGb - usedGb).clamp(0.0, widget.totalQuotaGb);
    final percentRemaining = widget.totalQuotaGb > 0
        ? ((remainingGb / widget.totalQuotaGb) * 100).clamp(0.0, 100.0)
        : 0.0;

    final topApp = widget.apps.isNotEmpty ? widget.apps.first : null;
    final topAppName = topApp != null ? topApp.appName : 'YouTube';
    final topAppBytes = topApp != null ? topApp.mobileFormatted : '1.24 GB';

    final timeStr = '${_currentTime.hour.toString().padLeft(2, '0')}:${_currentTime.minute.toString().padLeft(2, '0')}:${_currentTime.second.toString().padLeft(2, '0')}';
    final shortTimeStr = '${_currentTime.hour.toString().padLeft(2, '0')}:${_currentTime.minute.toString().padLeft(2, '0')}';

    return Center(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 420),
        margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        decoration: BoxDecoration(
          color: Colors.black,
          borderRadius: BorderRadius.circular(38),
          border: Border.all(color: const Color(0xFF00FF41), width: 2),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF00FF41).withOpacity(0.3),
              blurRadius: 25,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Status Bar
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  shortTimeStr,
                  style: const TextStyle(
                    fontFamily: 'monospace',
                    color: Color(0xFF00FF41),
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Row(
                  children: [
                    Text('5G_SA ', style: TextStyle(fontFamily: 'monospace', color: Color(0xFF00FF41), fontSize: 11, fontWeight: FontWeight.bold)),
                    Icon(Icons.signal_cellular_alt, color: Color(0xFF00FF41), size: 14),
                    SizedBox(width: 4),
                    Text('-72dBm ', style: TextStyle(fontFamily: 'monospace', color: Color(0xFF008F11), fontSize: 10)),
                    Icon(Icons.battery_charging_full, color: Color(0xFF00FF41), size: 14),
                    Text(' 98%', style: TextStyle(fontFamily: 'monospace', color: Color(0xFF00FF41), fontSize: 10)),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 20),

            // Giant Neon Green Digital Clock
            Text(
              timeStr,
              style: TextStyle(
                fontFamily: 'monospace',
                color: const Color(0xFF00FF41),
                fontSize: 38,
                fontWeight: FontWeight.w900,
                letterSpacing: 2,
                shadows: [
                  Shadow(color: const Color(0xFF00FF41).withOpacity(0.9), blurRadius: 18),
                ],
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'SECURE_CYBER_TERMINAL // WIB',
              style: TextStyle(
                fontFamily: 'monospace',
                color: Color(0xFF008F11),
                fontSize: 11,
                letterSpacing: 1.2,
              ),
            ),

            const SizedBox(height: 24),

            // Section Label
            const Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '[ QC_MCE HACKER WIDGET ]',
                  style: TextStyle(
                    fontFamily: 'monospace',
                    color: Color(0xFF00FF41),
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'TAP TO LAUNCH',
                  style: TextStyle(
                    fontFamily: 'monospace',
                    color: Color(0xFF006600),
                    fontSize: 10,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 8),

            // THE WIDGET CARD (EXACT REPLICA OF THE IMAGE)
            InkWell(
              onTap: widget.onOpenNetstat,
              borderRadius: BorderRadius.circular(20),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF020502),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFF00FF41), width: 1.8),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF00FF41).withOpacity(0.25),
                      blurRadius: 16,
                      spreadRadius: 1,
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Widget Header Row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                color: Color(0xFF00FF41),
                                boxShadow: [
                                  BoxShadow(color: Color(0xFF00FF41), blurRadius: 6, spreadRadius: 1),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            const Text(
                              'QC_MCE // NET_OBSERVER',
                              style: TextStyle(
                                fontFamily: 'monospace',
                                color: Color(0xFF00FF41),
                                fontSize: 12,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: const Color(0xFF00FF41),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            'SNIFF: ON',
                            style: TextStyle(
                              fontFamily: 'monospace',
                              color: Colors.black,
                              fontSize: 10,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 12),

                    // Big Quota Numbers
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Text(
                          remainingGb.toStringAsFixed(2),
                          style: TextStyle(
                            fontFamily: 'monospace',
                            color: Colors.white,
                            fontSize: 34,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -0.5,
                            shadows: [
                              Shadow(color: const Color(0xFF00FF41).withOpacity(0.8), blurRadius: 12),
                            ],
                          ),
                        ),
                        const SizedBox(width: 6),
                        const Text(
                          'GB',
                          style: TextStyle(
                            fontFamily: 'monospace',
                            color: Color(0xFF00FF41),
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Spacer(),
                        const Text(
                          '// REMAINING_OPERATOR',
                          style: TextStyle(
                            fontFamily: 'monospace',
                            color: Color(0xFF008F11),
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 12),

                    // Neon Green Progress Bar
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: Container(
                        height: 8,
                        decoration: BoxDecoration(
                          color: const Color(0xFF002200),
                          border: Border.all(color: const Color(0xFF004400), width: 0.5),
                        ),
                        child: LinearProgressIndicator(
                          value: (percentRemaining / 100).clamp(0.0, 1.0),
                          backgroundColor: const Color(0xFF002200),
                          color: const Color(0xFF00FF41),
                          minHeight: 8,
                        ),
                      ),
                    ),

                    const SizedBox(height: 14),

                    // Operator vs WiFi Split Grid
                    Row(
                      children: [
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                            decoration: BoxDecoration(
                              color: Colors.black,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: const Color(0xFF004400)),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'OPERATOR HARI INI:',
                                  style: TextStyle(fontFamily: 'monospace', color: Color(0xFF008F11), fontSize: 9),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '${widget.usageData.todayMobileMb.toStringAsFixed(2)} MB',
                                  style: const TextStyle(
                                    fontFamily: 'monospace',
                                    color: Color(0xFF00FF41),
                                    fontSize: 14,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                            decoration: BoxDecoration(
                              color: Colors.black,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: const Color(0xFF004400)),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'WIFI HARI INI:',
                                  style: TextStyle(fontFamily: 'monospace', color: Color(0xFF008F11), fontSize: 9),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '${widget.usageData.todayWifiGb.toStringAsFixed(2)} GB',
                                  style: const TextStyle(
                                    fontFamily: 'monospace',
                                    color: Color(0xFF00E5FF),
                                    fontSize: 14,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 12),

                    // Top Consumer Footnote
                    Container(
                      padding: const EdgeInsets.only(top: 8),
                      decoration: const BoxDecoration(
                        border: Border(top: BorderSide(color: Color(0xFF003300))),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'MAX_CONSUMER:',
                            style: TextStyle(fontFamily: 'monospace', color: Color(0xFF008F11), fontSize: 10),
                          ),
                          Text(
                            '> $topAppName [$topAppBytes]',
                            style: const TextStyle(
                              fontFamily: 'monospace',
                              color: Color(0xFF00FF41),
                              fontSize: 11,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Bottom App Icons Dock
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildDockItem('⚡', 'SHELL', false, () {}),
                _buildDockItem('🌐', 'BROWSER', false, () {}),
                _buildDockItem('QC', 'QC_MCE', true, widget.onOpenNetstat),
                _buildDockItem('🛰️', 'RADAR', false, () {}),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDockItem(String iconText, String label, bool isPrimary, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Colors.black,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: isPrimary ? const Color(0xFF00FF41) : const Color(0xFF004400),
                width: isPrimary ? 2 : 1,
              ),
              boxShadow: isPrimary
                  ? [
                      BoxShadow(
                        color: const Color(0xFF00FF41).withOpacity(0.5),
                        blurRadius: 14,
                        spreadRadius: 1,
                      ),
                    ]
                  : null,
            ),
            alignment: Alignment.center,
            child: Text(
              iconText,
              style: TextStyle(
                fontFamily: 'monospace',
                fontSize: isPrimary ? 16 : 20,
                fontWeight: isPrimary ? FontWeight.w900 : FontWeight.normal,
                color: isPrimary ? const Color(0xFF00FF41) : const Color(0xFF008F11),
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontFamily: 'monospace',
              fontSize: 9,
              color: isPrimary ? const Color(0xFF00FF41) : const Color(0xFF008F11),
              fontWeight: isPrimary ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }
}

