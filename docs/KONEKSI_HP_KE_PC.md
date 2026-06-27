# HP tidak bisa buka http://192.168.178.179:3000/v1/health

## Penyebab

Backend **sudah jalan** di PC (bisa dibuka dari browser PC).  
HP gagal karena **Windows Firewall** memblokir koneksi masuk dari WiFi — butuh izin Administrator.

## Solusi 1 — Buka firewall (disarankan)

1. Buka folder `backend`
2. **Klik kanan** `allow-firewall.bat` → **Run as administrator**
3. Pastikan muncul "Berhasil"
4. `npm start` (satu terminal saja)
5. Di HP buka: `http://192.168.178.179:3000/v1/health`

Atau PowerShell **as Administrator**:

```powershell
cd D:\KULIAH\SKRIPSI\depo_app\backend
.\allow-firewall.ps1
```

## Solusi 2 — Jaringan WiFi "Private"

1. Windows: Settings → Network → WiFi → properti jaringan Anda
2. Ubah **Network profile** dari Public ke **Private**
3. Ulangi Solusi 1

## Solusi 3 — USB + adb reverse (tanpa firewall WiFi)

Jika HP dicolok USB ke PC:

```bash
adb reverse tcp:3000 tcp:3000
```

Lalu di `lib/config/api_config.dart` sementara:

```dart
static const String lanHost = '127.0.0.1';
```

`flutter run` — app di HP memakai localhost PC lewat kabel USB.

## Cek cepat

| Tes | Dari mana | Harus |
|-----|-----------|--------|
| `http://127.0.0.1:3000/v1/health` | Browser PC | OK |
| `http://192.168.178.179:3000/v1/health` | Browser PC | OK |
| URL yang sama | Browser HP | OK setelah firewall |

IP HP (`192.168.178.17`) dan IP PC (`192.168.178.179`) **sudah benar** — beda IP, subnet sama.
