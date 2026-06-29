const express = require('express');
const router = express.Router();
const crypto = require('crypto');
const { getPool } = require('../config/db');
const { authMiddleware } = require('../middleware/auth');

const MIDTRANS_SERVER_KEY = (process.env.MIDTRANS_SERVER_KEY || '').trim();
const MIDTRANS_IS_PRODUCTION = String(process.env.MIDTRANS_IS_PRODUCTION || 'false').trim() === 'true';
const ALLOW_QRIS_SIMULATION = String(process.env.ALLOW_QRIS_SIMULATION || 'false').trim() === 'true';
const MIDTRANS_BASE_URL = process.env.MIDTRANS_BASE_URL || (
  MIDTRANS_IS_PRODUCTION ? 'https://api.midtrans.com' : 'https://api.sandbox.midtrans.com'
);

function midtransAuthHeader() {
  if (!MIDTRANS_SERVER_KEY) return '';
  return `Basic ${Buffer.from(MIDTRANS_SERVER_KEY + ':').toString('base64')}`;
}

function buildSimulationQr(paymentId, amount) {
  return `DEPO_QRIS_SIM|paymentId=${paymentId}|amount=${amount}|merchant=Depo Air Minum`;
}

// --- Test endpoint (DEBUG) ---
router.get('/qris/test-simulasi', async (req, res) => {
  if (!ALLOW_QRIS_SIMULATION) {
    return res.status(404).json({ message: 'Endpoint tidak tersedia' });
  }
  try {
    const testOrderId = `TEST-DEBUG-${Date.now()}`;
    const testAmount = 15000;
    const qrString = buildSimulationQr(testOrderId, testAmount);
    res.json({
      success: true,
      qrContent: qrString,
      testOrderId: testOrderId,
      testAmount: testAmount
    });
  } catch (err) {
    console.error(err);
    res.status(500).json({ success: false, message: 'Internal Server Error' });
  }
});

