<%-- dashboarduser.jsp --%>
<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="java.sql.*" %>
<%
    // Check if user is logged in and has 'user' role
    String username = (String) session.getAttribute("username");
    String userRole = (String) session.getAttribute("role");
    String email = (String) session.getAttribute("email");
    
    if (username == null) {
        response.sendRedirect("login.html");
        return;
    }
    
    // Check if user has 'user' role (bukan admin)
    if (!"user".equals(userRole)) {
        response.sendRedirect("dashboard.jsp"); // redirect ke admin dashboard
        return;
    }
    
    // Database connection untuk mengambil statistik
    String url = "jdbc:mysql://localhost:3306/webcapstone";
    String user = "root";
    String dbpass = "";
    Connection conn = null;
    PreparedStatement pstmt = null;
    ResultSet rs = null;
    
    // Variables untuk statistik
    int totalPesanan = 0;
    int pesananSelesai = 0;
    int pesananProses = 0;
    int pesananCancelled = 0;
    int userId = 0;
%>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>E-Shop - Dashboard User</title>
    <link href="https://cdnjs.cloudflare.com/ajax/libs/bootstrap/5.0.2/css/bootstrap.min.css" rel="stylesheet">
    <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.5.0/css/all.min.css"/>
    <style>
        :root {
            --primary-color: #2f6c3b;
            --hover-color: #255b30;
            --sidebar-bg: #343a40;
            --sidebar-text: #ffffff;
        }

        body {
            font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
            background-color: #f8f9fa;
        }

        .sidebar {
            background-color: var(--sidebar-bg);
            min-height: 100vh;
            color: var(--sidebar-text);
            position: fixed;
            top: 0;
            left: 0;
            width: 256px; /* atau sesuai kebutuhan */
            overflow: hidden; /* mencegah scroll */
        }

        .sidebar-header {
            padding: 20px;
            font-size: 24px;
            font-weight: bold;
            border-bottom: 1px solid rgba(255, 255, 255, 0.1);
            text-align: center;
        }

        .sidebar-menu {
            margin-top: 20px;
        }

        .sidebar-menu a {
            display: flex;
            align-items: center;
            padding: 15px 20px;
            color: var(--sidebar-text);
            text-decoration: none;
            transition: all 0.3s ease;
        }

        .sidebar-menu a:hover, .sidebar-menu a.active {
            background-color: rgba(255, 255, 255, 0.1);
            border-left: 4px solid var(--primary-color);
            color: var(--sidebar-text);
        }

        .sidebar-menu i {
            margin-right: 10px;
            width: 20px;
            text-align: center;
        }

        .main-content {
            padding: 20px;
        }

        .welcome-card {
            background: linear-gradient(135deg, var(--primary-color), var(--hover-color));
            color: white;
            border-radius: 10px;
            padding: 30px;
            margin-bottom: 30px;
        }

        .feature-card {
            background: white;
            border-radius: 10px;
            padding: 25px;
            box-shadow: 0 2px 10px rgba(0, 0, 0, 0.1);
            transition: transform 0.3s ease;
            height: 100%;
        }

        .feature-card:hover {
            transform: translateY(-5px);
        }

        .feature-icon {
            font-size: 3rem;
            color: var(--primary-color);
            margin-bottom: 15px;
        }

        .btn-custom {
            background-color: var(--primary-color);
            border-color: var(--primary-color);
            color: white;
        }

        .btn-custom:hover {
            background-color: var(--hover-color);
            border-color: var(--hover-color);
            color: white;
        }

        .logout-link {
            color: #dc3545 !important;
            transition: color 0.3s ease;
        }

        .logout-link:hover {
            color: #bd2130 !important;
        }

        .logout-link i {
            color: #dc3545 !important;
        }

        .stats-card {
            background: white;
            border-radius: 10px;
            padding: 25px;
            box-shadow: 0 2px 10px rgba(0, 0, 0, 0.1);
            transition: all 0.3s ease;
            height: 100%;
            border-left: 4px solid;
        }

        .stats-card:hover {
            transform: translateY(-3px);
            box-shadow: 0 4px 20px rgba(0, 0, 0, 0.15);
        }

        .stats-card.total {
            border-left-color: #007bff;
        }

        .stats-card.success {
            border-left-color: #28a745;
        }

        .stats-card.warning {
            border-left-color: #ffc107;
        }

        .stats-card.danger {
            border-left-color: #dc3545;
        }

        .stats-number {
            font-size: 2.5rem;
            font-weight: bold;
            margin-bottom: 10px;
        }

        .stats-label {
            color: #6c757d;
            font-size: 0.9rem;
            margin-bottom: 0;
        }

        .stats-icon {
            position: absolute;
            top: 20px;
            right: 20px;
            font-size: 2rem;
            opacity: 0.3;
        }

        .stats-card {
            position: relative;
        }

        .quick-action {
            background: #f8f9fa;
            border: 1px solid #dee2e6;
            border-radius: 8px;
            padding: 15px;
            text-align: center;
            transition: all 0.3s ease;
            text-decoration: none;
            color: #333;
            display: block;
        }

        .quick-action:hover {
            background: #e9ecef;
            border-color: var(--primary-color);
            color: var(--primary-color);
            text-decoration: none;
            transform: translateY(-2px);
        }

        .recent-activity {
            background: white;
            border-radius: 10px;
            padding: 20px;
            box-shadow: 0 2px 10px rgba(0, 0, 0, 0.1);
            margin-top: 20px;
        }
    </style>
