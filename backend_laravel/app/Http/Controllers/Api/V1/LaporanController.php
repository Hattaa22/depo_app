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
class LaporanController extends Controller
{
    use DepoApiHelpers;

    public function laporanKeuangan(Request $request)
    {
        $mulai = $request->query('tanggalMulai', now()->toDateString());
        $akhir = $request->query('tanggalAkhir', now()->toDateString());
        $tx = DB::table('transaksi')->where('status', 'selesai')->whereDate('created_at', '>=', $mulai)->whereDate('created_at', '<=', $akhir)->get();
        $pengeluaran = DB::table('pengeluaran')->where('tanggal', '>=', $mulai)->where('tanggal', '<=', $akhir)->get();

        return response()->json([
            'tanggalMulai' => $mulai,
            'tanggalAkhir' => $akhir,
            'totalPendapatan' => (float) $tx->sum('total_harga'),
            'totalPengeluaran' => (float) $pengeluaran->sum('nominal'),
            'pendapatanBersih' => (float) $tx->sum('total_harga') - (float) $pengeluaran->sum('nominal'),
            'totalTransaksi' => $tx->count(),
            'transaksiSelesai' => $tx->count(),
            'transaksiDibatalkan' => (int) DB::table('transaksi')->where('status', 'dibatalkan')->count(),
            'pendapatanTunai' => (float) $tx->where('metode_pembayaran', 'tunai')->sum('total_harga'),
            'pendapatanQris' => (float) $tx->where('metode_pembayaran', 'qris')->sum('total_harga'),
            'pendapatanTransfer' => (float) $tx->where('metode_pembayaran', 'transfer')->sum('total_harga'),
            'totalDikirim' => $tx->where('tipe_pembelian', 'dikirim')->count(),
            'totalDiDepo' => $tx->where('tipe_pembelian', '!=', 'dikirim')->count(),
            'transaksiCrew' => $this->pengirimanCrewData($mulai, $akhir),
            'breakdown' => [],
        ]);
    }

    public function pengirimanCrew(Request $request)
    {
        return response()->json($this->pengirimanCrewData(
            $request->query('tanggalMulai'),
            $request->query('tanggalAkhir'),
            $this->auth($request)['role'] === 'manager' ? null : $this->auth($request)['sub'],
        ));
    }
}
