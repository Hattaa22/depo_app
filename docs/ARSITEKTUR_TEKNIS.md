# 🏗️ ARSITEKTUR TEKNIS & KOMPONEN SISTEM
## Depo Air Management System - Technical Architecture

---

## 1. ARSITEKTUR SISTEM SECARA KESELURUHAN

### 1.1 High-Level Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                       PRESENTATION LAYER                         │
│                    (Flutter Mobile Application)                  │
│                                                                   │
│  ┌────────────────┐     ┌────────────────┐                      │
│  │  CREW UI       │     │  MANAGER UI    │                      │
│  │  Components    │     │  Components    │                      │
│  └────────┬───────┘     └────────┬───────┘                      │
│           │                      │                               │
└───────────┼──────────────────────┼───────────────────────────────┘
            │                      │
            │   ┌──────────────────┘
            │   │
            │   │  GetX State Management
            │   │  (Controllers & Bindings)
            │   │
┌───────────┼───┴──────────────────────────────────────────────────┐
│           ▼                                                       │
│  ┌────────────────────────────────────────────────────────────┐ │
│  │              BUSINESS LOGIC LAYER                          │ │
│  │                                                            │ │
│  │  AuthController    TransaksiController   ProdukController│ │
│  │  CrewController    LaporanController     PelangganControl│ │
│  │  GalonController   KasirController       CabangController│ │
│  │  PengeluaranControl AnalisisController                    │ │
│  └──────────────────────┬─────────────────────────────────┬──┘ │
│                         │                                 │    │
│  ┌──────────────────────┴──────────────────┬──────────────┴───┐ │
│  │         SERVICE LAYER (Business Logic)   │                 │ │
│  │                                          │                 │ │
│  │  AuthService          TransaksiService   │ APIInterceptor  │ │
│  │  LocalStorage         QRPaymentService   │ (JWT Handler)   │ │
│  │  APIService           ReportService      │                 │ │
│  └──────────────────────┬─────────────────────────────────┬──┘ │
│                         │                                 │    │
│         ┌───────────────┴────────────────────┬────────────┘    │
│         │                                    │                 │
│  ┌──────▼───────────────────────────────────▼─────────────┐   │
│  │    LOCAL DATA LAYER                                    │   │
│  │                                                        │   │
│  │  SharedPreferences    SQLite (Cache)                  │   │
│  │  FlutterSecureStorage (Encrypted Token)               │   │
│  │  File System (Temp Downloads)                         │   │
│  └──────┬─────────────────────────────────────────────────┘   │
│         │                                                      │
└─────────┼──────────────────────────────────────────────────────┘
          │
    [HTTPS REST API]
          │
          │ Request/Response in JSON
          │
          ▼
┌─────────────────────────────────────────────────────────────────┐
│                     SERVER LAYER (Laravel)                      │
│                                                                   │
│  ┌─────────────────────────────────────────────────────────┐   │
│  │  Laravel HTTP Kernel and API Routes                                │   │
│  │  - Routes (Auth, Transaction, Product, etc)            │   │
│  │  - Middleware (Logger, Error Handler, Rate Limit)      │   │
│  │  - JWT Verification Middleware                         │   │
│  └──────────────────────┬─────────────────────────────────┘   │
│                         │                                      │
│  ┌──────────────────────┴────────────────────────────────┐    │
│  │      SERVICE LAYER (Business Logic - Laravel)        │    │
│  │                                                       │    │
│  │  AuthService         TransactionService              │    │
│  │  UserService         PaymentService (QRIS)           │    │
│  │  ProductService      ReportService                   │    │
│  │  CustomerService     GalonService                    │    │
│  │  AnalyticsService    ValidationService               │    │
│  └──────────────┬────────────────────────┬──────────────┘    │
│                 │                        │                    │
│  ┌──────────────┴────────────────────────┴──────────────┐    │
│  │        DATA ACCESS LAYER (MySQL Queries)            │    │
│  │                                                       │    │
│  │  Query Builder / Raw SQL Execution                  │    │
│  │  Connection Pooling (mysql2/promise)                │    │
│  │  Error Handling & Logging                           │    │
│  └──────────────┬────────────────────────┬──────────────┘    │
│                 │                        │                    │
└─────────────────┼────────────────────────┼────────────────────┘
                  │                        │
            [MySQL Protocol]               │
                  │                        │
                  ▼                        ▼
        ┌──────────────────────────────────────┐
        │         MySQL Database               │
        │                                      │
        │  Primary Server (Master)             │
        │  ├─ users                            │
        │  ├─ produk                           │
        │  ├─ pelanggan                        │
        │  ├─ transaksi                        │
        │  ├─ transaksi_items                  │
        │  ├─ galon & galon_mutasi             │
        │  ├─ qr_payments                      │
        │  ├─ kategori                         │
        │  ├─ refresh_tokens                   │
        │  └─ pengeluaran (optional)           │
        │                                      │
        │  Replica Server (for Read)           │
        │  Backup Server                       │
        └──────────────────────────────────────┘
