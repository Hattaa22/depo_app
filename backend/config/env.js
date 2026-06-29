const crypto = require('crypto');

const NODE_ENV = process.env.NODE_ENV || 'development';
const isProduction = NODE_ENV === 'production';

function requireSecret(name, { minLength = 32 } = {}) {
  const value = (process.env[name] || '').trim();
  if (!value) {
    throw new Error(`${name} wajib diisi`);
  }
  if (value.length < minLength) {
    throw new Error(`${name} minimal ${minLength} karakter`);
  }
  return value;
}

function getJwtSecret() {
  return requireSecret('JWT_SECRET');
}

function corsOrigins() {
  return (process.env.CORS_ORIGINS || '')
    .split(',')
    .map((origin) => origin.trim())
    .filter(Boolean);
}

function validateEnv() {
  getJwtSecret();

  if (isProduction) {
    if (corsOrigins().length === 0) {
      throw new Error('CORS_ORIGINS wajib diisi di production');
    }

    const dbPassword = process.env.DB_PASSWORD;
    if (dbPassword === undefined || dbPassword === '') {
      throw new Error('DB_PASSWORD wajib diisi di production');
    }

    if (String(process.env.ALLOW_QRIS_SIMULATION || 'false') === 'true') {
      throw new Error('ALLOW_QRIS_SIMULATION harus false di production');
    }

    if (String(process.env.MIDTRANS_IS_PRODUCTION || 'false') === 'true') {
      requireSecret('MIDTRANS_SERVER_KEY', { minLength: 20 });
    }
  }
}

function makeExampleSecret() {
  return crypto.randomBytes(32).toString('hex');
}

module.exports = {
  NODE_ENV,
  isProduction,
  corsOrigins,
  getJwtSecret,
  makeExampleSecret,
  validateEnv,
};
