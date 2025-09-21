<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ page import="java.sql.*" %>
<%@ page import="java.util.*" %>
<%
    // Koneksi Database
    String DB_URL = "jdbc:mysql://localhost:3306/webcapstone";
    String DB_USER = "root";
    String DB_PASS = "";
    
    // Cek session user - SESUAIKAN dengan session yang kita set di koneksidb.jsp
    String userName = (String) session.getAttribute("username"); // bukan userName
    Integer userId = (Integer) session.getAttribute("user_id");   // bukan userId
    String userRole = (String) session.getAttribute("role");     // Tambahkan untuk cek role
    boolean isLoggedIn = (userName != null && userId != null);
    boolean isAdmin = "admin".equals(userRole);
    
    // Hitung jumlah item di keranjang (hanya untuk non-admin)
    int cartCount = 0;
    if (isLoggedIn && !isAdmin) {
        try {
            Class.forName("com.mysql.cj.jdbc.Driver");
            Connection conn = DriverManager.getConnection(DB_URL, DB_USER, DB_PASS);
            String sql = "SELECT SUM(quantity) as total FROM keranjang WHERE user_id = ?";
            PreparedStatement pstmt = conn.prepareStatement(sql);
            pstmt.setInt(1, userId);
            ResultSet rs = pstmt.executeQuery();
            if (rs.next() && rs.getObject("total") != null) {
                cartCount = rs.getInt("total");
            }
            conn.close();
        } catch (Exception e) {
            e.printStackTrace();
        }
    } else if (!isLoggedIn) {
        // SESUAIKAN dengan session cart yang kita gunakan
        Map<Integer, Integer> guestCart = (Map<Integer, Integer>) session.getAttribute("cart");
        if (guestCart != null) {
            for (int qty : guestCart.values()) {
                cartCount += qty;
            }
        }
    }