```

### 1.2 Component Interaction Diagram

```
USER
 │
 ▼
┌─────────────────────────┐
│  Flutter UI (View)      │
│  • Screens              │
│  • Widgets              │
│  • Forms                │
└────────┬────────────────┘
         │
         ▼ Input Event
┌─────────────────────────┐
│  GetX Controller        │
│  • State Management     │
│  • Event Handling       │
│  • Business Logic       │
└────────┬────────────────┘
         │
         ▼ Method Call
┌─────────────────────────┐
│  Service Layer          │
│  • APIService           │
│  • LocalStorageService  │
│  • QRPaymentService     │
└────────┬────────────────┘
         │
         ├──────┬─────────────┐
         │      │             │
         ▼      ▼             ▼
    ┌────┐ ┌──────┐     ┌──────────┐
    │API │ │Local │     │Validation│
    │Call│ │Data  │     │Logic     │
    └────┘ └──────┘     └──────────┘
         │
         │ JSON Over HTTPS
         │
         ▼
    ┌──────────────────────┐
    │ Laravel Router       │
    │ API Controller        │
    └──────┬───────────────┘
           │
           ▼
    ┌──────────────────────┐
    │ Server Service       │
    │ Business Logic       │
    └──────┬───────────────┘
           │
           ▼
    ┌──────────────────────┐
    │ Data Access Layer    │
    │ Database Query       │
    └──────┬───────────────┘
           │
           ▼ SQL
    ┌──────────────────────┐
    │ MySQL Database       │
    └──────────────────────┘
