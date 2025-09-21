CREATE TABLE barang (
  id INT(11) AUTO_INCREMENT PRIMARY KEY,
  nama_barang VARCHAR(255) NOT NULL,
  gambar VARCHAR(255) NOT NULL,
  quantity INT(11) NOT NULL,
  harga DECIMAL(15,2) NOT NULL
);

CREATE TABLE bukti_pembayaran (
  id INT(11) AUTO_INCREMENT PRIMARY KEY,
  id_transaksi INT(11) NOT NULL,
  nama_bank VARCHAR(100) NOT NULL,
  no_rekening VARCHAR(50) NOT NULL,
  nama_pengirim VARCHAR(100) NOT NULL,
  tanggal_upload TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  file_bukti VARCHAR(255) NOT NULL,
  status ENUM('pending','valid','invalid') DEFAULT 'pending',
  FOREIGN KEY (id_transaksi) REFERENCES transaksi(id)
);

CREATE TABLE detail_transaksi (
  id INT(11) AUTO_INCREMENT PRIMARY KEY,
  transaksi_id INT(11) NOT NULL,
  barang_id INT(11) NOT NULL,
  nama_barang VARCHAR(255) NOT NULL,
  harga DECIMAL(15,2) NOT NULL,
  quantity INT(11) NOT NULL,
  subtotal DECIMAL(15,2) NOT NULL,
  FOREIGN KEY (transaksi_id) REFERENCES transaksi(id),
  FOREIGN KEY (barang_id) REFERENCES barang(id)
);

CREATE TABLE keranjang (
  id INT(11) AUTO_INCREMENT PRIMARY KEY,
  user_id INT(11) NOT NULL,
  barang_id INT(11) NOT NULL,
  quantity INT(11) NOT NULL DEFAULT 1,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (user_id) REFERENCES user(id),
  FOREIGN KEY (barang_id) REFERENCES barang(id)
);

CREATE TABLE transaksi (
  id INT(11) AUTO_INCREMENT PRIMARY KEY,
  user_id INT(11) NOT NULL,
  total_harga DECIMAL(15,2) NOT NULL,
  metode_pembayaran ENUM('transfer_bank', 'e_wallet', 'cod') NOT NULL,
  status_pembayaran ENUM('pending', 'paid', 'failed') DEFAULT 'pending',
  status_pesanan ENUM('pending', 'processing', 'shipped', 'delivered', 'cancelled') DEFAULT 'pending',
  alamat_pengiriman TEXT NOT NULL,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  FOREIGN KEY (user_id) REFERENCES user(id)
);

CREATE TABLE user (
    id INT AUTO_INCREMENT PRIMARY KEY,
    nama VARCHAR(100) NOT NULL,
    email VARCHAR(191) NOT NULL UNIQUE,
    password VARCHAR(255) NULL,
    google_uid VARCHAR(255) UNIQUE NULL,
    google_photo TEXT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    last_login TIMESTAMP NULL,
    login_type ENUM('regular','google') DEFAULT 'regular',
    role ENUM('admin','user') NOT NULL DEFAULT 'user',
    email_verified TINYINT(1) DEFAULT 0,
    verify_token VARCHAR(255) NULL
);

CREATE TABLE user_profile (
    id INT AUTO_INCREMENT PRIMARY KEY,
    user_id INT NOT NULL,
    nama_lengkap VARCHAR(100) NULL,
    nomor_hp VARCHAR(20) NULL,
    alamat TEXT NULL,
    kota VARCHAR(50) NULL,
    kode_pos VARCHAR(10) NULL,
    tanggal_lahir DATE NULL,
    jenis_kelamin ENUM('L','P') NULL,
    foto_profil VARCHAR(255) NULL,
    bio TEXT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    CONSTRAINT fk_user FOREIGN KEY (user_id) REFERENCES user(id) ON DELETE CASCADE
);
