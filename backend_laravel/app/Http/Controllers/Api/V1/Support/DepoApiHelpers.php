<?php

namespace App\Http\Controllers\Api\V1\Support;

use App\Services\MidtransService;
use Carbon\Carbon;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Log;
use Illuminate\Support\Facades\Schema;
use Illuminate\Support\Str;
trait DepoApiHelpers
{
    private function produkBaseQuery()
    {
        return DB::table('produk as p')
            ->leftJoin('kategori as k', 'k.id', '=', 'p.kategori_id')
            ->select(
                'p.*',
                'k.id as kategori_id_full',
                'k.nama as kategori_nama',
                'k.deskripsi as kategori_deskripsi',
                'k.tipe as kategori_tipe',
                'k.ikon as kategori_ikon',
                'k.is_system as kategori_is_system',
                'k.is_aktif as kategori_is_aktif',
                'k.created_at as kategori_created_at'
            );
    }

    private function produkResponse(array $row): array
    {
        $produk = $this->camel([
            'id' => $row['id'],
            'nama' => $row['nama'],
            'kategori_id' => $row['kategori_id'],
            'harga' => $row['harga'],
            'stok' => $row['stok'],
            'deskripsi' => $row['deskripsi'],
            'gambar_url' => $row['gambar_url'],
            'is_aktif' => $row['is_aktif'],
            'created_at' => $row['created_at'],
            'updated_at' => $row['updated_at'] ?? null,
        ]);
        $produk['kategori'] = $row['kategori_id_full'] ? $this->camel([
            'id' => $row['kategori_id_full'],
            'nama' => $row['kategori_nama'],
            'deskripsi' => $row['kategori_deskripsi'],
            'tipe' => $row['kategori_tipe'],
            'ikon' => $row['kategori_ikon'],
            'is_system' => $row['kategori_is_system'],
            'is_aktif' => $row['kategori_is_aktif'],
            'created_at' => $row['kategori_created_at'],
        ]) : null;

        return $produk;
    }

    private function transaksiResponse(array $row): array
    {
        $trx = $this->camel($row);
        $trx['pelanggan'] = $row['pelanggan_id'] ? $this->camel((array) DB::table('pelanggan')->where('id', $row['pelanggan_id'])->first()) : null;
        $crew = $row['crew_id'] ? DB::table('users')->where('id', $row['crew_id'])->first() : null;
        $pengirimCrew = $row['pengirim_crew_id'] ? DB::table('users')->where('id', $row['pengirim_crew_id'])->first() : null;
        $trx['crew'] = $crew ? $this->crewResponse((array) $crew) : null;
        $trx['pengirimCrew'] = $pengirimCrew ? $this->crewResponse((array) $pengirimCrew) : null;
        $items = DB::table('transaksi_items')->where('transaksi_id', $row['id'])->get()->map(function ($item) {
            $mapped = $this->camel((array) $item);
            $produk = $this->produkBaseQuery()->where('p.id', $item->produk_id)->first();
            $mapped['produk'] = $produk ? $this->produkResponse((array) $produk) : null;

            return $mapped;
        })->all();
        $trx['items'] = $items;

        return $trx;
    }