router.post('/qris', authMiddleware, async (req, res) => {
  try {
    const { transaksiId } = req.body || {};
    const pool = getPool();
    const [trxRows] = await pool.query('SELECT * FROM transaksi WHERE id = ?', [transaksiId]);
    if (trxRows.length === 0) return res.status(404).json({ message: 'Transaksi tidak ditemukan' });

    const t = trxRows[0];
    if (t.metode_pembayaran !== 'qris') {
      return res.status(400).json({ message: 'Transaksi bukan metode QRIS' });
    }

    const [existing] = await pool.query(
      'SELECT * FROM qr_payments WHERE transaksi_id = ? AND status = "pending"',
      [transaksiId]
    );

    const now = new Date();
    if (existing.length > 0) {
      const exp = new Date(existing[0].expires_at);
      if (now > exp) {
        await pool.query(
          'UPDATE qr_payments SET status = "expired", updated_at = ? WHERE payment_id = ?',
          [now.toISOString().slice(0, 19).replace('T', ' '), existing[0].payment_id]
        );
      } else {
        const existingQr = existing[0].qr_content || '';
        return res.json({
          paymentId: existing[0].payment_id,
          transaksiId: existing[0].transaksi_id,
          qrContent: existingQr,
          jumlah: parseFloat(existing[0].jumlah),
          status: existing[0].status,
          expiresAt: existing[0].expires_at,
          namaDepot: existing[0].nama_depot || 'Depo Air Minum'
        });
      }
    }

    const orderId = `DEPO-${transaksiId.slice(0, 8).toUpperCase()}-${Date.now()}`;
    const grossAmount = Math.round(parseFloat(t.total_harga));

    let qrString = null;
    let paymentProvider = 'simulasi';
    
    if (ALLOW_QRIS_SIMULATION) {
      qrString = buildSimulationQr(orderId, grossAmount);
    } else {
      const usingSandboxKey = MIDTRANS_SERVER_KEY.startsWith('SB-Mid-');
      if (MIDTRANS_IS_PRODUCTION && usingSandboxKey) {
        return res.status(400).json({
          message: 'Konfigurasi Midtrans salah: production=true tetapi key masih sandbox (SB-Mid). E-wallet asli hanya bisa scan QRIS production dengan production key.'
        });
      }

      if (!MIDTRANS_SERVER_KEY) {
        return res.status(500).json({ message: 'MIDTRANS_SERVER_KEY belum dikonfigurasi di .env' });
      }

      const midtransPayload = {
        payment_type: 'qris',
        transaction_details: {
          order_id: orderId,
          gross_amount: grossAmount
        },
        qris: { acquirer: 'gopay' }
      };

      try {
        const midtransRes = await fetch(`${MIDTRANS_BASE_URL}/v2/charge`, {
          method: 'POST',
          headers: {
            'Accept': 'application/json',
            'Content-Type': 'application/json',
            'Authorization': midtransAuthHeader()
          },
          body: JSON.stringify(midtransPayload)
        });

        const midtransData = await midtransRes.json();
        if (midtransRes.ok && (midtransData.status_code === '201' || midtransData.status_code === '200')) {
          qrString = midtransData.qr_string || null;
          if (qrString) paymentProvider = 'midtrans';
        } else {
          const errMsg = midtransData.status_message || midtransData.error_messages?.join(', ') || 'Gagal membuat QRIS Midtrans';
          return res.status(502).json({ message: `Midtrans: ${errMsg}` });
        }
      } catch (midtransErr) {
        return res.status(502).json({ message: `Midtrans tidak dapat dihubungi: ${midtransErr.message}` });
      }

      if (!qrString) {
        return res.status(502).json({ message: 'Midtrans tidak mengembalikan qr_string. Pastikan metode QRIS/GoPay aktif di akun Midtrans.' });
      }

      if (!qrString.startsWith('000201')) {
        return res.status(502).json({ message: 'QR yang diterima bukan format QRIS EMV. E-wallet tidak akan bisa scan QR ini.' });
      }
    }

    const expiresAt = new Date(Date.now() + 15 * 60 * 1000).toISOString().slice(0, 19).replace('T', ' ');
    const nowSql = now.toISOString().slice(0, 19).replace('T', ' ');

    await pool.query(
      `INSERT INTO qr_payments (payment_id, transaksi_id, jumlah, qr_content, status, nama_depot, expires_at, created_at)
       VALUES (?, ?, ?, ?, 'pending', 'Depo Air Minum', ?, ?)`,
      [orderId, transaksiId, t.total_harga, qrString, expiresAt, nowSql]
    );

    await pool.query(
      'UPDATE transaksi SET qr_payment_id = ?, updated_at = ? WHERE id = ?',
      [orderId, nowSql, transaksiId]
    );

    res.status(201).json({
      paymentId: orderId,
      transaksiId,
      qrContent: qrString,
      jumlah: parseFloat(t.total_harga),
      status: 'pending',
      expiresAt,
      namaDepot: paymentProvider === 'midtrans' ? 'Depo Air Minum' : 'Depo Air Minum (Simulasi)'
    });
  } catch (err) {
    console.error('[QRIS ERROR]', err);
    res.status(500).json({ message: 'Internal Server Error' });
  }
});

router.get('/qris/:paymentId/status', authMiddleware, async (req, res) => {
  try {
    const pool = getPool();
    const [rows] = await pool.query('SELECT status, payment_id, transaksi_id, jumlah, paid_at, expires_at FROM qr_payments WHERE payment_id = ?', [req.params.paymentId]);
    if (rows.length === 0) return res.status(404).json({ message: 'Pembayaran QR tidak ditemukan' });
    const r = rows[0];
    res.json({
      paymentId: r.payment_id,
      transaksiId: r.transaksi_id,
      status: r.status,
      jumlah: parseFloat(r.jumlah),
      paidAt: r.paid_at ? r.paid_at.toISOString ? r.paid_at.toISOString() : r.paid_at : null,
      expiresAt: r.expires_at ? r.expires_at.toISOString ? r.expires_at.toISOString() : r.expires_at : null,
    });
  } catch (err) {
    console.error(err);
    res.status(500).json({ message: 'Internal Server Error' });
  }
});

