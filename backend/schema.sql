-- =============================================================================
-- DEPO APP - Database Schema (MySQL)
-- =============================================================================

CREATE TABLE IF NOT EXISTS `users` (
  `id` VARCHAR(100) NOT NULL,
  `role` ENUM('manager', 'crew') NOT NULL,
  `username` VARCHAR(100) NOT NULL UNIQUE,
  `password_hash` VARCHAR(255) NOT NULL,
  `nama` VARCHAR(150) NOT NULL,
  `email` VARCHAR(150) NULL,
  `no_hp` VARCHAR(20) NULL,
  `alamat` TEXT NULL,
  `foto_url` VARCHAR(255) NULL,
  `pin_hash` VARCHAR(255) NULL,
  `is_aktif` TINYINT(1) NOT NULL DEFAULT 1,
  `created_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` DATETIME NULL ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `kategori` (
  `id` VARCHAR(100) NOT NULL,
  `nama` VARCHAR(100) NOT NULL,
  `deskripsi` TEXT NULL,
  `tipe` ENUM('pemasukan', 'pengeluaran') NOT NULL DEFAULT 'pemasukan',
  `ikon` VARCHAR(100) NULL,
  `is_system` TINYINT(1) NOT NULL DEFAULT 0,
  `is_aktif` TINYINT(1) NOT NULL DEFAULT 1,
  `created_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `produk` (
  `id` VARCHAR(100) NOT NULL,
  `nama` VARCHAR(150) NOT NULL,
  `kategori_id` VARCHAR(100) NOT NULL,
  `harga` DECIMAL(12,2) NOT NULL DEFAULT 0.00,
  `stok` INT NOT NULL DEFAULT 0,
  `deskripsi` TEXT NULL,
  `gambar_url` VARCHAR(255) NULL,
  `is_aktif` TINYINT(1) NOT NULL DEFAULT 1,
  `created_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` DATETIME NULL ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  CONSTRAINT `fk_produk_kategori` FOREIGN KEY (`kategori_id`) REFERENCES `kategori` (`id`) ON UPDATE CASCADE ON DELETE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `pelanggan` (
  `id` VARCHAR(100) NOT NULL,
  `nama` VARCHAR(150) NOT NULL,
  `no_hp` VARCHAR(20) NULL,
  `alamat` TEXT NULL,
  `total_galon_pinjam` INT NOT NULL DEFAULT 0,
  `total_transaksi` DECIMAL(14,2) NOT NULL DEFAULT 0.00,
  `catatan` TEXT NULL,
  `is_aktif` TINYINT(1) NOT NULL DEFAULT 1,
  `created_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` DATETIME NULL ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `galon` (
  `id` VARCHAR(100) NOT NULL,
  `kode_galon` VARCHAR(20) NOT NULL UNIQUE,
  `merek` VARCHAR(100) NOT NULL,
  `jenis` ENUM('isi', 'kosong') NOT NULL DEFAULT 'isi',
  `status` ENUM('tersedia', 'dipinjam', 'rusak', 'hilang') NOT NULL DEFAULT 'tersedia',
  `pelanggan_id` VARCHAR(100) NULL,
  `tanggal_pinjam` DATETIME NULL,
  `catatan` TEXT NULL,
  `created_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` DATETIME NULL ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  CONSTRAINT `fk_galon_pelanggan` FOREIGN KEY (`pelanggan_id`) REFERENCES `pelanggan` (`id`) ON UPDATE CASCADE ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `galon_mutasi` (
  `id` VARCHAR(100) NOT NULL,
  `aksi` VARCHAR(50) NOT NULL,
  `jumlah` INT NOT NULL,
  `kode_galon` TEXT NOT NULL,
  `pelanggan_id` VARCHAR(100) NULL,
  `catatan` TEXT NULL,
  `crew_id` VARCHAR(100) NULL,
  `crew_nama` VARCHAR(150) NULL,
  `status_dari` VARCHAR(50) NULL,
  `status_ke` VARCHAR(50) NULL,
  `created_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `transaksi` (
  `id` VARCHAR(100) NOT NULL,
  `nomor_transaksi` VARCHAR(50) NOT NULL UNIQUE,
  `pelanggan_id` VARCHAR(100) NOT NULL,
  `crew_id` VARCHAR(100) NOT NULL,
  `pengirim_crew_id` VARCHAR(100) NULL,
  `total_harga` DECIMAL(14,2) NOT NULL DEFAULT 0.00,
  `metode_pembayaran` ENUM('tunai', 'qris', 'transfer') NOT NULL,
  `status` VARCHAR(50) NOT NULL DEFAULT 'pending',
  `status_validasi` VARCHAR(50) NOT NULL DEFAULT 'pending',
  `bayar` DECIMAL(14,2) NULL,
  `kembalian` DECIMAL(14,2) NULL,
  `qr_payment_id` VARCHAR(100) NULL,
  `catatan` TEXT NULL,
  `tipe_pembelian` VARCHAR(20) NOT NULL DEFAULT 'di_depo',
  `ongkir_per_galon` INT NOT NULL DEFAULT 0,
  `total_ongkir` DECIMAL(14,2) NOT NULL DEFAULT 0.00,
  `validasi_oleh` VARCHAR(100) NULL,
  `validasi_at` DATETIME NULL,
  `qr_paid_at` DATETIME NULL,
  `created_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` DATETIME NULL ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  CONSTRAINT `fk_transaksi_pelanggan` FOREIGN KEY (`pelanggan_id`) REFERENCES `pelanggan` (`id`) ON UPDATE CASCADE ON DELETE RESTRICT,
  CONSTRAINT `fk_transaksi_crew` FOREIGN KEY (`crew_id`) REFERENCES `users` (`id`) ON UPDATE CASCADE ON DELETE RESTRICT,
  CONSTRAINT `fk_transaksi_pengirim_crew` FOREIGN KEY (`pengirim_crew_id`) REFERENCES `users` (`id`) ON UPDATE CASCADE ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `transaksi_items` (
  `id` VARCHAR(100) NOT NULL,
  `transaksi_id` VARCHAR(100) NOT NULL,
  `produk_id` VARCHAR(100) NOT NULL,
  `jumlah` INT NOT NULL DEFAULT 1,
  `harga_satuan` DECIMAL(12,2) NOT NULL,
  `subtotal` DECIMAL(14,2) NOT NULL,
  `galon_pinjam` INT NOT NULL DEFAULT 0,
  `galon_kembali` INT NOT NULL DEFAULT 0,
  PRIMARY KEY (`id`),
  CONSTRAINT `fk_items_transaksi` FOREIGN KEY (`transaksi_id`) REFERENCES `transaksi` (`id`) ON UPDATE CASCADE ON DELETE CASCADE,
  CONSTRAINT `fk_items_produk` FOREIGN KEY (`produk_id`) REFERENCES `produk` (`id`) ON UPDATE CASCADE ON DELETE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `qr_payments` (
  `payment_id` VARCHAR(100) NOT NULL,
  `transaksi_id` VARCHAR(100) NOT NULL,
  `jumlah` DECIMAL(14,2) NOT NULL,
  `qr_content` TEXT NOT NULL,
  `status` VARCHAR(50) NOT NULL DEFAULT 'pending',
  `nama_depot` VARCHAR(150) NOT NULL DEFAULT 'Depo Air Minum',
  `expires_at` DATETIME NOT NULL,
  `created_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `paid_at` DATETIME NULL,
  `updated_at` DATETIME NULL ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`payment_id`),
  CONSTRAINT `fk_qr_transaksi` FOREIGN KEY (`transaksi_id`) REFERENCES `transaksi` (`id`) ON UPDATE CASCADE ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `refresh_tokens` (
  `token` VARCHAR(255) NOT NULL,
  `user_id` VARCHAR(100) NOT NULL,
  `created_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`token`),
  CONSTRAINT `fk_token_user` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON UPDATE CASCADE ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `pengeluaran` (
  `id` VARCHAR(100) NOT NULL,
  `kategori_id` VARCHAR(100) NOT NULL,
  `nominal` DECIMAL(12,2) NOT NULL DEFAULT 0.00,
  `keterangan` TEXT NULL,
  `tanggal` DATE NOT NULL,
  `created_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  CONSTRAINT `fk_pengeluaran_kategori` FOREIGN KEY (`kategori_id`) REFERENCES `kategori` (`id`) ON UPDATE CASCADE ON DELETE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- =============================================================================
-- INDEXES untuk optimalisasi performa query
-- =============================================================================
CREATE INDEX `idx_transaksi_pelanggan` ON `transaksi` (`pelanggan_id`);
CREATE INDEX `idx_transaksi_crew` ON `transaksi` (`crew_id`);
CREATE INDEX `idx_transaksi_pengirim_crew` ON `transaksi` (`pengirim_crew_id`);
CREATE INDEX `idx_transaksi_created` ON `transaksi` (`created_at`);
CREATE INDEX `idx_items_transaksi` ON `transaksi_items` (`transaksi_id`);
CREATE INDEX `idx_galon_status` ON `galon` (`status`);
CREATE INDEX `idx_galon_pelanggan` ON `galon` (`pelanggan_id`);
CREATE INDEX `idx_pengeluaran_tanggal` ON `pengeluaran` (`tanggal`);

CREATE TABLE IF NOT EXISTS `cabang` (
  `id` VARCHAR(100) NOT NULL,
  `nama` VARCHAR(150) NOT NULL,
  `alamat` TEXT NULL,
  `kota` VARCHAR(100) NULL,
  `no_hp` VARCHAR(20) NULL,
  `is_pusat` TINYINT(1) NOT NULL DEFAULT 0,
  `is_aktif` TINYINT(1) NOT NULL DEFAULT 1,
  `created_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` DATETIME NULL ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
