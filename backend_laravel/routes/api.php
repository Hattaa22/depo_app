<?php

use App\Http\Controllers\Api\V1\AuthController;
use App\Http\Controllers\Api\V1\CabangController;
use App\Http\Controllers\Api\V1\CrewController;
use App\Http\Controllers\Api\V1\DashboardController;
use App\Http\Controllers\Api\V1\GalonController;
use App\Http\Controllers\Api\V1\HealthController;
use App\Http\Controllers\Api\V1\KategoriController;
use App\Http\Controllers\Api\V1\LaporanController;
use App\Http\Controllers\Api\V1\PaymentController;
use App\Http\Controllers\Api\V1\PelangganController;
use App\Http\Controllers\Api\V1\PengeluaranController;
use App\Http\Controllers\Api\V1\ProdukController;
use App\Http\Controllers\Api\V1\TransaksiController;
use Illuminate\Support\Facades\Route;

Route::prefix('v1')->group(function () {
    Route::get('/health', [HealthController::class, 'health']);

    Route::post('/auth/login/crew', [AuthController::class, 'loginCrew'])->middleware('throttle:login');
    Route::post('/auth/login/manager', [AuthController::class, 'loginManager'])->middleware('throttle:login');
    Route::post('/auth/refresh', [AuthController::class, 'refresh']);
    Route::get('/pembayaran/qris/test-simulasi', [PaymentController::class, 'qrisTestSimulasi']);
    Route::get('/pembayaran/qris/{paymentId}/status-public', [PaymentController::class, 'qrisStatusPublic']);
    Route::post('/pembayaran/midtrans/notification', [PaymentController::class, 'midtransNotification']);

    Route::middleware('api.token')->group(function () {
        Route::post('/auth/logout', [AuthController::class, 'logout']);
        Route::put('/auth/change-password', [AuthController::class, 'changePassword']);
        Route::put('/auth/change-profile', [AuthController::class, 'changeProfile']);

        Route::get('/crew', [CrewController::class, 'crewIndex']);
        Route::post('/crew', [CrewController::class, 'crewStore']);
        Route::get('/crew/{id}', [CrewController::class, 'crewShow']);
        Route::put('/crew/{id}', [CrewController::class, 'crewUpdate']);
        Route::delete('/crew/{id}', [CrewController::class, 'crewDestroy']);
        Route::post('/crew/{id}/reset-pin', [CrewController::class, 'crewResetPin']);
        Route::put('/crew/{id}/status', [CrewController::class, 'crewUpdateStatus']);

        Route::get('/pelanggan', [PelangganController::class, 'pelangganIndex']);
        Route::post('/pelanggan', [PelangganController::class, 'pelangganStore']);
        Route::get('/pelanggan/{id}', [PelangganController::class, 'pelangganShow']);
        Route::put('/pelanggan/{id}', [PelangganController::class, 'pelangganUpdate']);
        Route::delete('/pelanggan/{id}', [PelangganController::class, 'pelangganDestroy']);

        Route::get('/produk', [ProdukController::class, 'produkIndex']);
        Route::post('/produk', [ProdukController::class, 'produkStore']);
        Route::get('/produk/{id}', [ProdukController::class, 'produkShow']);
        Route::put('/produk/{id}', [ProdukController::class, 'produkUpdate']);
        Route::delete('/produk/{id}', [ProdukController::class, 'produkDestroy']);

        Route::get('/kategori', [KategoriController::class, 'kategoriIndex']);
        Route::post('/kategori', [KategoriController::class, 'kategoriStore']);
        Route::put('/kategori/{id}', [KategoriController::class, 'kategoriUpdate']);
        Route::delete('/kategori/{id}', [KategoriController::class, 'kategoriDestroy']);

        Route::get('/pengeluaran', [PengeluaranController::class, 'pengeluaranIndex']);
        Route::post('/pengeluaran', [PengeluaranController::class, 'pengeluaranStore']);
        Route::delete('/pengeluaran/{id}', [PengeluaranController::class, 'pengeluaranDestroy']);

        Route::get('/galon/ringkasan', [GalonController::class, 'galonRingkasan']);
        Route::get('/galon/mutasi', [GalonController::class, 'galonMutasi']);
        Route::put('/galon/pinjam', [GalonController::class, 'galonPinjam']);
        Route::put('/galon/kembali', [GalonController::class, 'galonKembali']);
        Route::get('/galon', [GalonController::class, 'galonIndex']);
        Route::post('/galon', [GalonController::class, 'galonStore']);
        Route::put('/galon/{id}', [GalonController::class, 'galonUpdate']);

        Route::get('/transaksi', [TransaksiController::class, 'transaksiIndex']);
        Route::post('/transaksi', [TransaksiController::class, 'transaksiStore']);
        Route::get('/transaksi/{id}', [TransaksiController::class, 'transaksiShow']);
        Route::put('/transaksi/{id}/status', [TransaksiController::class, 'transaksiStatus']);
        Route::put('/transaksi/{id}/validasi', [TransaksiController::class, 'transaksiValidasi']);

        Route::get('/laporan/dashboard/manager', [DashboardController::class, 'dashboardManager']);
        Route::get('/laporan/dashboard/crew', [DashboardController::class, 'dashboardCrew']);
        Route::get('/laporan/keuangan', [LaporanController::class, 'laporanKeuangan']);
        Route::get('/laporan/pengiriman-crew', [LaporanController::class, 'pengirimanCrew']);

        Route::post('/pembayaran/qris', [PaymentController::class, 'qrisCreate']);
        Route::get('/pembayaran/qris/{paymentId}/status', [PaymentController::class, 'qrisStatus']);
        Route::post('/pembayaran/qris/{paymentId}/simulate-pay', [PaymentController::class, 'qrisSimulatePay']);

        Route::get('/cabang', [CabangController::class, 'cabangIndex']);
        Route::post('/cabang', [CabangController::class, 'cabangStore']);
        Route::get('/cabang/{id}', [CabangController::class, 'cabangShow']);
        Route::put('/cabang/{id}', [CabangController::class, 'cabangUpdate']);
        Route::delete('/cabang/{id}', [CabangController::class, 'cabangDestroy']);
    });
});
