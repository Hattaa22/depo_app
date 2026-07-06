<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        $duplicateTokens = DB::table('refresh_tokens')
            ->select('token')
            ->groupBy('token')
            ->havingRaw('COUNT(*) > 1')
            ->pluck('token');

        foreach ($duplicateTokens as $token) {
            DB::table('refresh_tokens')->where('token', $token)->delete();
        }

        Schema::table('refresh_tokens', function (Blueprint $table) {
            $table->unique('token', 'refresh_tokens_token_unique');
        });
    }

    public function down(): void
    {
        Schema::table('refresh_tokens', function (Blueprint $table) {
            $table->dropUnique('refresh_tokens_token_unique');
        });
    }
};
