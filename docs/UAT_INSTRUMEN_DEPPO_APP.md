# UAT Instrument - Depo App

## 1. Tujuan
Dokumen ini adalah instrumen User Acceptance Test (UAT) untuk sistem mobile `Depo App`. Instrumen ini berisi skenario, langkah, dan hasil yang diharapkan untuk memastikan fitur utama sistem bekerja sesuai kebutuhan pengguna.

## 2. Petunjuk Penggunaan
1. Siapkan lingkungan aplikasi dan backend berjalan.
2. Gunakan akun tester untuk role `Crew` dan `Manager`.
3. Jalankan setiap skenario dan isi kolom `Hasil Aktual` dan `Catatan`.
4. Beri status `Pass`, `Fail`, atau `Blocked`.

Format test case:
- ID
- Fitur
- Tujuan
- Precondition
- Langkah UAT
- Hasil yang Diharapkan
- Status
- Hasil Aktual
- Catatan

---

## 3. Lingkungan UAT
- Backend: Laravel API, port `8000`
- Database: MySQL
- Mobile app: Flutter android/iOS
- Backend API Laravel aktif dan dapat diakses melalui `API_BASE_URL`

---

## 4. UAT Role: Crew

### TC-CR-01: Login Crew
- Fitur: Autentikasi Crew
- Tujuan: Memastikan Crew dapat login dengan credential valid
- Precondition: Aplikasi menampilkan layar role selection dan backend aktif
- Langkah UAT:
  1. Buka aplikasi.
  2. Pilih role `Crew`.
  3. Masukkan `username` dan `password` valid.
  4. Klik `Login`.
- Hasil yang Diharapkan:
  - Login berhasil.
  - Aplikasi navigasi ke Dashboard Crew.
  - Token disimpan di secure storage.
- Status:
- Hasil Aktual:
- Catatan:

### TC-CR-02: Logout Crew
- Fitur: Logout
- Tujuan: Memastikan Crew bisa logout dan session dihapus
- Precondition: Crew sudah login dan berada di menu Settings atau akunnya aktif
- Langkah UAT:
  1. Akses menu `Settings` atau `Profile`.
  2. Klik tombol `Logout`.
  3. Konfirmasi logout.
- Hasil yang Diharapkan:
  - Session dihapus.
  - Aplikasi kembali ke layar role selection atau login.
  - Token tidak lagi valid untuk API.
- Status:
- Hasil Aktual:
- Catatan:

### TC-CR-03: Tambah Pelanggan Baru
- Fitur: Manajemen Pelanggan
- Tujuan: Memastikan Crew bisa menambahkan pelanggan baru saat membuat transaksi
- Precondition: Crew sudah login dan berada di alur buat transaksi
- Langkah UAT:
  1. Pilih menu `Tambah Pelanggan Baru`.
  2. Isi nama pelanggan, nomor HP, alamat, dan data wajib lain.
  3. Klik `Simpan`.
- Hasil yang Diharapkan:
  - Data pelanggan tersimpan di server.
  - Aplikasi kembali ke alur transaksi.
  - Pelanggan baru dipilih otomatis.
- Status:
- Hasil Aktual:
- Catatan:

### TC-CR-04: Buat Transaksi Baru (Cash)
- Fitur: Transaksi Penjualan
- Tujuan: Memastikan Crew dapat membuat transaksi jual beli tunai
- Precondition: Crew sudah login dan pelanggan terpilih
- Langkah UAT:
  1. Buka halaman `Buat Transaksi`.
  2. Pilih pelanggan.
  3. Tambahkan minimal 1 item produk ke keranjang.
  4. Pilih metode pembayaran `Cash`.
  5. Input nominal diterima.
  6. Konfirmasi pembayaran.
  7. Simpan transaksi.
- Hasil yang Diharapkan:
  - Transaksi berhasil dibuat dengan status `PENDING`.
  - Total dan kembalian tampil benar.
  - Detail transaksi tersimpan di backend.
- Status:
- Hasil Aktual:
- Catatan:

### TC-CR-05: Buat Transaksi Baru (QRIS)
- Fitur: Pembayaran QRIS
- Tujuan: Memastikan alur QRIS berjalan dan status dibaca
- Precondition: Crew sudah login, backend dan payment simulator aktif
- Langkah UAT:
  1. Buka halaman `Buat Transaksi`.
  2. Pilih pelanggan dan isi keranjang.
  3. Pilih metode pembayaran `QRIS`.
  4. Lihat QR code muncul.
  5. Lakukan simulasi pembayaran (jika ada endpoint sandbox).
  6. Tunggu status menjadi `paid` di aplikasi.
- Hasil yang Diharapkan:
  - QR code tampil.
  - Status pembayaran berganti ke `sukses` setelah simulasi.
  - Transaksi dapat disimpan dengan status `PENDING` menunggu validasi manager.
- Status:
- Hasil Aktual:
- Catatan:

