const express = require('express');
const router = express.Router();
const bcrypt = require('bcryptjs');
const { v4: uuidv4 } = require('uuid');
const { getPool } = require('../config/db');
const { authMiddleware, managerOnly } = require('../middleware/auth');
const { snakeToCamel, paginate } = require('../helpers/mappers');
const { crewResponseFrom } = require('../helpers/auth');

router.get('/', authMiddleware, async (req, res) => {
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
    
    const pool = getPool();
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

router.get('/:id', authMiddleware, async (req, res) => {
  try {
    const [rows] = await getPool().query('SELECT * FROM users WHERE id = ? AND role = "crew"', [req.params.id]);
    if (rows.length === 0) return res.status(404).json({ message: 'Crew tidak ditemukan' });
    res.json(crewResponseFrom(snakeToCamel(rows[0])));
  } catch (err) {
    console.error(err);
    res.status(500).json({ message: 'Internal Server Error' });
  }
});

router.post('/', authMiddleware, managerOnly, async (req, res) => {
  try {
    const { username, nama, noHp, alamat, isAktif, password, pin } = req.body || {};
    const u = String(username || '').trim();
    const n = String(nama || u).trim();
    if (!u) return res.status(400).json({ message: 'Username wajib diisi' });
    if (!n) return res.status(400).json({ message: 'Nama wajib diisi' });
    
    const pool = getPool();
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

router.put('/:id', authMiddleware, managerOnly, async (req, res) => {
  try {
    const pool = getPool();
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

router.delete('/:id', authMiddleware, managerOnly, async (req, res) => {
  try {
    const pool = getPool();
    const [rows] = await pool.query('SELECT id FROM users WHERE id = ? AND role = "crew"', [req.params.id]);
    if (rows.length === 0) return res.status(404).json({ message: 'Crew tidak ditemukan' });
    await pool.query('DELETE FROM users WHERE id = ?', [req.params.id]);
    res.status(204).send();
  } catch (err) {
    console.error(err);
    res.status(500).json({ message: 'Internal Server Error' });
  }
});

module.exports = router;
