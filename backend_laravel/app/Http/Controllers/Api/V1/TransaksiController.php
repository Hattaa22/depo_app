<?php

namespace App\Http\Controllers\Api\V1;

use App\Http\Controllers\Api\V1\Support\DepoApiHelpers;
use App\Http\Controllers\Controller;
use App\Services\MidtransService;
use App\Services\ApiTokenService;
use Illuminate\Http\Client\RequestException;
use Illuminate\Http\Exceptions\HttpResponseException;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Facades\Log;
use Illuminate\Support\Facades\Schema;
use Illuminate\Validation\Rule;
use Illuminate\Support\Str;
use Throwable;

class TransaksiController extends Controller
{
    use DepoApiHelpers;

    public function transaksiIndex(Request $request)
    {
        $query = DB::table('transaksi');
        if ($request->filled('status')) {
            $query->whereIn('status', explode(',', (string) $request->query('status')));
        }
        if ($request->filled('crewId')) {
            $crewId = $request->query('crewId');
            $query->where(function ($crewQuery) use ($crewId) {
                $crewQuery
                    ->where('crew_id', $crewId)
                    ->orWhere('pengirim_crew_id', $crewId);
            });
        }
        if ($request->filled('tanggalMulai')) {
            $query->where('created_at', '>=', $request->query('tanggalMulai'));
        }
        if ($request->filled('tanggalAkhir')) {
            $query->where('created_at', '<=', $request->query('tanggalAkhir').' 23:59:59');
        }

        return $this->paginate($query->orderByDesc('created_at'), $request, fn ($row) => $this->transaksiResponse((array) $row));
    }

    public function transaksiShow(string $id)
    {
        $row = DB::table('transaksi')->where('id', $id)->first();
        if (! $row) {
            return response()->json(['message' => 'Transaksi tidak ditemukan'], 404);
        }

        return response()->json($this->transaksiResponse((array) $row));
    }

    public function transaksiStore(Request $request)
    {
        Log::info('Request transaksi masuk', [
            'metodePembayaran' => $request->input('metodePembayaran'),
            'pelangganId' => $request->input('pelangganId'),
            'jumlahItem' => is_array($request->input('items')) ? count($request->input('items')) : 0,
        ]);

        $itemsIn = $request->input('items', []);
        if (! is_array($itemsIn) || count($itemsIn) === 0) {
            return response()->json(['message' => 'Transaksi harus memiliki minimal 1 item'], 400);
        }
        if (! $request->filled('pelangganId')) {
            return response()->json(['message' => 'Pelanggan wajib dipilih'], 400);
        }
        $metode = $request->input('metodePembayaran', 'tunai');
        if (! in_array($metode, ['tunai', 'qris', 'transfer'], true)) {
            return response()->json(['message' => 'Metode pembayaran tidak valid'], 400);
        }

        $trxId = (string) Str::uuid();
        $auth = $this->auth($request);
        $crewId = $request->input('crewId', $auth['sub']);
        $isQris = $metode === 'qris';
        $items = [];
        $total = 0;

        try {
            return DB::transaction(function () use ($request, $itemsIn, $metode, $trxId, $crewId, $isQris, &$items, &$total, $auth) {
                foreach ($itemsIn as $itemIn) {
                    $product = DB::table('produk')->where('id', $itemIn['produkId'] ?? '')->first();
                    if (! $product) {
                        abort(response()->json(['message' => 'Produk tidak ditemukan'], 400));
                    }
                    $jumlah = (int) ($itemIn['jumlah'] ?? 0);
                    if ($jumlah <= 0) {
                        abort(response()->json(['message' => 'Jumlah item harus lebih dari 0'], 400));
                    }
                    $subtotal = ((float) $product->harga) * $jumlah;
                    $total += $subtotal;
                    $items[] = [
                        'id' => (string) Str::uuid(),
                        'transaksi_id' => $trxId,
                        'produk_id' => $product->id,
                        'jumlah' => $jumlah,
                        'harga_satuan' => $product->harga,
                        'subtotal' => $subtotal,
                        'galon_pinjam' => (int) ($itemIn['galonPinjam'] ?? 0),
                        'galon_kembali' => (int) ($itemIn['galonKembali'] ?? 0),
                    ];
                }

                $tipePembelian = $request->input('tipePembelian') === 'dikirim' ? 'dikirim' : 'di_depo';
                $pengirimCrewId = $tipePembelian === 'dikirim' ? $request->input('pengirimCrewId') : null;
                if ($tipePembelian === 'dikirim' && ! $pengirimCrewId) {
                    abort(response()->json(['message' => 'Crew pengirim wajib dipilih untuk transaksi dikirim'], 400));
                }
                $jumlahGalon = collect($items)->sum('jumlah');
                $ongkirPerGalon = 0;
                $totalOngkir = 0;
                if ($tipePembelian === 'dikirim') {
                    $ongkirPerGalon = ((int) $request->input('ongkirPerGalon')) === 2000 ? 2000 : 1000;
                    $totalOngkir = $ongkirPerGalon * $jumlahGalon;
                    $total += $totalOngkir;
                }

                Log::info('Generate nomor transaksi', [
                    'transaksi_id' => $trxId,
                    'metode_pembayaran' => $metode,
                    'total_harga' => $total,
                ]);

                DB::table('transaksi')->insert([
                    'id' => $trxId,
                    'nomor_transaksi' => (string) round(microtime(true) * 1000),
                    'pelanggan_id' => $request->input('pelangganId'),
                    'crew_id' => $crewId,
                    'pengirim_crew_id' => $pengirimCrewId,
                    'total_harga' => $total,
                    'metode_pembayaran' => $metode,
                    'status' => $isQris ? 'pending' : 'selesai',
                    'status_validasi' => $isQris ? 'belumDivalidasi' : 'valid',
                    'bayar' => $request->input('bayar'),
                    'kembalian' => $request->input('kembalian'),
                    'qr_payment_id' => null,
                    'catatan' => $request->input('catatan'),
                    'tipe_pembelian' => $tipePembelian,
                    'ongkir_per_galon' => $ongkirPerGalon,
                    'total_ongkir' => $totalOngkir,
                    'created_at' => now(),
                ]);
                DB::table('transaksi_items')->insert($items);

                if (! $isQris) {
                    DB::table('pelanggan')->where('id', $request->input('pelangganId'))->increment('total_transaksi', $total);
                    $this->applyGalonFromItems($items, $request->input('pelangganId'), $crewId, $auth['nama'], $trxId);
                }

                Log::info('Transaksi berhasil disimpan', [
                    'transaksi_id' => $trxId,
                    'status' => $isQris ? 'pending' : 'selesai',
                ]);

                return response()->json($this->transaksiResponse((array) DB::table('transaksi')->where('id', $trxId)->first()), 201);
            });
        } catch (HttpResponseException $e) {
            throw $e;
        } catch (Throwable $e) {
            Log::error('Gagal menyimpan transaksi', [
                'metodePembayaran' => $metode,
                'pelangganId' => $request->input('pelangganId'),
                'error' => $e->getMessage(),
                'trace' => $e->getTraceAsString(),
            ]);

            return response()->json([
                'success' => false,
                'message' => 'Gagal menyimpan transaksi',
                'error' => $e->getMessage(),
            ], 500);
        }
    }