```

---

## 2. KOMPONEN FRONTEND (Flutter)

### 2.1 Struktur Directory

```
lib/
├── main.dart                          # Entry point
├── config/
│   ├── api_config.dart               # API configuration
│   ├── app_theme.dart                # Theme colors & styles
│   ├── constants.dart                # App constants
│   └── routes.dart                   # Navigation routes
├── models/                            # Data models
│   ├── cabang.dart
│   ├── crew.dart
│   ├── galon.dart
│   ├── manager.dart
│   ├── pelanggan.dart
│   ├── pengeluaran.dart
│   ├── produk.dart
│   └── transaksi.dart
├── services/                          # Business logic
│   ├── api_interceptor.dart          # JWT handling
│   ├── api_service.dart              # HTTP requests
│   ├── auth_service.dart             # Authentication
│   ├── local_storage.dart            # Local storage
│   └── qr_payment_service.dart       # QRIS handling
├── controllers/                       # GetX controllers
│   ├── auth_controller.dart
│   ├── analisis_controller.dart
│   ├── cabang_controller.dart
│   ├── crew_controller.dart
│   ├── crew_main_controller.dart
│   ├── galon_controller.dart
│   ├── kasir_controller.dart
│   ├── laporan_controller.dart
│   ├── pelanggan_controller.dart
│   ├── pengeluaran_controller.dart
│   ├── produk_controller.dart
│   └── transaksi_controller.dart
├── features/                         # UI Screens
│   ├── auth/
│   │   ├── login_peran_screen.dart
│   │   ├── login_crew_screen.dart
│   │   ├── login_manager_screen.dart
│   │   └── widgets/
│   ├── crew/
│   │   ├── dashboard/
│   │   │   ├── crew_main_screen.dart
│   │   │   ├── crewdashboard_screen.dart
│   │   │   ├── kasir.dart
│   │   │   ├── pembayaran_qr.dart
│   │   │   ├── data_pelanggan.dart
│   │   │   └── transaksi.dart
│   │   ├── history/
│   │   │   └── riwayat_transaksi.dart
│   │   ├── stock/
│   │   │   └── pencatatan_galon.dart
│   │   └── setting/
│   │       └── pengaturan.dart
│   ├── manager/
│   │   ├── dashboard/
│   │   │   ├── managerdashboard_screen.dart
│   │   │   ├── data_pelanggan.dart
│   │   │   ├── laporan_transaksi.dart
│   │   │   ├── analisis_keuangan.dart
│   │   │   └── data_crew.dart
│   │   ├── report/
│   │   │   └── analisis_keuangan.dart
│   │   ├── inventory/
│   │   │   └── asset_galon.dart
│   │   └── setting/
│   │       ├── data_produk.dart
│   │       ├── validasi_transaksi.dart
│   │       ├── data_kategori.dart
│   │       ├── data_pengeluaran.dart
│   │       ├── data_crew.dart
│   │       ├── manager_settings_screen.dart
│   │       └── cabang_depo_screen.dart
│   └── shared_components/
│       ├── navigation_drawer.dart
│       └── header_widget.dart
├── utils/
│   └── formatters.dart               # Format utilities
├── bindings/                         # GetX bindings
└── widgets/                          # Reusable widgets
```

### 2.2 Key Flutter Packages

| Package | Version | Use Case |
|---------|---------|----------|
| **get** | 4.6.6 | State management & navigation |
| **dio** | 5.4.0 | HTTP client for API calls |
| **shared_preferences** | 2.2.2 | Key-value storage |
| **flutter_secure_storage** | 9.0.0 | Encrypted token storage |
| **sqflite** | 2.3.2 | Local SQLite database |
| **qr_flutter** | 4.1.0 | QR code generation |
| **mobile_scanner** | 4.0.0 | QR code scanning |
| **flutter_svg** | 2.0.9 | SVG image support |
| **cached_network_image** | 3.3.1 | Image caching |
| **shimmer** | 3.0.0 | Skeleton loading |
| **intl** | 0.19.0 | Date formatting |
| **fl_chart** | 0.68.0 | Charts & graphs |

### 2.3 State Management Pattern (GetX)

```
┌─────────────────────────────────────────┐
│         GetX Controller Example          │
├─────────────────────────────────────────┤
│                                         │
│  class TransaksiController extends      │
│         GetxController {                │
│                                         │
│    // Observable State                  │
│    var transaksiList = <Transaksi>[].obs│
│    var isLoading = false.obs             │
│    var selectedPelanggan = Rx<Pelang... │
│                                         │
│    // Reactive Computed Values          │
│    get totalHarga => transaksiList      │
│      .fold(0.0, (sum, tx) =>            │
│        sum + tx.totalHarga)             │
│                                         │
│    // Methods                           │
│    Future<void> getTransaksi() async {  │
│      isLoading.value = true             │
│      try {                              │
│        final data = await              │
│          apiService.getTransaksi()     │
│        transaksiList.value = data       │
│      } catch(e) {                       │
│        handleError(e)                   │
│      } finally {                        │
│        isLoading.value = false          │
│      }                                  │
│    }                                    │
│  }                                      │
│                                         │
└─────────────────────────────────────────┘
```

### 2.4 API Request Flow

```
User Action (Button Click)
         │
         ▼
Get.find<TransaksiController>()
  .createTransaksi(data)
         │
         ▼
┌─────────────────────────────────┐
│ Service.apiService.post(...)    │
└────────┬────────────────────────┘
         │
         ▼
┌─────────────────────────────────┐
│ Dio Interceptor                 │
│ • Add JWT token to header       │
│ • Add request metadata          │
└────────┬────────────────────────┘
         │
         ▼
┌─────────────────────────────────┐
│ HTTP POST Request (HTTPS)       │
│ To: server/api/transaksi        │
└────────┬────────────────────────┘
         │
         ▼ (wait for response)
┌─────────────────────────────────┐
│ Response Handler                │
│ • Parse JSON                    │
│ • Convert to Model              │
│ • Error handling                │
└────────┬────────────────────────┘
         │
         ▼
┌─────────────────────────────────┐
│ Update Observable State         │
│ transaksiList.value = newList   │
└────────┬────────────────────────┘
         │
         ▼
