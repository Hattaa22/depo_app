const express = require('express');
const router = express.Router();
const { v4: uuidv4 } = require('uuid');
const { getPool } = require('../config/db');
const { authMiddleware, managerOnly } = require('../middleware/auth');
const { snakeToCamel, paginate } = require('../helpers/mappers');

async function enrichProdukSql(conn, produkRow) {
  const [katRows] = await conn.query('SELECT * FROM kategori WHERE id = ?', [produkRow.kategori_id]);
  const p = snakeToCamel(produkRow);
  p.kategori = katRows.length > 0 ? snakeToCamel(katRows[0]) : null;
  return p;
}

function mapProdukWithKategori(row) {
  const produk = snakeToCamel({
    id: row.id,
    nama: row.nama,
    kategori_id: row.kategori_id,
    harga: row.harga,
    stok: row.stok,
    deskripsi: row.deskripsi,
    gambar_url: row.gambar_url,
    is_aktif: row.is_aktif,
    created_at: row.created_at,
    updated_at: row.updated_at,
  });

  produk.kategori = row.kategori_nama ? snakeToCamel({
    id: row.kategori_id,
    nama: row.kategori_nama,
    deskripsi: row.kategori_deskripsi,
    tipe: row.kategori_tipe,
    ikon: row.kategori_ikon,
    is_system: row.kategori_is_system,
    is_aktif: row.kategori_is_aktif,
    created_at: row.kategori_created_at,
  }) : null;

  return produk;
}

router.get('/', authMiddleware, async (req, res) => {
  try {
    const { kategoriId, search, page, limit } = req.query;
    const p = Math.max(1, parseInt(page, 10) || 1);
    const l = Math.max(1, Math.min(100, parseInt(limit, 10) || 20));
    const offset = (p - 1) * l;
    
    let query = `
      SELECT p.*,
             k.nama AS kategori_nama,
             k.deskripsi AS kategori_deskripsi,
             k.tipe AS kategori_tipe,
             k.ikon AS kategori_ikon,
             k.is_system AS kategori_is_system,
             k.is_aktif AS kategori_is_aktif,
             k.created_at AS kategori_created_at
      FROM produk p
      LEFT JOIN kategori k ON k.id = p.kategori_id
      WHERE p.is_aktif = 1`;
    let countQuery = 'SELECT COUNT(*) as total FROM produk WHERE is_aktif = 1';
    const params = [];
    const countParams = [];
    
    if (kategoriId) {
      query += ' AND p.kategori_id = ?';
      countQuery += ' AND kategori_id = ?';
      params.push(kategoriId);
      countParams.push(kategoriId);
    }
    
    if (search) {
      const s = `%${search}%`;
      query += ' AND LOWER(p.nama) LIKE ?';
      countQuery += ' AND LOWER(nama) LIKE ?';
      params.push(s);
      countParams.push(s);
    }
    
    query += ' ORDER BY p.nama ASC LIMIT ? OFFSET ?';
    params.push(l, offset);
    
    const pool = getPool();
    const [rows] = await pool.query(query, params);
    const [countRows] = await pool.query(countQuery, countParams);
    
    const totalCount = countRows[0].total;
    
    const enrichedList = rows.map(mapProdukWithKategori);
    
    res.json(paginate(enrichedList, page, limit, totalCount));
  } catch (err) {
    console.error(err);
    res.status(500).json({ message: 'Internal Server Error' });
  }
});

router.get('/:id', authMiddleware, async (req, res) => {
  try {
    const pool = getPool();
    const [rows] = await pool.query('SELECT * FROM produk WHERE id = ?', [req.params.id]);
    if (rows.length === 0) return res.status(404).json({ message: 'Produk tidak ditemukan' });
    const p = await enrichProdukSql(pool, rows[0]);
    res.json(p);
  } catch (err) {
    console.error(err);
    res.status(500).json({ message: 'Internal Server Error' });
  }
});

router.post('/', authMiddleware, managerOnly, async (req, res) => {
  try {
    const { nama, kategoriId, harga, stok, deskripsi, gambarUrl, isAktif } = req.body || {};
    if (!nama || !String(nama).trim()) return res.status(400).json({ message: 'Nama produk wajib diisi' });
    
    const pool = getPool();
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

router.put('/:id', authMiddleware, managerOnly, async (req, res) => {
  try {
    const pool = getPool();
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

router.delete('/:id', authMiddleware, managerOnly, async (req, res) => {
  try {
    const pool = getPool();
    const [rows] = await pool.query('SELECT id FROM produk WHERE id = ?', [req.params.id]);
    if (rows.length === 0) return res.status(404).json({ message: 'Produk tidak ditemukan' });
    
    await pool.query('UPDATE produk SET is_aktif = 0 WHERE id = ?', [req.params.id]);
    res.status(204).send();
  } catch (err) {
    console.error(err);
    res.status(500).json({ message: 'Internal Server Error' });
  }
});

module.exports = router;
module.exports.enrichProdukSql = enrichProdukSql; // Exported for use in transaksi
