<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\HasMany;

class Pelanggan extends Model
{
    protected $table = 'pelanggan';

    public $incrementing = false;

    protected $keyType = 'string';

    const UPDATED_AT = null;

    protected $fillable = [
        'id',
        'nama',
        'no_hp',
        'alamat',
        'total_galon_pinjam',
        'total_transaksi',
        'catatan',
        'is_aktif',
    ];

    protected $casts = [
        'total_galon_pinjam' => 'integer',
        'total_transaksi' => 'decimal:2',
        'is_aktif' => 'boolean',
        'created_at' => 'datetime',
    ];

    public function galon(): HasMany
    {
        return $this->hasMany(Galon::class, 'pelanggan_id');
    }

    public function transaksi(): HasMany
    {
        return $this->hasMany(Transaksi::class, 'pelanggan_id');
    }

    public function mutasiGalon(): HasMany
    {
        return $this->hasMany(GalonMutasi::class, 'pelanggan_id');
    }
}