┌─────────────────────────────────┐
│ UI Rebuilds (Reactive)          │
│ Obx() -> updates only affected  │
│         widgets                 │
└─────────────────────────────────┘
```

---

## 3. KOMPONEN BACKEND (Laravel)

### 3.1 Struktur Directory

```
backend_laravel/
├── artisan                          # CLI entry point
├── composer.json                    # PHP dependencies
├── .env                             # Environment variables
├── .env.example                     # Environment template
├── config/
│   ├── database.php                # MySQL connection config
│   ├── auth.php                    # Auth config
│   └── cors.php                    # CORS config
├── routes/                          # API Routes
│   ├── auth.js                     # /api/auth/*
│   ├── transactions.js             # /api/transaksi/*
│   ├── products.js                 # /api/produk/*
│   ├── customers.js                # /api/pelanggan/*
│   ├── users.js                    # /api/users/*
│   ├── reports.js                  # /api/laporan/*
│   ├── gallon.js                   # /api/galon/*
│   ├── qr-payments.js              # /api/qr-payment/*
│   ├── categories.js               # /api/kategori/*
│   └── analytics.js                # /api/analisis/*
├── middleware/
│   ├── auth.js                     # JWT verification
│   ├── errorHandler.js             # Error handling
│   ├── logger.js                   # Request logging
│   ├── rateLimiter.js              # Rate limiting
│   └── validator.js                # Input validation
├── services/                        # Business logic
│   ├── authService.js
│   ├── transactionService.js
│   ├── productService.js
│   ├── customerService.js
│   ├── userService.js
│   ├── reportService.js
│   ├── gallonService.js
│   ├── paymentService.js
│   ├── analyticsService.js
│   └── validationService.js
├── models/                          # Database models
│   ├── User.js
│   ├── Product.js
│   ├── Customer.js
│   ├── Transaction.js
│   ├── Category.js
│   ├── Gallon.js
│   └── QRPayment.js
├── controllers/                     # Route handlers
│   ├── authController.js
│   ├── transactionController.js
│   ├── productController.js
│   ├── customerController.js
│   ├── userController.js
│   ├── reportController.js
│   ├── gallonController.js
│   ├── paymentController.js
│   └── analyticsController.js
├── utils/
│   ├── validator.js                # Validation helpers
│   ├── formatter.js                # Format helpers
│   ├── errorHandler.js             # Error utilities
│   └── logger.js                   # Logging utility
├── database/
│   └── schema.sql                  # Database schema
├── docs/
│   ├── API.md                      # API documentation
│   └── SETUP.md                    # Setup guide
└── tests/                           # Unit tests
    ├── auth.test.js
    ├── transaction.test.js
    └── ...
```

### 3.2 Laravel Router Structure

```javascript
// server.js structure
const express = require('express');
const app = express();

// ┌──────────────────────────────────┐
// │  Middleware Setup                │
// └──────────────────────────────────┘
app.use(cors());
app.use(express.json());
app.use(requestLogger);
app.use(errorHandler);

// ┌──────────────────────────────────┐
// │  Route Groups                    │
// └──────────────────────────────────┘
app.use('/api/auth', authRoutes);          // Authentication
app.use('/api/transaksi', authMiddleware, transactionRoutes);
app.use('/api/produk', authMiddleware, productRoutes);
app.use('/api/pelanggan', authMiddleware, customerRoutes);
app.use('/api/laporan', authMiddleware, reportRoutes);
app.use('/api/galon', authMiddleware, gallonRoutes);
app.use('/api/qr-payment', paymentRoutes);
app.use('/api/analisis', authMiddleware, analyticsRoutes);

// ┌──────────────────────────────────┐
// │  Error Handling Middleware       │
// └──────────────────────────────────┘
app.use(errorHandler);

// ┌──────────────────────────────────┐
// │  Start Server                    │
// └──────────────────────────────────┘
app.listen(PORT, () => {
  console.log(`Server running on port ${PORT}`);
});
```

### 3.3 Authentication Flow

```
1. LOGIN REQUEST
   ┌────────────────────────────┐
   │  POST /api/auth/login      │
   │  Body: username, password  │
   └────────┬───────────────────┘
            │
            ▼
2. VALIDATE CREDENTIALS
   ┌────────────────────────────┐
   │  Query: SELECT * FROM users│
   │  WHERE username = ?        │
   └────────┬───────────────────┘
            │
            ▼
3. VERIFY PASSWORD
   ┌────────────────────────────┐
   │  bcrypt.compare(password,  │
   │           passwordHash)    │
   └────────┬───────────────────┘
            │
       ┌────┴────┐
       │          │
      Valid    Invalid
       │          │
       │          ▼
       │    ┌──────────────────┐
       │    │ Return 401 Error │
       │    └──────────────────┘
       │
       ▼
4. GENERATE TOKENS
   ┌────────────────────────────┐
   │  JWT.sign({              │
   │    userId, role, exp: 8h  │
   │  })                        │
   │  Refresh Token: exp: 30d   │
   └────────┬───────────────────┘
            │
            ▼
5. STORE REFRESH TOKEN
   ┌────────────────────────────┐
   │  INSERT INTO refresh_tokens│
   │  (token, user_id, ...)     │
   └────────┬───────────────────┘
            │
            ▼
6. RETURN RESPONSE
   ┌────────────────────────────┐
   │  {                         │
   │    token,                  │
   │    refreshToken,           │
   │    user: {id, name, role}  │
   │  }                         │
   └────────────────────────────┘
