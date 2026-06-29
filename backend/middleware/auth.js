/**
 * middleware/auth.js
 * JWT auth middleware dan role guard.
 */
const jwt = require('jsonwebtoken');
const { getJwtSecret } = require('../config/env');

function authMiddleware(req, res, next) {
  const header = req.headers.authorization || '';
  const token = header.startsWith('Bearer ') ? header.slice(7) : null;
  if (!token) return res.status(401).json({ message: 'Token tidak ditemukan' });
  try {
    req.user = jwt.verify(token, getJwtSecret());
    next();
  } catch {
    return res.status(401).json({ message: 'Token tidak valid' });
  }
}

function managerOnly(req, res, next) {
  if (req.user?.role !== 'manager')
    return res.status(403).json({ message: 'Akses khusus manager' });
  next();
}

module.exports = { authMiddleware, managerOnly };
