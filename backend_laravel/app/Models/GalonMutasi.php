<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class GalonMutasi extends Model
{
    protected $table = 'galon_mutasi';

    public $incrementing = false;

    protected $keyType = 'string';

    const UPDATED_AT = null;

    protected $fillable = [
        'id',
        'galon_id',
        'pelanggan_id',
        'transaksi_id',
        'jenis_mutasi',
        'catatan',
        'aksi',
        'jumlah',
        'kode_galon',
        'crew_id',
        'crew_nama',
        'status_dari',
        'status_ke',
    ];

    protected $casts = [
        'jumlah' => 'integer',
        'created_at' => 'datetime',
    ];

    public function galon(): BelongsTo
    {
        return $this->belongsTo(Galon::class, 'galon_id');
    }

    public function pelanggan(): BelongsTo
    {
        return $this->belongsTo(Pelanggan::class, 'pelanggan_id');
    }

    public function transaksi(): BelongsTo
    {
        return $this->belongsTo(Transaksi::class, 'transaksi_id');
    }

    public function crew(): BelongsTo
    {
        return $this->belongsTo(User::class, 'crew_id');
    }
}
