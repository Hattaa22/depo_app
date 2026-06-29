<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        DB::statement("ALTER TABLE transaksi MODIFY status VARCHAR(50) NOT NULL DEFAULT 'pending'");

        Schema::table('qr_payments', function (Blueprint $table) {
            if (! Schema::hasColumn('qr_payments', 'order_id')) {
                $table->string('order_id', 100)->nullable()->after('payment_id')->index();
            }
            if (! Schema::hasColumn('qr_payments', 'transaction_code')) {
                $table->string('transaction_code', 100)->nullable()->after('order_id')->index();
            }
            if (! Schema::hasColumn('qr_payments', 'payment_url')) {
                $table->text('payment_url')->nullable()->after('redirect_url');
            }
            if (! Schema::hasColumn('qr_payments', 'gross_amount')) {
                $table->decimal('gross_amount', 14, 2)->nullable()->after('jumlah');
            }
            if (! Schema::hasColumn('qr_payments', 'payment_status')) {
                $table->string('payment_status', 50)->default('pending')->after('status');
            }
            if (! Schema::hasColumn('qr_payments', 'transaction_status')) {
                $table->string('transaction_status', 50)->default('pending')->after('payment_status');
            }
            if (! Schema::hasColumn('qr_payments', 'expired_at')) {
                $table->dateTime('expired_at')->nullable()->after('expires_at');
            }
        });

        DB::table('qr_payments')->whereNull('order_id')->update([
            'order_id' => DB::raw('COALESCE(midtrans_order_id, payment_id)'),
        ]);
        DB::table('qr_payments')->whereNull('transaction_code')->update([
            'transaction_code' => DB::raw('payment_id'),
        ]);
        DB::table('qr_payments')->whereNull('payment_url')->update([
            'payment_url' => DB::raw('COALESCE(redirect_url, qr_content)'),
        ]);
        DB::table('qr_payments')->whereNull('gross_amount')->update([
            'gross_amount' => DB::raw('jumlah'),
        ]);
        DB::table('qr_payments')->whereNull('expired_at')->update([
            'expired_at' => DB::raw('expires_at'),
        ]);
    }

    public function down(): void
    {
        Schema::table('qr_payments', function (Blueprint $table) {
            if (Schema::hasColumn('qr_payments', 'order_id')) {
                $table->dropIndex(['order_id']);
            }
            if (Schema::hasColumn('qr_payments', 'transaction_code')) {
                $table->dropIndex(['transaction_code']);
            }

            foreach ([
                'order_id',
                'transaction_code',
                'payment_url',
                'gross_amount',
                'payment_status',
                'transaction_status',
                'expired_at',
            ] as $column) {
                if (Schema::hasColumn('qr_payments', $column)) {
                    $table->dropColumn($column);
                }
            }
        });

        DB::statement("ALTER TABLE transaksi MODIFY status ENUM('pending', 'paid', 'expired', 'cancelled') NOT NULL DEFAULT 'pending'");
    }
};
