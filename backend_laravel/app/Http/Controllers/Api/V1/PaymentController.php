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
class PaymentController extends Controller
{
    use DepoApiHelpers;

    public function qrisCreate(Request $request, MidtransService $midtrans)
    {
        Log::info('Request pembayaran QRIS masuk', [
            'transaksiId' => $request->input('transaksiId'),
            'content_type' => $request->header('Content-Type'),
            'accept' => $request->header('Accept'),
            'has_authorization' => $request->bearerToken() !== null,
        ]);

        try {
            $transaksiId = (string) $request->input('transaksiId', '');
            if ($transaksiId === '') {
                return response()->json([
                    'success' => false,
                    'message' => 'transaksiId wajib diisi',
                    'error' => 'Parameter transaksiId kosong',
                ], 422);
            }

            $trx = DB::table('transaksi')->where('id', $transaksiId)->first();
            if (! $trx) {
                return response()->json([
                    'success' => false,
                    'message' => 'Transaksi tidak ditemukan',
                    'error' => 'transaksiId tidak valid',
                ], 404);
            }
            if (! $this->canAccessTransaksi($request, $trx)) {
                return response()->json([
                    'success' => false,
                    'message' => 'Anda tidak berwenang mengakses transaksi ini',
                ], 403);
            }
            if ($trx->metode_pembayaran !== 'qris') {
                return response()->json([
                    'success' => false,
                    'message' => 'Transaksi bukan metode QRIS',
                    'error' => 'metode_pembayaran harus qris',
                ], 400);
            }
            if ((float) $trx->total_harga <= 0) {
                return response()->json([
                    'success' => false,
                    'message' => 'Nominal transaksi tidak valid',
                    'error' => 'total_harga harus lebih dari 0',
                ], 400);
            }
            if (! $trx->pelanggan_id || ! DB::table('pelanggan')->where('id', $trx->pelanggan_id)->exists()) {
                return response()->json([
                    'success' => false,
                    'message' => 'Data customer tidak ditemukan',
                    'error' => 'pelanggan_id kosong atau tidak valid',
                ], 400);
            }
            if (! $midtrans->isConfigured()) {
                return response()->json([
                    'success' => false,
                    'message' => 'MIDTRANS_SERVER_KEY belum dikonfigurasi',
                    'error' => 'Konfigurasi Midtrans tidak lengkap',
                ], 500);
            }

            Log::info('Validasi pembayaran QRIS berhasil', [
                'transaksi_id' => $trx->id,
                'total_harga' => $trx->total_harga,
            ]);

            $existing = DB::table('qr_payments')->where('transaksi_id', $trx->id)->where('status', 'pending')->first();
            $existingExpiresAt = $existing ? ($existing->expires_at ?? $existing->expired_at ?? null) : null;
            $existingCheckoutUrl = $existing ? ($existing->redirect_url ?? $existing->payment_url ?? $existing->qr_content ?? null) : null;
            $existingIsSnapCheckout = is_string($existingCheckoutUrl)
                && (($existing->snap_token ?? null) || str_contains($existingCheckoutUrl, '/snap/'));
            if ($existing && $existingExpiresAt && now()->lessThan($existingExpiresAt) && $existingCheckoutUrl && $existingIsSnapCheckout) {
                Log::info('Menggunakan pembayaran QRIS pending yang masih aktif', [
                    'payment_id' => $existing->payment_id,
                    'transaksi_id' => $trx->id,
                ]);

                return response()->json($this->qrisResponse($existing));
            }

            $paymentId = 'DEPO-'.strtoupper(substr($trx->id, 0, 8)).'-'.round(microtime(true) * 1000);
            $expiresAt = now()->addMinutes(15);
            $snapPayload = $this->midtransSnapPayload($trx, $paymentId);

            Log::info('Generate order ID QRIS', [
                'transaksi_id' => $trx->id,
                'order_id' => $paymentId,
                'gross_amount' => $snapPayload['transaction_details']['gross_amount'] ?? null,
            ]);

            $snap = $midtrans->createSnapTransaction($snapPayload);
        } catch (RequestException $e) {
            Log::error('Gagal membuat transaksi Snap Midtrans', [
                'transaksi_id' => $request->input('transaksiId'),
                'status' => $e->response?->status(),
                'body' => $e->response?->body(),
                'error' => $e->getMessage(),
                'trace' => $e->getTraceAsString(),
            ]);

            if ($e->response?->status() === 401) {
                return response()->json([
                    'success' => false,
                    'message' => 'Midtrans menolak transaksi. Periksa kembali Server Key sandbox di backend.',
                    'error' => $e->getMessage(),
                ], 502);
            }

            return response()->json([
                'success' => false,
                'message' => 'Gagal menghubungi Midtrans. Coba lagi beberapa saat.',
                'error' => $e->getMessage(),
            ], 502);
        } catch (Throwable $e) {
            Log::error('Gagal membuat transaksi Snap Midtrans', [
                'transaksi_id' => $request->input('transaksiId'),
                'error' => $e->getMessage(),
                'trace' => $e->getTraceAsString(),
            ]);

            return response()->json([
                'success' => false,
                'message' => 'Gagal membuat pembayaran Midtrans',
                'error' => $e->getMessage(),
            ], 502);
        }

        $redirectUrl = (string) ($snap['redirect_url'] ?? '');
        if ($redirectUrl === '') {
            Log::error('Midtrans tidak mengembalikan URL checkout Snap', [
                'transaksi_id' => $trx->id,
                'order_id' => $paymentId,
                'response' => $snap,
            ]);

            return response()->json([
                'success' => false,
                'message' => 'Midtrans tidak mengembalikan URL checkout pembayaran',
                'error' => 'redirect_url kosong',
            ], 502);
        }

        try {
            DB::transaction(function () use ($paymentId, $trx, $redirectUrl, $snap, $expiresAt) {
                Log::info('Simpan pembayaran QRIS ke database', [
                    'payment_id' => $paymentId,
                    'transaksi_id' => $trx->id,
                ]);

                $this->insertQrPayment([
                    'payment_id' => $paymentId,
                    'order_id' => $paymentId,
                    'transaction_code' => $paymentId,
                    'midtrans_order_id' => $paymentId,
                    'transaksi_id' => $trx->id,
                    'gateway' => 'midtrans',
                    'jumlah' => $trx->total_harga,
                    'gross_amount' => $trx->total_harga,
                    'qr_content' => $redirectUrl,
                    'snap_token' => $snap['token'] ?? null,
                    'redirect_url' => $redirectUrl,
                    'payment_url' => $redirectUrl,
                    'payment_type' => 'qris',
                    'status' => 'pending',
                    'payment_status' => 'pending',
                    'transaction_status' => 'pending',
                    'nama_depot' => 'Depo Air Minum',
                    'gateway_response' => json_encode($snap),
                    'expires_at' => $expiresAt,
                    'expired_at' => $expiresAt,
                    'created_at' => now(),
                ]);
                DB::table('transaksi')->where('id', $trx->id)->update(['qr_payment_id' => $paymentId, 'updated_at' => now()]);
            });
        } catch (Throwable $e) {
            Log::error('Gagal menyimpan pembayaran QRIS', [
                'payment_id' => $paymentId,
                'transaksi_id' => $trx->id,
                'error' => $e->getMessage(),
                'trace' => $e->getTraceAsString(),
            ]);

            return response()->json([
                'success' => false,
                'message' => 'Gagal menyimpan pembayaran QRIS',
                'error' => $e->getMessage(),
            ], 500);
        }

        $response = $this->qrisResponse(DB::table('qr_payments')->where('payment_id', $paymentId)->first());
        Log::info('Response pembayaran QRIS dikirim', [
            'payment_id' => $paymentId,
            'transaksi_id' => $trx->id,
            'status' => $response['status'],
            'has_snap_token' => ! empty($response['snapToken']),
            'has_redirect_url' => ! empty($response['redirectUrl']),
            'gross_amount' => $response['grossAmount'],
        ]);

        return response()->json($response, 201);
    }

