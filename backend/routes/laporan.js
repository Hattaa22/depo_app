const express = require('express');
const router = express.Router();
const { getPool } = require('../config/db');
const { authMiddleware } = require('../middleware/auth');

function dateRangeFilter(column, tanggalMulai, tanggalAkhir, params) {
  const filters = [];
  if (tanggalMulai) {
    filters.push(`${column} >= ?`);
    params.push(tanggalMulai);
  }
  if (tanggalAkhir) {
    filters.push(`${column} <= ?`);
    params.push(`${tanggalAkhir} 23:59:59`);
  }
  return filters.length ? ` AND ${filters.join(' AND ')}` : '';
}

router.get('/dashboard/manager', authMiddleware, async (req, res) => {
  try {
    const getLocalDateString = (date) => {
      const d = new Date(date);
      const year = d.getFullYear();
      const month = String(d.getMonth() + 1).padStart(2, '0');
      const day = String(d.getDate()).padStart(2, '0');
      return `${year}-${month}-${day}`;
    };

    const pool = getPool();
    
    // Helper to calculate data for a date range
    const calculateData = async (startDate, endDate) => {
      const txQuery = 'SELECT * FROM transaksi WHERE status = "selesai" AND DATE(created_at) >= ? AND DATE(created_at) <= ?';
      const expQuery = 'SELECT * FROM pengeluaran WHERE tanggal >= ? AND tanggal <= ?';
      const [txList] = await pool.query(txQuery, [startDate, endDate]);
      const [expList] = await pool.query(expQuery, [startDate, endDate]);

      let totalPendapatan = 0;
      let totalPengiriman = 0;
      txList.forEach((t) => {
        totalPendapatan += parseFloat(t.total_harga) || 0;
        if (t.tipe_pembelian === 'dikirim') {
          totalPengiriman += 1;
        }
      });

      const totalPengeluaran = expList.reduce((sum, p) => sum + (parseFloat(p.nominal) || 0), 0);

      return {
        totalPendapatan,
        totalTransaksi: txList.length,
        totalPengeluaran,
        pendapatanBersih: totalPendapatan - totalPengeluaran,
        totalPengiriman
      };
    };

    // Calculate for each period
    const today = getLocalDateString(new Date());
    const now = new Date();
    const firstDayOfMonth = getLocalDateString(new Date(now.getFullYear(), now.getMonth(), 1));
    const veryOldDate = '2000-01-01';

    const harian = await calculateData(today, today);
    const bulanan = await calculateData(firstDayOfMonth, today);
    const semua = await calculateData(veryOldDate, today);

    // Get galon count and pelanggan count
    const [galonSummary] = await pool.query('SELECT SUM(CASE WHEN status = "tersedia" THEN 1 ELSE 0 END) as tersedia FROM galon');
    const [pelangganSummary] = await pool.query('SELECT COUNT(*) as total FROM pelanggan');

    // Get breakdown (for demo purposes, we'll use the same breakdown for all periods for now)
    const [categoryRows] = await pool.query('SELECT * FROM kategori');
    const breakdownAll = [];
    for (const kat of categoryRows) {
      let total = 0;
      if (kat.tipe === 'pemasukan') {
        const [itemSumRows] = await pool.query(
          `SELECT SUM(ti.subtotal) as subtotal_sum
           FROM transaksi_items ti
           JOIN produk p ON p.id = ti.produk_id
           JOIN transaksi t ON t.id = ti.transaksi_id
           WHERE t.status = "selesai" AND p.kategori_id = ?`,
          [kat.id]
        );
        total += parseFloat(itemSumRows[0]?.subtotal_sum || 0);
      } else {
        const [expSumRows] = await pool.query(
          'SELECT SUM(nominal) as nominal_sum FROM pengeluaran WHERE kategori_id = ?',
          [kat.id]
        );
        total += parseFloat(expSumRows[0]?.nominal_sum || 0);
      }
      breakdownAll.push({
        id: kat.id,
        nama: kat.nama,
        tipe: kat.tipe,
        ikon: kat.ikon,
        total
      });
    }

    res.json({
      harian: {
        totalPendapatan: Number(harian.totalPendapatan),
        totalTransaksi: Number(harian.totalTransaksi),
        totalPengeluaran: Number(harian.totalPengeluaran),
        pendapatanBersih: Number(harian.pendapatanBersih),
        totalPengiriman: Number(harian.totalPengiriman)
      },
      bulanan: {
        totalPendapatan: Number(bulanan.totalPendapatan),
        totalTransaksi: Number(bulanan.totalTransaksi),
        totalPengeluaran: Number(bulanan.totalPengeluaran),
        pendapatanBersih: Number(bulanan.pendapatanBersih),
        totalPengiriman: Number(bulanan.totalPengiriman)
      },
      semua: {
        totalPendapatan: Number(semua.totalPendapatan),
        totalTransaksi: Number(semua.totalTransaksi),
        totalPengeluaran: Number(semua.totalPengeluaran),
        pendapatanBersih: Number(semua.pendapatanBersih),
        totalPengiriman: Number(semua.totalPengiriman)
      },
      galonBersih: Number(galonSummary[0]?.tersedia || 0),
      tersedia: Number(galonSummary[0]?.tersedia || 0),
      totalPelanggan: Number(pelangganSummary[0]?.total || 0),
      totalPendapatanHarian: Number(harian.totalPendapatan),
      totalTransaksiHari: Number(harian.totalTransaksi),
      breakdown: {
        harian: breakdownAll.map(b => ({ ...b, total: Number(b.total) })),
        bulanan: breakdownAll.map(b => ({ ...b, total: Number(b.total) })),
        semua: breakdownAll.map(b => ({ ...b, total: Number(b.total) })),
      }
    });
  } catch (err) {
    console.error(err);
    res.status(500).json({ message: 'Internal Server Error' });
  }
});

