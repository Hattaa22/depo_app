# 📱 FITUR-FITUR SISTEM & IMPLEMENTASI
## Depo Air Management System - Features & Implementation Details

---

## 1. FITUR AUTENTIKASI & MANAJEMEN PENGGUNA

### 1.1 Role Selection Screen

**Tujuan**: User memilih role sebelum login

**Flow:**
```
App Start
    ↓
Check Local Token
    ├─ Token Valid → Redirect ke Dashboard
    └─ Token Expired/None → Tampilkan Role Selection
         ↓
    ┌─────────────────────────┐
    │  Pilih Peran Anda        │
    │                          │
    │  [  Login Crew  ]        │
    │  [  Login Manager  ]     │
    │                          │
    └─────────────────────────┘
         │
    ┌────┴────┐
    │         │
 Crew    Manager
    │         │
    ▼         ▼
Login1   Login2
```

**Implementasi:**
- StatefulWidget untuk track pilihan user
- LocalStorage untuk cek token yang ada
- Routing ke login screen yang sesuai

### 1.2 Login Crew

**Input Fields:**
- Username (required)
- Password (required, masked)

**Validasi Client-side:**
```
├─ Username: Min 3 karakter
├─ Password: Min 6 karakter
├─ Format: No special characters untuk username
└─ Empty check: Jangan biarkan kosong
```

**Proses:**
```
User input credentials
    ↓
Client validation
    ├─ Invalid → Show error snackbar
    └─ Valid → Send to server
         ↓
    POST /api/auth/login
    Body: { username, password }
         ↓
    Server Process
    ├─ Validate format
    ├─ Check user exists
    ├─ Verify password (bcrypt)
    ├─ Check role is 'crew'
    ├─ Generate tokens (JWT)
    └─ Return { token, refreshToken, user }
         ↓
    Client receive response
    ├─ Save token ke SecureStorage (encrypted)
    ├─ Save user data ke SharedPreferences
    ├─ Set GetX controller state
    └─ Navigate to CrewDashboard
```

**Error Handling:**
- 400: Invalid input format
- 401: Wrong credentials
- 403: User is not crew
- 404: User not found
- 500: Server error

### 1.3 Login Manager

**Perbedaan dari Crew Login:**
- Login menggunakan email (bukan username)
- Role harus 'manager'
- Redirect ke ManagerDashboard

### 1.4 Token Management

**Token Storage:**
```
Access Token (8 hours)
├─ Disimpan di: FlutterSecureStorage (encrypted)
├─ Dipakai untuk: Authorize setiap API request
├─ Auto refresh: 7 jam 30 menit dari login
└─ Saat expired: Gunakan refresh token untuk get baru

Refresh Token (30 days)
├─ Disimpan di: FlutterSecureStorage (encrypted)
├─ Dipakai untuk: Mendapatkan access token baru
├─ Disimpan di DB: refresh_tokens table
└─ Saat expired: Force user untuk login ulang
```

**Auto Refresh Logic:**
```
Before setiap API request:
    ├─ Get token dari storage
    ├─ Decode JWT (tanpa verify)
    ├─ Check expiry time
    ├─ If expiry < 30 menit:
    │  └─ POST /api/auth/refresh
    │     ├─ Verify refresh token
    │     ├─ Generate new access token
    │     ├─ Store new token
    │     └─ Continue dengan request baru
    └─ Lanjut dengan existing token
```

**Logout:**
```
User tap Logout
    ↓
POST /api/auth/logout
├─ Delete refresh token dari DB
├─ Clear token dari storage
├─ Clear user data
├─ Clear controller state
└─ Navigate ke PilihPeran screen
```

---

## 2. FITUR TRANSAKSI PENJUALAN

### 2.1 Kasir Screen (Create Transaction)