### TC-CR-06: Buat Transaksi Baru (Transfer)
- Fitur: Pembayaran Transfer
- Tujuan: Memastikan alur pembayaran transfer ditampilkan dengan jelas
- Precondition: Crew sudah login dan pelanggan dipilih
- Langkah UAT:
  1. Buat transaksi seperti biasa.
  2. Pilih metode pembayaran `Transfer`.
  3. Verifikasi informasi rekening bank tampil.
  4. Konfirmasi transaksi.
- Hasil yang Diharapkan:
  - Informasi rekening tampil.
  - Transaksi tersimpan dengan status `PENDING`.
- Status:
- Hasil Aktual:
- Catatan:

### TC-CR-07: Lihat Riwayat Transaksi Crew
- Fitur: Riwayat Transaksi
- Tujuan: Memastikan Crew bisa melihat transaksi yang dibuat sendiri
- Precondition: Crew sudah login dan ada transaksi sebelumnya
- Langkah UAT:
  1. Masuk ke menu `Riwayat Transaksi`.
  2. Periksa daftar transaksi muncul.
  3. Cari transaksi berdasarkan nomor atau nama pelanggan.
  4. Buka detail transaksi.
- Hasil yang Diharapkan:
  - Daftar transaksi menampilkan data yang benar.
  - Filter/ pencarian bekerja.
  - Detail transaksi menampilkan informasi lengkap.
- Status:
- Hasil Aktual:
- Catatan:

### TC-CR-08: Manajemen Galon Pinjam/Kembali
- Fitur: Tracking Galon
- Tujuan: Memastikan input pinjam/kembali galon terekam benar
- Precondition: Crew sudah login dan membuat transaksi dengan galon pinjam/kembali
- Langkah UAT:
  1. Saat membuat transaksi, input jumlah galon pinjam.
  2. Input jumlah galon kembali jika ada.
  3. Simpan transaksi.
  4. Periksa perubahan status galon di sistem.
- Hasil yang Diharapkan:
  - Galon pinjam terbarui ke status `dipinjam`.
  - Galon kembali terbarui ke `tersedia`.
  - Total galon pinjam pelanggan diperbarui.
- Status:
- Hasil Aktual:
- Catatan:

### TC-CR-09: Tambah & Lihat Daftar Pelanggan
- Fitur: Daftar Pelanggan
- Tujuan: Memastikan fitur pencarian dan tampilan pelanggan bekerja
- Precondition: Crew sudah login
- Langkah UAT:
  1. Masuk ke menu `Pelanggan`.
  2. Pencarian pelanggan dengan nama atau nomor HP.
  3. Pilih 1 pelanggan dan lihat detail.
- Hasil yang Diharapkan:
  - Semua pelanggan tampil.
  - Pencarian memfilter data.
  - Detail pelanggan menampilkan riwayat transaksi dan total galon pinjam.
- Status:
- Hasil Aktual:
- Catatan:

---

## 5. UAT Role: Manager

### TC-MG-01: Login Manager
- Fitur: Autentikasi Manager
- Tujuan: Memastikan Manager dapat login dengan credential valid
- Precondition: Aplikasi backend aktif dan manager memiliki akun
- Langkah UAT:
  1. Buka aplikasi.
  2. Pilih role `Manager`.
  3. Masukkan email dan password.
  4. Klik `Login`.
- Hasil yang Diharapkan:
  - Login berhasil.
  - Navigasi ke Dashboard Manager.
  - Token tersimpan.
- Status:
- Hasil Aktual:
- Catatan:

### TC-MG-02: Lihat Dashboard Manager
- Fitur: Dashboard Analitik
- Tujuan: Memastikan dashboard menampilkan metrik dan notifikasi transaksi pending
- Precondition: Manager sudah login
- Langkah UAT:
  1. Setelah login, lihat tampilan dashboard.
  2. Periksa widget `Transaksi Menunggu Validasi`, total penjualan, dan chart.
  3. Klik menu `Validasi Transaksi` jika tersedia.
- Hasil yang Diharapkan:
  - Dashboard menampilkan metrik penting.
  - Data summary relevan dan tidak kosong.
  - Link navigasi berfungsi.
- Status:
- Hasil Aktual:
- Catatan:

### TC-MG-03: Validasi Transaksi Crew - Approve
- Fitur: Validasi Transaksi
- Tujuan: Memastikan Manager dapat approve transaksi pending
- Precondition: Ada transaksi `PENDING` dari Crew
- Langkah UAT:
  1. Buka menu `Validasi Transaksi`.
  2. Pilih transaksi pending.
  3. Review detail transaksi: produk, pelanggan, galon, pembayaran.
  4. Klik `Approve`.
  5. Konfirmasi aksi.
- Hasil yang Diharapkan:
  - Status transaksi berubah dari `PENDING` ke `APPROVED` atau `SELESAI`.
  - Stok produk ter-update sesuai jumlah terjual.
  - Notifikasi atau pesan sukses tampil.
