/**
 * config/db.js
 * Koneksi MySQL pool, inisialisasi skema, dan seeding data awal.
 */
require('dotenv').config();
const mysql = require('mysql2/promise');
const fs = require('fs');
const path = require('path');
const bcrypt = require('bcryptjs');
const { v4: uuidv4 } = require('uuid');

let pool;

function getPool() {
  if (!pool) throw new Error('Database belum diinisialisasi. Panggil connectDb() terlebih dahulu.');
  return pool;
}

async function connectDb() {
  pool = mysql.createPool({
    host: process.env.DB_HOST || '127.0.0.1',
    port: parseInt(process.env.DB_PORT, 10) || 3306,
    user: process.env.DB_USER || 'root',
    password: process.env.DB_PASSWORD !== undefined ? process.env.DB_PASSWORD : 'password',
    database: process.env.DB_NAME || 'depo_app',
    waitForConnections: true,
    connectionLimit: 10,
    queueLimit: 0,
  });
  try {
    const conn = await pool.getConnection();
    console.log(`[DB] Terhubung ke MySQL database: ${process.env.DB_NAME}`);
    conn.release();
  } catch (err) {
    console.error('[DB] Gagal terhubung ke MySQL database.');
    console.error(err);
    process.exit(1);
  }
}

async function tableExists(conn, table) {
  const [rows] = await conn.query(
    `SELECT COUNT(*) AS c FROM information_schema.TABLES WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = ?`,
    [table]
  );
  return Number(rows[0].c) > 0;
}

async function columnExists(conn, table, column) {
  const [rows] = await conn.query(
    `SELECT COUNT(*) AS c FROM information_schema.COLUMNS WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = ? AND COLUMN_NAME = ?`,
    [table, column]
  );
  return Number(rows[0].c) > 0;
}

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
    if (await columnExists(conn, 'galon_mutasi', 'galon_id')) {
      try {
        await conn.query('ALTER TABLE galon_mutasi MODIFY COLUMN `galon_id` VARCHAR(100) NULL');
        console.log('[DB] Migrasi: galon_mutasi.galon_id dibuat nullable');
      } catch (e) {
        console.warn('[DB] Tidak bisa mengubah galon_mutasi.galon_id:', e.message);
      }
    }
  }
  try { await conn.query('CREATE INDEX `idx_galon_status` ON `galon` (`status`)'); } catch (_) {}
  try { await conn.query('CREATE INDEX `idx_galon_pelanggan` ON `galon` (`pelanggan_id`)'); } catch (_) {}
}

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
      { id: uuidv4(), nama: 'Depo Sitiarjo', alamat: 'Jl. Raya Sitiarjo No. 12', kota: 'Malang', noHp: '0341-123456', isPusat: 1 },
      { id: uuidv4(), nama: 'Depo Merjosari', alamat: 'Jl. Merjosari Indah No. 5', kota: 'Malang', noHp: '0341-234567', isPusat: 0 },
      { id: uuidv4(), nama: 'Depo Pasuruan', alamat: 'Jl. Panglima Sudirman No. 88', kota: 'Pasuruan', noHp: '0343-345678', isPusat: 0 },
    ];
    for (const b of branches) {
      await conn.query(
        `INSERT INTO cabang (id, nama, alamat, kota, no_hp, is_pusat, is_aktif, created_at) VALUES (?, ?, ?, ?, ?, ?, 1, ?)`,
        [b.id, b.nama, b.alamat, b.kota, b.noHp, b.isPusat, now]
      );
    }
    console.log('[DB] Seeding cabang selesai (3 cabang).');
  }
}

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