**Layout:**
```
┌──────────────────────────────────┐
│  KASIR - Buat Transaksi          │
├──────────────────────────────────┤
│ ┌──────────────────────────────┐ │
│ │ Pilih Pelanggan              │ │
│ │ [Budi Santoso           ▼  ] │ │
│ └──────────────────────────────┘ │
│                                  │
│ ┌──────────────────────────────┐ │
│ │ Produk Tersedia              │ │
│ │ ┌────────────────────────┐   │ │
│ │ │ Air Galon Isi   Rp 20k│   │ │
│ │ │ [+] Qty: 0      [-]   │   │ │
│ │ └────────────────────────┘   │ │
│ │ ┌────────────────────────┐   │ │
│ │ │ Air Galon Kosong Rp 8k│   │ │
│ │ │ [+] Qty: 0      [-]   │   │ │
│ │ └────────────────────────┘   │ │
│ │         ... (scroll)          │ │
│ └──────────────────────────────┘ │
│                                  │
│ ┌──────────────────────────────┐ │
│ │ KERANJANG                    │ │
│ │ ┌────────────────────────┐   │ │
│ │ │ Air Galon Isi × 5      │   │ │
│ │ │ Rp 100.000       [×]   │   │ │
│ │ └────────────────────────┘   │ │
│ │ ┌────────────────────────┐   │ │
│ │ │ Air Galon Kosong × 3   │   │ │
│ │ │ Rp 24.000        [×]   │   │ │
│ │ └────────────────────────┘   │ │
│ │                              │ │
│ │ SUBTOTAL:    Rp 124.000      │ │
│ │ TOTAL:       Rp 124.000      │ │
│ │                              │ │
│ │ Galon Pinjam: [3] Kembali: [1]
│ └──────────────────────────────┘ │
│                                  │
│ ┌──────────────────────────────┐ │
│ │ Metode Pembayaran:           │ │
│ │ ● Cash   ○ QRIS   ○ Transfer │ │
│ └──────────────────────────────┘ │
│                                  │
│       [SIMPAN] [BATAL]           │
└──────────────────────────────────┘
```

**Process Flow:**

```
1. SELECT PELANGGAN
   ┌─────────────────────────────┐
   │ Tap: "Pilih Pelanggan"      │
   │ ↓                           │
   │ Show dialog pelanggan list  │
   │ [Search: ______]            │
   │ • Budi Santoso              │
   │ • Citra Dewi                │
   │ • Diana Putri               │
   │ [+ Tambah Pelanggan Baru]   │
   └─────────────────────────────┘
   
   ├─ Pilih existing → Load customer
   └─ Tambah baru → Open form
      └─ Input nama, no_hp, alamat
      └─ Save & select

2. ADD ITEM TO CART
   ┌─────────────────────────────┐
   │ Tap [+] di samping produk   │
   │ ↓                           │
   │ Show quantity dialog:       │
   │ Masukkan jumlah: [1]        │
   │ [TAMBAH] [BATAL]            │
   │ ↓                           │
   │ Add ke cart + update total  │
   └─────────────────────────────┘

3. EDIT ITEM
   ┌─────────────────────────────┐
   │ Long press di cart item     │
   │ ↓                           │
   │ Show dialog:                │
   │ Jumlah: [5] [−] [+]         │
   │ [UPDATE] [HAPUS] [BATAL]    │
   └─────────────────────────────┘

4. PILIH METODE PEMBAYARAN
   ┌─────────────────────────────┐
   │ Radio button:               │
   │ ● Cash   ○ QRIS   ○ Transfer│
   │                             │
   │ Jika QRIS:                  │
   │ ├─ Input nominal bayar      │
   │ └─ [GENERATE QR]            │
   │                             │
   │ Jika Cash/Transfer:         │
   │ ├─ Input nominal bayar      │
   │ └─ Hitung kembalian         │
   └─────────────────────────────┘

5. SUBMIT TRANSACTION
   ┌─────────────────────────────┐
   │ Validasi:                   │
   │ ✓ Pelanggan dipilih         │
   │ ✓ Min 1 item di keranjang   │
   │ ✓ Metode pembayaran dipilih │
   │                             │
   │ POST /api/transaksi         │
   │ ├─ Create transaksi (pending)
   │ ├─ Insert items             │
   │ ├─ Update stock produk      │
   │ ├─ Update galon status      │
   │ └─ Return nomor_transaksi   │
   │                             │
   │ Jika success:               │
   │ ├─ Show sukses dialog       │
   │ ├─ Nomor: TRX-20240619-001  │
   │ ├─ Show [PRINT] [TUTUP]     │
   │ └─ Clear cart & pelanggan   │
   │                             │
   │ Jika gagal:                 │
   │ └─ Show error message       │
   └─────────────────────────────┘
```

### 2.2 Payment QRIS Flow

**Alur Pembayaran QRIS:**

