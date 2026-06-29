<?php

namespace App\Services;

use Illuminate\Http\Client\RequestException;
use Illuminate\Support\Facades\Http;
use Illuminate\Support\Facades\Log;
use RuntimeException;

class MidtransService
{
    public function createSnapTransaction(array $payload): array
    {
        $response = $this->client()
            ->post($this->snapBaseUrl().'/snap/v1/transactions', $payload)
            ->throw();

        return $response->json();
    }

    public function getTransactionStatus(string $orderId): array
    {
        try {
            $response = $this->client()
                ->get($this->apiBaseUrl().'/v2/'.rawurlencode($orderId).'/status')
                ->throw();

            return $response->json();
        } catch (RequestException $e) {
            if ($e->response?->status() === 404) {
                return [];
            }

            throw $e;
        }
    }

    public function verifyNotificationSignature(array $payload): bool
    {
        $signature = (string) ($payload['signature_key'] ?? '');
        if ($signature === '') {
            return false;
        }

        $expected = hash('sha512', implode('', [
            (string) ($payload['order_id'] ?? ''),
            (string) ($payload['status_code'] ?? ''),
            (string) ($payload['gross_amount'] ?? ''),
            $this->serverKey(),
        ]));

        return hash_equals($expected, $signature);
    }

    public function mapPaymentStatus(array $payload): string
    {
        $transactionStatus = (string) ($payload['transaction_status'] ?? '');
        $fraudStatus = (string) ($payload['fraud_status'] ?? '');

        if ($transactionStatus === 'capture') {
            return $fraudStatus === 'challenge' ? 'challenge' : 'paid';
        }

        if ($transactionStatus === 'settlement') {
            return 'paid';
        }

        if ($transactionStatus === 'pending') {
            return 'pending';
        }

        if ($transactionStatus === 'expire') {
            return 'expired';
        }

        if (in_array($transactionStatus, ['cancel', 'deny', 'failure'], true)) {
            return 'failed';
        }

        return $transactionStatus !== '' ? $transactionStatus : 'pending';
    }

    public function isConfigured(): bool
    {
        return $this->serverKey() !== '';
    }

    private function client()
    {
        $serverKey = $this->serverKey();
        if ($serverKey === '') {
            throw new RuntimeException('MIDTRANS_SERVER_KEY belum dikonfigurasi');
        }

        return Http::withBasicAuth($serverKey, '')
            ->acceptJson()
            ->asJson()
            ->timeout(20);
    }

    private function snapBaseUrl(): string
    {
        $configured = trim((string) config('services.midtrans.snap_base_url', ''));
        if ($configured !== '') {
            return rtrim($configured, '/');
        }

        return config('services.midtrans.is_production')
            ? 'https://app.midtrans.com'
            : 'https://app.sandbox.midtrans.com';
    }

    private function apiBaseUrl(): string
    {
        $configured = trim((string) config('services.midtrans.api_base_url', ''));
        if ($configured !== '') {
            return rtrim($configured, '/');
        }

        return config('services.midtrans.is_production')
            ? 'https://api.midtrans.com'
            : 'https://api.sandbox.midtrans.com';
    }

    private function serverKey(): string
    {
        return trim((string) config('services.midtrans.server_key', ''));
    }
}