%>
<!DOCTYPE html>
<html lang="id">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>FarmStock - Peternakan & Pertanian Terpercaya</title>
    <link href="https://cdnjs.cloudflare.com/ajax/libs/bootstrap/5.0.2/css/bootstrap.min.css" rel="stylesheet">
    <link href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.4.0/css/all.min.css" rel="stylesheet">
    <link href="https://fonts.googleapis.com/css2?family=Poppins:wght@300;400;600;700;800&display=swap" rel="stylesheet">
    <style>
        :root {
            --primary: #2d5016;
            --secondary: #4a7c59;
            --accent: #8bc34a;
            --gold: #ffc107;
            --cream: #f8f6f0;
            --brown: #8d6e63;
            --green-light: #e8f5e8;
        }

        * { 
            margin: 0; 
            padding: 0; 
            box-sizing: border-box; 
        }

        body {
            font-family: 'Poppins', sans-serif;
            background: var(--cream);
            line-height: 1.6;
        }

        /* Enhanced Navigation */
        .navbar {
            background: linear-gradient(135deg, var(--primary) 0%, var(--secondary) 100%);
            padding: 1rem 0;
            box-shadow: 0 4px 20px rgba(45, 80, 22, 0.3);
            position: sticky;
            top: 0;
            z-index: 1000;
        }

        .navbar-brand {
            font-size: 2rem;
            font-weight: 800;
            color: white !important;
            text-shadow: 2px 2px 4px rgba(0,0,0,0.4);
            display: flex;
            align-items: center;
            gap: 10px;
        }

        .navbar-brand i {
            font-size: 2.2rem;
            color: var(--accent);
        }

        .navbar-nav .nav-link {
            color: rgba(255,255,255,0.9) !important;
            font-weight: 500;
            margin: 0 15px;
            transition: all 0.3s ease;
            position: relative;
        }

        .navbar-nav .nav-link:hover {
            color: var(--accent) !important;
            transform: translateY(-2px);
        }

        .navbar-nav .nav-link::after {
            content: '';
            position: absolute;
            width: 0;
            height: 2px;
            bottom: -5px;
            left: 50%;
            background: var(--accent);
            transition: all 0.3s ease;
        }

        .navbar-nav .nav-link:hover::after {
            width: 100%;
            left: 0;
        }

        .cart-icon {
            position: relative;
            font-size: 1.6rem;
            color: white;
            text-decoration: none;
            transition: all 0.3s ease;
            cursor: pointer;
            margin-right: 20px;
        }

        .cart-icon:hover { 
            color: var(--accent); 
            transform: scale(1.1); 
        }

        .cart-icon.disabled {
            opacity: 0.5;
            cursor: not-allowed;
        }

        .cart-icon.disabled:hover {
            color: white;
            transform: none;
        }

        .cart-count {
            position: absolute;
            top: -8px;
            right: -8px;
            background: var(--gold);
            color: #333;
            border-radius: 50%;
            width: 24px;
            height: 24px;
            display: flex;
            align-items: center;
            justify-content: center;
            font-size: 0.8rem;
            font-weight: bold;
            box-shadow: 0 2px 8px rgba(0,0,0,0.3);
            animation: pulse 2s infinite;
        }

        @keyframes pulse {
            0% { transform: scale(1); }
            50% { transform: scale(1.1); }
            100% { transform: scale(1); }
        }

        .admin-badge {
            background: linear-gradient(135deg, #dc3545, #e83e8c);
            color: white;
            padding: 0.4rem 1rem;
            border-radius: 20px;
            font-size: 0.8rem;
            font-weight: 700;
            margin-left: 15px;
            box-shadow: 0 2px 10px rgba(220, 53, 69, 0.3);
        }

        /* Enhanced Hero Section */
        .hero-section {
            background: linear-gradient(135deg, rgba(45, 80, 22, 0.85), rgba(74, 124, 89, 0.85)),
                        url('https://images.unsplash.com/photo-1500937386664-56d1dfef3854?ixlib=rb-4.0.3&auto=format&fit=crop&w=2000&q=80') center/cover;
            color: white;
            padding: 120px 0;
            text-align: center;
            position: relative;
            overflow: hidden;
        }

        .hero-section::before {
            content: '';
            position: absolute;
            top: 0;
            left: 0;
            right: 0;
            bottom: 0;
            background: url('data:image/svg+xml,<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 100 100"><circle cx="20" cy="20" r="2" fill="rgba(255,255,255,0.1)"/><circle cx="80" cy="40" r="1.5" fill="rgba(255,255,255,0.1)"/><circle cx="40" cy="80" r="1" fill="rgba(255,255,255,0.1)"/></svg>');
            animation: float 20s infinite linear;
        }

        @keyframes float {
            0% { transform: translateY(0); }
            100% { transform: translateY(-100px); }
        }

        .hero-content {
            position: relative;
            z-index: 2;
        }

        .hero-title {
            font-size: 4rem;
            font-weight: 800;
            margin-bottom: 1.5rem;
            text-shadow: 3px 3px 6px rgba(0,0,0,0.4);
            animation: fadeInUp 1s ease-out;
        }

        .hero-subtitle {
            font-size: 1.4rem;
            margin-bottom: 2.5rem;
            opacity: 0.95;
            font-weight: 400;
            animation: fadeInUp 1s ease-out 0.3s both;
        }

        .hero-stats {
            display: flex;
            justify-content: center;
            gap: 3rem;
            margin-top: 3rem;
            animation: fadeInUp 1s ease-out 0.6s both;
        }

        .stat-item {
            text-align: center;
        }

        .stat-number {
            font-size: 2.5rem;
            font-weight: 800;
            color: var(--accent);
            display: block;
        }

        .stat-label {
            font-size: 1rem;
            opacity: 0.9;
            margin-top: 0.5rem;
        }

        @keyframes fadeInUp {
            from {
                opacity: 0;
                transform: translateY(30px);
            }
            to {
                opacity: 1;
                transform: translateY(0);
            }
        }

        /* Enhanced Search Section */
        .search-section {
            background: white;
            padding: 2.5rem;
            border-radius: 25px;
            box-shadow: 0 15px 35px rgba(0,0,0,0.1);
            margin: -80px auto 80px;
            max-width: 700px;
            position: relative;
            z-index: 10;
            border: 3px solid var(--green-light);
        }

        .search-wrapper {
            position: relative;
        }

        .search-icon {
            position: absolute;
            left: 20px;
            top: 50%;
            transform: translateY(-50%);
            color: var(--secondary);
            font-size: 1.3rem;
            z-index: 5;
        }

        .form-control {
            border-radius: 15px;
            border: 2px solid var(--green-light);
            padding: 1rem 1rem 1rem 60px;
            font-size: 1.1rem;
            transition: all 0.3s ease;
            box-shadow: 0 2px 10px rgba(0,0,0,0.05);
        }

        .form-control:focus {
            border-color: var(--accent);
            box-shadow: 0 0 0 0.2rem rgba(139, 195, 74, 0.25);
            transform: translateY(-2px);
        }

        /* Features Section */
        .features-section {
            padding: 100px 0;
            background: white;
        }

        .section-title {
            text-align: center;
            margin-bottom: 4rem;
        }

        .section-title h2 {
            font-size: 3rem;
            font-weight: 700;
            color: var(--primary);
            margin-bottom: 1rem;
        }

        .section-title p {
            font-size: 1.2rem;
            color: var(--brown);
            max-width: 600px;
            margin: 0 auto;
        }

        .features-grid {
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(300px, 1fr));
            gap: 2.5rem;
            margin-top: 3rem;
        }

        .feature-card {
            background: linear-gradient(135deg, #fff 0%, var(--green-light) 100%);
            padding: 2.5rem;
            border-radius: 20px;
            text-align: center;
            box-shadow: 0 10px 30px rgba(0,0,0,0.08);
            transition: all 0.4s ease;
            border: 2px solid transparent;
        }

        .feature-card:hover {
            transform: translateY(-10px);
            box-shadow: 0 20px 40px rgba(0,0,0,0.15);
            border-color: var(--accent);
        }

        .feature-icon {
            width: 80px;
            height: 80px;
            background: linear-gradient(135deg, var(--accent), var(--secondary));
            border-radius: 50%;
            display: flex;
            align-items: center;
            justify-content: center;
            margin: 0 auto 1.5rem;
            font-size: 2rem;
            color: white;
            box-shadow: 0 8px 20px rgba(139, 195, 74, 0.3);
        }

        .feature-title {
            font-size: 1.5rem;
            font-weight: 700;
            color: var(--primary);
            margin-bottom: 1rem;
        }

        .feature-desc {
            color: var(--brown);
            line-height: 1.8;
        }

        /* Products Preview Section */
        .products-preview {
            padding: 100px 0;
            background: linear-gradient(135deg, var(--green-light) 0%, #fff 100%);
        }

        .products-grid {
            display: grid;
            grid-template-columns: repeat(auto-fill, minmax(320px, 1fr));
            gap: 2.5rem;
            margin-top: 3rem;
        }

        .product-card {
            background: white;
            border-radius: 25px;
            overflow: hidden;
            box-shadow: 0 15px 35px rgba(0,0,0,0.1);
            transition: all 0.4s ease;
            position: relative;
            border: 3px solid transparent;
        }

        .product-card:hover {
            transform: translateY(-15px);
            box-shadow: 0 25px 50px rgba(0,0,0,0.2);
            border-color: var(--accent);
        }

        .product-image {
            width: 100%;
            height: 280px;
            object-fit: cover;
            background: var(--green-light);
            transition: all 0.4s ease;
        }

        .product-card:hover .product-image {
            transform: scale(1.05);
        }

        .product-overlay {
            position: absolute;
            top: 0;
            left: 0;
            right: 0;
            height: 280px;
            background: linear-gradient(135deg, rgba(45, 80, 22, 0.8), rgba(74, 124, 89, 0.8));
            opacity: 0;
            transition: all 0.4s ease;
            display: flex;
            align-items: center;
            justify-content: center;
        }

        .product-card:hover .product-overlay {
            opacity: 1;
        }

        .overlay-content {
            text-align: center;
            color: white;
        }

        .overlay-title {
            font-size: 1.8rem;
            font-weight: 700;
            margin-bottom: 1rem;
        }

        .overlay-subtitle {
            font-size: 1.1rem;
            opacity: 0.9;
        }

        .stock-badge {
            position: absolute;
            top: 20px;
            right: 20px;
            padding: 0.6rem 1.2rem;
            border-radius: 25px;
            font-size: 0.85rem;
            font-weight: 700;
            text-transform: uppercase;
            backdrop-filter: blur(10px);
            border: 2px solid rgba(255,255,255,0.3);
        }

        .stock-high { 
            background: rgba(76, 175, 80, 0.9); 
            color: white; 
            box-shadow: 0 4px 15px rgba(76, 175, 80, 0.4);
        }
        .stock-medium { 
            background: rgba(255, 193, 7, 0.9); 
            color: #333; 
            box-shadow: 0 4px 15px rgba(255, 193, 7, 0.4);
        }
        .stock-low { 
            background: rgba(255, 87, 34, 0.9); 
            color: white; 
            box-shadow: 0 4px 15px rgba(255, 87, 34, 0.4);
        }
        .stock-out { 
            background: rgba(244, 67, 54, 0.9); 
            color: white; 
            box-shadow: 0 4px 15px rgba(244, 67, 54, 0.4);
        }

        .product-content { 
            padding: 2rem; 
        }

        .product-name {
            font-size: 1.4rem;
            font-weight: 700;
            color: var(--primary);
            margin-bottom: 0.8rem;
            line-height: 1.3;
        }

        .product-price {
            font-size: 1.6rem;
            font-weight: 800;
            color: var(--secondary);
            margin-bottom: 1rem;
        }

        .product-stock {
            color: var(--brown);
            margin-bottom: 1.5rem;
            font-weight: 500;
        }

        .quantity-controls {
            display: flex;
            align-items: center;
            justify-content: center;
            gap: 0.8rem;
            margin-bottom: 1.5rem;
        }

        .qty-btn {
            background: linear-gradient(135deg, var(--accent), var(--secondary));
            color: white;
            border: none;
            width: 45px;
            height: 45px;
            border-radius: 50%;
            display: flex;
            align-items: center;
            justify-content: center;
            cursor: pointer;
            transition: all 0.3s ease;
            font-weight: 700;
            box-shadow: 0 4px 15px rgba(139, 195, 74, 0.3);
        }

        .qty-btn:hover { 
            transform: scale(1.1);
            box-shadow: 0 6px 20px rgba(139, 195, 74, 0.4);
        }
        
        .qty-btn:disabled { 
            background: #ccc; 
            cursor: not-allowed; 
            transform: none; 
            box-shadow: none;
        }

        .qty-input {
            width: 90px;
            text-align: center;
            border: 2px solid var(--green-light);
            border-radius: 12px;
            padding: 0.8rem;
            font-weight: 700;
            font-size: 1.1rem;
            transition: all 0.3s ease;
        }

        .qty-input:focus {
            border-color: var(--accent);
            box-shadow: 0 0 0 0.2rem rgba(139, 195, 74, 0.25);
        }

        .btn-add-cart {
            background: linear-gradient(135deg, var(--gold), #ffeb3b);
            color: #333;
            border: none;
            padding: 1rem 2rem;
            border-radius: 15px;
            font-weight: 700;
            width: 100%;
            transition: all 0.3s ease;
            text-transform: uppercase;
            letter-spacing: 1px;
            font-size: 1rem;
            box-shadow: 0 6px 20px rgba(255, 193, 7, 0.3);
        }

        .btn-add-cart:hover {
            transform: translateY(-3px);
            box-shadow: 0 10px 25px rgba(255, 193, 7, 0.4);
        }

        .btn-add-cart:disabled {
            background: #6c757d;
            cursor: not-allowed;
            transform: none;
            box-shadow: none;
        }

        .admin-notice {
            background: linear-gradient(135deg, #495057, #343a40);
            color: #fff;
            padding: 1rem 1.5rem;
            border-radius: 15px;
            font-weight: 600;
            width: 100%;
            margin: 0;
            box-shadow: 0 8px 20px rgba(0, 0, 0, 0.25);
            text-align: center;
            letter-spacing: 0.5px;
            transition: all 0.3s ease;
            border: 2px solid rgba(255,255,255,0.1);
        }

        .admin-notice:hover {
            transform: translateY(-2px);
            box-shadow: 0 10px 25px rgba(0, 0, 0, 0.3);
        }

        /* CTA Section */
        .cta-section {
            background: linear-gradient(135deg, var(--primary) 0%, var(--secondary) 100%),
                        url('https://images.unsplash.com/photo-1516253593875-bd7ba052fbc2?ixlib=rb-4.0.3&auto=format&fit=crop&w=1600&q=80') center/cover;
            color: white;
            padding: 100px 0;
            text-align: center;
            position: relative;
        }

        .cta-section::before {
            content: '';
            position: absolute;
            top: 0;
            left: 0;
            right: 0;
            bottom: 0;
            background: linear-gradient(135deg, rgba(45, 80, 22, 0.9), rgba(74, 124, 89, 0.9));
        }

        .cta-content {
            position: relative;
            z-index: 2;
        }

        .cta-title {
            font-size: 3rem;
            font-weight: 800;
            margin-bottom: 1.5rem;
        }

        .cta-subtitle {
            font-size: 1.3rem;
            margin-bottom: 2.5rem;
            opacity: 0.9;
        }

        .cta-buttons {
            display: flex;
            gap: 1.5rem;
            justify-content: center;
            flex-wrap: wrap;
        }

        .btn-cta {
            background: var(--gold);
            color: #333;
            padding: 1rem 2.5rem;
            border-radius: 50px;
            text-decoration: none;
            font-weight: 700;
            font-size: 1.1rem;
            transition: all 0.3s ease;
            box-shadow: 0 8px 25px rgba(255, 193, 7, 0.3);
        }

        .btn-cta:hover {
            color: #333;
            transform: translateY(-3px);
            box-shadow: 0 12px 30px rgba(255, 193, 7, 0.4);
        }

        .btn-cta-outline {
            background: transparent;
            color: white;
            border: 2px solid white;
        }

        .btn-cta-outline:hover {
            background: white;
            color: var(--primary);
        }

        /* Notifications */
        .notification {
            position: fixed;
            top: 20px;
            right: 20px;
            padding: 1.2rem 2rem;
            border-radius: 15px;
            color: white;
            font-weight: 600;
            z-index: 1000;
            transform: translateX(400px);
            transition: transform 0.3s ease;
            box-shadow: 0 8px 25px rgba(0,0,0,0.15);
        }

        .notification.show { transform: translateX(0); }
        .notification.success { background: linear-gradient(135deg, #28a745, #20c997); }
        .notification.error { background: linear-gradient(135deg, #dc3545, #e83e8c); }
        .notification.info { background: linear-gradient(135deg, #17a2b8, #6f42c1); }

        .no-products {
            text-align: center;
            padding: 5rem 2rem;
            color: var(--brown);
        }

        .no-products i {
            font-size: 5rem;
            margin-bottom: 2rem;
            color: var(--green-light);
        }

        /* Responsive Design */
        @media (max-width: 768px) {
            .hero-title { font-size: 2.5rem; }
            .hero-stats { flex-direction: column; gap: 1.5rem; }
            .section-title h2 { font-size: 2.2rem; }
            .products-grid { grid-template-columns: 1fr; gap: 2rem; }
            .features-grid { grid-template-columns: 1fr; }
            .cta-title { font-size: 2.2rem; }
            .cta-buttons { flex-direction: column; align-items: center; }
        }

        /* Animations */
        .fade-in {
            animation: fadeIn 1s ease-out;
        }

        @keyframes fadeIn {
            from { opacity: 0; }
            to { opacity: 1; }
        }

        .slide-up {
            animation: slideUp 0.8s ease-out;
        }

        @keyframes slideUp {
            from {
                opacity: 0;
                transform: translateY(50px);
            }
            to {
                opacity: 1;
                transform: translateY(0);
            }
        }
    </style>
</head>
<body>
    <!-- Navigation -->
    <nav class="navbar navbar-expand-lg">
        <div class="container">
            <a class="navbar-brand" href="#">
                <i class="fas fa-tractor"></i> FarmStock
            </a>
            
            <div class="navbar-nav ms-auto d-flex align-items-center">
                <% if (isLoggedIn) { %>
                    <% if (isAdmin) { %>
                        <!-- Admin Navigation -->
                        <a href="transaksi.jsp" class="nav-link">
                            <i class="fas fa-chart-line"></i> Dashboard
                        </a>
                        <!-- Disabled Cart for Admin -->
                        <span class="cart-icon disabled" onclick="showAdminNotification()">
                            <i class="fas fa-shopping-cart"></i>
                            <span class="cart-count">0</span>
                        </span>
                        <span class="nav-link">Halo, <%= userName %></span>
                        <span class="admin-badge">
                            <i class="fas fa-user-shield"></i> ADMIN
                        </span>
                    <% } else { %>
                        <!-- Regular User Navigation -->
                        <a href="keranjangUser.jsp" class="cart-icon">
                            <i class="fas fa-shopping-cart"></i>
                            <span class="cart-count"><%= cartCount %></span>
                        </a>
                        <span class="nav-link">Halo, <%= userName %></span>
                    <% } %>
                    <a class="nav-link" href="logout.jsp">
                        <i class="fas fa-sign-out-alt"></i> Logout
                    </a>
                <% } else { %>
                    <a href="keranjangGuest.jsp" class="cart-icon">
                        <i class="fas fa-shopping-cart"></i>
                        <span class="cart-count"><%= cartCount %></span>
                    </a>
                    <a class="nav-link" href="login.html">
                        <i class="fas fa-sign-in-alt"></i> Login
                    </a>
                    <a class="nav-link" href="register.html">
                        <i class="fas fa-user-plus"></i> Register
                    </a>
                <% } %>
            </div>
        </div>
    </nav>

    <!-- Hero Section -->
    <section class="hero-section">
        <div class="container">
            <div class="hero-content">
                <h1 class="hero-title">🌾 Selamat Datang di FarmStock</h1>
                <p class="hero-subtitle">Platform Terpercaya untuk Kebutuhan Peternakan & Pertanian Modern</p>
                
                <div class="hero-stats">
                    <div class="stat-item">
                        <span class="stat-number">500+</span>
                        <span class="stat-label">Produk Berkualitas</span>
                    </div>
                    <div class="stat-item">
                        <span class="stat-number">1000+</span>
                        <span class="stat-label">Pelanggan Puas</span>
                    </div>
                    <div class="stat-item">
                        <span class="stat-number">24/7</span>
                        <span class="stat-label">Layanan Support</span>
                    </div>
                </div>
            </div>
        </div>
    </section>

    <!-- Search Section -->
    <div class="container">
        <div class="search-section slide-up">
            <div class="search-wrapper">
                <i class="fas fa-search search-icon"></i>
                <input type="text" class="form-control" id="searchInput" placeholder="Cari produk peternakan, pakan ternak, alat pertanian...">
            </div>
        </div>
    </div>

    <!-- Features Section -->
    <section class="features-section fade-in">
        <div class="container">
            <div class="section-title">
                <h2>🎯 Mengapa Memilih FarmStock</h2>
                <p>Kami menyediakan solusi lengkap untuk kebutuhan peternakan dan pertanian Anda dengan kualitas terbaik dan harga terjangkau</p>
            </div>
            
            <div class="features-grid">
                <div class="feature-card">
                    <div class="feature-icon">
                        <i class="fas fa-leaf"></i>
                    </div>
                    <h3 class="feature-title">Produk Organik</h3>
                    <p class="feature-desc">Semua produk kami menggunakan bahan organik alami yang aman untuk ternak dan lingkungan. Tanpa bahan kimia berbahaya.</p>
                </div>
                
                <div class="feature-card">
                    <div class="feature-icon">
                        <i class="fas fa-shipping-fast"></i>
                    </div>
                    <h3 class="feature-title">Pengiriman Cepat</h3>
                    <p class="feature-desc">Layanan pengiriman express ke seluruh Indonesia. Produk fresh langsung dari peternakan ke rumah Anda.</p>
                </div>
                
                <div class="feature-card">
                    <div class="feature-icon">
                        <i class="fas fa-award"></i>
                    </div>
                    <h3 class="feature-title">Kualitas Terjamin</h3>
                    <p class="feature-desc">Setiap produk telah melalui quality control ketat dan bersertifikat. Garansi 100% uang kembali jika tidak puas.</p>
                </div>
                
                <div class="feature-card">
                    <div class="feature-icon">
                        <i class="fas fa-headset"></i>
                    </div>
                    <h3 class="feature-title">Support 24/7</h3>
                    <p class="feature-desc">Tim ahli peternakan kami siap membantu konsultasi dan memberikan solusi terbaik untuk kebutuhan Anda.</p>
                </div>
                
                <div class="feature-card">
                    <div class="feature-icon">
                        <i class="fas fa-coins"></i>
                    </div>
                    <h3 class="feature-title">Harga Kompetitif</h3>
                    <p class="feature-desc">Dapatkan harga terbaik langsung dari produsen. Berbagai promo menarik setiap bulannya untuk pelanggan setia.</p>
                </div>
                
                <div class="feature-card">
                    <div class="feature-icon">
                        <i class="fas fa-users"></i>
                    </div>
                    <h3 class="feature-title">Komunitas Peternak</h3>
                    <p class="feature-desc">Bergabung dengan ribuan peternak Indonesia. Sharing pengalaman, tips, dan trik sukses beternak bersama kami.</p>
                </div>
            </div>
        </div>
    </section>

    <!-- Products Section -->
    <section class="products-preview">
        <div class="container">
            <div class="section-title">
                <h2>🛒 Produk Unggulan Kami</h2>
                <p>Pilihan terbaik produk peternakan dan pertanian berkualitas tinggi untuk mendukung usaha Anda</p>
            </div>
            
            <%
                // Tampilkan notifikasi dari URL parameter
                String success = request.getParameter("success");
                String error = request.getParameter("error");
                
                if (success != null) {
            %>
                <div class="alert alert-success text-center mb-4 slide-up">
                    <i class="fas fa-check-circle"></i> <%= success %>
                </div>
            <%
                }
                
                if (error != null) {
            %>
                <div class="alert alert-danger text-center mb-4 slide-up">
                    <i class="fas fa-exclamation-triangle"></i> <%= error %>
                </div>
            <%
                }
            %>
            
            <div class="products-grid" id="productsGrid">
                <%
                    try {
                        Class.forName("com.mysql.cj.jdbc.Driver");
                        Connection conn = DriverManager.getConnection(DB_URL, DB_USER, DB_PASS);
                        String sql = "SELECT * FROM barang ORDER BY nama_barang ASC LIMIT 6";
                        Statement stmt = conn.createStatement();
                        ResultSet rs = stmt.executeQuery(sql);
                        
                        boolean hasProducts = false;
                        while (rs.next()) {
                            hasProducts = true;
                            int barangId = rs.getInt("id");
                            String namaBarang = rs.getString("nama_barang");
                            String gambar = rs.getString("gambar");
                            int quantity = rs.getInt("quantity");
                            double harga = rs.getDouble("harga");
                            
                            // Determine stock level
                            String stockClass, stockText;
                            boolean isOutOfStock = quantity == 0;
                            
                            if (isOutOfStock) {
                                stockClass = "stock-out";
                                stockText = "Habis";
                            } else if (quantity <= 10) {
                                stockClass = "stock-low";
                                stockText = "Terbatas";
                            } else if (quantity <= 50) {
                                stockClass = "stock-medium";
                                stockText = "Sedang";
                            } else {
                                stockClass = "stock-high";
                                stockText = "Banyak";
                            }
                %>
                    <div class="product-card fade-in" data-name="<%= namaBarang.toLowerCase() %>">
                        <div class="position-relative">
                            <% if (gambar != null && !gambar.trim().isEmpty()) { %>
                                <img src="<%= gambar.startsWith("http") ? gambar : "uploads/" + gambar %>" 
                                     alt="<%= namaBarang %>" class="product-image" 
                                     onerror="this.src='https://images.unsplash.com/photo-1574323347407-f5e1ad6d020b?ixlib=rb-4.0.3&auto=format&fit=crop&w=400&h=300&q=80'">
                            <% } else { %>
                                <img src="https://images.unsplash.com/photo-1574323347407-f5e1ad6d020b?ixlib=rb-4.0.3&auto=format&fit=crop&w=400&h=300&q=80" 
                                     alt="Produk Peternakan" class="product-image">
                            <% } %>
                            
                            <div class="product-overlay">
                                <div class="overlay-content">
                                    <h4 class="overlay-title"><%= namaBarang %></h4>
                                    <p class="overlay-subtitle">Produk Berkualitas Tinggi</p>
                                </div>
                            </div>
                            
                            <div class="stock-badge <%= stockClass %>">
                                <i class="fas fa-warehouse"></i> <%= stockText %>
                            </div>
                        </div>
                        
                        <div class="product-content">
                            <h5 class="product-name"><%= namaBarang %></h5>
                            <div class="product-price">Rp <%= String.format("%,d", (long)harga) %></div>
                            <p class="product-stock">
                                <i class="fas fa-boxes"></i> Stok tersedia: <strong><%= quantity %></strong> unit
                            </p>
                            
                            <% if (isAdmin) { %>
                                <!-- Admin View - Cannot add to cart -->
                                <div class="quantity-controls">
                                    <button type="button" class="qty-btn" disabled>
                                        <i class="fas fa-minus"></i>
                                    </button>
                                    <input type="number" class="qty-input" value="0" disabled>
                                    <button type="button" class="qty-btn" disabled>
                                        <i class="fas fa-plus"></i>
                                    </button>
                                </div>
                                
                                <button type="button" class="admin-notice" onclick="showAdminNotification()">
                                    <i class="fas fa-user-shield"></i> Mode Admin - Dashboard Only
                                </button>
                            <% } else if (!isOutOfStock) { %>
                                <!-- Regular User View - Can add to cart -->
                                <form action="<%= isLoggedIn ? "addToCartUser.jsp" : "addToCartGuest.jsp" %>" method="post" onsubmit="return validateStock(<%= barangId %>, <%= quantity %>)">
                                    <input type="hidden" name="barang_id" value="<%= barangId %>">
                                    <div class="quantity-controls">
                                        <button type="button" class="qty-btn" onclick="decreaseQty(<%= barangId %>)">
                                            <i class="fas fa-minus"></i>
                                        </button>
                                        <input type="number" name="quantity" id="qty_<%= barangId %>" 
                                               class="qty-input" value="1" min="1" max="<%= quantity %>">
                                        <button type="button" class="qty-btn" onclick="increaseQty(<%= barangId %>, <%= quantity %>)">
                                            <i class="fas fa-plus"></i>
                                        </button>
                                    </div>
                                    
                                    <button type="submit" class="btn-add-cart">
                                        <i class="fas fa-cart-plus"></i> Tambah ke Keranjang
                                    </button>
                                </form>
                            <% } else { %>
                                <!-- Out of Stock -->
                                <div class="quantity-controls">
                                    <button type="button" class="qty-btn" disabled>
                                        <i class="fas fa-minus"></i>
                                    </button>
                                    <input type="number" class="qty-input" value="0" disabled>
                                    <button type="button" class="qty-btn" disabled>
                                        <i class="fas fa-plus"></i>
                                    </button>
                                </div>
                                
                                <button type="button" class="btn-add-cart" disabled>
                                    <i class="fas fa-times"></i> Stok Habis
                                </button>
                            <% } %>
                        </div>
                    </div>
                <%
                        }
                        
                        if (!hasProducts) {
                %>
                    <div class="no-products col-12">
                        <i class="fas fa-tractor"></i>
                        <h4>Produk Sedang Dalam Persiapan</h4>
                        <p>Tim kami sedang mempersiapkan produk-produk terbaik untuk kebutuhan peternakan Anda. Silakan kembali lagi nanti!</p>
                    </div>
                <%
                        }
                        conn.close();
                    } catch (Exception e) {
                        out.println("<div class='alert alert-danger col-12'><i class='fas fa-exclamation-triangle'></i> Terjadi kesalahan dalam memuat produk: " + e.getMessage() + "</div>");
                    }
                %>
            </div>
            
            <div class="text-center mt-5">
                <a href="#" class="btn-cta" onclick="showAllProducts()">
                    <i class="fas fa-th-large"></i> Lihat Semua Produk
                </a>
            </div>
        </div>
    </section>

    <!-- CTA Section -->
    <section class="cta-section">
        <div class="container">
            <div class="cta-content">
                <h2 class="cta-title">🚀 Mulai Perjalanan Sukses Anda!</h2>
                <p class="cta-subtitle">Bergabung dengan ribuan peternak dan petani Indonesia yang telah mempercayai FarmStock</p>
                
                <div class="cta-buttons">
                    <% if (!isLoggedIn) { %>
                        <a href="register.html" class="btn-cta">
                            <i class="fas fa-user-plus"></i> Daftar Sekarang
                        </a>
                        <a href="login.html" class="btn-cta btn-cta-outline">
                            <i class="fas fa-sign-in-alt"></i> Masuk
                        </a>
                    <% } else if (!isAdmin) { %>
                        <a href="keranjangUser.jsp" class="btn-cta">
                            <i class="fas fa-shopping-cart"></i> Cek Keranjang
                        </a>
                        <a href="#" onclick="showAllProducts()" class="btn-cta btn-cta-outline">
                            <i class="fas fa-shopping-bag"></i> Belanja Sekarang
                        </a>
                    <% } else { %>
                        <a href="transaksi.jsp" class="btn-cta">
                            <i class="fas fa-chart-line"></i> Dashboard Admin
                        </a>
                        <a href="#" onclick="showAllProducts()" class="btn-cta btn-cta-outline">
                            <i class="fas fa-eye"></i> Lihat Produk
                        </a>
                    <% } %>
                </div>
            </div>
        </div>
    </section>

    <!-- Footer -->
    <footer style="background: var(--primary); color: white; padding: 3rem 0; text-align: center;">
        <div class="container">
            <div class="row">
                <div class="col-md-4 mb-4">
                    <h5><i class="fas fa-tractor"></i> FarmStock</h5>
                    <p>Platform terpercaya untuk kebutuhan peternakan dan pertanian modern Indonesia.</p>
                </div>
                <div class="col-md-4 mb-4">
                    <h5><i class="fas fa-phone"></i> Kontak Kami</h5>
                    <p>📞 +62 812-3456-7890<br>📧 info@farmstock.id<br>📍 Jakarta, Indonesia</p>
                </div>
                <div class="col-md-4 mb-4">
                    <h5><i class="fas fa-share-alt"></i> Ikuti Kami</h5>
                    <div style="font-size: 1.5rem; gap: 1rem; display: flex; justify-content: center;">
                        <i class="fab fa-facebook" style="cursor: pointer; transition: color 0.3s;"></i>
                        <i class="fab fa-instagram" style="cursor: pointer; transition: color 0.3s;"></i>
                        <i class="fab fa-whatsapp" style="cursor: pointer; transition: color 0.3s;"></i>
                        <i class="fab fa-youtube" style="cursor: pointer; transition: color 0.3s;"></i>
                    </div>
                </div>
            </div>
            <hr style="border-color: rgba(255,255,255,0.3); margin: 2rem 0;">
            <p>&copy; 2024 FarmStock. All rights reserved. Made with ❤️ for Indonesian Farmers.</p>
        </div>
    </footer>

    <script src="https://cdnjs.cloudflare.com/ajax/libs/bootstrap/5.0.2/js/bootstrap.bundle.min.js"></script>
    <script>
        // Quantity Controls
        function decreaseQty(id) {
            let input = document.getElementById('qty_' + id);
            let value = parseInt(input.value);
            if (value > 1) {
                input.value = value - 1;
            }
        }
        
        function increaseQty(id, maxQty) {
            let input = document.getElementById('qty_' + id);
            let value = parseInt(input.value);
            if (value < maxQty) {
                input.value = value + 1;
            }
        }

        // Stock Validation
        function validateStock(barangId, maxStock) {
            let input = document.getElementById('qty_' + barangId);
            let requestedQty = parseInt(input.value);
            
            if (maxStock <= 0) {
                showNotification('🚫 Maaf, produk ini sedang tidak tersedia!', 'error');
                return false;
            }
            
            if (requestedQty > maxStock) {
                showNotification('⚠️ Jumlah yang diminta melebihi stok tersedia! Maksimal: ' + maxStock + ' unit', 'error');
                input.value = maxStock;
                return false;
            }
            
            showNotification('✅ Produk berhasil ditambahkan ke keranjang!', 'success');
            return true;
        }

        // Admin Notification
        function showAdminNotification() {
            showNotification('👨‍💼 Sebagai admin, Anda dapat mengakses Dashboard untuk melihat data transaksi dan mengelola sistem. Fitur keranjang tidak tersedia untuk admin.', 'info');
        }

        // Show All Products
        function showAllProducts() {
            showNotification('🔍 Fitur ini akan menampilkan halaman galeri produk lengkap. Silakan implementasikan navigasi ke halaman produk.', 'info');
        }

        // Enhanced Notification System
        function showNotification(message, type) {
            // Remove existing notifications
            const existingNotifications = document.querySelectorAll('.notification');
            existingNotifications.forEach(notif => {
                if (document.body.contains(notif)) {
                    document.body.removeChild(notif);
                }
            });

            const notification = document.createElement('div');
            notification.className = `notification ${type} show`;
            
            const icons = {
                success: 'check-circle',
                error: 'exclamation-triangle',
                info: 'info-circle'
            };
            
            notification.innerHTML = `
                <div style="display: flex; align-items: center; gap: 10px;">
                    <i class="fas fa-${icons[type]}" style="font-size: 1.2rem;"></i>
                    <span>${message}</span>
                </div>
            `;
            
            document.body.appendChild(notification);
            
            setTimeout(() => {
                notification.classList.remove('show');
                setTimeout(() => {
                    if (document.body.contains(notification)) {
                        document.body.removeChild(notification);
                    }
                }, 300);
            }, 6000);
        }

        // Enhanced Search Functionality
        document.getElementById('searchInput').addEventListener('input', function() {
            const searchTerm = this.value.toLowerCase();
            const products = document.querySelectorAll('.product-card');
            let visibleCount = 0;
            
            products.forEach(product => {
                const name = product.getAttribute('data-name');
                if (name && name.includes(searchTerm)) {
                    product.style.display = 'block';
                    product.style.animation = 'fadeIn 0.5s ease-out';
                    visibleCount++;
                } else {
                    product.style.display = 'none';
                }
            });

            // Show search results info
            if (searchTerm.length > 0) {
                if (visibleCount === 0) {
                    showNotification(`🔍 Tidak ditemukan produk dengan kata kunci "${searchTerm}"`, 'info');
                } else {
                    console.log(`Ditemukan ${visibleCount} produk untuk "${searchTerm}"`);
                }
            }
        });

        // Auto-hide alerts with enhanced animation
        document.addEventListener('DOMContentLoaded', function() {
            const alerts = document.querySelectorAll('.alert');
            alerts.forEach(alert => {
                setTimeout(() => {
                    alert.style.transition = 'all 0.5s ease';
                    alert.style.opacity = '0';
                    alert.style.transform = 'translateY(-20px)';
                    setTimeout(() => {
                        if (alert.parentNode) {
                            alert.parentNode.removeChild(alert);
                        }
                    }, 500);
                }, 7000);
            });

            // Add scroll animations
            const observerOptions = {
                threshold: 0.1,
                rootMargin: '0px 0px -50px 0px'
            };

            const observer = new IntersectionObserver((entries) => {
                entries.forEach(entry => {
                    if (entry.isIntersecting) {
                        entry.target.style.animation = 'slideUp 0.8s ease-out forwards';
                    }
                });
            }, observerOptions);

            // Observe elements for scroll animation
            document.querySelectorAll('.feature-card, .product-card').forEach(el => {
                observer.observe(el);
            });
        });

        // Social media hover effects
        document.addEventListener('DOMContentLoaded', function() {
            const socialIcons = document.querySelectorAll('footer .fab-facebook, footer .fab-instagram, footer .fab-whatsapp, footer .fab-youtube');
            socialIcons.forEach(icon => {
                icon.addEventListener('mouseenter', function() {
                    this.style.color = 'var(--accent)';
                    this.style.transform = 'scale(1.2)';
                });
                icon.addEventListener('mouseleave', function() {
                    this.style.color = 'white';
                    this.style.transform = 'scale(1)';
                });
            });
        });

        // Enhanced cart count animation
        function updateCartCount() {
            const cartBadge = document.querySelector('.cart-count');
            if (cartBadge) {
                cartBadge.style.animation = 'pulse 0.5s ease-out';
                setTimeout(() => {
                    cartBadge.style.animation = 'pulse 2s infinite';
                }, 500);
            }
        }

        // Welcome message for first-time visitors
        document.addEventListener('DOMContentLoaded', function() {
            const isFirstVisit = !localStorage.getItem('farmstock_visited');
            if (isFirstVisit) {
                setTimeout(() => {
                    showNotification('🎉 Selamat datang di FarmStock! Temukan produk peternakan terbaik untuk kebutuhan Anda.', 'success');
                    localStorage.setItem('farmstock_visited', 'true');
                }, 2000);
            }
        });
    </script>
</body>
</html>