```

### 3.4 Transaction Creation Flow

```
POST /api/transaksi
│
├─ Extract data (pelanggan_id, items, metode)
│
├─ VALIDATE INPUT
│  ├─ Check pelanggan exists
│  ├─ Check produk exists
│  ├─ Check stock sufficient
│  └─ Validate amounts
│
├─ BEGIN TRANSACTION
│  │
│  ├─ INSERT INTO transaksi
│  │  (id, nomor_transaksi, total_harga, status='pending')
│  │
│  ├─ FOR EACH ITEM:
│  │  ├─ INSERT INTO transaksi_items
│  │  │  (transaksi_id, produk_id, jumlah, harga_satuan)
│  │  │
│  │  └─ IF galon dipinjam:
│  │     └─ UPDATE galon status='dipinjam'
│  │
│  ├─ COMMIT TRANSACTION
│  │
│  └─ ON ERROR: ROLLBACK ALL CHANGES
│
└─ RETURN transaksi response
```

---

## 4. DATABASE LAYER

### 4.1 MySQL Connection Pool

```javascript
// Menggunakan mysql2/promise untuk pooling
const mysql = require('mysql2/promise');

const pool = mysql.createPool({
  host: process.env.DB_HOST,
  user: process.env.DB_USER,
  password: process.env.DB_PASSWORD,
  database: process.env.DB_NAME,
  waitForConnections: true,
  connectionLimit: 10,      // Max 10 concurrent
  queueLimit: 0            // Unlimited queue
});

// ┌─────────────────────────────────────┐
// │  Connection Pool Diagram            │
// └─────────────────────────────────────┘
//
//  Request 1  Request 2  Request 3
//      │          │          │
//      └──────────┼──────────┘
//                 │
//      ┌──────────▼────────────┐
//      │  Connection Pool      │
//      │  (Max 10 connections) │
//      │                       │
//      │  ┌────────────────┐   │
//      │  │ Connection 1   │──→ MySQL
//      │  └────────────────┘   │
//      │  ┌────────────────┐   │
//      │  │ Connection 2   │──→ MySQL
//      │  └────────────────┘   │
//      │  ...                   │
//      │  ┌────────────────┐   │
//      │  │ Connection 10  │──→ MySQL
//      │  └────────────────┘   │
//      │                       │
//      └───────────────────────┘
```

### 4.2 Query Examples

```javascript
// ┌─────────────────────────────────────┐
// │  Example 1: Get All Transactions    │
// └─────────────────────────────────────┘
async function getTransactions(userId, role) {
  const conn = await pool.getConnection();
  try {
    let query = `
      SELECT t.*, 
             p.nama as pelanggan_nama,
             u.nama as crew_nama
      FROM transaksi t
      JOIN pelanggan p ON t.pelanggan_id = p.id
      JOIN users u ON t.crew_id = u.id
      WHERE 1=1
    `;
    
    const params = [];
    
    // Crew hanya lihat transaksi mereka sendiri
    if (role === 'crew') {
      query += ` AND t.crew_id = ?`;
      params.push(userId);
    }
    
    // Filter by date if provided
    if (startDate && endDate) {
      query += ` AND DATE(t.created_at) BETWEEN ? AND ?`;
      params.push(startDate, endDate);
    }
    
    query += ` ORDER BY t.created_at DESC LIMIT ? OFFSET ?`;
    params.push(limit, offset);
    
    const [rows] = await conn.query(query, params);
    return rows;
  } finally {
    conn.release();
  }
}

