<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;
use Illuminate\Database\Eloquent\Relations\HasOne;

class Transaksi extends Model
{
    protected $table = 'transaksi';

    public $incrementing = false;

    protected $keyType = 'string';

    protected $fillable = [
        'id',
        'nomor_transaksi',
        'pelanggan_id',
        'crew_id',
        'pengirim_crew_id',
        'total_harga',
        'metode_pembayaran',
        'status',
        'status_validasi',
        'bayar',
        'kembalian',
        'qr_payment_id',
        'catatan',
        'tipe_pembelian',
        'ongkir_per_galon',
        'total_ongkir',
        'validasi_oleh',
        'validasi_at',
        'qr_paid_at',
    ];

    protected $casts = [
        'total_harga' => 'decimal:2',
        'bayar' => 'decimal:2',
        'kembalian' => 'decimal:2',
        'ongkir_per_galon' => 'integer',
        'total_ongkir' => 'decimal:2',
        'validasi_at' => 'datetime',
        'qr_paid_at' => 'datetime',
        'created_at' => 'datetime',
        'updated_at' => 'datetime',
    ];

    public function pelanggan(): BelongsTo
    {
        return $this->belongsTo(Pelanggan::class, 'pelanggan_id');
    }

    public function crew(): BelongsTo
    {
        return $this->belongsTo(User::class, 'crew_id');
    }

    public function pengirimCrew(): BelongsTo
    {
        return $this->belongsTo(User::class, 'pengirim_crew_id');
    }

    public function items(): HasMany
    {
        return $this->hasMany(TransaksiItem::class, 'transaksi_id');
    }

    public function qrPayment(): HasOne
    {
        return $this->hasOne(QrPayment::class, 'transaksi_id');
    }
}