router.get('/qris/:paymentId/status-public', async (req, res) => {
  try {
    const pool = getPool();
    const [rows] = await pool.query('SELECT status, paid_at FROM qr_payments WHERE payment_id = ?', [req.params.paymentId]);
    if (rows.length === 0) return res.status(404).json({ message: 'Tidak ditemukan' });
    const r = rows[0];
    res.json({
      status: r.status,
      paidAt: r.paid_at ? (r.paid_at.toISOString ? r.paid_at.toISOString() : r.paid_at) : null
    });
  } catch (err) {
    res.status(500).json({ message: 'Internal Server Error' });
  }
});

router.get('/qris/:paymentId/scan-web', async (req, res) => {
  if (!ALLOW_QRIS_SIMULATION) {
    return res.status(403).send('Simulasi QRIS tidak aktif');
  }
  try {
    const pool = getPool();
    const [rows] = await pool.query('SELECT * FROM qr_payments WHERE payment_id = ?', [req.params.paymentId]);
    if (rows.length === 0) {
      return res.status(404).send('<h1 style="text-align:center;margin-top:100px;font-family:sans-serif;">Pembayaran tidak ditemukan.</h1>');
    }
    const t = rows[0];
    if (t.status === 'paid') {
      return res.send(`
        <div style="text-align:center;margin-top:100px;font-family:sans-serif;">
          <h1 style="color:green;">Pembayaran Berhasil!</h1>
          <p>Terima kasih. Anda sudah dapat menutup halaman ini.</p>
        </div>
      `);
    }
    
    // Halaman simulasi - bisa menekan tombol bayar
    res.send(`
      <!DOCTYPE html>
      <html>
      <head>
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
        <style>
          body { font-family: sans-serif; text-align: center; margin-top: 50px; background-color: #f5f5f5; }
          .card { background: white; padding: 20px; border-radius: 8px; box-shadow: 0 4px 6px rgba(0,0,0,0.1); max-width: 400px; margin: 0 auto; }
          button { background: #0088cc; color: white; border: none; padding: 12px 24px; border-radius: 4px; font-size: 16px; cursor: pointer; width: 100%; margin-top: 20px; }
          button:disabled { background: #cccccc; cursor: not-allowed; }
          .amount { font-size: 24px; font-weight: bold; margin: 10px 0; }
        </style>
      </head>
      <body>
        <div class="card">
          <h2>Simulasi QRIS Depo</h2>
          <p>Membayar pesanan untuk:</p>
          <div class="amount">Rp ${parseFloat(t.jumlah).toLocaleString('id-ID')}</div>
          
          <button id="btnBayar" onclick="bayar()">Bayar Sekarang</button>
          <p id="msg" style="color: green; display: none; margin-top: 15px;">Pembayaran berhasil!</p>
        </div>
        
        <script>
          async function bayar() {
            document.getElementById('btnBayar').disabled = true;
            document.getElementById('btnBayar').innerText = 'Memproses...';
            try {
              const res = await fetch(window.location.pathname.replace('/scan-web', '/simulate-pay'), {
                method: 'POST'
              });
              if(res.ok) {
                document.getElementById('btnBayar').style.display = 'none';
                document.getElementById('msg').style.display = 'block';
              } else {
                document.getElementById('btnBayar').disabled = false;
                document.getElementById('btnBayar').innerText = 'Gagal, Coba Lagi';
                alert('Gagal memproses simulasi');
              }
            } catch(e) {
              document.getElementById('btnBayar').disabled = false;
              document.getElementById('btnBayar').innerText = 'Gagal, Coba Lagi';
              alert('Error jaringan');
            }
          }
        </script>
      </body>
      </html>
    `);
  } catch (err) {
    res.status(500).send('Internal Server Error');
  }
});

