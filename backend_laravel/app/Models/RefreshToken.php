<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class RefreshToken extends Model
{
    protected $table = 'refresh_tokens';

    protected $primaryKey = 'token';

    public $incrementing = false;

    public $timestamps = false;

    protected $keyType = 'string';

    protected $fillable = [
        'token',
        'user_id',
        'expires_at',
        'created_at',
    ];

    protected $hidden = [
        'token',
    ];

    protected $casts = [
        'expires_at' => 'datetime',
        'created_at' => 'datetime',
    ];

    public function user(): BelongsTo
    {
        return $this->belongsTo(User::class);
    }
}
