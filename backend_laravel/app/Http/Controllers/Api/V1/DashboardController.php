<?php

namespace App\Http\Controllers\Api\V1;

use App\Http\Controllers\Api\V1\Support\DepoApiHelpers;
use App\Http\Controllers\Controller;
use App\Services\MidtransService;
use App\Services\ApiTokenService;
use Illuminate\Http\Client\RequestException;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Facades\Log;
use Illuminate\Support\Facades\Schema;
use Illuminate\Support\Str;
use Throwable;
class DashboardController extends Controller
{
    use DepoApiHelpers;

    public function dashboardCrew(Request $request)
    {
        $crewId = $this->auth($request)['sub'];
        $today = now()->toDateString();
        $tx = DB::table('transaksi')
            ->where('status', 'selesai')
            ->whereDate('created_at', $today)
            ->where(function ($q) use ($crewId) {
                $q->where('crew_id', $crewId)->orWhere('pengirim_crew_id', $crewId);
            })
            ->get();
        $ids = $tx->pluck('id')->all();
        $totalGalon = count($ids)
            ? (int) DB::table('transaksi_items')->whereIn('transaksi_id', $ids)->sum('jumlah')
            : 0;

        return response()->json([
            'totalPenjualanHarian' => (float) $tx->sum('total_harga'),
            'totalGalonTerjual' => $totalGalon,
        ]);
    }

    public function dashboardManager()
    {
        $today = now()->toDateString();
        $monthStart = now()->startOfMonth()->toDateString();

        return response()->json([
            'harian' => $this->financialSummary($today, $today),
            'bulanan' => $this->financialSummary($monthStart, $today),
            'semua' => $this->financialSummary('2000-01-01', $today),
            'galonBersih' => (int) DB::table('galon')->where('status', 'tersedia')->count(),
            'tersedia' => (int) DB::table('galon')->where('status', 'tersedia')->count(),
            'totalPelanggan' => (int) DB::table('pelanggan')->count(),
            'totalPendapatanHarian' => (float) DB::table('transaksi')->where('status', 'selesai')->whereDate('created_at', $today)->sum('total_harga'),
            'totalTransaksiHari' => (int) DB::table('transaksi')->where('status', 'selesai')->whereDate('created_at', $today)->count(),
            'breakdown' => ['harian' => [], 'bulanan' => [], 'semua' => []],
        ]);
    }
}