router.post('/qris/:paymentId/simulate-pay', async (req, res) => {
  if (!ALLOW_QRIS_SIMULATION) {
    return res.status(404).json({ message: 'Endpoint tidak tersedia' });
  }
  const pool = getPool();
  const connection = await pool.getConnection();
  await connection.beginTransaction();
  try {
    const orderId = req.params.paymentId;
    const nowSql = new Date().toISOString().slice(0, 19).replace('T', ' ');
    
    await connection.query(
      'UPDATE qr_payments SET status = "paid", paid_at = ?, updated_at = ? WHERE payment_id = ?',
      [nowSql, nowSql, orderId]
    );

    const [payRows] = await connection.query(
      'SELECT transaksi_id FROM qr_payments WHERE payment_id = ?', [orderId]
    );

    if (payRows.length > 0) {
      const trxId = payRows[0].transaksi_id;
      await connection.query(
        `UPDATE transaksi SET qr_paid_at = ?, status = 'menungguValidasi', updated_at = ? WHERE id = ?`,
        [nowSql, nowSql, trxId]
      );
    }
    
    await connection.commit();
    res.json({ success: true });
  } catch (err) {
    await connection.rollback();
    res.status(500).json({ message: 'Internal Server Error' });
  } finally {
    connection.release();
  }
});

router.post('/midtrans-notification', async (req, res) => {
  const pool = getPool();
  const connection = await pool.getConnection();
  await connection.beginTransaction();
  try {
    const notif = req.body || {};
    const orderId         = notif.order_id;
    const statusCode      = notif.status_code;
    const grossAmount     = notif.gross_amount;
    const transactionStatus = notif.transaction_status;
    const fraudStatus     = notif.fraud_status;
    const signatureKey    = notif.signature_key;

    if (MIDTRANS_SERVER_KEY && signatureKey) {
      const expectedSignature = crypto
        .createHash('sha512')
        .update(`${orderId}${statusCode}${grossAmount}${MIDTRANS_SERVER_KEY}`)
        .digest('hex');

      if (expectedSignature !== signatureKey) {
        await connection.rollback();
        return res.status(403).json({ message: 'Invalid signature' });
      }
    }

    const isSuccess =
      transactionStatus === 'settlement' ||
      (transactionStatus === 'capture' && fraudStatus === 'accept');

    const isExpiredOrDenied =
      transactionStatus === 'expire' ||
      transactionStatus === 'cancel' ||
      transactionStatus === 'deny';

    const nowSql = new Date().toISOString().slice(0, 19).replace('T', ' ');

    if (isSuccess) {
      await connection.query(
        'UPDATE qr_payments SET status = "paid", paid_at = ?, updated_at = ? WHERE payment_id = ?',
        [nowSql, nowSql, orderId]
      );

      const [payRows] = await connection.query(
        'SELECT transaksi_id FROM qr_payments WHERE payment_id = ?', [orderId]
      );

      if (payRows.length > 0) {
        const trxId = payRows[0].transaksi_id;
        await connection.query(
          `UPDATE transaksi SET qr_paid_at = ?, status = 'menungguValidasi', updated_at = ? WHERE id = ?`,
          [nowSql, nowSql, trxId]
        );
      }
    } else if (isExpiredOrDenied) {
      await connection.query(
        'UPDATE qr_payments SET status = "expired", updated_at = ? WHERE payment_id = ?',
        [nowSql, orderId]
      );
    }

    await connection.commit();
    res.status(200).json({ message: 'OK' });
  } catch (err) {
    await connection.rollback();
    res.status(500).json({ message: 'Internal Server Error' });
  } finally {
    connection.release();
  }
});

module.exports = router;
