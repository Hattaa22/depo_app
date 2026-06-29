<?php

namespace App\Services;

use Illuminate\Support\Str;

class ApiTokenService
{
    public function issueAccessToken(array $user): string
    {
        return $this->sign([
            's' => $user['id'],
            'r' => $user['role'],
            'u' => $user['username'],
            't' => 'access',
            'e' => now()->addHours(8)->timestamp,
        ]);
    }

    public function issueRefreshToken(array $user): string
    {
        return $this->sign([
            's' => $user['id'],
            'r' => $user['role'],
            't' => 'refresh',
            'j' => substr((string) Str::uuid(), 0, 8),
            'e' => now()->addDays(7)->timestamp,
        ]);
    }

    public function verify(string $token, string $type = 'access'): ?array
    {
        $parts = explode('.', $token);
        if (count($parts) !== 3) {
            return null;
        }

        [$header, $payload, $signature] = $parts;
        $expected = $this->signature("$header.$payload");
        if (! hash_equals($expected, $signature)) {
            return null;
        }

        $data = json_decode($this->base64UrlDecode($payload), true);
        if (! is_array($data)) {
            return null;
        }

        $normalized = [
            'sub' => $data['sub'] ?? $data['s'] ?? null,
            'role' => $data['role'] ?? $data['r'] ?? null,
            'username' => $data['username'] ?? $data['u'] ?? null,
            'type' => $data['type'] ?? $data['t'] ?? null,
            'exp' => $data['exp'] ?? $data['e'] ?? 0,
        ];

        if (($normalized['type'] ?? null) !== $type) {
            return null;
        }

        if (($normalized['exp'] ?? 0) < time()) {
            return null;
        }

        return $normalized;
    }

    private function sign(array $payload): string
    {
        $header = $this->base64UrlEncode(json_encode(['alg' => 'HS256', 'typ' => 'JWT']));
        $body = $this->base64UrlEncode(json_encode($payload));

        return "$header.$body.".$this->signature("$header.$body");
    }

    private function signature(string $value): string
    {
        return $this->base64UrlEncode(hash_hmac('sha256', $value, $this->secret(), true));
    }

    private function secret(): string
    {
        $key = (string) config('app.key');
        if (str_starts_with($key, 'base64:')) {
            return base64_decode(substr($key, 7)) ?: $key;
        }

        return $key;
    }

    private function base64UrlEncode(string $value): string
    {
        return rtrim(strtr(base64_encode($value), '+/', '-_'), '=');
    }

    private function base64UrlDecode(string $value): string
    {
        return base64_decode(strtr($value, '-_', '+/')) ?: '';
    }
}