// ┌─────────────────────────────────────┐
// │  Example 2: Create Transaction      │
// │  (with Transaction Support)         │
// └─────────────────────────────────────┘
async function createTransaction(data) {
  const conn = await pool.getConnection();
  
  try {
    // BEGIN TRANSACTION
    await conn.beginTransaction();
    
    // 1. Insert main transaction
    const [result] = await conn.query(
      `INSERT INTO transaksi 
       (id, nomor_transaksi, pelanggan_id, crew_id, 
        total_harga, metode_pembayaran, status)
       VALUES (?, ?, ?, ?, ?, ?, 'pending')`,
      [id, nomor, pelangganId, crewId, totalHarga, metode]
    );
    
    // 2. Insert transaction items
    for (const item of data.items) {
      await conn.query(
        `INSERT INTO transaksi_items
         (id, transaksi_id, produk_id, jumlah, 
          harga_satuan, subtotal)
         VALUES (?, ?, ?, ?, ?, ?)`,
        [itemId, id, item.produk_id, item.jumlah,
         item.harga, item.subtotal]
      );
      
      // Update product stock
      await conn.query(
        `UPDATE produk 
         SET stok = stok - ?
         WHERE id = ?`,
        [item.jumlah, item.produk_id]
      );
    }
    
    // 3. If gallon borrowed, update gallon status
    if (data.galonPinjam > 0) {
      await conn.query(
        `UPDATE galon 
         SET status = 'dipinjam',
             pelanggan_id = ?
         WHERE id IN (SELECT id FROM galon 
                      WHERE status = 'tersedia' 
                      LIMIT ?)`,
        [pelangganId, data.galonPinjam]
      );
    }
    
    // COMMIT TRANSACTION
    await conn.commit();
    
    return { success: true, transaksiId: id };
    
  } catch (error) {
    // ROLLBACK on error
    await conn.rollback();
    throw error;
  } finally {
    conn.release();
  }
}
```

### 4.3 Index Strategy

```sql
-- ┌─────────────────────────────────────┐
-- │  Performance Indexes                │
-- └─────────────────────────────────────┘

-- Users table
CREATE INDEX idx_users_username ON users(username);
CREATE INDEX idx_users_role ON users(role);

-- Transaksi table
CREATE INDEX idx_transaksi_pelanggan_id ON transaksi(pelanggan_id);
CREATE INDEX idx_transaksi_crew_id ON transaksi(crew_id);
CREATE INDEX idx_transaksi_status ON transaksi(status);
CREATE INDEX idx_transaksi_created_at ON transaksi(created_at);

-- Produk table
CREATE INDEX idx_produk_kategori_id ON produk(kategori_id);
CREATE INDEX idx_produk_is_aktif ON produk(is_aktif);

-- Pelanggan table
CREATE INDEX idx_pelanggan_is_aktif ON pelanggan(is_aktif);
CREATE FULLTEXT INDEX idx_pelanggan_nama ON pelanggan(nama);

-- Galon table
CREATE INDEX idx_galon_status ON galon(status);
CREATE INDEX idx_galon_pelanggan_id ON galon(pelanggan_id);
CREATE INDEX idx_galon_kode_galon ON galon(kode_galon);

-- Galon mutasi
CREATE INDEX idx_galon_mutasi_created_at ON galon_mutasi(created_at);
CREATE INDEX idx_galon_mutasi_pelanggan_id ON galon_mutasi(pelanggan_id);
```

---

## 5. KEAMANAN SISTEM

### 5.1 JWT Token Flow

```
┌────────────────────────────────────────────────┐
│  TOKEN GENERATION (at Login)                   │
├────────────────────────────────────────────────┤
│                                                │
│  Payload: {                                    │
│    "userId": "abc123",                         │
│    "role": "crew",                             │
│    "exp": 1234567890  (8 hours from now)       │
│  }                                             │
│                                                │
│  Header: {                                     │
│    "alg": "HS256",                             │
│    "typ": "JWT"                                │
│  }                                             │
│                                                │
│  Signature = HMAC-SHA256(                      │
│    base64(header).base64(payload),             │
│    JWT_SECRET                                  │
│  )                                             │
│                                                │
│  Token = header.payload.signature              │
│                                                │
└────────────────────────────────────────────────┘

┌────────────────────────────────────────────────┐
│  TOKEN VERIFICATION (on each API call)         │
├────────────────────────────────────────────────┤
│                                                │
│  1. Extract token from Authorization header    │
│     Authorization: Bearer <token>              │
│                                                │
│  2. Verify signature using JWT_SECRET          │
│     If signature invalid → 401 Unauthorized    │
│                                                │
│  3. Check token expiry (exp claim)             │
│     If expired → return 401                    │
│     → Use refresh token to get new token       │
│                                                │
│  4. Extract payload (userId, role)             │
│     Add to request.user for downstream         │
│                                                │
│  5. Check authorization (RBAC)                 │
│     If not authorized → 403 Forbidden          │
│                                                │
│  6. Process the request                        │
│                                                │
└────────────────────────────────────────────────┘