    private function applyGalonFromItems(array $items, ?string $pelangganId, string $crewId, string $crewNama, string $trxId): void
    {
        $pinjam = 0;
        $kembali = 0;
        foreach ($items as $item) {
            $productId = $item['produk_id'] ?? $item['produkId'] ?? null;
            $produk = $productId ? DB::table('produk as p')->leftJoin('kategori as k', 'k.id', '=', 'p.kategori_id')->where('p.id', $productId)->select('p.nama as produk_nama', 'k.nama as kategori_nama')->first() : null;
            $name = strtolower(($produk->produk_nama ?? '').' '.($produk->kategori_nama ?? ''));
            if (str_contains($name, 'galon baru') || str_contains($name, 'penjualan galon') || preg_match('/(^|\s)galon(\s|$)/', $name)) {
                $pinjam += (int) ($item['jumlah'] ?? 0);
            }
            $pinjam += (int) ($item['galon_pinjam'] ?? $item['galonPinjam'] ?? 0);
            $kembali += (int) ($item['galon_kembali'] ?? $item['galonKembali'] ?? 0);
        }
        if ($kembali > 0) {
            $this->applyGalonMutasi('kembali', $kembali, compact('pelangganId') + ['pelanggan_id' => $pelangganId, 'catatan' => "Transaksi $trxId", 'crew_id' => $crewId, 'crew_nama' => $crewNama], false);
        }
        if ($pinjam > 0) {
            $this->applyGalonMutasi('pinjam', $pinjam, compact('pelangganId') + ['pelanggan_id' => $pelangganId, 'catatan' => "Transaksi $trxId", 'crew_id' => $crewId, 'crew_nama' => $crewNama], false);
        }
    }

    private function applyGalonMutasi(string $aksi, int $jumlah, array $meta = [], bool $wrap = true): array
    {
        $runner = function () use ($aksi, $jumlah, $meta) {
            $from = $aksi === 'pinjam' ? 'tersedia' : 'dipinjam';
            $to = $aksi === 'pinjam' ? 'dipinjam' : 'tersedia';
            $query = DB::table('galon')->where('status', $from)->orderBy('kode_galon')->limit(max(0, $jumlah))->lockForUpdate();
            if ($aksi === 'kembali' && ($meta['pelanggan_id'] ?? null)) {
                $query->where('pelanggan_id', $meta['pelanggan_id']);
            }
            $galons = $query->get();
            $codes = [];
            foreach ($galons as $galon) {
                DB::table('galon')->where('id', $galon->id)->update([
                    'status' => $to,
                    'pelanggan_id' => $aksi === 'pinjam' ? ($meta['pelanggan_id'] ?? null) : null,
                    'tanggal_pinjam' => $aksi === 'pinjam' ? ($meta['tanggal'] ?? now()) : null,
                    'catatan' => $aksi === 'pinjam' ? ($meta['catatan'] ?? null) : null,
                    'updated_at' => now(),
                ]);
                $codes[] = $galon->kode_galon;
            }
            if (count($codes) > 0) {
                $this->insertGalonMutasi([
                    'galon_id' => $galons[0]->id,
                    'aksi' => $aksi,
                    'jenis_mutasi' => $aksi,
                    'jumlah' => count($codes),
                    'kode_galon' => json_encode($codes),
                    'pelanggan_id' => $meta['pelanggan_id'] ?? null,
                    'catatan' => $meta['catatan'] ?? null,
                    'crew_id' => $meta['crew_id'] ?? null,
                    'crew_nama' => $meta['crew_nama'] ?? null,
                ]);
                if ($meta['pelanggan_id'] ?? null) {
                    $method = $aksi === 'pinjam' ? 'increment' : 'decrement';
                    DB::table('pelanggan')->where('id', $meta['pelanggan_id'])->$method('total_galon_pinjam', count($codes));
                }
            }

            return [
                'jumlah' => count($codes),
                'kodeList' => $codes,
                'summary' => $this->galonSummary(),
            ];
        };

        return $wrap ? DB::transaction($runner) : $runner();
    }

    private function insertGalonMutasi(array $data): void
    {
        $columns = Schema::getColumnListing('galon_mutasi');
        $row = ['id' => (string) Str::uuid(), 'created_at' => now()] + $data;
        DB::table('galon_mutasi')->insert(collect($row)->only($columns)->all());
    }

    private function nextGalonCode(int $offset = 0): string
    {
        $max = DB::table('galon')
            ->where('kode_galon', 'regexp', '^G-[0-9]+$')
            ->selectRaw("MAX(CAST(SUBSTRING(kode_galon, 3) AS UNSIGNED)) as max_number")
            ->value('max_number');

        return 'G-'.str_pad((string) (((int) $max) + 1 + $offset), 3, '0', STR_PAD_LEFT);
    }

