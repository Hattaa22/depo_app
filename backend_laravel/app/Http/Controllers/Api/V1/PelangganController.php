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
class PelangganController extends Controller
{
    use DepoApiHelpers;

    public function pelangganIndex(Request $request)
    {
        $query = DB::table('pelanggan');
        if ($request->filled('search')) {
            $search = '%'.strtolower((string) $request->query('search')).'%';
            $query->where(function ($q) use ($search) {
                $q->whereRaw('LOWER(nama) LIKE ?', [$search])->orWhere('no_hp', 'like', $search);
            });
        }

        return $this->paginate($query->orderBy('nama'), $request);
    }

    public function pelangganShow(string $id)
    {
        return $this->showRow('pelanggan', $id, 'Pelanggan tidak ditemukan');
    }

    public function pelangganStore(Request $request)
    {
        $data = $request->validate(['nama' => ['required', 'string', 'max:150']]);
        $id = (string) Str::uuid();
        DB::table('pelanggan')->insert([
            'id' => $id,
            'nama' => trim($data['nama']),
            'no_hp' => $request->input('noHp', ''),
            'alamat' => $request->input('alamat'),
            'total_galon_pinjam' => (int) $request->input('totalGalonPinjam', 0),
            'total_transaksi' => 0,
            'catatan' => $request->input('catatan'),
            'is_aktif' => $request->has('isAktif') ? ($request->boolean('isAktif') ? 1 : 0) : 1,
            'created_at' => now(),
        ]);

        return response()->json($this->camel((array) DB::table('pelanggan')->where('id', $id)->first()), 201);
    }

    public function pelangganUpdate(Request $request, string $id)
    {
        $current = DB::table('pelanggan')->where('id', $id)->first();
        if (! $current) {
            return response()->json(['message' => 'Pelanggan tidak ditemukan'], 404);
        }
        DB::table('pelanggan')->where('id', $id)->update($this->withUpdatedAt('pelanggan', [
            'nama' => $request->input('nama', $current->nama),
            'no_hp' => $request->input('noHp', $current->no_hp),
            'alamat' => $request->input('alamat', $current->alamat),
            'total_galon_pinjam' => $request->has('totalGalonPinjam') ? (int) $request->input('totalGalonPinjam') : $current->total_galon_pinjam,
            'catatan' => $request->input('catatan', $current->catatan),
            'is_aktif' => $request->has('isAktif') ? ($request->boolean('isAktif') ? 1 : 0) : $current->is_aktif,
        ]));

        return response()->json($this->camel((array) DB::table('pelanggan')->where('id', $id)->first()));
    }

    public function pelangganDestroy(Request $request, string $id)
    {
        $this->managerOnly($request);

        DB::table('pelanggan')->where('id', $id)->update($this->withUpdatedAt('pelanggan', ['is_aktif' => 0]));

        return response()->noContent();
    }
}
