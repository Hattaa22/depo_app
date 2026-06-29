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
class CabangController extends Controller
{
    use DepoApiHelpers;

    public function cabangIndex(Request $request)
    {
        $query = DB::table('cabang');
        if (! in_array((string) $request->query('all'), ['1', 'true'], true)) {
            $query->where('is_aktif', 1);
        }

        return response()->json($this->camel($query->orderByDesc('is_pusat')->orderBy('nama')->get()->all()));
    }

    public function cabangShow(string $id)
    {
        return $this->showRow('cabang', $id, 'Cabang tidak ditemukan');
    }

    public function cabangStore(Request $request)
    {
        $this->managerOnly($request);
        $request->validate(['nama' => ['required', 'string']]);
        $id = (string) Str::uuid();
        if ($request->boolean('isPusat')) {
            DB::table('cabang')->update(['is_pusat' => 0]);
        }
        DB::table('cabang')->insert([
            'id' => $id,
            'nama' => $request->input('nama'),
            'alamat' => $request->input('alamat'),
            'kota' => $request->input('kota'),
            'no_hp' => $request->input('noHp'),
            'is_pusat' => $request->boolean('isPusat') ? 1 : 0,
            'is_aktif' => 1,
            'created_at' => now(),
        ]);

        return $this->showRow('cabang', $id, 'Cabang tidak ditemukan')->setStatusCode(201);
    }

    public function cabangUpdate(Request $request, string $id)
    {
        $this->managerOnly($request);
        $current = DB::table('cabang')->where('id', $id)->first();
        if (! $current) {
            return response()->json(['message' => 'Cabang tidak ditemukan'], 404);
        }
        if ($request->boolean('isPusat')) {
            DB::table('cabang')->where('id', '!=', $id)->update(['is_pusat' => 0]);
        }
        DB::table('cabang')->where('id', $id)->update([
            'nama' => $request->input('nama', $current->nama),
            'alamat' => $request->input('alamat', $current->alamat),
            'kota' => $request->input('kota', $current->kota),
            'no_hp' => $request->input('noHp', $current->no_hp),
            'is_pusat' => $request->has('isPusat') ? ($request->boolean('isPusat') ? 1 : 0) : $current->is_pusat,
            'is_aktif' => $request->has('isAktif') ? ($request->boolean('isAktif') ? 1 : 0) : $current->is_aktif,
            'updated_at' => now(),
        ]);

        return $this->showRow('cabang', $id, 'Cabang tidak ditemukan');
    }

    public function cabangDestroy(Request $request, string $id)
    {
        $this->managerOnly($request);
        DB::table('cabang')->where('id', $id)->update(['is_aktif' => 0, 'updated_at' => now()]);

        return response()->noContent();
    }
}
