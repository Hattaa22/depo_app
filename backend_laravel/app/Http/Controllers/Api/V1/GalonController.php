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
class GalonController extends Controller
{
    use DepoApiHelpers;

    public function galonRingkasan()
    {
        return response()->json($this->galonSummary());
    }

    public function galonIndex(Request $request)
    {
        $query = DB::table('galon as g')
            ->leftJoin('pelanggan as p', 'p.id', '=', 'g.pelanggan_id')
            ->select(
                'g.*',
                'p.nama as pelanggan_nama',
                'p.no_hp as pelanggan_no_hp',
                'p.alamat as pelanggan_alamat',
                DB::raw('(select gm.crew_id from galon_mutasi gm where gm.galon_id = g.id order by gm.created_at desc limit 1) as mutasi_crew_id'),
                DB::raw('(select gm.crew_nama from galon_mutasi gm where gm.galon_id = g.id order by gm.created_at desc limit 1) as mutasi_crew_nama'),
                DB::raw('(select gm.jenis_mutasi from galon_mutasi gm where gm.galon_id = g.id order by gm.created_at desc limit 1) as mutasi_jenis'),
                DB::raw('(select gm.status_dari from galon_mutasi gm where gm.galon_id = g.id order by gm.created_at desc limit 1) as mutasi_status_dari'),
                DB::raw('(select gm.status_ke from galon_mutasi gm where gm.galon_id = g.id order by gm.created_at desc limit 1) as mutasi_status_ke'),
                DB::raw('(select gm.created_at from galon_mutasi gm where gm.galon_id = g.id order by gm.created_at desc limit 1) as mutasi_created_at')
            );
        if ($request->filled('status')) {
            $query->where('g.status', $request->query('status'));
        }

        return $this->paginate($query->orderBy('g.kode_galon'), $request);
    }

    public function galonMutasi(Request $request)
    {
        $rows = DB::table('galon_mutasi')->orderByDesc('created_at')->limit(min(100, (int) $request->query('limit', 30)))->get();
        $data = collect($this->camel($rows->all()))->map(function ($row) {
            if (isset($row['kodeGalon']) && is_string($row['kodeGalon'])) {
                $decoded = json_decode($row['kodeGalon'], true);
                $row['kodeGalon'] = is_array($decoded) ? $decoded : [];
            }

            return $row;
        });

        return response()->json($data->values()->all());
    }

    public function galonStore(Request $request)
    {
        $count = max(1, (int) $request->input('jumlah', 1));
        $created = [];
        for ($i = 0; $i < $count; $i++) {
            $id = (string) Str::uuid();
            $code = $count === 1 && $request->filled('kodeGalon')
                ? (string) $request->input('kodeGalon')
                : $this->nextGalonCode($i);
            DB::table('galon')->insert([
                'id' => $id,
                'kode_galon' => $code,
                'merek' => 'Depo',
                'jenis' => $request->input('jenis', 'isi'),
                'status' => $request->input('status', 'tersedia'),
                'pelanggan_id' => $request->input('pelangganId'),
                'tanggal_pinjam' => $request->input('status') === 'dipinjam' ? now() : null,
                'catatan' => $request->input('catatan'),
                'created_at' => now(),
            ]);
            $created[] = $this->camel((array) DB::table('galon')->where('id', $id)->first());
        }

        return response()->json(array_merge($created[0], [
            'createdCount' => $count,
            'galons' => $count > 1 ? $created : null,
        ]), 201);
    }

    public function galonUpdate(Request $request, string $id)
    {
        $current = DB::table('galon')->where('id', $id)->first();
        if (! $current) {
            return response()->json(['message' => 'Galon tidak ditemukan'], 404);
        }
        $nextStatus = $request->input('status', $current->status);
        DB::table('galon')->where('id', $id)->update([
            'kode_galon' => $request->input('kodeGalon', $current->kode_galon),
            'merek' => 'Depo',
            'jenis' => $request->input('jenis', $current->jenis),
            'status' => $nextStatus,
            'pelanggan_id' => $request->has('pelangganId') ? $request->input('pelangganId') : $current->pelanggan_id,
            'tanggal_pinjam' => $nextStatus === 'dipinjam' ? ($current->tanggal_pinjam ?: now()) : null,
            'catatan' => $request->input('catatan', $current->catatan),
            'updated_at' => now(),
        ]);

        if ($request->filled('status') && $request->input('status') !== $current->status) {
            $jenisMutasi = match ($nextStatus) {
                'dipinjam' => 'pinjam',
                'tersedia' => 'kembali',
                'rusak' => 'rusak',
                'hilang' => 'hilang',
                default => 'perbaiki',
            };
            $this->insertGalonMutasi([
                'galon_id' => $id,
                'aksi' => 'ubah_status',
                'jenis_mutasi' => $jenisMutasi,
                'jumlah' => 1,
                'kode_galon' => json_encode([$request->input('kodeGalon', $current->kode_galon)]),
                'status_dari' => $current->status,
                'status_ke' => $request->input('status'),
                'crew_id' => $this->auth($request)['sub'],
                'crew_nama' => $this->auth($request)['nama'],
            ]);
        }

        return response()->json($this->camel((array) DB::table('galon')->where('id', $id)->first()));
    }

    public function galonPinjam(Request $request)
    {
        return response()->json($this->applyGalonMutasi('pinjam', (int) $request->input('jumlah'), [
            'pelanggan_id' => $request->input('pelangganId'),
            'catatan' => $request->input('catatan'),
            'crew_id' => $this->auth($request)['sub'],
            'crew_nama' => $this->auth($request)['nama'],
            'tanggal' => $request->input('tanggal'),
        ]));
    }

    public function galonKembali(Request $request)
    {
        return response()->json($this->applyGalonMutasi('kembali', (int) $request->input('jumlah'), [
            'pelanggan_id' => $request->input('pelangganId'),
            'catatan' => $request->input('catatan'),
            'crew_id' => $this->auth($request)['sub'],
            'crew_nama' => $this->auth($request)['nama'],
            'tanggal' => $request->input('tanggal'),
        ]));
    }
}