router.get('/dashboard/crew', authMiddleware, async (req, res) => {
  try {
    const getLocalDateString = (date) => {
      const d = new Date(date);
      const year = d.getFullYear();
      const month = String(d.getMonth() + 1).padStart(2, '0');
      const day = String(d.getDate()).padStart(2, '0');
      return `${year}-${month}-${day}`;
    };

    const today = getLocalDateString(new Date());
    const pool = getPool();
    const crewId = req.user?.sub;
    
    let txQuery = 'SELECT t.id, t.total_harga FROM transaksi t WHERE t.status = "selesai" AND DATE(t.created_at) = ?';
    const txParams = [today];
    
    if (crewId) {
      txQuery += ' AND (t.crew_id = ? OR t.pengirim_crew_id = ?)';
      txParams.push(crewId, crewId);
    }
    
    const [txList] = await pool.query(txQuery, txParams);
    const totalPenjualan = txList.reduce((sum, tx) => sum + (parseFloat(tx.total_harga) || 0), 0);
    const txIds = txList.map((tx) => tx.id);
    let totalGalonTerjual = 0;
    if (txIds.length > 0) {
      const placeholders = txIds.map(() => '?').join(',');
      const [itemRows] = await pool.query(
        `SELECT SUM(jumlah) as total FROM transaksi_items WHERE transaksi_id IN (${placeholders})`,
        txIds
      );
      totalGalonTerjual = parseInt(itemRows[0]?.total || 0, 10);
    }
    
    res.json({
      totalPenjualanHarian: totalPenjualan,
      totalGalonTerjual
    });
  } catch (err) {
    console.error(err);
    res.status(500).json({ message: 'Internal Server Error' });
  }
});

router.get('/pengiriman-crew', authMiddleware, async (req, res) => {
  try {
    const { tanggalMulai, tanggalAkhir } = req.query;
    const params = [];
    const filter = dateRangeFilter('t.created_at', tanggalMulai, tanggalAkhir, params);
    const selfOnly = req.user?.role !== 'manager';
    const selfFilter = selfOnly ? ' AND u.id = ?' : '';
    if (selfOnly) params.push(req.user.sub);
    const pool = getPool();
    const [rows] = await pool.query(
      `SELECT
         u.id AS crewId,
         u.nama AS crewNama,
         u.username AS username,
         COUNT(t.id) AS totalTransaksi,
         SUM(CASE WHEN t.tipe_pembelian = 'dikirim' THEN 1 ELSE 0 END) AS totalKirim,
         SUM(CASE WHEN t.tipe_pembelian <> 'dikirim' OR t.tipe_pembelian IS NULL THEN 1 ELSE 0 END) AS totalDiDepo,
         COALESCE(SUM(t.total_harga), 0) AS totalNominal,
         COALESCE(SUM(t.total_ongkir), 0) AS totalOngkir
       FROM users u
       LEFT JOIN transaksi t
         ON (t.pengirim_crew_id = u.id OR (t.pengirim_crew_id IS NULL AND t.crew_id = u.id))
        AND t.status = 'selesai'
        ${filter}
       WHERE u.role = 'crew' AND u.is_aktif = 1
       ${selfFilter}
       GROUP BY u.id, u.nama, u.username
       ORDER BY totalTransaksi DESC, u.nama ASC`,
      params
    );

    res.json(rows.map((row) => ({
      crewId: row.crewId,
      crewNama: row.crewNama,
      username: row.username,
      totalTransaksi: Number(row.totalTransaksi || 0),
      totalKirim: Number(row.totalKirim || 0),
      totalDiDepo: Number(row.totalDiDepo || 0),
      totalNominal: Number(row.totalNominal || 0),
      totalOngkir: Number(row.totalOngkir || 0),
    })));
  } catch (err) {
    console.error(err);
    res.status(500).json({ message: 'Internal Server Error' });
  }
});

