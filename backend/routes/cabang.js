const express = require('express');
const router = express.Router();
const { v4: uuidv4 } = require('uuid');
const { getPool } = require('../config/db');
const { authMiddleware, managerOnly } = require('../middleware/auth');
const { snakeToCamel, sqlErrorMessage } = require('../helpers/mappers');

router.get('/', authMiddleware, managerOnly, async (req, res) => {
  try {
    const showAll = req.query.all === '1' || req.query.all === 'true';
    let query = 'SELECT * FROM cabang';
    if (!showAll) query += ' WHERE is_aktif = 1';
    query += ' ORDER BY is_pusat DESC, nama ASC';
    const pool = getPool();
    const [rows] = await pool.query(query);
    res.json(rows.map((r) => snakeToCamel(r)));
  } catch (err) {
    console.error(err);
    res.status(500).json({ message: sqlErrorMessage(err) });
  }
});

router.get('/:id', authMiddleware, managerOnly, async (req, res) => {
  try {
    const pool = getPool();
    const [rows] = await pool.query('SELECT * FROM cabang WHERE id = ?', [req.params.id]);
    if (rows.length === 0) return res.status(404).json({ message: 'Cabang tidak ditemukan' });
    res.json(snakeToCamel(rows[0]));
  } catch (err) {
    console.error(err);
    res.status(500).json({ message: sqlErrorMessage(err) });
  }
});

router.post('/', authMiddleware, managerOnly, async (req, res) => {
  try {
    const body = req.body || {};
    const nama = String(body.nama || '').trim();
    if (!nama) return res.status(400).json({ message: 'Nama cabang wajib diisi' });

    const id = uuidv4();
    const now = new Date().toISOString().slice(0, 19).replace('T', ' ');
    const isPusat = body.isPusat ? 1 : 0;
    const pool = getPool();

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

router.put('/:id', authMiddleware, managerOnly, async (req, res) => {
  try {
    const pool = getPool();
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

router.delete('/:id', authMiddleware, managerOnly, async (req, res) => {
  try {
    const pool = getPool();
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

module.exports = router;
