require('dotenv').config();
const express = require('express');
const cors = require('cors');
const path = require('path');
const os = require('os');
const { connectDb, initDbSchema, getPool } = require('./config/db');
const { corsOrigins, isProduction, validateEnv } = require('./config/env');
const { setPool } = require('./helpers/galon');

validateEnv();

const app = express();
const PORT = process.env.PORT || 3000;

app.disable('x-powered-by');

app.use((req, res, next) => {
  res.setHeader('X-Content-Type-Options', 'nosniff');
  res.setHeader('X-Frame-Options', 'DENY');
  res.setHeader('Referrer-Policy', 'no-referrer');
  res.setHeader('Permissions-Policy', 'geolocation=(), microphone=(), camera=()');
  next();
});

const allowedOrigins = corsOrigins();
app.use(cors({
  origin(origin, callback) {
    if (!origin || !isProduction || allowedOrigins.includes(origin)) {
      return callback(null, true);
    }
    return callback(new Error('Origin tidak diizinkan oleh CORS'));
  },
  credentials: true,
}));
app.use(express.json({ limit: process.env.JSON_BODY_LIMIT || '1mb' }));
app.use(express.urlencoded({ extended: false, limit: process.env.JSON_BODY_LIMIT || '1mb' }));
app.use(express.static(path.join(__dirname, 'public')));

// Pastikan helper galon memakai pool yang sudah aktif.
app.use((req, res, next) => {
  try {
    setPool(getPool());
  } catch (e) {
    // Pool di-set saat startup; middleware ini hanya fallback saat hot reload dev.
  }
  next();
});

// Import & Gunakan Routes
const authRoutes = require('./routes/auth');
const crewRoutes = require('./routes/crew');
const pelangganRoutes = require('./routes/pelanggan');
const produkRoutes = require('./routes/produk');
const kategoriRoutes = require('./routes/kategori');
const pengeluaranRoutes = require('./routes/pengeluaran');
const galonRoutes = require('./routes/galon');
const transaksiRoutes = require('./routes/transaksi');
const pembayaranRoutes = require('./routes/pembayaran');
const laporanRoutes = require('./routes/laporan');
const cabangRoutes = require('./routes/cabang');
const healthRoutes = require('./routes/health');

app.use('/v1/auth', authRoutes);
app.use('/v1/crew', crewRoutes);
app.use('/v1/pelanggan', pelangganRoutes);
app.use('/v1/produk', produkRoutes);
app.use('/v1/kategori', kategoriRoutes);
app.use('/v1/pengeluaran', pengeluaranRoutes);
app.use('/v1/galon', galonRoutes);
app.use('/v1/transaksi', transaksiRoutes);
app.use('/v1/pembayaran', pembayaranRoutes);
app.use('/v1/laporan', laporanRoutes);
app.use('/v1/cabang', cabangRoutes);
app.use('/v1/health', healthRoutes);

// Penanganan Route Tidak Ditemukan
app.use((req, res) => {
  res.status(404).json({ message: `Route tidak ditemukan: ${req.method} ${req.path}` });
});

function getLanIpv4() {
  const nets = os.networkInterfaces();
  for (const name of Object.keys(nets)) {
    for (const net of nets[name]) {
      const isIpv4 = net.family === 'IPv4' || net.family === 4;
      if (isIpv4 && !net.internal) {
        return net.address;
      }
    }
  }
  return null;
}

// Server Startup
async function startServer() {
  await connectDb();
  setPool(getPool()); // Set pool for helpers
  await initDbSchema();
  
  app.listen(PORT, '0.0.0.0', () => {
    const lanIp = getLanIpv4();
    console.log('');
    console.log(`Depo Air API aktif — listen 0.0.0.0:${PORT} (semua jaringan)`);
    console.log(`  Browser di PC     : http://127.0.0.1:${PORT}/v1`);
    if (lanIp) {
      console.log(`  HP / Flutter app  : http://${lanIp}:${PORT}/v1`);
      console.log(`  → samakan lanHost di lib/config/api_config.dart`);
    } else {
      console.log(`  HP / Flutter app  : http://<IP-WiFi-PC>:${PORT}/v1  (cek: ipconfig)`);
    }
    if (!isProduction && process.env.SHOW_DEMO_CREDENTIALS === 'true') {
      console.log('Akun uji: crew001 / manager@depoair.com — password: lihat dokumentasi lokal');
    }
    console.log('');
  });
}

startServer().catch((err) => {
  console.error('[SERVER] Gagal memulai server:', err);
  process.exit(1);
});
