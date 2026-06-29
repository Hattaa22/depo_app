<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class QrPayment extends Model
{
    protected $table = 'qr_payments';

    protected $primaryKey = 'payment_id';

    public $incrementing = false;

    protected $keyType = 'string';

    protected $fillable = [
        'payment_id',
        'midtrans_order_id',
        'transaksi_id',
        'gateway',
        'jumlah',
        'qr_content',
        'snap_token',
        'redirect_url',
        'status',
        'payment_type',
        'gateway_response',
        'nama_depot',
        'expires_at',
        'paid_at',
    ];

    protected $casts = [
        'jumlah' => 'decimal:2',
        'expires_at' => 'datetime',
        'paid_at' => 'datetime',
        'gateway_response' => 'array',
        'created_at' => 'datetime',
        'updated_at' => 'datetime',
    ];

    public function transaksi(): BelongsTo
    {
        return $this->belongsTo(Transaksi::class, 'transaksi_id');
    }
}
