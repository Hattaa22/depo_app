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
class PengeluaranController extends Controller
{
    use DepoApiHelpers;

    public function pengeluaranIndex()
    {
        $rows = DB::table('pengeluaran as p')
            ->join('kategori as k', 'k.id', '=', 'p.kategori_id')
            ->select('p.*', 'k.nama as kategori_nama')
            ->orderByDesc('p.tanggal')
            ->orderByDesc('p.created_at')
            ->get();

        return response()->json($this->camel($rows->all()));
    }

    public function pengeluaranStore(Request $request)
    {
        $this->managerOnly($request);
        $request->validate([
            'kategoriId' => ['required', 'string'],
            'nominal' => ['required', 'numeric', 'min:1'],
        ]);
        $id = (string) Str::uuid();
        DB::table('pengeluaran')->insert([
            'id' => $id,
            'kategori_id' => $request->input('kategoriId'),
            'nominal' => (float) $request->input('nominal'),
            'keterangan' => $request->input('keterangan', ''),
            'tanggal' => $request->input('tanggal', now()->toDateString()),
            'created_at' => now(),
        ]);

        $row = DB::table('pengeluaran as p')
            ->join('kategori as k', 'k.id', '=', 'p.kategori_id')
            ->select('p.*', 'k.nama as kategori_nama')
            ->where('p.id', $id)
            ->first();

        return response()->json($this->camel((array) $row), 201);
    }

    public function pengeluaranDestroy(Request $request, string $id)
    {
        $this->managerOnly($request);
        DB::table('pengeluaran')->where('id', $id)->delete();

        return response()->json(['message' => 'Catatan pengeluaran berhasil dihapus']);
    }
}
