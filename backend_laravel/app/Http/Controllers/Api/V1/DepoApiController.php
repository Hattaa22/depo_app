<?php

namespace App\Http\Controllers\Api\V1;

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

class DepoApiController extends Controller
{
    public function health()
    {
        return response()->json([
            'status' => 'ok',
            'service' => 'depo-laravel-api',
            'timestamp' => now()->toISOString(),
        ]);
    }

    public function login(Request $request, string $role, ApiTokenService $tokens)
    {
        if (! in_array($role, ['crew', 'manager'], true)) {
            return response()->json(['message' => 'Role tidak valid'], 404);
        }

        $username = strtolower(trim((string) $request->input('username', '')));
        $secret = (string) ($role === 'crew'
            ? ($request->input('pin') ?? $request->input('password') ?? '')
            : $request->input('password', ''));

        $query = DB::table('users')->where('role', $role)->where('is_aktif', 1);
        $rows = [];

        if ($role === 'crew' && $username === '') {
            $rows = $query->orderByRaw("CASE WHEN username = 'crew001' THEN 0 ELSE 1 END")
                ->orderBy('username')
                ->get()
                ->filter(fn ($row) => Hash::check($secret, $row->pin_hash ?: $row->password_hash))
                ->values()
                ->all();
        } else {
            $rows = $query->where(function ($q) use ($username) {
                $q->whereRaw('LOWER(username) = ?', [$username])
                    ->orWhereRaw('LOWER(email) = ?', [$username]);
            })->get()->all();
        }

        if (count($rows) === 0) {
            return response()->json(['message' => $role === 'crew' ? 'PIN crew salah' : 'Username atau password salah'], 401);
        }

        $user = (array) $rows[0];
        if (! ($role === 'crew' && $username === '')) {
            $hash = $role === 'crew' ? ($user['pin_hash'] ?: $user['password_hash']) : $user['password_hash'];
            if (! Hash::check($secret, $hash)) {
                return response()->json(['message' => $role === 'crew' ? 'PIN crew salah' : 'Username atau password salah'], 401);
            }
        }

        $accessToken = $tokens->issueAccessToken($user);
        $refreshToken = $tokens->issueRefreshToken($user);
        $this->storeRefreshToken($refreshToken, $user['id']);

        return response()->json([
            'access_token' => $accessToken,
            'refresh_token' => $refreshToken,
            'role' => $user['role'],
            'user_data' => $this->userData($user),
        ]);
    }

    public function loginCrew(Request $request, ApiTokenService $tokens)
    {
        return $this->login($request, 'crew', $tokens);
    }

    public function loginManager(Request $request, ApiTokenService $tokens)
    {
        return $this->login($request, 'manager', $tokens);
    }

    public function refresh(Request $request, ApiTokenService $tokens)
    {
        $refreshToken = (string) $request->input('refresh_token', '');
        if ($refreshToken === '') {
            return response()->json(['message' => 'refresh_token wajib'], 400);
        }

        $payload = $tokens->verify($refreshToken, 'refresh');
        if (! $payload) {
            return response()->json(['message' => 'Refresh token tidak valid'], 401);
        }

        $exists = DB::table('refresh_tokens')->where('token', $refreshToken)->exists();
        if (! $exists) {
            return response()->json(['message' => 'Refresh token tidak valid'], 401);
        }

        $user = DB::table('users')->where('id', $payload['sub'])->where('is_aktif', 1)->first();
        if (! $user) {
            return response()->json(['message' => 'User tidak ditemukan'], 401);
        }

        $userArray = (array) $user;
        $newAccessToken = $tokens->issueAccessToken($userArray);
        $newRefreshToken = $tokens->issueRefreshToken($userArray);

        DB::table('refresh_tokens')->where('token', $refreshToken)->delete();
        $this->storeRefreshToken($newRefreshToken, $user->id);

        return response()->json([
            'access_token' => $newAccessToken,
            'refresh_token' => $newRefreshToken,
            'role' => $user->role,
            'user_data' => $this->userData($userArray),
        ]);
    }

