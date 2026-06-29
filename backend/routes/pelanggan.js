const express = require('express');
const router = express.Router();
const { v4: uuidv4 } = require('uuid');
const { getPool } = require('../config/db');
const { authMiddleware } = require('../middleware/auth');
const { snakeToCamel, paginate } = require('../helpers/mappers');

router.get('/', authMiddleware, async (req, res) => {
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
    
    const pool = getPool();
    const [rows] = await pool.query(query, params);
    const [countRows] = await pool.query(countQuery, countParams);
    
    const totalCount = countRows[0].total;
    res.json(paginate(snakeToCamel(rows), page, limit, totalCount));
  } catch (err) {
    console.error(err);
    res.status(500).json({ message: 'Internal Server Error' });
  }
});

router.get('/:id', authMiddleware, async (req, res) => {
  try {
    const pool = getPool();
    const [rows] = await pool.query('SELECT * FROM pelanggan WHERE id = ?', [req.params.id]);
    if (rows.length === 0) return res.status(404).json({ message: 'Pelanggan tidak ditemukan' });
    res.json(snakeToCamel(rows[0]));
  } catch (err) {
    console.error(err);
    res.status(500).json({ message: 'Internal Server Error' });
  }
});

router.post('/', authMiddleware, async (req, res) => {
  try {
    const { nama, noHp, alamat, totalGalonPinjam, catatan, isAktif } = req.body || {};
    const n = String(nama || '').trim();
    if (!n) return res.status(400).json({ message: 'Nama pelanggan wajib diisi' });
    
    const id = uuidv4();
    const now = new Date().toISOString().slice(0, 19).replace('T', ' ');
    const pool = getPool();
    
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

router.put('/:id', authMiddleware, async (req, res) => {
  try {
    const pool = getPool();
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

router.delete('/:id', authMiddleware, async (req, res) => {
  try {
    const pool = getPool();
    const [rows] = await pool.query('SELECT id FROM pelanggan WHERE id = ?', [req.params.id]);
    if (rows.length === 0) return res.status(404).json({ message: 'Pelanggan tidak ditemukan' });
    await pool.query('DELETE FROM pelanggan WHERE id = ?', [req.params.id]);
    res.status(204).send();
  } catch (err) {
    console.error(err);
    res.status(500).json({ message: 'Internal Server Error' });
  }
});

module.exports = router;
