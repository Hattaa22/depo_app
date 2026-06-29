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
class ProdukController extends Controller
{
    use DepoApiHelpers;

    public function produkIndex(Request $request)
    {
        $query = $this->produkBaseQuery()->where('p.is_aktif', 1);
        if ($request->filled('kategoriId')) {
            $query->where('p.kategori_id', $request->query('kategoriId'));
        }
        if ($request->filled('search')) {
            $query->whereRaw('LOWER(p.nama) LIKE ?', ['%'.strtolower((string) $request->query('search')).'%']);
        }

        return $this->paginate($query->orderBy('p.nama'), $request, fn ($row) => $this->produkResponse((array) $row));
    }

    public function produkShow(string $id)
    {
        $row = $this->produkBaseQuery()->where('p.id', $id)->first();
        if (! $row) {
            return response()->json(['message' => 'Produk tidak ditemukan'], 404);
        }

        return response()->json($this->produkResponse((array) $row));
    }

    public function produkStore(Request $request)
    {
        $this->managerOnly($request);
        $request->validate(['nama' => ['required', 'string', 'max:150']]);
        $kategoriId = $request->input('kategoriId') ?: DB::table('kategori')->where('is_aktif', 1)->value('id');
        if (! $kategoriId) {
            return response()->json(['message' => 'Buat kategori produk terlebih dahulu'], 400);
        }
        $id = (string) Str::uuid();
        DB::table('produk')->insert([
            'id' => $id,
            'nama' => trim((string) $request->input('nama')),
            'kategori_id' => $kategoriId,
            'harga' => (float) $request->input('harga', 0),
            'stok' => (int) $request->input('stok', 0),
            'deskripsi' => $request->input('deskripsi'),
            'gambar_url' => $request->input('gambarUrl'),
            'is_aktif' => $request->has('isAktif') ? ($request->boolean('isAktif') ? 1 : 0) : 1,
            'created_at' => now(),
        ]);

        return $this->produkShow($id)->setStatusCode(201);
    }

    public function produkUpdate(Request $request, string $id)
    {
        $this->managerOnly($request);
        $current = DB::table('produk')->where('id', $id)->first();
        if (! $current) {
            return response()->json(['message' => 'Produk tidak ditemukan'], 404);
        }
        DB::table('produk')->where('id', $id)->update($this->withUpdatedAt('produk', [
            'nama' => $request->input('nama', $current->nama),
            'kategori_id' => $request->input('kategoriId', $current->kategori_id),
            'harga' => $request->has('harga') ? (float) $request->input('harga') : $current->harga,
            'stok' => $request->has('stok') ? (int) $request->input('stok') : $current->stok,
            'deskripsi' => $request->input('deskripsi', $current->deskripsi),
            'gambar_url' => $request->input('gambarUrl', $current->gambar_url),
            'is_aktif' => $request->has('isAktif') ? ($request->boolean('isAktif') ? 1 : 0) : $current->is_aktif,
        ]));

        return $this->produkShow($id);
    }

    public function produkDestroy(Request $request, string $id)
    {
        $this->managerOnly($request);
        DB::table('produk')->where('id', $id)->update($this->withUpdatedAt('produk', ['is_aktif' => 0]));

        return response()->noContent();
    }
}
