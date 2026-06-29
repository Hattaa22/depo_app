/**
 * helpers/galon.js
 * Helper fungsi untuk manajemen galon: summary, mutasi, transaksi galon.
 */
const { v4: uuidv4 } = require('uuid');
const { snakeToCamel } = require('./mappers');

let pool;
let galonMutasiColumnCache = null;

function setPool(p) { pool = p; }

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
    hilang: parseInt(s.hilang, 10) || 0,
  };
}

async function getGalonMutasiColumns(conn) {
  if (galonMutasiColumnCache) return galonMutasiColumnCache;
  const [dbRow] = await conn.query('SELECT DATABASE() AS db');
  const db = dbRow[0]?.db;
  const [rows] = await conn.query(
    `SELECT COLUMN_NAME FROM information_schema.COLUMNS WHERE TABLE_SCHEMA = ? AND TABLE_NAME = 'galon_mutasi'`,
    [db]
  );
  galonMutasiColumnCache = new Set(rows.map((r) => r.COLUMN_NAME));
  return galonMutasiColumnCache;
}

function resetGalonMutasiColumnCache() { galonMutasiColumnCache = null; }

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
  const fields = [], values = [];
  for (const [col, val] of Object.entries(mapping)) {
    if (!cols.has(col)) continue;
    if (val === undefined) continue;
    fields.push(col);
    values.push(val);
  }
  if (fields.length === 0) throw new Error('Tabel galon_mutasi tidak memiliki kolom yang dikenali');
  const sql = `INSERT INTO galon_mutasi (${fields.map((f) => `\`${f}\``).join(', ')}) VALUES (${fields.map(() => '?').join(', ')})`;
  await conn.query(sql, values);
}

async function applyGalonMutasiWithConnection(connection, aksi, jumlah, meta = {}) {
  const want = Math.max(0, parseInt(jumlah, 10) || 0);
  if (want === 0) return { jumlah: 0, kodeList: [], mutasiId: null };

  const fromStatus = aksi === 'pinjam' ? 'tersedia' : 'dipinjam';
  const toStatus = aksi === 'pinjam' ? 'dipinjam' : 'tersedia';

  if (aksi === 'pinjam' && meta.pelangganId) {
    const [pelangganRows] = await connection.query('SELECT id FROM pelanggan WHERE id = ?', [meta.pelangganId]);
    if (pelangganRows.length === 0) throw new Error('Pelanggan dengan ID ' + meta.pelangganId + ' tidak ditemukan');
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
    let tanggalPinjam;
    if (aksi === 'pinjam') {
      tanggalPinjam = meta.tanggal ? new Date(meta.tanggal).toISOString().slice(0, 19).replace('T', ' ') : now;
    } else {
      tanggalPinjam = null;
    }
    await connection.query(
      'UPDATE galon SET status = ?, pelanggan_id = ?, tanggal_pinjam = ?, catatan = ?, updated_at = ? WHERE id = ?',
      [toStatus, aksi === 'pinjam' ? (meta.pelangganId || null) : null, tanggalPinjam, aksi === 'pinjam' ? (meta.catatan || null) : null, now, g.id]
    );
    kodeList.push(g.kode_galon);
  }

  let mutasiId = null;
  if (n > 0) {
    mutasiId = uuidv4();
    await insertGalonMutasiRow(connection, {
      id: mutasiId,
      galonId: galons[0]?.id || null,
      aksi, jumlah: n,
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
      await connection.query('UPDATE pelanggan SET total_galon_pinjam = total_galon_pinjam + ? WHERE id = ?', [n, meta.pelangganId]);
    } else if (aksi === 'kembali') {
      await connection.query('UPDATE pelanggan SET total_galon_pinjam = GREATEST(0, total_galon_pinjam - ?) WHERE id = ?', [n, meta.pelangganId]);
    }
  }

  return { jumlah: n, kodeList, mutasiId };
}

async function applyGalonMutasi(aksi, jumlah, meta = {}) {
  const connection = await pool.getConnection();
  await connection.beginTransaction();
  try {
    const result = await applyGalonMutasiWithConnection(connection, aksi, jumlah, meta);
    await connection.commit();
    const summary = await getGalonSummary();
    return {
      jumlah: result.jumlah,
      mutasi: result.mutasiId ? { id: result.mutasiId, aksi, jumlah: result.jumlah, kodeGalon: result.kodeList, pelangganId: meta.pelangganId || null, catatan: meta.catatan || null, crewId: meta.crewId || null, crewNama: meta.crewNama || null, createdAt: new Date().toISOString() } : null,
      summary,
    };
  } catch (err) {
    await connection.rollback();
    throw err;
  } finally {
    connection.release();
  }
}

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

async function isProdukGalonBaru(connection, produkId, cache = {}) {
  if (cache[produkId] !== undefined) return cache[produkId];
  const [rows] = await connection.query(
    `SELECT p.nama AS produk_nama, k.nama AS kategori_nama FROM produk p LEFT JOIN kategori k ON p.kategori_id = k.id WHERE p.id = ?`,
    [produkId]
  );
  if (!rows.length) { cache[produkId] = false; return false; }
  const isBaru = isProdukGalonFisikFromNames(rows[0].kategori_nama, rows[0].produk_nama);
  cache[produkId] = isBaru;
  return isBaru;
}

async function applyGalonFromTransaksiItems(connection, { items, pelangganId, crewId, crewNama, transaksiId }) {
  const cache = {};
  let galonBaruTerjual = 0, galonKembali = 0, galonPinjamManual = 0;
  for (const item of items) {
    if (await isProdukGalonBaru(connection, item.produkId, cache)) galonBaruTerjual += item.jumlah;
    galonKembali += parseInt(item.galonKembali, 10) || 0;
    galonPinjamManual += parseInt(item.galonPinjam, 10) || 0;
  }
  const pinjamTotal = galonBaruTerjual + galonPinjamManual;
  if (pinjamTotal === 0 && galonKembali === 0) return;
  const catatan = `Transaksi ${transaksiId}`;
  const metaBase = { catatan, crewId, crewNama };
  if (galonKembali > 0) {
    if (!pelangganId) throw new Error('Pelanggan wajib dipilih untuk pencatatan galon kembali');
    await applyGalonMutasiWithConnection(connection, 'kembali', galonKembali, { ...metaBase, pelangganId });
  }
  if (pinjamTotal > 0) {
    if (!pelangganId) throw new Error('Pelanggan wajib dipilih untuk penjualan galon baru');
    const pinjam = await applyGalonMutasiWithConnection(connection, 'pinjam', pinjamTotal, { ...metaBase, pelangganId });
    if (pinjam.jumlah < pinjamTotal) throw new Error(`Stok galon di depo tidak mencukupi (tersedia: ${pinjam.jumlah}, dibutuhkan: ${pinjamTotal})`);
  }
}

module.exports = {
  setPool, getGalonSummary, getGalonMutasiColumns, resetGalonMutasiColumnCache,
  insertGalonMutasiRow, applyGalonMutasiWithConnection, applyGalonMutasi,
  isProdukGalonBaru, isProdukGalonFisikFromNames, applyGalonFromTransaksiItems,
};
