# 📋 ANALISIS DAN PERANCANGAN SISTEM
## Sistem Manajemen Depot Air Minum Berbasis Mobile Application

---

## 1. PENDAHULUAN

### 1.1 Latar Belakang

Industri depot air minum merupakan salah satu bisnis yang berkembang pesat di masyarakat modern. Setiap hari, depot air harus mengelola berbagai aspek operasional meliputi:

- **Manajemen Penjualan** - Mencatat setiap transaksi penjualan produk
- **Manajemen Galon** - Tracking galon yang dipinjam dan dikembalikan oleh pelanggan
- **Manajemen Pelanggan** - Data pelanggan tetap dan pelanggan baru
- **Manajemen Keuangan** - Pencatatan pemasukan dan pengeluaran
- **Manajemen Staff** - Data crew/staff dan monitoring performa mereka
- **Laporan dan Analytics** - Analisis data penjualan untuk pengambilan keputusan

Namun, pada umumnya depot air masih menggunakan sistem manual atau spreadsheet yang tidak terintegrasi, sehingga menyebabkan:

1. **Kesalahan Data** - Duplikasi dan inkonsistensi data
2. **Proses Lambat** - Pencatatan manual memakan waktu
3. **Validasi Sulit** - Sulit mengontrol transaksi yang dibuat crew
4. **Laporan Tidak Real-time** - Manager sulit membuat keputusan dengan cepat
5. **Tracking Galon Tidak Akurat** - Galon yang hilang atau rusak sulit diidentifikasi
6. **Tidak Ada Integrasi Pembayaran** - Belum support metode pembayaran digital

### 1.2 Tujuan Sistem

Sistem **"Depo Air Management System"** dikembangkan dengan tujuan:

1. **Meningkatkan Efisiensi Operasional** - Otomasi proses bisnis yang sebelumnya manual
2. **Meningkatkan Akurasi Data** - Mengurangi kesalahan melalui validasi terstruktur
3. **Real-time Monitoring** - Manager dapat melihat data penjualan secara real-time
4. **Meningkatkan Kontrol Transaksi** - Validasi transaksi sebelum finalisasi
5. **Tracking Galon Otomatis** - Sistem tracking mutasi galon yang akurat
6. **Integrasi Pembayaran** - Support pembayaran online via QRIS
7. **Laporan Komprehensif** - Laporan penjualan, keuangan, dan analytics
8. **Manajemen Multi-role** - Role-based access control untuk security

### 1.3 Ruang Lingkup Sistem

Sistem mencakup fitur-fitur untuk **dua role utama**:

#### **Role Crew (Staff/Kasir)**
- Login dan autentikasi
- Membuat transaksi penjualan
- Memilih metode pembayaran (Cash, QRIS, Transfer)
- Generate QR code untuk pembayaran
- Mencatat mutasi galon (pinjam/kembali)
- Melihat riwayat transaksi
- Manajemen data pelanggan (tambah, edit, cari)
- Pengaturan profil

#### **Role Manager**
- Dashboard dengan analytics & KPI
- Validasi transaksi yang dibuat crew
- Laporan penjualan komprehensif
- Analisis keuangan dan revenue
- Manajemen produk dan kategori
- Manajemen crew/staff
- Manajemen galon (asset tracking)
- Pengaturan sistem dan backup data

---

## 2. ANALISIS SISTEM

### 2.1 Stakeholder Sistem

| No | Stakeholder | Peran | Kebutuhan |
|-----|-----------|------|----------|
| 1 | Crew/Kasir | Operator Transaksi | Interface sederhana, quick checkout, print receipt |
| 2 | Manager | Administrator & Analyst | Dashboard, laporan, validasi transaksi |
| 3 | Owner/Pemilik | Decision Maker | Laporan keuangan, analytics, KPI |
| 4 | Pelanggan | End User | Transaksi cepat, kemudahan pembayaran |

### 2.2 Analisis Kebutuhan Fungsional (Functional Requirements)

#### **A. User Management**
- User dapat login sesuai role (Crew/Manager)
- Password dienkripsi dengan bcrypt
- Token JWT untuk session management
- Auto refresh token sebelum expire
- Logout dan clear session
- Profile management (view & update)

#### **B. Transaction Management**
- Crew membuat transaksi baru
- Pilih/tambah pelanggan dalam transaksi
- Tambah item produk ke transaksi
- Edit jumlah atau harga item
- Hapus item dari transaksi
- Generate nomor transaksi unik
- Pilih metode pembayaran (cash/QRIS/transfer)
- Simpan sebagai pending untuk validasi
- Manager validasi/approve/reject transaksi
- Finalisasi transaksi menjadi complete

#### **C. Payment Processing**
- Generate QR code QRIS untuk pembayaran
- Polling status pembayaran dari QRIS
- Webhook handler untuk notifikasi pembayaran
- Konfirmasi pembayaran otomatis
- Timeout handling untuk pembayaran expired
- Payment history tracking

#### **D. Bottle/Galon Management**
- Create galon dengan kode unik
- Track status galon (tersedia/dipinjam/rusak/hilang)
- Record galon dipinjam pelanggan
- Record galon dikembalikan
- Mutation history (audit trail)
- Update status galon (rusak/hilang)
- Query galon per pelanggan
- Query total stok galon per merek

#### **E. Customer Management**
- Add pelanggan baru
- Edit data pelanggan
- Delete pelanggan (soft delete)
- Search pelanggan
- View detail pelanggan
- View riwayat transaksi pelanggan
- View total galon yang dipinjam
- View total pembelian pelanggan

