import 'package:flutter/material.dart';

class WidgetGuideDialog extends StatelessWidget {
  const WidgetGuideDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: Color(0xFF00FF41), width: 1.5),
      ),
      backgroundColor: const Color(0xFF020602),
      title: const Row(
        children: [
          Icon(Icons.widgets_rounded, color: Color(0xFF00FF41), size: 24),
          SizedBox(width: 10),
          Text(
            'DEPLOY // HOMESCREEN_WIDGET',
            style: TextStyle(
              fontFamily: 'monospace',
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Color(0xFF00FF41),
            ),
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              '>> INSTRUKSI PASANG WIDGET KUOTA KE LAYAR DEPAN HP:',
              style: TextStyle(fontFamily: 'monospace', fontSize: 11, color: Color(0xFF008F11), height: 1.4),
            ),
            const SizedBox(height: 16),
            _buildStepItem(
              number: '1',
              title: 'Ke Layar Utama (Home Screen)',
              desc: 'Tutup aplikasi lalu pergi ke layar utama ponsel Anda.',
            ),
            _buildStepItem(
              number: '2',
              title: 'Tekan & Tahan Layar',
              desc: 'Tekan dan tahan pada area kosong di layar depan selama 1–2 detik.',
            ),
            _buildStepItem(
              number: '3',
              title: 'Pilih Menu "Widget"',
              desc: 'Ketuk ikon menu "Widgets" atau "Alat Layar" yang muncul di bagian bawah.',
            ),
            _buildStepItem(
              number: '4',
              title: 'Cari "QC_MCE"',
              desc: 'Cari nama aplikasi "QC_MCE" di daftar widget.',
            ),
            _buildStepItem(
              number: '5',
              title: 'Tarik ke Layar Depan',
              desc: 'Tahan widget "QC_MCE" lalu seret ke posisi yang Anda inginkan di layar depan HP Anda.',
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFF004400)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.info_outline, color: Color(0xFF00FF41), size: 18),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'STATUS: Widget tersinkronisasi otomatis dengan kuota operator & wifi harian.',
                      style: TextStyle(fontFamily: 'monospace', fontSize: 10, color: Color(0xFF00FF41)),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      actions: [
        FilledButton(
          onPressed: () => Navigator.pop(context),
          style: FilledButton.styleFrom(
            backgroundColor: const Color(0xFF00FF41),
            foregroundColor: Colors.black,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
          ),
          child: const Text('DISMISS // ACK', style: TextStyle(fontFamily: 'monospace', fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }

  Widget _buildStepItem({required String number, required String title, required String desc}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 22,
            height: 22,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: Colors.black,
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFF00FF41)),
            ),
            child: Text(
              number,
              style: const TextStyle(
                fontFamily: 'monospace',
                color: Color(0xFF00FF41),
                fontWeight: FontWeight.bold,
                fontSize: 11,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontFamily: 'monospace',
                    color: Color(0xFF00FF41),
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  desc,
                  style: const TextStyle(
                    fontFamily: 'monospace',
                    color: Color(0xFF008F11),
                    fontSize: 11,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

