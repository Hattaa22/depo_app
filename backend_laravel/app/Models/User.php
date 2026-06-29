<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Relations\HasMany;
use Illuminate\Foundation\Auth\User as Authenticatable;
use Illuminate\Notifications\Notifiable;

class User extends Authenticatable
{
    use Notifiable;

    public $incrementing = false;

    protected $keyType = 'string';

    const UPDATED_AT = 'updated_at';

    const CREATED_AT = 'created_at';

    /**
     * The attributes that are mass assignable.
     *
     * @var array<int, string>
     */
    protected $fillable = [
        'id',
        'role',
        'nama',
        'email',
        'password_hash',
        'pin_hash',
        'no_hp',
        'alamat',
        'foto_url',
        'is_aktif',
    ];

    /**
     * The attributes that should be hidden for serialization.
     *
     * @var array<int, string>
     */
    protected $hidden = [
        'password_hash',
        'pin_hash',
    ];

    /**
     * The attributes that should be cast.
     *
     * @var array<string, string>
     */
    protected $casts = [
        'is_aktif' => 'boolean',
        'created_at' => 'datetime',
        'updated_at' => 'datetime',
    ];

    public function transaksi(): HasMany
    {
        return $this->hasMany(Transaksi::class, 'crew_id');
    }

    public function pengiriman(): HasMany
    {
        return $this->hasMany(Transaksi::class, 'pengirim_crew_id');
    }

    public function refreshTokens(): HasMany
    {
        return $this->hasMany(RefreshToken::class);
    }

    public function galonMutasi(): HasMany
    {
        return $this->hasMany(GalonMutasi::class, 'crew_id');
    }
}
