# Depo Air API

Backend Laravel untuk aplikasi Depo Air Minum. API memakai MySQL dan endpoint kompatibel Flutter pada prefix `/api/v1`.

## Local Development

```bash
composer install
cp .env.example .env
php artisan key:generate
php artisan migrate --seed
php artisan serve --host=127.0.0.1 --port=8000
```

Jalankan Flutter lokal dengan API lokal eksplisit:

```bash
flutter run --dart-define=API_BASE_URL=http://127.0.0.1:8000/api/v1 --dart-define=ALLOW_HTTP_API=true
```

Health check: `GET /api/v1/health`.

## Production Deployment

Gunakan domain atau subdomain HTTPS, misalnya `https://api.domain.com`.

Environment minimal:

```env
APP_ENV=production
APP_DEBUG=false
APP_URL=https://api.domain.com
FORCE_HTTPS=true
TRUSTED_PROXIES=*
CORS_ALLOWED_ORIGINS=https://app.domain.com
FILESYSTEM_DISK=public
SESSION_DRIVER=array
SESSION_SECURE_COOKIE=true
SESSION_SAME_SITE=lax
```

Web server harus mengarah ke folder `backend_laravel/public`, bukan root project. Pastikan SSL aktif dan jalankan:

```bash
composer install --no-dev --optimize-autoloader
php artisan key:generate --force
php artisan migrate --force
php artisan storage:link
php artisan config:cache
php artisan route:cache
```

## Flutter Production Build

Release build wajib memakai domain HTTPS:

```bash
flutter build apk --release --dart-define=API_BASE_URL=https://api.domain.com/api/v1
```

Tanpa `API_BASE_URL`, aplikasi akan menolak fallback IP lokal.

## Validasi

```bash
php artisan test
php artisan route:list --path=api/v1
```
