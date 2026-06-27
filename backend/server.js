/**
 * Depo Air REST API v1
 * Kontrak: depo_app/lib/services/api_service.dart
 * Database: MySQL
 */
require('dotenv').config();
const express = require('express');
const cors = require('cors');
const fs = require('fs');
const os = require('os');
const path = require('path');
const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
const { v4: uuidv4 } = require('uuid');
const mysql = require('mysql2/promise');
const crypto = require('crypto');

// ── MIDTRANS CONFIG ───────────────────────────────────────────────────────────
const MIDTRANS_SERVER_KEY = process.env.MIDTRANS_SERVER_KEY || '';
const MIDTRANS_CLIENT_KEY = process.env.MIDTRANS_CLIENT_KEY || '';
const MIDTRANS_IS_PRODUCTION = process.env.MIDTRANS_IS_PRODUCTION === 'true';
const MIDTRANS_BASE_URL = MIDTRANS_IS_PRODUCTION
  ? 'https://api.midtrans.com'
  : 'https://api.sandbox.midtrans.com';

function midtransAuthHeader() {
  return 'Basic ' + Buffer.from(MIDTRANS_SERVER_KEY + ':').toString('base64');
}

const PORT = process.env.PORT || 3000;
const JWT_SECRET = process.env.JWT_SECRET || 'depoair-dev-secret-change-in-production';

const app = express();
app.use(cors());
app.use(express.json());

// MySQL connection pool
let pool;

// Decimal keys to automatically cast back to number
const DECIMAL_KEYS = new Set([
  'harga', 'nominal', 'totalHarga', 'bayar', 'kembalian', 
  'hargaSatuan', 'subtotal', 'jumlah', 'totalTransaksi'
]);

// Mapping helpers
function snakeToCamel(obj) {
  if (obj === null || obj === undefined) return obj;
  if (obj instanceof Date) return obj.toISOString();
  if (Array.isArray(obj)) return obj.map(snakeToCamel);
  if (typeof obj === 'object') {
    if (obj.constructor && obj.constructor.name === 'Buffer') {
      return obj;
    }
    return Object.keys(obj).reduce((acc, key) => {
      const camelKey = key.replace(/_([a-z0-9])/g, (g) => g[1].toUpperCase());
      let val = obj[key];
      
      if (val instanceof Date) {
        acc[camelKey] = val.toISOString();
        return acc;
      }
      
      // Convert buffer boolean or numeric representations
      if (typeof val === 'object' && val !== null && val.type === 'Buffer') {
        val = val.data[0];
      }
      
      // If it's is_aktif or is_system, convert to boolean
      if (key === 'is_aktif' || key === 'is_system' || key === 'is_pusat') {
        val = val === 1 || val === true;
      }
      
      // If it's a date column and key is tanggal, keep it as YYYY-MM-DD
      if (key === 'tanggal' && val instanceof Date) {
        const y = val.getFullYear();
        const m = String(val.getMonth() + 1).padStart(2, '0');
        const d = String(val.getDate()).padStart(2, '0');
        val = `${y}-${m}-${d}`;
      }
      
      // Handle decimals cast to floats
      if (DECIMAL_KEYS.has(camelKey) && typeof val === 'string') {
        val = parseFloat(val);
      }
      
      acc[camelKey] = snakeToCamel(val);
      return acc;
    }, {});
  }
  return obj;
}

function camelToSnake(obj) {
  if (obj === null || obj === undefined) return obj;
  if (obj instanceof Date) return obj.toISOString().slice(0, 19).replace('T', ' ');
  if (Array.isArray(obj)) return obj.map(camelToSnake);
  if (typeof obj === 'object') {
    return Object.keys(obj).reduce((acc, key) => {
      const snakeKey = key.replace(/[A-Z0-9]/g, (letter) => `_${letter.toLowerCase()}`);
      acc[snakeKey] = camelToSnake(obj[key]);
      return acc;
    }, {});
  }
  return obj;
}

// Connect to Database
async function connectDb() {
  pool = mysql.createPool({
    host: process.env.DB_HOST || '127.0.0.1',
    port: parseInt(process.env.DB_PORT, 10) || 3306,
    user: process.env.DB_USER || 'root',
    password: process.env.DB_PASSWORD !== undefined ? process.env.DB_PASSWORD : 'password',
    database: process.env.DB_NAME || 'depo_app',
    waitForConnections: true,
    connectionLimit: 10,
    queueLimit: 0
  });
  
  try {
    const conn = await pool.getConnection();
    console.log(`[DB] Terhubung ke MySQL database: ${process.env.DB_NAME}`);
    conn.release();
  } catch (err) {
    console.error('[DB] Gagal terhubung ke MySQL database. Pastikan database sudah dibuat di MySQL Anda.');
    console.error(err);
    process.exit(1);
  }
}

// Seeding Default Data
async function seedDbData(conn) {
  console.log('[DB] Seeding data awal...');
  const now = new Date().toISOString().slice(0, 19).replace('T', ' ');
  const crewId = 'crew_001';
  const managerId = 'manager_001';
  const katIsiUlang = uuidv4();
  const katGalonBaru = uuidv4();
  const katAksesoris = uuidv4();
  const katGajiCrew = uuidv4();
  const katListrik = uuidv4();
  const katSewa = uuidv4();
  const katMaintenance = uuidv4();
  const produkAir = uuidv4();
  const produkGalon = uuidv4();
  const pelanggan1 = uuidv4();

  // Users
  await conn.query(
    `INSERT INTO users (id, role, username, password_hash, pin_hash, nama, no_hp, alamat, is_aktif, created_at) VALUES 
     (?, 'crew', 'crew001', ?, ?, 'Budi Santoso', '081234567890', 'Jl. Crew No. 1', 1, ?),
     (?, 'manager', 'manager@depoair.com', ?, NULL, 'Ahmad Manager', '081298765432', 'Kantor Depo', 1, ?)`,
    [
      crewId, bcrypt.hashSync('1234', 10), bcrypt.hashSync('1234', 10), now,
      managerId, bcrypt.hashSync('Password123', 10), now
    ]
  );

  // Kategori
  await conn.query(
    `INSERT INTO kategori (id, nama, deskripsi, tipe, ikon, is_system, is_aktif, created_at) VALUES 
     (?, 'Penjualan Isi Ulang', 'Produk Utama', 'pemasukan', 'water_drop', 1, 1, ?),
     (?, 'Penjualan Galon Baru', 'Inventori', 'pemasukan', 'inventory_2', 1, 1, ?),
     (?, 'Penjualan Aksesoris', 'Tambahan (Tutup/Tissue)', 'pemasukan', 'widgets', 0, 1, ?),
     (?, 'Gaji Crew', 'Biaya Operasional', 'pengeluaran', 'people', 1, 1, ?),
     (?, 'Biaya Listrik & Air', 'Utilitas Bulanan', 'pengeluaran', 'bolt', 1, 1, ?),
     (?, 'Sewa Tempat', 'Biaya Tetap', 'pengeluaran', 'store', 1, 1, ?),
     (?, 'Perawatan Alat', 'Maintenance', 'pengeluaran', 'build', 0, 1, ?)`,
    [
      katIsiUlang, now,
      katGalonBaru, now,
      katAksesoris, now,
      katGajiCrew, now,
      katListrik, now,
      katSewa, now,
      katMaintenance, now
    ]
  );

  // Produk
  await conn.query(
    `INSERT INTO produk (id, nama, kategori_id, harga, stok, deskripsi, is_aktif, created_at) VALUES 
     (?, 'Air Galon 19L', ?, 15000, 100, 'Air minum kemasan galon 19 liter', 1, ?),
     (?, 'Isi Ulang Galon', ?, 12000, 200, 'Layanan isi ulang galon pelanggan', 1, ?)`,
    [
      produkAir, katIsiUlang, now,
      produkGalon, katGalonBaru, now
    ]
  );

  // Pelanggan
  await conn.query(
    `INSERT INTO pelanggan (id, nama, no_hp, alamat, total_galon_pinjam, total_transaksi, is_aktif, created_at) VALUES 
     (?, 'Siti Aminah', '081211112222', 'Jl. Melati No. 5', 2, 450000.00, 1, ?)`,
    [
      pelanggan1, now
    ]
  );
  
  // Seed 50 units of galon (35 tersedia, 12 dipinjam, 2 rusak, 1 hilang)
  for (let i = 1; i <= 35; i++) {
    const gid = uuidv4();
    const code = `G-${String(i).padStart(3, '0')}`;
    await conn.query(
      `INSERT INTO galon (id, kode_galon, merek, jenis, status, pelanggan_id, created_at) VALUES (?, ?, 'Depo', 'isi', 'tersedia', NULL, ?)`,
      [gid, code, now]
    );
  }
  for (let i = 36; i <= 47; i++) {
    const gid = uuidv4();
    const code = `G-${String(i).padStart(3, '0')}`;
    await conn.query(
      `INSERT INTO galon (id, kode_galon, merek, jenis, status, pelanggan_id, created_at) VALUES (?, ?, 'Depo', 'isi', 'dipinjam', ?, ?)`,
      [gid, code, pelanggan1, now]
    );
  }
  for (let i = 48; i <= 49; i++) {
    const gid = uuidv4();
    const code = `G-${String(i).padStart(3, '0')}`;
    await conn.query(
      `INSERT INTO galon (id, kode_galon, merek, jenis, status, pelanggan_id, created_at) VALUES (?, ?, 'Depo', 'isi', 'rusak', NULL, ?)`,
      [gid, code, now]
    );
  }
  {
    const gid = uuidv4();
    const code = `G-050`;
    await conn.query(
      `INSERT INTO galon (id, kode_galon, merek, jenis, status, pelanggan_id, created_at) VALUES (?, ?, 'Depo', 'isi', 'hilang', NULL, ?)`,
      [gid, code, now]
    );
  }

  console.log('[DB] Seeding selesai.');
}

// Auto Initialize Schema
async function initDbSchema() {
  const conn = await pool.getConnection();
  try {
    const [rows] = await conn.query("SHOW TABLES LIKE 'users'");
    if (rows.length === 0) {
      console.log('[DB] Tabel tidak ditemukan. Menginisialisasi skema dari schema.sql...');
      const schemaPath = path.join(__dirname, 'schema.sql');
      if (fs.existsSync(schemaPath)) {
        const sql = fs.readFileSync(schemaPath, 'utf8');
        const statements = sql
          .split(';')
          .map((s) => s.trim())
          .filter((s) => s.length > 0);
          
        for (const statement of statements) {
          await conn.query(statement);
        }
        console.log('[DB] Skema database berhasil diinisialisasi.');
        await seedDbData(conn);
      } else {
        console.warn('[DB] schema.sql tidak ditemukan. Tidak dapat menginisialisasi skema.');
      }
    } else {
      console.log('[DB] Skema database sudah terinisialisasi.');
    }
    await ensureUserSchema(conn);
    await ensureGalonSchema(conn);
    await ensureCabangSchema(conn);
    await ensureTransaksiSchema(conn);
  } catch (err) {
    console.error('[DB] Gagal menginisialisasi skema database:', err);
  } finally {
    conn.release();
  }
}

async function tableExists(conn, table) {
  const [rows] = await conn.query(
    `SELECT COUNT(*) AS c FROM information_schema.TABLES
     WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = ?`,
    [table]
  );
  return Number(rows[0].c) > 0;
}

async function columnExists(conn, table, column) {
  const [rows] = await conn.query(
    `SELECT COUNT(*) AS c FROM information_schema.COLUMNS
     WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = ? AND COLUMN_NAME = ?`,
    [table, column]
  );
  return Number(rows[0].c) > 0;
}


/** Kolom PIN crew untuk login mobile yang lebih cepat. */
async function ensureUserSchema(conn) {
  if (!(await tableExists(conn, 'users'))) return;

  const columns = [
    { name: 'email', ddl: 'ADD COLUMN `email` VARCHAR(150) NULL' },
    { name: 'foto_url', ddl: 'ADD COLUMN `foto_url` VARCHAR(255) NULL' },
    { name: 'pin_hash', ddl: 'ADD COLUMN `pin_hash` VARCHAR(255) NULL' },
    { name: 'updated_at', ddl: 'ADD COLUMN `updated_at` DATETIME NULL ON UPDATE CURRENT_TIMESTAMP' },
  ];

  for (const col of columns) {
    if (!(await columnExists(conn, 'users', col.name))) {
      await conn.query(`ALTER TABLE users ${col.ddl}`);
      console.log(`[DB] Migrasi: users.${col.name} ditambahkan`);
    }
  }

  await conn.query(
    `UPDATE users SET pin_hash = ? WHERE role = 'crew' AND (pin_hash IS NULL OR pin_hash = '')`,
    [bcrypt.hashSync('1234', 10)]
  );
}

/** Perbaiki skema galon jika DB dibuat dari versi lama (unknown column). */
async function ensureGalonSchema(conn) {
  if (!(await tableExists(conn, 'galon'))) {
    console.log('[DB] Tabel galon belum ada, membuat...');
    await conn.query(`
      CREATE TABLE IF NOT EXISTS \`galon\` (
        \`id\` VARCHAR(100) NOT NULL,
        \`kode_galon\` VARCHAR(20) NOT NULL UNIQUE,
        \`merek\` VARCHAR(100) NOT NULL DEFAULT 'Depo',
        \`jenis\` ENUM('isi', 'kosong') NOT NULL DEFAULT 'isi',
        \`status\` ENUM('tersedia', 'dipinjam', 'rusak', 'hilang') NOT NULL DEFAULT 'tersedia',
        \`pelanggan_id\` VARCHAR(100) NULL,
        \`catatan\` TEXT NULL,
        \`created_at\` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
        \`updated_at\` DATETIME NULL ON UPDATE CURRENT_TIMESTAMP,
        PRIMARY KEY (\`id\`)
      ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
    `);
  }

  const galonColumns = [
    { name: 'pelanggan_id', ddl: 'ADD COLUMN `pelanggan_id` VARCHAR(100) NULL' },
    { name: 'catatan', ddl: 'ADD COLUMN `catatan` TEXT NULL' },
    { name: 'updated_at', ddl: 'ADD COLUMN `updated_at` DATETIME NULL ON UPDATE CURRENT_TIMESTAMP' },
    { name: 'merek', ddl: "ADD COLUMN `merek` VARCHAR(100) NOT NULL DEFAULT 'Depo'" },
    { name: 'jenis', ddl: "ADD COLUMN `jenis` ENUM('isi', 'kosong') NOT NULL DEFAULT 'isi'" },
  ];

  for (const col of galonColumns) {
    if (!(await columnExists(conn, 'galon', col.name))) {
      await conn.query(`ALTER TABLE galon ${col.ddl}`);
      console.log(`[DB] Migrasi: kolom galon.${col.name} ditambahkan`);
    }
  }

  if (!(await tableExists(conn, 'galon_mutasi'))) {
    console.log('[DB] Tabel galon_mutasi belum ada, membuat...');
    await conn.query(`
      CREATE TABLE IF NOT EXISTS \`galon_mutasi\` (
        \`id\` VARCHAR(100) NOT NULL,
        \`aksi\` VARCHAR(50) NOT NULL,
        \`jumlah\` INT NOT NULL,
        \`kode_galon\` TEXT NOT NULL,
        \`pelanggan_id\` VARCHAR(100) NULL,
        \`catatan\` TEXT NULL,
        \`crew_id\` VARCHAR(100) NULL,
        \`crew_nama\` VARCHAR(150) NULL,
        \`status_dari\` VARCHAR(50) NULL,
        \`status_ke\` VARCHAR(50) NULL,
        \`created_at\` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
        PRIMARY KEY (\`id\`)
      ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
    `);
  } else {
    const mutasiColumns = [
      { name: 'aksi', ddl: "ADD COLUMN `aksi` VARCHAR(50) NOT NULL DEFAULT 'pinjam'" },
      { name: 'jumlah', ddl: 'ADD COLUMN `jumlah` INT NOT NULL DEFAULT 0' },
      { name: 'kode_galon', ddl: "ADD COLUMN `kode_galon` TEXT NOT NULL DEFAULT '[]'" },
      { name: 'pelanggan_id', ddl: 'ADD COLUMN `pelanggan_id` VARCHAR(100) NULL' },
      { name: 'catatan', ddl: 'ADD COLUMN `catatan` TEXT NULL' },
      { name: 'crew_id', ddl: 'ADD COLUMN `crew_id` VARCHAR(100) NULL' },
      { name: 'crew_nama', ddl: 'ADD COLUMN `crew_nama` VARCHAR(150) NULL' },
      { name: 'status_dari', ddl: 'ADD COLUMN `status_dari` VARCHAR(50) NULL' },
      { name: 'status_ke', ddl: 'ADD COLUMN `status_ke` VARCHAR(50) NULL' },
      { name: 'created_at', ddl: 'ADD COLUMN `created_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP' },
    ];
    for (const col of mutasiColumns) {
      if (!(await columnExists(conn, 'galon_mutasi', col.name))) {
        await conn.query(`ALTER TABLE galon_mutasi ${col.ddl}`);
        console.log(`[DB] Migrasi: kolom galon_mutasi.${col.name} ditambahkan`);
      }
    }
    // Skema lama: galon_id wajib tanpa default — bulk pinjam/kembali tidak pakai satu id
    if (await columnExists(conn, 'galon_mutasi', 'galon_id')) {
      try {
        await conn.query(
          'ALTER TABLE galon_mutasi MODIFY COLUMN `galon_id` VARCHAR(100) NULL'
        );
        console.log('[DB] Migrasi: galon_mutasi.galon_id dibuat nullable');
      } catch (e) {
        console.warn('[DB] Tidak bisa mengubah galon_mutasi.galon_id:', e.message);
      }
    }
  }

  galonMutasiColumnCache = null;

  try {
    await conn.query('CREATE INDEX `idx_galon_status` ON `galon` (`status`)');
  } catch (_) { /* index mungkin sudah ada */ }
  try {
    await conn.query('CREATE INDEX `idx_galon_pelanggan` ON `galon` (`pelanggan_id`)');
  } catch (_) { /* index mungkin sudah ada */ }
}

