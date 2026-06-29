<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\HasMany;

class Kategori extends Model
{
    protected $table = 'kategori';

    public $incrementing = false;

    protected $keyType = 'string';

    const UPDATED_AT = null;

    protected $fillable = [
        'id',
        'nama',
        'deskripsi',
        'tipe',
        'ikon',
        'is_system',
        'is_aktif',
    ];

    protected $casts = [
        'is_system' => 'boolean',
        'is_aktif' => 'boolean',
        'created_at' => 'datetime',
    ];

    public function produk(): HasMany
    {
        return $this->hasMany(Produk::class, 'kategori_id');
    }

    public function pengeluaran(): HasMany
    {
        return $this->hasMany(Pengeluaran::class, 'kategori_id');
    }
}
