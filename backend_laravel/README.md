# Depo Air API

Backend Laravel untuk aplikasi Depo Air Minum. API ini memakai MySQL dan mengekspos endpoint kompatibel dengan aplikasi Flutter pada prefix `/api/v1`.

## Setup

1. Install dependency:
   ```bash
   composer install
   ```
2. Salin konfigurasi environment:
   ```bash
   cp .env.example .env
   php artisan key:generate
   ```
3. Sesuaikan koneksi MySQL di `.env`.
4. Jalankan migrasi dan seeder:
   ```bash
   php artisan migrate --seed
   ```
5. Jalankan server lokal:
   ```bash
   php artisan serve --host=127.0.0.1 --port=8000
   ```

Health check tersedia di `GET /api/v1/health`.

## Akun Demo Seeder

- Manager: `manager@depoair.com` / `Password123`
- Crew: PIN `1234`

## Flutter

Default frontend memakai `http://127.0.0.1:8000/api/v1`. Untuk staging atau production, jalankan Flutter dengan:

```bash
flutter run --dart-define=API_BASE_URL=https://domain-api.example.com/api/v1
```

## Validasi

```bash
php artisan test
php artisan route:list --path=api/v1
```
