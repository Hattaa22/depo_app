<?php

namespace App\Http\Middleware;

use App\Services\ApiTokenService;
use Closure;
use Illuminate\Http\Request;
use Symfony\Component\HttpFoundation\Response;

class ApiTokenAuth
{
    public function handle(Request $request, Closure $next): Response
    {
        $header = (string) $request->header('Authorization', '');
        $token = str_starts_with($header, 'Bearer ') ? substr($header, 7) : null;
        if (! $token) {
            return response()->json(['message' => 'Token tidak ditemukan'], 401);
        }

        $payload = app(ApiTokenService::class)->verify($token, 'access');
        if (! $payload) {
            return response()->json(['message' => 'Token tidak valid'], 401);
        }

        $request->attributes->set('auth_user', $payload);

        return $next($request);
    }
}
