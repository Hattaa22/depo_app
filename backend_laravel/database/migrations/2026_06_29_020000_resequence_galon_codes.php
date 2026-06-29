<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Support\Facades\DB;

return new class extends Migration
{
    public function up(): void
    {
        DB::transaction(function () {
            $rows = DB::table('galon')
                ->orderBy('created_at')
                ->orderBy('kode_galon')
                ->orderBy('id')
                ->get(['id']);

            foreach ($rows as $index => $row) {
                DB::table('galon')->where('id', $row->id)->update([
                    'kode_galon' => 'TMP-'.str_pad((string) ($index + 1), 6, '0', STR_PAD_LEFT),
                    'merek' => 'Depo',
                ]);
            }

            foreach ($rows as $index => $row) {
                DB::table('galon')->where('id', $row->id)->update([
                    'kode_galon' => 'G-'.str_pad((string) ($index + 1), 3, '0', STR_PAD_LEFT),
                    'merek' => 'Depo',
                ]);
            }
        });
    }

    public function down(): void
    {
        //
    }
};