    public function qrisStatus(Request $request, string $paymentId, MidtransService $midtrans)
    {
        try {
            Log::info('Cek status pembayaran QRIS', ['payment_id' => $paymentId]);

            $row = DB::table('qr_payments')->where('payment_id', $paymentId)->first();
            if (! $row) {
                return response()->json([
                    'success' => false,
                    'message' => 'Pembayaran QR tidak ditemukan',
                    'error' => 'paymentId tidak valid',
                ], 404);
            }
            $trx = DB::table('transaksi')->where('id', $row->transaksi_id)->first();
            if (! $trx || ! $this->canAccessTransaksi($request, $trx)) {
                return response()->json([
                    'success' => false,
                    'message' => 'Anda tidak berwenang mengakses pembayaran ini',
                ], 403);
            }

            $expiresAt = $row->expires_at ?? $row->expired_at ?? null;
            if ($row->status === 'pending' && $expiresAt && now()->greaterThan($expiresAt)) {
                $update = ['status' => 'expire', 'updated_at' => now()];
                if (Schema::hasColumn('qr_payments', 'payment_status')) {
                    $update['payment_status'] = 'expire';
                }
                if (Schema::hasColumn('qr_payments', 'transaction_status')) {
                    $update['transaction_status'] = 'expire';
                }
                DB::table('qr_payments')->where('payment_id', $paymentId)->update($update);
                DB::table('transaksi')->where('id', $row->transaksi_id)->update(['status' => 'dibatalkan', 'updated_at' => now()]);
                $row = DB::table('qr_payments')->where('payment_id', $paymentId)->first();
            } elseif ($row->status === 'pending' && $midtrans->isConfigured()) {
                $payload = $midtrans->getTransactionStatus($row->midtrans_order_id ?? $row->payment_id);
                if ($payload !== []) {
                    $this->applyMidtransPaymentStatus($row, $payload, $midtrans);
                    $row = DB::table('qr_payments')->where('payment_id', $paymentId)->first();
                }
            }

            return response()->json([
                'paymentId' => $row->payment_id,
                'transaksiId' => $row->transaksi_id,
                'status' => $row->status,
                'paymentStatus' => $row->payment_status ?? $row->status,
                'transactionStatus' => $row->transaction_status ?? $row->status,
                'jumlah' => (float) $row->jumlah,
                'paidAt' => $row->paid_at,
                'expiresAt' => $row->expires_at ?? $row->expired_at ?? null,
            ]);
        } catch (Throwable $e) {
            Log::error('Gagal cek status pembayaran QRIS', [
                'payment_id' => $paymentId,
                'error' => $e->getMessage(),
                'trace' => $e->getTraceAsString(),
            ]);

            return response()->json([
                'success' => false,
                'message' => 'Gagal cek status pembayaran QRIS',
                'error' => $e->getMessage(),
            ], 500);
        }
    }

