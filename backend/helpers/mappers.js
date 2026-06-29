/**
 * helpers/mappers.js
 * Konversi snake_case ↔ camelCase dan konstanta tipe data.
 */

const { isProduction } = require('../config/env');

const DECIMAL_KEYS = new Set([
  'harga', 'nominal', 'totalHarga', 'bayar', 'kembalian',
  'hargaSatuan', 'subtotal', 'jumlah', 'totalTransaksi'
]);

function snakeToCamel(obj) {
  if (obj === null || obj === undefined) return obj;
  if (obj instanceof Date) return obj.toISOString();
  if (Array.isArray(obj)) return obj.map(snakeToCamel);
  if (typeof obj === 'object') {
    if (obj.constructor && obj.constructor.name === 'Buffer') return obj;
    return Object.keys(obj).reduce((acc, key) => {
      const camelKey = key.replace(/_([a-z0-9])/g, (g) => g[1].toUpperCase());
      let val = obj[key];

      if (val instanceof Date) { acc[camelKey] = val.toISOString(); return acc; }
      if (typeof val === 'object' && val !== null && val.type === 'Buffer') val = val.data[0];
      if (key === 'is_aktif' || key === 'is_system' || key === 'is_pusat') val = val === 1 || val === true;
      if (key === 'tanggal' && val instanceof Date) {
        const y = val.getFullYear();
        const m = String(val.getMonth() + 1).padStart(2, '0');
        const d = String(val.getDate()).padStart(2, '0');
        val = `${y}-${m}-${d}`;
      }
      if (DECIMAL_KEYS.has(camelKey) && typeof val === 'string') val = parseFloat(val);
      acc[camelKey] = snakeToCamel(val);
      return acc;
    }, {});
  }
  return obj;
}

function camelToSnake(obj) {
  if (obj === null || obj === undefined) return obj;
  if (obj instanceof Date) return obj.toISOString().slice(0, 19).replace('T', ' ');
  if (Array.isArray(obj)) return obj.map(camelToSnake);
  if (typeof obj === 'object') {
    return Object.keys(obj).reduce((acc, key) => {
      const snakeKey = key.replace(/[A-Z0-9]/g, (letter) => `_${letter.toLowerCase()}`);
      acc[snakeKey] = camelToSnake(obj[key]);
      return acc;
    }, {});
  }
  return obj;
}

function paginate(list, page, limit, totalCount) {
  const p = Math.max(1, parseInt(page, 10) || 1);
  const l = Math.max(1, Math.min(100, parseInt(limit, 10) || 20));
  return {
    data: list,
    total: totalCount,
    page: p,
    limit: l,
    totalPages: Math.max(1, Math.ceil(totalCount / l)),
  };
}

function sqlErrorMessage(err, fallback = 'Internal Server Error') {
  if (isProduction) return fallback;
  if (err && err.code === 'ER_BAD_FIELD_ERROR')
    return `Kolom database tidak ditemukan (${err.sqlMessage || 'unknown column'}). Restart backend setelah migrasi.`;
  if (err && err.code === 'ER_NO_SUCH_TABLE')
    return `Tabel database tidak ditemukan (${err.sqlMessage || err.message}). Restart backend.`;
  if (err && err.code === 'ER_NO_DEFAULT_FOR_FIELD')
    return `Kolom database wajib diisi (${err.sqlMessage || err.message}). Restart backend agar migrasi galon jalan.`;
  return err?.message || fallback;
}

module.exports = { snakeToCamel, camelToSnake, DECIMAL_KEYS, paginate, sqlErrorMessage };
