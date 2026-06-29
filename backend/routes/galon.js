const express = require('express');
const router = express.Router();
const { v4: uuidv4 } = require('uuid');
const { getPool } = require('../config/db');
const { authMiddleware } = require('../middleware/auth');
const { snakeToCamel, paginate, sqlErrorMessage } = require('../helpers/mappers');
const { getGalonSummary, applyGalonMutasi, insertGalonMutasiRow } = require('../helpers/galon');

router.get('/ringkasan', authMiddleware, async (req, res) => {
  try {
    const summary = await getGalonSummary();
    res.json(summary);
  } catch (err) {
    console.error(err);
    res.status(500).json({ message: sqlErrorMessage(err) });
  }
});

router.get('/mutasi', authMiddleware, async (req, res) => {
  try {
    const limit = Math.min(100, parseInt(req.query.limit, 10) || 30);
    const pool = getPool();
    const [rows] = await pool.query('SELECT * FROM galon_mutasi ORDER BY created_at DESC LIMIT ?', [limit]);
    
    const mapped = rows.map((r) => {
      const item = snakeToCamel(r);
      try {
        item.kodeGalon = JSON.parse(r.kode_galon);
      } catch (e) {
        item.kodeGalon = [];
      }
      return item;
    });
    
    res.json(mapped);
  } catch (err) {
    console.error(err);
    res.status(500).json({ message: sqlErrorMessage(err) });
  }
});

router.put('/pinjam', authMiddleware, async (req, res) => {
  try {
    const body = req.body || {};
    const result = await applyGalonMutasi('pinjam', body.jumlah, {
      pelangganId: body.pelangganId,
      catatan: body.catatan,
      crewId: req.user.sub,
      crewNama: req.user.username,
      tanggal: body.tanggal || null,
    });
    if (result.jumlah === 0) {
      return res.status(400).json({ message: 'Tidak ada galon tersedia untuk dipinjam' });
    }
    res.json(result);
  } catch (err) {
    console.error('[PINJAM ERROR]', err);
    res.status(500).json({ message: sqlErrorMessage(err) });
  }
});

router.put('/kembali', authMiddleware, async (req, res) => {
  try {
    const body = req.body || {};
    const result = await applyGalonMutasi('kembali', body.jumlah, {
      pelangganId: body.pelangganId,
      catatan: body.catatan,
      crewId: req.user.sub,
      crewNama: req.user.username,
      tanggal: body.tanggal || null,
    });
    if (result.jumlah === 0) {
      return res.status(400).json({ message: 'Tidak ada galon dipinjam untuk dikembalikan' });
    }
    res.json(result);
  } catch (err) {
    console.error('[KEMBALI ERROR]', err);
    res.status(500).json({ message: sqlErrorMessage(err) });
  }
});

router.get('/', authMiddleware, async (req, res) => {
  try {
    const { status, page, limit } = req.query;
    const p = Math.max(1, parseInt(page, 10) || 1);
    const l = Math.max(1, Math.min(100, parseInt(limit, 10) || 20));
    const offset = (p - 1) * l;
    
    let query = `SELECT g.*, p.nama as pelanggan_nama, p.no_hp as pelanggan_no_hp, p.alamat as pelanggan_alamat 
                 FROM galon g 
                 LEFT JOIN pelanggan p ON g.pelanggan_id = p.id`;
    let countQuery = 'SELECT COUNT(*) as total FROM galon';
    const params = [];
    const countParams = [];
    
    if (status) {
      query += ' WHERE g.status = ?';
      countQuery += ' WHERE status = ?';
      params.push(status);
      countParams.push(status);
    }
    
    query += ' ORDER BY g.kode_galon ASC LIMIT ? OFFSET ?';
    params.push(l, offset);
    
    const pool = getPool();
    const [rows] = await pool.query(query, params);
    const [countRows] = await pool.query(countQuery, countParams);
    
    const totalCount = countRows[0].total;
    res.json(paginate(snakeToCamel(rows), page, limit, totalCount));
  } catch (err) {
    console.error(err);
    res.status(500).json({ message: sqlErrorMessage(err) });
  }
});

