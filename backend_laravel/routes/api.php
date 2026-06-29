<?php

use App\Http\Controllers\Api\V1\DepoApiController;
use Illuminate\Support\Facades\Route;

Route::prefix('v1')->controller(DepoApiController::class)->group(function () {
    Route::get('/health', 'health');

    Route::post('/auth/login/crew', 'loginCrew')->middleware('throttle:login');
    Route::post('/auth/login/manager', 'loginManager')->middleware('throttle:login');
    Route::post('/auth/refresh', 'refresh');
    Route::get('/pembayaran/qris/test-simulasi', 'qrisTestSimulasi');
    Route::get('/pembayaran/qris/{paymentId}/status-public', 'qrisStatusPublic');
    Route::post('/pembayaran/qris/{paymentId}/simulate-pay', 'qrisSimulatePay');
    Route::post('/pembayaran/midtrans/notification', 'midtransNotification');

    Route::middleware('api.token')->group(function () {
        Route::post('/auth/logout', 'logout');
        Route::put('/auth/change-password', 'changePassword');
        Route::put('/auth/change-profile', 'changeProfile');

        Route::get('/crew', 'crewIndex');
        Route::post('/crew', 'crewStore');
        Route::get('/crew/{id}', 'crewShow');
        Route::put('/crew/{id}', 'crewUpdate');
        Route::delete('/crew/{id}', 'crewDestroy');

        Route::get('/pelanggan', 'pelangganIndex');
        Route::post('/pelanggan', 'pelangganStore');
        Route::get('/pelanggan/{id}', 'pelangganShow');
        Route::put('/pelanggan/{id}', 'pelangganUpdate');
        Route::delete('/pelanggan/{id}', 'pelangganDestroy');

        Route::get('/produk', 'produkIndex');
        Route::post('/produk', 'produkStore');
        Route::get('/produk/{id}', 'produkShow');
        Route::put('/produk/{id}', 'produkUpdate');
        Route::delete('/produk/{id}', 'produkDestroy');

        Route::get('/kategori', 'kategoriIndex');
        Route::post('/kategori', 'kategoriStore');
        Route::put('/kategori/{id}', 'kategoriUpdate');
        Route::delete('/kategori/{id}', 'kategoriDestroy');

        Route::get('/pengeluaran', 'pengeluaranIndex');
        Route::post('/pengeluaran', 'pengeluaranStore');
        Route::delete('/pengeluaran/{id}', 'pengeluaranDestroy');

        Route::get('/galon/ringkasan', 'galonRingkasan');
        Route::get('/galon/mutasi', 'galonMutasi');
        Route::put('/galon/pinjam', 'galonPinjam');
        Route::put('/galon/kembali', 'galonKembali');
        Route::get('/galon', 'galonIndex');
        Route::post('/galon', 'galonStore');
        Route::put('/galon/{id}', 'galonUpdate');

        Route::get('/transaksi', 'transaksiIndex');
        Route::post('/transaksi', 'transaksiStore');
        Route::get('/transaksi/{id}', 'transaksiShow');
        Route::put('/transaksi/{id}/status', 'transaksiStatus');
        Route::put('/transaksi/{id}/validasi', 'transaksiValidasi');

        Route::get('/laporan/dashboard/manager', 'dashboardManager');
        Route::get('/laporan/dashboard/crew', 'dashboardCrew');
        Route::get('/laporan/keuangan', 'laporanKeuangan');
        Route::get('/laporan/pengiriman-crew', 'pengirimanCrew');

        Route::post('/pembayaran/qris', 'qrisCreate');
        Route::get('/pembayaran/qris/{paymentId}/status', 'qrisStatus');

        Route::get('/cabang', 'cabangIndex');
        Route::post('/cabang', 'cabangStore');
        Route::get('/cabang/{id}', 'cabangShow');
        Route::put('/cabang/{id}', 'cabangUpdate');
        Route::delete('/cabang/{id}', 'cabangDestroy');
    });
});