    public function logout(Request $request)
    {
        $refreshToken = (string) $request->input('refresh_token', '');
        if ($refreshToken !== '') {
            DB::table('refresh_tokens')->where('token', $refreshToken)->delete();
        }

        return response()->json(['message' => 'Logout berhasil']);
    }

    public function changePassword(Request $request)
    {
        $user = DB::table('users')->where('id', $this->auth($request)['sub'])->first();
        if (! $user) {
            return response()->json(['message' => 'User tidak ditemukan'], 404);
        }

        if ($user->role === 'crew') {
            $request->validate([
                'pinLama' => ['required', 'string'],
                'pinBaru' => ['required', 'string', 'min:4'],
            ]);

            $hashToCheck = $user->pin_hash ?: $user->password_hash;
            if (! Hash::check((string) $request->input('pinLama'), $hashToCheck)) {
                return response()->json(['message' => 'PIN lama tidak sesuai'], 400);
            }

            $newHash = Hash::make((string) $request->input('pinBaru'));
            DB::table('users')->where('id', $user->id)->update([
                'pin_hash' => $newHash,
                'password_hash' => $newHash,
                'updated_at' => now(),
            ]);

            return response()->json(['message' => 'PIN berhasil diubah']);
        }

        $request->validate([
            'passwordLama' => ['required', 'string'],
            'passwordBaru' => ['required', 'string', 'min:6'],
        ]);

        if (! Hash::check((string) $request->input('passwordLama'), $user->password_hash)) {
            return response()->json(['message' => 'Password lama tidak sesuai'], 400);
        }

        DB::table('users')->where('id', $user->id)->update([
            'password_hash' => Hash::make((string) $request->input('passwordBaru')),
            'updated_at' => now(),
        ]);

        return response()->json(['message' => 'Password berhasil diubah']);
    }

    public function changeProfile(Request $request)
    {
        $request->validate([
            'nama' => ['required', 'string', 'max:100'],
        ]);

        $user = DB::table('users')->where('id', $this->auth($request)['sub'])->first();
        if (! $user) {
            return response()->json(['message' => 'User tidak ditemukan'], 404);
        }

        DB::table('users')->where('id', $user->id)->update([
            'nama' => (string) $request->input('nama'),
            'updated_at' => now(),
        ]);

        return response()->json(['message' => 'Profil berhasil diperbarui']);
    }

