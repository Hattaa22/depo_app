/**
 * helpers/auth.js
 * Helpers for auth and user formatting
 */
const jwt = require('jsonwebtoken');
const { getJwtSecret } = require('../config/env');

function issueTokens(user) {
  const payload = { sub: user.id, role: user.role, username: user.username };
  const accessToken = jwt.sign(payload, getJwtSecret(), { expiresIn: '8h' });
  const refreshToken = jwt.sign({ ...payload, type: 'refresh' }, getJwtSecret(), { expiresIn: '7d' });
  return { accessToken, refreshToken };
}

function userDataFrom(user) {
  const data = {
    id: user.id,
    nama: user.nama,
    username: user.username,
    noHp: user.noHp || '',
    alamat: user.alamat || '',
    isAktif: user.isAktif !== false,
  };
  if (user.email) data.email = user.email;
  return data;
}

function crewResponseFrom(user) {
  return {
    id: user.id,
    nama: user.nama,
    username: user.username,
    noHp: user.noHp || '',
    alamat: user.alamat || '',
    isAktif: user.isAktif !== false,
    fotoUrl: user.fotoUrl || null,
    createdAt: user.createdAt,
    updatedAt: user.updatedAt || null,
  };
}

module.exports = {
  issueTokens,
  userDataFrom,
  crewResponseFrom,
};
