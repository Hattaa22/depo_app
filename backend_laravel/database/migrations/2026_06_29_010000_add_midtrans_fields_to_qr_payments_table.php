<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('qr_payments', function (Blueprint $table) {
            if (! Schema::hasColumn('qr_payments', 'gateway')) {
                $table->string('gateway', 50)->default('midtrans')->after('transaksi_id');
            }
            if (! Schema::hasColumn('qr_payments', 'midtrans_order_id')) {
                $table->string('midtrans_order_id', 100)->nullable()->after('payment_id')->index();
            }
            if (! Schema::hasColumn('qr_payments', 'snap_token')) {
                $table->string('snap_token')->nullable()->after('qr_content');
            }
            if (! Schema::hasColumn('qr_payments', 'redirect_url')) {
                $table->text('redirect_url')->nullable()->after('snap_token');
            }
            if (! Schema::hasColumn('qr_payments', 'payment_type')) {
                $table->string('payment_type', 50)->nullable()->after('status');
            }
            if (! Schema::hasColumn('qr_payments', 'gateway_response')) {
                $table->json('gateway_response')->nullable()->after('payment_type');
            }
        });
    }

    public function down(): void
    {
        Schema::table('qr_payments', function (Blueprint $table) {
            if (Schema::hasColumn('qr_payments', 'midtrans_order_id')) {
                $table->dropIndex(['midtrans_order_id']);
            }

            foreach ([
                'gateway',
                'midtrans_order_id',
                'snap_token',
                'redirect_url',
                'payment_type',
                'gateway_response',
            ] as $column) {
                if (Schema::hasColumn('qr_payments', $column)) {
                    $table->dropColumn($column);
                }
            }
        });
    }
};