┌────────────────────────────────────────────────┐
│  TOKEN REFRESH FLOW                            │
├────────────────────────────────────────────────┤
│                                                │
│  Client detects token expired                  │
│            ↓                                    │
│  POST /api/auth/refresh                        │
│  Body: { refreshToken: "..." }                 │
│            ↓                                    │
│  Server validates refresh token                │
│  • Check in refresh_tokens table               │
│  • Verify signature                            │
│  • Check expiry (30 days)                      │
│            ↓                                    │
│  Generate new access token (8 hours)           │
│  Generate new refresh token (30 days)          │
│  Store new refresh token in DB                 │
│            ↓                                    │
│  Return: { token, refreshToken }               │
│            ↓                                    │
│  Client stores new token & retries request     │
│                                                │
└────────────────────────────────────────────────┘
```

### 5.2 Password Encryption

```javascript
// ┌────────────────────────────────────┐
// │  Password Hashing with Bcrypt      │
// └────────────────────────────────────┘

// When creating/updating password
const bcrypt = require('bcryptjs');

async function hashPassword(plainPassword) {
  const salt = await bcrypt.genSalt(10);  // 10 rounds
  const hash = await bcrypt.hash(plainPassword, salt);
  return hash;  // Store in database
}

// When verifying password
async function verifyPassword(plainPassword, hash) {
  const isValid = await bcrypt.compare(plainPassword, hash);
  return isValid;
}

// Never store plain password
// Example hash:
// $2a$10$vI8aWBYW3KwFvJ/Fk.y4Eu2p9ZxZ.gZaLWPyPKK3rU6u5xL2lxnLS
// ^salt       ^hashed password
```

### 5.3 Input Validation

```javascript
// ┌────────────────────────────────────┐
// │  Server-side Validation            │
// └────────────────────────────────────┘

// Example: Create transaction validation
function validateCreateTransaction(data) {
  const errors = {};
  
  // Validate pelanggan_id
  if (!data.pelanggan_id) {
    errors.pelanggan_id = 'Pelanggan harus dipilih';
  }
  
  // Validate items
  if (!data.items || data.items.length === 0) {
    errors.items = 'Minimal 1 item harus ada';
  } else {
    data.items.forEach((item, idx) => {
      if (!item.produk_id) 
        errors[`items[${idx}].produk_id`] = 'Produk tidak valid';
      if (item.jumlah < 1) 
        errors[`items[${idx}].jumlah`] = 'Jumlah harus >= 1';
      if (item.harga_satuan < 0) 
        errors[`items[${idx}].harga`] = 'Harga tidak valid';
    });
  }
  
  // Validate payment method
  const validMethods = ['tunai', 'qris', 'transfer'];
  if (!validMethods.includes(data.metode_pembayaran)) {
    errors.metode = 'Metode pembayaran tidak valid';
  }
  
  return Object.keys(errors).length === 0 ? null : errors;
}

// Client-side validation (Flutter)
// Use same validation logic before sending to server
```

---

## 6. PERFORMANCE OPTIMIZATION

### 6.1 Caching Strategy

```
┌─────────────────────────────────────────┐
│  CLIENT-SIDE CACHING (Flutter)          │
├─────────────────────────────────────────┤
│                                         │
│  ┌──────────────────────────────────┐  │
│  │ Layer 1: Memory Cache            │  │
│  │ • GetX observable state           │  │
│  │ • Duration: Session lifetime      │  │
│  │ • Hit rate: Very High (90%+)      │  │
│  └──────────────────────────────────┘  │
│                                         │
│  ┌──────────────────────────────────┐  │
│  │ Layer 2: SQLite Cache             │  │
│  │ • Local database                  │  │
│  │ • Duration: 7 days (or user set)  │  │
│  │ • Hit rate: High (70%)            │  │
│  │ • Use for offline support         │  │
│  └──────────────────────────────────┘  │
│                                         │
│  ┌──────────────────────────────────┐  │
│  │ Layer 3: Shared Preferences       │  │
│  │ • Key-value store                 │  │
│  │ • Duration: Until cleared         │  │
│  │ • Hit rate: Very High for keys    │  │
│  │ • Use for settings & metadata     │  │
│  └──────────────────────────────────┘  │
│                                         │
│  Miss on all layers → Fetch from server │
│                                         │
└─────────────────────────────────────────┘

