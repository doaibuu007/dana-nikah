# 💍 Dana Nikah (v1.1.0)

Aplikasi pencatatan keuangan & perencanaan pernikahan berbahasa Indonesia (format Rupiah, tema *dusty pink / rose gold*) yang mendukung **Android (APK)** dan **iPhone / iOS (Web App / PWA)**.

Seluruh data tersimpan **100% offline** di perangkat masing-masing (**SQLite** di Android & **Local Storage** di Safari iPhone) dan dapat disinkronkan antar HP pasangan kapan saja menggunakan fitur **Backup & Restore JSON**.

🔗 **Link Web App (iPhone / Browser):** [https://doaibuu007.github.io/dana-nikah/](https://doaibuu007.github.io/dana-nikah/)

---

## ✨ Fitur Utama

| Menu | Deskripsi Fitur |
|---|---|
| **Beranda (Dashboard)** | Countdown menuju Hari H, progres tabungan vs target dana, rekomendasi tabungan bulanan, sisa dana, total tagihan vendor belum lunas, kontribusi per orang, pengingat jatuh tempo terdekat, dan pintasan alat bantu cepat. |
| **Tabungan** | Catat pemasukan/setoran tabungan berdasarkan penyetor (*Calon Suami*, *Calon Istri*, *Keluarga*, atau tambah sendiri), filter per orang, dikelompokkan rapi per bulan. |
| **Anggaran & Pengeluaran** | Alokasi anggaran per kategori vs realisasi pengeluaran, indikator **Dana Belum Dialokasikan / Melebihi Target**, peringatan *over-budget*, **Generator Anggaran Otomatis (1-Klik)** berdasarkan persentase ideal, serta riwayat pembayaran lengkap dengan pencarian & filter. |
| **Kalkulator Katering** | Hitung estimasi total tamu hadir dari jumlah undangan (×2 orang) + keluarga/panitia + cadangan (*buffer* %), atur komposisi porsi **Buffet (Prasmanan)** vs **Gubukan (Stall)**, hitung total biaya, dan terapkan langsung ke anggaran kategori **Katering**. |
| **Seserahan & Mahar** | Daftar rincian barang mahar & seserahan lengkap dengan harga estimasi vs harga beli aktual, catatan toko/link, filter status (*Belum Dibeli* / *Sudah Dibeli*), dan progres pembelian. |
| **Vendor** | Daftar vendor pernikahan + kontak langsung (**Telepon** & **Chat WhatsApp**), nilai kontrak, riwayat pembayaran (**DP**, **Cicilan**, **Pelunasan**), status otomatis (*Belum Bayar* / *DP* / *Lunas*), jatuh tempo, serta pencarian & filter kategori. |
| **Checklist** | Daftar tugas persiapan pernikahan (sudah terisi daftar bawaan), filter status & kategori, pencarian tugas, serta tenggat waktu. |
| **Laporan & Bagikan** | Grafik *Pie Chart* pengeluaran & anggaran per kategori, perbandingan anggaran vs realisasi, kontribusi penyetor, **Bagikan Ringkasan ke WhatsApp**, serta **Export Tabel CSV (Excel / Google Sheets)**. |
| **Pengaturan & Backup** | Profil pasangan & tanggal nikah, kelola penyetor, **Pengingat Notifikasi** (nabung bulanan & jatuh tempo H-1/Hari H), **Backup & Restore Data (JSON)** lintas perangkat, dan panduan pasang di iPhone. |

---

## 📱 Cara Menggunakan di HP

### 1. Pengguna Android (Install File `.apk`)
1. Buka tab [**Actions**](https://github.com/doaibuu007/dana-nikah/actions) di repositori GitHub ini.
2. Klik hasil *workflow* **Build APK & Web (iPhone PWA)** paling atas yang sudah centang hijau ✅.
3. Gulir ke bagian paling bawah (**Artifacts**) ➔ unduh **`dana-nikah-apk`**.
4. Ekstrak file `.zip` tersebut untuk mendapatkan `app-release.apk`, lalu pasang (*install*) di HP Android Anda.

### 2. Pengguna iPhone / iOS (Install Web App / PWA via Safari)
Tanpa perlu App Store atau colok kabel ke laptop, aplikasi dapat dipasang ke layar utama iPhone:
1. Buka link **[https://doaibuu007.github.io/dana-nikah/](https://doaibuu007.github.io/dana-nikah/)** menggunakan browser **Safari** di iPhone.
2. Ketuk tombol **Share / Bagikan** (ikon kotak dengan panah ke atas di bagian bawah layar Safari).
3. Geser ke bawah lalu pilih **"Add to Home Screen"** (*Tambahkan ke Layar Utama*) ➔ ketuk **Add** (*Tambah*).
4. Ikon **Dana Nikah 💍** akan muncul di layar utama iPhone dan berjalan **layar penuh (*full-screen*)** serta tetap berfungsi saat *offline*.

> **Catatan Aktivasi GitHub Pages (untuk pemilik repositori):**
> Pastikan repositori berstatus **Public**, lalu buka **Settings ➔ Pages**, dan pada bagian **Branch** pilih **`gh-pages`** (`/root`) lalu klik **Save**.

---

## 🔄 Cara Sinkronisasi Data Antara Android & iPhone Pasangan

Karena aplikasi bekerja secara *offline* demi privasi, Anda dan pasangan dapat menyamakan data kapan saja dengan langkah berikut:
1. Di HP pertama: buka menu **Pengaturan** ➔ **Backup Data (Salin / Kirim WA)** ➔ kirim kode JSON backup ke WhatsApp pasangan (atau klik **Salin Backup**).
2. Di HP kedua (Android maupun iPhone): salin pesan kode JSON tersebut, lalu buka **Pengaturan** ➔ **Restore Data dari Backup** ➔ tempel (*paste*) kode dan ketuk **Pulihkan Data**.

---

## 🗂️ Struktur Proyek

```text
├── lib/
│   ├── main.dart                           # Entry point aplikasi
│   ├── app.dart                            # MaterialApp, tema, lokalisasi Indonesia
│   ├── theme.dart                          # Palet warna dusty pink / rose gold
│   ├── models/
│   │   └── models.dart                     # Model data (Profil, Kategori, Vendor, Seserahan, dll)
│   ├── data/
│   │   ├── database.dart                   # Penyimpanan lokal (SQLite di Android & LocalStorage di Web/iPhone)
│   │   └── app_state.dart                  # State management (Provider), kalkulasi & pengingat
│   ├── services/
│   │   └── notification_service.dart       # Penjadwalan notifikasi lokal
│   ├── utils/
│   │   ├── format.dart                     # Format Rupiah & tanggal Indonesia
│   │   ├── category_icons.dart             # Pemetaan ikon kategori anggaran
│   │   └── exporter.dart                   # Generator laporan WhatsApp & Export CSV
│   ├── widgets/
│   │   └── common.dart                     # Komponen UI bersama (AppCard, MoneyField, SearchBarField)
│   └── screens/
│       ├── home_shell.dart                 # Navigasi bawah utama
│       ├── onboarding_screen.dart          # Layar awal pengaturan profil pernikahan
│       ├── dashboard_screen.dart           # Beranda & ringkasan progres
│       ├── savings_screen.dart             # Tabungan & setoran per penyetor
│       ├── budget_screen.dart              # Anggaran kategori & Generator Anggaran Otomatis
│       ├── category_detail_screen.dart     # Detail pengeluaran & vendor per kategori
│       ├── payments_screen.dart            # Riwayat semua pengeluaran + pencarian & filter
│       ├── catering_calculator_screen.dart # Kalkulator tamu & porsi katering
│       ├── seserahan_screen.dart           # Rincian barang mahar & seserahan
│       ├── vendors_screen.dart             # Daftar vendor + pencarian & filter
│       ├── vendor_detail_screen.dart       # Detail kontrak & pembayaran vendor
│       ├── checklist_screen.dart           # Daftar tugas persiapan pernikahan
│       ├── report_screen.dart              # Laporan grafik pie chart, WA & CSV
│       ├── settings_screen.dart            # Pengaturan, pengingat, Backup & Restore JSON
│       └── profile_form_screen.dart        # Form edit profil pasangan & target dana
├── android/                                # Konfigurasi Android (Gradle, Manifest, Adaptive Icon)
├── web/                                    # Konfigurasi PWA iPhone / Safari (index.html & manifest.json)
├── test/
│   └── format_test.dart                    # Unit test format, model, & kalkulasi anggaran
└── .github/workflows/
    └── build-apk.yml                       # CI/CD otomatis: Build APK Android & Deploy Web PWA ke GitHub Pages
```

---

## 🛠️ Menjalankan Secara Lokal (Opsional)

Jika ingin menjalankan atau memodifikasi kode di komputer yang memiliki Flutter SDK:

```bash
# 1. Unduh dependensi
flutter pub get

# 2. Jalankan unit test
flutter test

# 3. Jalankan di browser (Web / PWA)
flutter run -d chrome

# 4. Build APK Android (Release)
flutter build apk --release

# 5. Build Web PWA (Release)
flutter build web --release
```
