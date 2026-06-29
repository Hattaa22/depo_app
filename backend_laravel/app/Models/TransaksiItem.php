<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class TransaksiItem extends Model
{
    protected $table = 'transaksi_items';

    public $incrementing = false;

    public $timestamps = false;

    protected $keyType = 'string';

    protected $fillable = [
        'id',
        'transaksi_id',
        'produk_id',
        'jumlah',
        'harga_satuan',
        'subtotal',
        'galon_pinjam',
        'galon_kembali',
    ];

    protected $casts = [
        'jumlah' => 'integer',
        'harga_satuan' => 'decimal:2',
        'subtotal' => 'decimal:2',
        'galon_pinjam' => 'integer',
        'galon_kembali' => 'integer',
    ];

    public function transaksi(): BelongsTo
    {
        return $this->belongsTo(Transaksi::class, 'transaksi_id');
    }

    public function produk(): BelongsTo
    {
        return $this->belongsTo(Produk::class, 'produk_id');
    }
}
