const express = require('express');
const router = express.Router();
const { v4: uuidv4 } = require('uuid');
const { getPool } = require('../config/db');
const { authMiddleware } = require('../middleware/auth');
const { snakeToCamel, paginate, sqlErrorMessage } = require('../helpers/mappers');
const { applyGalonFromTransaksiItems } = require('../helpers/galon');

async function enrichTransaksiSql(conn, tRow) {
  const [result] = await enrichTransaksiListSql(conn, [tRow]);
  return result;
}

function inClause(values) {
  return values.map(() => '?').join(',');
}

async function enrichTransaksiListSql(conn, rows) {
  if (rows.length === 0) return [];

  const trxIds = rows.map((row) => row.id);
  const pelangganIds = [...new Set(rows.map((row) => row.pelanggan_id).filter(Boolean))];
  const crewIds = [...new Set(rows.flatMap((row) => [row.crew_id, row.pengirim_crew_id]).filter(Boolean))];

  const pelangganMap = new Map();
  if (pelangganIds.length > 0) {
    const [pelRows] = await conn.query(
      `SELECT * FROM pelanggan WHERE id IN (${inClause(pelangganIds)})`,
      pelangganIds
    );
    pelRows.forEach((row) => pelangganMap.set(row.id, snakeToCamel(row)));
  }

  const crewMap = new Map();
  if (crewIds.length > 0) {
    const [crewRows] = await conn.query(
      `SELECT id, nama, username, no_hp, alamat, is_aktif, created_at FROM users WHERE id IN (${inClause(crewIds)})`,
      crewIds
    );
    crewRows.forEach((row) => crewMap.set(row.id, snakeToCamel(row)));
  }

  const [itemRows] = await conn.query(
    `SELECT
       ti.*,
       p.id AS produk_id_full,
       p.nama AS produk_nama,
       p.kategori_id AS produk_kategori_id,
       p.harga AS produk_harga,
       p.stok AS produk_stok,
       p.deskripsi AS produk_deskripsi,
       p.gambar_url AS produk_gambar_url,
       p.is_aktif AS produk_is_aktif,
       p.created_at AS produk_created_at,
       p.updated_at AS produk_updated_at,
       k.id AS kategori_id_full,
       k.nama AS kategori_nama,
       k.deskripsi AS kategori_deskripsi,
       k.tipe AS kategori_tipe,
       k.ikon AS kategori_ikon,
       k.is_system AS kategori_is_system,
       k.is_aktif AS kategori_is_aktif,
       k.created_at AS kategori_created_at
     FROM transaksi_items ti
     JOIN produk p ON p.id = ti.produk_id
     LEFT JOIN kategori k ON k.id = p.kategori_id
     WHERE ti.transaksi_id IN (${inClause(trxIds)})`,
    trxIds
  );

  const itemsByTransaksi = new Map();
  for (const row of itemRows) {
    const item = snakeToCamel({
      id: row.id,
      transaksi_id: row.transaksi_id,
      produk_id: row.produk_id,
      jumlah: row.jumlah,
      harga_satuan: row.harga_satuan,
      subtotal: row.subtotal,
      galon_pinjam: row.galon_pinjam,
      galon_kembali: row.galon_kembali,
    });

    item.produk = snakeToCamel({
      id: row.produk_id_full,
      nama: row.produk_nama,
      kategori_id: row.produk_kategori_id,
      harga: row.produk_harga,
      stok: row.produk_stok,
      deskripsi: row.produk_deskripsi,
      gambar_url: row.produk_gambar_url,
      is_aktif: row.produk_is_aktif,
      created_at: row.produk_created_at,
      updated_at: row.produk_updated_at,
    });
    item.produk.kategori = row.kategori_id_full ? snakeToCamel({
      id: row.kategori_id_full,
      nama: row.kategori_nama,
      deskripsi: row.kategori_deskripsi,
      tipe: row.kategori_tipe,
      ikon: row.kategori_ikon,
      is_system: row.kategori_is_system,
      is_aktif: row.kategori_is_aktif,
      created_at: row.kategori_created_at,
    }) : null;

    const list = itemsByTransaksi.get(row.transaksi_id) || [];
    list.push(item);
    itemsByTransaksi.set(row.transaksi_id, list);
  }

  return rows.map((row) => {
    const t = snakeToCamel(row);
    t.pelanggan = pelangganMap.get(row.pelanggan_id) || null;
    t.crew = crewMap.get(row.crew_id) || null;
    t.pengirimCrew = row.pengirim_crew_id ? (crewMap.get(row.pengirim_crew_id) || null) : null;
    t.items = itemsByTransaksi.get(row.id) || [];
    return t;
  });
}