</head>
<body>
    <%
    try {
        Class.forName("com.mysql.cj.jdbc.Driver");
        conn = DriverManager.getConnection(url, user, dbpass);
        
        // Get user ID
        String getUserSql = "SELECT id FROM user WHERE email = ?";
        pstmt = conn.prepareStatement(getUserSql);
        pstmt.setString(1, email);
        rs = pstmt.executeQuery();
        
        if (rs.next()) {
            userId = rs.getInt("id");
        }
        rs.close();
        pstmt.close();
        
        // Get statistics
        if (userId > 0) {
            // Total pesanan
            String totalSql = "SELECT COUNT(*) as total FROM transaksi WHERE user_id = ?";
            pstmt = conn.prepareStatement(totalSql);
            pstmt.setInt(1, userId);
            rs = pstmt.executeQuery();
            if (rs.next()) {
                totalPesanan = rs.getInt("total");
            }
            rs.close();
            pstmt.close();
            
            // Pesanan selesai (delivered)
            String selesaiSql = "SELECT COUNT(*) as selesai FROM transaksi WHERE user_id = ? AND status_pesanan = 'delivered'";
            pstmt = conn.prepareStatement(selesaiSql);
            pstmt.setInt(1, userId);
            rs = pstmt.executeQuery();
            if (rs.next()) {
                pesananSelesai = rs.getInt("selesai");
            }
            rs.close();
            pstmt.close();
            
            // Pesanan dalam proses (pending, processing, shipped)
            String prosesSql = "SELECT COUNT(*) as proses FROM transaksi WHERE user_id = ? AND status_pesanan IN ('pending', 'processing', 'shipped')";
            pstmt = conn.prepareStatement(prosesSql);
            pstmt.setInt(1, userId);
            rs = pstmt.executeQuery();
            if (rs.next()) {
                pesananProses = rs.getInt("proses");
            }
            rs.close();
            pstmt.close();
            
            // Pesanan dibatalkan
            String cancelledSql = "SELECT COUNT(*) as cancelled FROM transaksi WHERE user_id = ? AND status_pesanan = 'cancelled'";
            pstmt = conn.prepareStatement(cancelledSql);
            pstmt.setInt(1, userId);
            rs = pstmt.executeQuery();
            if (rs.next()) {
                pesananCancelled = rs.getInt("cancelled");
            }
            rs.close();
            pstmt.close();
        }
        
    } catch(Exception e) {
        out.println("<!-- Error loading stats: " + e.getMessage() + " -->");
    } finally {
        if (rs != null) try { rs.close(); } catch (SQLException e) { e.printStackTrace(); }
        if (pstmt != null) try { pstmt.close(); } catch (SQLException e) { e.printStackTrace(); }
        if (conn != null) try { conn.close(); } catch (SQLException e) { e.printStackTrace(); }
    }
    %>

    <div class="container-fluid">
        <div class="row">
            <!-- Sidebar -->
            <div class="col-md-3 col-lg-2 px-0">
                <div class="sidebar">
                    <div class="sidebar-header">
                        <i class="fas fa-shopping-cart"></i> E-Shop
                    </div>
                    <div class="sidebar-menu">
                        <a href="dashboarduser.jsp" class="active">
                            <i class="fas fa-home"></i> Dashboard
                        </a>
                        <a href="daftarBarang.jsp">
                            <i class="fas fa-boxes"></i> Daftar Barang
                        </a>
                        <a href="keranjang.jsp">
                            <i class="fas fa-shopping-basket"></i> Keranjang
                        </a>
                        <a href="riwayatTransaksi.jsp">
                            <i class="fas fa-history"></i> Riwayat Transaksi
                        </a>
                        <a href="lacakPesanan.jsp">
                            <i class="fas fa-truck"></i> Lacak Pesanan
                        </a>
                        <a href="userProfile.jsp">
                            <i class="fas fa-user-cog"></i> Profile Settings
                        </a>
                        <a href="logout.jsp" class="logout-link" onclick="return confirm('Yakin ingin logout?')">
                            <i class="fas fa-sign-out-alt"></i> Logout
                        </a>
                    </div>
                </div>
            </div>

            <!-- Main Content -->
            <div class="col-md-9 col-lg-10">
                <div class="main-content">
                    <!-- Welcome Section -->
                    <div class="welcome-card">
                        <h2><i class="fas fa-user-circle"></i> Selamat Datang, <%= username %>!</h2>
                        <p class="mb-0">Nikmati pengalaman berbelanja online yang mudah dan menyenangkan di E-Shop.</p>
                    </div>

                    <!-- Quick Stats -->
                    <div class="row mb-4">
                        <div class="col-12">
                            <h4 class="mb-3"><i class="fas fa-chart-bar"></i> Statistik Pesanan Anda</h4>
                        </div>
                        <div class="col-md-3 col-sm-6 mb-3">
                            <div class="stats-card total">
                                <i class="fas fa-shopping-bag stats-icon text-primary"></i>
                                <div class="stats-number text-primary"><%= totalPesanan %></div>
                                <p class="stats-label">Total Pesanan</p>
                            </div>
                        </div>
                        <div class="col-md-3 col-sm-6 mb-3">
                            <div class="stats-card success">
                                <i class="fas fa-check-circle stats-icon text-success"></i>
                                <div class="stats-number text-success"><%= pesananSelesai %></div>
                                <p class="stats-label">Pesanan Selesai</p>
                            </div>
                        </div>
                        <div class="col-md-3 col-sm-6 mb-3">
                            <div class="stats-card warning">
                                <i class="fas fa-clock stats-icon text-warning"></i>
                                <div class="stats-number text-warning"><%= pesananProses %></div>
                                <p class="stats-label">Dalam Proses</p>
                            </div>
                        </div>
                        <div class="col-md-3 col-sm-6 mb-3">
                            <div class="stats-card danger">
                                <i class="fas fa-times-circle stats-icon text-danger"></i>
                                <div class="stats-number text-danger"><%= pesananCancelled %></div>
                                <p class="stats-label">Dibatalkan</p>
                            </div>
                        </div>
                    </div>

                    <!-- Quick Actions -->
                    <div class="row mb-4">
                        <div class="col-12">
                            <h4 class="mb-3"><i class="fas fa-bolt"></i> Aksi Cepat</h4>
                        </div>
                        <div class="col-md-3 col-sm-6 mb-3">
                            <a href="daftarBarang.jsp" class="quick-action">
                                <i class="fas fa-shopping-bag fa-2x mb-2 text-primary"></i>
                                <h6>Mulai Belanja</h6>
                                <small>Lihat produk terbaru</small>
                            </a>
                        </div>
                        <div class="col-md-3 col-sm-6 mb-3">
                            <a href="keranjang.jsp" class="quick-action">
                                <i class="fas fa-shopping-cart fa-2x mb-2 text-warning"></i>
                                <h6>Lihat Keranjang</h6>
                                <small>Checkout pesanan</small>
                            </a>
                        </div>
                        <div class="col-md-3 col-sm-6 mb-3">
                            <a href="riwayatTransaksi.jsp" class="quick-action">
                                <i class="fas fa-history fa-2x mb-2 text-info"></i>
                                <h6>Riwayat Transaksi</h6>
                                <small>Lihat semua pesanan</small>
                            </a>
                        </div>
                        <div class="col-md-3 col-sm-6 mb-3">
                            <a href="lacakPesanan.jsp" class="quick-action">
                                <i class="fas fa-truck fa-2x mb-2 text-success"></i>
                                <h6>Lacak Pesanan</h6>
                                <small>Pantau pengiriman</small>
                            </a>
                        </div>
                    </div>

                    <!-- Recent Activity -->
                    <% if (totalPesanan > 0) { %>
                    <div class="recent-activity">
                        <h5><i class="fas fa-clock"></i> Aktivitas Terbaru</h5>
                        <p class="text-muted">
                            <% if (pesananProses > 0) { %>
                                Anda memiliki <%= pesananProses %> pesanan yang sedang diproses. 
                                <a href="lacakPesanan.jsp" class="text-decoration-none">Lacak pesanan →</a>
                            <% } else if (pesananSelesai > 0) { %>
                                Terima kasih! Anda telah menyelesaikan <%= pesananSelesai %> pesanan. 
                                <a href="daftarBarang.jsp" class="text-decoration-none">Belanja lagi →</a>
                            <% } else { %>
                                Mulai berbelanja untuk mendapatkan produk terbaik dari kami!
                                <a href="daftarBarang.jsp" class="text-decoration-none">Mulai belanja →</a>
                            <% } %>
                        </p>
                    </div>
                    <% } %>
                </div>
            </div>
        </div>
    </div>

    <script src="https://cdnjs.cloudflare.com/ajax/libs/bootstrap/5.0.2/js/bootstrap.bundle.min.js"></script>
    <script>
        // Auto refresh stats setiap 30 detik (opsional)
        function refreshStats() {
            // Bisa ditambahkan AJAX call untuk refresh statistics tanpa reload page
            console.log('Stats refreshed at:', new Date().toLocaleTimeString());
        }
        
        // Refresh stats setiap 30 detik
        // setInterval(refreshStats, 30000);
        
        // Animation untuk angka statistik
        document.addEventListener('DOMContentLoaded', function() {
            const statsNumbers = document.querySelectorAll('.stats-number');
            
            statsNumbers.forEach(number => {
                const finalValue = parseInt(number.textContent);
                if (finalValue > 0) {
                    let currentValue = 0;
                    const increment = Math.ceil(finalValue / 20);
                    const timer = setInterval(() => {
                        currentValue += increment;
                        if (currentValue >= finalValue) {
                            currentValue = finalValue;
                            clearInterval(timer);
                        }
                        number.textContent = currentValue;
                    }, 50);
                }
            });
        });
    </script>
</body>
</html>