# 💍 Dana Nikah

Aplikasi Android (Flutter) untuk mencatat dan merencanakan dana pernikahan.
Semua data tersimpan **offline** di HP (SQLite).

## Fitur

| Menu | Isi |
|---|---|
| **Beranda** | Countdown hari H, progres dana vs target, saran nabung per bulan, saldo, sisa tagihan vendor, kontribusi per orang, jadwal jatuh tempo terdekat, progres checklist |
| **Tabungan** | Catat setoran per penyetor (calon suami / calon istri / keluarga / lainnya), filter per orang, dikelompokkan per bulan |
| **Anggaran** | Anggaran per kategori (gedung, katering, MUA, dekorasi, mahar, seserahan, dll) vs realisasi, peringatan jika over budget, riwayat pengeluaran |
| **Vendor** | Daftar vendor + kontak (telepon / WhatsApp), nilai kontrak, status (Belum Bayar / DP / Lunas), jatuh tempo pelunasan, riwayat pembayaran (DP, cicilan, pelunasan) |
| **Checklist** | Daftar persiapan (sudah terisi contoh), tenggat, kategori |
| **Laporan** | Pie chart pengeluaran / anggaran per kategori, anggaran vs realisasi, kontribusi tabungan, ringkasan keuangan |
| **Pengaturan** | Profil pasangan, target dana, kelola penyetor, pengingat nabung bulanan, pengingat jatuh tempo, reset data |

**Notifikasi:** pengingat nabung bulanan (tanggal & jam bisa diatur), pengingat
pelunasan vendor (H-1 jam 09.00 dan hari H jam 08.00), dan tenggat checklist.

## Struktur Proyek

```
lib/
├── main.dart                  # Entry point
├── app.dart                   # MaterialApp, tema, lokalisasi Indonesia
├── theme.dart                 # Warna dusty pink / rose gold
├── models/models.dart         # Model data
├── data/
│   ├── database.dart          # SQLite (skema + data bawaan)
│   └── app_state.dart         # State, perhitungan, penjadwalan pengingat
├── services/notification_service.dart
├── utils/                     # Format Rupiah/tanggal, ikon kategori
├── widgets/                   # Komponen UI bersama
└── screens/                   # Semua halaman
android/                       # Konfigurasi Android (Gradle, manifest, ikon)
.github/workflows/build-apk.yml  # Build APK otomatis di GitHub
```

## Cara Mendapatkan APK

### Opsi A — Tanpa install apa pun (GitHub Actions) ✅ disarankan

1. Buat repository baru di [github.com](https://github.com) (boleh private).
2. Upload/push seluruh isi folder ini ke repository tersebut.
3. Buka tab **Actions** → workflow **Build APK** akan berjalan otomatis
   (atau klik **Run workflow**).
4. Setelah selesai (± 5–10 menit), buka hasil run → bagian **Artifacts** →
   unduh `dana-nikah-apk` → ekstrak → `app-release.apk`.
5. Kirim APK ke HP, buka, izinkan "Install dari sumber tidak dikenal".

### Opsi B — Di komputer lain yang ada Flutter

```bash
flutter pub get
flutter run                 # jalankan di HP/emulator
flutter build apk --release # hasil: build/app/outputs/flutter-apk/app-release.apk
```

> Jika muncul error terkait `gradlew` / Gradle wrapper, jalankan sekali:
> `flutter create --org com.dananikah --project-name dana_nikah --platforms android .`
> (file yang sudah ada tidak akan ditimpa).

Ingin versi iOS nanti? Jalankan `flutter create --platforms ios .` di Mac.

## Catatan

- Minimal Android 8.0.
- Menghapus aplikasi = menghapus data. Sinkronisasi online (mis. Firebase)
  bisa ditambahkan nanti — semua akses data sudah terpusat di
  `lib/data/database.dart` & `lib/data/app_state.dart`.
- APK release ditandatangani dengan debug key (cukup untuk pemakaian
  pribadi). Untuk Play Store, buat keystore sendiri.