router.get('/', authMiddleware, async (req, res) => {
  try {
    const { status, crewId, tanggalMulai, tanggalAkhir, page, limit } = req.query;
    const p = Math.max(1, parseInt(page, 10) || 1);
    const l = Math.max(1, Math.min(100, parseInt(limit, 10) || 20));
    const offset = (p - 1) * l;
    
    let query = 'SELECT * FROM transaksi WHERE 1=1';
    let countQuery = 'SELECT COUNT(*) as total FROM transaksi WHERE 1=1';
    const params = [];
    const countParams = [];
    
    if (status) {
      const statuses = String(status).split(',');
      const placeholders = statuses.map(() => '?').join(',');
      query += ` AND status IN (${placeholders})`;
      countQuery += ` AND status IN (${placeholders})`;
      params.push(...statuses);
      countParams.push(...statuses);
    }
    
    if (crewId) {
      query += ' AND crew_id = ?';
      countQuery += ' AND crew_id = ?';
      params.push(crewId);
      countParams.push(crewId);
    }
    
    if (tanggalMulai) {
      query += ' AND created_at >= ?';
      countQuery += ' AND created_at >= ?';
      params.push(tanggalMulai);
      countParams.push(tanggalMulai);
    }
    
    if (tanggalAkhir) {
      query += ' AND created_at <= ?';
      countQuery += ' AND created_at <= ?';
      params.push(`${tanggalAkhir} 23:59:59`);
      countParams.push(`${tanggalAkhir} 23:59:59`);
    }
    
    query += ' ORDER BY created_at DESC LIMIT ? OFFSET ?';
    params.push(l, offset);
    
    const pool = getPool();
    const [rows] = await pool.query(query, params);
    const [countRows] = await pool.query(countQuery, countParams);
    const totalCount = countRows[0].total;
    
    const enrichedList = await enrichTransaksiListSql(pool, rows);
    
    res.json(paginate(enrichedList, page, limit, totalCount));
  } catch (err) {
    console.error(err);
    res.status(500).json({ message: 'Internal Server Error' });
  }
});

router.get('/:id', authMiddleware, async (req, res) => {
  try {
    const pool = getPool();
    const [rows] = await pool.query('SELECT * FROM transaksi WHERE id = ?', [req.params.id]);
    if (rows.length === 0) return res.status(404).json({ message: 'Transaksi tidak ditemukan' });
    const t = await enrichTransaksiSql(pool, rows[0]);
    res.json(t);
  } catch (err) {
    console.error(err);
    res.status(500).json({ message: 'Internal Server Error' });
  }
});