    public function qrisStatusPublic(string $paymentId)
    {
        try {
            $row = DB::table('qr_payments')->where('payment_id', $paymentId)->first();
            if (! $row) {
                return response()->json(['success' => false, 'message' => 'Tidak ditemukan'], 404);
            }

            return response()->json([
                'status' => $row->status,
                'paymentStatus' => $row->payment_status ?? $row->status,
                'transactionStatus' => $row->transaction_status ?? $row->status,
                'paidAt' => $row->paid_at,
            ]);
        } catch (Throwable $e) {
            Log::error('Gagal cek status public QRIS', [
                'payment_id' => $paymentId,
                'error' => $e->getMessage(),
                'trace' => $e->getTraceAsString(),
            ]);

            return response()->json([
                'success' => false,
                'message' => 'Gagal cek status public QRIS',
                'error' => $e->getMessage(),
            ], 500);
        }
    }

    public function qrisSimulatePay(Request $request, string $paymentId)
    {
        if (! config('services.midtrans.allow_simulation')) {
            return response()->json(['success' => false, 'message' => 'Simulasi pembayaran dinonaktifkan'], 403);
        }

        try {
            $row = DB::table('qr_payments')->where('payment_id', $paymentId)->first();
            if (! $row) {
                return response()->json(['success' => false, 'message' => 'Pembayaran QR tidak ditemukan'], 404);
            }
            $trx = DB::table('transaksi')->where('id', $row->transaksi_id)->first();
            if (! $trx || ! $this->canAccessTransaksi($request, $trx)) {
                return response()->json([
                    'success' => false,
                    'message' => 'Anda tidak berwenang mengakses pembayaran ini',
                ], 403);
            }
            $paidAt = now();
            $update = ['status' => 'settlement', 'paid_at' => $paidAt, 'updated_at' => $paidAt];
            if (Schema::hasColumn('qr_payments', 'payment_status')) {
                $update['payment_status'] = 'settlement';
            }
            if (Schema::hasColumn('qr_payments', 'transaction_status')) {
                $update['transaction_status'] = 'settlement';
            }
            DB::table('qr_payments')->where('payment_id', $paymentId)->update($update);
            DB::table('transaksi')->where('id', $row->transaksi_id)->update(['qr_paid_at' => $paidAt, 'status' => 'menungguValidasi', 'updated_at' => $paidAt]);

            Log::info('Simulasi pembayaran QRIS berhasil', [
                'payment_id' => $paymentId,
                'transaksi_id' => $row->transaksi_id,
            ]);

            return response()->json(['success' => true, 'transaksiId' => $row->transaksi_id, 'status' => 'settlement', 'paidAt' => $paidAt->toISOString()]);
        } catch (Throwable $e) {
            Log::error('Gagal simulasi pembayaran QRIS', [
                'payment_id' => $paymentId,
                'error' => $e->getMessage(),
                'trace' => $e->getTraceAsString(),
            ]);

            return response()->json([
                'success' => false,
                'message' => 'Gagal simulasi pembayaran QRIS',
                'error' => $e->getMessage(),
            ], 500);
        }
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

    private function canAccessTransaksi(Request $request, object $trx): bool
    {
        $auth = $this->auth($request);
        if (($auth['role'] ?? null) === 'manager') {
            return true;
        }

        $userId = $auth['sub'] ?? null;

        return $userId !== null && in_array($userId, [$trx->crew_id, $trx->pengirim_crew_id], true);
    }

    public function midtransNotification(Request $request, MidtransService $midtrans)
    {
        try {
            $payload = $request->all();
            Log::info('Callback Midtrans diterima', [
                'order_id' => $payload['order_id'] ?? null,
                'transaction_status' => $payload['transaction_status'] ?? null,
                'payment_type' => $payload['payment_type'] ?? null,
            ]);

            if (! $midtrans->verifyNotificationSignature($payload)) {
                Log::warning('Signature Midtrans tidak valid', [
                    'order_id' => $payload['order_id'] ?? null,
                ]);

                return response()->json([
                    'success' => false,
                    'message' => 'Signature Midtrans tidak valid',
                    'error' => 'signature_key mismatch',
                ], 403);
            }

            $orderId = (string) ($payload['order_id'] ?? '');
            $row = $this->findQrPaymentByOrderId($orderId);
            if (! $row) {
                return response()->json([
                    'success' => false,
                    'message' => 'Pembayaran tidak ditemukan',
                    'error' => 'order_id tidak cocok dengan qr_payments',
                ], 404);
            }

            $this->applyMidtransPaymentStatus($row, $payload, $midtrans);

            return response()->json(['success' => true]);
        } catch (Throwable $e) {
            Log::error('Gagal memproses callback Midtrans', [
                'order_id' => $request->input('order_id'),
                'error' => $e->getMessage(),
                'trace' => $e->getTraceAsString(),
            ]);

            return response()->json([
                'success' => false,
                'message' => 'Gagal memproses callback Midtrans',
                'error' => $e->getMessage(),
            ], 500);
        }
    }
}