/** Tabel cabang depo — dikelola manager utama. */
async function ensureCabangSchema(conn) {
  if (!(await tableExists(conn, 'cabang'))) {
    console.log('[DB] Tabel cabang belum ada, membuat...');
    await conn.query(`
      CREATE TABLE IF NOT EXISTS \`cabang\` (
        \`id\` VARCHAR(100) NOT NULL,
        \`nama\` VARCHAR(150) NOT NULL,
        \`alamat\` TEXT NULL,
        \`kota\` VARCHAR(100) NULL,
        \`no_hp\` VARCHAR(20) NULL,
        \`is_pusat\` TINYINT(1) NOT NULL DEFAULT 0,
        \`is_aktif\` TINYINT(1) NOT NULL DEFAULT 1,
        \`created_at\` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
        \`updated_at\` DATETIME NULL ON UPDATE CURRENT_TIMESTAMP,
        PRIMARY KEY (\`id\`)
      ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
    `);
  }

  const [countRows] = await conn.query('SELECT COUNT(*) AS c FROM cabang');
  if (Number(countRows[0].c) === 0) {
    console.log('[DB] Seeding cabang depo default...');
    const now = new Date().toISOString().slice(0, 19).replace('T', ' ');
    const branches = [
      {
        id: uuidv4(),
        nama: 'Depo Sitiarjo',
        alamat: 'Jl. Raya Sitiarjo No. 12, Lowokwaru',
        kota: 'Malang',
        noHp: '0341-123456',
        isPusat: 1,
      },
      {
        id: uuidv4(),
        nama: 'Depo Merjosari',
        alamat: 'Jl. Merjosari Indah No. 5, Merjosari',
        kota: 'Malang',
        noHp: '0341-234567',
        isPusat: 0,
      },
      {
        id: uuidv4(),
        nama: 'Depo Pasuruan',
        alamat: 'Jl. Panglima Sudirman No. 88, Panggungrejo',
        kota: 'Pasuruan',
        noHp: '0343-345678',
        isPusat: 0,
      },
    ];
    for (const b of branches) {
      await conn.query(
        `INSERT INTO cabang (id, nama, alamat, kota, no_hp, is_pusat, is_aktif, created_at)
         VALUES (?, ?, ?, ?, ?, ?, 1, ?)`,
        [b.id, b.nama, b.alamat, b.kota, b.noHp, b.isPusat, now]
      );
    }
    console.log('[DB] Seeding cabang selesai (3 cabang).');
  }
}

/** Kolom tipe pembelian & ongkir pada transaksi. */
async function ensureTransaksiSchema(conn) {
  if (!(await tableExists(conn, 'transaksi'))) return;

  const columns = [
    { name: 'tipe_pembelian', ddl: "ADD COLUMN `tipe_pembelian` VARCHAR(20) NOT NULL DEFAULT 'di_depo'" },
    { name: 'ongkir_per_galon', ddl: 'ADD COLUMN `ongkir_per_galon` INT NOT NULL DEFAULT 0' },
    { name: 'total_ongkir', ddl: 'ADD COLUMN `total_ongkir` DECIMAL(14,2) NOT NULL DEFAULT 0.00' },
    { name: 'pengirim_crew_id', ddl: 'ADD COLUMN `pengirim_crew_id` VARCHAR(100) NULL AFTER `crew_id`' },
  ];

  for (const col of columns) {
    if (!(await columnExists(conn, 'transaksi', col.name))) {
      await conn.query(`ALTER TABLE transaksi ${col.ddl}`);
      console.log(`[DB] Migrasi: transaksi.${col.name} ditambahkan`);
    }
  }
}

function sqlErrorMessage(err, fallback = 'Internal Server Error') {
  if (err && err.code === 'ER_BAD_FIELD_ERROR') {
    return `Kolom database tidak ditemukan (${err.sqlMessage || 'unknown column'}). Restart backend setelah migrasi.`;
  }
  if (err && err.code === 'ER_NO_SUCH_TABLE') {
    return `Tabel database tidak ditemukan (${err.sqlMessage || err.message}). Restart backend.`;
  }
  if (err && err.code === 'ER_NO_DEFAULT_FOR_FIELD') {
    return `Kolom database wajib diisi (${err.sqlMessage || err.message}). Restart backend agar migrasi galon jalan.`;
  }
  return err?.message || fallback;
}

let galonMutasiColumnCache = null;

async function getGalonMutasiColumns(conn) {
  if (galonMutasiColumnCache) return galonMutasiColumnCache;
  const [dbRow] = await conn.query('SELECT DATABASE() AS db');
  const db = dbRow[0]?.db;
  const [rows] = await conn.query(
    `SELECT COLUMN_NAME FROM information_schema.COLUMNS
     WHERE TABLE_SCHEMA = ? AND TABLE_NAME = 'galon_mutasi'`,
    [db]
  );
  galonMutasiColumnCache = new Set(rows.map((r) => r.COLUMN_NAME));
  return galonMutasiColumnCache;
}