router.post('/', authMiddleware, async (req, res) => {
  try {
    const { kodeGalon, merek, jenis, status, pelangganId, catatan, jumlah } = req.body || {};
    const now = new Date().toISOString().slice(0, 19).replace('T', ' ');
    const count = Math.max(1, parseInt(jumlah) || 1);
    const createdGalons = [];
    const tanggalPinjam = status === 'dipinjam' ? now : null;
    const pool = getPool();
    
    for (let i = 0; i < count; i++) {
      const id = uuidv4();
      const code = `G-${Date.now()}-${i + 1}`;
      await pool.query(
        `INSERT INTO galon (id, kode_galon, merek, jenis, status, pelanggan_id, tanggal_pinjam, catatan, created_at)
         VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)`,
        [id, code, 'Depo', jenis || 'isi', status || 'tersedia', pelangganId || null, tanggalPinjam, catatan || null, now]
      );
      const [inserted] = await pool.query('SELECT * FROM galon WHERE id = ?', [id]);
      createdGalons.push(snakeToCamel(inserted[0]));
    }
    
    res.status(201).json({
      ...createdGalons[0],
      createdCount: count,
      galons: count > 1 ? createdGalons : undefined
    });
  } catch (err) {
    console.error('[GALON POST ERROR]', err);
    res.status(500).json({ message: sqlErrorMessage(err) });
  }
});

router.put('/:id', authMiddleware, async (req, res) => {
  try {
    if (req.params.id === 'pinjam' || req.params.id === 'kembali') {
      return res.status(400).json({ message: 'Gunakan /galon/pinjam atau /galon/kembali' });
    }
    const pool = getPool();
    const [rows] = await pool.query('SELECT * FROM galon WHERE id = ?', [req.params.id]);
    if (rows.length === 0) return res.status(404).json({ message: 'Galon tidak ditemukan' });
    
    const body = req.body || {};
    const current = rows[0];
    const prevStatus = current.status;
    const now = new Date().toISOString().slice(0, 19).replace('T', ' ');
    
    let tanggalPinjam = current.tanggal_pinjam;
    if (body.status === 'dipinjam' && prevStatus !== 'dipinjam') {
      tanggalPinjam = now;
    } else if (body.status && body.status !== 'dipinjam') {
      tanggalPinjam = null;
    }
    
    await pool.query(
      `UPDATE galon SET kode_galon = ?, merek = ?, jenis = ?, status = ?, pelanggan_id = ?, tanggal_pinjam = ?, catatan = ?, updated_at = ? WHERE id = ?`,
      [
        body.kodeGalon ?? current.kode_galon,
        body.merek ?? current.merek,
        body.jenis ?? current.jenis,
        body.status ?? current.status,
        body.pelangganId !== undefined ? body.pelangganId : current.pelanggan_id,
        tanggalPinjam,
        body.catatan !== undefined ? body.catatan : current.catatan,
        now,
        req.params.id
      ]
    );
    
    if (body.status && body.status !== prevStatus) {
      await insertGalonMutasiRow(pool, {
        id: uuidv4(),
        galonId: req.params.id,
        aksi: 'ubah_status',
        jumlah: 1,
        kodeGalon: JSON.stringify([body.kodeGalon ?? current.kode_galon]),
        statusDari: prevStatus,
        statusKe: body.status,
        crewId: req.user.sub,
        crewNama: req.user.username,
        createdAt: now,
      });
    }
    
    const [updated] = await pool.query('SELECT * FROM galon WHERE id = ?', [req.params.id]);
    res.json(snakeToCamel(updated[0]));
  } catch (err) {
    console.error(err);
    res.status(500).json({ message: sqlErrorMessage(err) });
  }
});

module.exports = router;
