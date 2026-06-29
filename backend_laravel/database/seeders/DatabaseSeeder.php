<?php

namespace Database\Seeders;

use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Str;
use Illuminate\Database\Seeder;

class DatabaseSeeder extends Seeder
{
    /**
     * Seed the application's database.
     */
    public function run(): void
    {
        if (DB::table('users')->exists()) {
            return;
        }

        $now = now();
        $crewId = 'crew_001';
        $managerId = 'manager_001';

        DB::table('users')->insert([
            'id' => $crewId,
            'role' => 'crew',
            'email' => 'crew@depoair.com',
            'password_hash' => Hash::make('123456'),
            'pin_hash' => Hash::make('123456'),
            'nama' => 'Budi Santoso',
            'no_hp' => '081234567890',
            'alamat' => 'Jl. Crew No. 1',
            'is_aktif' => 1,
            'created_at' => $now,
        ]);

        DB::table('users')->insert([
            'id' => $managerId,
            'role' => 'manager',
            'email' => 'manager@depoair.com',
            'password_hash' => Hash::make('Password123'),
            'nama' => 'Ahmad Manager',
            'no_hp' => '081298765432',
            'alamat' => 'Kantor Depo',
            'is_aktif' => 1,
            'created_at' => $now,
        ]);

        $katIsi = (string) Str::uuid();
        $katGalon = (string) Str::uuid();
        $katGaji = (string) Str::uuid();

        DB::table('kategori')->insert([
            ['id' => $katIsi, 'nama' => 'Penjualan Isi Ulang', 'deskripsi' => 'Produk Utama', 'tipe' => 'pemasukan', 'ikon' => 'water_drop', 'is_system' => 1, 'is_aktif' => 1, 'created_at' => $now],
            ['id' => $katGalon, 'nama' => 'Penjualan Galon Baru', 'deskripsi' => 'Inventori', 'tipe' => 'pemasukan', 'ikon' => 'inventory_2', 'is_system' => 1, 'is_aktif' => 1, 'created_at' => $now],
            ['id' => $katGaji, 'nama' => 'Gaji Crew', 'deskripsi' => 'Biaya Operasional', 'tipe' => 'pengeluaran', 'ikon' => 'people', 'is_system' => 1, 'is_aktif' => 1, 'created_at' => $now],
        ]);

        DB::table('produk')->insert([
            ['id' => (string) Str::uuid(), 'nama' => 'Isi Ulang Galon', 'kategori_id' => $katIsi, 'harga' => 12000, 'stok' => 200, 'deskripsi' => 'Layanan isi ulang galon pelanggan', 'is_aktif' => 1, 'created_at' => $now],
            ['id' => (string) Str::uuid(), 'nama' => 'Galon Baru', 'kategori_id' => $katGalon, 'harga' => 45000, 'stok' => 50, 'deskripsi' => 'Penjualan galon baru', 'is_aktif' => 1, 'created_at' => $now],
        ]);

        $pelangganId = (string) Str::uuid();
        DB::table('pelanggan')->insert([
            'id' => $pelangganId,
            'nama' => 'Siti Aminah',
            'no_hp' => '081211112222',
            'alamat' => 'Jl. Melati No. 5',
            'total_galon_pinjam' => 0,
            'total_transaksi' => 0,
            'is_aktif' => 1,
            'created_at' => $now,
        ]);

        $galons = [];
        for ($i = 1; $i <= 30; $i++) {
            $galons[] = [
                'id' => (string) Str::uuid(),
                'kode_galon' => 'G-'.str_pad((string) $i, 3, '0', STR_PAD_LEFT),
                'merek' => 'Depo',
                'jenis' => 'isi',
                'status' => 'tersedia',
                'created_at' => $now,
            ];
        }
        DB::table('galon')->insert($galons);

        DB::table('cabang')->insert([
            'id' => (string) Str::uuid(),
            'nama' => 'Depo Utama',
            'alamat' => 'Jl. Raya Depo',
            'kota' => 'Malang',
            'no_hp' => '0341-123456',
            'is_pusat' => 1,
            'is_aktif' => 1,
            'created_at' => $now,
        ]);
    }
}