/** INSERT galon_mutasi — menyesuaikan kolom yang ada di DB (termasuk galon_id legacy). */
async function insertGalonMutasiRow(conn, row) {
  const cols = await getGalonMutasiColumns(conn);
  const mapping = {
    id: row.id,
    galon_id: row.galonId ?? null,
    aksi: row.aksi,
    jumlah: row.jumlah,
    kode_galon: row.kodeGalon,
    pelanggan_id: row.pelangganId ?? null,
    catatan: row.catatan ?? null,
    crew_id: row.crewId ?? null,
    crew_nama: row.crewNama ?? null,
    status_dari: row.statusDari ?? null,
    status_ke: row.statusKe ?? null,
    created_at: row.createdAt,
  };
  const fields = [];
  const values = [];
  for (const [col, val] of Object.entries(mapping)) {
    if (!cols.has(col)) continue;
    if (val === undefined) continue;
    fields.push(col);
    values.push(val);
  }
  if (fields.length === 0) {
    throw new Error('Tabel galon_mutasi tidak memiliki kolom yang dikenali');
  }
  const sql = `INSERT INTO galon_mutasi (${fields.map((f) => `\`${f}\``).join(', ')})
               VALUES (${fields.map(() => '?').join(', ')})`;
  await conn.query(sql, values);
}

// Galon Summary calculations
async function getGalonSummary() {
  const [rows] = await pool.query(`
    SELECT 
      COUNT(*) as totalGalon,
      SUM(CASE WHEN status = 'tersedia' THEN 1 ELSE 0 END) as tersedia,
      SUM(CASE WHEN status = 'dipinjam' THEN 1 ELSE 0 END) as dipinjam,
      SUM(CASE WHEN status = 'rusak' THEN 1 ELSE 0 END) as rusak,
      SUM(CASE WHEN status = 'hilang' THEN 1 ELSE 0 END) as hilang
    FROM galon
  `);
  const s = rows[0];
  return {
    totalGalon: parseInt(s.totalGalon, 10) || 0,
    tersedia: parseInt(s.tersedia, 10) || 0,
    dipinjam: parseInt(s.dipinjam, 10) || 0,
    rusak: parseInt(s.rusak, 10) || 0,
    hilang: parseInt(s.hilang, 10) || 0
  };
}

// Apply mutations inside transaction (reusable dalam transaksi kasir)
async function applyGalonMutasiWithConnection(connection, aksi, jumlah, meta = {}) {
  const want = Math.max(0, parseInt(jumlah, 10) || 0);
  if (want === 0) return { jumlah: 0, kodeList: [], mutasiId: null };

  const fromStatus = aksi === 'pinjam' ? 'tersedia' : 'dipinjam';
  const toStatus = aksi === 'pinjam' ? 'dipinjam' : 'tersedia';

  if (aksi === 'pinjam' && meta.pelangganId) {
    const [pelangganRows] = await connection.query(
      'SELECT id FROM pelanggan WHERE id = ?',
      [meta.pelangganId]
    );
    if (pelangganRows.length === 0) {
      throw new Error('Pelanggan dengan ID ' + meta.pelangganId + ' tidak ditemukan');
    }
  }

  let query = 'SELECT id, kode_galon FROM galon WHERE status = ?';
  const params = [fromStatus];

  if (aksi === 'kembali' && meta.pelangganId) {
    query += ' AND pelanggan_id = ?';
    params.push(meta.pelangganId);
  }

  query += ' ORDER BY kode_galon LIMIT ? FOR UPDATE';
  params.push(want);

  const [galons] = await connection.query(query, params);
  const n = galons.length;
  const kodeList = [];
  const now = new Date().toISOString().slice(0, 19).replace('T', ' ');

  for (const g of galons) {
    // Tentukan tanggal_pinjam: gunakan dari meta jika ada, jika tidak gunakan now (untuk pinjam) atau null (untuk kembali)
    let tanggalPinjam;
    if (aksi === 'pinjam') {
      tanggalPinjam = meta.tanggal ? new Date(meta.tanggal).toISOString().slice(0, 19).replace('T', ' ') : now;
    } else {
      tanggalPinjam = null; // Reset saat kembali
    }
    
    await connection.query(
      'UPDATE galon SET status = ?, pelanggan_id = ?, tanggal_pinjam = ?, catatan = ?, updated_at = ? WHERE id = ?',
      [
        toStatus,
        aksi === 'pinjam' ? (meta.pelangganId || null) : null,
        tanggalPinjam,
        aksi === 'pinjam' ? (meta.catatan || null) : null,
        now,
        g.id,
      ]
    );
    kodeList.push(g.kode_galon);
  }

  let mutasiId = null;
  if (n > 0) {
    mutasiId = uuidv4();
    await insertGalonMutasiRow(connection, {
      id: mutasiId,
      galonId: galons[0]?.id || null,
      aksi,
      jumlah: n,
      kodeGalon: JSON.stringify(kodeList),
      pelangganId: meta.pelangganId || null,
      catatan: meta.catatan || null,
      crewId: meta.crewId || null,
      crewNama: meta.crewNama || null,
      createdAt: now,
    });
  }

  if (meta.pelangganId && n > 0) {
    if (aksi === 'pinjam') {
      await connection.query(
        'UPDATE pelanggan SET total_galon_pinjam = total_galon_pinjam + ? WHERE id = ?',
        [n, meta.pelangganId]
      );
    } else if (aksi === 'kembali') {
      await connection.query(
        'UPDATE pelanggan SET total_galon_pinjam = GREATEST(0, total_galon_pinjam - ?) WHERE id = ?',
        [n, meta.pelangganId]
      );
    }
  }

  return { jumlah: n, kodeList, mutasiId };
}

async function isProdukGalonBaru(connection, produkId, cache = {}) {
  if (cache[produkId] !== undefined) return cache[produkId];
  const [rows] = await connection.query(
    `SELECT p.nama AS produk_nama, k.nama AS kategori_nama
     FROM produk p
     LEFT JOIN kategori k ON p.kategori_id = k.id
     WHERE p.id = ?`,
    [produkId]
  );
  if (!rows.length) {
    cache[produkId] = false;
    return false;
  }
  const isBaru = isProdukGalonFisikFromNames(rows[0].kategori_nama, rows[0].produk_nama);
  cache[produkId] = isBaru;
  return isBaru;
}

/** Produk yang menjual unit galon fisik (bukan sekadar isi ulang air). */
function isProdukGalonFisikFromNames(kategoriNama, produkNama) {
  const kn = String(kategoriNama || '').toLowerCase().trim();
  const pn = String(produkNama || '').toLowerCase().trim();
  if (!kn && !pn) return false;

  if (kn.includes('galon baru') || pn.includes('galon baru')) return true;
  if (kn === 'galon' || kn.startsWith('galon ') || kn.includes('penjualan galon')) return true;
  if (pn.includes('galon kosong')) return true;
  if (pn === 'galon' || /^galon(\s|$)/.test(pn)) return true;

  return false;
}

/** Kurangi stok galon depo saat transaksi (galon baru / pinjam-kembali item). */
async function applyGalonFromTransaksiItems(connection, {
  items,
  pelangganId,
  crewId,
  crewNama,
  transaksiId,
}) {
  const cache = {};
  let galonBaruTerjual = 0;
  let galonKembali = 0;
  let galonPinjamManual = 0;

  for (const item of items) {
    if (await isProdukGalonBaru(connection, item.produkId, cache)) {
      galonBaruTerjual += item.jumlah;
    }
    galonKembali += parseInt(item.galonKembali, 10) || 0;
    galonPinjamManual += parseInt(item.galonPinjam, 10) || 0;
  }

  const pinjamTotal = galonBaruTerjual + galonPinjamManual;
  if (pinjamTotal === 0 && galonKembali === 0) return;

  const catatan = `Transaksi ${transaksiId}`;
  const metaBase = { catatan, crewId, crewNama };

  if (galonKembali > 0) {
    if (!pelangganId) {
      throw new Error('Pelanggan wajib dipilih untuk pencatatan galon kembali');
    }
    await applyGalonMutasiWithConnection(connection, 'kembali', galonKembali, {
      ...metaBase,
      pelangganId,
    });
  }

  if (pinjamTotal > 0) {
    if (!pelangganId) {
      throw new Error('Pelanggan wajib dipilih untuk penjualan galon baru');
    }
    const pinjam = await applyGalonMutasiWithConnection(connection, 'pinjam', pinjamTotal, {
      ...metaBase,
      pelangganId,
    });
    if (pinjam.jumlah < pinjamTotal) {
      throw new Error(
        `Stok galon di depo tidak mencukupi (tersedia: ${pinjam.jumlah}, dibutuhkan: ${pinjamTotal})`
      );
    }
  }
}

// Apply mutations inside transaction
async function applyGalonMutasi(aksi, jumlah, meta = {}) {
  console.log('[MUTASI] Starting:', { aksi, jumlah, meta });
  const connection = await pool.getConnection();
  await connection.beginTransaction();
  try {
    const result = await applyGalonMutasiWithConnection(connection, aksi, jumlah, meta);
    await connection.commit();
    console.log('[MUTASI] Committed successfully');
    const summary = await getGalonSummary();
    return {
      jumlah: result.jumlah,
      mutasi: result.mutasiId
        ? {
            id: result.mutasiId,
            aksi,
            jumlah: result.jumlah,
            kodeGalon: result.kodeList,
            pelangganId: meta.pelangganId || null,
            catatan: meta.catatan || null,
            crewId: meta.crewId || null,
            crewNama: meta.crewNama || null,
            createdAt: new Date().toISOString(),
          }
        : null,
      summary,
    };
  } catch (err) {
    console.error('[MUTASI ERROR]', err);
    await connection.rollback();
    throw err;
  } finally {
    connection.release();
  }
}

// Pagination helper
function paginate(list, page, limit, totalCount) {
  const p = Math.max(1, parseInt(page, 10) || 1);
  const l = Math.max(1, Math.min(100, parseInt(limit, 10) || 20));
  return {
    data: list,
    total: totalCount,
    page: p,
    limit: l,
    totalPages: Math.max(1, Math.ceil(totalCount / l)),
  };
}

// Auth Middleware
function authMiddleware(req, res, next) {
  const header = req.headers.authorization || '';
  const token = header.startsWith('Bearer ') ? header.slice(7) : null;
  if (!token) {
    return res.status(401).json({ message: 'Token tidak ditemukan' });
  }
  try {
    req.user = jwt.verify(token, JWT_SECRET);
    next();
  } catch {
    return res.status(401).json({ message: 'Token tidak valid' });
  }
}

function managerOnly(req, res, next) {
  if (req.user?.role !== 'manager') {
    return res.status(403).json({ message: 'Akses khusus manager' });
  }
  next();
}

// Token Issuing
function issueTokens(user) {
  const payload = { sub: user.id, role: user.role, username: user.username };
  const accessToken = jwt.sign(payload, JWT_SECRET, { expiresIn: '8h' });
  const refreshToken = jwt.sign({ ...payload, type: 'refresh' }, JWT_SECRET, { expiresIn: '7d' });
  return { accessToken, refreshToken };
}

// Models Formatting
function userDataFrom(user) {
  const data = {
    id: user.id,
    nama: user.nama,
    username: user.username,
    noHp: user.noHp || '',
    alamat: user.alamat || '',
    isAktif: user.isAktif !== false,
  };
  if (user.email) data.email = user.email;
  return data;
}

function crewResponseFrom(user) {
  return {
    id: user.id,
    nama: user.nama,
    username: user.username,
    noHp: user.noHp || '',
    alamat: user.alamat || '',
    isAktif: user.isAktif !== false,
    fotoUrl: user.fotoUrl || null,
    createdAt: user.createdAt,
    updatedAt: user.updatedAt || null,
  };
}


// ── AUTH ──────────────────────────────────────────────────────────────────────

function loginHandler(role) {
  return async (req, res) => {
    const { username, password, pin } = req.body || {};
    try {
      const u = (username || '').trim().toLowerCase();
      let rows = [];
      if (role === 'crew' && !u) {
        const [crewRows] = await pool.query(
          `SELECT * FROM users WHERE role = ? AND is_aktif = 1
           ORDER BY CASE WHEN username = 'crew001' THEN 0 ELSE 1 END, username ASC`,
          [role]
        );
        const secret = String(pin ?? password ?? '');
        rows = crewRows.filter((row) => bcrypt.compareSync(secret, row.pin_hash || row.password_hash));
      } else {
        const [matchedRows] = await pool.query(
          'SELECT * FROM users WHERE (LOWER(username) = ? OR LOWER(email) = ?) AND role = ? AND is_aktif = 1',
          [u, u, role]
        );
        rows = matchedRows;
      }
      
      if (rows.length === 0) {
        return res.status(401).json({ message: role === 'crew' ? 'PIN crew salah' : 'Username atau password salah' });
      }
      
      const user = snakeToCamel(rows[0]);
      if (!(role === 'crew' && !u)) {
        const secret = role === 'crew' ? String(pin ?? password ?? '') : String(password ?? '');
        const hash = role === 'crew' ? (rows[0].pin_hash || rows[0].password_hash) : rows[0].password_hash;
        if (!bcrypt.compareSync(secret, hash)) {
          return res.status(401).json({ message: role === 'crew' ? 'PIN crew salah' : 'Username atau password salah' });
        }
      }
      
      const { accessToken, refreshToken } = issueTokens(user);
      
      await pool.query(
        'INSERT INTO refresh_tokens (token, user_id) VALUES (?, ?)',
        [refreshToken, user.id]
      );
      
      res.json({
        access_token: accessToken,
        refresh_token: refreshToken,
        role: user.role,
        user_data: userDataFrom(user),
      });
    } catch (err) {
      console.error(err);
      res.status(500).json({ message: 'Internal Server Error' });
    }
  };
}

app.post('/v1/auth/login/crew', loginHandler('crew'));
app.post('/v1/auth/login/manager', loginHandler('manager'));

app.post('/v1/auth/logout', authMiddleware, async (req, res) => {
  const { refresh_token } = req.body || {};
  try {
    if (refresh_token) {
      await pool.query('DELETE FROM refresh_tokens WHERE token = ?', [refresh_token]);
    }
    res.json({ message: 'Logout berhasil' });
  } catch (err) {
    console.error(err);
    res.status(500).json({ message: 'Internal Server Error' });
  }
});

app.post('/v1/auth/refresh', async (req, res) => {
  const { refresh_token: refreshToken } = req.body || {};
  if (!refreshToken) {
    return res.status(400).json({ message: 'refresh_token wajib' });
  }
  try {
    const payload = jwt.verify(refreshToken, JWT_SECRET);
    if (payload.type !== 'refresh') throw new Error('invalid');
    
    const [tokenRows] = await pool.query('SELECT * FROM refresh_tokens WHERE token = ?', [refreshToken]);
    if (tokenRows.length === 0) {
      return res.status(401).json({ message: 'Refresh token tidak valid' });
    }
    
    const [userRows] = await pool.query('SELECT * FROM users WHERE id = ?', [payload.sub]);
    if (userRows.length === 0) {
      return res.status(401).json({ message: 'User tidak ditemukan' });
    }
    
    const user = snakeToCamel(userRows[0]);
    const tokens = issueTokens(user);
    
    await pool.query('DELETE FROM refresh_tokens WHERE token = ?', [refreshToken]);
    await pool.query('INSERT INTO refresh_tokens (token, user_id) VALUES (?, ?)', [tokens.refreshToken, user.id]);
    
    res.json({
      access_token: tokens.accessToken,
      refresh_token: tokens.refreshToken,
      role: user.role,
      user_data: userDataFrom(user),
    });
  } catch (err) {
    res.status(401).json({ message: 'Refresh token tidak valid' });
  }
});

// ── UBAH PASSWORD ─────────────────────────────────────────────────────────────
app.put('/v1/auth/change-password', authMiddleware, async (req, res) => {
  try {
    const { passwordLama, passwordBaru } = req.body || {};
    if (!passwordLama || !passwordBaru) {
      return res.status(400).json({ message: 'Password lama dan password baru wajib diisi' });
    }
    if (passwordBaru.length < 6) {
      return res.status(400).json({ message: 'Password baru minimal 6 karakter' });
    }

    const [rows] = await pool.query('SELECT * FROM users WHERE id = ?', [req.user.sub]);
    if (rows.length === 0) {
      return res.status(404).json({ message: 'User tidak ditemukan' });
    }

    const user = rows[0];
    const match = await bcrypt.compare(passwordLama, user.password_hash);
    if (!match) {
      return res.status(401).json({ message: 'Password lama tidak sesuai' });
    }

    const newHash = await bcrypt.hash(passwordBaru, 10);
    const now = new Date().toISOString().slice(0, 19).replace('T', ' ');
    await pool.query('UPDATE users SET password_hash = ?, updated_at = ? WHERE id = ?', [newHash, now, req.user.sub]);

    res.json({ message: 'Password berhasil diubah' });
  } catch (err) {
    console.error(err);
    res.status(500).json({ message: 'Internal Server Error' });
  }
});


// ── CREW ──────────────────────────────────────────────────────────────────────

app.get('/v1/crew', authMiddleware, async (req, res) => {
  try {
    const { search, page, limit } = req.query;
    const p = Math.max(1, parseInt(page, 10) || 1);
    const l = Math.max(1, Math.min(100, parseInt(limit, 10) || 20));
    const offset = (p - 1) * l;
    
    let query = 'SELECT * FROM users WHERE role = "crew"';
    let countQuery = 'SELECT COUNT(*) as total FROM users WHERE role = "crew"';
    const params = [];
    const countParams = [];
    
    if (search) {
      const s = `%${search}%`;
      query += ' AND (LOWER(nama) LIKE ? OR LOWER(username) LIKE ?)';
      countQuery += ' AND (LOWER(nama) LIKE ? OR LOWER(username) LIKE ?)';
      params.push(s, s);
      countParams.push(s, s);
    }
    
    query += ' ORDER BY created_at DESC LIMIT ? OFFSET ?';
    params.push(l, offset);
    
    const [rows] = await pool.query(query, params);
    const [countRows] = await pool.query(countQuery, countParams);
    
    const totalCount = countRows[0].total;
    const list = snakeToCamel(rows).map(crewResponseFrom);
    
    res.json(paginate(list, page, limit, totalCount));
  } catch (err) {
    console.error(err);
    res.status(500).json({ message: 'Internal Server Error' });
  }
});

app.get('/v1/crew/:id', authMiddleware, async (req, res) => {
  try {
    const [rows] = await pool.query('SELECT * FROM users WHERE id = ? AND role = "crew"', [req.params.id]);
    if (rows.length === 0) return res.status(404).json({ message: 'Crew tidak ditemukan' });
    res.json(crewResponseFrom(snakeToCamel(rows[0])));
  } catch (err) {
    console.error(err);
    res.status(500).json({ message: 'Internal Server Error' });
  }
});

app.post('/v1/crew', authMiddleware, async (req, res) => {
  try {
    const { username, nama, noHp, alamat, isAktif, password, pin } = req.body || {};
    const u = String(username || '').trim();
    const n = String(nama || u).trim();
    if (!u) return res.status(400).json({ message: 'Username wajib diisi' });
    if (!n) return res.status(400).json({ message: 'Nama wajib diisi' });
    
    const [dup] = await pool.query('SELECT id FROM users WHERE LOWER(username) = ?', [u.toLowerCase()]);
    if (dup.length > 0) return res.status(400).json({ message: 'Username sudah digunakan' });
    
    const id = uuidv4();
    const pinValue = String(pin || password || '1234');
    if (!/^\d{4,6}$/.test(pinValue)) return res.status(400).json({ message: 'PIN crew harus 4-6 digit' });
    const pwdHash = bcrypt.hashSync(pinValue, 10);
    const pinHash = bcrypt.hashSync(pinValue, 10);
    const now = new Date().toISOString().slice(0, 19).replace('T', ' ');
    
    await pool.query(
      `INSERT INTO users (id, role, username, password_hash, pin_hash, nama, no_hp, alamat, is_aktif, created_at)
       VALUES (?, 'crew', ?, ?, ?, ?, ?, ?, ?, ?)`,
      [id, u, pwdHash, pinHash, n, noHp || '', alamat || '', isAktif !== false ? 1 : 0, now]
    );
    
    const [inserted] = await pool.query('SELECT * FROM users WHERE id = ?', [id]);
    res.status(201).json(crewResponseFrom(snakeToCamel(inserted[0])));
  } catch (err) {
    console.error(err);
    res.status(500).json({ message: 'Internal Server Error' });
  }
});

app.put('/v1/crew/:id', authMiddleware, async (req, res) => {
  try {
    const [rows] = await pool.query('SELECT * FROM users WHERE id = ? AND role = "crew"', [req.params.id]);
    if (rows.length === 0) return res.status(404).json({ message: 'Crew tidak ditemukan' });
    
    const body = req.body || {};
    const now = new Date().toISOString().slice(0, 19).replace('T', ' ');
    
    if (body.resetPassword) {
      const pinValue = String(body.pin || body.password || '1234');
      if (!/^\d{4,6}$/.test(pinValue)) return res.status(400).json({ message: 'PIN crew harus 4-6 digit' });
      const pwdHash = bcrypt.hashSync(pinValue, 10);
      await pool.query('UPDATE users SET password_hash = ?, pin_hash = ?, updated_at = ? WHERE id = ?', [pwdHash, pwdHash, now, req.params.id]);
    } else {
      const currentUser = rows[0];
      const isAktifVal = body.isAktif !== undefined ? (body.isAktif ? 1 : 0) : currentUser.is_aktif;
      await pool.query(
        `UPDATE users SET nama = ?, username = ?, no_hp = ?, alamat = ?, is_aktif = ?, updated_at = ? WHERE id = ?`,
        [
          body.nama ?? currentUser.nama,
          body.username ?? currentUser.username,
          body.noHp ?? currentUser.no_hp,
          body.alamat ?? currentUser.alamat,
          isAktifVal,
          now,
          req.params.id
        ]
      );
    }
    
    const [updated] = await pool.query('SELECT * FROM users WHERE id = ?', [req.params.id]);
    res.json(crewResponseFrom(snakeToCamel(updated[0])));
  } catch (err) {
    console.error(err);
    res.status(500).json({ message: 'Internal Server Error' });
  }
});

app.delete('/v1/crew/:id', authMiddleware, async (req, res) => {
  try {
    const [rows] = await pool.query('SELECT id FROM users WHERE id = ? AND role = "crew"', [req.params.id]);
    if (rows.length === 0) return res.status(404).json({ message: 'Crew tidak ditemukan' });
    await pool.query('DELETE FROM users WHERE id = ?', [req.params.id]);
    res.status(204).send();
  } catch (err) {
    console.error(err);
    res.status(500).json({ message: 'Internal Server Error' });
  }
});


// ── PELANGGAN ─────────────────────────────────────────────────────────────────

app.get('/v1/pelanggan', authMiddleware, async (req, res) => {
  try {
    const { search, page, limit } = req.query;
    const p = Math.max(1, parseInt(page, 10) || 1);
    const l = Math.max(1, Math.min(100, parseInt(limit, 10) || 20));
    const offset = (p - 1) * l;
    
    let query = 'SELECT * FROM pelanggan WHERE 1=1';
    let countQuery = 'SELECT COUNT(*) as total FROM pelanggan WHERE 1=1';
    const params = [];
    const countParams = [];
    
    if (search) {
      const s = `%${search}%`;
      query += ' AND (LOWER(nama) LIKE ? OR no_hp LIKE ?)';
      countQuery += ' AND (LOWER(nama) LIKE ? OR no_hp LIKE ?)';
      params.push(s, s);
      countParams.push(s, s);
    }
    
    query += ' ORDER BY nama ASC LIMIT ? OFFSET ?';
    params.push(l, offset);
    
    const [rows] = await pool.query(query, params);
    const [countRows] = await pool.query(countQuery, countParams);
    
    const totalCount = countRows[0].total;
    res.json(paginate(snakeToCamel(rows), page, limit, totalCount));
  } catch (err) {
    console.error(err);
    res.status(500).json({ message: 'Internal Server Error' });
  }
});

app.get('/v1/pelanggan/:id', authMiddleware, async (req, res) => {
  try {
    const [rows] = await pool.query('SELECT * FROM pelanggan WHERE id = ?', [req.params.id]);
    if (rows.length === 0) return res.status(404).json({ message: 'Pelanggan tidak ditemukan' });
    res.json(snakeToCamel(rows[0]));
  } catch (err) {
    console.error(err);
    res.status(500).json({ message: 'Internal Server Error' });
  }
});

app.post('/v1/pelanggan', authMiddleware, async (req, res) => {
  try {
    const { nama, noHp, alamat, totalGalonPinjam, catatan, isAktif } = req.body || {};
    const n = String(nama || '').trim();
    if (!n) return res.status(400).json({ message: 'Nama pelanggan wajib diisi' });
    
    const id = uuidv4();
    const now = new Date().toISOString().slice(0, 19).replace('T', ' ');
    
    await pool.query(
      `INSERT INTO pelanggan (id, nama, no_hp, alamat, total_galon_pinjam, total_transaksi, catatan, is_aktif, created_at)
       VALUES (?, ?, ?, ?, ?, 0.00, ?, ?, ?)`,
      [
        id,
        n,
        noHp || '',
        alamat || null,
        parseInt(totalGalonPinjam, 10) || 0,
        catatan || null,
        isAktif !== false ? 1 : 0,
        now
      ]
    );
    
    const [inserted] = await pool.query('SELECT * FROM pelanggan WHERE id = ?', [id]);
    res.status(201).json(snakeToCamel(inserted[0]));
  } catch (err) {
    console.error(err);
    res.status(500).json({ message: 'Internal Server Error' });
  }
});

app.put('/v1/pelanggan/:id', authMiddleware, async (req, res) => {
  try {
    const [rows] = await pool.query('SELECT * FROM pelanggan WHERE id = ?', [req.params.id]);
    if (rows.length === 0) return res.status(404).json({ message: 'Pelanggan tidak ditemukan' });
    
    const body = req.body || {};
    const now = new Date().toISOString().slice(0, 19).replace('T', ' ');
    const current = rows[0];
    
    const isAktifVal = body.isAktif !== undefined ? (body.isAktif ? 1 : 0) : current.is_aktif;
    
    await pool.query(
      `UPDATE pelanggan SET nama = ?, no_hp = ?, alamat = ?, total_galon_pinjam = ?, catatan = ?, is_aktif = ?, updated_at = ? WHERE id = ?`,
      [
        body.nama ?? current.nama,
        body.noHp ?? current.no_hp,
        body.alamat ?? current.alamat,
        body.totalGalonPinjam !== undefined ? parseInt(body.totalGalonPinjam, 10) : current.total_galon_pinjam,
        body.catatan !== undefined ? body.catatan : current.catatan,
        isAktifVal,
        now,
        req.params.id
      ]
    );
    
    const [updated] = await pool.query('SELECT * FROM pelanggan WHERE id = ?', [req.params.id]);
    res.json(snakeToCamel(updated[0]));
  } catch (err) {
    console.error(err);
    res.status(500).json({ message: 'Internal Server Error' });
  }
});

app.delete('/v1/pelanggan/:id', authMiddleware, async (req, res) => {
  try {
    const [rows] = await pool.query('SELECT id FROM pelanggan WHERE id = ?', [req.params.id]);
    if (rows.length === 0) return res.status(404).json({ message: 'Pelanggan tidak ditemukan' });
    await pool.query('DELETE FROM pelanggan WHERE id = ?', [req.params.id]);
    res.status(204).send();
  } catch (err) {
    console.error(err);
    res.status(500).json({ message: 'Internal Server Error' });
  }
});


// ── PRODUK ────────────────────────────────────────────────────────────────────

async function enrichProdukSql(conn, produkRow) {
  const [katRows] = await conn.query('SELECT * FROM kategori WHERE id = ?', [produkRow.kategori_id]);
  const p = snakeToCamel(produkRow);
  p.kategori = katRows.length > 0 ? snakeToCamel(katRows[0]) : null;
  return p;
}

app.get('/v1/produk', authMiddleware, async (req, res) => {
  try {
    const { kategoriId, search, page, limit } = req.query;
    const p = Math.max(1, parseInt(page, 10) || 1);
    const l = Math.max(1, Math.min(100, parseInt(limit, 10) || 20));
    const offset = (p - 1) * l;
    
    let query = 'SELECT * FROM produk WHERE is_aktif = 1';
    let countQuery = 'SELECT COUNT(*) as total FROM produk WHERE is_aktif = 1';
    const params = [];
    const countParams = [];
    
    if (kategoriId) {
      query += ' AND kategori_id = ?';
      countQuery += ' AND kategori_id = ?';
      params.push(kategoriId);
      countParams.push(kategoriId);
    }
    
    if (search) {
      const s = `%${search}%`;
      query += ' AND LOWER(nama) LIKE ?';
      countQuery += ' AND LOWER(nama) LIKE ?';
      params.push(s);
      countParams.push(s);
    }
    
    query += ' ORDER BY nama ASC LIMIT ? OFFSET ?';
    params.push(l, offset);
    
    const [rows] = await pool.query(query, params);
    const [countRows] = await pool.query(countQuery, countParams);
    
    const totalCount = countRows[0].total;
    
    const enrichedList = [];
    for (const r of rows) {
      const enriched = await enrichProdukSql(pool, r);
      enrichedList.push(enriched);
    }
    
    res.json(paginate(enrichedList, page, limit, totalCount));
  } catch (err) {
    console.error(err);
    res.status(500).json({ message: 'Internal Server Error' });
  }
});

app.get('/v1/produk/:id', authMiddleware, async (req, res) => {
  try {
    const [rows] = await pool.query('SELECT * FROM produk WHERE id = ?', [req.params.id]);
    if (rows.length === 0) return res.status(404).json({ message: 'Produk tidak ditemukan' });
    const p = await enrichProdukSql(pool, rows[0]);
    res.json(p);
  } catch (err) {
    console.error(err);
    res.status(500).json({ message: 'Internal Server Error' });
  }
});

app.post('/v1/produk', authMiddleware, async (req, res) => {
  try {
    const { nama, kategoriId, harga, stok, deskripsi, gambarUrl, isAktif } = req.body || {};
    if (!nama || !String(nama).trim()) return res.status(400).json({ message: 'Nama produk wajib diisi' });
    
    let targetKategoriId = kategoriId;
    if (!targetKategoriId) {
      const [kats] = await pool.query('SELECT id FROM kategori WHERE is_aktif = 1 LIMIT 1');
      if (kats.length === 0) {
        return res.status(400).json({ message: 'Buat kategori produk terlebih dahulu' });
      }
      targetKategoriId = kats[0].id;
    }
    
    const id = uuidv4();
    const now = new Date().toISOString().slice(0, 19).replace('T', ' ');
    
    await pool.query(
      `INSERT INTO produk (id, nama, kategori_id, harga, stok, deskripsi, gambar_url, is_aktif, created_at)
       VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)`,
      [
        id,
        String(nama).trim(),
        targetKategoriId,
        parseFloat(harga) || 0.00,
        parseInt(stok, 10) || 0,
        deskripsi || null,
        gambarUrl || null,
        isAktif !== false ? 1 : 0,
        now
      ]
    );
    
    const [inserted] = await pool.query('SELECT * FROM produk WHERE id = ?', [id]);
    const enriched = await enrichProdukSql(pool, inserted[0]);
    res.status(201).json(enriched);
  } catch (err) {
    console.error(err);
    res.status(500).json({ message: 'Internal Server Error' });
  }
});

app.put('/v1/produk/:id', authMiddleware, async (req, res) => {
  try {
    const [rows] = await pool.query('SELECT * FROM produk WHERE id = ?', [req.params.id]);
    if (rows.length === 0) return res.status(404).json({ message: 'Produk tidak ditemukan' });
    
    const body = req.body || {};
    const current = rows[0];
    const now = new Date().toISOString().slice(0, 19).replace('T', ' ');
    
    const isAktifVal = body.isAktif !== undefined ? (body.isAktif ? 1 : 0) : current.is_aktif;
    
    await pool.query(
      `UPDATE produk SET nama = ?, kategori_id = ?, harga = ?, stok = ?, deskripsi = ?, gambar_url = ?, is_aktif = ?, updated_at = ? WHERE id = ?`,
      [
        body.nama ?? current.nama,
        body.kategoriId ?? current.kategori_id,
        body.harga !== undefined ? parseFloat(body.harga) : current.harga,
        body.stok !== undefined ? parseInt(body.stok, 10) : current.stok,
        body.deskripsi !== undefined ? body.deskripsi : current.deskripsi,
        body.gambarUrl !== undefined ? body.gambarUrl : current.gambar_url,
        isAktifVal,
        now,
        req.params.id
      ]
    );
    
    const [updated] = await pool.query('SELECT * FROM produk WHERE id = ?', [req.params.id]);
    const enriched = await enrichProdukSql(pool, updated[0]);
    res.json(enriched);
  } catch (err) {
    console.error(err);
    res.status(500).json({ message: 'Internal Server Error' });
  }
});

app.delete('/v1/produk/:id', authMiddleware, async (req, res) => {
  try {
    const [rows] = await pool.query('SELECT id FROM produk WHERE id = ?', [req.params.id]);
    if (rows.length === 0) return res.status(404).json({ message: 'Produk tidak ditemukan' });
    
    await pool.query('UPDATE produk SET is_aktif = 0 WHERE id = ?', [req.params.id]);
    res.status(204).send();
  } catch (err) {
    console.error(err);
    res.status(500).json({ message: 'Internal Server Error' });
  }
});


// ── KATEGORI ──────────────────────────────────────────────────────────────────

app.get('/v1/kategori', authMiddleware, async (req, res) => {
  try {
    const [rows] = await pool.query('SELECT * FROM kategori WHERE is_aktif = 1 ORDER BY nama ASC');
    res.json(snakeToCamel(rows));
  } catch (err) {
    console.error(err);
    res.status(500).json({ message: 'Internal Server Error' });
  }
});

app.post('/v1/kategori', authMiddleware, async (req, res) => {
  try {
    const { nama, deskripsi, tipe, ikon, isSystem } = req.body || {};
    if (!nama || !String(nama).trim()) return res.status(400).json({ message: 'Nama kategori wajib diisi' });
    
    const id = uuidv4();
    const now = new Date().toISOString().slice(0, 19).replace('T', ' ');
    
    await pool.query(
      `INSERT INTO kategori (id, nama, deskripsi, tipe, ikon, is_system, is_aktif, created_at)
       VALUES (?, ?, ?, ?, ?, ?, 1, ?)`,
      [
        id,
        String(nama).trim(),
        deskripsi || null,
        tipe === 'pengeluaran' ? 'pengeluaran' : 'pemasukan',
        ikon || null,
        isSystem === true ? 1 : 0,
        now
      ]
    );
    
    const [inserted] = await pool.query('SELECT * FROM kategori WHERE id = ?', [id]);
    res.status(201).json(snakeToCamel(inserted[0]));
  } catch (err) {
    console.error(err);
    res.status(500).json({ message: 'Internal Server Error' });
  }
});

app.put('/v1/kategori/:id', authMiddleware, async (req, res) => {
  try {
    const [rows] = await pool.query('SELECT * FROM kategori WHERE id = ?', [req.params.id]);
    if (rows.length === 0) return res.status(404).json({ message: 'Kategori tidak ditemukan' });
    
    const body = req.body || {};
    const current = rows[0];
    const isSystemVal = body.isSystem !== undefined ? (body.isSystem ? 1 : 0) : current.is_system;
    
    await pool.query(
      `UPDATE kategori SET nama = ?, deskripsi = ?, tipe = ?, ikon = ?, is_system = ? WHERE id = ?`,
      [
        body.nama ?? current.nama,
        body.deskripsi !== undefined ? body.deskripsi : current.deskripsi,
        body.tipe ?? current.tipe,
        body.ikon !== undefined ? body.ikon : current.ikon,
        isSystemVal,
        req.params.id
      ]
    );
    
    const [updated] = await pool.query('SELECT * FROM kategori WHERE id = ?', [req.params.id]);
    res.json(snakeToCamel(updated[0]));
  } catch (err) {
    console.error(err);
    res.status(500).json({ message: 'Internal Server Error' });
  }
});

app.delete('/v1/kategori/:id', authMiddleware, async (req, res) => {
  try {
    const [rows] = await pool.query('SELECT * FROM kategori WHERE id = ?', [req.params.id]);
    if (rows.length === 0) return res.status(404).json({ message: 'Kategori tidak ditemukan' });
    if (rows[0].is_system === 1) {
      return res.status(403).json({ message: 'Kategori sistem tidak dapat dihapus' });
    }
    await pool.query('UPDATE kategori SET is_aktif = 0 WHERE id = ?', [req.params.id]);
    res.status(204).send();
  } catch (err) {
    console.error(err);
    res.status(500).json({ message: 'Internal Server Error' });
  }
});


// ── PENGELUARAN ──────────────────────────────────────────────────────────────

app.get('/v1/pengeluaran', authMiddleware, async (req, res) => {
  try {
    const [rows] = await pool.query(`
      SELECT p.*, k.nama as kategori_nama 
      FROM pengeluaran p
      JOIN kategori k ON k.id = p.kategori_id
      ORDER BY p.tanggal DESC, p.created_at DESC
    `);
    res.json(snakeToCamel(rows));
  } catch (err) {
    console.error(err);
    res.status(500).json({ message: 'Internal Server Error' });
  }
});

app.post('/v1/pengeluaran', authMiddleware, async (req, res) => {
  try {
    const { kategoriId, nominal, keterangan, tanggal } = req.body || {};
    if (!kategoriId) return res.status(400).json({ message: 'kategoriId wajib diisi' });
    if (!nominal || isNaN(Number(nominal)) || Number(nominal) <= 0) {
      return res.status(400).json({ message: 'nominal harus lebih dari 0' });
    }
    
    const [katRows] = await pool.query('SELECT * FROM kategori WHERE id = ?', [kategoriId]);
    if (katRows.length === 0) return res.status(404).json({ message: 'Kategori tidak ditemukan' });
    
    const id = uuidv4();
    const now = new Date().toISOString().slice(0, 19).replace('T', ' ');
    const tgl = tanggal || now.slice(0, 10);
    
    await pool.query(
      `INSERT INTO pengeluaran (id, kategori_id, nominal, keterangan, tanggal, created_at)
       VALUES (?, ?, ?, ?, ?, ?)`,
      [id, kategoriId, parseFloat(nominal), keterangan || '', tgl, now]
    );
    
    const [inserted] = await pool.query(`
      SELECT p.*, k.nama as kategori_nama 
      FROM pengeluaran p
      JOIN kategori k ON k.id = p.kategori_id
      WHERE p.id = ?
    `, [id]);
    
    res.status(201).json(snakeToCamel(inserted[0]));
  } catch (err) {
    console.error(err);
    res.status(500).json({ message: 'Internal Server Error' });
  }
});

app.delete('/v1/pengeluaran/:id', authMiddleware, async (req, res) => {
  try {
    const [rows] = await pool.query('SELECT id FROM pengeluaran WHERE id = ?', [req.params.id]);
    if (rows.length === 0) return res.status(404).json({ message: 'Catatan pengeluaran tidak ditemukan' });
    
    await pool.query('DELETE FROM pengeluaran WHERE id = ?', [req.params.id]);
    res.json({ message: 'Catatan pengeluaran berhasil dihapus' });
  } catch (err) {
    console.error(err);
    res.status(500).json({ message: 'Internal Server Error' });
  }
});


// ── GALON ─────────────────────────────────────────────────────────────────────

app.get('/v1/galon/ringkasan', authMiddleware, async (req, res) => {
  try {
    const summary = await getGalonSummary();
    res.json(summary);
  } catch (err) {
    console.error(err);
    res.status(500).json({ message: sqlErrorMessage(err) });
  }
});

app.get('/v1/galon/mutasi', authMiddleware, async (req, res) => {
  try {
    const limit = Math.min(100, parseInt(req.query.limit, 10) || 30);
    const [rows] = await pool.query('SELECT * FROM galon_mutasi ORDER BY created_at DESC LIMIT ?', [limit]);
    
    const mapped = rows.map((r) => {
      const item = snakeToCamel(r);
      try {
        item.kodeGalon = JSON.parse(r.kode_galon);
      } catch (e) {
        item.kodeGalon = [];
      }
      return item;
    });
    
    res.json(mapped);
  } catch (err) {
    console.error(err);
    res.status(500).json({ message: sqlErrorMessage(err) });
  }
});

app.put('/v1/galon/pinjam', authMiddleware, async (req, res) => {
  try {
    const body = req.body || {};
    console.log('[PINJAM] Request body:', body);
    
    const result = await applyGalonMutasi('pinjam', body.jumlah, {
      pelangganId: body.pelangganId,
      catatan: body.catatan,
      crewId: req.user.sub,
      crewNama: req.user.username,
      tanggal: body.tanggal || null, // Gunakan tanggal dari frontend jika ada
    });
    if (result.jumlah === 0) {
      return res.status(400).json({ message: 'Tidak ada galon tersedia untuk dipinjam' });
    }
    res.json(result);
  } catch (err) {
    console.error('[PINJAM ERROR]', err);
    res.status(500).json({ message: sqlErrorMessage(err) });
  }
});

app.put('/v1/galon/kembali', authMiddleware, async (req, res) => {
  try {
    const body = req.body || {};
    console.log('[KEMBALI] Request body:', body);
    
    const result = await applyGalonMutasi('kembali', body.jumlah, {
      pelangganId: body.pelangganId,
      catatan: body.catatan,
      crewId: req.user.sub,
      crewNama: req.user.username,
      tanggal: body.tanggal || null, // Gunakan tanggal dari frontend jika ada
    });
    if (result.jumlah === 0) {
      return res.status(400).json({ message: 'Tidak ada galon dipinjam untuk dikembalikan' });
    }
    res.json(result);
  } catch (err) {
    console.error('[KEMBALI ERROR]', err);
    res.status(500).json({ message: sqlErrorMessage(err) });
  }
});

app.get('/v1/galon', authMiddleware, async (req, res) => {
  try {
    const { status, page, limit } = req.query;
    const p = Math.max(1, parseInt(page, 10) || 1);
    const l = Math.max(1, Math.min(100, parseInt(limit, 10) || 20));
    const offset = (p - 1) * l;
    
    let query = `SELECT g.*, p.nama as pelanggan_nama, p.no_hp as pelanggan_no_hp, p.alamat as pelanggan_alamat 
                 FROM galon g 
                 LEFT JOIN pelanggan p ON g.pelanggan_id = p.id`;
    let countQuery = 'SELECT COUNT(*) as total FROM galon';
    const params = [];
    const countParams = [];
    
    if (status) {
      query += ' WHERE g.status = ?';
      countQuery += ' WHERE status = ?';
      params.push(status);
      countParams.push(status);
    }
    
    query += ' ORDER BY g.kode_galon ASC LIMIT ? OFFSET ?';
    params.push(l, offset);
    
    const [rows] = await pool.query(query, params);
    const [countRows] = await pool.query(countQuery, countParams);
    
    const totalCount = countRows[0].total;
    res.json(paginate(snakeToCamel(rows), page, limit, totalCount));
  } catch (err) {
    console.error(err);
    res.status(500).json({ message: sqlErrorMessage(err) });
  }
});

app.post('/v1/galon', authMiddleware, async (req, res) => {
  try {
    const { kodeGalon, merek, jenis, status, pelangganId, catatan, jumlah } = req.body || {};
    const now = new Date().toISOString().slice(0, 19).replace('T', ' ');
    
    console.log('[GALON POST] Request body:', req.body);
    console.log('[GALON POST] Jumlah received:', jumlah, 'type:', typeof jumlah);
    
    // Jika jumlah > 1, buat multiple galon dengan kode auto-generate
    const count = Math.max(1, parseInt(jumlah) || 1);
    console.log('[GALON POST] Will create', count, 'galon(s)');
    
    const createdGalons = [];
    
    // Set tanggal_pinjam jika status dipinjam
    const tanggalPinjam = status === 'dipinjam' ? now : null;
    
    for (let i = 0; i < count; i++) {
      const id = uuidv4();
      // Auto-generate kode galon dengan format: G-TIMESTAMP-INDEX
      const code = `G-${Date.now()}-${i + 1}`;
      
      // Selalu gunakan 'Depo' sebagai merek, abaikan input user
      await pool.query(
        `INSERT INTO galon (id, kode_galon, merek, jenis, status, pelanggan_id, tanggal_pinjam, catatan, created_at)
         VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)`,
        [id, code, 'Depo', jenis || 'isi', status || 'tersedia', pelangganId || null, tanggalPinjam, catatan || null, now]
      );
      
      const [inserted] = await pool.query('SELECT * FROM galon WHERE id = ?', [id]);
      createdGalons.push(snakeToCamel(inserted[0]));
      
      console.log(`[GALON POST] Created galon ${i + 1}/${count}: ${code}`);
    }
    
    console.log('[GALON POST] Total created:', createdGalons.length);
    
    // Return galon pertama untuk backward compatibility
    res.status(201).json({
      ...createdGalons[0],
      createdCount: count,
      galons: count > 1 ? createdGalons : undefined
    });
  } catch (err) {
    console.error('[GALON POST ERROR]', err);
    res.status(500).json({ message: sqlErrorMessage(err) });
  }
});

app.put('/v1/galon/:id', authMiddleware, async (req, res) => {
  try {
    if (req.params.id === 'pinjam' || req.params.id === 'kembali') {
      return res.status(400).json({ message: 'Gunakan /galon/pinjam atau /galon/kembali' });
    }
    const [rows] = await pool.query('SELECT * FROM galon WHERE id = ?', [req.params.id]);
    if (rows.length === 0) return res.status(404).json({ message: 'Galon tidak ditemukan' });
    
    const body = req.body || {};
    const current = rows[0];
    const prevStatus = current.status;
    const now = new Date().toISOString().slice(0, 19).replace('T', ' ');
    
    // Update tanggal_pinjam based on status change
    let tanggalPinjam = current.tanggal_pinjam;
    if (body.status === 'dipinjam' && prevStatus !== 'dipinjam') {
      tanggalPinjam = now; // Set borrow date when status changes to dipinjam
    } else if (body.status && body.status !== 'dipinjam') {
      tanggalPinjam = null; // Clear borrow date when status changes from dipinjam
    }
    
    await pool.query(
      `UPDATE galon SET kode_galon = ?, merek = ?, jenis = ?, status = ?, pelanggan_id = ?, tanggal_pinjam = ?, catatan = ?, updated_at = ? WHERE id = ?`,
      [
        body.kodeGalon ?? current.kode_galon,
        body.merek ?? current.merek,
        body.jenis ?? current.jenis,
        body.status ?? current.status,
        body.pelangganId !== undefined ? body.pelangganId : current.pelanggan_id,
        tanggalPinjam,
        body.catatan !== undefined ? body.catatan : current.catatan,
        now,
        req.params.id
      ]
    );
    
    if (body.status && body.status !== prevStatus) {
      await insertGalonMutasiRow(pool, {
        id: uuidv4(),
        galonId: req.params.id,
        aksi: 'ubah_status',
        jumlah: 1,
        kodeGalon: JSON.stringify([body.kodeGalon ?? current.kode_galon]),
        statusDari: prevStatus,
        statusKe: body.status,
        crewId: req.user.sub,
        crewNama: req.user.username,
        createdAt: now,
      });
    }
    
    const [updated] = await pool.query('SELECT * FROM galon WHERE id = ?', [req.params.id]);
    res.json(snakeToCamel(updated[0]));
  } catch (err) {
    console.error(err);
    res.status(500).json({ message: sqlErrorMessage(err) });
  }
});


// ── TRANSAKSI ─────────────────────────────────────────────────────────────────

async function enrichTransaksiSql(conn, tRow) {
  const [pelRows] = await conn.query('SELECT * FROM pelanggan WHERE id = ?', [tRow.pelanggan_id]);
  const [crewRows] = await conn.query('SELECT id, nama, username, no_hp, alamat, is_aktif, created_at FROM users WHERE id = ?', [tRow.crew_id]);
  
  const [itemRows] = await conn.query(`
    SELECT ti.*, p.nama as produk_nama, p.kategori_id as produk_kategori_id
    FROM transaksi_items ti
    JOIN produk p ON p.id = ti.produk_id
    WHERE ti.transaksi_id = ?
  `, [tRow.id]);
  
  const items = [];
  for (const itemRow of itemRows) {
    const item = snakeToCamel(itemRow);
    const [pRows] = await conn.query('SELECT * FROM produk WHERE id = ?', [itemRow.produk_id]);
    if (pRows.length > 0) {
      const prod = await enrichProdukSql(conn, pRows[0]);
      item.produk = prod;
    } else {
      item.produk = null;
    }
    items.push(item);
  }
  
  const t = snakeToCamel(tRow);
  t.pelanggan = pelRows.length > 0 ? snakeToCamel(pelRows[0]) : null;
  t.crew = crewRows.length > 0 ? snakeToCamel(crewRows[0]) : null;
  t.items = items;
  return t;
}

app.get('/v1/transaksi', authMiddleware, async (req, res) => {
  try {
    const { status, crewId, tanggalMulai, tanggalAkhir, page, limit } = req.query;
    const p = Math.max(1, parseInt(page, 10) || 1);
    const l = Math.max(1, Math.min(100, parseInt(limit, 10) || 20));
    const offset = (p - 1) * l;
    
    let query = 'SELECT * FROM transaksi WHERE 1=1';
    let countQuery = 'SELECT COUNT(*) as total FROM transaksi WHERE 1=1';
    const params = [];
    const countParams = [];
    
    if (status) {
      const statuses = String(status).split(',');
      const placeholders = statuses.map(() => '?').join(',');
      query += ` AND status IN (${placeholders})`;
      countQuery += ` AND status IN (${placeholders})`;
      params.push(...statuses);
      countParams.push(...statuses);
    }
    
    if (crewId) {
      query += ' AND crew_id = ?';
      countQuery += ' AND crew_id = ?';
      params.push(crewId);
      countParams.push(crewId);
    }
    
    if (tanggalMulai) {
      query += ' AND created_at >= ?';
      countQuery += ' AND created_at >= ?';
      params.push(tanggalMulai);
      countParams.push(tanggalMulai);
    }
    
    if (tanggalAkhir) {
      query += ' AND created_at <= ?';
      countQuery += ' AND created_at <= ?';
      params.push(`${tanggalAkhir}T23:59:59.999Z`);
      countParams.push(`${tanggalAkhir}T23:59:59.999Z`);
    }
    
    query += ' ORDER BY created_at DESC LIMIT ? OFFSET ?';
    params.push(l, offset);
    
    const [rows] = await pool.query(query, params);
    const [countRows] = await pool.query(countQuery, countParams);
    const totalCount = countRows[0].total;
    
    const enrichedList = [];
    for (const r of rows) {
      const enriched = await enrichTransaksiSql(pool, r);
      enrichedList.push(enriched);
    }
    
    res.json(paginate(enrichedList, page, limit, totalCount));
  } catch (err) {
    console.error(err);
    res.status(500).json({ message: 'Internal Server Error' });
  }
});

app.get('/v1/transaksi/:id', authMiddleware, async (req, res) => {
  try {
    const [rows] = await pool.query('SELECT * FROM transaksi WHERE id = ?', [req.params.id]);
    if (rows.length === 0) return res.status(404).json({ message: 'Transaksi tidak ditemukan' });
    const t = await enrichTransaksiSql(pool, rows[0]);
    res.json(t);
  } catch (err) {
    console.error(err);
    res.status(500).json({ message: 'Internal Server Error' });
  }
});

app.post('/v1/transaksi', authMiddleware, async (req, res) => {
  const connection = await pool.getConnection();
  await connection.beginTransaction();
  try {
    const body = req.body || {};
    const crewId = body.crewId || req.user.sub;
    const itemsIn = body.items || [];
    const metode = body.metodePembayaran || 'tunai';
    const isQris = metode === 'qris';
    const now = new Date().toISOString().slice(0, 19).replace('T', ' ');
    const trxId = uuidv4();
    
    const items = [];
    let totalHarga = 0;
    
    for (const itemIn of itemsIn) {
      const [prodRows] = await connection.query('SELECT * FROM produk WHERE id = ?', [itemIn.produkId]);
      const product = prodRows[0];
      const hargaSatuan = product ? parseFloat(product.harga) : 0;
      const jumlah = parseInt(itemIn.jumlah, 10) || 0;
      const subtotal = hargaSatuan * jumlah;
      totalHarga += subtotal;
      
      items.push({
        id: uuidv4(),
        transaksiId: trxId,
        produkId: itemIn.produkId,
        jumlah,
        hargaSatuan,
        subtotal,
        galonPinjam: itemIn.galonPinjam || 0,
        galonKembali: itemIn.galonKembali || 0
      });
    }

    const tipePembelian = body.tipePembelian === 'dikirim' ? 'dikirim' : 'di_depo';
    const pengirimCrewId = tipePembelian === 'dikirim' ? (body.pengirimCrewId || body.crewPengirimId || null) : null;
    if (tipePembelian === 'dikirim' && !pengirimCrewId) {
      return res.status(400).json({ message: 'Crew pengirim wajib dipilih untuk transaksi dikirim' });
    }
    if (pengirimCrewId) {
      const [pengirimRows] = await connection.query('SELECT id FROM users WHERE id = ? AND role = "crew" AND is_aktif = 1', [pengirimCrewId]);
      if (pengirimRows.length === 0) {
        return res.status(400).json({ message: 'Crew pengirim tidak valid' });
      }
    }
    const jumlahGalon = items.reduce((s, i) => s + i.jumlah, 0);
    let ongkirPerGalon = 0;
    let totalOngkir = 0;
    if (tipePembelian === 'dikirim') {
      const rate = parseInt(body.ongkirPerGalon, 10);
      ongkirPerGalon = rate === 2000 ? 2000 : 1000;
      totalOngkir = ongkirPerGalon * jumlahGalon;
      totalHarga += totalOngkir;
    }
    
    const qrPaymentId = isQris ? `QR-${uuidv4()}` : null;
    
    await connection.query(
      `INSERT INTO transaksi (id, nomor_transaksi, pelanggan_id, crew_id, pengirim_crew_id, total_harga, metode_pembayaran, status, status_validasi, bayar, kembalian, qr_payment_id, catatan, tipe_pembelian, ongkir_per_galon, total_ongkir, validasi_oleh, validasi_at, created_at)
       VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, NULL, NULL, ?)`,
      [
        trxId,
        String(Date.now()),
        body.pelangganId || null,
        crewId,
        pengirimCrewId,
        totalHarga,
        metode,
        isQris ? 'menungguValidasi' : 'selesai',
        isQris ? 'belumDivalidasi' : 'valid',
        body.bayar !== undefined ? parseFloat(body.bayar) : null,
        body.kembalian !== undefined ? parseFloat(body.kembalian) : null,
        qrPaymentId,
        body.catatan || null,
        tipePembelian,
        ongkirPerGalon,
        totalOngkir,
        now
      ]
    );
    
    for (const item of items) {
      await connection.query(
        `INSERT INTO transaksi_items (id, transaksi_id, produk_id, jumlah, harga_satuan, subtotal, galon_pinjam, galon_kembali)
         VALUES (?, ?, ?, ?, ?, ?, ?, ?)`,
        [item.id, item.transaksiId, item.produkId, item.jumlah, item.hargaSatuan, item.subtotal, item.galonPinjam, item.galonKembali]
      );
    }
    
    if (body.pelangganId && !isQris) {
      await connection.query(
        'UPDATE pelanggan SET total_transaksi = total_transaksi + ? WHERE id = ?',
        [totalHarga, body.pelangganId]
      );
    }

    // Galon baru / pinjam-kembali: kurangi stok depo saat transaksi selesai (tunai)
    if (!isQris) {
      await applyGalonFromTransaksiItems(connection, {
        items,
        pelangganId: body.pelangganId || null,
        crewId,
        crewNama: req.user.username || req.user.sub,
        transaksiId: trxId,
      });
    }
    
    await connection.commit();
    
    const [inserted] = await pool.query('SELECT * FROM transaksi WHERE id = ?', [trxId]);
    const enriched = await enrichTransaksiSql(pool, inserted[0]);
    res.status(201).json(enriched);
  } catch (err) {
    await connection.rollback();
    console.error(err);
    res.status(500).json({ message: sqlErrorMessage(err) });
  } finally {
    connection.release();
  }
});

app.put('/v1/transaksi/:id/status', authMiddleware, async (req, res) => {
  try {
    const [rows] = await pool.query('SELECT id FROM transaksi WHERE id = ?', [req.params.id]);
    if (rows.length === 0) return res.status(404).json({ message: 'Transaksi tidak ditemukan' });
    
    const now = new Date().toISOString().slice(0, 19).replace('T', ' ');
    await pool.query('UPDATE transaksi SET status = ?, updated_at = ? WHERE id = ?', [req.body.status, now, req.params.id]);
    
    const [updated] = await pool.query('SELECT * FROM transaksi WHERE id = ?', [req.params.id]);
    const enriched = await enrichTransaksiSql(pool, updated[0]);
    res.json(enriched);
  } catch (err) {
    console.error(err);
    res.status(500).json({ message: 'Internal Server Error' });
  }
});

app.put('/v1/transaksi/:id/validasi', authMiddleware, async (req, res) => {
  const connection = await pool.getConnection();
  await connection.beginTransaction();
  try {
    const [rows] = await connection.query('SELECT * FROM transaksi WHERE id = ?', [req.params.id]);
    if (rows.length === 0) return res.status(404).json({ message: 'Transaksi tidak ditemukan' });
    
    const t = rows[0];
    const { status } = req.body || {};
    let statusText = t.status;
    let statusValidasiText = t.status_validasi;
    
    if (status === 'sukses') {
      statusText = 'selesai';
      statusValidasiText = 'valid';
      if (t.pelanggan_id) {
        await connection.query(
          'UPDATE pelanggan SET total_transaksi = total_transaksi + ? WHERE id = ?',
          [parseFloat(t.total_harga), t.pelanggan_id]
        );
      }
      const [itemRows] = await connection.query(
        'SELECT produk_id, jumlah, galon_pinjam, galon_kembali FROM transaksi_items WHERE transaksi_id = ?',
        [req.params.id]
      );
      const txItems = itemRows.map((r) => ({
        produkId: r.produk_id,
        jumlah: r.jumlah,
        galonPinjam: r.galon_pinjam,
        galonKembali: r.galon_kembali,
      }));
      await applyGalonFromTransaksiItems(connection, {
        items: txItems,
        pelangganId: t.pelanggan_id,
        crewId: t.crew_id,
        crewNama: req.user.username || req.user.sub,
        transaksiId: t.id,
      });
    } else if (status === 'gagal') {
      statusText = 'dibatalkan';
      statusValidasiText = 'invalid';
    }
    
    const now = new Date().toISOString().slice(0, 19).replace('T', ' ');
    await connection.query(
      `UPDATE transaksi 
       SET status = ?, status_validasi = ?, validasi_oleh = ?, validasi_at = ?, updated_at = ? 
       WHERE id = ?`,
      [statusText, statusValidasiText, req.user.sub, now, now, req.params.id]
    );
    
    await connection.commit();
    
    const [updated] = await pool.query('SELECT * FROM transaksi WHERE id = ?', [req.params.id]);
    const enriched = await enrichTransaksiSql(pool, updated[0]);
    res.json(enriched);
  } catch (err) {
    await connection.rollback();
    console.error(err);
    res.status(500).json({ message: sqlErrorMessage(err) });
  } finally {
    connection.release();
  }
});


// ── PEMBAYARAN QRIS (online — simulasi gateway) ───────────────────────────────

app.post('/v1/pembayaran/qris', authMiddleware, async (req, res) => {
  try {
    const { transaksiId } = req.body || {};
    const [trxRows] = await pool.query('SELECT * FROM transaksi WHERE id = ?', [transaksiId]);
    if (trxRows.length === 0) return res.status(404).json({ message: 'Transaksi tidak ditemukan' });

    const t = trxRows[0];
    if (t.metode_pembayaran !== 'qris') {
      return res.status(400).json({ message: 'Transaksi bukan metode QRIS' });
    }

    // Cek apakah sudah ada pembayaran pending yang masih valid
    const [existing] = await pool.query(
      'SELECT * FROM qr_payments WHERE transaksi_id = ? AND status = "pending"',
      [transaksiId]
    );

    const now = new Date();
    if (existing.length > 0) {
      const exp = new Date(existing[0].expires_at);
      if (now > exp) {
        await pool.query(
          'UPDATE qr_payments SET status = "expired", updated_at = ? WHERE payment_id = ?',
          [now.toISOString().slice(0, 19).replace('T', ' '), existing[0].payment_id]
        );
      } else {
        return res.json({
          paymentId: existing[0].payment_id,
          transaksiId: existing[0].transaksi_id,
          qrContent: existing[0].qr_content,
          jumlah: parseFloat(existing[0].jumlah),
          status: existing[0].status,
          expiresAt: existing[0].expires_at,
          namaDepot: existing[0].nama_depot || 'Depo Air Minum'
        });
      }
    }

    // Buat Order ID unik untuk Midtrans
    const orderId = `DEPO-${transaksiId.slice(0, 8).toUpperCase()}-${Date.now()}`;
    const grossAmount = Math.round(parseFloat(t.total_harga));

    let qrString = null;
    let paymentProvider = 'midtrans';

    if (MIDTRANS_SERVER_KEY) {
      const midtransPayload = {
        payment_type: 'qris',
        transaction_details: {
          order_id: orderId,
          gross_amount: grossAmount
        },
        qris: { acquirer: 'gopay' }
      };

      try {
        console.log('[MIDTRANS] Charging QRIS:', { orderId, grossAmount });

        const midtransRes = await fetch(`${MIDTRANS_BASE_URL}/v2/charge`, {
          method: 'POST',
          headers: {
            'Accept': 'application/json',
            'Content-Type': 'application/json',
            'Authorization': midtransAuthHeader()
          },
          body: JSON.stringify(midtransPayload)
        });

        const midtransData = await midtransRes.json();
        console.log('[MIDTRANS] Response:', midtransData);

        if (midtransRes.ok && (midtransData.status_code === '201' || midtransData.status_code === '200')) {
          qrString = midtransData.qr_string || null;
        } else {
          const errMsg = midtransData.status_message || midtransData.error_messages?.join(', ') || 'Gagal charge ke Midtrans';
          console.warn('[MIDTRANS] Fallback ke QRIS simulasi:', errMsg);
        }
      } catch (midtransErr) {
        console.warn('[MIDTRANS] Fallback ke QRIS simulasi:', midtransErr.message);
      }
    } else {
      console.warn('[MIDTRANS] Server key kosong. Menggunakan QRIS simulasi lokal.');
    }

    if (!qrString) {
      paymentProvider = 'simulasi';
      qrString = [
        'DEPO_QRIS_SIM',
        `paymentId=${orderId}`,
        `transaksiId=${transaksiId}`,
        `amount=${grossAmount}`,
        `merchant=Depo Air Minum`,
      ].join('|');
    }

    const expiresAt = new Date(Date.now() + 15 * 60 * 1000).toISOString().slice(0, 19).replace('T', ' ');
    const nowSql = now.toISOString().slice(0, 19).replace('T', ' ');

    await pool.query(
      `INSERT INTO qr_payments (payment_id, transaksi_id, jumlah, qr_content, status, nama_depot, expires_at, created_at)
       VALUES (?, ?, ?, ?, 'pending', 'Depo Air Minum', ?, ?)`,
      [orderId, transaksiId, t.total_harga, qrString, expiresAt, nowSql]
    );

    await pool.query(
      'UPDATE transaksi SET qr_payment_id = ?, updated_at = ? WHERE id = ?',
      [orderId, nowSql, transaksiId]
    );

    res.status(201).json({
      paymentId: orderId,
      transaksiId,
      qrContent: qrString,
      jumlah: parseFloat(t.total_harga),
      status: 'pending',
      expiresAt,
      namaDepot: paymentProvider === 'midtrans' ? 'Depo Air Minum' : 'Depo Air Minum (Simulasi)'
    });
  } catch (err) {
    console.error('[QRIS ERROR]', err);
    res.status(500).json({ message: err.message || 'Internal Server Error' });
  }
});

app.get('/v1/pembayaran/qris/:paymentId/status', authMiddleware, async (req, res) => {
  try {
    const [rows] = await pool.query('SELECT status, payment_id, transaksi_id, jumlah, paid_at, expires_at FROM qr_payments WHERE payment_id = ?', [req.params.paymentId]);
    if (rows.length === 0) return res.status(404).json({ message: 'Pembayaran QR tidak ditemukan' });
    const r = rows[0];
    res.json({
      paymentId: r.payment_id,
      transaksiId: r.transaksi_id,
      status: r.status,
      jumlah: parseFloat(r.jumlah),
      paidAt: r.paid_at ? r.paid_at.toISOString ? r.paid_at.toISOString() : r.paid_at : null,
      expiresAt: r.expires_at ? r.expires_at.toISOString ? r.expires_at.toISOString() : r.expires_at : null,
    });
  } catch (err) {
    console.error(err);
    res.status(500).json({ message: 'Internal Server Error' });
  }
});

// Status endpoint publik (tanpa auth) — digunakan oleh scan-web browser page
app.get('/v1/pembayaran/qris/:paymentId/status-public', async (req, res) => {
  try {
    const [rows] = await pool.query('SELECT status, paid_at FROM qr_payments WHERE payment_id = ?', [req.params.paymentId]);
    if (rows.length === 0) return res.status(404).json({ message: 'Tidak ditemukan' });
    const r = rows[0];
    res.json({
      status: r.status,
      paidAt: r.paid_at ? (r.paid_at.toISOString ? r.paid_at.toISOString() : r.paid_at) : null
    });
  } catch (err) {
    res.status(500).json({ message: 'Internal Server Error' });
  }
});

// ── HALAMAN WEB: Tampilan QRIS Midtrans (dapat di-scan HP nyata) ─────────────
app.get('/v1/pembayaran/qris/:paymentId/scan-web', async (req, res) => {
  try {
    const [rows] = await pool.query('SELECT * FROM qr_payments WHERE payment_id = ?', [req.params.paymentId]);
    if (rows.length === 0) {
      return res.status(404).send('<h1 style="text-align:center;margin-top:100px;font-family:sans-serif;">Pembayaran tidak ditemukan.</h1>');
    }

    const payment = rows[0];

    if (payment.status === 'paid') {
      return res.send(`<!DOCTYPE html><html lang="id"><head><meta charset="UTF-8"><title>Pembayaran Berhasil</title>
      <link href="https://fonts.googleapis.com/css2?family=Outfit:wght@400;700;800&display=swap" rel="stylesheet">
      <style>body{font-family:'Outfit',sans-serif;background:#f0fdf4;display:flex;justify-content:center;align-items:center;min-height:100vh;}
      .card{background:#fff;border-radius:24px;padding:40px 32px;text-align:center;box-shadow:0 20px 40px rgba(0,0,0,.08);}
      .icon{font-size:64px;} h1{color:#10b981;margin:16px 0 8px;} p{color:#64748b;}</style></head>
      <body><div class="card"><div class="icon">✅</div><h1>Pembayaran Berhasil!</h1><p>Transaksi Anda telah diterima.</p></div></body></html>`);
    }

    if (payment.status === 'expired') {
      return res.status(400).send('<h1 style="text-align:center;margin-top:100px;font-family:sans-serif;color:#ef4444;">QRIS sudah kadaluarsa. Minta kasir buat transaksi baru.</h1>');
    }

    const formatter = new Intl.NumberFormat('id-ID', {
      style: 'currency', currency: 'IDR',
      minimumFractionDigits: 0, maximumFractionDigits: 0
    });
    const formattedAmount = formatter.format(payment.jumlah);
    const qrData = payment.qr_content || '';
    const isMidtransQris = qrData.startsWith('00020101');
    const orderId = payment.payment_id;

    res.send(`<!DOCTYPE html>
<html lang="id">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>Pembayaran QRIS — Depo Air Minum</title>
  <link href="https://fonts.googleapis.com/css2?family=Outfit:wght@400;500;600;700;800&display=swap" rel="stylesheet">
  <script src="https://cdnjs.cloudflare.com/ajax/libs/qrcodejs/1.0.0/qrcode.min.js"></script>
  <style>
    :root {
      --blue: #0284c7; --green: #10b981; --red: #ef4444;
      --bg: #f8fafc; --card: #fff; --muted: #64748b;
    }
    * { box-sizing: border-box; margin: 0; padding: 0; }
    body {
      font-family: 'Outfit', sans-serif;
      background: var(--bg);
      min-height: 100vh;
      display: flex;
      justify-content: center;
      align-items: flex-start;
      padding: 20px 16px 40px;
    }
    .card {
      background: var(--card);
      border-radius: 28px;
      box-shadow: 0 20px 40px -10px rgba(0,0,0,.1);
      padding: 28px 20px;
      width: 100%;
      max-width: 400px;
      display: flex;
      flex-direction: column;
      align-items: center;
      gap: 16px;
    }
    .badge {
      background: linear-gradient(135deg,#e0f2fe,#bae6fd);
      color: var(--blue);
      font-size: 11px;
      font-weight: 700;
      letter-spacing: 1.2px;
      padding: 5px 16px;
      border-radius: 20px;
      text-transform: uppercase;
    }
    h1 { font-size: 22px; font-weight: 800; color: #0f172a; text-align: center; }
    .amount {
      font-size: 32px;
      font-weight: 800;
      color: var(--blue);
      letter-spacing: -0.5px;
    }
    .qr-box {
      background: #fff;
      border: 2.5px solid #e2e8f0;
      border-radius: 20px;
      padding: 18px;
      display: flex;
      flex-direction: column;
      align-items: center;
      gap: 12px;
      width: 100%;
    }
    #qrcode canvas, #qrcode img { border-radius: 10px; }
    .wallets {
      display: flex;
      justify-content: center;
      gap: 8px;
      flex-wrap: wrap;
    }
    .wallet-pill {
      font-size: 11px;
      font-weight: 700;
      background: #f0f9ff;
      color: #0369a1;
      border: 1px solid #bae6fd;
      border-radius: 20px;
      padding: 3px 10px;
    }
    .info {
      width: 100%;
      background: #f8fafc;
      border-radius: 14px;
      padding: 14px;
      border: 1px solid #f1f5f9;
    }
    .info-row { display: flex; justify-content: space-between; font-size: 13px; margin-bottom: 7px; }
    .info-row:last-child { margin-bottom: 0; }
    .label { color: var(--muted); }
    .val { font-weight: 700; color: #1e293b; }
    .status-waiting { color: #f59e0b; }
    .status-paid { color: var(--green); }
    .status-expired { color: var(--red); }
    .note {
      font-size: 12px;
      color: var(--muted);
      text-align: center;
      line-height: 1.6;
      padding: 0 8px;
    }
    .btn-sim {
      width: 100%;
      background: linear-gradient(135deg, #10b981, #059669);
      color: #fff;
      border: none;
      padding: 16px;
      border-radius: 16px;
      font-size: 15px;
      font-weight: 700;
      cursor: pointer;
      box-shadow: 0 8px 20px -5px rgba(16,185,129,.4);
      transition: opacity .2s;
      font-family: 'Outfit', sans-serif;
    }
    .btn-sim:hover { opacity: .9; }
    .btn-sim:disabled { opacity: .5; cursor: not-allowed; }
    .divider { width: 100%; border-top: 1.5px dashed #e2e8f0; }
    .success-overlay {
      display: none;
      flex-direction: column;
      align-items: center;
      gap: 16px;
      padding: 20px 0;
    }
    .success-overlay .big-icon { font-size: 72px; }
    .success-overlay h2 { font-size: 22px; font-weight: 800; color: var(--green); }
    .success-overlay p { font-size: 14px; color: var(--muted); text-align: center; }
    .spinner {
      width: 18px; height: 18px;
      border: 2.5px solid #cbd5e1;
      border-top-color: var(--blue);
      border-radius: 50%;
      animation: spin .8s linear infinite;
      display: inline-block;
    }
    @keyframes spin { to { transform: rotate(360deg); } }
    .polling-row {
      display: flex;
      align-items: center;
      gap: 8px;
      font-size: 13px;
      color: var(--muted);
    }
  </style>
</head>
<body>
  <div class="card">

    <!-- SUCCESS OVERLAY -->
    <div class="success-overlay" id="success-overlay">
      <div class="big-icon">✅</div>
      <h2>Pembayaran Berhasil!</h2>
      <p>Terima kasih. Transaksi Anda telah diterima dan sedang diproses.</p>
    </div>

    <!-- MAIN PAY VIEW -->
    <div id="pay-view" style="width:100%;display:flex;flex-direction:column;align-items:center;gap:16px;">
      <span class="badge">QRIS Midtrans · Sandbox</span>
      <h1>${payment.nama_depot || 'Depo Air Minum'}</h1>
      <p class="amount">${formattedAmount}</p>

      ${isMidtransQris ? `
      <div class="qr-box">
        <div style="background:#fffbeb;border:1px solid #fde68a;border-radius:12px;padding:12px;margin-bottom:8px;width:100%;">
          <p style="font-size:11px;color:#d97706;margin:0;line-height:1.4;text-align:center;"><b>PENTING:</b> Karena ini mode Sandbox (Uji Coba), e-wallet asli (ShopeePay, OVO, dll) mungkin menampilkan peringatan <b>"QR Tidak Valid"</b>. Silakan gunakan tombol <b>Simulasi Bayar</b> di bawah.</p>
        </div>
        <p style="font-size:12px;font-weight:600;color:#0284c7;text-align:center;">📱 Scan Simulator / Klik Simulasi</p>
        <div id="qrcode"></div>
        <div class="wallets">
          <span class="wallet-pill">GoPay</span>
          <span class="wallet-pill">OVO</span>
          <span class="wallet-pill">DANA</span>
          <span class="wallet-pill">ShopeePay</span>
          <span class="wallet-pill">M-Banking</span>
        </div>
      </div>
      ` : `
      <div class="qr-box" style="padding:24px;">
        <p style="font-size:13px;color:var(--muted);text-align:center;">⚠️ QR Code simulasi lama.<br>Restart transaksi untuk QRIS Midtrans asli.</p>
      </div>
      `}

      <div class="info">
        <div class="info-row">
          <span class="label">Merchant</span>
          <span class="val">${payment.nama_depot || 'Depo Air Minum'}</span>
        </div>
        <div class="info-row">
          <span class="label">Order ID</span>
          <span class="val" style="font-size:11px;font-family:monospace;">${orderId}</span>
        </div>
        <div class="info-row">
          <span class="label">Jumlah</span>
          <span class="val">${formattedAmount}</span>
        </div>
        <div class="info-row">
          <span class="label">Status</span>
          <span class="val status-waiting" id="status-text">⏳ Menunggu Pembayaran</span>
        </div>
      </div>

      <div class="divider"></div>

      <!-- SANDBOX SIMULATOR BUTTON -->
      <div style="width:100%;">
        <p style="font-size:11px;text-align:center;color:#94a3b8;margin-bottom:10px;font-weight:600;letter-spacing:.5px;">— MODE SANDBOX / TESTING —</p>
        <button class="btn-sim" id="btn-simulate" onclick="simulatePay()">
          🧪 Simulasi Bayar (Sandbox)
        </button>
        <p class="note" style="margin-top:10px;">
          Klik tombol di atas untuk mensimulasikan pembayaran berhasil melalui Midtrans Sandbox. Status akan otomatis diperbarui.
        </p>
      </div>

      <div class="divider"></div>

      <div class="polling-row">
        <div class="spinner"></div>
        <span>Memeriksa status pembayaran setiap 3 detik...</span>
      </div>

    </div>
  </div>

  <script>
    ${isMidtransQris ? `
    new QRCode(document.getElementById('qrcode'), {
      text: ${JSON.stringify(qrData)},
      width: 230,
      height: 230,
      colorDark: '#0f172a',
      colorLight: '#ffffff',
      correctLevel: QRCode.CorrectLevel.M
    });
    ` : ''}

    const PAYMENT_ID = ${JSON.stringify(orderId)};
    let isFinished = false;

    function showSuccess() {
      if (isFinished) return;
      isFinished = true;
      document.getElementById('pay-view').style.display = 'none';
      const overlay = document.getElementById('success-overlay');
      overlay.style.display = 'flex';
    }

    async function simulatePay() {
      const btn = document.getElementById('btn-simulate');
      btn.disabled = true;
      btn.textContent = '⏳ Memproses...';
      try {
        const resp = await fetch('/v1/pembayaran/qris/' + PAYMENT_ID + '/simulate-pay', {
          method: 'POST',
          headers: { 'Content-Type': 'application/json' }
        });
        const data = await resp.json();
        if (resp.ok && (data.status === 'paid' || data.success)) {
          showSuccess();
        } else {
          alert('Gagal simulasi: ' + (data.message || 'Coba lagi'));
          btn.disabled = false;
          btn.textContent = '🧪 Simulasi Bayar (Sandbox)';
        }
      } catch (e) {
        alert('Error koneksi: ' + e.message);
        btn.disabled = false;
        btn.textContent = '🧪 Simulasi Bayar (Sandbox)';
      }
    }

    // Auto polling status setiap 3 detik
    async function pollStatus() {
      if (isFinished) return;
      try {
        const resp = await fetch('/v1/pembayaran/qris/' + PAYMENT_ID + '/status-public');
        if (!resp.ok) return;
        const data = await resp.json();
        const statusEl = document.getElementById('status-text');
        if (data.status === 'paid') {
          if (statusEl) { statusEl.textContent = '✅ LUNAS'; statusEl.className = 'val status-paid'; }
          showSuccess();
        } else if (data.status === 'expired') {
          if (statusEl) { statusEl.textContent = '❌ Kadaluarsa'; statusEl.className = 'val status-expired'; }
          isFinished = true;
        }
      } catch (e) {}
    }

    setInterval(pollStatus, 3000);
    // Check immediately on load too
    setTimeout(pollStatus, 500);
  </script>
</body>
</html>`);
  } catch (err) {
    console.error(err);
    res.status(500).send('Kesalahan internal server.');
  }
});

// ── SIMULATE PAY (Midtrans Sandbox — panggil API accept-payment) ───────────────
app.post('/v1/pembayaran/qris/:paymentId/simulate-pay', async (req, res) => {
  const connection = await pool.getConnection();
  await connection.beginTransaction();
  try {
    const { paymentId } = req.params;
    const [rows] = await pool.query('SELECT * FROM qr_payments WHERE payment_id = ?', [paymentId]);
    if (rows.length === 0) {
      await connection.rollback();
      return res.status(404).json({ message: 'Pembayaran tidak ditemukan' });
    }

    const payment = rows[0];
    if (payment.status !== 'pending') {
      await connection.rollback();
      return res.json({ message: `Status sudah ${payment.status}`, status: payment.status, success: payment.status === 'paid' });
    }

    const nowSql = new Date().toISOString().slice(0, 19).replace('T', ' ');

    // Coba panggil Midtrans Sandbox accept-payment API untuk trigger settlement
    let midtransOk = false;
    if (MIDTRANS_SERVER_KEY && !MIDTRANS_IS_PRODUCTION) {
      try {
        // Midtrans sandbox accept endpoint: POST /v2/{orderId}/accept
        const acceptRes = await fetch(`${MIDTRANS_BASE_URL}/v2/${paymentId}/accept`, {
          method: 'POST',
          headers: {
            'Accept': 'application/json',
            'Content-Type': 'application/json',
            'Authorization': midtransAuthHeader()
          }
        });
        const acceptData = await acceptRes.json();
        console.log('[SIMULATE-PAY] Midtrans accept response:', acceptData);
        // Jika Midtrans accept berhasil, webhook akan otomatis datang
        // Tapi kita juga update lokal agar langsung tampil
        if (acceptRes.ok || acceptData.status_code === '200' || acceptData.transaction_status === 'settlement') {
          midtransOk = true;
        }
      } catch (e) {
        console.warn('[SIMULATE-PAY] Midtrans accept failed, falling back to local update:', e.message);
      }
    }

    // Update lokal (fallback atau setelah Midtrans OK)
    await connection.query(
      'UPDATE qr_payments SET status = "paid", paid_at = ?, updated_at = ? WHERE payment_id = ?',
      [nowSql, nowSql, paymentId]
    );

    const [payRows] = await connection.query(
      'SELECT transaksi_id FROM qr_payments WHERE payment_id = ?', [paymentId]
    );
    if (payRows.length > 0) {
      const trxId = payRows[0].transaksi_id;
      await connection.query(
        `UPDATE transaksi SET qr_paid_at = ?, status = 'menungguValidasi', updated_at = ? WHERE id = ?`,
        [nowSql, nowSql, trxId]
      );
      console.log(`[SIMULATE-PAY] ✅ Transaksi ${trxId} dibayar (sandbox simulate). Midtrans OK: ${midtransOk}`);
    }

    await connection.commit();
    res.json({ paymentId, success: true, status: 'paid', midtransTriggered: midtransOk, message: 'Pembayaran simulasi berhasil' });
  } catch (err) {
    await connection.rollback();
    console.error('[SIMULATE-PAY ERROR]', err);
    res.status(500).json({ message: err.message || 'Internal Server Error' });
  } finally {
    connection.release();
  }
});

// ── MIDTRANS WEBHOOK NOTIFICATION ────────────────────────────────────────────
app.post('/v1/pembayaran/midtrans-notification', async (req, res) => {
  const connection = await pool.getConnection();
  await connection.beginTransaction();
  try {
    const notif = req.body || {};
    const orderId         = notif.order_id;
    const statusCode      = notif.status_code;
    const grossAmount     = notif.gross_amount;
    const transactionStatus = notif.transaction_status;
    const fraudStatus     = notif.fraud_status;
    const signatureKey    = notif.signature_key;

    console.log('[MIDTRANS WEBHOOK] Received:', { orderId, transactionStatus, fraudStatus });

    if (MIDTRANS_SERVER_KEY && signatureKey) {
      const expectedSignature = crypto
        .createHash('sha512')
        .update(`${orderId}${statusCode}${grossAmount}${MIDTRANS_SERVER_KEY}`)
        .digest('hex');

      if (expectedSignature !== signatureKey) {
        console.warn('[MIDTRANS WEBHOOK] Invalid signature! Kemungkinan request palsu.');
        await connection.rollback();
        return res.status(403).json({ message: 'Invalid signature' });
      }
    }

    const isSuccess =
      transactionStatus === 'settlement' ||
      (transactionStatus === 'capture' && fraudStatus === 'accept');

    const isExpiredOrDenied =
      transactionStatus === 'expire' ||
      transactionStatus === 'cancel' ||
      transactionStatus === 'deny';

    const nowSql = new Date().toISOString().slice(0, 19).replace('T', ' ');

    if (isSuccess) {
      await connection.query(
        'UPDATE qr_payments SET status = "paid", paid_at = ?, updated_at = ? WHERE payment_id = ?',
        [nowSql, nowSql, orderId]
      );

      const [payRows] = await connection.query(
        'SELECT transaksi_id FROM qr_payments WHERE payment_id = ?', [orderId]
      );

      if (payRows.length > 0) {
        const trxId = payRows[0].transaksi_id;
        await connection.query(
          `UPDATE transaksi SET qr_paid_at = ?, status = 'menungguValidasi', updated_at = ? WHERE id = ?`,
          [nowSql, nowSql, trxId]
        );
        console.log(`[MIDTRANS WEBHOOK] ✅ Transaksi ${trxId} SUKSES dibayar via Midtrans.`);
      }
    } else if (isExpiredOrDenied) {
      await connection.query(
        'UPDATE qr_payments SET status = "expired", updated_at = ? WHERE payment_id = ?',
        [nowSql, orderId]
      );
      console.log(`[MIDTRANS WEBHOOK] ❌ Transaksi ${orderId} expired/dibatalkan.`);
    } else {
      console.log(`[MIDTRANS WEBHOOK] ℹ️ Status pending/belum final: ${transactionStatus}`);
    }

    await connection.commit();
    res.status(200).json({ message: 'OK' });
  } catch (err) {
    await connection.rollback();
    console.error('[MIDTRANS WEBHOOK ERROR]', err);
    res.status(500).json({ message: 'Internal Server Error' });
  } finally {
    connection.release();
  }
});


// ── LAPORAN ───────────────────────────────────────────────────────────────────

app.get('/v1/laporan/dashboard/manager', authMiddleware, async (req, res) => {
  try {
    const getLocalDateString = (date) => {
      const d = new Date(date);
      const year = d.getFullYear();
      const month = String(d.getMonth() + 1).padStart(2, '0');
      const day = String(d.getDate()).padStart(2, '0');
      return `${year}-${month}-${day}`;
    };

    const getLocalMonthString = (date) => {
      const d = new Date(date);
      const year = d.getFullYear();
      const month = String(d.getMonth() + 1).padStart(2, '0');
      return `${year}-${month}`;
    };

    const today = getLocalDateString(new Date());
    const thisMonth = getLocalMonthString(new Date());
    
    const [completedRows] = await pool.query('SELECT * FROM transaksi WHERE status = "selesai"');
    const [expenseRows] = await pool.query('SELECT * FROM pengeluaran');
    const [categoryRows] = await pool.query('SELECT * FROM kategori');
    
    const harianList = completedRows.filter((t) => getLocalDateString(t.created_at) === today);
    const bulananList = completedRows.filter((t) => getLocalMonthString(t.created_at) === thisMonth);
    const semuaList = completedRows;
    
    const pengeluaranHarian = expenseRows.filter((p) => {
      const tgl = p.tanggal instanceof Date ? p.tanggal : new Date(p.tanggal);
      return getLocalDateString(tgl) === today;
    });
    const pengeluaranBulanan = expenseRows.filter((p) => {
      const tgl = p.tanggal instanceof Date ? p.tanggal : new Date(p.tanggal);
      return getLocalMonthString(tgl) === thisMonth;
    });
    const pengeluaranSemua = expenseRows;
    
    const getBreakdownForList = async (txList, pengList) => {
      const list = [];
      for (const kat of categoryRows) {
        let total = 0;
        if (kat.tipe === 'pemasukan') {
          for (const t of txList) {
            const [itemSumRows] = await pool.query(
              `SELECT SUM(ti.subtotal) as subtotal_sum
               FROM transaksi_items ti
               JOIN produk p ON p.id = ti.produk_id
               WHERE ti.transaksi_id = ? AND p.kategori_id = ?`,
              [t.id, kat.id]
            );
            total += parseFloat(itemSumRows[0].subtotal_sum) || 0;
          }
        } else {
          pengList.forEach((p) => {
            if (p.kategori_id === kat.id) {
              total += parseFloat(p.nominal) || 0;
            }
          });
        }
        list.push({
          id: kat.id,
          nama: kat.nama,
          tipe: kat.tipe,
          ikon: kat.ikon,
          total
        });
      }
      return list;
    };
    
    const breakdownHarian = await getBreakdownForList(harianList, pengeluaranHarian);
    const breakdownBulanan = await getBreakdownForList(bulananList, pengeluaranBulanan);
    const breakdownSemua = await getBreakdownForList(semuaList, pengeluaranSemua);
    
    const summary = await getGalonSummary();
    const [pelangganCountRows] = await pool.query('SELECT COUNT(*) as total FROM pelanggan');
    
    const totalPendapatanHarian = harianList.reduce((s, t) => s + parseFloat(t.total_harga), 0);
    const totalPengeluaranHarian = pengeluaranHarian.reduce((s, p) => s + parseFloat(p.nominal), 0);
    
    const totalPendapatanBulanan = bulananList.reduce((s, t) => s + parseFloat(t.total_harga), 0);
    const totalPengeluaranBulanan = pengeluaranBulanan.reduce((s, p) => s + parseFloat(p.nominal), 0);
    
    const totalPendapatanSemua = semuaList.reduce((s, t) => s + parseFloat(t.total_harga), 0);
    const totalPengeluaranSemua = pengeluaranSemua.reduce((s, p) => s + parseFloat(p.nominal), 0);
    
    res.json({
      harian: {
        totalPendapatan: totalPendapatanHarian,
        totalPengeluaran: totalPengeluaranHarian,
        pendapatanBersih: totalPendapatanHarian - totalPengeluaranHarian,
        totalTransaksi: harianList.length
      },
      bulanan: {
        totalPendapatan: totalPendapatanBulanan,
        totalPengeluaran: totalPengeluaranBulanan,
        pendapatanBersih: totalPendapatanBulanan - totalPengeluaranBulanan,
        totalTransaksi: bulananList.length
      },
      semua: {
        totalPendapatan: totalPendapatanSemua,
        totalPengeluaran: totalPengeluaranSemua,
        pendapatanBersih: totalPendapatanSemua - totalPengeluaranSemua,
        totalTransaksi: semuaList.length
      },
      breakdown: {
        harian: breakdownHarian,
        bulanan: breakdownBulanan,
        semua: breakdownSemua
      },
      totalPendapatanHarian,
      totalTransaksiHari: harianList.length,
      galonBersih: summary.tersedia,
      tersedia: summary.tersedia,
      dipinjam: summary.dipinjam,
      totalPelanggan: pelangganCountRows[0].total,
      totalPendapatan: totalPendapatanSemua,
      totalPengeluaran: totalPengeluaranSemua,
      pendapatanBersih: totalPendapatanSemua - totalPengeluaranSemua,
      totalTransaksi: semuaList.length
    });
  } catch (err) {
    console.error(err);
    res.status(500).json({ message: 'Internal Server Error' });
  }
});

app.get('/v1/laporan/dashboard/crew', authMiddleware, async (req, res) => {
  try {
    const today = new Date().toISOString().slice(0, 10);
    const crewId = req.user.sub;
    
    const [txRows] = await pool.query(
      'SELECT id, total_harga FROM transaksi WHERE status = "selesai" AND crew_id = ? AND DATE(created_at) = ?',
      [crewId, today]
    );
    
    let totalPenjualanHarian = 0;
    let totalGalonTerjual = 0;
    
    for (const tx of txRows) {
      totalPenjualanHarian += parseFloat(tx.total_harga) || 0;
      const [itemQtyRows] = await pool.query(
        'SELECT SUM(jumlah) as qty FROM transaksi_items WHERE transaksi_id = ?',
        [tx.id]
      );
      totalGalonTerjual += parseInt(itemQtyRows[0].qty, 10) || 0;
    }
    
    res.json({
      totalPenjualanHarian,
      totalGalonTerjual,
      totalTransaksiHari: txRows.length
    });
  } catch (err) {
    console.error(err);
    res.status(500).json({ message: 'Internal Server Error' });
  }
});

app.get('/v1/laporan/keuangan', authMiddleware, async (req, res) => {
  try {
    const { tanggalMulai, tanggalAkhir } = req.query;
    
    let txQuery = 'SELECT * FROM transaksi WHERE status = "selesai"';
    let expQuery = 'SELECT * FROM pengeluaran WHERE 1=1';
    const txParams = [];
    const expParams = [];
    
    if (tanggalMulai) {
      txQuery += ' AND DATE(created_at) >= ?';
      expQuery += ' AND tanggal >= ?';
      txParams.push(tanggalMulai);
      expParams.push(tanggalMulai);
    }
    
    if (tanggalAkhir) {
      txQuery += ' AND DATE(created_at) <= ?';
      expQuery += ' AND tanggal <= ?';
      txParams.push(tanggalAkhir);
      expParams.push(tanggalAkhir);
    }
    
    const [txList] = await pool.query(txQuery, txParams);
    const [expList] = await pool.query(expQuery, expParams);
    const [categoryRows] = await pool.query('SELECT * FROM kategori');
    
    const totalPendapatan = txList.reduce((s, t) => s + parseFloat(t.total_harga), 0);
    const totalPengeluaran = expList.reduce((s, p) => s + parseFloat(p.nominal), 0);
    const totalDikirim = txList.filter((t) => t.tipe_pembelian === 'dikirim').length;
    const totalDiDepo = txList.filter((t) => t.tipe_pembelian !== 'dikirim').length;
    const transaksiCrewMap = new Map();
    for (const t of txList) {
      const id = t.pengirim_crew_id || t.crew_id;
      if (!id) continue;
      const current = transaksiCrewMap.get(id) || { crewId: id, totalTransaksi: 0, totalKirim: 0, totalDiDepo: 0, totalNominal: 0 };
      current.totalTransaksi += 1;
      current.totalNominal += parseFloat(t.total_harga) || 0;
      if (t.tipe_pembelian === 'dikirim') current.totalKirim += 1;
      else current.totalDiDepo += 1;
      transaksiCrewMap.set(id, current);
    }
    const transaksiCrew = [];
    for (const item of transaksiCrewMap.values()) {
      const [crewRows] = await pool.query('SELECT nama, username FROM users WHERE id = ?', [item.crewId]);
      transaksiCrew.push({
        ...item,
        crewNama: crewRows[0]?.nama || item.crewId,
        username: crewRows[0]?.username || '',
      });
    }
    transaksiCrew.sort((a, b) => b.totalTransaksi - a.totalTransaksi);
    
    const breakdown = [];
    for (const kat of categoryRows) {
      let total = 0;
      if (kat.tipe === 'pemasukan') {
        for (const t of txList) {
          const [itemSumRows] = await pool.query(
            `SELECT SUM(ti.subtotal) as subtotal_sum
             FROM transaksi_items ti
             JOIN produk p ON p.id = ti.produk_id
             WHERE ti.transaksi_id = ? AND p.kategori_id = ?`,
            [t.id, kat.id]
          );
          total += parseFloat(itemSumRows[0].subtotal_sum) || 0;
        }
      } else {
        expList.forEach((p) => {
          if (p.kategori_id === kat.id) {
            total += parseFloat(p.nominal) || 0;
          }
        });
      }
      breakdown.push({
        id: kat.id,
        nama: kat.nama,
        tipe: kat.tipe,
        ikon: kat.ikon,
        total
      });
    }
    
    const [cancelRows] = await pool.query('SELECT COUNT(*) as total FROM transaksi WHERE status = "dibatalkan"');
    
    const pendapatanTunai = txList.filter((t) => t.metode_pembayaran === 'tunai').reduce((s, t) => s + parseFloat(t.total_harga), 0);
    const pendapatanQris = txList.filter((t) => t.metode_pembayaran === 'qris').reduce((s, t) => s + parseFloat(t.total_harga), 0);
    const pendapatanTransfer = txList.filter((t) => t.metode_pembayaran === 'transfer').reduce((s, t) => s + parseFloat(t.total_harga), 0);
    
    res.json({
      tanggalMulai: tanggalMulai || new Date().toISOString().slice(0, 10),
      tanggalAkhir: tanggalAkhir || new Date().toISOString().slice(0, 10),
      totalPendapatan,
      totalPengeluaran,
      pendapatanBersih: totalPendapatan - totalPengeluaran,
      totalTransaksi: txList.length,
      transaksiSelesai: txList.length,
      transaksiDibatalkan: cancelRows[0].total,
      pendapatanTunai,
      pendapatanQris,
      pendapatanTransfer,
      totalDikirim,
      totalDiDepo,
      transaksiCrew,
      breakdown
    });
  } catch (err) {
    console.error(err);
    res.status(500).json({ message: 'Internal Server Error' });
  }
});


// ── HEALTH & UTILS ─────────────────────────────────────────────────────────────

app.get('/v1/health', (req, res) => {
  res.json({ status: 'ok', version: '1.0.0' });
});

// ── CABANG DEPO (Manager) ───────────────────────────────────────────────────

app.get('/v1/cabang', authMiddleware, managerOnly, async (req, res) => {
  try {
    const showAll = req.query.all === '1' || req.query.all === 'true';
    let query = 'SELECT * FROM cabang';
    if (!showAll) query += ' WHERE is_aktif = 1';
    query += ' ORDER BY is_pusat DESC, nama ASC';
    const [rows] = await pool.query(query);
    res.json(rows.map((r) => snakeToCamel(r)));
  } catch (err) {
    console.error(err);
    res.status(500).json({ message: sqlErrorMessage(err) });
  }
});

app.get('/v1/cabang/:id', authMiddleware, managerOnly, async (req, res) => {
  try {
    const [rows] = await pool.query('SELECT * FROM cabang WHERE id = ?', [req.params.id]);
    if (rows.length === 0) return res.status(404).json({ message: 'Cabang tidak ditemukan' });
    res.json(snakeToCamel(rows[0]));
  } catch (err) {
    console.error(err);
    res.status(500).json({ message: sqlErrorMessage(err) });
  }
});

app.post('/v1/cabang', authMiddleware, managerOnly, async (req, res) => {
  try {
    const body = req.body || {};
    const nama = String(body.nama || '').trim();
    if (!nama) return res.status(400).json({ message: 'Nama cabang wajib diisi' });

    const id = uuidv4();
    const now = new Date().toISOString().slice(0, 19).replace('T', ' ');
    const isPusat = body.isPusat ? 1 : 0;

    if (isPusat) {
      await pool.query('UPDATE cabang SET is_pusat = 0');
    }

    await pool.query(
      `INSERT INTO cabang (id, nama, alamat, kota, no_hp, is_pusat, is_aktif, created_at)
       VALUES (?, ?, ?, ?, ?, ?, 1, ?)`,
      [
        id,
        nama,
        body.alamat || null,
        body.kota || null,
        body.noHp || null,
        isPusat,
        now,
      ]
    );

    const [inserted] = await pool.query('SELECT * FROM cabang WHERE id = ?', [id]);
    res.status(201).json(snakeToCamel(inserted[0]));
  } catch (err) {
    console.error(err);
    res.status(500).json({ message: sqlErrorMessage(err) });
  }
});

app.put('/v1/cabang/:id', authMiddleware, managerOnly, async (req, res) => {
  try {
    const [rows] = await pool.query('SELECT * FROM cabang WHERE id = ?', [req.params.id]);
    if (rows.length === 0) return res.status(404).json({ message: 'Cabang tidak ditemukan' });

    const body = req.body || {};
    const current = rows[0];
    const now = new Date().toISOString().slice(0, 19).replace('T', ' ');
    const isPusat = body.isPusat !== undefined ? (body.isPusat ? 1 : 0) : current.is_pusat;

    if (isPusat) {
      await pool.query('UPDATE cabang SET is_pusat = 0 WHERE id != ?', [req.params.id]);
    }

    await pool.query(
      `UPDATE cabang SET nama = ?, alamat = ?, kota = ?, no_hp = ?, is_pusat = ?, is_aktif = ?, updated_at = ?
       WHERE id = ?`,
      [
        body.nama !== undefined ? String(body.nama).trim() : current.nama,
        body.alamat !== undefined ? body.alamat : current.alamat,
        body.kota !== undefined ? body.kota : current.kota,
        body.noHp !== undefined ? body.noHp : current.no_hp,
        isPusat,
        body.isAktif !== undefined ? (body.isAktif ? 1 : 0) : current.is_aktif,
        now,
        req.params.id,
      ]
    );

    const [updated] = await pool.query('SELECT * FROM cabang WHERE id = ?', [req.params.id]);
    res.json(snakeToCamel(updated[0]));
  } catch (err) {
    console.error(err);
    res.status(500).json({ message: sqlErrorMessage(err) });
  }
});

app.delete('/v1/cabang/:id', authMiddleware, managerOnly, async (req, res) => {
  try {
    const [rows] = await pool.query('SELECT id FROM cabang WHERE id = ?', [req.params.id]);
    if (rows.length === 0) return res.status(404).json({ message: 'Cabang tidak ditemukan' });

    const now = new Date().toISOString().slice(0, 19).replace('T', ' ');
    await pool.query('UPDATE cabang SET is_aktif = 0, updated_at = ? WHERE id = ?', [now, req.params.id]);
    res.status(204).send();
  } catch (err) {
    console.error(err);
    res.status(500).json({ message: sqlErrorMessage(err) });
  }
});

app.use((req, res) => {
  res.status(404).json({ message: `Route tidak ditemukan: ${req.method} ${req.path}` });
});

function getLanIpv4() {
  const nets = os.networkInterfaces();
  for (const name of Object.keys(nets)) {
    for (const net of nets[name]) {
      const isIpv4 = net.family === 'IPv4' || net.family === 4;
      if (isIpv4 && !net.internal) {
        return net.address;
      }
    }
  }
  return null;
}

// Server Startup
async function startServer() {
  await connectDb();
  await initDbSchema();
  
  app.listen(PORT, '0.0.0.0', () => {
    const lanIp = getLanIpv4();
    console.log('');
    console.log(`Depo Air API aktif — listen 0.0.0.0:${PORT} (semua jaringan)`);
    console.log(`  Browser di PC     : http://127.0.0.1:${PORT}/v1`);
    if (lanIp) {
      console.log(`  HP / Flutter app  : http://${lanIp}:${PORT}/v1`);
      console.log(`  → samakan lanHost di lib/config/api_config.dart`);
    } else {
      console.log(`  HP / Flutter app  : http://<IP-WiFi-PC>:${PORT}/v1  (cek: ipconfig)`);
    }
    console.log('Akun uji: crew001 / manager@depoair.com — password: Password123');
    console.log('');
  });
}

startServer().catch((err) => {
  console.error('[SERVER] Gagal memulai server:', err);
});
