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
class KategoriController extends Controller
{
    use DepoApiHelpers;

    public function kategoriIndex()
    {
        return response()->json($this->camel(DB::table('kategori')->where('is_aktif', 1)->orderBy('nama')->get()->all()));
    }

    public function kategoriStore(Request $request)
    {
        $this->managerOnly($request);
        $request->validate(['nama' => ['required', 'string', 'max:100']]);
        $id = (string) Str::uuid();
        DB::table('kategori')->insert([
            'id' => $id,
            'nama' => trim((string) $request->input('nama')),
            'deskripsi' => $request->input('deskripsi'),
            'tipe' => $request->input('tipe') === 'pengeluaran' ? 'pengeluaran' : 'pemasukan',
            'ikon' => $request->input('ikon'),
            'is_system' => $request->boolean('isSystem') ? 1 : 0,
            'is_aktif' => 1,
            'created_at' => now(),
        ]);

        return response()->json($this->camel((array) DB::table('kategori')->where('id', $id)->first()), 201);
    }

    public function kategoriUpdate(Request $request, string $id)
    {
        $this->managerOnly($request);
        $current = DB::table('kategori')->where('id', $id)->first();
        if (! $current) {
            return response()->json(['message' => 'Kategori tidak ditemukan'], 404);
        }
        DB::table('kategori')->where('id', $id)->update([
            'nama' => $request->input('nama', $current->nama),
            'deskripsi' => $request->input('deskripsi', $current->deskripsi),
            'tipe' => $request->input('tipe', $current->tipe),
            'ikon' => $request->input('ikon', $current->ikon),
            'is_system' => $request->has('isSystem') ? ($request->boolean('isSystem') ? 1 : 0) : $current->is_system,
        ]);

        return response()->json($this->camel((array) DB::table('kategori')->where('id', $id)->first()));
    }

    public function kategoriDestroy(Request $request, string $id)
    {
        $this->managerOnly($request);
        $row = DB::table('kategori')->where('id', $id)->first();
        if (! $row) {
            return response()->json(['message' => 'Kategori tidak ditemukan'], 404);
        }
        if ((int) $row->is_system === 1) {
            return response()->json(['message' => 'Kategori sistem tidak dapat dihapus'], 403);
        }
        DB::table('kategori')->where('id', $id)->update(['is_aktif' => 0]);

        return response()->noContent();
    }
}