#### **F. Product Management**
- Add produk baru
- Edit produk (harga, stok, deskripsi)
- Delete produk (soft delete)
- Category management
- Filter produk per kategori
- Update stok produk
- Upload gambar produk

#### **G. Reporting & Analytics**
- Dashboard with KPI (today's sales, total customers, etc)
- Revenue chart (daily/monthly)
- Top products chart
- Top customers chart
- Payment method breakdown
- Sales trend chart
- Crew performance report
- Export report to file

#### **H. Settings & Configuration**
- Manage user accounts (crew)
- Manage categories
- Manage products
- Set pricing
- Manage expenses category
- Manage branches (multi-depot support)
- System settings
- Backup & restore data

### 2.3 Analisis Kebutuhan Non-Fungsional (Non-Functional Requirements)

| Kategori | Requirement |
|----------|-------------|
| **Performance** | Response time < 2 detik, handle 100+ concurrent users |
| **Scalability** | Support 1000+ transactions per hari, 10000+ customers |
| **Security** | Authentication JWT, password encryption, HTTPS |
| **Availability** | 99% uptime, 24/7 availability |
| **Usability** | Responsive design, works on Android 8.0+ |
| **Maintainability** | Well-documented code, structured architecture |
| **Reliability** | Data backup, error handling, recovery mechanism |
| **Compatibility** | Android & iOS support (Flutter) |

### 2.4 Analisis Data Flow

```
┌─────────────────────────────────────────────────────────────┐
│                     CLIENT (Flutter App)                      │
│  ┌──────────────────────────────────────────────────────┐   │
│  │ • Crew Screen       • Manager Dashboard              │   │
│  │ • Kasir Screen      • Laporan Screen                 │   │
│  │ • Transaksi Screen  • Pengaturan Screen              │   │
│  │ • Payment Screen    • Analytics Screen               │   │
│  └──────────────────────────────────────────────────────┘   │
│                           │                                   │
│                  ┌────────┴────────┐                          │
│                  │  API Interceptor│                          │
│                  │  + JWT Handler  │                          │
│                  └────────┬────────┘                          │
│                           │                                   │
│         ┌─────────────────┴─────────────────┐                │
│         │    Local Storage (Secure)         │                │
│         │  • Token & Refresh Token           │                │
│         │  • User Profile                    │                │
│         │  • Offline Cache                   │                │
│         └─────────────────┬─────────────────┘                │
└──────────────────────────┼────────────────────────────────────┘
                           │
                    [HTTPS REST API]
                           │
┌──────────────────────────┼────────────────────────────────────┐
│                     SERVER (Node.js)                           │
│  ┌──────────────────────────────────────────────────────┐    │
│  │ Express Server                                       │    │
│  │ • Route Handler (Auth, Transaction, etc)             │    │
│  │ • Middleware (JWT Validation, Error Handler)         │    │
│  │ • Business Logic Layer                               │    │
│  └──────────────────────────────────────────────────────┘    │
│                           │                                   │
│  ┌──────────────────────────────────────────────────────┐    │
│  │ Service Layer                                        │    │
│  │ • Auth Service      • Transaction Service            │    │
│  │ • User Service      • Payment Service (QRIS)         │    │
│  │ • Product Service   • Analytics Service              │    │
│  │ • Report Service    • Galon Service                   │    │
│  └──────────────────────────────────────────────────────┘    │
│                           │                                   │
│  ┌──────────────────────────────────────────────────────┐    │
│  │ Data Access Layer (MySQL)                            │    │
│  │ • Users, Produk, Pelanggan                            │    │
│  │ • Transaksi, TransaksiItems                           │    │
│  │ • Galon, Kategori, QRPayments                         │    │
│  └──────────────────────────────────────────────────────┘    │
└──────────────────────────────────────────────────────────────┘
```

---

## 3. PERANCANGAN SISTEM

### 3.1 Arsitektur Sistem

#### **3.1.1 Client-Server Architecture**

```
┌────────────────────────────────────────────────────────────┐
│                        PRESENTATION LAYER                   │
│          (Flutter UI Components - Cross Platform)           │
│  ┌─────────────────────────────────────────────────────┐  │
│  │ Views: Screens for Crew & Manager                  │  │
│  │ • CrewMainScreen    • ManagerDashboardScreen       │  │
│  │ • KasirScreen       • LaporanScreen                │  │
│  │ • TransaksiScreen   • AnalisisScreen               │  │
│  └─────────────────────────────────────────────────────┘  │
└────────────────────────────────────────────────────────────┘
                           │
┌────────────────────────────────────────────────────────────┐
│                    CONTROLLER LAYER (GetX)                  │
│         (State Management & Business Logic Controller)      │
│  ┌─────────────────────────────────────────────────────┐  │
│  │ AuthController          • ProdukController          │  │
│  │ TransaksiController     • PelangganController       │  │
│  │ CrewController          • KasirController           │  │
│  │ LaporanController       • GalonController           │  │
│  └─────────────────────────────────────────────────────┘  │
└────────────────────────────────────────────────────────────┘
                           │
┌────────────────────────────────────────────────────────────┐
│                    SERVICE LAYER (Dart)                     │
│      (Business Logic, API Calls, Data Handling)             │
│  ┌─────────────────────────────────────────────────────┐  │
│  │ AuthService         • TransaksiService              │  │
│  │ ApiService          • QRPaymentService              │  │
│  │ LocalStorage        • Interceptor (JWT Handler)     │  │
│  └─────────────────────────────────────────────────────┘  │
└────────────────────────────────────────────────────────────┘
                           │
┌────────────────────────────────────────────────────────────┐
│                       DATA LAYER (Local)                    │
│    (Local Database & Secure Storage for Offline Support)    │
│  ┌─────────────────────────────────────────────────────┐  │
│  │ SharedPreferences • SQLite • SecureStorage           │  │
│  │ • Cache Data      • Local DB  • Encrypted Token     │  │
│  └─────────────────────────────────────────────────────┘  │
└────────────────────────────────────────────────────────────┘
                   [HTTPS REST API Channel]
┌────────────────────────────────────────────────────────────┐
│                    SERVER SIDE (Node.js)                    │
│  ┌─────────────────────────────────────────────────────┐  │
│  │ API ROUTES & MIDDLEWARE (Express)                   │  │
│  │ • Authentication Routes  • Product Routes           │  │
│  │ • Transaction Routes     • Report Routes            │  │
│  │ • Payment Routes         • User Management Routes   │  │
│  └─────────────────────────────────────────────────────┘  │
│                           │                                │
│  ┌─────────────────────────────────────────────────────┐  │
│  │ SERVICE LAYER (Business Logic - Node.js)           │  │
│  │ • AuthService       • TransactionService            │  │
│  │ • UserService       • PaymentService (QRIS)         │  │
│  │ • ProductService    • ReportService                 │  │
│  │ • AnalyticsService  • GalonService                  │  │
│  └─────────────────────────────────────────────────────┘  │
│                           │                                │
│  ┌─────────────────────────────────────────────────────┐  │
│  │ DATABASE LAYER (MySQL)                              │  │
│  │ • users             • transaksi                      │  │
│  │ • produk            • transaksi_items                │  │
│  │ • pelanggan         • qr_payments                    │  │
│  │ • kategori          • galon & galon_mutasi           │  │
│  │ • refresh_tokens    • pengeluaran (optional)         │  │
│  └─────────────────────────────────────────────────────┘  │
└────────────────────────────────────────────────────────────┘
```

#### **3.1.2 Design Pattern Yang Digunakan**

1. **MVC Pattern** - Separation of concerns pada server side
2. **GetX State Management** - For reactive UI updates
3. **Dependency Injection** - Using GetX for DI container
4. **Repository Pattern** - Abstraction for data access
5. **Service Locator Pattern** - For service registration
6. **JWT Authentication** - Stateless authentication

### 3.2 Database Design (Entity Relationship Diagram)

#### **3.2.1 Database Schema Overview**

```
┌─────────────────────────────────────────────────────────────┐
│                                                               │
│  ┌──────────┐         ┌──────────┐       ┌──────────┐      │
│  │  USERS   │         │ KATEGORI │       │  PRODUK  │      │
│  ├──────────┤         ├──────────┤       ├──────────┤      │
│  │ id (PK)  │         │ id (PK)  │       │ id (PK)  │      │
│  │ username │◄────┬──►│ nama     │◄──┬──►│ nama     │      │
│  │ password │     │   │ tipe     │   │   │ kategori │      │
│  │ role     │     │   │ is_aktif │   │   │ harga    │      │
│  │ nama     │     │   └──────────┘   │   │ stok     │      │
│  │ is_aktif │     │                  │   │ is_aktif │      │
│  └──────────┘     │                  │   └──────────┘      │
│        ▲          │                  │                       │
│        │1         │1                 │1                      │
│        └──────────┴──────────────────┴──────────────────────┘
│                   │
│                   │N
│          ┌────────┴────────┐
│          │ TRANSAKSI       │
│          ├─────────────────┤         ┌──────────────┐
│          │ id (PK)         │        │ TRANSAKSI_   │
│          │ nomor_transaksi │◄──N───►│ ITEMS        │
│          │ pelanggan_id(FK)│        │              │
│          │ crew_id (FK)    │        └──────────────┘
│          │ total_harga     │
│          │ metode_pembayaran
│          │ status          │        ┌──────────────┐
│          │ status_validasi │◄────N─►│ QR_PAYMENTS  │
│          │ validated_by    │        │              │
│          └─────────────────┘        └──────────────┘
│                   │
│                   │FK
│          ┌────────┴────────┐
│        1 │                 │ N
│   ┌──────────────┐  ┌─────────────────┐
│   │  PELANGGAN   │  │  GALON          │
│   ├──────────────┤  ├─────────────────┤
│   │ id (PK)      │  │ id (PK)         │
│   │ nama         │  │ kode_galon      │
│   │ no_hp        │  │ merek           │
│   │ alamat       │  │ jenis           │
│   │ total_piutang│  │ status          │
│   │ is_aktif     │  │ pelanggan_id(FK)│
│   └──────────────┘  │ created_at      │
│        ▲            └─────────────────┘
│        │                   ▲
│        └───────────────────┘
│
│       ┌──────────────────────┐
│       │ GALON_MUTASI         │
│       ├──────────────────────┤
│       │ id (PK)              │
│       │ aksi                 │
│       │ jumlah               │
│       │ pelanggan_id         │
│       │ crew_id              │
│       │ status_dari/ke       │
│       │ created_at           │
│       └──────────────────────┘
│
│   ┌──────────────────────────┐
│   │ REFRESH_TOKENS           │
│   ├──────────────────────────┤
│   │ token (PK)               │
│   │ user_id (FK)             │
│   │ created_at               │
│   └──────────────────────────┘
│
└─────────────────────────────────────────────────────────────┘
```

#### **3.2.2 Key Tables Description**

| Table | Purpose | Key Fields |
|-------|---------|-----------|
| **users** | Manage login & user data | id, username, password_hash, role, is_aktif |
| **kategori** | Product categories | id, nama, tipe (pemasukan/pengeluaran), ikon |
| **produk** | Product inventory | id, nama, kategori_id, harga, stok |
| **pelanggan** | Customer data | id, nama, no_hp, total_galon_pinjam, total_transaksi |
| **transaksi** | Transaction records | id, nomor_transaksi, pelanggan_id, total_harga, status |
| **transaksi_items** | Transaction details | id, transaksi_id, produk_id, jumlah, harga_satuan |
| **galon** | Bottle tracking | id, kode_galon, status, pelanggan_id, jenis |
| **galon_mutasi** | Bottle mutation audit | id, aksi, jumlah, crew_id, status_dari/ke |
| **qr_payments** | QRIS payment records | payment_id, transaksi_id, status, qr_content |
| **refresh_tokens** | JWT token storage | token, user_id |

### 3.3 API Endpoint Design

#### **3.3.1 Authentication Endpoints**

```
POST /api/auth/login
  Body: { username, password }
  Response: { token, refreshToken, user }

POST /api/auth/refresh
  Body: { refreshToken }
  Response: { token, refreshToken }

POST /api/auth/logout
  Headers: Authorization: Bearer {token}
  Response: { success }

GET /api/auth/profile
  Headers: Authorization: Bearer {token}
  Response: { user }
```

#### **3.3.2 Transaction Endpoints**

```
POST /api/transaksi
  Body: { pelanggan_id, items: [{produk_id, jumlah, harga_satuan}], metode_pembayaran }
  Response: { transaksi }

GET /api/transaksi
  Query: { status, crew_id, tanggal_dari, tanggal_sampai, limit, offset }
  Response: { data: [transaksi], total }

GET /api/transaksi/:id
  Response: { transaksi dengan items }

PUT /api/transaksi/:id/validasi
  Body: { status_validasi: 'approved'|'rejected' }
  Response: { transaksi }

PUT /api/transaksi/:id/finalisasi
  Response: { transaksi }

DELETE /api/transaksi/:id
  Response: { success }
```

#### **3.3.3 Product Endpoints**

```
GET /api/produk
  Query: { kategori_id, search, limit, offset }
  Response: { data: [produk], total }

POST /api/produk
  Body: { nama, kategori_id, harga, stok, deskripsi }
  Response: { produk }

PUT /api/produk/:id
  Body: { nama, harga, stok, deskripsi }
  Response: { produk }

DELETE /api/produk/:id
  Response: { success }

GET /api/kategori
  Response: { data: [kategori] }
```

#### **3.3.4 Customer Endpoints**

```
GET /api/pelanggan
  Query: { search, is_aktif, limit, offset }
  Response: { data: [pelanggan], total }

POST /api/pelanggan
  Body: { nama, no_hp, alamat, catatan }
  Response: { pelanggan }

PUT /api/pelanggan/:id
  Body: { nama, no_hp, alamat, catatan, is_aktif }
  Response: { pelanggan }

DELETE /api/pelanggan/:id
  Response: { success }

GET /api/pelanggan/:id/transaksi
  Response: { data: [transaksi] }

GET /api/pelanggan/:id/galon
  Response: { data: [galon] }
```

#### **3.3.5 Payment Endpoints**

```
POST /api/qr-payment
  Body: { transaksi_id, jumlah }
  Response: { payment_id, qr_content, expires_at }

GET /api/qr-payment/:payment_id/status
  Response: { status, paid_at }

PUT /api/qr-payment/:payment_id/webhook
  Body: { status, paid_at }
  Response: { success }
```

#### **3.3.6 Galon Endpoints**

```
GET /api/galon
  Query: { status, pelanggan_id, limit, offset }
  Response: { data: [galon], total }

POST /api/galon
  Body: { kode_galon, merek, jenis, status }
  Response: { galon }

PUT /api/galon/:id
  Body: { status, pelanggan_id, catatan }
  Response: { galon }

GET /api/galon/mutasi
  Query: { tanggal_dari, tanggal_sampai, limit, offset }
  Response: { data: [galon_mutasi], total }
```

#### **3.3.7 Report Endpoints**

```
GET /api/laporan/penjualan
  Query: { tanggal_dari, tanggal_sampai, crew_id }
  Response: { data: [transaksi] }

GET /api/laporan/keuangan
  Query: { bulan, tahun }
  Response: { total_revenue, total_expense, net_profit }

GET /api/analisis/top-produk
  Query: { limit }
  Response: { data: [{ produk, total_terjual }] }

GET /api/analisis/top-pelanggan
  Query: { limit }
  Response: { data: [{ pelanggan, total_pembelian }] }

GET /api/dashboard/summary
  Response: { today_sales, total_customers, total_transaction, total_revenue }
```

### 3.4 User Interface (UI/UX) Design

#### **3.4.1 Crew App Screens**

```
┌─────────────────────────────────────────────────────────┐
│                 CREW APPLICATION FLOW                   │
│                                                         │
│  Login Screen → Dashboard → [Choose Action]             │
│        ↓                                                │
│  ┌──────────────┬──────────────┬──────────────┐        │
│  │    Kasir     │  Data        │   Riwayat    │        │
│  │ (Transaksi)  │  Pelanggan   │  Transaksi   │        │
│  └──────┬───────┴──────┬───────┴──────┬───────┘        │
│         │              │              │                 │
│         ↓              ↓              ↓                 │
│  ┌──────────────┐  ┌────────┐  ┌──────────────┐        │
│  │ Create Trans.│  │Add/Edit│  │View History  │        │
│  │+ Select Cust.│  │Cust.   │  │Filter Dates  │        │
│  │+ Add Items   │  │Search  │  │Export        │        │
│  │+ Pilih Metode│  │        │  │              │        │
│  │+ QR Payment  │  │        │  │              │        │
│  │+ Print       │  │        │  │              │        │
│  └──────────────┘  └────────┘  └──────────────┘        │
│                                                         │
│  ┌──────────────┬──────────────┬──────────────┐        │
│  │  Galon       │  Pengaturan  │  Logout      │        │
│  │  Tracking    │              │              │        │
│  └──────┬───────┴──────┬───────┴──────┬───────┘        │
│         │              │              │                 │
│         ↓              ↓              ↓                 │
│  ┌──────────────┐  ┌────────┐  ┌──────────────┐        │
│  │Pinjam/Kembali│  │Edit    │  │Konfirmasi    │        │
│  │Mutasi List   │  │Profile │  │Logout        │        │
│  │Filter Status │  │Settings│  │              │        │
│  │              │  │        │  │              │        │
│  └──────────────┘  └────────┘  └──────────────┘        │
│                                                         │
└─────────────────────────────────────────────────────────┘
```

#### **3.4.2 Manager App Screens**

```
┌─────────────────────────────────────────────────────────┐
│               MANAGER APPLICATION FLOW                  │
│                                                         │
│  Login Screen → Dashboard (KPI) → [Choose Action]       │
│        ↓                                                │
│  ┌──────────────┬──────────────┬──────────────┐        │
│  │  Laporan &   │  Validasi    │  Manajemen   │        │
│  │  Analytics   │  Transaksi   │  Data        │        │
│  └──────┬───────┴──────┬───────┴──────┬───────┘        │
│         │              │              │                 │
│         ↓              ↓              ↓                 │
│  ┌──────────────┐  ┌────────┐  ┌──────────────┐        │
│  │Revenue Chart │  │Pending │  │Products      │        │
│  │Sales Report  │  │Trans   │  │Categories    │        │
│  │Pelanggan List│  │Approve │  │Crew          │        │
│  │Top Products  │  │Reject  │  │Customers     │        │
│  │Export        │  │        │  │Edit/Delete   │        │
│  │              │  │        │  │              │        │
│  └──────────────┘  └────────┘  └──────────────┘        │
│                                                         │
│  ┌──────────────┬──────────────┬──────────────┐        │
│  │  Galon Asset │  Setting     │  Logout      │        │
│  │  Tracking    │              │              │        │
│  └──────┬───────┴──────┬───────┴──────┬───────┘        │
│         │              │              │                 │
│         ↓              ↓              ↓                 │
│  ┌──────────────┐  ┌────────┐  ┌──────────────┐        │
│  │Galon List    │  │Backup  │  │Konfirmasi    │        │
│  │By Status     │  │Data    │  │Logout        │        │
│  │Mutasi History│  │Clear   │  │              │        │
│  │Lost/Damage   │  │Cache   │  │              │        │
│  │              │  │Reset   │  │              │        │
│  └──────────────┘  └────────┘  └──────────────┘        │
│                                                         │
└─────────────────────────────────────────────────────────┘
```

### 3.5 Security Design

#### **3.5.1 Authentication & Authorization**

```
Login Process:
  1. User input username & password
  2. Client send ke server via HTTPS
  3. Server validate di database
  4. Generate JWT token (8 jam) + Refresh token
  5. Server return token ke client
  6. Client menyimpan token di SecureStorage
  
Setiap API Request:
  1. Client include token di Authorization header
  2. Server validate JWT signature & expiry
  3. Jika valid → process request
  4. Jika expired → use refresh token untuk get token baru
  5. Jika invalid → return 401 Unauthorized
```

#### **3.5.2 Data Security**

```
Client Side:
  • Password tidak pernah disimpan di local
  • Token disimpan di FlutterSecureStorage (encrypted)
  • Sensitive data (transaksi) disimpan di SQLite with encryption

Server Side:
  • Password di-hash dengan bcrypt (salt: 10 rounds)
  • JWT_SECRET di environment variable
  • HTTPS only (mandatory)
  • Input validation & SQL injection prevention
  • Rate limiting untuk login attempt
```

#### **3.5.3 Role-Based Access Control (RBAC)**

```
┌────────────────────────────────────────────────────┐
│ Access Control Matrix                              │
├────────────────────────────────────────────────────┤
│ Feature              │ Crew │ Manager │ Admin      │
├──────────────────────┼──────┼─────────┼────────────┤
│ Create Transaksi     │  ✓   │   ✓     │    ✓       │
│ View Own Transaksi   │  ✓   │   -     │    ✓       │
│ Validasi Transaksi   │  -   │   ✓     │    ✓       │
│ View All Transaksi   │  -   │   ✓     │    ✓       │
│ Manage Products      │  -   │   ✓     │    ✓       │
│ View Dashboard       │  ✓   │   ✓     │    ✓       │
│ View Report          │  -   │   ✓     │    ✓       │
│ Manage Users         │  -   │   ✓     │    ✓       │
│ System Settings      │  -   │   ✓     │    ✓       │
└────────────────────────────────────────────────────┘
```

### 3.6 Error Handling & Validation

#### **3.6.1 Input Validation**

```
Frontend (Flutter):
  • Required field validation
  • Format validation (email, phone, number)
  • Length validation (min/max)
  • Custom validation rules
  • Real-time validation feedback

Backend (Node.js):
  • Schema validation (input body)
  • Type checking
  • Business rule validation
  • Database constraint validation
```

#### **3.6.2 Error Response**

```
Standardized Error Response:
{
  "success": false,
  "status": 400|401|403|404|500,
  "message": "Error message in Indonesian",
  "error": {
    "code": "ERROR_CODE",
    "details": "Additional details if needed"
  }
}

HTTP Status Codes:
  • 200 OK - Successful request
  • 201 Created - Resource created
  • 400 Bad Request - Invalid input
  • 401 Unauthorized - Not authenticated
  • 403 Forbidden - No permission
  • 404 Not Found - Resource not found
  • 500 Internal Server Error - Server error
```

---

## 4. TEKNOLOGI & STACK YANG DIGUNAKAN

### 4.1 Frontend Technology Stack

| Component | Technology | Version | Purpose |
|-----------|-----------|---------|---------|
| **Framework** | Flutter | 3.6.2+ | Cross-platform mobile development |
| **Language** | Dart | 3.6.2+ | Programming language for Flutter |
| **State Management** | GetX | 4.6.6 | State management & navigation |
| **HTTP Client** | Dio | 5.4.0 | REST API communication |
| **Local Storage** | SharedPreferences | 2.2.2 | Key-value storage |
| **Secure Storage** | FlutterSecureStorage | 9.0.0 | Encrypted data storage |
| **Local Database** | SQLite | 2.3.2 | Local database for offline |
| **QR Code** | qr_flutter | 4.1.0 | QR code generation |
| **QR Scanner** | mobile_scanner | 4.0.0 | QR code scanning |
| **UI Components** | flutter_svg | 2.0.9 | SVG rendering |
| **Image Caching** | cached_network_image | 3.3.1 | Image caching & loading |
| **Loading Animation** | shimmer | 3.0.0 | Skeleton loading |
| **Internationalization** | intl | 0.19.0 | Date/time formatting |
| **Charts** | fl_chart | 0.68.0 | Charts & graphs |
| **Logger** | logger | 2.2.0 | Debug logging |

### 4.2 Backend Technology Stack

| Component | Technology | Version | Purpose |
|-----------|-----------|---------|---------|
| **Framework** | Express.js | 4.21.2 | Web framework for Node.js |
| **Runtime** | Node.js | 18.0+ | JavaScript runtime |
| **Language** | JavaScript | ES6+ | Backend programming language |
| **Database** | MySQL | 8.0+ | Relational database |
| **DB Driver** | mysql2 | 3.22.4 | MySQL connection pool |
| **Authentication** | JWT | 9.0.2 | Token-based authentication |
| **Password Encryption** | bcryptjs | 2.4.3 | Password hashing |
| **CORS** | cors | 2.8.5 | Cross-origin resource sharing |
| **Environment** | dotenv | 17.4.2 | Environment variable management |
| **UUID** | uuid | 11.0.5 | Unique identifier generation |

### 4.3 Database

- **MySQL 8.0+** - Relational database management system
- **Charset**: utf8mb4_unicode_ci (support emoji & special characters)
- **Engine**: InnoDB (transaction support)

### 4.4 Development & Deployment

| Tool | Purpose |
|------|---------|
| **VS Code** | Code editor |
| **Git/GitHub** | Version control |
| **Postman/Thunder** | API testing |
| **Android Studio** | Android emulator |
| **Xcode** | iOS development |
| **Docker** (optional) | Containerization |
| **PM2** (optional) | Node.js process manager |
| **Nginx** (optional) | Reverse proxy |

---

## 5. FITUR-FITUR UTAMA SISTEM

### 5.1 Fitur Authentication & User Management

**Alur Login Crew:**
```
1. User buka aplikasi
2. Pilih "Login Sebagai Crew"
3. Input username & password
4. Validasi ke server
5. Jika valid → simpan token di secure storage
6. Redirect ke Crew Dashboard
7. Token otomatis refresh sebelum expire (8 jam)
```

**Alur Login Manager:**
```
Sama seperti crew, hanya role yang berbeda
```

**Token Management:**
- Access Token: Valid 8 jam
- Refresh Token: Valid 30 hari
- Auto-refresh ketika access token expired

### 5.2 Fitur Transaksi Penjualan

**Alur Create Transaksi:**
```
1. Crew buka Kasir Screen
2. Pilih/tambah pelanggan
3. Add produk ke keranjang
4. Edit jumlah jika perlu
5. Hitung total & pilih metode pembayaran
6. Jika QRIS → generate QR code
7. Jika cash/transfer → input nominal bayar
8. Submit transaksi (status: pending)
9. Tunggu manager validasi
```

**Status Transaksi:**
```
pending → validated_approved → completed
             ↓
         rejected
```

**Validasi Status:**
- pending: Menunggu manager approval
- approved: Manager setuju
- rejected: Manager tolak
- completed: Transaksi selesai

### 5.3 Fitur Pembayaran QRIS

**Alur QRIS Payment:**
```
1. User memilih metode QRIS
2. System generate QR code + payment ID
3. QR ditampilkan ke customer untuk scan
4. System polling status pembayaran
5. Saat pembayaran berhasil → auto update status
6. Transaksi auto-finalized
7. Receipt dicetak/dikirim
```

**Payment Status:**
- pending: Menunggu pembayaran
- paid: Pembayaran berhasil
- expired: QR code expired
- cancelled: Pembayaran dibatalkan

### 5.4 Fitur Galon Management

**Tracking Galon:**
```
1. Setiap galon memiliki kode unik (barcode)
2. Galon dapat dipinjam pelanggan saat transaksi
3. Galon dapat dikembalikan kemudian
4. Status galon: tersedia/dipinjam/rusak/hilang
5. Sistem track semua mutasi galon
6. Manager dapat lihat laporan galon hilang
```

**Jenis Galon:**
- Isi: Galon berisi air
- Kosong: Galon untuk diisi

**Mutasi Galon:**
- Pinjam: Pelanggan pinjam galon
- Kembali: Pelanggan kembalikan galon
- Rusak: Update status rusak
- Hilang: Update status hilang

### 5.5 Fitur Laporan & Analytics

**Dashboard Crew:**
- Total transaksi hari ini
- Total revenue hari ini
- Pending transaksi (waiting approval)
- Recent transactions list

**Dashboard Manager:**
- KPI cards (today's sales, total customers, etc)
- Revenue chart (daily/monthly)
- Sales by payment method
- Top products
- Top customers
- Trend chart
- Crew performance

**Laporan Manager:**
- Laporan penjualan (filter tanggal/crew)
- Laporan keuangan (revenue, expense, profit)
- Laporan galon (lost/damaged)
- Laporan pelanggan
- Export ke file

### 5.6 Fitur Manajemen Data

**Data Produk:**
- Tambah/edit/delete produk
- Set harga & stok
- Upload gambar produk
- Filter per kategori
- Category management

**Data Pelanggan:**
- Tambah/edit/delete pelanggan
- View riwayat transaksi pelanggan
- View total galon dipinjam
- View total pembelian

**Data Crew:**
- Tambah/edit/delete crew
- View performa crew
- View riwayat transaksi crew
- Suspend/aktivasi crew

**Data Kategori:**
- Manage produk categories
- Manage expense categories
- Manage income categories

---

## 6. USE CASE DIAGRAM

### 6.1 Use Case: Crew (Operator/Kasir)

```
                    ┌─────────────────────┐
                    │   Sistem Depo Air   │
                    └─────────────────────┘
                              △
                              │
                    ┌─────────┴─────────┐
                    │                   │
              ┌─────▼────┐      ┌──────▼──────┐
              │   Crew   │      │   Manager   │
              └─────┬────┘      └──────┬──────┘
                    │                  │
          ┌─────────┼─────────┐        │
          │         │         │        │
    ┌─────▼──┐ ┌───▼──┐ ┌───▼──┐     │
    │ Login  │ │Create│ │ View │     │
    │Aplikasi│ │Trans │ │Data  │     │
    └────────┘ └──────┘ └──────┘     │
                │                     │
        ┌───────┴────────┐            │
        │                │            │
    ┌──▼───┐    ┌───────▼──┐        │
    │Choose│    │ Generate │        │
    │Cust  │    │ QR Code  │        │
    └──────┘    └──────────┘        │
                                     │
                ┌────────────────────┤
                │                    │
            ┌──▼───────┐      ┌─────▼──────┐
            │ Manage   │      │ Track Galon│
            │Pelanggan │      │(Pinjam/Kbl)│
            └──────────┘      └────────────┘

              ┌─────────────────────┐
              │   Manager Only      │
              └─────────────────────┘
                      │
      ┌───────────────┼───────────────┐
      │               │               │
  ┌───▼──┐    ┌──────▼─────┐  ┌──────▼────┐
  │Validasi   │View Report │  │Manage Data│
  │Transaksi  │& Analytics │  │(Prod/User)│
  └────────┘    └────────────┘  └───────────┘
```

### 6.2 Activity Diagram: Transaksi Penjualan

```
                   ┌─────────────────┐
                   │ Start Transaction│
                   └────────┬─────────┘
                            │
                   ┌────────▼────────┐
                   │ Select/Add Cust │
                   └────────┬────────┘
                            │
                   ┌────────▼───────┐
                   │ Add Item to Cart│
                   └────────┬───────┘
                            │
                   ┌────────▼────────────┐
         Yes ──┐  │ Add More Item?      │
             │  └───────┬────────┬──────┘
             │          │        No
             └──────────┘        │
                                 │
                        ┌────────▼──────┐
                        │Pilih Metode   │
                        │Pembayaran     │
                        └────┬───┬──┬──┘
                             │   │  │
           ┌─────────────────┘   │  └──────────────────┐
           │                     │                     │
       ┌───▼────┐        ┌───────▼────┐        ┌──────▼──┐
       │ Cash   │        │    QRIS    │        │Transfer │
       └───┬────┘        └───┬────────┘        └──────┬──┘
           │                 │                        │
           │         ┌───────▼──────┐                │
           │         │ Generate QR  │                │
           │         └───┬──────────┘                │
           │             │                          │
           │         ┌───▼───────────┐              │
           │         │Wait Pembayaran│              │
           │         └───┬──────────┬┘              │
           │             │          No              │
           │         Yes │          │               │
           │             │     ┌────▼─┐            │
           │             │     │Timeout│            │
           │             │     └───────┘            │
           │             │                          │
           └──────┬───────┴──────────────┬──────────┘
                  │                      │
           ┌──────▼──────────────────────▼──────┐
           │   Submit Transaction (Pending)    │
           └──────┬──────────────────────┬──────┘
                  │                      │
                  │         ┌────────────┘
                  │         │
                  ▼         ▼
            ┌─────────────────────┐
            │ Wait Manager Validasi│
            └─────┬───────┬───────┘
                  │       │
              ┌───▼┐     ┌▼───┐
              │Appr│     │Rejct
              └───┬┘     └┬───┘
                  │       │
                  │   ┌───▼────┐
                  │   │ Notify │
                  │   │Crew    │
                  │   └────────┘
                  │
           ┌──────▼──────┐
           │Finalized Txn│
           └──────┬──────┘
                  │
           ┌──────▼──────┐
           │ End        │
           └─────────────┘
```

---

## 7. DEPLOYMENT & SYSTEM REQUIREMENTS

### 7.1 Client Requirements

**Minimum Requirements:**
- Android 8.0+ atau iOS 12.0+
- RAM: 2 GB
- Storage: 100 MB
- Internet connection (required)

**Recommended:**
- Android 10.0+ atau iOS 14.0+
- RAM: 4 GB+
- Storage: 200 MB+
- 4G/5G connection

### 7.2 Server Requirements

**Minimum:**
- CPU: 2 cores
- RAM: 4 GB
- Storage: 50 GB
- OS: Ubuntu 20.04 LTS / Windows Server 2019

**Recommended:**
- CPU: 4 cores+
- RAM: 8 GB+
- Storage: 100 GB+ (SSD)
- OS: Ubuntu 22.04 LTS
- SSL Certificate (HTTPS)

### 7.3 Database Requirements

- MySQL 8.0+
- InnoDB engine
- utf8mb4 charset
- Backup: Daily at 00:00 UTC
- Recovery: Within 24 hours

### 7.4 Deployment Architecture

```
┌────────────────────────────────────────────────────────────┐
│                    CLIENT DEVICES                           │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐        │
│  │  Crew Crew  │  │  Crew No. 2 │  │  Manager    │        │
│  │  Phone 1    │  │  Phone      │  │  Tablet     │        │
│  └─────────────┘  └─────────────┘  └─────────────┘        │
└────────────────────────────────────────────────────────────┘
                   [HTTPS / INTERNET]
                           │
┌────────────────────────────────────────────────────────────┐
│              REVERSE PROXY (Nginx/Apache)                   │
│  • SSL Termination                                          │
│  • Load Balancing                                           │
│  • Request Caching                                          │
└──────────────────────┬─────────────────────────────────────┘
                       │
        ┌──────────────┼──────────────┐
        │              │              │
┌───────▼──────┐ ┌──────▼──────┐ ┌───▼────────┐
│  App Node 1  │ │  App Node 2 │ │ App Node 3 │
│  (Express)   │ │  (Express)  │ │ (Express)  │
└───────┬──────┘ └──────┬──────┘ └───┬────────┘
        │               │            │
        │    ┌──────────┼────────────┘
        │    │          │
        └────┼──────────┘
             │
        ┌────▼──────────────┐
        │  MySQL Database   │
        │  (Primary-Replica)│
        │  • Master DB      │
        │  • Replica DB 1   │
        │  • Replica DB 2   │
        └───────────────────┘
```

---

## 8. TIMELINE & DEVELOPMENT PHASES

### Phase 1: Planning & Requirements (Week 1-2)
- Requirements gathering
- System design
- Database design
- API specification

### Phase 2: Backend Development (Week 3-5)
- Setup Node.js environment
- Implement authentication
- Implement transaction module
- Implement payment module
- API testing

### Phase 3: Frontend Development (Week 6-8)
- Setup Flutter environment
- Implement authentication UI
- Implement crew dashboard
- Implement manager dashboard
- Local storage & caching

### Phase 4: Integration Testing (Week 9)
- API integration testing
- End-to-end testing
- Performance testing
- Security testing

### Phase 5: Deployment (Week 10)
- Prepare production environment
- Deploy backend to server
- Deploy mobile app (Play Store/App Store)
- Monitoring & maintenance

---

## 9. KESIMPULAN

Sistem **"Depo Air Management System"** dirancang dengan arsitektur yang scalable, secure, dan user-friendly. Sistem ini menggunakan teknologi modern seperti Flutter untuk frontend, Node.js untuk backend, dan MySQL untuk database.

Dengan fitur-fitur yang komprehensif, sistem ini mampu mengatasi tantangan operasional depot air minum modern termasuk:
- Efisiensi operasional
- Akurasi data
- Real-time monitoring
- Validasi transaksi terpusat
- Tracking galon otomatis
- Integrasi pembayaran digital
- Laporan & analytics

Sistem ini diharapkan dapat meningkatkan produktivitas depot air minum dan memberikan informasi real-time untuk pengambilan keputusan yang lebih baik.

---

## REFERENSI

1. Flutter Documentation - https://flutter.dev
2. Express.js Documentation - https://expressjs.com
3. MySQL Documentation - https://dev.mysql.com
4. JWT Authentication - https://jwt.io
5. REST API Best Practices - https://restfulapi.net
6. SOLID Principles - https://en.wikipedia.org/wiki/SOLID

---

**Dokumen ini dibuat sebagai bagian dari Skripsi Pengembangan Sistem Manajemen Depot Air Minum**

*Last Updated: 2026-06-19*
*Version: 1.0*