```
User memilih QRIS
    ↓
┌──────────────────────────────┐
│ PEMBAYARAN QRIS              │
├──────────────────────────────┤
│                              │
│ Jumlah: Rp 124.000           │
│                              │
│ Waktu kadaluarsa:            │
│ 00:05:00 (countdown)         │
│                              │
│ ┌──────────────────────────┐ │
│ │                          │ │
│ │    ┌─────────────────┐   │ │
│ │    │ ╔══════════════╗ │   │ │
│ │    │ ║ QR CODE IMG  ║ │   │ │
│ │    │ ║              ║ │   │ │
│ │    │ ╚══════════════╝ │   │ │
│ │    │                 │   │ │
│ │    │ Scan dengan app │   │ │
│ │    │ QRIS yang      │   │ │
│ │    │ tersedia        │   │ │
│ │    └─────────────────┘   │ │
│ │                          │ │
│ └──────────────────────────┘ │
│                              │
│ Status: Menunggu pembayaran  │
│                              │
│       [BATALKAN]             │
└──────────────────────────────┘
    │
    ├─ Polling status setiap 2 detik
    │  POST /api/qr-payment/{paymentId}/status
    │
    ├─ Pembayaran berhasil
    │  Status → PAID
    │  Update transaksi status
    │  ↓
    │  ┌──────────────────────────────┐
    │  │ PEMBAYARAN BERHASIL!         │
    │  │ Rp 124.000                   │
    │  │ Nomor Transaksi: TRX-001     │
    │  │ Waktu: 10:30:45              │
    │  │ [CETAK] [SELESAI]            │
    │  └──────────────────────────────┘
    │
    └─ Timeout
       Status → EXPIRED
       ↓
       ┌──────────────────────────────┐
       │ QR CODE KADALUARSA           │
       │ Silakan coba lagi            │
       │ [GENERATE ULANG] [BATAL]     │
       └──────────────────────────────┘
```

### 2.3 Transaction History & Validation

**Riwayat Transaksi (Crew View):**
```
GET /api/transaksi?crew_id={crewId}&limit=20

Response:
[
  {
    id: "txn_001",
    nomor_transaksi: "TRX-20240619-001",
    pelanggan_nama: "Budi Santoso",
    total_harga: 124000,
    status: "completed",
    status_validasi: "approved",
    metode_pembayaran: "QRIS",
    created_at: "2024-06-19T10:30:45Z"
  },
  ...
]
```

**Validasi Transaksi (Manager View):**
```
GET /api/transaksi?status=pending

┌─────────────────────────────────────┐
│ VALIDASI TRANSAKSI                  │
├─────────────────────────────────────┤
│ Filter: Semua (pending)              │
│                                     │
│ ┌──────────────────────────────────┐│
│ │ TRX-20240619-001                 ││
│ │ Crew: Andri (Kasir 1)            ││
│ │ Pelanggan: Budi Santoso          ││
│ │ Total: Rp 124.000                ││
│ │ Status: Pending                  ││
│ │ [DETAIL] [TERIMA] [TOLAK]        ││
│ └──────────────────────────────────┘│
│                                     │
│ [Scroll untuk transaksi lainnya]    │
└─────────────────────────────────────┘

Manager tap TERIMA:
    ├─ PUT /api/transaksi/{id}/validasi
    ├─ Body: { status_validasi: "approved" }
    ├─ Update status di DB
    ├─ Send notification to crew
    └─ Show success message

Manager tap TOLAK:
    ├─ Show dialog alasan penolakan
    ├─ PUT /api/transaksi/{id}/validasi
    ├─ Body: { status_validasi: "rejected", alasan: "..." }
    ├─ Rollback transaksi (restore stock)
    ├─ Send notification to crew
    └─ Show success message
```

---

## 3. FITUR MANAJEMEN GALON

### 3.1 Galon Tracking

**Status Galon:**
```
TERSEDIA
    ├─ Galon kosong atau sudah dicuci
    ├─ Siap untuk dipinjam
    └─ Tidak ada pemilik
    
DIPINJAM
    ├─ Galon sedang ada di tangan pelanggan
    ├─ Tercatat nama pelanggan
    └─ Menunggu dikembalikan
    
RUSAK
    ├─ Galon pecah atau tidak layak pakai
    ├─ Tidak bisa dipinjam lagi
    └─ Perlu diganti/perbaiki
    
HILANG
    ├─ Galon tidak ditemukan
    ├─ Tidak bisa dipinjam lagi
    └─ Perlu dibuat laporan
```

**Pencatatan Galon Pinjam/Kembali:**

