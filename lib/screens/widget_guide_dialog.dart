import 'package:flutter/material.dart';

class WidgetGuideDialog extends StatelessWidget {
  const WidgetGuideDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      backgroundColor: const Color(0xFF1E222D),
      title: const Row(
        children: [
          Icon(Icons.widgets_rounded, color: Color(0xFF64B5F6), size: 26),
          SizedBox(width: 10),
          Text(
            'Pasang di Layar Depan',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
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
              'Agar kuota data terpantau langsung di layar depan HP Anda tanpa buka aplikasi:',
              style: TextStyle(fontSize: 13, color: Color(0xFFB0BEC5), height: 1.4),
            ),
            const SizedBox(height: 16),
            _buildStepItem(
              number: '1',
              title: 'Ke Layar Utama (Home Screen)',
              desc: 'Tutup aplikasi lalu pergi ke layar utama HP Anda.',
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
              desc: 'Tahan widget "QC_MCE Widget Kuota" lalu seret ke posisi yang Anda inginkan di layar depan HP Anda.',
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF263238),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF37474F)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.info_outline, color: Color(0xFF81D4FA), size: 20),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Widget akan selalu terupdate otomatis & sisa kuota langsung tampil di layar depan.',
                      style: TextStyle(fontSize: 11, color: Color(0xFFCFD8DC)),
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
            backgroundColor: const Color(0xFF1E88E5),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
          child: const Text('Mengerti', style: TextStyle(color: Colors.white)),
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
            width: 24,
            height: 24,
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              color: Color(0xFF1976D2),
              shape: BoxShape.circle,
            ),
            child: Text(
              number,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 12,
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
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  desc,
                  style: const TextStyle(
                    color: Color(0xFF90A4AE),
                    fontSize: 12,
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

