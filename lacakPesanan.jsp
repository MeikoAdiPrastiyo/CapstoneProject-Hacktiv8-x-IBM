<%-- lacakPesanan.jsp --%>
<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="java.sql.*" %>
<%@ page import="java.text.SimpleDateFormat" %>
<%@ page import="java.util.*" %>
<%
    // Check if user is logged in
    String username = (String) session.getAttribute("username");
    String userRole = (String) session.getAttribute("role");
    String email = (String) session.getAttribute("email");
    if (username == null) {
        response.sendRedirect("login.html");
        return;
    }
    
    // Database connection
    String url = "jdbc:mysql://localhost:3306/webcapstone";
    String user = "root";
    String dbpass = "";
    Connection conn = null;
    PreparedStatement pstmt = null;
    ResultSet rs = null;
    
    // Get user ID
    int userId = 0;
%>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>E-Shop - Lacak Pesanan</title>
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
            height: 100vh;
            overflow: hidden;
        }

        .container-fluid {
            height: 100vh;
        }

        .sidebar {
            background-color: var(--sidebar-bg);
            height: 100vh;
            color: var(--sidebar-text);
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
            height: 100vh;
            overflow-y: auto;
            padding: 20px;
        }

        .page-header {
            background: linear-gradient(135deg, var(--primary-color), var(--hover-color));
            color: white;
            border-radius: 10px;
            padding: 20px;
            margin-bottom: 20px;
        }

        .tracking-card {
            background: white;
            border-radius: 10px;
            box-shadow: 0 2px 10px rgba(0, 0, 0, 0.1);
            margin-bottom: 20px;
            overflow: hidden;
        }

        .tracking-header {
            background: linear-gradient(135deg, #f8f9fa, #e9ecef);
            padding: 20px;
            border-bottom: 1px solid #dee2e6;
        }

        .order-info {
            display: flex;
            justify-content: space-between;
            align-items: center;
            margin-bottom: 15px;
        }

        .order-id {
            font-weight: 600;
            color: var(--primary-color);
            font-size: 1.2rem;
        }

        .order-date {
            color: #6c757d;
            font-size: 0.9rem;
        }

        .order-total {
            font-weight: 600;
            color: var(--primary-color);
            font-size: 1.1rem;
        }

        .status-timeline {
            padding: 30px 20px;
            position: relative;
        }

        .timeline {
            position: relative;
            padding-left: 40px;
        }

        .timeline::before {
            content: '';
            position: absolute;
            left: 20px;
            top: 0;
            bottom: 0;
            width: 2px;
            background: #dee2e6;
        }

        .timeline-item {
            position: relative;
            margin-bottom: 30px;
            padding-bottom: 20px;
        }

        .timeline-item:last-child {
            margin-bottom: 0;
        }

        .timeline-marker {
            position: absolute;
            left: -28px;
            top: 5px;
            width: 16px;
            height: 16px;
            border-radius: 50%;
            border: 3px solid #dee2e6;
            background: white;
            z-index: 1;
        }

        .timeline-marker.completed {
            border-color: #28a745;
            background: #28a745;
        }

        .timeline-marker.current {
            border-color: var(--primary-color);
            background: var(--primary-color);
            width: 20px;
            height: 20px;
            left: -30px;
            top: 3px;
            box-shadow: 0 0 0 4px rgba(47, 108, 59, 0.2);
        }

        .timeline-content {
            background: #f8f9fa;
            border-radius: 8px;
            padding: 15px;
            border-left: 4px solid #dee2e6;
        }

        .timeline-content.completed {
            border-left-color: #28a745;
            background: #d4edda;
        }

        .timeline-content.current {
            border-left-color: var(--primary-color);
            background: #e8f5e8;
        }

        .timeline-title {
            font-weight: 600;
            color: #333;
            margin-bottom: 5px;
        }

        .timeline-desc {
            color: #6c757d;
            font-size: 0.9rem;
            margin-bottom: 8px;
        }

        .timeline-time {
            color: #6c757d;
            font-size: 0.8rem;
            font-style: italic;
        }

        .order-items {
            background: #f8f9fa;
            padding: 20px;
            margin-top: 20px;
        }

        .order-items h6 {
            color: #333;
            margin-bottom: 15px;
            font-weight: 600;
        }

        .item-row {
            display: flex;
            justify-content: space-between;
            align-items: center;
            padding: 10px 0;
            border-bottom: 1px solid #dee2e6;
        }

        .item-row:last-child {
            border-bottom: none;
        }

        .item-name {
            font-weight: 500;
            color: #333;
        }

        .item-qty {
            color: #6c757d;
            font-size: 0.9rem;
        }

        .item-price {
            font-weight: 600;
            color: var(--primary-color);
        }

        .payment-info {
            background: #fff3cd;
            border: 1px solid #ffeaa7;
            border-radius: 8px;
            padding: 15px;
            margin-top: 15px;
        }

        .payment-info.paid {
            background: #d4edda;
            border-color: #c3e6cb;
        }

        .payment-info.failed {
            background: #f8d7da;
            border-color: #f1aeb5;
        }

        .shipping-address {
            background: #e7f3ff;
            border: 1px solid #b8daff;
            border-radius: 8px;
            padding: 15px;
            margin-top: 15px;
        }

        .empty-state {
            text-align: center;
            padding: 60px 20px;
            background: white;
            border-radius: 10px;
            box-shadow: 0 2px 10px rgba(0, 0, 0, 0.1);
        }

        .empty-state i {
            font-size: 4rem;
            color: #dee2e6;
            margin-bottom: 20px;
        }

        .empty-state h4 {
            color: #6c757d;
            margin-bottom: 10px;
        }

        .empty-state p {
            color: #6c757d;
            margin-bottom: 20px;
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

        .search-section {
            background: white;
            border-radius: 10px;
            padding: 20px;
            margin-bottom: 20px;
            box-shadow: 0 2px 10px rgba(0, 0, 0, 0.1);
        }

        .btn-track {
            background-color: var(--primary-color);
            border-color: var(--primary-color);
            color: white;
        }

        .btn-track:hover {
            background-color: var(--hover-color);
            border-color: var(--hover-color);
            color: white;
        }

        .status-badge {
            padding: 6px 12px;
            border-radius: 20px;
            font-size: 0.8rem;
            font-weight: 600;
            text-transform: uppercase;
        }

        .status-pending {
            background-color: #fff3cd;
            color: #856404;
        }

        .status-processing {
            background-color: #cce5ff;
            color: #004085;
        }

        .status-shipped {
            background-color: #d4edda;
            color: #155724;
        }

        .status-delivered {
            background-color: #d1ecf1;
            color: #0c5460;
        }

        .status-cancelled {
            background-color: #f8d7da;
            color: #721c24;
        }

        @media (max-width: 768px) {
            .order-info {
                flex-direction: column;
                align-items: flex-start;
                gap: 10px;
            }

            .item-row {
                flex-direction: column;
                align-items: flex-start;
                gap: 5px;
            }

            .timeline {
                padding-left: 30px;
            }

            .timeline::before {
                left: 15px;
            }

            .timeline-marker {
                left: -23px;
            }

            .timeline-marker.current {
                left: -25px;
            }
        }
    </style>
</head>
<body>
    <div class="container-fluid">
        <div class="row h-100">
            <!-- Sidebar -->
            <div class="col-md-3 col-lg-2 px-0">
                <div class="sidebar">
                    <div class="sidebar-header">
                        <i class="fas fa-shopping-cart"></i> E-Shop
                    </div>
                    <div class="sidebar-menu">
                        <a href="dashboarduser.jsp">
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
                        <a href="lacakPesanan.jsp" class="active">
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
                    <!-- Page Header -->
                    <div class="page-header">
                        <h2><i class="fas fa-truck"></i> Lacak Pesanan</h2>
                        <p class="mb-0">Pantau status pengiriman pesanan Anda, <%= username %>!</p>
                    </div>

                    <!-- Search Section -->
                    <div class="search-section">
                        <h5><i class="fas fa-search"></i> Cari Pesanan</h5>
                        <div class="row">
                            <div class="col-md-8">
                                <input type="number" class="form-control" id="searchOrderId" placeholder="Masukkan ID Transaksi (contoh: 123)">
                            </div>
                            <div class="col-md-4">
                                <button type="button" class="btn btn-track w-100" onclick="searchOrder()">
                                    <i class="fas fa-search"></i> Lacak Pesanan
                                </button>
                            </div>
                        </div>
                    </div>

                    <!-- Orders List -->
                    <div id="ordersContainer">
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
                            
                            // Get active orders (not delivered and not cancelled)
                            String getOrdersSql = "SELECT * FROM transaksi WHERE user_id = ? AND status_pesanan NOT IN ('delivered', 'cancelled') ORDER BY created_at DESC";
                            pstmt = conn.prepareStatement(getOrdersSql);
                            pstmt.setInt(1, userId);
                            rs = pstmt.executeQuery();
                            
                            SimpleDateFormat sdfDisplay = new SimpleDateFormat("dd MMM yyyy, HH:mm");
                            boolean hasActiveOrders = false;
                            
                            while (rs.next()) {
                                hasActiveOrders = true;
                                int transaksiId = rs.getInt("id");
                                double totalHarga = rs.getDouble("total_harga");
                                String metodePembayaran = rs.getString("metode_pembayaran");
                                String statusPembayaran = rs.getString("status_pembayaran");
                                String statusPesanan = rs.getString("status_pesanan");
                                String alamatPengiriman = rs.getString("alamat_pengiriman");
                                Timestamp createdAt = rs.getTimestamp("created_at");
                                
                                String displayDate = sdfDisplay.format(createdAt);
                                
                                // Get payment method display name
                                String paymentMethodDisplay = "";
                                switch(metodePembayaran) {
                                    case "transfer_bank":
                                        paymentMethodDisplay = "Transfer Bank";
                                        break;
                                    case "e_wallet":
                                        paymentMethodDisplay = "E-Wallet";
                                        break;
                                    case "cod":
                                        paymentMethodDisplay = "COD";
                                        break;
                                    default:
                                        paymentMethodDisplay = metodePembayaran;
                                }
                        %>
                        
                        <div class="tracking-card" id="order-<%= transaksiId %>">
                            <div class="tracking-header">
                                <div class="order-info">
                                    <div>
                                        <div class="order-id">
                                            <i class="fas fa-receipt"></i> Pesanan #<%= transaksiId %>
                                        </div>
                                        <div class="order-date">
                                            <i class="fas fa-calendar"></i> Dipesan pada <%= displayDate %>
                                        </div>
                                    </div>
                                    <div class="text-end">
                                        <div class="order-total">
                                            Rp <%= String.format("%,.0f", totalHarga) %>
                                        </div>
                                        <span class="status-badge status-<%= statusPesanan %>">
                                            <%= statusPesanan.toUpperCase() %>
                                        </span>
                                    </div>
                                </div>
                                
                                <!-- Payment Info -->
                                <div class="payment-info <%= statusPembayaran %>">
                                    <strong><i class="fas fa-credit-card"></i> Status Pembayaran:</strong>
                                    <%= statusPembayaran.toUpperCase() %> via <%= paymentMethodDisplay %>
                                    <% if (statusPembayaran.equals("pending")) { %>
                                        <br><small>Silakan selesaikan pembayaran Anda untuk memproses pesanan.</small>
                                    <% } %>
                                </div>
                            </div>
                            
                            <div class="status-timeline">
                                <div class="timeline">
                                    <!-- Pesanan Dibuat -->
                                    <div class="timeline-item">
                                        <div class="timeline-marker completed"></div>
                                        <div class="timeline-content completed">
                                            <div class="timeline-title">
                                                <i class="fas fa-check-circle"></i> Pesanan Dibuat
                                            </div>
                                            <div class="timeline-desc">
                                                Pesanan Anda telah berhasil dibuat dan menunggu konfirmasi pembayaran.
                                            </div>
                                            <div class="timeline-time">
                                                <%= displayDate %>
                                            </div>
                                        </div>
                                    </div>
                                    
                                    <!-- Pending Payment -->
                                    <% if (statusPesanan.equals("pending")) { %>
                                    <div class="timeline-item">
                                        <div class="timeline-marker current"></div>
                                        <div class="timeline-content current">
                                            <div class="timeline-title">
                                                <i class="fas fa-clock"></i> Menunggu Pembayaran
                                            </div>
                                            <div class="timeline-desc">
                                                Pesanan sedang menunggu pembayaran. Silakan lakukan pembayaran sesuai metode yang dipilih.
                                            </div>
                                            <div class="timeline-time">
                                                Status saat ini
                                            </div>
                                        </div>
                                    </div>
                                    <% } %>
                                    
                                    <!-- Processing -->
                                    <div class="timeline-item">
                                        <div class="timeline-marker <%= statusPesanan.equals("processing") || statusPesanan.equals("shipped") ? "current" : "" %>"></div>
                                        <div class="timeline-content <%= statusPesanan.equals("processing") || statusPesanan.equals("shipped") ? "current" : "" %>">
                                            <div class="timeline-title">
                                                <i class="fas fa-cog"></i> Sedang Diproses
                                            </div>
                                            <div class="timeline-desc">
                                                Pembayaran telah dikonfirmasi. Pesanan sedang disiapkan oleh penjual.
                                            </div>
                                            <% if (statusPesanan.equals("processing")) { %>
                                            <div class="timeline-time">
                                                Status saat ini - Sedang disiapkan
                                            </div>
                                            <% } %>
                                        </div>
                                    </div>
                                    
                                    <!-- Shipped -->
                                    <div class="timeline-item">
                                        <div class="timeline-marker <%= statusPesanan.equals("shipped") ? "current" : "" %>"></div>
                                        <div class="timeline-content <%= statusPesanan.equals("shipped") ? "current" : "" %>">
                                            <div class="timeline-title">
                                                <i class="fas fa-truck"></i> Sedang Dikirim
                                            </div>
                                            <div class="timeline-desc">
                                                Pesanan Anda sedang dalam perjalanan menuju alamat tujuan.
                                            </div>
                                            <% if (statusPesanan.equals("shipped")) { %>
                                            <div class="timeline-time">
                                                Status saat ini - Dalam pengiriman
                                            </div>
                                            <% } %>
                                        </div>
                                    </div>
                                    
                                    <!-- Delivered -->
                                    <div class="timeline-item">
                                        <div class="timeline-marker"></div>
                                        <div class="timeline-content">
                                            <div class="timeline-title">
                                                <i class="fas fa-home"></i> Pesanan Tiba
                                            </div>
                                            <div class="timeline-desc">
                                                Pesanan akan sampai di alamat tujuan dan siap diterima.
                                            </div>
                                        </div>
                                    </div>
                                </div>
                            </div>
                            
                            <!-- Shipping Address -->
                            <div class="shipping-address">
                                <strong><i class="fas fa-map-marker-alt"></i> Alamat Pengiriman:</strong><br>
                                <%= alamatPengiriman %>
                            </div>
                            
                            <!-- Order Items -->
                            <div class="order-items">
                                <h6><i class="fas fa-box"></i> Item Pesanan</h6>
                                <%
                                    // Get order items
                                    PreparedStatement pstmtItems = null;
                                    ResultSet rsItems = null;
                                    try {
                                        String getItemsSql = "SELECT * FROM detail_transaksi WHERE transaksi_id = ?";
                                        pstmtItems = conn.prepareStatement(getItemsSql);
                                        pstmtItems.setInt(1, transaksiId);
                                        rsItems = pstmtItems.executeQuery();
                                        
                                        while (rsItems.next()) {
                                            String namaBarang = rsItems.getString("nama_barang");
                                            int quantity = rsItems.getInt("quantity");
                                            double harga = rsItems.getDouble("harga");
                                            double subtotal = rsItems.getDouble("subtotal");
                                %>
                                <div class="item-row">
                                    <div>
                                        <div class="item-name"><%= namaBarang %></div>
                                        <div class="item-qty">Qty: <%= quantity %> × Rp <%= String.format("%,.0f", harga) %></div>
                                    </div>
                                    <div class="item-price">
                                        Rp <%= String.format("%,.0f", subtotal) %>
                                    </div>
                                </div>
                                <%
                                        }
                                    } finally {
                                        if (rsItems != null) try { rsItems.close(); } catch (SQLException e) { e.printStackTrace(); }
                                        if (pstmtItems != null) try { pstmtItems.close(); } catch (SQLException e) { e.printStackTrace(); }
                                    }
                                %>
                            </div>
                        </div>
                        
                        <%
                            }
                            
                            if (!hasActiveOrders) {
                        %>
                        
                        <div class="empty-state">
                            <i class="fas fa-truck"></i>
                            <h4>Tidak Ada Pesanan Aktif</h4>
                            <p>Anda tidak memiliki pesanan yang sedang diproses saat ini.</p>
                            <a href="daftarBarang.jsp" class="btn btn-track">
                                <i class="fas fa-shopping-bag"></i> Mulai Belanja
                            </a>
                        </div>
                        
                        <%
                            }
                            
                        } catch(Exception e) {
                            out.println("<div class='alert alert-danger'><i class='fas fa-exclamation-triangle'></i> Error: " + e.getMessage() + "</div>");
                        } finally {
                            if (rs != null) try { rs.close(); } catch (SQLException e) { e.printStackTrace(); }
                            if (pstmt != null) try { pstmt.close(); } catch (SQLException e) { e.printStackTrace(); }
                            if (conn != null) try { conn.close(); } catch (SQLException e) { e.printStackTrace(); }
                        }
                        %>
                    </div>
                </div>
            </div>
        </div>
    </div>

    <script src="https://cdnjs.cloudflare.com/ajax/libs/bootstrap/5.0.2/js/bootstrap.bundle.min.js"></script>
    <script>
        // Search specific order
        function searchOrder() {
            const orderId = document.getElementById('searchOrderId').value.trim();
            
            if (!orderId) {
                alert('Silakan masukkan ID transaksi.');
                return;
            }
            
            // Hide all orders first
            const allOrders = document.querySelectorAll('.tracking-card');
            const emptyState = document.querySelector('.empty-state');
            let found = false;
            
            allOrders.forEach(order => {
                const orderIdText = order.id.replace('order-', '');
                if (orderIdText === orderId) {
                    order.style.display = 'block';
                    found = true;
                } else {
                    order.style.display = 'none';
                }
            });
            
            if (emptyState) {
                emptyState.style.display = found ? 'none' : 'block';
            }
            
            if (!found && !emptyState) {
                // Show message if order not found
                showMessage('Pesanan dengan ID #' + orderId + ' tidak ditemukan atau sudah selesai.', false);
            }
        }
        
        // Show all orders
        function showAllOrders() {
            const allOrders = document.querySelectorAll('.tracking-card');
            const emptyState = document.querySelector('.empty-state');
            
            allOrders.forEach(order => {
                order.style.display = 'block';
            });
            
            if (emptyState && allOrders.length > 0) {
                emptyState.style.display = 'none';
            }
            
            document.getElementById('searchOrderId').value = '';
        }
        
        // Show message function
        function showMessage(message, isSuccess) {
            // Create message element if doesn't exist
            let messageDiv = document.getElementById('message');
            if (!messageDiv) {
                messageDiv = document.createElement('div');
                messageDiv.id = 'message';
                messageDiv.className = 'alert position-fixed';
                messageDiv.style.cssText = 'top: 20px; right: 20px; z-index: 1050; min-width: 300px; display: none;';
                document.body.appendChild(messageDiv);
            }
            
            messageDiv.innerHTML = '<i class="fas fa-' + (isSuccess ? 'check-circle' : 'exclamation-triangle') + '"></i> ' + message;
            messageDiv.className = 'alert position-fixed ' + (isSuccess ? 'alert-success' : 'alert-warning');
            messageDiv.style.display = 'block';
            
            setTimeout(function() {
                messageDiv.style.display = 'none';
            }, 4000);
        }
        
        // Auto refresh page every 5 minutes for status updates
        // setInterval(function() {
        //     location.reload();
        // }, 300000);
        
        // Enter key support for search
        document.getElementById('searchOrderId').addEventListener('keypress', function(e) {
            if (e.key === 'Enter') {
                searchOrder();
            }
        });
        
        // Add button to show all orders if search is used
        document.getElementById('searchOrderId').addEventListener('input', function(e) {
            if (e.target.value === '') {
                showAllOrders();
            }
        });
    </script>
</body>
</html>