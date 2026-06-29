<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('users', function (Blueprint $table) {
            $table->string('id', 100)->primary();
            $table->enum('role', ['manager', 'crew']);
            $table->string('password_hash');
            $table->string('nama', 150);
            $table->string('email', 150)->unique()->nullable();
            $table->string('no_hp', 20)->unique()->nullable();
            $table->text('alamat')->nullable();
            $table->string('foto_url')->nullable();
            $table->string('pin_hash')->nullable();
            $table->boolean('is_aktif')->default(true);
            $table->dateTime('created_at')->useCurrent();
            $table->dateTime('updated_at')->nullable();
        });

        Schema::create('kategori', function (Blueprint $table) {
            $table->string('id', 100)->primary();
            $table->string('nama', 100);
            $table->text('deskripsi')->nullable();
            $table->enum('tipe', ['pemasukan', 'pengeluaran'])->default('pemasukan');
            $table->string('ikon', 100)->nullable();
            $table->boolean('is_system')->default(false);
            $table->boolean('is_aktif')->default(true);
            $table->dateTime('created_at')->useCurrent();
        });

        Schema::create('produk', function (Blueprint $table) {
            $table->string('id', 100)->primary();
            $table->string('nama', 150);
            $table->string('kategori_id', 100);
            $table->decimal('harga', 12, 2)->default(0);
            $table->integer('stok')->default(0);
            $table->text('deskripsi')->nullable();
            $table->string('gambar_url')->nullable();
            $table->boolean('is_aktif')->default(true);
            $table->dateTime('created_at')->useCurrent();

            $table->foreign('kategori_id')->references('id')->on('kategori')->restrictOnDelete()->cascadeOnUpdate();
        });

        Schema::create('pelanggan', function (Blueprint $table) {
            $table->string('id', 100)->primary();
            $table->string('nama', 150);
            $table->string('no_hp', 20)->nullable();
            $table->text('alamat')->nullable();
            $table->integer('total_galon_pinjam')->default(0);
            $table->decimal('total_transaksi', 14, 2)->default(0);
            $table->text('catatan')->nullable();
            $table->boolean('is_aktif')->default(true);
            $table->dateTime('created_at')->useCurrent();
        });

        Schema::create('galon', function (Blueprint $table) {
            $table->string('id', 100)->primary();
            $table->string('kode_galon', 20)->unique();
            $table->string('merek', 100)->default('Depo');
            $table->enum('jenis', ['isi', 'kosong'])->default('isi');
            $table->enum('status', ['tersedia', 'dipinjam', 'rusak', 'hilang'])->default('tersedia');
            $table->string('pelanggan_id', 100)->nullable();
            $table->dateTime('tanggal_pinjam')->nullable();
            $table->text('catatan')->nullable();
            $table->dateTime('created_at')->useCurrent();
            $table->dateTime('updated_at')->nullable();

            $table->index('status', 'idx_galon_status');
            $table->index('pelanggan_id', 'idx_galon_pelanggan');
            $table->foreign('pelanggan_id')->references('id')->on('pelanggan')->nullOnDelete()->cascadeOnUpdate();
        });

        Schema::create('galon_mutasi', function (Blueprint $table) {
            $table->string('id', 100)->primary();
            $table->string('galon_id', 100)->nullable();
            $table->string('pelanggan_id', 100)->nullable();
            $table->string('transaksi_id', 100)->nullable();
            $table->enum('jenis_mutasi', ['pinjam', 'kembali', 'rusak', 'hilang', 'perbaiki']);
            $table->text('catatan')->nullable();
            $table->string('aksi', 50)->nullable();
            $table->integer('jumlah')->default(0);
            $table->text('kode_galon')->nullable();
            $table->string('crew_id', 100)->nullable();
            $table->string('crew_nama', 150)->nullable();
            $table->string('status_dari', 50)->nullable();
            $table->string('status_ke', 50)->nullable();
            $table->dateTime('created_at')->useCurrent();

            $table->index('galon_id', 'fk_mutasi_galon');
            $table->foreign('galon_id')->references('id')->on('galon')->restrictOnDelete()->cascadeOnUpdate();
        });

        Schema::create('transaksi', function (Blueprint $table) {
            $table->string('id', 100)->primary();
            $table->string('nomor_transaksi', 50)->unique();
            $table->string('pelanggan_id', 100)->nullable();
            $table->string('crew_id', 100);
            $table->string('pengirim_crew_id', 100)->nullable();
            $table->decimal('total_harga', 14, 2)->default(0);
            $table->enum('metode_pembayaran', ['tunai', 'qris', 'transfer']);
            $table->string('status', 50)->default('pending');
            $table->string('status_validasi', 50)->default('pending');
            $table->decimal('bayar', 14, 2)->nullable();
            $table->decimal('kembalian', 14, 2)->nullable();
            $table->string('qr_payment_id', 100)->nullable();
            $table->text('catatan')->nullable();
            $table->string('tipe_pembelian', 20)->default('di_depo');
            $table->integer('ongkir_per_galon')->default(0);
            $table->decimal('total_ongkir', 14, 2)->default(0);
            $table->string('validasi_oleh', 100)->nullable();
            $table->dateTime('validasi_at')->nullable();
            $table->dateTime('qr_paid_at')->nullable();
            $table->dateTime('created_at')->useCurrent();
            $table->dateTime('updated_at')->nullable();

            $table->index('pelanggan_id', 'idx_transaksi_pelanggan');
            $table->index('crew_id', 'idx_transaksi_crew');
            $table->index('pengirim_crew_id', 'idx_transaksi_pengirim_crew');
            $table->index('created_at', 'idx_transaksi_created');
            $table->index('status', 'idx_transaksi_status');
            $table->foreign('pelanggan_id')->references('id')->on('pelanggan')->restrictOnDelete()->cascadeOnUpdate();
            $table->foreign('crew_id')->references('id')->on('users')->restrictOnDelete()->cascadeOnUpdate();
            $table->foreign('pengirim_crew_id')->references('id')->on('users')->nullOnDelete()->cascadeOnUpdate();
        });

        Schema::create('transaksi_items', function (Blueprint $table) {
            $table->string('id', 100)->primary();
            $table->string('transaksi_id', 100);
            $table->string('produk_id', 100);
            $table->integer('jumlah')->default(1);
            $table->decimal('harga_satuan', 12, 2);
            $table->decimal('subtotal', 14, 2);
            $table->integer('galon_pinjam')->default(0);
            $table->integer('galon_kembali')->default(0);

            $table->index('transaksi_id', 'idx_items_transaksi');
            $table->foreign('transaksi_id')->references('id')->on('transaksi')->cascadeOnDelete()->cascadeOnUpdate();
            $table->foreign('produk_id')->references('id')->on('produk')->restrictOnDelete()->cascadeOnUpdate();
        });

        Schema::create('qr_payments', function (Blueprint $table) {
            $table->string('payment_id', 100)->primary();
            $table->string('transaksi_id', 100);
            $table->decimal('jumlah', 14, 2);
            $table->text('qr_content');
            $table->string('status', 50)->default('pending');
            $table->string('nama_depot', 150)->default('Depo Air Minum');
            $table->dateTime('expires_at');
            $table->dateTime('created_at')->useCurrent();
            $table->dateTime('paid_at')->nullable();
            $table->dateTime('updated_at')->nullable();

            $table->index('transaksi_id', 'idx_qr_transaksi');
            $table->foreign('transaksi_id')->references('id')->on('transaksi')->cascadeOnDelete()->cascadeOnUpdate();
        });

        Schema::create('refresh_tokens', function (Blueprint $table) {
            $table->string('token');
            $table->string('user_id', 100);
            $table->dateTime('expires_at')->nullable();
            $table->dateTime('created_at')->useCurrent();

            $table->index('user_id', 'idx_refresh_user');
            $table->foreign('user_id')->references('id')->on('users')->cascadeOnDelete()->cascadeOnUpdate();
        });

        Schema::create('pengeluaran', function (Blueprint $table) {
            $table->string('id', 100)->primary();
            $table->string('kategori_id', 100);
            $table->decimal('nominal', 12, 2)->default(0);
            $table->text('keterangan')->nullable();
            $table->date('tanggal');
            $table->dateTime('created_at')->useCurrent();

            $table->index('tanggal', 'idx_pengeluaran_tanggal');
            $table->foreign('kategori_id')->references('id')->on('kategori')->restrictOnDelete()->cascadeOnUpdate();
        });

        Schema::create('cabang', function (Blueprint $table) {
            $table->string('id', 100)->primary();
            $table->string('nama', 150);
            $table->text('alamat')->nullable();
            $table->string('kota', 100)->nullable();
            $table->string('no_hp', 20)->nullable();
            $table->boolean('is_pusat')->default(false);
            $table->boolean('is_aktif')->default(true);
            $table->dateTime('created_at')->useCurrent();
            $table->dateTime('updated_at')->nullable();
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('cabang');
        Schema::dropIfExists('pengeluaran');
        Schema::dropIfExists('refresh_tokens');
        Schema::dropIfExists('qr_payments');
        Schema::dropIfExists('transaksi_items');
        Schema::dropIfExists('transaksi');
        Schema::dropIfExists('galon_mutasi');
        Schema::dropIfExists('galon');
        Schema::dropIfExists('pelanggan');
        Schema::dropIfExists('produk');
        Schema::dropIfExists('kategori');
        Schema::dropIfExists('users');
    }
};
