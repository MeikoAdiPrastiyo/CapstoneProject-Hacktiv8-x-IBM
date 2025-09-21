<%-- keranjang.jsp --%>
<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="java.sql.*" %>
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
    double totalHarga = 0;
    int totalItems = 0;
%>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>E-Shop - Keranjang Belanja</title>
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

        .cart-summary-section {
            background: white;
            border-radius: 10px;
            padding: 20px;
            box-shadow: 0 2px 10px rgba(0, 0, 0, 0.1);
            margin-bottom: 20px;
        }

        .cart-items-section {
            background: white;
            border-radius: 10px;
            padding: 20px;
            box-shadow: 0 2px 10px rgba(0, 0, 0, 0.1);
            margin-bottom: 20px;
        }

        .checkout-section {
            background: white;
            border-radius: 10px;
            padding: 20px;
            box-shadow: 0 2px 10px rgba(0, 0, 0, 0.1);
        }

        .summary-card {
            background: #f8f9fa;
            border-radius: 8px;
            padding: 15px;
            text-align: center;
            margin-bottom: 10px;
        }

        .summary-number {
            font-size: 1.5rem;
            font-weight: 600;
            color: var(--primary-color);
        }

        .summary-label {
            font-size: 0.9rem;
            color: #6c757d;
        }

        .cart-item {
            border: 1px solid #e9ecef;
            border-radius: 8px;
            padding: 15px;
            margin-bottom: 15px;
            transition: all 0.3s ease;
        }

        .cart-item:hover {
            transform: translateY(-2px);
            box-shadow: 0 4px 15px rgba(0, 0, 0, 0.1);
        }

        .item-image {
            width: 80px;
            height: 80px;
            object-fit: cover;
            border-radius: 6px;
        }

        .item-name {
            font-weight: 600;
            color: #333;
            margin-bottom: 5px;
        }

        .item-price {
            color: #6c757d;
            font-size: 0.9rem;
        }

        .item-total {
            font-weight: 600;
            color: var(--primary-color);
            font-size: 1.1rem;
        }

        .quantity-controls {
            display: flex;
            align-items: center;
            gap: 8px;
        }

        .quantity-btn {
            width: 35px;
            height: 35px;
            border: 1px solid #dee2e6;
            background-color: white;
            cursor: pointer;
            border-radius: 6px;
            display: flex;
            align-items: center;
            justify-content: center;
            font-weight: 600;
            transition: all 0.3s ease;
        }

        .quantity-btn:hover:not(:disabled) {
            background-color: var(--primary-color);
            color: white;
            border-color: var(--primary-color);
        }

        .quantity-btn:disabled {
            background-color: #f8f9fa;
            color: #ccc;
            cursor: not-allowed;
        }

        .quantity-input {
            width: 60px;
            text-align: center;
            border: 1px solid #dee2e6;
            border-radius: 6px;
            padding: 8px;
            font-size: 14px;
            font-weight: 600;
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

        .btn-danger-custom {
            background-color: #dc3545;
            border-color: #dc3545;
            color: white;
        }

        .btn-danger-custom:hover {
            background-color: #c82333;
            border-color: #bd2130;
            color: white;
        }

        .btn-secondary-custom {
            background-color: #6c757d;
            border-color: #6c757d;
            color: white;
        }

        .btn-secondary-custom:hover {
            background-color: #5a6268;
            border-color: #545b62;
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

        .message {
            position: fixed;
            top: 20px;
            right: 20px;
            z-index: 1050;
            min-width: 300px;
            display: none;
        }

        .empty-cart {
            text-align: center;
            padding: 60px 20px;
            color: #6c757d;
        }

        .empty-cart i {
            font-size: 4rem;
            color: #dee2e6;
            margin-bottom: 20px;
        }

        .checkout-total {
            font-size: 1.25rem;
            font-weight: 600;
            color: var(--primary-color);
        }

        @media (max-width: 768px) {
            .quantity-controls {
                justify-content: center;
                margin: 10px 0;
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
                        <a href="keranjang.jsp" class="active">
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
                    <!-- Page Header -->
                    <div class="page-header">
                        <h2><i class="fas fa-shopping-basket"></i> Keranjang Belanja</h2>
                        <p class="mb-0">Kelola barang yang akan Anda beli, <%= username %>!</p>
                    </div>

                    <!-- Success/Error Message -->
                    <div id="message" class="alert message"></div>

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
                          
                          // Get cart items with product details
                          String sql = "SELECT k.id as keranjang_id, k.barang_id, k.quantity, " +
                                      "b.nama_barang, b.gambar, b.harga, b.quantity as stok " +
                                      "FROM keranjang k " +
                                      "JOIN barang b ON k.barang_id = b.id " +
                                      "WHERE k.user_id = ? " +
                                      "ORDER BY k.created_at DESC";
                          
                          pstmt = conn.prepareStatement(sql);
                          pstmt.setInt(1, userId);
                          rs = pstmt.executeQuery();
                          
                          // Check if cart has items
                          boolean hasItems = false;
                          StringBuilder cartItemsHtml = new StringBuilder();
                          
                          while(rs.next()) {
                              hasItems = true;
                              int keranjangId = rs.getInt("keranjang_id");
                              int barangId = rs.getInt("barang_id");
                              String namaBarang = rs.getString("nama_barang");
                              String gambar = rs.getString("gambar");
                              double harga = rs.getDouble("harga");
                              int quantity = rs.getInt("quantity");
                              int stok = rs.getInt("stok");
                              double subtotal = harga * quantity;
                              
                              totalHarga += subtotal;
                              totalItems += quantity;
                              
                              cartItemsHtml.append("<div class='cart-item'>");
                              cartItemsHtml.append("<div class='row align-items-center'>");
                              
                              // Product Image
                              cartItemsHtml.append("<div class='col-md-2 col-3 mb-2 mb-md-0'>");
                              if (gambar != null && !gambar.trim().isEmpty()) {
                                  cartItemsHtml.append("<img src='uploads/").append(gambar).append("' alt='").append(namaBarang).append("' class='item-image img-fluid' onerror=\"this.src='https://via.placeholder.com/80x80?text=No+Image'\">");
                              } else {
                                  cartItemsHtml.append("<img src='https://via.placeholder.com/80x80?text=No+Image' alt='No Image' class='item-image img-fluid'>");
                              }
                              cartItemsHtml.append("</div>");
                              
                              // Product Details
                              cartItemsHtml.append("<div class='col-md-4 col-9 mb-2 mb-md-0'>");
                              cartItemsHtml.append("<div class='item-name'>").append(namaBarang).append("</div>");
                              cartItemsHtml.append("<div class='item-price'>Rp ").append(String.format("%,.0f", harga)).append(" per item</div>");
                              cartItemsHtml.append("<div class='item-total'>Total: Rp ").append(String.format("%,.0f", subtotal)).append("</div>");
                              cartItemsHtml.append("</div>");
                              
                              // Quantity Controls
                              cartItemsHtml.append("<div class='col-md-4 col-8 mb-2 mb-md-0'>");
                              cartItemsHtml.append("<div class='quantity-controls justify-content-center justify-content-md-start'>");
                              cartItemsHtml.append("<button type='button' class='quantity-btn' onclick='updateQuantity(").append(keranjangId).append(", ").append(quantity - 1).append(", ").append(stok).append(")' ").append(quantity <= 1 ? "disabled" : "").append(">");
                              cartItemsHtml.append("<i class='fas fa-minus'></i>");
                              cartItemsHtml.append("</button>");
                              cartItemsHtml.append("<input type='number' class='quantity-input' value='").append(quantity).append("' min='1' max='").append(stok).append("' onchange='updateQuantityInput(").append(keranjangId).append(", this.value, ").append(stok).append(")'>");
                              cartItemsHtml.append("<button type='button' class='quantity-btn' onclick='updateQuantity(").append(keranjangId).append(", ").append(quantity + 1).append(", ").append(stok).append(")' ").append(quantity >= stok ? "disabled" : "").append(">");
                              cartItemsHtml.append("<i class='fas fa-plus'></i>");
                              cartItemsHtml.append("</button>");
                              cartItemsHtml.append("</div>");
                              cartItemsHtml.append("</div>");
                              
                              // Remove Button
                              cartItemsHtml.append("<div class='col-md-2 col-4 text-end'>");
                              cartItemsHtml.append("<button type='button' class='btn btn-danger-custom btn-sm' onclick='removeFromCart(").append(keranjangId).append(", \"").append(namaBarang).append("\")'>");
                              cartItemsHtml.append("<i class='fas fa-trash'></i>");
                              cartItemsHtml.append("</button>");
                              cartItemsHtml.append("</div>");
                              
                              cartItemsHtml.append("</div>");
                              cartItemsHtml.append("</div>");
                          }
                          
                          if (hasItems) {
                    %>
                    
                    <!-- Cart Summary -->
                    <div class="cart-summary-section">
                        <div class="row">
                            <div class="col-md-6">
                                <div class="summary-card">
                                    <div class="summary-number"><%= totalItems %></div>
                                    <div class="summary-label"><i class="fas fa-shopping-bag"></i> Total Item</div>
                                </div>
                            </div>
                            <div class="col-md-6">
                                <div class="summary-card">
                                    <div class="summary-number">Rp <%= String.format("%,.0f", totalHarga) %></div>
                                    <div class="summary-label"><i class="fas fa-money-bill-wave"></i> Total Harga</div>
                                </div>
                            </div>
                        </div>
                    </div>
                    
                    <!-- Cart Items -->
                    <div class="cart-items-section">
                        <h5 class="mb-3"><i class="fas fa-list"></i> Item dalam Keranjang</h5>
                        <%= cartItemsHtml.toString() %>
                    </div>
                    
                    <!-- Checkout Section -->
                    <div class="checkout-section">
                        <div class="row align-items-center">
                            <div class="col-md-6">
                                <div class="checkout-total">
                                    <i class="fas fa-calculator"></i> Total Pembayaran: Rp <%= String.format("%,.0f", totalHarga) %>
                                </div>
                            </div>
                            <div class="col-md-6">
                                <div class="d-flex gap-2 justify-content-md-end mt-3 mt-md-0">
                                    <a href="daftarBarang.jsp" class="btn btn-secondary-custom">
                                        <i class="fas fa-arrow-left"></i> Lanjut Belanja
                                    </a>
                                    <button type="button" class="btn btn-custom" onclick="proceedToCheckout()">
                                        <i class="fas fa-credit-card"></i> Checkout
                                    </button>
                                </div>
                            </div>
                        </div>
                    </div>
                    
                    <%
                          } else {
                    %>
                    
                    <!-- Empty Cart -->
                    <div class="cart-items-section">
                        <div class="empty-cart">
                            <i class="fas fa-shopping-cart"></i>
                            <h4>Keranjang Belanja Kosong</h4>
                            <p class="text-muted">Anda belum menambahkan produk ke keranjang</p>
                            <a href="daftarBarang.jsp" class="btn btn-custom">
                                <i class="fas fa-shopping-bag"></i> Mulai Belanja
                            </a>
                        </div>
                    </div>
                    
                    <%
                          }
                      } catch(Exception e) {
                          out.println("<div class='cart-items-section'><div class='alert alert-danger'><i class='fas fa-exclamation-triangle'></i> Error: " + e.getMessage() + "</div></div>");
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

    <script src="https://cdnjs.cloudflare.com/ajax/libs/bootstrap/5.0.2/js/bootstrap.bundle.min.js"></script>
    <script>
        // Update quantity function
        function updateQuantity(keranjangId, newQuantity, stok) {
            if (newQuantity < 1 || newQuantity > stok) {
                showMessage('Jumlah tidak valid', false);
                return;
            }
            
            const xhr = new XMLHttpRequest();
            xhr.open('POST', 'updateCart.jsp', true);
            xhr.setRequestHeader('Content-Type', 'application/x-www-form-urlencoded');
            
            xhr.onload = function() {
                if (xhr.status === 200) {
                    try {
                        const response = JSON.parse(xhr.responseText);
                        showMessage(response.message, response.success);
                        
                        if (response.success) {
                            // Reload page to update totals
                            setTimeout(() => {
                                location.reload();
                            }, 1000);
                        }
                    } catch (e) {
                        showMessage('Terjadi kesalahan saat memproses permintaan', false);
                    }
                }
            };
            
            xhr.send('keranjangId=' + encodeURIComponent(keranjangId) + 
                     '&quantity=' + encodeURIComponent(newQuantity));
        }
        
        // Update quantity from input
        function updateQuantityInput(keranjangId, newQuantity, stok) {
            const qty = parseInt(newQuantity);
            updateQuantity(keranjangId, qty, stok);
        }
        
        // Remove from cart function
        function removeFromCart(keranjangId, namaBarang) {
            if (!confirm('Apakah Anda yakin ingin menghapus "' + namaBarang + '" dari keranjang?')) {
                return;
            }
            
            const xhr = new XMLHttpRequest();
            xhr.open('POST', 'removeFromCart.jsp', true);
            xhr.setRequestHeader('Content-Type', 'application/x-www-form-urlencoded');
            
            xhr.onload = function() {
                if (xhr.status === 200) {
                    try {
                        const response = JSON.parse(xhr.responseText);
                        showMessage(response.message, response.success);
                        
                        if (response.success) {
                            // Reload page to update cart
                            setTimeout(() => {
                                location.reload();
                            }, 1000);
                        }
                    } catch (e) {
                        showMessage('Terjadi kesalahan saat memproses permintaan', false);
                    }
                }
            };
            
            xhr.send('keranjangId=' + encodeURIComponent(keranjangId));
        }
        
        // Proceed to checkout
        function proceedToCheckout() {
            // Redirect to checkout page (will be created later)
            window.location.href = 'checkout.jsp';
        }
        
        // Show message function
        function showMessage(message, isSuccess) {
            const messageDiv = document.getElementById('message');
            messageDiv.innerHTML = '<i class="fas fa-' + (isSuccess ? 'check-circle' : 'exclamation-triangle') + '"></i> ' + message;
            messageDiv.className = 'alert message ' + (isSuccess ? 'alert-success' : 'alert-danger');
            messageDiv.style.display = 'block';
            
            setTimeout(function() {
                messageDiv.style.display = 'none';
            }, 3000);
        }
    </script>
</body>
</html>