    public function transaksiStatus(Request $request, string $id)
    {
        $this->managerOnly($request);
        $data = $request->validate([
            'status' => ['required', 'string', Rule::in(['pending', 'menungguValidasi', 'selesai', 'dibatalkan'])],
        ]);

        if (! DB::table('transaksi')->where('id', $id)->exists()) {
            return response()->json(['message' => 'Transaksi tidak ditemukan'], 404);
        }
        DB::table('transaksi')->where('id', $id)->update(['status' => $data['status'], 'updated_at' => now()]);

        return $this->transaksiShow($id);
    }

    public function transaksiValidasi(Request $request, string $id)
    {
        $this->managerOnly($request);
        $data = $request->validate([
            'status' => ['required', 'string', Rule::in(['sukses', 'gagal'])],
        ]);

        $auth = $this->auth($request);
        return DB::transaction(function () use ($id, $auth, $data) {
            $trx = DB::table('transaksi')->where('id', $id)->lockForUpdate()->first();
            if (! $trx) {
                return response()->json(['message' => 'Transaksi tidak ditemukan'], 404);
            }

            if (in_array($trx->status_validasi, ['valid', 'invalid'], true)) {
                return $this->transaksiShow($id);
            }

            $status = $data['status'];
            $nextStatus = $trx->status;
            $nextValidasi = $trx->status_validasi;
            if ($status === 'sukses') {
                $nextStatus = 'selesai';
                $nextValidasi = 'valid';
                DB::table('pelanggan')->where('id', $trx->pelanggan_id)->increment('total_transaksi', (float) $trx->total_harga);
                $items = DB::table('transaksi_items')->where('transaksi_id', $id)->get()->map(fn ($row) => (array) $row)->all();
                $this->applyGalonFromItems($items, $trx->pelanggan_id, $trx->crew_id, $auth['nama'], $id);
            } elseif ($status === 'gagal') {
                $nextStatus = 'dibatalkan';
                $nextValidasi = 'invalid';
            }
            DB::table('transaksi')->where('id', $id)->update([
                'status' => $nextStatus,
                'status_validasi' => $nextValidasi,
                'validasi_oleh' => $auth['sub'],
                'validasi_at' => now(),
                'updated_at' => now(),
            ]);

            return $this->transaksiShow($id);
        });
    }
}