```
SAAT TRANSAKSI (Crew)
│
├─ Input jumlah galon yang dipinjam
├─ System update status galon ke "DIPINJAM"
├─ Catat pelanggan_id di tabel galon
├─ Create record di galon_mutasi
│  (aksi: "pinjam", jumlah: X, status_ke: "dipinjam")
│
├─ Input jumlah galon yang dikembalikan
├─ System update status galon ke "TERSEDIA"
├─ Clear pelanggan_id dari tabel galon
├─ Create record di galon_mutasi
│  (aksi: "kembali", jumlah: Y, status_dari: "dipinjam")
│
└─ Update total_galon_pinjam di pelanggan table

HISTORY MUTASI (Manager Report)
│
GET /api/galon/mutasi?tanggal_dari=...&tanggal_sampai=...
│
Response:
[
  {
    id: "mut_001",
    aksi: "pinjam",
    jumlah: 5,
    pelanggan_nama: "Budi",
    crew_nama: "Andri",
    status_ke: "dipinjam",
    created_at: "2024-06-19T10:30:45Z"
  },
  {
    id: "mut_002",
    aksi: "kembali",
    jumlah: 3,
    pelanggan_nama: "Budi",
    crew_nama: "Andri",
    status_dari: "dipinjam",
    created_at: "2024-06-19T11:45:30Z"
  }
]

LAPORAN GALON (Manager Dashboard)
│
Total Galon:
├─ Tersedia: 450
├─ Dipinjam: 120
├─ Rusak: 8
└─ Hilang: 5
│
Per Merek:
├─ Merek A: 300 (Tersedia: 270, Dipinjam: 25, Rusak: 5)
├─ Merek B: 200 (Tersedia: 180, Dipinjam: 20, Rusak: 3)
└─ Merek C: 100 (Tersedia: 50, Dipinjam: 25, Rusak: 0)
│
Top 5 Pelanggan (Galon Pinjam Paling Banyak):
├─ Budi Santoso: 15 galon
├─ Citra Dewi: 12 galon
├─ Diana Putri: 10 galon
├─ Edi Wijaya: 8 galon
└─ Farah Hasna: 5 galon
│
Galon Hilang/Rusak:
├─ Galon hilang (5):
│  ├─ Kode: GAL-001 (Merek A) - Hilang sejak 2024-06-10
│  ├─ Kode: GAL-045 (Merek B) - Hilang sejak 2024-06-15
│  └─ ... (3 lainnya)
│
├─ Galon rusak (8):
│  ├─ Kode: GAL-050 (Merek A) - Pecah 2024-06-18
│  ├─ Kode: GAL-078 (Merek B) - Crack 2024-06-19
│  └─ ... (6 lainnya)
```

---

## 4. FITUR MANAJEMEN DATA

### 4.1 Manajemen Produk

**Manager dapat:**
```
1. LIHAT DAFTAR PRODUK
   GET /api/produk?kategori_id=...&limit=20
   
   Display:
   ├─ Nama produk
   ├─ Kategori
   ├─ Harga
   ├─ Stok
   ├─ Status aktif/tidak
   └─ [EDIT] [HAPUS]

2. TAMBAH PRODUK BARU
   POST /api/produk
   Body: {
     nama: "Air Galon Isi",
     kategori_id: "cat_001",
     harga: 20000,
     stok: 500,
     deskripsi: "...",
     gambar_url: "..."
   }
   
   Form:
   ├─ Nama: [_____________]
   ├─ Kategori: [Pilih ▼]
   ├─ Harga: [20000]
   ├─ Stok: [500]
   ├─ Deskripsi: [_____________]
   ├─ Upload Gambar: [PILIH FILE]
   └─ [SIMPAN] [BATAL]

3. EDIT PRODUK
   PUT /api/produk/{id}
   
   Bisa update:
   ├─ Nama produk
   ├─ Harga (akan tercatat histori perubahan)
   ├─ Stok (add/reduce)
   ├─ Deskripsi
   ├─ Status aktif/tidak
   └─ Gambar

4. HAPUS PRODUK
   DELETE /api/produk/{id}
   
   Soft delete (tidak benar-benar dihapus)
   Set: is_aktif = 0
   Keep history untuk referensi transaksi lama

5. KATEGORI PRODUK
   GET /api/kategori
   POST /api/kategori
   PUT /api/kategori/{id}
   DELETE /api/kategori/{id}
   
   Kategori terbagi:
   ├─ Pemasukan (produk penjualan)
   └─ Pengeluaran (biaya operasional)
```

