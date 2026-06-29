<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;

class Produk extends Model
{
    protected $table = 'produk';

    public $incrementing = false;

    protected $keyType = 'string';

    const UPDATED_AT = null;

    protected $fillable = [
        'id',
        'nama',
        'kategori_id',
        'harga',
        'stok',
        'deskripsi',
        'gambar_url',
        'is_aktif',
    ];

    protected $casts = [
        'harga' => 'decimal:2',
        'stok' => 'integer',
        'is_aktif' => 'boolean',
        'created_at' => 'datetime',
    ];

    public function kategori(): BelongsTo
    {
        return $this->belongsTo(Kategori::class, 'kategori_id');
    }

    public function transaksiItems(): HasMany
    {
        return $this->hasMany(TransaksiItem::class, 'produk_id');
    }
}
