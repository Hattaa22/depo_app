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
class AuthController extends Controller
{
    use DepoApiHelpers;

    public function login(Request $request, string $role, ApiTokenService $tokens)
    {
        if (! in_array($role, ['crew', 'manager'], true)) {
            return response()->json(['message' => 'Role tidak valid'], 404);
        }

        $email = strtolower(trim((string) ($request->input('email') ?? $request->input('username') ?? '')));
        $secret = (string) ($role === 'crew'
            ? ($request->input('pin') ?? $request->input('password') ?? '')
            : $request->input('password', ''));

        $query = DB::table('users')->where('role', $role)->where('is_aktif', 1);
        $rows = [];

        if ($role === 'crew') {
            $noHp = trim((string) ($request->input('noHp') ?? $request->input('no_hp') ?? $request->input('username') ?? ''));
            if ($noHp === '') {
                return response()->json(['message' => 'Nomor telepon wajib diisi'], 400);
            }
            $rows = $query->where('no_hp', $noHp)->get()->all();
        } else {
            if ($email === '') {
                return response()->json(['message' => 'Email wajib diisi'], 400);
            }
            $rows = $query->where('email', $email)->get()->all();
        }

        if (count($rows) === 0) {
            return response()->json(['message' => $role === 'crew' ? 'Nomor HP tidak terdaftar atau tidak aktif' : 'Email atau password salah'], 401);
        }

        $user = (array) $rows[0];
        $hash = $role === 'crew' ? ($user['pin_hash'] ?: $user['password_hash']) : $user['password_hash'];
        
        if (! Hash::check($secret, $hash)) {
            return response()->json(['message' => $role === 'crew' ? 'PIN salah' : 'Email atau password salah'], 401);
        }

        $accessToken = $tokens->issueAccessToken($user);
        $refreshToken = $tokens->issueRefreshToken($user);
        $this->storeRefreshToken($refreshToken, $user['id']);

        DB::table('users')->where('id', $user['id'])->update(['last_login_at' => now()]);

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
                'pinBaru' => ['required', 'regex:/^\d{6}$/'],
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
}