router.post('/', authMiddleware, async (req, res) => {
  const pool = getPool();
  const connection = await pool.getConnection();
  await connection.beginTransaction();
  try {
    const body = req.body || {};
    const crewId = body.crewId || req.user.sub;
    const itemsIn = body.items || [];
    const metode = body.metodePembayaran || 'tunai';
    const isQris = metode === 'qris';
    const now = new Date().toISOString().slice(0, 19).replace('T', ' ');
    const trxId = uuidv4();

    if (itemsIn.length === 0) {
      await connection.rollback();
      return res.status(400).json({ message: 'Transaksi harus memiliki minimal 1 item' });
    }
    if (!body.pelangganId) {
      await connection.rollback();
      return res.status(400).json({ message: 'Pelanggan wajib dipilih' });
    }
    if (!['tunai', 'qris', 'transfer'].includes(metode)) {
      await connection.rollback();
      return res.status(400).json({ message: 'Metode pembayaran tidak valid' });
    }
    
    const items = [];
    let totalHarga = 0;
    
    for (const itemIn of itemsIn) {
      const [prodRows] = await connection.query('SELECT * FROM produk WHERE id = ?', [itemIn.produkId]);
      const product = prodRows[0];
      if (!product) {
        await connection.rollback();
        return res.status(400).json({ message: `Produk dengan id ${itemIn.produkId} tidak ditemukan` });
      }
      const hargaSatuan = parseFloat(product.harga);
      const jumlah = parseInt(itemIn.jumlah, 10) || 0;
      if (jumlah <= 0) {
        await connection.rollback();
        return res.status(400).json({ message: 'Jumlah item harus lebih dari 0' });
      }
      const subtotal = hargaSatuan * jumlah;
      totalHarga += subtotal;
      
      items.push({
        id: uuidv4(),
        transaksiId: trxId,
        produkId: itemIn.produkId,
        jumlah,
        hargaSatuan,
        subtotal,
        galonPinjam: itemIn.galonPinjam || 0,
        galonKembali: itemIn.galonKembali || 0
      });
    }

    const tipePembelian = body.tipePembelian === 'dikirim' ? 'dikirim' : 'di_depo';
    const pengirimCrewId = tipePembelian === 'dikirim' ? (body.pengirimCrewId || body.crewPengirimId || null) : null;
    if (tipePembelian === 'dikirim' && !pengirimCrewId) {
      await connection.rollback();
      return res.status(400).json({ message: 'Crew pengirim wajib dipilih untuk transaksi dikirim' });
    }
    if (pengirimCrewId) {
      const [pengirimRows] = await connection.query('SELECT id FROM users WHERE id = ? AND role = "crew" AND is_aktif = 1', [pengirimCrewId]);
      if (pengirimRows.length === 0) {
        await connection.rollback();
        return res.status(400).json({ message: 'Crew pengirim tidak valid' });
      }
    }
    const jumlahGalon = items.reduce((s, i) => s + i.jumlah, 0);
    let ongkirPerGalon = 0;
    let totalOngkir = 0;
    if (tipePembelian === 'dikirim') {
      const rate = parseInt(body.ongkirPerGalon, 10);
      ongkirPerGalon = rate === 2000 ? 2000 : 1000;
      totalOngkir = ongkirPerGalon * jumlahGalon;
      totalHarga += totalOngkir;
    }
    
    const qrPaymentId = isQris ? `QR-${uuidv4()}` : null;
    
    await connection.query(
      `INSERT INTO transaksi (id, nomor_transaksi, pelanggan_id, crew_id, pengirim_crew_id, total_harga, metode_pembayaran, status, status_validasi, bayar, kembalian, qr_payment_id, catatan, tipe_pembelian, ongkir_per_galon, total_ongkir, validasi_oleh, validasi_at, created_at)
       VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, NULL, NULL, ?)`,
      [
        trxId,
        String(Date.now()),
        body.pelangganId || null,
        crewId,
        pengirimCrewId,
        totalHarga,
        metode,
        isQris ? 'menungguValidasi' : 'selesai',
        isQris ? 'belumDivalidasi' : 'valid',
        body.bayar !== undefined ? parseFloat(body.bayar) : null,
        body.kembalian !== undefined ? parseFloat(body.kembalian) : null,
        qrPaymentId,
        body.catatan || null,
        tipePembelian,
        ongkirPerGalon,
        totalOngkir,
        now
      ]
    );
    
    for (const item of items) {
      await connection.query(
        `INSERT INTO transaksi_items (id, transaksi_id, produk_id, jumlah, harga_satuan, subtotal, galon_pinjam, galon_kembali)
         VALUES (?, ?, ?, ?, ?, ?, ?, ?)`,
        [item.id, item.transaksiId, item.produkId, item.jumlah, item.hargaSatuan, item.subtotal, item.galonPinjam, item.galonKembali]
      );
    }
    
    if (body.pelangganId && !isQris) {
      await connection.query(
        'UPDATE pelanggan SET total_transaksi = total_transaksi + ? WHERE id = ?',
        [totalHarga, body.pelangganId]
      );
    }

    if (!isQris) {
      await applyGalonFromTransaksiItems(connection, {
        items,
        pelangganId: body.pelangganId || null,
        crewId,
        crewNama: req.user.username || req.user.sub,
        transaksiId: trxId,
      });
    }
    
    await connection.commit();
    
    const [inserted] = await pool.query('SELECT * FROM transaksi WHERE id = ?', [trxId]);
    const enriched = await enrichTransaksiSql(pool, inserted[0]);
    res.status(201).json(enriched);
  } catch (err) {
    await connection.rollback();
    console.error(err);
    res.status(500).json({ message: sqlErrorMessage(err) });
  } finally {
    connection.release();
  }
});

