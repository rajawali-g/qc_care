# QC_MCE (qc_care) • Pemantau Paket Data Android

[![Release Build](https://github.com/rajawali-g/qc_care/actions/workflows/release.yml/badge.svg)](https://github.com/rajawali-g/qc_care/actions/workflows/release.yml)
[![Flutter Version](https://img.shields.io/badge/Flutter-3.22.2-blue.svg)](https://flutter.dev)
[![Java Version](https://img.shields.io/badge/Java-17%20LTS-orange.svg)](https://learn.microsoft.com/java/)
[![Platform](https://img.shields.io/badge/Platform-Android%20(API%2023%2B)-brightgreen.svg)](https://android.com)

Aplikasi pemantauan kuota paket data internet berbasis **Flutter** dan **Android Native (Kotlin)** yang dilengkapi dengan **Widget Layar Depan (Home Screen Widget)** agar sisa kuota dan pemakaian internet harian dapat dipantau langsung tanpa harus membuka aplikasi.

---

## Fitur Utama

- 📱 **Widget Layar Depan (Home Screen Widget)**: Menampilkan sisa kuota (GB), progress bar visual, dan pemakaian hari ini langsung di layar utama HP.
- ⚡ **Data Aktual Real-time**: Memanfaatkan Android `NetworkStatsManager` untuk membaca konsumsi data seluler dan WiFi secara akurat.
- 🎯 **Konfigurasi Fleksibel**: Pengguna dapat mengatur batas total kuota (GB), tanggal reset siklus bulanan, dan batas peringatan kuota menipis.
- 🌓 **Desain Modern Material 3**: Tampilan antarmuka gelap (*Dark Indigo*) yang hemat baterai dan nyaman di mata.
- 🚀 **Otomatisasi Rilis GitHub**: CI/CD GitHub Actions terintegrasi yang secara otomatis mengompilasi APK dan merilisnya ke halaman **Releases** setiap kali ada pembaruan kode.

---

## 📥 Unduh APK Terbaru

Anda dapat mengunduh file APK siap pasang langsung dari halaman rilis resmi:
👉 **[Download APK Terbaru di GitHub Releases](https://github.com/rajawali-g/qc_care/releases)**

---

## 🛠️ Cara Memasang Widget di Layar Depan HP

1. Instal aplikasi **QC_MCE** di ponsel Android Anda.
2. Buka aplikasi, lalu ketuk **"Buka Pengaturan Izin"** untuk mengaktifkan izin **Akses Penggunaan (Usage Access)**.
3. Kembali ke Layar Utama (Home Screen) HP Anda.
4. Tekan dan tahan area kosong di layar utama selama 1–2 detik.
5. Pilih menu **Widget** -> Cari **QC_MCE** -> Tarik widget ke layar depan.

---

## 💻 Pengembangan Lokal

```bash
# Clone repositori
git clone https://github.com/rajawali-g/qc_care.git
cd qc_care

# Ambil paket dependensi
flutter pub get

# Jalankan di perangkat Android
flutter run
```

---

## 📄 Lisensi
Dikelola oleh [@rajawali-g](https://github.com/rajawali-g).