### 4.2 Manajemen Pelanggan

**Crew & Manager dapat:**
```
1. LIHAT DAFTAR PELANGGAN
   ├─ Crew: Hanya pelanggan yang sudah bertransaksi dengannya
   └─ Manager: Semua pelanggan
   
   Display:
   ├─ Nama
   ├─ No. HP
   ├─ Alamat
   ├─ Total galon pinjam
   ├─ Total pembelian (Rp)
   ├─ Status aktif/tidak
   └─ [DETAIL] [EDIT] [HAPUS]

2. TAMBAH PELANGGAN BARU
   POST /api/pelanggan
   Body: {
     nama: "Budi Santoso",
     no_hp: "081234567890",
     alamat: "Jl. Mawar No. 5",
     catatan: "Prefer deliver on Sunday"
   }
   
   Form (Ada di Crew & Manager):
   ├─ Nama: [_____________]
   ├─ No. HP: [_____________]
   ├─ Alamat: [_____________]
   ├─ Catatan: [_____________]
   └─ [SIMPAN] [BATAL]

3. EDIT PELANGGAN
   PUT /api/pelanggan/{id}
   
   Bisa update:
   ├─ Nama
   ├─ No. HP
   ├─ Alamat
   ├─ Catatan
   └─ Status aktif/tidak

4. VIEW DETAIL PELANGGAN
   GET /api/pelanggan/{id}
   
   Info:
   ├─ Data dasar pelanggan
   ├─ Riwayat transaksi (10 terakhir)
   ├─ Total galon yang dipinjam saat ini
   ├─ Total pembelian (all time)
   ├─ Galon per merek yang dipinjam
   └─ Catatan khusus

5. CARI PELANGGAN
   GET /api/pelanggan?search=budi
   
   Search by:
   ├─ Nama (partial match)
   ├─ No. HP
   └─ Alamat (partial match)

6. HAPUS PELANGGAN
   DELETE /api/pelanggan/{id}
   
   Soft delete:
   ├─ Set is_aktif = 0
   ├─ Keep history transaksi
   └─ Bisa di-reactivate
```

### 4.3 Manajemen Crew (Manager Only)

**Manager dapat:**
```
1. LIHAT DAFTAR CREW
   GET /api/users?role=crew
   
   Display:
   ├─ Nama
   ├─ Username
   ├─ Email
   ├─ No. HP
   ├─ Status aktif/tidak
   ├─ Total transaksi (bulan ini)
   ├─ Total revenue (bulan ini)
   └─ [DETAIL] [EDIT] [HAPUS]

2. TAMBAH CREW BARU
   POST /api/users
   Body: {
     role: "crew",
     username: "andri_kasir",
     password: "SecurePass123",
     nama: "Andri Wijaya",
     email: "andri@depo.com",
     no_hp: "081234567890",
     alamat: "..."
   }
   
   Validasi:
   ├─ Username unik
   ├─ Username min 3 char
   ├─ Password min 6 char
   ├─ Email format valid
   └─ Password di-hash dengan bcrypt

3. EDIT CREW
   PUT /api/users/{id}
   
   Bisa update:
   ├─ Nama
   ├─ Email
   ├─ No. HP
   ├─ Alamat
   ├─ Status aktif/tidak
   ├─ Password (optional)
   └─ Role (tidak bisa diubah ke manager)

4. PERFORMANCE CREW
   GET /api/laporan/crew/{crewId}?bulan=6&tahun=2024
   
   Info:
   ├─ Total transaksi (bulan ini)
   ├─ Total revenue
   ├─ Rata-rata transaksi per hari
   ├─ Payment method breakdown
   ├─ Top 5 produk terjual
   └─ Top 5 pelanggan

5. HAPUS CREW
   DELETE /api/users/{id}
   
   Soft delete:
   ├─ Set is_aktif = 0
   ├─ Crew tidak bisa login lagi
   ├─ Keep history transaksi crew
   └─ Bisa di-reactivate
```

---

## 5. FITUR LAPORAN & ANALYTICS

### 5.1 Dashboard Crew