- Status:
- Hasil Aktual:
- Catatan:

### TC-MG-04: Validasi Transaksi Crew - Reject
- Fitur: Validasi Transaksi
- Tujuan: Memastikan Manager dapat reject transaksi dengan alasan
- Precondition: Ada transaksi `PENDING` dari Crew
- Langkah UAT:
  1. Buka menu `Validasi Transaksi`.
  2. Pilih transaksi pending.
  3. Klik `Reject`.
  4. Pilih alasan penolakan dan isi catatan tambahan.
  5. Konfirmasi reject.
- Hasil yang Diharapkan:
  - Status transaksi menjadi `REJECTED` atau `DIBATALKAN`.
  - Stok tidak berubah atau dikembalikan bila sebelumnya ter-commit.
  - Notifikasi reject dikirim ke Crew.
- Status:
- Hasil Aktual:
- Catatan:

### TC-MG-05: Lihat Laporan Penjualan & Keuangan
- Fitur: Laporan Keuangan
- Tujuan: Memastikan Manager bisa generate laporan periode
- Precondition: Manager sudah login
- Langkah UAT:
  1. Masuk ke menu `Laporan Keuangan` atau `Laporan`.
  2. Set periode tanggal (hari ini / minggu ini / custom).
  3. Klik `Generate Laporan`.
  4. Periksa ringkasan, breakdown pembayaran, top produk, dan top pelanggan.
  5. Klik `Export PDF` jika tersedia.
- Hasil yang Diharapkan:
  - Laporan tampil sesuai periode.
  - Nilai penjualan, jumlah transaksi, dan grafik akurat.
  - Ekspor PDF berhasil (jika fitur ada).
- Status:
- Hasil Aktual:
- Catatan:

### TC-MG-06: Manajemen Stok & Produk
- Fitur: Stok Produk
- Tujuan: Memastikan Manager dapat melihat dan mengubah stok produk
- Precondition: Manager sudah login
- Langkah UAT:
  1. Masuk ke menu `Manajemen Stok` atau `Produk`.
  2. Lihat daftar produk dengan stok dan status.
  3. Pilih produk untuk edit stok/harga.
  4. Simpan perubahan.
- Hasil yang Diharapkan:
  - Data produk tampil lengkap.
  - Edit produk menyimpan perubahan ke backend.
- Status:
- Hasil Aktual:
- Catatan:

### TC-MG-07: Manajemen Pelanggan
- Fitur: Daftar Pelanggan
- Tujuan: Memastikan Manager dapat melihat dan mencari data pelanggan
- Precondition: Manager sudah login
- Langkah UAT:
  1. Buka menu `Pelanggan`.
  2. Cari pelanggan dengan nama atau nomor HP.
  3. Buka detail pelanggan.
- Hasil yang Diharapkan:
  - Semua pelanggan muncul.
  - Cari berfungsi.
  - Detail pelanggan menampilkan ringkasan transaksi dan galon pinjam.
- Status:
- Hasil Aktual:
- Catatan:

---

## 6. UAT Tambahan

### TC-AD-01: Error Handling Server Down
- Fitur: Konektivitas
- Tujuan: Memastikan aplikasi menangani server offline dengan baik
- Precondition: Backend dimatikan
- Langkah UAT:
  1. Buka aplikasi.
  2. Lakukan login atau panggil API.
- Hasil yang Diharapkan:
  - Muncul pesan error koneksi.
  - Aplikasi tidak crash.
- Status:
- Hasil Aktual:
- Catatan:

### TC-AD-02: Role Access Control
- Fitur: Kontrol Akses
- Tujuan: Memastikan Crew tidak dapat mengakses fitur Manager dan sebaliknya
- Precondition: Login sebagai Crew dan Manager
- Langkah UAT:
  1. Login dengan role Crew dan periksa menu.
  2. Login dengan role Manager dan periksa menu.
- Hasil yang Diharapkan:
  - Crew hanya melihat fitur Crew.
  - Manager melihat fitur Manager lengkap.
- Status:
- Hasil Aktual:
- Catatan:

### TC-AD-03: Validasi Input Form
- Fitur: Validasi Form
- Tujuan: Memastikan form tidak menerima input kosong atau invalid
- Precondition: Login sebagai Crew atau Manager
- Langkah UAT:
  1. Buka form login, pelanggan, transaksi, atau produk.
  2. Isi field dengan data invalid atau kosong.
  3. Coba simpan.
- Hasil yang Diharapkan:
  - Muncul error validasi sesuai field.
  - Data tidak disubmit.
- Status:
- Hasil Aktual:
- Catatan:

---

## 7. Catatan Evaluasi
- Gunakan UAT ini bersama data uji yang realistis (pelanggan, produk, stok, transaksi).
- Jika ada fitur tambahan di aplikasi, tambahkan test case baru di dokumen ini.
- Simpan hasil UAT untuk laporan akhir skripsi.