    private function galonSummary(): array
    {
        $rows = DB::table('galon')->selectRaw("
            COUNT(*) as totalGalon,
            SUM(CASE WHEN status = 'tersedia' THEN 1 ELSE 0 END) as tersedia,
            SUM(CASE WHEN status = 'dipinjam' THEN 1 ELSE 0 END) as dipinjam,
            SUM(CASE WHEN status = 'rusak' THEN 1 ELSE 0 END) as rusak,
            SUM(CASE WHEN status = 'hilang' THEN 1 ELSE 0 END) as hilang
        ")->first();

        return [
            'totalGalon' => (int) ($rows->totalGalon ?? 0),
            'tersedia' => (int) ($rows->tersedia ?? 0),
            'dipinjam' => (int) ($rows->dipinjam ?? 0),
            'rusak' => (int) ($rows->rusak ?? 0),
            'hilang' => (int) ($rows->hilang ?? 0),
        ];
    }

    private function financialSummary(string $start, string $end): array
    {
        $pendapatan = (float) DB::table('transaksi')->where('status', 'selesai')->whereDate('created_at', '>=', $start)->whereDate('created_at', '<=', $end)->sum('total_harga');
        $pengeluaran = (float) DB::table('pengeluaran')->where('tanggal', '>=', $start)->where('tanggal', '<=', $end)->sum('nominal');
        $totalTransaksi = (int) DB::table('transaksi')->where('status', 'selesai')->whereDate('created_at', '>=', $start)->whereDate('created_at', '<=', $end)->count();
        $pengiriman = (int) DB::table('transaksi')->where('status', 'selesai')->where('tipe_pembelian', 'dikirim')->whereDate('created_at', '>=', $start)->whereDate('created_at', '<=', $end)->count();

        return [
            'totalPendapatan' => $pendapatan,
            'totalTransaksi' => $totalTransaksi,
            'totalPengeluaran' => $pengeluaran,
            'pendapatanBersih' => $pendapatan - $pengeluaran,
            'totalPengiriman' => $pengiriman,
        ];
    }

    private function categoryBreakdown(string $start, string $end): array
    {
        $pemasukan = DB::table('kategori as k')
            ->join('produk as p', 'p.kategori_id', '=', 'k.id')
            ->join('transaksi_items as ti', 'ti.produk_id', '=', 'p.id')
            ->join('transaksi as t', 't.id', '=', 'ti.transaksi_id')
            ->where('k.is_aktif', 1)
            ->where('t.status', 'selesai')
            ->whereDate('t.created_at', '>=', $start)
            ->whereDate('t.created_at', '<=', $end)
            ->groupBy('k.id', 'k.nama', 'k.tipe', 'k.ikon')
            ->selectRaw('k.id, k.nama, k.tipe, k.ikon, COALESCE(SUM(ti.subtotal), 0) as total, COALESCE(SUM(ti.jumlah), 0) as jumlah')
            ->get();

        $pengeluaran = DB::table('kategori as k')
            ->join('pengeluaran as p', 'p.kategori_id', '=', 'k.id')
            ->where('k.is_aktif', 1)
            ->where('p.tanggal', '>=', $start)
            ->where('p.tanggal', '<=', $end)
            ->groupBy('k.id', 'k.nama', 'k.tipe', 'k.ikon')
            ->selectRaw('k.id, k.nama, k.tipe, k.ikon, COALESCE(SUM(p.nominal), 0) as total, COUNT(p.id) as jumlah')
            ->get();

        return $pemasukan->merge($pengeluaran)
            ->map(fn ($row) => [
                'id' => $row->id,
                'nama' => $row->nama,
                'tipe' => $row->tipe ?: 'pemasukan',
                'ikon' => $row->ikon ?: 'category',
                'total' => (float) $row->total,
                'jumlah' => (int) $row->jumlah,
            ])
            ->sortByDesc('total')
            ->values()
            ->all();
    }

    private function pengirimanCrewData(?string $start = null, ?string $end = null, ?string $crewId = null): array
    {
        $query = DB::table('users as u')
            ->leftJoin('transaksi as t', function ($join) use ($start, $end) {
                $join->on('t.pengirim_crew_id', '=', 'u.id')
                    ->orOn(function ($q) {
                        $q->on('t.crew_id', '=', 'u.id')->whereNull('t.pengirim_crew_id');
                    });
            })
            ->where('u.role', 'crew')
            ->where('u.is_aktif', 1);
        if ($crewId) {
            $query->where('u.id', $crewId);
        }
        if ($start) {
            $query->whereDate('t.created_at', '>=', $start);
        }
        if ($end) {
            $query->whereDate('t.created_at', '<=', $end);
        }

        return $query->groupBy('u.id', 'u.nama')
            ->selectRaw("
                u.id as crewId,
                u.nama as crewNama,
                COUNT(t.id) as totalTransaksi,
                SUM(CASE WHEN t.tipe_pembelian = 'dikirim' THEN 1 ELSE 0 END) as totalKirim,
                SUM(CASE WHEN t.tipe_pembelian <> 'dikirim' OR t.tipe_pembelian IS NULL THEN 1 ELSE 0 END) as totalDiDepo,
                COALESCE(SUM(t.total_harga), 0) as totalNominal,
                COALESCE(SUM(t.total_ongkir), 0) as totalOngkir
            ")
            ->orderByDesc('totalTransaksi')
            ->get()
            ->map(fn ($row) => [
                'crewId' => $row->crewId,
                'crewNama' => $row->crewNama,
                'totalTransaksi' => (int) $row->totalTransaksi,
                'totalKirim' => (int) $row->totalKirim,
                'totalDiDepo' => (int) $row->totalDiDepo,
                'totalNominal' => (float) $row->totalNominal,
                'totalOngkir' => (float) $row->totalOngkir,
            ])->all();
    }

    private function paginate($query, Request $request, ?callable $mapper = null)
    {
        $page = max(1, (int) $request->query('page', 1));
        $limit = max(1, min(100, (int) $request->query('limit', 20)));
        $total = (clone $query)->count();
        $rows = $query->offset(($page - 1) * $limit)->limit($limit)->get()->all();
        $data = $mapper ? array_map($mapper, $rows) : $this->camel($rows);

        return response()->json([
            'data' => $data,
            'total' => $total,
            'page' => $page,
            'limit' => $limit,
            'totalPages' => max(1, (int) ceil($total / $limit)),
        ]);
    }

    private function showRow(string $table, string $id, string $notFound)
    {
        $row = DB::table($table)->where('id', $id)->first();
        if (! $row) {
            return response()->json(['message' => $notFound], 404);
        }

        return response()->json($this->camel((array) $row));
    }

    private function storeRefreshToken(string $token, string $userId): void
    {
        $row = ['token' => $token, 'user_id' => $userId, 'created_at' => now()];
        if (Schema::hasColumn('refresh_tokens', 'expires_at')) {
            $row['expires_at'] = now()->addDays(7);
        }
        DB::table('refresh_tokens')->insert($row);
    }

    private function withUpdatedAt(string $table, array $data): array
    {
        if (Schema::hasColumn($table, 'updated_at')) {
            $data['updated_at'] = now();
        }

        return $data;
    }

    private function qrisResponse(object $row): array
    {
        $value = fn (string $key, mixed $fallback = null) => property_exists($row, $key) ? $row->{$key} : $fallback;
        $redirectUrl = $value('redirect_url') ?: $value('payment_url') ?: $value('qr_content');
        $qrContent = $value('qr_content') ?: $redirectUrl;
        $qrImageUrl = is_string($qrContent)
            && (str_contains($qrContent, '/qr-code') || preg_match('/\.(png|jpg|jpeg)(\?|$)/i', $qrContent))
            ? $qrContent
            : null;
        $expiresAt = $value('expires_at') ?: $value('expired_at');

        return [
            'paymentId' => $row->payment_id,
            'transaksiId' => $row->transaksi_id,
            'transactionCode' => $value('transaction_code') ?: $row->payment_id,
            'orderId' => $value('order_id') ?: $value('midtrans_order_id') ?: $row->payment_id,
            'qrContent' => $redirectUrl,
            'qrImageUrl' => $qrImageUrl,
            'snapToken' => $value('snap_token'),
            'redirectUrl' => $redirectUrl,
            'paymentUrl' => $value('payment_url') ?: $redirectUrl,
            'jumlah' => (float) $row->jumlah,
            'grossAmount' => (float) ($value('gross_amount') ?: $row->jumlah),
            'status' => $row->status,
            'paymentStatus' => $value('payment_status') ?: $row->status,
            'transactionStatus' => $value('transaction_status') ?: $row->status,
            'expiresAt' => $expiresAt,
            'expiredAt' => $expiresAt,
            'namaDepot' => $value('nama_depot') ?: 'Depo Air Minum',
        ];
    }

    private function midtransSnapPayload(object $trx, string $paymentId): array
    {
        $pelanggan = $trx->pelanggan_id
            ? DB::table('pelanggan')->where('id', $trx->pelanggan_id)->first()
            : null;

        $payload = [
            'transaction_details' => [
                'order_id' => $paymentId,
                'gross_amount' => (int) round((float) $trx->total_harga),
            ],
            'enabled_payments' => ['qris'],
            'expiry' => [
                'unit' => 'minutes',
                'duration' => 15,
            ],
            'custom_field1' => $trx->id,
        ];

        if ($pelanggan) {
            $payload['customer_details'] = [
                'first_name' => $pelanggan->nama,
                'phone' => $pelanggan->no_hp,
                'billing_address' => [
                    'first_name' => $pelanggan->nama,
                    'phone' => $pelanggan->no_hp,
                    'address' => $pelanggan->alamat,
                ],
            ];
        }

        return $payload;
    }

    private function insertQrPayment(array $data): void
    {
        $columns = Schema::getColumnListing('qr_payments');
        DB::table('qr_payments')->insert(collect($data)->only($columns)->all());
    }

    private function findQrPaymentByOrderId(string $orderId): ?object
    {
        if ($orderId === '') {
            return null;
        }

        $query = DB::table('qr_payments')->where('payment_id', $orderId);
        if (Schema::hasColumn('qr_payments', 'midtrans_order_id')) {
            $query->orWhere('midtrans_order_id', $orderId);
        }
        if (Schema::hasColumn('qr_payments', 'order_id')) {
            $query->orWhere('order_id', $orderId);
        }

        return $query->first();
    }

    private function applyMidtransPaymentStatus(object $row, array $payload, MidtransService $midtrans): void
    {
        $status = $midtrans->mapPaymentStatus($payload);
        $paidStatuses = ['settlement', 'capture', 'paid'];
        $failedStatuses = ['expire', 'expired', 'cancel', 'deny', 'failure', 'failed'];
        $update = [
            'status' => $status,
            'updated_at' => now(),
        ];

        if (Schema::hasColumn('qr_payments', 'payment_status')) {
            $update['payment_status'] = $status;
        }
        if (Schema::hasColumn('qr_payments', 'transaction_status')) {
            $update['transaction_status'] = (string) ($payload['transaction_status'] ?? $status);
        }
        if (Schema::hasColumn('qr_payments', 'payment_type')) {
            $update['payment_type'] = $payload['payment_type'] ?? null;
        }
        if (Schema::hasColumn('qr_payments', 'gateway_response')) {
            $update['gateway_response'] = json_encode($payload);
        }

        if (in_array($status, $paidStatuses, true)) {
            $update['paid_at'] = $row->paid_at ?: now();
        }

        DB::table('qr_payments')->where('payment_id', $row->payment_id)->update($update);

        Log::info('Status pembayaran QRIS diperbarui', [
            'payment_id' => $row->payment_id,
            'transaksi_id' => $row->transaksi_id,
            'status' => $status,
            'transaction_status' => $payload['transaction_status'] ?? null,
        ]);

        if (in_array($status, $paidStatuses, true)) {
            DB::table('transaksi')->where('id', $row->transaksi_id)->update([
                'qr_paid_at' => $row->paid_at ?: now(),
                'status' => 'menungguValidasi',
                'updated_at' => now(),
            ]);
        } elseif (in_array($status, $failedStatuses, true)) {
            DB::table('transaksi')->where('id', $row->transaksi_id)->update([
                'status' => 'dibatalkan',
                'updated_at' => now(),
            ]);
        }
    }

    private function userData(array $user): array
    {
        return [
            'id' => $user['id'],
            'nama' => $user['nama'],
            'email' => $user['email'] ?? null,
            'noHp' => $user['no_hp'] ?? '',
            'alamat' => $user['alamat'] ?? '',
            'isAktif' => (bool) ($user['is_aktif'] ?? true),
        ];
    }

    private function crewResponse(array $user): array
    {
        return [
            'id' => $user['id'],
            'nama' => $user['nama'],
            'noHp' => $user['no_hp'] ?? '',
            'alamat' => $user['alamat'] ?? '',
            'isAktif' => (bool) ($user['is_aktif'] ?? true),
            'fotoUrl' => $user['foto_url'] ?? null,
            'createdAt' => $this->dateValue($user['created_at'] ?? null),
            'updatedAt' => $this->dateValue($user['updated_at'] ?? null),
        ];
    }

    private function auth(Request $request): array
    {
        return (array) $request->attributes->get('auth_user', []);
    }

    private function managerOnly(Request $request): void
    {
        if (($this->auth($request)['role'] ?? null) !== 'manager') {
            abort(response()->json(['message' => 'Akses khusus manager'], 403));
        }
    }

    private function camel(mixed $value): mixed
    {
        if (is_array($value)) {
            if (array_is_list($value)) {
                return array_map(fn ($item) => $this->camel(is_object($item) ? (array) $item : $item), $value);
            }
            $out = [];
            foreach ($value as $key => $item) {
                $camelKey = preg_replace_callback('/_([a-z0-9])/', fn ($m) => strtoupper($m[1]), (string) $key);
                $out[$camelKey] = $this->normalize($camelKey, $item);
            }

            return $out;
        }
        if (is_object($value)) {
            return $this->camel((array) $value);
        }

        return $value;
    }

    private function normalize(string $key, mixed $value): mixed
    {
        if (in_array($key, ['isAktif', 'isSystem', 'isPusat'], true)) {
            return (bool) $value;
        }
        if (in_array($key, ['harga', 'nominal', 'totalHarga', 'bayar', 'kembalian', 'hargaSatuan', 'subtotal', 'jumlah', 'totalTransaksi', 'totalOngkir'], true)) {
            return is_numeric($value) ? (float) $value : $value;
        }

        return $this->dateValue($value);
    }

    private function dateValue(mixed $value): mixed
    {
        if ($value instanceof \DateTimeInterface) {
            return Carbon::instance($value)->timezone('Asia/Jakarta')->toAtomString();
        }

        if (is_string($value) && preg_match('/^\d{4}-\d{2}-\d{2}[ T]\d{2}:\d{2}:\d{2}/', $value)) {
            return Carbon::parse($value, 'Asia/Jakarta')->timezone('Asia/Jakarta')->toAtomString();
        }

        return $value;
    }
}
