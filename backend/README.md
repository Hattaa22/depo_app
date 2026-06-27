# Depo Air API (Backend)

REST API untuk aplikasi Flutter `depo_app`.

## Menjalankan

```bash
cd backend
npm install
npm start
```

Server: **http://127.0.0.1:3000/v1**

## Akun uji

| Role | Username | Password |
|------|----------|----------|
| Manager | `manager@depoair.com` | `Password123` |
| Crew | `crew001` | `Password123` |

## Pembayaran QRIS (online)

1. `POST /v1/pembayaran/qris` — body: `{ "transaksiId": "..." }`  
   Response: `paymentId`, `qrContent`, `expiresAt`, `jumlah`

2. `GET /v1/pembayaran/qris/:paymentId/status` — polling status (`pending` | `paid` | `expired`)

3. `POST /v1/pembayaran/qris/:paymentId/simulate-pay` — simulasi pelanggan sudah bayar (uji/skripsi)

Alur: transaksi QRIS dibuat → app tampilkan QR dari server → polling status → setelah `paid`, transaksi tetap `menungguValidasi` untuk manager.

## Flutter

`lib/config/constants.dart` → `baseUrl` harus mengarah ke server ini.

- Windows: `http://127.0.0.1:3000/v1`
- Android emulator: `http://10.0.2.2:3000/v1`

Header: `Authorization: Bearer <access_token>`
