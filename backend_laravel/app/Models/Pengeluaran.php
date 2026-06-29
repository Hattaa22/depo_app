<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class Pengeluaran extends Model
{
    protected $table = 'pengeluaran';

    public $incrementing = false;

    protected $keyType = 'string';

    const UPDATED_AT = null;

    protected $fillable = [
        'id',
        'kategori_id',
        'nominal',
        'keterangan',
        'tanggal',
    ];

    protected $casts = [
        'nominal' => 'decimal:2',
        'tanggal' => 'date',
        'created_at' => 'datetime',
    ];

    public function kategori(): BelongsTo
    {
        return $this->belongsTo(Kategori::class, 'kategori_id');
    }
}
