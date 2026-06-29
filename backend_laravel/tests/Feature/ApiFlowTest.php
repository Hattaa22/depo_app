<?php

namespace Tests\Feature;

use Illuminate\Foundation\Testing\DatabaseTransactions;
use Illuminate\Support\Facades\DB;
use Tests\TestCase;

class ApiFlowTest extends TestCase
{
    use DatabaseTransactions;

    private function managerToken(): string
    {
        $response = $this->postJson('/api/v1/auth/login/manager', [
            'username' => 'manager@depoair.com',
            'password' => 'Password123',
        ]);

        $response->assertOk()->assertJsonStructure([
            'access_token',
            'refresh_token',
            'role',
            'user_data' => ['id', 'nama'],
        ]);

        return (string) $response->json('access_token');
    }

    private function crewToken(): string
    {
        $response = $this->postJson('/api/v1/auth/login/crew', [
            'noHp' => '081234567890',
            'password' => '123456',
        ]);

        $response->assertOk()->assertJsonStructure([
            'access_token',
            'refresh_token',
            'role',
            'user_data' => ['id', 'nama'],
        ]);

        return (string) $response->json('access_token');
    }

    public function test_protected_endpoint_requires_token(): void
    {
        $this->getJson('/api/v1/produk')
            ->assertUnauthorized()
            ->assertJson(['message' => 'Token tidak ditemukan']);

        $this->postJson('/api/v1/pembayaran/qris/unknown/simulate-pay')
            ->assertUnauthorized()
            ->assertJson(['message' => 'Token tidak ditemukan']);
    }

    public function test_manager_can_load_core_reference_data(): void
    {
        $token = $this->managerToken();

        $headers = ['Authorization' => "Bearer {$token}"];
        $this->getJson('/api/v1/produk', $headers)
            ->assertOk()
            ->assertJsonStructure(['data', 'total', 'page', 'limit', 'totalPages']);

        $this->getJson('/api/v1/pelanggan', $headers)
            ->assertOk()
            ->assertJsonStructure(['data', 'total', 'page', 'limit', 'totalPages']);

        $this->getJson('/api/v1/galon/ringkasan', $headers)
            ->assertOk()
            ->assertJsonStructure(['totalGalon', 'tersedia', 'dipinjam', 'rusak', 'hilang']);
    }

    public function test_crew_transaction_history_includes_delivered_transactions(): void
    {
        $token = $this->crewToken();
        $crewId = 'crew_001';
        $transactionId = 'test-history-delivered';

        DB::table('transaksi')->insert([
            'id' => $transactionId,
            'nomor_transaksi' => 'TEST-HISTORY-DELIVERED',
            'pelanggan_id' => DB::table('pelanggan')->value('id'),
            'crew_id' => 'manager_001',
            'pengirim_crew_id' => $crewId,
            'total_harga' => 12000,
            'metode_pembayaran' => 'tunai',
            'status' => 'selesai',
            'status_validasi' => 'valid',
            'tipe_pembelian' => 'dikirim',
            'ongkir_per_galon' => 0,
            'total_ongkir' => 0,
            'created_at' => now(),
        ]);

        $this->getJson("/api/v1/transaksi?crewId={$crewId}", [
            'Authorization' => "Bearer {$token}",
        ])
            ->assertOk()
            ->assertJsonFragment(['id' => $transactionId]);
    }

    public function test_crew_can_create_cash_transaction(): void
    {
        $token = $this->crewToken();
        $product = DB::table('produk')->where('is_aktif', 1)->first();
        $customer = DB::table('pelanggan')->where('is_aktif', 1)->first();

        $response = $this->postJson('/api/v1/transaksi', [
            'pelangganId' => $customer->id,
            'crewId' => 'crew_001',
            'metodePembayaran' => 'tunai',
            'items' => [
                [
                    'produkId' => $product->id,
                    'jumlah' => 1,
                    'galonPinjam' => 0,
                    'galonKembali' => 0,
                ],
            ],
        ], [
            'Authorization' => "Bearer {$token}",
        ]);

        $response
            ->assertCreated()
            ->assertJsonStructure([
                'id',
                'nomorTransaksi',
                'pelanggan',
                'crew',
                'items',
                'totalHarga',
                'metodePembayaran',
                'status',
                'statusValidasi',
                'createdAt',
            ])
            ->assertJson([
                'metodePembayaran' => 'tunai',
                'status' => 'selesai',
                'statusValidasi' => 'valid',
            ]);
    }
}
