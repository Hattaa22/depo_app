<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;

class Galon extends Model
{
    protected $table = 'galon';

    public $incrementing = false;

    protected $keyType = 'string';

    protected $fillable = [
        'id',
        'kode_galon',
        'merek',
        'jenis',
        'status',
        'pelanggan_id',
        'tanggal_pinjam',
        'catatan',
    ];

    protected $casts = [
        'tanggal_pinjam' => 'datetime',
        'created_at' => 'datetime',
        'updated_at' => 'datetime',
    ];

    public function pelanggan(): BelongsTo
    {
        return $this->belongsTo(Pelanggan::class, 'pelanggan_id');
    }

    public function mutasi(): HasMany
    {
        return $this->hasMany(GalonMutasi::class, 'galon_id');
    }
}
