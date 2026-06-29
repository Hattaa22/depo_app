# Deployment Production Checklist

## Backend Laravel

- Domain API aktif, contoh `https://api.domain.com`.
- SSL valid dan auto-renew aktif.
- Document root web server mengarah ke `backend_laravel/public`.
- `.env` production memakai:
  - `APP_ENV=production`
  - `APP_DEBUG=false`
  - `APP_URL=https://api.domain.com`
  - `FORCE_HTTPS=true`
  - `TRUSTED_PROXIES=*` atau IP reverse proxy yang spesifik
  - `CORS_ALLOWED_ORIGINS=https://app.domain.com`
  - `SESSION_DRIVER=array`
- Database MySQL hanya dapat diakses dari server aplikasi atau private network.
- `php artisan storage:link` sudah dijalankan jika ada file publik.
- `php artisan config:cache` dan `php artisan route:cache` berhasil.
- `php artisan migrate --force` berhasil.

## Mobile App

- Build release memakai `--dart-define=API_BASE_URL=https://api.domain.com/api/v1`.
- Android release tidak mengizinkan cleartext HTTP.
- Login berhasil dari jaringan seluler, bukan hanya WiFi yang sama.
- Token disimpan di secure storage dan dikirim sebagai `Authorization: Bearer <token>`.

## Security

- Endpoint login terkena rate limit.
- API memakai HTTPS end-to-end.
- CORS tidak memakai wildcard untuk web frontend production.
- `APP_KEY` production unik dan tidak memakai key lokal/development.
- Composer audit diperiksa sebelum deploy.