    public function crewIndex(Request $request)
    {
        $query = DB::table('users')->where('role', 'crew');
        if ($request->filled('search')) {
            $search = '%'.strtolower((string) $request->query('search')).'%';
            $query->where(function ($q) use ($search) {
                $q->whereRaw('LOWER(nama) LIKE ?', [$search])
                    ->orWhereRaw('LOWER(username) LIKE ?', [$search]);
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

        return response()->json($this->crewResponse((array) $row));
    }

    public function crewStore(Request $request)
    {
        $this->managerOnly($request);
        $data = $request->validate([
            'username' => ['required', 'string', 'max:100'],
            'nama' => ['nullable', 'string', 'max:150'],
            'pin' => ['nullable', 'regex:/^\d{4,6}$/'],
            'password' => ['nullable', 'string'],
            'noHp' => ['nullable', 'string', 'max:20'],
            'alamat' => ['nullable', 'string'],
            'isAktif' => ['nullable', 'boolean'],
        ]);

        $username = trim($data['username']);
        if (DB::table('users')->whereRaw('LOWER(username) = ?', [strtolower($username)])->exists()) {
            return response()->json(['message' => 'Username sudah digunakan'], 400);
        }

        $pin = (string) ($data['pin'] ?? $data['password'] ?? '1234');
        if (! preg_match('/^\d{4,6}$/', $pin)) {
            return response()->json(['message' => 'PIN crew harus 4-6 digit'], 400);
        }

        $id = (string) Str::uuid();
        DB::table('users')->insert([
            'id' => $id,
            'role' => 'crew',
            'username' => $username,
            'password_hash' => Hash::make($pin),
            'pin_hash' => Hash::make($pin),
            'nama' => trim($data['nama'] ?? $username),
            'no_hp' => $data['noHp'] ?? '',
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
            $pin = (string) ($request->input('pin') ?? $request->input('password') ?? '1234');
            if (! preg_match('/^\d{4,6}$/', $pin)) {
                return response()->json(['message' => 'PIN crew harus 4-6 digit'], 400);
            }
            DB::table('users')->where('id', $id)->update([
                'password_hash' => Hash::make($pin),
                'pin_hash' => Hash::make($pin),
                'updated_at' => now(),
            ]);
        } else {
            DB::table('users')->where('id', $id)->update([
                'nama' => $request->input('nama', $current->nama),
                'username' => $request->input('username', $current->username),
                'no_hp' => $request->input('noHp', $current->no_hp),
                'alamat' => $request->input('alamat', $current->alamat),
                'is_aktif' => $request->has('isAktif') ? ($request->boolean('isAktif') ? 1 : 0) : $current->is_aktif,
                'updated_at' => now(),
            ]);
        }

        return response()->json($this->crewResponse((array) DB::table('users')->where('id', $id)->first()));
    }

    public function crewDestroy(Request $request, string $id)
    {
        $this->managerOnly($request);
        DB::table('users')->where('id', $id)->where('role', 'crew')->update(['is_aktif' => 0, 'updated_at' => now()]);

        return response()->noContent();
    }

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

    public function pelangganDestroy(string $id)
    {
        DB::table('pelanggan')->where('id', $id)->update($this->withUpdatedAt('pelanggan', ['is_aktif' => 0]));

        return response()->noContent();
    }

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
                'crew_nama' => $this->auth($request)['username'],
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
            'crew_nama' => $this->auth($request)['username'],
            'tanggal' => $request->input('tanggal'),
        ]));
    }

    public function galonKembali(Request $request)
    {
        return response()->json($this->applyGalonMutasi('kembali', (int) $request->input('jumlah'), [
            'pelanggan_id' => $request->input('pelangganId'),
            'catatan' => $request->input('catatan'),
            'crew_id' => $this->auth($request)['sub'],
            'crew_nama' => $this->auth($request)['username'],
            'tanggal' => $request->input('tanggal'),
        ]));
    }

