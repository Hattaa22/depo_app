const express = require('express');
const router = express.Router();
const { v4: uuidv4 } = require('uuid');
const { getPool } = require('../config/db');
const { authMiddleware, managerOnly } = require('../middleware/auth');
const { snakeToCamel } = require('../helpers/mappers');

router.get('/', authMiddleware, async (req, res) => {
  try {
    const pool = getPool();
    const [rows] = await pool.query('SELECT * FROM kategori WHERE is_aktif = 1 ORDER BY nama ASC');
    res.json(snakeToCamel(rows));
  } catch (err) {
    console.error(err);
    res.status(500).json({ message: 'Internal Server Error' });
  }
});

router.post('/', authMiddleware, managerOnly, async (req, res) => {
  try {
    const { nama, deskripsi, tipe, ikon, isSystem } = req.body || {};
    if (!nama || !String(nama).trim()) return res.status(400).json({ message: 'Nama kategori wajib diisi' });
    
    const id = uuidv4();
    const now = new Date().toISOString().slice(0, 19).replace('T', ' ');
    const pool = getPool();
    
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

router.put('/:id', authMiddleware, managerOnly, async (req, res) => {
  try {
    const pool = getPool();
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

router.delete('/:id', authMiddleware, managerOnly, async (req, res) => {
  try {
    const pool = getPool();
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

module.exports = router;
