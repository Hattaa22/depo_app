const express = require('express');
const router = express.Router();
const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
const { getPool } = require('../config/db');
const { authMiddleware } = require('../middleware/auth');
const { getJwtSecret } = require('../config/env');
const { snakeToCamel } = require('../helpers/mappers');
const { issueTokens, userDataFrom } = require('../helpers/auth');

const failedLogins = new Map();
const MAX_LOGIN_ATTEMPTS = parseInt(process.env.MAX_LOGIN_ATTEMPTS, 10) || 5;
const LOGIN_LOCK_MS = parseInt(process.env.LOGIN_LOCK_MS, 10) || 15 * 60 * 1000;

function loginKey(req, role, username) {
  return `${req.ip}|${role}|${String(username || '').trim().toLowerCase()}`;
}

function isLoginLocked(key) {
  const entry = failedLogins.get(key);
  if (!entry) return false;
  if (Date.now() > entry.lockedUntil) {
    failedLogins.delete(key);
    return false;
  }
  return entry.count >= MAX_LOGIN_ATTEMPTS;
}

function recordFailedLogin(key) {
  const current = failedLogins.get(key) || { count: 0, lockedUntil: 0 };
  const next = {
    count: current.count + 1,
    lockedUntil: Date.now() + LOGIN_LOCK_MS,
  };
  failedLogins.set(key, next);
}

function loginHandler(role) {
  return async (req, res) => {
    const { username, password, pin } = req.body || {};
    const key = loginKey(req, role, username);
    if (isLoginLocked(key)) {
      return res.status(429).json({ message: 'Terlalu banyak percobaan login. Coba lagi nanti.' });
    }

    try {
      const u = (username || '').trim().toLowerCase();
      let rows = [];
      const pool = getPool();
      
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
        recordFailedLogin(key);
        return res.status(401).json({ message: role === 'crew' ? 'PIN crew salah' : 'Username atau password salah' });
      }
      
      const user = snakeToCamel(rows[0]);
      if (!(role === 'crew' && !u)) {
        const secret = role === 'crew' ? String(pin ?? password ?? '') : String(password ?? '');
        const hash = role === 'crew' ? (rows[0].pin_hash || rows[0].password_hash) : rows[0].password_hash;
        if (!bcrypt.compareSync(secret, hash)) {
          recordFailedLogin(key);
          return res.status(401).json({ message: role === 'crew' ? 'PIN crew salah' : 'Username atau password salah' });
        }
      }
      
      const { accessToken, refreshToken } = issueTokens(user);
      
      await pool.query(
        'INSERT INTO refresh_tokens (token, user_id) VALUES (?, ?)',
        [refreshToken, user.id]
      );
      failedLogins.delete(key);
      
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

router.post('/login/crew', loginHandler('crew'));
router.post('/login/manager', loginHandler('manager'));

router.post('/logout', authMiddleware, async (req, res) => {
  const { refresh_token } = req.body || {};
  try {
    if (refresh_token) {
      await getPool().query('DELETE FROM refresh_tokens WHERE token = ?', [refresh_token]);
    }
    res.json({ message: 'Logout berhasil' });
  } catch (err) {
    console.error(err);
    res.status(500).json({ message: 'Internal Server Error' });
  }
});

router.post('/refresh', async (req, res) => {
  const { refresh_token: refreshToken } = req.body || {};
  if (!refreshToken) {
    return res.status(400).json({ message: 'refresh_token wajib' });
  }
  try {
    const payload = jwt.verify(refreshToken, getJwtSecret());
    if (payload.type !== 'refresh') throw new Error('invalid');
    
    const pool = getPool();
    const [tokenRows] = await pool.query('SELECT * FROM refresh_tokens WHERE token = ?', [refreshToken]);
    if (tokenRows.length === 0) {
      return res.status(401).json({ message: 'Refresh token tidak valid' });
    }
    
    const [userRows] = await pool.query(
      'SELECT * FROM users WHERE id = ? AND is_aktif = 1',
      [payload.sub]
    );
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

router.put('/change-password', authMiddleware, async (req, res) => {
  try {
    const { passwordLama, passwordBaru } = req.body || {};
    if (!passwordLama || !passwordBaru) {
      return res.status(400).json({ message: 'Password lama dan password baru wajib diisi' });
    }
    if (passwordBaru.length < 6) {
      return res.status(400).json({ message: 'Password baru minimal 6 karakter' });
    }

    const pool = getPool();
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

module.exports = router;
