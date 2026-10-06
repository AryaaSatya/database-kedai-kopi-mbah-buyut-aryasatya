-- =========================================================
-- DATABASE: db_kedai_kopi_mbah_buyut
-- Sistem Pemesanan Digital QR Code + Aplikasi Kasir
-- DBMS: MySQL / MariaDB
-- =========================================================

CREATE DATABASE IF NOT EXISTS db_kedai_kopi_mbah_buyut
  CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
USE db_kedai_kopi_mbah_buyut;

SET FOREIGN_KEY_CHECKS = 0;

DROP TABLE IF EXISTS coin_transactions;
DROP TABLE IF EXISTS payments;
DROP TABLE IF EXISTS order_items;
DROP TABLE IF EXISTS orders;
DROP TABLE IF EXISTS qr_tables;
DROP TABLE IF EXISTS operating_hours;
DROP TABLE IF EXISTS menu_variants;
DROP TABLE IF EXISTS menus;
DROP TABLE IF EXISTS menu_categories;
DROP TABLE IF EXISTS customers;
DROP TABLE IF EXISTS users;
DROP TABLE IF EXISTS roles;

SET FOREIGN_KEY_CHECKS = 1;

-- 1. ROLE
CREATE TABLE roles (
    id_role INT AUTO_INCREMENT PRIMARY KEY,
    nama_role VARCHAR(30) NOT NULL UNIQUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB;

-- 2. USER
CREATE TABLE users (
    id_user INT AUTO_INCREMENT PRIMARY KEY,
    id_role INT NOT NULL,
    nama_lengkap VARCHAR(100) NOT NULL,
    username VARCHAR(50) NOT NULL UNIQUE,
    email VARCHAR(100) UNIQUE,
    password VARCHAR(255) NOT NULL,
    no_hp VARCHAR(20),
    foto_profil VARCHAR(255),
    status ENUM('aktif','nonaktif') NOT NULL DEFAULT 'aktif',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    CONSTRAINT fk_users_role
        FOREIGN KEY (id_role) REFERENCES roles(id_role)
        ON UPDATE CASCADE ON DELETE RESTRICT
) ENGINE=InnoDB;

-- 3. CUSTOMER / DATA PELANGGAN
CREATE TABLE customers (
    id_customer INT AUTO_INCREMENT PRIMARY KEY,
    id_user INT NOT NULL UNIQUE,
    coin INT NOT NULL DEFAULT 0,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    CONSTRAINT fk_customers_user
        FOREIGN KEY (id_user) REFERENCES users(id_user)
        ON UPDATE CASCADE ON DELETE CASCADE,
    CONSTRAINT chk_customer_coin CHECK (coin >= 0)
) ENGINE=InnoDB;

-- 4. KATEGORI MENU
CREATE TABLE menu_categories (
    id_kategori INT AUTO_INCREMENT PRIMARY KEY,
    nama_kategori VARCHAR(100) NOT NULL UNIQUE,
    deskripsi TEXT,
    status ENUM('aktif','nonaktif') NOT NULL DEFAULT 'aktif',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB;

-- 5. MENU
CREATE TABLE menus (
    id_menu INT AUTO_INCREMENT PRIMARY KEY,
    id_kategori INT NOT NULL,
    nama_menu VARCHAR(100) NOT NULL,
    deskripsi TEXT,
    foto VARCHAR(255),
    status ENUM('tersedia','habis','nonaktif') NOT NULL DEFAULT 'tersedia',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    CONSTRAINT fk_menus_category
        FOREIGN KEY (id_kategori) REFERENCES menu_categories(id_kategori)
        ON UPDATE CASCADE ON DELETE RESTRICT
) ENGINE=InnoDB;

-- 6. VARIAN + HARGA
CREATE TABLE menu_variants (
    id_varian INT AUTO_INCREMENT PRIMARY KEY,
    id_menu INT NOT NULL,
    nama_varian VARCHAR(100) NOT NULL,
    harga DECIMAL(12,2) NOT NULL,
    status ENUM('aktif','nonaktif') NOT NULL DEFAULT 'aktif',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    UNIQUE KEY uk_menu_variant (id_menu, nama_varian),
    CONSTRAINT fk_variants_menu
        FOREIGN KEY (id_menu) REFERENCES menus(id_menu)
        ON UPDATE CASCADE ON DELETE CASCADE,
    CONSTRAINT chk_variant_price CHECK (harga >= 0)
) ENGINE=InnoDB;

-- 7. JAM OPERASIONAL
CREATE TABLE operating_hours (
    id_jam INT AUTO_INCREMENT PRIMARY KEY,
    hari ENUM('Senin','Selasa','Rabu','Kamis','Jumat','Sabtu','Minggu') NOT NULL UNIQUE,
    jam_buka TIME,
    jam_tutup TIME,
    status ENUM('buka','tutup') NOT NULL DEFAULT 'buka',
    CONSTRAINT chk_operating_time CHECK (jam_tutup IS NULL OR jam_buka IS NULL OR jam_tutup > jam_buka)
) ENGINE=InnoDB;

-- 8. MEJA / QR CODE
CREATE TABLE qr_tables (
    id_meja INT AUTO_INCREMENT PRIMARY KEY,
    nomor_meja VARCHAR(20) NOT NULL UNIQUE,
    kode_qr VARCHAR(255) NOT NULL UNIQUE,
    status ENUM('aktif','nonaktif') NOT NULL DEFAULT 'aktif',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB;

-- 9. PESANAN / TRANSAKSI
CREATE TABLE orders (
    id_order BIGINT AUTO_INCREMENT PRIMARY KEY,
    kode_order VARCHAR(30) NOT NULL UNIQUE,
    id_customer INT NULL,
    id_kasir INT NULL,
    id_meja INT NULL,
    jenis_pesanan ENUM('dine_in','take_away') NOT NULL DEFAULT 'dine_in',
    status_order ENUM(
        'menunggu',
        'diproses',
        'siap',
        'selesai',
        'ditolak',
        'dibatalkan'
    ) NOT NULL DEFAULT 'menunggu',
    catatan TEXT,
    subtotal DECIMAL(12,2) NOT NULL DEFAULT 0,
    diskon_coin DECIMAL(12,2) NOT NULL DEFAULT 0,
    total DECIMAL(12,2) NOT NULL DEFAULT 0,
    waktu_pesan DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    waktu_selesai DATETIME NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,

    CONSTRAINT fk_orders_customer
        FOREIGN KEY (id_customer) REFERENCES customers(id_customer)
        ON UPDATE CASCADE ON DELETE SET NULL,

    CONSTRAINT fk_orders_cashier
        FOREIGN KEY (id_kasir) REFERENCES users(id_user)
        ON UPDATE CASCADE ON DELETE SET NULL,

    CONSTRAINT fk_orders_table
        FOREIGN KEY (id_meja) REFERENCES qr_tables(id_meja)
        ON UPDATE CASCADE ON DELETE SET NULL,

    CONSTRAINT chk_order_amounts CHECK (
        subtotal >= 0 AND diskon_coin >= 0 AND total >= 0
    )
) ENGINE=InnoDB;

-- 10. DETAIL PESANAN
CREATE TABLE order_items (
    id_detail BIGINT AUTO_INCREMENT PRIMARY KEY,
    id_order BIGINT NOT NULL,
    id_varian INT NOT NULL,
    jumlah INT NOT NULL,
    harga_satuan DECIMAL(12,2) NOT NULL,
    subtotal DECIMAL(12,2) NOT NULL,
    catatan VARCHAR(255),

    CONSTRAINT fk_order_items_order
        FOREIGN KEY (id_order) REFERENCES orders(id_order)
        ON UPDATE CASCADE ON DELETE CASCADE,

    CONSTRAINT fk_order_items_variant
        FOREIGN KEY (id_varian) REFERENCES menu_variants(id_varian)
        ON UPDATE CASCADE ON DELETE RESTRICT,

    CONSTRAINT chk_item_qty CHECK (jumlah > 0),
    CONSTRAINT chk_item_price CHECK (harga_satuan >= 0 AND subtotal >= 0)
) ENGINE=InnoDB;

-- 11. PEMBAYARAN
CREATE TABLE payments (
    id_pembayaran BIGINT AUTO_INCREMENT PRIMARY KEY,
    id_order BIGINT NOT NULL UNIQUE,
    metode_pembayaran ENUM('tunai','qris','e_wallet','transfer') NOT NULL,
    jumlah_bayar DECIMAL(12,2) NOT NULL,
    status_pembayaran ENUM('menunggu','berhasil','gagal','dibatalkan') NOT NULL DEFAULT 'menunggu',
    referensi_pembayaran VARCHAR(100),
    waktu_bayar DATETIME NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT fk_payments_order
        FOREIGN KEY (id_order) REFERENCES orders(id_order)
        ON UPDATE CASCADE ON DELETE CASCADE,

    CONSTRAINT chk_payment_amount CHECK (jumlah_bayar >= 0)
) ENGINE=InnoDB;

-- 12. RIWAYAT COIN / LOYALITAS
CREATE TABLE coin_transactions (
    id_coin BIGINT AUTO_INCREMENT PRIMARY KEY,
    id_customer INT NOT NULL,
    id_order BIGINT NULL,
    jenis ENUM('perolehan','penukaran','penyesuaian') NOT NULL,
    jumlah INT NOT NULL,
    keterangan VARCHAR(255),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT fk_coin_customer
        FOREIGN KEY (id_customer) REFERENCES customers(id_customer)
        ON UPDATE CASCADE ON DELETE CASCADE,

    CONSTRAINT fk_coin_order
        FOREIGN KEY (id_order) REFERENCES orders(id_order)
        ON UPDATE CASCADE ON DELETE SET NULL,

    CONSTRAINT chk_coin_amount CHECK (jumlah > 0)
) ENGINE=InnoDB;

-- =========================================================
-- DATA AWAL
-- =========================================================

INSERT INTO roles (nama_role) VALUES
('Admin'),
('Kasir'),
('Pelanggan');

INSERT INTO operating_hours (hari, jam_buka, jam_tutup, status) VALUES
('Senin',   '08:00:00', '22:00:00', 'buka'),
('Selasa',  '08:00:00', '22:00:00', 'buka'),
('Rabu',    '08:00:00', '22:00:00', 'buka'),
('Kamis',   '08:00:00', '22:00:00', 'buka'),
('Jumat',   '08:00:00', '22:00:00', 'buka'),
('Sabtu',   '08:00:00', '23:00:00', 'buka'),
('Minggu',  '08:00:00', '23:00:00', 'buka');

INSERT INTO menu_categories (nama_kategori, deskripsi) VALUES
('Kopi', 'Berbagai minuman kopi'),
('Non Kopi', 'Minuman tanpa kopi'),
('Makanan', 'Makanan pendamping'),
('Snack', 'Makanan ringan');

-- =========================================================
-- VIEW LAPORAN PENJUALAN
-- =========================================================
CREATE OR REPLACE VIEW v_laporan_penjualan AS
SELECT
    o.id_order,
    o.kode_order,
    o.waktu_pesan,
    COALESCE(u.nama_lengkap, '-') AS kasir,
    COALESCE(cu.nama_lengkap, 'Pelanggan Umum') AS pelanggan,
    o.jenis_pesanan,
    o.status_order,
    o.subtotal,
    o.diskon_coin,
    o.total,
    COALESCE(p.metode_pembayaran, '-') AS metode_pembayaran,
    COALESCE(p.status_pembayaran, '-') AS status_pembayaran
FROM orders o
LEFT JOIN users u ON o.id_kasir = u.id_user
LEFT JOIN customers c ON o.id_customer = c.id_customer
LEFT JOIN users cu ON c.id_user = cu.id_user
LEFT JOIN payments p ON o.id_order = p.id_order
WHERE o.status_order NOT IN ('dibatalkan', 'ditolak');

-- =========================================================
-- INDEX UNTUK PENCARIAN / LAPORAN
-- =========================================================
CREATE INDEX idx_orders_date ON orders(waktu_pesan);
CREATE INDEX idx_orders_status ON orders(status_order);
CREATE INDEX idx_orders_customer ON orders(id_customer);
CREATE INDEX idx_order_items_order ON order_items(id_order);
CREATE INDEX idx_coin_customer ON coin_transactions(id_customer);

-- =========================================================
-- CONTOH QUERY LAPORAN
-- =========================================================
-- SELECT * FROM v_laporan_penjualan;
-- SELECT DATE(waktu_pesan) AS tanggal, SUM(total) AS omzet
-- FROM orders
-- WHERE status_order = 'selesai'
-- GROUP BY DATE(waktu_pesan)
-- ORDER BY tanggal DESC;
