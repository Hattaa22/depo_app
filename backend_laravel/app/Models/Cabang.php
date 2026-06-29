<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class Cabang extends Model
{
    protected $table = 'cabang';

    public $incrementing = false;

    protected $keyType = 'string';

    protected $fillable = [
        'id',
        'nama',
        'alamat',
        'kota',
        'no_hp',
        'is_pusat',
        'is_aktif',
    ];

    protected $casts = [
        'is_pusat' => 'boolean',
        'is_aktif' => 'boolean',
        'created_at' => 'datetime',
        'updated_at' => 'datetime',
    ];
}