**Metrics:**
```
┌─────────────────────────────────────┐
│         DASHBOARD CREW              │
├─────────────────────────────────────┤
│                                     │
│ ┌─────────────────────────────────┐ │
│ │ HARI INI                        │ │
│ ├─────────────────────────────────┤ │
│ │ Transaksi: 12                   │ │
│ │ Revenue: Rp 2.480.000           │ │
│ │ Pelanggan: 8                    │ │
│ │ Cash: Rp 1.240.000 | QRIS: 50%  │ │
│ └─────────────────────────────────┘ │
│                                     │
│ ┌─────────────────────────────────┐ │
│ │ TRANSAKSI PENDING               │ │
│ │ (Menunggu validasi manager)     │ │
│ │ 3 transaksi pending             │ │
│ │ Total: Rp 640.000               │ │
│ │ [LIHAT DETAIL]                  │ │
│ └─────────────────────────────────┘ │
│                                     │
│ ┌─────────────────────────────────┐ │
│ │ TRANSAKSI TERBARU               │ │
│ │ • TRX-001 Rp 124.000 (10:30)   │ │
│ │ • TRX-002 Rp 85.000  (10:45)   │ │
│ │ • TRX-003 Rp 150.000 (11:00)   │ │
│ │ [LIHAT SEMUA]                   │ │
│ └─────────────────────────────────┘ │
│                                     │
│ [MULAI TRANSAKSI BARU]              │
│ [LIHAT RIWAYAT]  [PENCATATAN GALON] │
└─────────────────────────────────────┘
```

### 5.2 Dashboard Manager

**Metrics & Charts:**
```
┌─────────────────────────────────────────────────────────┐
│               MANAGER DASHBOARD                         │
├─────────────────────────────────────────────────────────┤
│                                                         │
│  ┌──────────────┬──────────────┬──────────────┐        │
│  │ Hari Ini     │ Bulan Ini    │ Total All    │        │
│  │ Rp 2.480K    │ Rp 74.560K   │ Rp 2.486.5M  │        │
│  │ (12 txn)     │ (342 txn)    │ (18.3K txn)  │        │
│  └──────────────┴──────────────┴──────────────┘        │
│                                                         │
│  ┌──────────────────────────────────────────────┐      │
│  │ REVENUE TREND (Last 30 Days)                │      │
│  │ [CHART: Line graph showing daily revenue]   │      │
│  │ Peak: 19 June - Rp 3.2M                    │      │
│  └──────────────────────────────────────────────┘      │
│                                                         │
│  ┌─────────────────────┬──────────────────────┐       │
│  │ TOP 5 PRODUK        │ TOP 5 PELANGGAN      │       │
│  ├─────────────────────┼──────────────────────┤       │
│  │ 1. Air Galon Isi    │ 1. Budi Santoso      │       │
│  │    (850 unit)       │    Rp 3.2M           │       │
│  │ 2. Air Galon Kosong │ 2. Citra Dewi        │       │
│  │    (620 unit)       │    Rp 2.8M           │       │
│  │ 3. Mineralizer      │ 3. Diana Putri       │       │
│  │    (145 unit)       │    Rp 2.1M           │       │
│  │ 4. Cooler Rental    │ 4. Edi Wijaya        │       │
│  │    (42 unit)        │    Rp 1.9M           │       │
│  │ 5. Delivery Fee     │ 5. Farah Hasna       │       │
│  │    (1,200 unit)     │    Rp 1.5M           │       │
│  └─────────────────────┴──────────────────────┘       │
│                                                         │
│  ┌──────────────────────────────────────────────┐      │
│  │ PAYMENT METHOD BREAKDOWN                    │      │
│  │ Cash: 45% (Rp 33.6M)                        │      │
│  │ QRIS: 48% (Rp 35.8M)                        │      │
│  │ Transfer: 7% (Rp 5.2M)                      │      │
│  │ [PIE CHART]                                 │      │
│  └──────────────────────────────────────────────┘      │
│                                                         │
│  ┌──────────────────────────────────────────────┐      │
│  │ QUICK ACTIONS                               │      │
│  │ [LIHAT TRANSAKSI PENDING] [LAPORAN]         │      │
│  │ [ANALISIS KEUANGAN] [ASSET GALON]           │      │
│  │ [CREW PERFORMANCE] [MANAJEMEN DATA]         │      │
│  └──────────────────────────────────────────────┘      │
│                                                         │
└─────────────────────────────────────────────────────────┘
```

### 5.3 Laporan Komprehensif

