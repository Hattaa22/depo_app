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
class CrewController extends Controller
{
    use DepoApiHelpers;

    public function crewIndex(Request $request)
    {
        $query = DB::table('users')->where('role', 'crew');
        if ($request->filled('search')) {
            $search = '%'.strtolower((string) $request->query('search')).'%';
            $query->where(function ($q) use ($search) {
                $q->whereRaw('LOWER(nama) LIKE ?', [$search]);
            });
        }

        return $this->paginate($query->orderByDesc('created_at'), $request, fn ($row) => $this->crewResponse((array) $row));
    }

    public function crewShow(string $id)
    {
        $row = DB::table('users')->where('id', $id)->where('role', 'crew')->first();
        if (! $row) {
            return response()->json(['message' => 'Crew tidak ditemukan'], 404);
        }

        $response = $this->crewResponse((array) $row);
        $response['lastLoginAt'] = $this->dateValue($row->last_login_at ?? null);

        // Calculate stats
        $totalTransaksi = DB::table('transaksi')->where('crew_id', $id)->count();
        $totalPengiriman = DB::table('transaksi')
            ->where('crew_id', $id)
            ->where('tipe_pembelian', 'dikirim')
            ->count();

        $response['stats'] = [
            'totalTransaksi' => $totalTransaksi,
            'totalPengiriman' => $totalPengiriman,
        ];

        return response()->json($response);
    }

    public function crewStore(Request $request)
    {
        $this->managerOnly($request);
        $data = $request->validate([
            'nama' => ['required', 'string', 'max:150'],
            'pin' => ['required', 'regex:/^\d{6}$/'],
            'noHp' => ['required', 'string', 'max:20', 'unique:users,no_hp'],
            'alamat' => ['nullable', 'string'],
            'isAktif' => ['nullable', 'boolean'],
        ]);

        $pin = (string) $data['pin'];
        $noHp = trim($data['noHp']);

        $id = (string) Str::uuid();
        DB::table('users')->insert([
            'id' => $id,
            'role' => 'crew',
            'password_hash' => Hash::make($pin),
            'pin_hash' => Hash::make($pin),
            'nama' => trim($data['nama']),
            'no_hp' => $noHp,
            'alamat' => $data['alamat'] ?? '',
            'is_aktif' => ($data['isAktif'] ?? true) ? 1 : 0,
            'created_at' => now(),
        ]);

        return response()->json($this->crewResponse((array) DB::table('users')->where('id', $id)->first()), 201);
    }

    public function crewUpdate(Request $request, string $id)
    {
        $this->managerOnly($request);
        $current = DB::table('users')->where('id', $id)->where('role', 'crew')->first();
        if (! $current) {
            return response()->json(['message' => 'Crew tidak ditemukan'], 404);
        }

        if ($request->boolean('resetPassword')) {
            $data = $request->validate([
                'pin' => ['required', 'regex:/^\d{6}$/'],
            ]);
            $pin = (string) $data['pin'];
            DB::table('users')->where('id', $id)->update([
                'password_hash' => Hash::make($pin),
                'pin_hash' => Hash::make($pin),
                'updated_at' => now(),
            ]);
        } else {
            $data = $request->validate([
                'nama' => ['nullable', 'string', 'max:150'],
                'noHp' => ['nullable', 'string', 'max:20', 'unique:users,no_hp,'.$id],
                'alamat' => ['nullable', 'string'],
                'isAktif' => ['nullable', 'boolean'],
            ]);
            
            DB::table('users')->where('id', $id)->update([
                'nama' => $data['nama'] ?? $current->nama,
                'no_hp' => $data['noHp'] ?? $current->no_hp,
                'alamat' => $data['alamat'] ?? $current->alamat,
                'is_aktif' => isset($data['isAktif']) ? ($data['isAktif'] ? 1 : 0) : $current->is_aktif,
                'updated_at' => now(),
            ]);
        }

        return response()->json($this->crewResponse((array) DB::table('users')->where('id', $id)->first()));
    }

    public function crewResetPin(Request $request, string $id)
    {
        $this->managerOnly($request);
        $current = DB::table('users')->where('id', $id)->where('role', 'crew')->first();
        if (! $current) {
            return response()->json(['message' => 'Crew tidak ditemukan'], 404);
        }

        $defaultPin = '123456';
        DB::table('users')->where('id', $id)->update([
            'password_hash' => Hash::make($defaultPin),
            'pin_hash' => Hash::make($defaultPin),
            'updated_at' => now(),
        ]);

        return response()->json(['message' => 'PIN berhasil direset ke '.$defaultPin]);
    }

    public function crewUpdateStatus(Request $request, string $id)
    {
        $this->managerOnly($request);
        $current = DB::table('users')->where('id', $id)->where('role', 'crew')->first();
        if (! $current) {
            return response()->json(['message' => 'Crew tidak ditemukan'], 404);
        }

        $isAktif = $request->boolean('isAktif');
        DB::table('users')->where('id', $id)->update([
            'is_aktif' => $isAktif ? 1 : 0,
            'updated_at' => now(),
        ]);

        return response()->json([
            'message' => 'Status crew berhasil diperbarui',
            'isAktif' => $isAktif
        ]);
    }

    public function crewDestroy(Request $request, string $id)
    {
        $this->managerOnly($request);
        DB::table('users')->where('id', $id)->where('role', 'crew')->update(['is_aktif' => 0, 'updated_at' => now()]);

        return response()->noContent();
    }
}