┌─────────────────────────────────────────┐
│  SERVER-SIDE CACHING (Laravel)          │
├─────────────────────────────────────────┤
│                                         │
│  ┌──────────────────────────────────┐  │
│  │ Layer 1: Memory Cache (Redis)    │  │
│  │ • In-memory data store            │  │
│  │ • Duration: 5-60 minutes          │  │
│  │ • Hit rate: Very High (80%+)      │  │
│  │ • Use for: Products, Categories   │  │
│  └──────────────────────────────────┘  │
│                                         │
│  ┌──────────────────────────────────┐  │
│  │ Layer 2: Database Cache           │  │
│  │ • MySQL Query Cache                │  │
│  │ • Duration: Until data changes     │  │
│  │ • Hit rate: Medium (50-60%)        │  │
│  └──────────────────────────────────┘  │
│                                         │
│  ┌──────────────────────────────────┐  │
│  │ Layer 3: HTTP Cache (Nginx)      │  │
│  │ • Reverse proxy cache              │  │
│  │ • Duration: 1-24 hours             │  │
│  │ • Hit rate: High for GET requests  │  │
│  └──────────────────────────────────┘  │
│                                         │
└─────────────────────────────────────────┘
```

### 6.2 Query Optimization

```sql
-- ❌ BAD: N+1 Query Problem
SELECT * FROM transaksi WHERE crew_id = 1;
-- For each transaction:
SELECT * FROM transaksi_items WHERE transaksi_id = ?;
SELECT * FROM produk WHERE id = ?;
-- Total: 1 + N + N queries

-- ✅ GOOD: Single optimized query with JOIN
SELECT 
    t.*,
    ti.id as item_id,
    ti.jumlah,
    ti.harga_satuan,
    p.nama as produk_nama,
    c.nama as pelanggan_nama
FROM transaksi t
LEFT JOIN transaksi_items ti ON t.id = ti.transaksi_id
LEFT JOIN produk p ON ti.produk_id = p.id
JOIN pelanggan c ON t.pelanggan_id = c.id
WHERE t.crew_id = 1
ORDER BY t.created_at DESC;
-- Total: 1 query
```

### 6.3 API Response Pagination

```javascript
// ┌────────────────────────────────────┐
// │  Pagination Example                │
// └────────────────────────────────────┘

// Request
GET /api/transaksi?limit=20&offset=0

// Response
{
  "data": [
    { id: "1", nomor_transaksi: "TRX001", ... },
    { id: "2", nomor_transaksi: "TRX002", ... },
    ...  (20 items)
  ],
  "pagination": {
    "limit": 20,
    "offset": 0,
    "total": 1000,
    "pages": 50,
    "current_page": 1,
    "has_next": true,
    "has_prev": false
  }
}

// Benefits
// • Reduces response payload
// • Faster loading
// • Better memory usage
```

---

## 7. ERROR HANDLING & LOGGING

### 7.1 Error Handling Flow

```
API Request
    ↓
API Controller
    ↓
Try/Catch Block
    ├─ Success → Response 200
    └─ Error → Error Handler
         │
         ├─ Validate Error Type
         │  ├─ Input Validation Error → 400
         │  ├─ Authentication Error → 401
         │  ├─ Authorization Error → 403
         │  ├─ Not Found Error → 404
         │  ├─ Database Error → 500
         │  └─ Server Error → 500
         │
         ├─ Log Error Details
         │  ├─ Timestamp
         │  ├─ Error message
         │  ├─ Stack trace
         │  ├─ User info
         │  └─ Request details
         │
         ├─ Prepare Response
         │  ├─ Status code
         │  ├─ Error message (user-friendly)
         │  └─ Error code (for debugging)
         │
         └─ Return Error Response
```

### 7.2 Logging Strategy

```javascript
// ┌────────────────────────────────────┐
// │  Structured Logging                │
// └────────────────────────────────────┘

// Log Levels (from least to most severe)
DEBUG    - Development debugging info
INFO     - General information
WARN     - Warning conditions
ERROR    - Error conditions
FATAL    - Fatal conditions

// Log Example
{
  timestamp: "2024-06-19T10:30:45.123Z",
  level: "INFO",
  method: "POST",
  url: "/api/transaksi",
  status: 200,
  duration: "245ms",
  user_id: "user_123",
  role: "crew",
  message: "Transaction created successfully",
  details: {
    transaksi_id: "txn_456",
    total_harga: 50000
  }
}
```

---

## KESIMPULAN

Dokumentasi arsitektur teknis ini menjelaskan:

1. **Arsitektur Sistem** - Client-server dengan tiga layer (presentation, business logic, data)
2. **Frontend Components** - Flutter dengan GetX state management
3. **Backend Components** - Laravel API dengan controller, middleware, model, dan service layer
4. **Database Layer** - MySQL dengan connection pooling dan optimization
5. **Security** - JWT authentication, password hashing, input validation
6. **Performance** - Caching strategies, query optimization, pagination
7. **Error Handling** - Comprehensive error handling dan logging

Sistem dirancang untuk scalability, security, dan maintainability.

---

**Dokumen Arsitektur Teknis**
*Version: 1.0*
*Last Updated: 2026-06-19*