    public function transaksiIndex(Request $request)
    {
        $query = DB::table('transaksi');
        if ($request->filled('status')) {
            $query->whereIn('status', explode(',', (string) $request->query('status')));
        }
        if ($request->filled('crewId')) {
            $query->where('crew_id', $request->query('crewId'));
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

            DB::table('transaksi')->insert([
                'id' => $trxId,
                'nomor_transaksi' => (string) round(microtime(true) * 1000),
                'pelanggan_id' => $request->input('pelangganId'),
                'crew_id' => $crewId,
                'pengirim_crew_id' => $pengirimCrewId,
                'total_harga' => $total,
                'metode_pembayaran' => $metode,
                'status' => $isQris ? 'menungguValidasi' : 'selesai',
                'status_validasi' => $isQris ? 'belumDivalidasi' : 'valid',
                'bayar' => $request->input('bayar'),
                'kembalian' => $request->input('kembalian'),
                'qr_payment_id' => $isQris ? 'QR-'.Str::uuid() : null,
                'catatan' => $request->input('catatan'),
                'tipe_pembelian' => $tipePembelian,
                'ongkir_per_galon' => $ongkirPerGalon,
                'total_ongkir' => $totalOngkir,
                'created_at' => now(),
            ]);
            DB::table('transaksi_items')->insert($items);

            if (! $isQris) {
                DB::table('pelanggan')->where('id', $request->input('pelangganId'))->increment('total_transaksi', $total);
                $this->applyGalonFromItems($items, $request->input('pelangganId'), $crewId, $auth['username'], $trxId);
            }

            return response()->json($this->transaksiResponse((array) DB::table('transaksi')->where('id', $trxId)->first()), 201);
        });
    }

    public function transaksiStatus(Request $request, string $id)
    {
        if (! DB::table('transaksi')->where('id', $id)->exists()) {
            return response()->json(['message' => 'Transaksi tidak ditemukan'], 404);
        }
        DB::table('transaksi')->where('id', $id)->update(['status' => $request->input('status'), 'updated_at' => now()]);

        return $this->transaksiShow($id);
    }

    public function transaksiValidasi(Request $request, string $id)
    {
        $auth = $this->auth($request);
        return DB::transaction(function () use ($request, $id, $auth) {
            $trx = DB::table('transaksi')->where('id', $id)->first();
            if (! $trx) {
                return response()->json(['message' => 'Transaksi tidak ditemukan'], 404);
            }
            $status = $request->input('status');
            $nextStatus = $trx->status;
            $nextValidasi = $trx->status_validasi;
            if ($status === 'sukses') {
                $nextStatus = 'selesai';
                $nextValidasi = 'valid';
                DB::table('pelanggan')->where('id', $trx->pelanggan_id)->increment('total_transaksi', (float) $trx->total_harga);
                $items = DB::table('transaksi_items')->where('transaksi_id', $id)->get()->map(fn ($row) => (array) $row)->all();
                $this->applyGalonFromItems($items, $trx->pelanggan_id, $trx->crew_id, $auth['username'], $id);
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

    public function dashboardCrew(Request $request)
    {
        $crewId = $this->auth($request)['sub'];
        $today = now()->toDateString();
        $tx = DB::table('transaksi')
            ->where('status', 'selesai')
            ->whereDate('created_at', $today)
            ->where(function ($q) use ($crewId) {
                $q->where('crew_id', $crewId)->orWhere('pengirim_crew_id', $crewId);
            })
            ->get();
        $ids = $tx->pluck('id')->all();
        $totalGalon = count($ids)
            ? (int) DB::table('transaksi_items')->whereIn('transaksi_id', $ids)->sum('jumlah')
            : 0;

        return response()->json([
            'totalPenjualanHarian' => (float) $tx->sum('total_harga'),
            'totalGalonTerjual' => $totalGalon,
        ]);
    }

    public function dashboardManager()
    {
        $today = now()->toDateString();
        $monthStart = now()->startOfMonth()->toDateString();

        return response()->json([
            'harian' => $this->financialSummary($today, $today),
            'bulanan' => $this->financialSummary($monthStart, $today),
            'semua' => $this->financialSummary('2000-01-01', $today),
            'galonBersih' => (int) DB::table('galon')->where('status', 'tersedia')->count(),
            'tersedia' => (int) DB::table('galon')->where('status', 'tersedia')->count(),
            'totalPelanggan' => (int) DB::table('pelanggan')->count(),
            'totalPendapatanHarian' => (float) DB::table('transaksi')->where('status', 'selesai')->whereDate('created_at', $today)->sum('total_harga'),
            'totalTransaksiHari' => (int) DB::table('transaksi')->where('status', 'selesai')->whereDate('created_at', $today)->count(),
            'breakdown' => ['harian' => [], 'bulanan' => [], 'semua' => []],
        ]);
    }

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

    public function qrisCreate(Request $request, MidtransService $midtrans)
    {
        $trx = DB::table('transaksi')->where('id', $request->input('transaksiId'))->first();
        if (! $trx) {
            return response()->json(['message' => 'Transaksi tidak ditemukan'], 404);
        }
        if ($trx->metode_pembayaran !== 'qris') {
            return response()->json(['message' => 'Transaksi bukan metode QRIS'], 400);
        }
        if (! $midtrans->isConfigured()) {
            return response()->json(['message' => 'MIDTRANS_SERVER_KEY belum dikonfigurasi'], 500);
        }

        $existing = DB::table('qr_payments')->where('transaksi_id', $trx->id)->where('status', 'pending')->first();
        if ($existing && now()->lessThan($existing->expires_at) && ($existing->redirect_url ?? $existing->qr_content ?? null)) {
            return response()->json($this->qrisResponse($existing));
        }

        $paymentId = 'DEPO-'.strtoupper(substr($trx->id, 0, 8)).'-'.round(microtime(true) * 1000);
        $expiresAt = now()->addMinutes(15);
        $snapPayload = $this->midtransSnapPayload($trx, $paymentId);

        try {
            $snap = $midtrans->createSnapTransaction($snapPayload);
        } catch (RequestException $e) {
            Log::error('Gagal membuat transaksi Snap Midtrans', [
                'transaksi_id' => $trx->id,
                'error' => $e->getMessage(),
            ]);

            if ($e->response?->status() === 401) {
                return response()->json([
                    'message' => 'Midtrans menolak transaksi. Periksa kembali Server Key sandbox di backend.',
                ], 502);
            }

            return response()->json(['message' => 'Gagal menghubungi Midtrans. Coba lagi beberapa saat.'], 502);
        } catch (Throwable $e) {
            Log::error('Gagal membuat transaksi Snap Midtrans', [
                'transaksi_id' => $trx->id,
                'error' => $e->getMessage(),
            ]);

            return response()->json(['message' => 'Gagal membuat pembayaran Midtrans'], 502);
        }

        $redirectUrl = (string) ($snap['redirect_url'] ?? '');
        if ($redirectUrl === '') {
            return response()->json(['message' => 'Midtrans tidak mengembalikan URL pembayaran'], 502);
        }

        $this->insertQrPayment([
            'payment_id' => $paymentId,
            'midtrans_order_id' => $paymentId,
            'transaksi_id' => $trx->id,
            'gateway' => 'midtrans',
            'jumlah' => $trx->total_harga,
            'qr_content' => $redirectUrl,
            'snap_token' => $snap['token'] ?? null,
            'redirect_url' => $redirectUrl,
            'status' => 'pending',
            'nama_depot' => 'Depo Air Minum',
            'gateway_response' => json_encode($snap),
            'expires_at' => $expiresAt,
            'created_at' => now(),
        ]);
        DB::table('transaksi')->where('id', $trx->id)->update(['qr_payment_id' => $paymentId, 'updated_at' => now()]);

        return response()->json($this->qrisResponse(DB::table('qr_payments')->where('payment_id', $paymentId)->first()), 201);
    }

    public function qrisStatus(string $paymentId, MidtransService $midtrans)
    {
        $row = DB::table('qr_payments')->where('payment_id', $paymentId)->first();
        if (! $row) {
            return response()->json(['message' => 'Pembayaran QR tidak ditemukan'], 404);
        }
        if ($row->status === 'pending' && now()->greaterThan($row->expires_at)) {
            DB::table('qr_payments')->where('payment_id', $paymentId)->update(['status' => 'expired', 'updated_at' => now()]);
            $row = DB::table('qr_payments')->where('payment_id', $paymentId)->first();
        } elseif ($row->status === 'pending' && $midtrans->isConfigured()) {
            try {
                $payload = $midtrans->getTransactionStatus($row->midtrans_order_id ?? $row->payment_id);
                if ($payload !== []) {
                    $this->applyMidtransPaymentStatus($row, $payload, $midtrans);
                    $row = DB::table('qr_payments')->where('payment_id', $paymentId)->first();
                }
            } catch (Throwable $e) {
                Log::warning('Gagal sinkron status Midtrans', [
                    'payment_id' => $paymentId,
                    'error' => $e->getMessage(),
                ]);
            }
        }

        return response()->json([
            'paymentId' => $row->payment_id,
            'transaksiId' => $row->transaksi_id,
            'status' => $row->status,
            'jumlah' => (float) $row->jumlah,
            'paidAt' => $row->paid_at,
            'expiresAt' => $row->expires_at,
        ]);
    }

    public function qrisStatusPublic(string $paymentId)
    {
        $row = DB::table('qr_payments')->where('payment_id', $paymentId)->first();
        if (! $row) {
            return response()->json(['message' => 'Tidak ditemukan'], 404);
        }

        return response()->json(['status' => $row->status, 'paidAt' => $row->paid_at]);
    }

    public function qrisSimulatePay(string $paymentId)
    {
        if (! config('services.midtrans.allow_simulation')) {
            return response()->json(['message' => 'Simulasi pembayaran dinonaktifkan'], 403);
        }

        $row = DB::table('qr_payments')->where('payment_id', $paymentId)->first();
        if (! $row) {
            return response()->json(['message' => 'Pembayaran QR tidak ditemukan'], 404);
        }
        DB::table('qr_payments')->where('payment_id', $paymentId)->update(['status' => 'paid', 'paid_at' => now(), 'updated_at' => now()]);
        DB::table('transaksi')->where('id', $row->transaksi_id)->update(['qr_paid_at' => now(), 'status' => 'menungguValidasi', 'updated_at' => now()]);

        return response()->json(['success' => true, 'transaksiId' => $row->transaksi_id, 'status' => 'paid', 'paidAt' => now()->toISOString()]);
    }

    public function qrisTestSimulasi()
    {
        $id = 'TEST-QRIS-'.round(microtime(true) * 1000);

        return response()->json([
            'success' => true,
            'qrContent' => "DEPO_QRIS_SIM|paymentId=$id|amount=15000|merchant=Depo Air Minum",
            'testOrderId' => $id,
            'testAmount' => 15000,
        ]);
    }

    public function midtransNotification(Request $request, MidtransService $midtrans)
    {
        $payload = $request->all();
        if (! $midtrans->verifyNotificationSignature($payload)) {
            return response()->json(['message' => 'Signature Midtrans tidak valid'], 403);
        }

        $orderId = (string) ($payload['order_id'] ?? '');
        $row = $this->findQrPaymentByOrderId($orderId);
        if (! $row) {
            return response()->json(['message' => 'Pembayaran tidak ditemukan'], 404);
        }

        $this->applyMidtransPaymentStatus($row, $payload, $midtrans);

        return response()->json(['success' => true]);
    }

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

        return $query->groupBy('u.id', 'u.nama', 'u.username')
            ->selectRaw("
                u.id as crewId,
                u.nama as crewNama,
                u.username as username,
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
                'username' => $row->username,
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
        return [
            'paymentId' => $row->payment_id,
            'transaksiId' => $row->transaksi_id,
            'qrContent' => $row->redirect_url ?? $row->qr_content,
            'snapToken' => $row->snap_token ?? null,
            'redirectUrl' => $row->redirect_url ?? $row->qr_content,
            'jumlah' => (float) $row->jumlah,
            'status' => $row->status,
            'expiresAt' => $row->expires_at,
            'namaDepot' => $row->nama_depot ?: 'Depo Air Minum',
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

        return $query->first();
    }

    private function applyMidtransPaymentStatus(object $row, array $payload, MidtransService $midtrans): void
    {
        $status = $midtrans->mapPaymentStatus($payload);
        $update = [
            'status' => $status,
            'updated_at' => now(),
        ];

        if (Schema::hasColumn('qr_payments', 'payment_type')) {
            $update['payment_type'] = $payload['payment_type'] ?? null;
        }
        if (Schema::hasColumn('qr_payments', 'gateway_response')) {
            $update['gateway_response'] = json_encode($payload);
        }

        if ($status === 'paid') {
            $update['paid_at'] = $row->paid_at ?: now();
        }

        DB::table('qr_payments')->where('payment_id', $row->payment_id)->update($update);

        if ($status === 'paid') {
            DB::table('transaksi')->where('id', $row->transaksi_id)->update([
                'qr_paid_at' => $row->paid_at ?: now(),
                'status' => 'menungguValidasi',
                'updated_at' => now(),
            ]);
        } elseif (in_array($status, ['expired', 'failed'], true)) {
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
            'username' => $user['username'],
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
            'username' => $user['username'],
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
            return $value->format(DATE_ATOM);
        }

        return $value;
    }
}