**Laporan Penjualan:**
```
GET /api/laporan/penjualan
Query: {
  tanggal_dari: "2024-06-01",
  tanggal_sampai: "2024-06-30",
  crew_id: "crew_001",
  metode: "all",
  limit: 100
}

Response:
{
  period: "1 - 30 June 2024",
  crew: "Andri Wijaya",
  summary: {
    total_transaksi: 342,
    total_revenue: Rp 74.560.000,
    rata_rata_transaksi: Rp 218.011,
    transaksi_sukses: 320,
    transaksi_ditolak: 22
  },
  by_payment_method: {
    cash: { count: 154, total: Rp 33.614.000 },
    qris: { count: 164, total: Rp 35.816.000 },
    transfer: { count: 24, total: Rp 5.130.000 }
  },
  by_date: [
    { date: "2024-06-01", transaksi: 8, revenue: Rp 1.840.000 },
    { date: "2024-06-02", transaksi: 12, revenue: Rp 2.640.000 },
    ...
  ],
  top_produk: [
    { produk: "Air Galon Isi", qty: 850, revenue: Rp 17.000.000 },
    { produk: "Air Galon Kosong", qty: 620, revenue: Rp 4.960.000 },
    ...
  ]
}

Export to:
├─ PDF
├─ Excel
└─ Print
```

**Laporan Keuangan:**
```
GET /api/laporan/keuangan
Query: {
  bulan: 6,
  tahun: 2024
}

Response:
{
  period: "June 2024",
  revenue: {
    penjualan: Rp 74.560.000,
    komisi: Rp 500.000,
    total: Rp 75.060.000
  },
  expense: {
    gaji: Rp 12.000.000,
    asuransi: Rp 2.000.000,
    utilitas: Rp 3.500.000,
    maintenance: Rp 1.200.000,
    marketing: Rp 800.000,
    lainnya: Rp 500.000,
    total: Rp 20.000.000
  },
  net_profit: Rp 55.060.000,
  profit_margin: 73.4%
}
```

---

## 6. USER EXPERIENCE & INTERFACE

### 6.1 Theme & Colors

**Color Palette:**
```
Primary Colors:
├─ Brand Blue: #1E88E5 (Main actions, buttons)
├─ Success Green: #43A047 (Success states)
├─ Warning Orange: #FB8C00 (Warnings)
├─ Error Red: #E53935 (Errors)
└─ Neutral Gray: #6C757D (Secondary elements)

Background:
├─ Light: #F5F5F5 (Cards, panels)
├─ White: #FFFFFF (Main background)
└─ Dark (optional): #121212 (Dark mode)

Text:
├─ Primary: #212121 (Headlines)
├─ Secondary: #757575 (Body text)
└─ Disabled: #BDBDBD (Disabled elements)
```

### 6.2 Navigation Pattern

**Bottom Navigation (Crew):**
```
┌──────────────────────────────────────┐
│ Content Area                         │
├──────────────────────────────────────┤
│ [Home] [Kasir] [Galon] [Settings] [Profile]
  ▼
```

**Side Navigation (Manager - Tablet/Desktop view):**
```
┌──────────────┬───────────────────────┐
│ • Dashboard  │ Content Area          │
│ • Laporan    │                       │
│ • Validasi   │                       │
│ • Manajemen  │                       │
│ • Pengaturan │                       │
└──────────────┴───────────────────────┘
```

### 6.3 Responsive Design

```
Mobile (< 600px):
├─ Single column layout
├─ Full-width cards
├─ Bottom navigation
├─ Stacked forms
└─ Large touch targets (min 48dp)

Tablet (600px - 900px):
├─ Two column layout
├─ Side drawer navigation
├─ Optimized spacing
└─ Medium touch targets

Desktop (> 900px):
├─ Multi-column layout
├─ Permanent navigation
├─ Detailed views
└─ Normal touch targets
```

---

## KESIMPULAN

Dokumentasi fitur-fitur ini menjelaskan:

1. **Autentikasi** - Login, token management, session handling
2. **Transaksi** - Kasir screen, pembayaran QRIS, validasi
3. **Galon Tracking** - Status, mutasi, laporan
4. **Manajemen Data** - Produk, pelanggan, crew
5. **Laporan & Analytics** - Dashboard, metrics, export
6. **UX & Interface** - Design system, navigation, responsiveness

Setiap fitur dirancang dengan user-centric approach dan mempertimbangkan workflow operasional depot air minum modern.

---

**Dokumen Fitur & Implementasi**
*Version: 1.0*
*Last Updated: 2026-06-19*