router.put('/:id/status', authMiddleware, async (req, res) => {
  try {
    const pool = getPool();
    const [rows] = await pool.query('SELECT id FROM transaksi WHERE id = ?', [req.params.id]);
    if (rows.length === 0) return res.status(404).json({ message: 'Transaksi tidak ditemukan' });
    
    const now = new Date().toISOString().slice(0, 19).replace('T', ' ');
    await pool.query('UPDATE transaksi SET status = ?, updated_at = ? WHERE id = ?', [req.body.status, now, req.params.id]);
    
    const [updated] = await pool.query('SELECT * FROM transaksi WHERE id = ?', [req.params.id]);
    const enriched = await enrichTransaksiSql(pool, updated[0]);
    res.json(enriched);
  } catch (err) {
    console.error(err);
    res.status(500).json({ message: 'Internal Server Error' });
  }
});

router.put('/:id/validasi', authMiddleware, async (req, res) => {
  const pool = getPool();
  const connection = await pool.getConnection();
  await connection.beginTransaction();
  try {
    const [rows] = await connection.query('SELECT * FROM transaksi WHERE id = ?', [req.params.id]);
    if (rows.length === 0) {
      await connection.rollback();
      return res.status(404).json({ message: 'Transaksi tidak ditemukan' });
    }
    
    const t = rows[0];
    const { status } = req.body || {};
    let statusText = t.status;
    let statusValidasiText = t.status_validasi;
    
    if (status === 'sukses') {
      statusText = 'selesai';
      statusValidasiText = 'valid';
      if (t.pelanggan_id) {
        await connection.query(
          'UPDATE pelanggan SET total_transaksi = total_transaksi + ? WHERE id = ?',
          [parseFloat(t.total_harga), t.pelanggan_id]
        );
      }
      const [itemRows] = await connection.query(
        'SELECT produk_id, jumlah, galon_pinjam, galon_kembali FROM transaksi_items WHERE transaksi_id = ?',
        [req.params.id]
      );
      const txItems = itemRows.map((r) => ({
        produkId: r.produk_id,
        jumlah: r.jumlah,
        galonPinjam: r.galon_pinjam,
        galonKembali: r.galon_kembali,
      }));
      await applyGalonFromTransaksiItems(connection, {
        items: txItems,
        pelangganId: t.pelanggan_id,
        crewId: t.crew_id,
        crewNama: req.user.username || req.user.sub,
        transaksiId: t.id,
      });
    } else if (status === 'gagal') {
      statusText = 'dibatalkan';
      statusValidasiText = 'invalid';
    }
    
    const now = new Date().toISOString().slice(0, 19).replace('T', ' ');
    await connection.query(
      `UPDATE transaksi 
       SET status = ?, status_validasi = ?, validasi_oleh = ?, validasi_at = ?, updated_at = ? 
       WHERE id = ?`,
      [statusText, statusValidasiText, req.user.sub, now, now, req.params.id]
    );
    
    await connection.commit();
    
    const [updated] = await pool.query('SELECT * FROM transaksi WHERE id = ?', [req.params.id]);
    const enriched = await enrichTransaksiSql(pool, updated[0]);
    res.json(enriched);
  } catch (err) {
    await connection.rollback();
    console.error(err);
    res.status(500).json({ message: sqlErrorMessage(err) });
  } finally {
    connection.release();
  }
});

module.exports = router;
