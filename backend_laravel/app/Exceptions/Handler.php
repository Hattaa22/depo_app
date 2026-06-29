<?php

namespace App\Exceptions;

use Illuminate\Foundation\Exceptions\Handler as ExceptionHandler;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Log;
use Throwable;

class Handler extends ExceptionHandler
{
    /**
     * A list of exception types with their corresponding custom log levels.
     *
     * @var array<class-string<\Throwable>, \Psr\Log\LogLevel::*>
     */
    protected $levels = [
        //
    ];

    /**
     * A list of the exception types that are not reported.
     *
     * @var array<int, class-string<\Throwable>>
     */
    protected $dontReport = [
        //
    ];

    /**
     * A list of the inputs that are never flashed to the session on validation exceptions.
     *
     * @var array<int, string>
     */
    protected $dontFlash = [
        'current_password',
        'password',
        'password_confirmation',
    ];

    /**
     * Register the exception handling callbacks for the application.
     */
    public function register(): void
    {
        $this->reportable(function (Throwable $e) {
            //
        });
    }

    public function render($request, Throwable $e)
    {
        if ($request instanceof Request && ($request->is('api/*') || $request->expectsJson())) {
            $status = method_exists($e, 'getStatusCode') ? $e->getStatusCode() : 500;
            $status = $status >= 400 && $status < 600 ? $status : 500;

            Log::error('API exception', [
                'path' => $request->path(),
                'method' => $request->method(),
                'status' => $status,
                'message' => $e->getMessage(),
                'trace' => $e->getTraceAsString(),
            ]);

            return response()->json([
                'success' => false,
                'message' => $status === 500 ? 'Terjadi kesalahan pada server' : ($e->getMessage() ?: 'Request tidak dapat diproses'),
                'error' => config('app.debug') ? $e->getMessage() : class_basename($e),
            ], $status);
        }

        return parent::render($request, $e);
    }
}
