const express = require('express');
const router = express.Router();
const { v4: uuidv4 } = require('uuid');
const { getPool } = require('../config/db');
const { authMiddleware, managerOnly } = require('../middleware/auth');
const { snakeToCamel } = require('../helpers/mappers');

router.get('/', authMiddleware, async (req, res) => {
  try {
    const pool = getPool();
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

router.post('/', authMiddleware, managerOnly, async (req, res) => {
  try {
    const { kategoriId, nominal, keterangan, tanggal } = req.body || {};
    if (!kategoriId) return res.status(400).json({ message: 'kategoriId wajib diisi' });
    if (!nominal || isNaN(Number(nominal)) || Number(nominal) <= 0) {
      return res.status(400).json({ message: 'nominal harus lebih dari 0' });
    }
    
    const pool = getPool();
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

router.delete('/:id', authMiddleware, managerOnly, async (req, res) => {
  try {
    const pool = getPool();
    const [rows] = await pool.query('SELECT id FROM pengeluaran WHERE id = ?', [req.params.id]);
    if (rows.length === 0) return res.status(404).json({ message: 'Catatan pengeluaran tidak ditemukan' });
    
    await pool.query('DELETE FROM pengeluaran WHERE id = ?', [req.params.id]);
    res.json({ message: 'Catatan pengeluaran berhasil dihapus' });
  } catch (err) {
    console.error(err);
    res.status(500).json({ message: 'Internal Server Error' });
  }
});

module.exports = router;