async function seedDbData(conn) {
  console.log('[DB] Seeding data awal...');
  const now = new Date().toISOString().slice(0, 19).replace('T', ' ');
  const crewId = 'crew_001';
  const managerId = 'manager_001';
  const katIsiUlang = uuidv4(), katGalonBaru = uuidv4(), katAksesoris = uuidv4();
  const katGajiCrew = uuidv4(), katListrik = uuidv4(), katSewa = uuidv4(), katMaintenance = uuidv4();
  const produkAir = uuidv4(), produkGalon = uuidv4(), pelanggan1 = uuidv4();

  await conn.query(
    `INSERT INTO users (id, role, username, password_hash, pin_hash, nama, no_hp, alamat, is_aktif, created_at) VALUES
     (?, 'crew', 'crew001', ?, ?, 'Budi Santoso', '081234567890', 'Jl. Crew No. 1', 1, ?),
     (?, 'manager', 'manager@depoair.com', ?, NULL, 'Ahmad Manager', '081298765432', 'Kantor Depo', 1, ?)`,
    [crewId, bcrypt.hashSync('1234', 10), bcrypt.hashSync('1234', 10), now, managerId, bcrypt.hashSync('Password123', 10), now]
  );
  await conn.query(
    `INSERT INTO kategori (id, nama, deskripsi, tipe, ikon, is_system, is_aktif, created_at) VALUES
     (?, 'Penjualan Isi Ulang', 'Produk Utama', 'pemasukan', 'water_drop', 1, 1, ?),
     (?, 'Penjualan Galon Baru', 'Inventori', 'pemasukan', 'inventory_2', 1, 1, ?),
     (?, 'Penjualan Aksesoris', 'Tambahan', 'pemasukan', 'widgets', 0, 1, ?),
     (?, 'Gaji Crew', 'Biaya Operasional', 'pengeluaran', 'people', 1, 1, ?),
     (?, 'Biaya Listrik & Air', 'Utilitas Bulanan', 'pengeluaran', 'bolt', 1, 1, ?),
     (?, 'Sewa Tempat', 'Biaya Tetap', 'pengeluaran', 'store', 1, 1, ?),
     (?, 'Perawatan Alat', 'Maintenance', 'pengeluaran', 'build', 0, 1, ?)`,
    [katIsiUlang, now, katGalonBaru, now, katAksesoris, now, katGajiCrew, now, katListrik, now, katSewa, now, katMaintenance, now]
  );
  await conn.query(
    `INSERT INTO produk (id, nama, kategori_id, harga, stok, deskripsi, is_aktif, created_at) VALUES
     (?, 'Air Galon 19L', ?, 15000, 100, 'Air minum kemasan galon 19 liter', 1, ?),
     (?, 'Isi Ulang Galon', ?, 12000, 200, 'Layanan isi ulang galon pelanggan', 1, ?)`,
    [produkAir, katIsiUlang, now, produkGalon, katGalonBaru, now]
  );
  await conn.query(
    `INSERT INTO pelanggan (id, nama, no_hp, alamat, total_galon_pinjam, total_transaksi, is_aktif, created_at) VALUES (?, 'Siti Aminah', '081211112222', 'Jl. Melati No. 5', 2, 450000.00, 1, ?)`,
    [pelanggan1, now]
  );
  for (let i = 1; i <= 35; i++) {
    await conn.query(`INSERT INTO galon (id, kode_galon, merek, jenis, status, pelanggan_id, created_at) VALUES (?, ?, 'Depo', 'isi', 'tersedia', NULL, ?)`, [uuidv4(), `G-${String(i).padStart(3,'0')}`, now]);
  }
  for (let i = 36; i <= 47; i++) {
    await conn.query(`INSERT INTO galon (id, kode_galon, merek, jenis, status, pelanggan_id, created_at) VALUES (?, ?, 'Depo', 'isi', 'dipinjam', ?, ?)`, [uuidv4(), `G-${String(i).padStart(3,'0')}`, pelanggan1, now]);
  }
  for (let i = 48; i <= 49; i++) {
    await conn.query(`INSERT INTO galon (id, kode_galon, merek, jenis, status, pelanggan_id, created_at) VALUES (?, ?, 'Depo', 'isi', 'rusak', NULL, ?)`, [uuidv4(), `G-${String(i).padStart(3,'0')}`, now]);
  }
  await conn.query(`INSERT INTO galon (id, kode_galon, merek, jenis, status, pelanggan_id, created_at) VALUES (?, 'G-050', 'Depo', 'isi', 'hilang', NULL, ?)`, [uuidv4(), now]);
  console.log('[DB] Seeding selesai.');
}

async function initDbSchema() {
  const conn = await pool.getConnection();
  try {
    const [rows] = await conn.query("SHOW TABLES LIKE 'users'");
    if (rows.length === 0) {
      console.log('[DB] Tabel tidak ditemukan. Menginisialisasi skema dari schema.sql...');
      const schemaPath = path.join(__dirname, '..', 'schema.sql');
      if (fs.existsSync(schemaPath)) {
        const sql = fs.readFileSync(schemaPath, 'utf8');
        const statements = sql.split(';').map((s) => s.trim()).filter((s) => s.length > 0);
        for (const statement of statements) await conn.query(statement);
        console.log('[DB] Skema database berhasil diinisialisasi.');
        await seedDbData(conn);
      } else {
        console.warn('[DB] schema.sql tidak ditemukan.');
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

module.exports = { connectDb, initDbSchema, getPool };