router.get('/keuangan', authMiddleware, async (req, res) => {
  try {
    const { tanggalMulai, tanggalAkhir } = req.query;
    
    let txQuery = 'SELECT * FROM transaksi WHERE status = "selesai"';
    let expQuery = 'SELECT * FROM pengeluaran WHERE 1=1';
    const txParams = [];
    const expParams = [];
    
    if (tanggalMulai) {
      txQuery += ' AND DATE(created_at) >= ?';
      expQuery += ' AND tanggal >= ?';
      txParams.push(tanggalMulai);
      expParams.push(tanggalMulai);
    }
    
    if (tanggalAkhir) {
      txQuery += ' AND DATE(created_at) <= ?';
      expQuery += ' AND tanggal <= ?';
      txParams.push(tanggalAkhir);
      expParams.push(tanggalAkhir);
    }
    
    const pool = getPool();
    const [txList] = await pool.query(txQuery, txParams);
    const [expList] = await pool.query(expQuery, expParams);
    const [categoryRows] = await pool.query('SELECT * FROM kategori');
    
    const totalPendapatan = txList.reduce((s, t) => s + parseFloat(t.total_harga), 0);
    const totalPengeluaran = expList.reduce((s, p) => s + parseFloat(p.nominal), 0);
    const totalDikirim = txList.filter((t) => t.tipe_pembelian === 'dikirim').length;
    const totalDiDepo = txList.filter((t) => t.tipe_pembelian !== 'dikirim').length;
    const transaksiCrewMap = new Map();
    for (const t of txList) {
      const id = t.pengirim_crew_id || t.crew_id;
      if (!id) continue;
      const current = transaksiCrewMap.get(id) || { crewId: id, totalTransaksi: 0, totalKirim: 0, totalDiDepo: 0, totalNominal: 0 };
      current.totalTransaksi += 1;
      current.totalNominal += parseFloat(t.total_harga) || 0;
      if (t.tipe_pembelian === 'dikirim') current.totalKirim += 1;
      else current.totalDiDepo += 1;
      transaksiCrewMap.set(id, current);
    }
    const transaksiCrew = [];
    for (const item of transaksiCrewMap.values()) {
      const [crewRows] = await pool.query('SELECT nama, username FROM users WHERE id = ?', [item.crewId]);
      transaksiCrew.push({
        ...item,
        crewNama: crewRows[0]?.nama || item.crewId,
        username: crewRows[0]?.username || '',
      });
    }
    transaksiCrew.sort((a, b) => b.totalTransaksi - a.totalTransaksi);
    
    const breakdown = [];
    for (const kat of categoryRows) {
      let total = 0;
      if (kat.tipe === 'pemasukan') {
        for (const t of txList) {
          const [itemSumRows] = await pool.query(
            `SELECT SUM(ti.subtotal) as subtotal_sum
             FROM transaksi_items ti
             JOIN produk p ON p.id = ti.produk_id
             WHERE ti.transaksi_id = ? AND p.kategori_id = ?`,
            [t.id, kat.id]
          );
          total += parseFloat(itemSumRows[0]?.subtotal_sum || 0);
        }
      } else {
        expList.forEach((p) => {
          if (p.kategori_id === kat.id) {
            total += parseFloat(p.nominal) || 0;
          }
        });
      }
      breakdown.push({
        id: kat.id,
        nama: kat.nama,
        tipe: kat.tipe,
        ikon: kat.ikon,
        total
      });
    }
    
    const [cancelRows] = await pool.query('SELECT COUNT(*) as total FROM transaksi WHERE status = "dibatalkan"');
    
    const pendapatanTunai = txList.filter((t) => t.metode_pembayaran === 'tunai').reduce((s, t) => s + parseFloat(t.total_harga), 0);
    const pendapatanQris = txList.filter((t) => t.metode_pembayaran === 'qris').reduce((s, t) => s + parseFloat(t.total_harga), 0);
    const pendapatanTransfer = txList.filter((t) => t.metode_pembayaran === 'transfer').reduce((s, t) => s + parseFloat(t.total_harga), 0);
    
    res.json({
      tanggalMulai: tanggalMulai || new Date().toISOString().slice(0, 10),
      tanggalAkhir: tanggalAkhir || new Date().toISOString().slice(0, 10),
      totalPendapatan,
      totalPengeluaran,
      pendapatanBersih: totalPendapatan - totalPengeluaran,
      totalTransaksi: txList.length,
      transaksiSelesai: txList.length,
      transaksiDibatalkan: cancelRows[0]?.total || 0,
      pendapatanTunai,
      pendapatanQris,
      pendapatanTransfer,
      totalDikirim,
      totalDiDepo,
      transaksiCrew,
      breakdown
    });
  } catch (err) {
    console.error(err);
    res.status(500).json({ message: 'Internal Server Error' });
  }
});

module.exports = router;
