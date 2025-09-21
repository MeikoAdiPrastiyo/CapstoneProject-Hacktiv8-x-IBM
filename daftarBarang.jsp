<%-- daftarBarang.jsp --%>
<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="java.sql.*" %>
<%
    // Check if user is logged in
    String username = (String) session.getAttribute("username");
    String userRole = (String) session.getAttribute("role");
    
    if (username == null) {
        response.sendRedirect("login.html");
        return;
    }
    
    // Check if user has 'user' role (bukan admin)
    if (!"user".equals(userRole)) {
        response.sendRedirect("dashboard.jsp"); // redirect ke admin dashboard
        return;
    }
    
    // Database connection
    String url = "jdbc:mysql://localhost:3306/webcapstone";
    String user = "root";
    String dbpass = "";
    Connection conn = null;
    PreparedStatement pstmt = null;
    ResultSet rs = null;
%>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>E-Shop - Daftar Barang</title>
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

        .search-filter-section {
            background: white;
            border-radius: 10px;
            padding: 15px;
            box-shadow: 0 2px 10px rgba(0, 0, 0, 0.1);
            margin-bottom: 20px;
        }

        .products-section {
            background: white;
            border-radius: 10px;
            padding: 20px;
            box-shadow: 0 2px 10px rgba(0, 0, 0, 0.1);
        }

        .product-card {
            background: white;
            border: 1px solid #e9ecef;
            border-radius: 10px;
            padding: 15px;
            margin-bottom: 20px;
            box-shadow: 0 2px 8px rgba(0, 0, 0, 0.1);
            transition: all 0.3s ease;
            height: 100%;
        }

        .product-card:hover {
            transform: translateY(-5px);
            box-shadow: 0 4px 15px rgba(0, 0, 0, 0.15);
        }

        .product-image {
            width: 100%;
            height: 150px;
            object-fit: cover;
            border-radius: 8px;
            margin-bottom: 10px;
        }

        .product-name {
            font-size: 14px;
            font-weight: 600;
            color: #333;
            margin-bottom: 8px;
            line-height: 1.3;
        }

        .product-price {
            font-size: 16px;
            font-weight: 700;
            color: var(--primary-color);
            margin-bottom: 8px;
        }

        .stock-badge {
            padding: 3px 8px;
            border-radius: 15px;
            font-size: 10px;
            font-weight: 600;
            margin-bottom: 10px;
        }

        .stock-badge.low {
            background-color: #fff3cd;
            color: #856404;
        }

        .stock-badge.medium {
            background-color: #d1ecf1;
            color: #0c5460;
        }

        .stock-badge.high {
            background-color: #d4edda;
            color: #155724;
        }

        .quantity-selector {
            display: flex;
            align-items: center;
            justify-content: center;
            gap: 8px;
            margin-bottom: 10px;
        }

        .quantity-btn {
            width: 30px;
            height: 30px;
            border: 1px solid #dee2e6;
            background-color: white;
            cursor: pointer;
            border-radius: 5px;
            display: flex;
            align-items: center;
            justify-content: center;
            font-weight: 600;
            transition: all 0.3s ease;
            font-size: 12px;
        }

        .quantity-btn:hover {
            background-color: var(--primary-color);
            color: white;
            border-color: var(--primary-color);
        }

        .quantity-input {
            width: 50px;
            text-align: center;
            border: 1px solid #dee2e6;
            border-radius: 5px;
            padding: 5px;
            font-size: 12px;
        }

        .btn-custom {
            background-color: var(--primary-color);
            border-color: var(--primary-color);
            color: white;
            font-size: 12px;
            padding: 8px 12px;
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

        .search-box {
            position: relative;
        }

        .search-box .form-control {
            padding-right: 45px;
        }

        .search-box .search-btn {
            position: absolute;
            right: 5px;
            top: 50%;
            transform: translateY(-50%);
            background: none;
            border: none;
            color: var(--primary-color);
            font-size: 18px;
        }

        .message {
            position: fixed;
            top: 20px;
            right: 20px;
            z-index: 1050;
            min-width: 300px;
            display: none;
        }

        .no-products {
            text-align: center;
            padding: 40px 20px;
            color: #6c757d;
        }

        .no-products i {
            font-size: 3rem;
            color: #dee2e6;
            margin-bottom: 15px;
        }

        @media (max-width: 768px) {
            .quantity-selector {
                flex-direction: column;
                gap: 5px;
            }
            
            .quantity-input {
                width: 60px;
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
                        <a href="daftarBarang.jsp" class="active">
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
                    <!-- Page Header -->
                    <div class="page-header">
                        <h2><i class="fas fa-boxes"></i> Daftar Barang</h2>
                        <p class="mb-0">Selamat berbelanja, <%= username %>! Pilih produk favorit Anda.</p>
                    </div>

                    <!-- Search and Filter Section -->
                    <div class="search-filter-section">
                        <div class="row align-items-center">
                            <div class="col-md-6">
                                <div class="search-box">
                                    <input type="text" id="searchInput" class="form-control" placeholder="Cari produk...">
                                    <button type="button" class="search-btn" onclick="searchProducts()">
                                        <i class="fas fa-search"></i>
                                    </button>
                                </div>
                            </div>
                            <div class="col-md-6">
                                <div class="d-flex align-items-center justify-content-md-end mt-3 mt-md-0">
                                    <label for="sortBy" class="me-2 text-nowrap">Urutkan:</label>
                                    <select id="sortBy" class="form-select" onchange="sortProducts()" style="width: auto;">
                                        <option value="nama">Nama A-Z</option>
                                        <option value="nama_desc">Nama Z-A</option>
                                        <option value="harga">Harga Terendah</option>
                                        <option value="harga_desc">Harga Tertinggi</option>
                                        <option value="stok">Stok Terbanyak</option>
                                    </select>
                                </div>
                            </div>
                        </div>
                    </div>

                    <!-- Success/Error Message -->
                    <div id="message" class="alert message"></div>

                    <!-- Products Section -->
                    <div class="products-section">
                        <div class="row g-3" id="productsGrid">
                            <%
                              try {
                                  Class.forName("com.mysql.cj.jdbc.Driver");
                                  conn = DriverManager.getConnection(url, user, dbpass);
                                  String sql = "SELECT * FROM barang WHERE quantity > 0 ORDER BY nama_barang ASC";
                                  pstmt = conn.prepareStatement(sql);
                                  rs = pstmt.executeQuery();
                                  
                                  boolean hasProducts = false;
                                  while(rs.next()) {
                                      hasProducts = true;
                                      String barangId = rs.getString("id");
                                      String namaBarang = rs.getString("nama_barang");
                                      String gambar = rs.getString("gambar");
                                      int quantity = rs.getInt("quantity");
                                      double harga = rs.getDouble("harga");
                                      
                                      // Determine stock level
                                      String stockClass = quantity <= 10 ? "low" : quantity <= 50 ? "medium" : "high";
                                      String stockText = quantity <= 10 ? "Stok Terbatas" : quantity <= 50 ? "Stok Sedang" : "Stok Banyak";
                            %>
                            <div class="col-md-6 col-lg-4 col-xl-3">
                                <div class="product-card" data-name="<%= namaBarang.toLowerCase() %>" data-price="<%= harga %>" data-stock="<%= quantity %>">
                                    <% if (gambar != null && !gambar.trim().isEmpty()) { %>
                                        <img src="uploads/<%= gambar %>" alt="<%= namaBarang %>" class="product-image" onerror="this.src='https://via.placeholder.com/280x150?text=No+Image'">
                                    <% } else { %>
                                        <img src="https://via.placeholder.com/280x150?text=No+Image" alt="No Image" class="product-image">
                                    <% } %>
                                    
                                    <div class="product-name"><%= namaBarang %></div>
                                    <div class="product-price">Rp <%= String.format("%,.0f", harga) %></div>
                                    
                                    <div class="text-center">
                                        <span class="stock-badge <%= stockClass %>">
                                            <i class="fas fa-box"></i> <%= stockText %> (<%= quantity %>)
                                        </span>
                                    </div>
                                    
                                    <div class="quantity-selector">
                                        <button type="button" class="quantity-btn" onclick="decreaseQuantity('<%= barangId %>')">
                                            <i class="fas fa-minus"></i>
                                        </button>
                                        <input type="number" id="qty_<%= barangId %>" class="quantity-input" value="1" min="1" max="<%= quantity %>">
                                        <button type="button" class="quantity-btn" onclick="increaseQuantity('<%= barangId %>', <%= quantity %>)">
                                            <i class="fas fa-plus"></i>
                                        </button>
                                    </div>
                                    
                                    <div class="d-grid">
                                        <button class="btn btn-custom" onclick="addToCart('<%= barangId %>', '<%= namaBarang %>', <%= harga %>)">
                                            <i class="fas fa-cart-plus"></i> Tambah ke Keranjang
                                        </button>
                                    </div>
                                </div>
                            </div>
                            <%
                                  }
                                  
                                  if (!hasProducts) {
                            %>
                            <div class="col-12">
                                <div class="no-products">
                                    <i class="fas fa-shopping-bag"></i>
                                    <h5>Tidak ada produk yang tersedia</h5>
                                    <p class="text-muted">Silakan kembali lagi nanti untuk melihat produk terbaru.</p>
                                </div>
                            </div>
                            <%
                                  }
                              } catch(Exception e) {
                                  out.println("<div class='col-12'><div class='alert alert-danger'><i class='fas fa-exclamation-triangle'></i> Error: " + e.getMessage() + "</div></div>");
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
    </div>

    <script src="https://cdnjs.cloudflare.com/ajax/libs/bootstrap/5.0.2/js/bootstrap.bundle.min.js"></script>
    <script>
        // Quantity selector functions
        function increaseQuantity(barangId, maxQty) {
            const input = document.getElementById('qty_' + barangId);
            const currentValue = parseInt(input.value);
            if (currentValue < maxQty) {
                input.value = currentValue + 1;
            }
        }

        function decreaseQuantity(barangId) {
            const input = document.getElementById('qty_' + barangId);
            const currentValue = parseInt(input.value);
            if (currentValue > 1) {
                input.value = currentValue - 1;
            }
        }

        // Add to cart function
        function addToCart(barangId, namaBarang, harga) {
            const quantity = document.getElementById('qty_' + barangId).value;
            
            const xhr = new XMLHttpRequest();
            xhr.open('POST', 'addToCart.jsp', true);
            xhr.setRequestHeader('Content-Type', 'application/x-www-form-urlencoded');
            
            xhr.onload = function() {
                if (xhr.status === 200) {
                    try {
                        const response = JSON.parse(xhr.responseText);
                        showMessage(response.message, response.success);
                        
                        if (response.success) {
                            // Reset quantity to 1 after successful add
                            document.getElementById('qty_' + barangId).value = 1;
                        }
                    } catch (e) {
                        showMessage('Terjadi kesalahan saat memproses permintaan', false);
                    }
                }
            };
            
            xhr.send('barangId=' + encodeURIComponent(barangId) + 
                     '&quantity=' + encodeURIComponent(quantity));
        }

        // Search function
        function searchProducts() {
            const input = document.getElementById('searchInput');
            const filter = input.value.toLowerCase();
            const cards = document.querySelectorAll('[data-name]');
            
            cards.forEach(card => {
                const name = card.getAttribute('data-name');
                const parentCol = card.closest('.col-md-6, .col-lg-4, .col-xl-3');
                if (name.includes(filter)) {
                    parentCol.style.display = 'block';
                } else {
                    parentCol.style.display = 'none';
                }
            });
        }

        // Sort function
        function sortProducts() {
            const sortBy = document.getElementById('sortBy').value;
            const grid = document.getElementById('productsGrid');
            const cards = Array.from(document.querySelectorAll('[data-name]'));
            
            cards.sort((a, b) => {
                switch(sortBy) {
                    case 'nama':
                        return a.getAttribute('data-name').localeCompare(b.getAttribute('data-name'));
                    case 'nama_desc':
                        return b.getAttribute('data-name').localeCompare(a.getAttribute('data-name'));
                    case 'harga':
                        return parseFloat(a.getAttribute('data-price')) - parseFloat(b.getAttribute('data-price'));
                    case 'harga_desc':
                        return parseFloat(b.getAttribute('data-price')) - parseFloat(a.getAttribute('data-price'));
                    case 'stok':
                        return parseInt(b.getAttribute('data-stock')) - parseInt(a.getAttribute('data-stock'));
                    default:
                        return 0;
                }
            });
            
            // Clear grid and re-append sorted cards with their parent columns
            const sortedColumns = cards.map(card => card.closest('.col-md-6, .col-lg-4, .col-xl-3'));
            grid.innerHTML = '';
            sortedColumns.forEach(col => grid.appendChild(col));
        }

        // Real-time search
        document.getElementById('searchInput').addEventListener('input', searchProducts);

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