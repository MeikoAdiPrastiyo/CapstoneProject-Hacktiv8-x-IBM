# 🛒 FarmStock – E-Commerce System (Jakarta EE + JSP)

## 📌 Project Overview
Proyek ini merupakan sistem e-commerce sederhana berbasis **Jakarta EE (GlassFish Server)** dengan dukungan autentikasi **Firebase (Google Login)**.  
Terdapat tiga role utama pengguna:
- **Guest** → hanya bisa melihat daftar barang.  
- **User** → bisa melakukan transaksi (keranjang, checkout, riwayat, lacak pesanan, profil, logout).  
- **Admin** → memiliki akses penuh ke dashboard (home, data register, master barang, transaksi).  

Tujuan proyek adalah menyediakan platform sederhana untuk memahami integrasi antara **JSP**, **Database MySQL**, dan **Firebase Authentication**.

---

## 🛠️ Technologies Used
- **GlassFish Server (Jakarta EE)**
- **NetBeans IDE**
- **Bootstrap 5.0.2** (UI Styling)
- **HTML, CSS, JavaScript, JSP**
- **MySQL (XAMPP)** sebagai database
- **Firebase Authentication** untuk Google Login
- **Libraries**:
  - `mysql-connector-j-9.3.0.jar`
  - `gson-2.13.1.jar`
  - `javax.servlet-api-3.0.1.jar`

---

## 📂 Features
### Admin Dashboard
- Home  
- Data Register  
- Master Barang (CRUD Produk)  
- Transaksi  

### User Dashboard
- Dashboard  
- Daftar Barang  
- Keranjang  
- Riwayat Transaksi  
- Lacak Pesanan  
- Profile Settings  
- Logout  

### Guest
- Bisa melihat daftar barang sebelum login  

---

## 🔐 Firebase Google Login
1. Masuk ke [Firebase Console](https://console.firebase.google.com/).  
2. Buat project baru → aktifkan **Authentication**.  
3. Pilih metode login → aktifkan **Google Sign-In**.  
4. Tambahkan Web App dan salin konfigurasi Firebase SDK:  
5. Simpan file konfigurasi ke js/firebase-config.js.
6. Panggil Firebase Authentication di halaman login.html.
```javascript
const firebaseConfig = {
  apiKey: "API_KEY",
  authDomain: "PROJECT_ID.firebaseapp.com",
  projectId: "PROJECT_ID",
  storageBucket: "PROJECT_ID.appspot.com",
  messagingSenderId: "SENDER_ID",
  appId: "APP_ID"
};

Simpan file konfigurasi ke js/firebase-config.js.

Panggil Firebase Authentication di halaman login.html.
