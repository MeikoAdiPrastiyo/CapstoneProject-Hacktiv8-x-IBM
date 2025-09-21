<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="java.sql.*" %>
<%
    // Cek login
    Integer userId = (Integer) session.getAttribute("user_id");
    if (userId == null) {
        response.sendRedirect("login.html");
        return;
    }
%>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Keranjang Belanja</title>
    <link href="https://cdnjs.cloudflare.com/ajax/libs/bootstrap/5.0.2/css/bootstrap.min.css" rel="stylesheet">
    <link href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.0.0/css/all.min.css" rel="stylesheet">
    <link href="https://fonts.googleapis.com/css2?family=Poppins:wght@300;400;500;600;700;800&display=swap" rel="stylesheet">
    <style>
        :root {
            --primary: #2d5016;
            --secondary: #4a7c59;
            --accent: #8bc34a;
            --gold: #ffc107;
            --cream: #f8f6f0;
            --brown: #8d6e63;
            --green-light: #e8f5e8;
            --white: #ffffff;
            --light-gray: #f8f9fa;
            --border-color: #e9ecef;
            --shadow: 0 4px 15px rgba(0,0,0,0.1);
            --shadow-hover: 0 8px 25px rgba(0,0,0,0.15);
        }

        * { 
            margin: 0; 
            padding: 0; 
            box-sizing: border-box; 
        }

        body {
            font-family: 'Poppins', sans-serif;
            background: linear-gradient(135deg, var(--cream) 0%, var(--green-light) 100%);
            line-height: 1.6;
            min-height: 100vh;
        }

        /* Enhanced Navigation */
        .navbar {
            background: linear-gradient(135deg, var(--primary) 0%, var(--secondary) 100%);
            padding: 0.1rem 0;
            box-shadow: 0 4px 20px rgba(45, 80, 22, 0.3);
            position: sticky;
            top: 0;
            z-index: 1000;
        }

        .navbar-brand {
            font-size: 1.8rem;
            font-weight: 800;
            color: white !important;
            text-shadow: 2px 2px 4px rgba(0,0,0,0.4);
            display: flex;
            align-items: center;
            gap: 10px;
        }

        .navbar-brand i {
            font-size: 2rem;
            color: var(--accent);
        }

        /* Container Styling */
        .container {
            max-width: 1200px;
            margin: 0 auto;
            padding: 1.1rem 1rem;
        }

        /* Page Header */
        .page-header {
            text-align: center;
            margin-bottom: 3rem;
            padding: 2rem 0;
            background: var(--white);
            border-radius: 20px;
            box-shadow: var(--shadow);
            position: relative;
            overflow: hidden;
        }

        .page-header::before {
            content: '';
            position: absolute;
            top: -50%;
            left: -50%;
            width: 200%;
            height: 200%;
            background: linear-gradient(45deg, transparent, rgba(139, 195, 74, 0.1), transparent);
            transform: rotate(45deg);
            animation: shimmer 3s infinite;
        }

        @keyframes shimmer {
            0% { transform: translateX(-100%) translateY(-100%) rotate(45deg); }
            100% { transform: translateX(100%) translateY(100%) rotate(45deg); }
        }

        .page-header h2 {
            font-size: 2.5rem;
            font-weight: 700;
            color: var(--primary);
            margin-bottom: 0.5rem;
            position: relative;
            z-index: 2;
        }

        .page-header .subtitle {
            color: var(--secondary);
            font-size: 1.1rem;
            font-weight: 400;
            position: relative;
            z-index: 2;
        }

        /* Empty Cart Styling */
        .empty-cart {
            background: var(--white);
            border-radius: 20px;
            padding: 3rem;
            text-align: center;
            box-shadow: var(--shadow);
            border: 2px solid var(--green-light);
        }

        .empty-cart-icon {
            font-size: 4rem;
            color: var(--accent);
            margin-bottom: 1.5rem;
        }

        .empty-cart h4 {
            color: var(--primary);
            font-weight: 600;
            margin-bottom: 1rem;
        }

        .empty-cart p {
            color: var(--secondary);
            margin-bottom: 2rem;
            font-size: 1.1rem;
        }

        /* Cart Table Styling */
        .cart-wrapper {
            background: var(--white);
            border-radius: 20px;
            padding: 2rem;
            box-shadow: var(--shadow);
            margin-bottom: 2rem;
        }

        .table {
            margin-bottom: 0;
            border-radius: 15px;
            overflow: hidden;
            box-shadow: 0 2px 10px rgba(0,0,0,0.05);
        }

        .table thead th {
            background: linear-gradient(135deg, var(--primary) 0%, var(--secondary) 100%);
            color: white;
            font-weight: 600;
            text-transform: uppercase;
            letter-spacing: 0.5px;
            border: none;
            padding: 1.2rem 1rem;
            font-size: 0.9rem;
        }

        .table tbody td {
            padding: 1.5rem 1rem;
            vertical-align: middle;
            border-color: var(--border-color);
            font-weight: 500;
        }

        .table tbody tr {
            transition: all 0.3s ease;
        }

        .table tbody tr:hover {
            background: var(--green-light);
            transform: translateY(-2px);
            box-shadow: 0 5px 15px rgba(139, 195, 74, 0.2);
        }

        /* Product Name Styling */
        .product-name {
            font-weight: 600;
            color: var(--primary);
            font-size: 1.1rem;
        }

        /* Price Styling */
        .price {
            font-weight: 600;
            color: var(--secondary);
            font-size: 1rem;
        }

        /* Quantity Controls */
        .quantity-controls {
            display: flex;
            align-items: center;
            justify-content: center;
            gap: 0.5rem;
        }

        .quantity-btn {
            width: 35px;
            height: 35px;
            border: 2px solid var(--accent);
            background: var(--white);
            color: var(--accent);
            border-radius: 50%;
            display: flex;
            align-items: center;
            justify-content: center;
            font-weight: 600;
            transition: all 0.3s ease;
        }

        .quantity-btn:hover:not(:disabled) {
            background: var(--accent);
            color: white;
            transform: scale(1.1);
            box-shadow: 0 3px 10px rgba(139, 195, 74, 0.3);
        }

        .quantity-btn:disabled {
            opacity: 0.5;
            cursor: not-allowed;
        }

        .quantity-display {
            background: var(--green-light);
            padding: 0.5rem 1rem;
            border-radius: 25px;
            font-weight: 600;
            color: var(--primary);
            min-width: 50px;
            text-align: center;
        }

        .stock-info {
            color: var(--brown);
            font-size: 0.85rem;
            margin-top: 0.3rem;
            font-style: italic;
        }

        /* Subtotal Styling */
        .subtotal {
            font-weight: 700;
            color: var(--primary);
            font-size: 1.1rem;
        }

        /* Action Buttons */
        .btn-remove {
            background: linear-gradient(135deg, #dc3545 0%, #c82333 100%);
            border: none;
            color: white;
            padding: 0.5rem 1rem;
            border-radius: 25px;
            font-weight: 500;
            transition: all 0.3s ease;
            box-shadow: 0 2px 8px rgba(220, 53, 69, 0.3);
        }

        .btn-remove:hover {
            transform: translateY(-2px);
            box-shadow: 0 5px 15px rgba(220, 53, 69, 0.4);
            color: white;
        }

        /* Footer Total */
        .table tfoot th {
            background: linear-gradient(135deg, var(--gold) 0%, #ffb300 100%);
            color: var(--primary);
            font-weight: 700;
            font-size: 1.1rem;
            padding: 1.5rem 1rem;
            border: none;
        }

        .total-amount {
            font-size: 1.3rem;
            font-weight: 800;
            color: var(--primary);
        }

        /* Action Buttons Row */
        .action-buttons {
            display: flex;
            justify-content: space-between;
            align-items: center;
            margin-top: 2rem;
            gap: 1rem;
        }

        .btn-continue {
            background: linear-gradient(135deg, var(--brown) 0%, #6d4c41 100%);
            border: none;
            color: white;
            padding: 0.8rem 2rem;
            border-radius: 25px;
            font-weight: 600;
            text-decoration: none;
            transition: all 0.3s ease;
            box-shadow: 0 3px 12px rgba(141, 110, 99, 0.3);
        }

        .btn-continue:hover {
            color: white;
            transform: translateY(-3px);
            box-shadow: 0 8px 20px rgba(141, 110, 99, 0.4);
        }

        .btn-checkout {
            background: linear-gradient(135deg, var(--accent) 0%, #689f38 100%);
            border: none;
            color: white;
            padding: 0.8rem 2.5rem;
            border-radius: 25px;
            font-weight: 700;
            text-decoration: none;
            transition: all 0.3s ease;
            box-shadow: 0 3px 12px rgba(139, 195, 74, 0.3);
            font-size: 1.1rem;
        }

        .btn-checkout:hover {
            color: white;
            transform: translateY(-3px);
            box-shadow: 0 8px 20px rgba(139, 195, 74, 0.4);
        }

        /* Error Alert */
        .alert-danger {
            background: linear-gradient(135deg, #f8d7da 0%, #f5c6cb 100%);
            border: 2px solid #f1aeb5;
            border-radius: 15px;
            color: #721c24;
            padding: 1.5rem;
            margin-bottom: 2rem;
        }

        /* Responsive Design */
        @media (max-width: 768px) {
            .container {
                padding: 1rem;
            }
            
            .page-header h2 {
                font-size: 2rem;
            }
            
            .action-buttons {
                flex-direction: column;
                gap: 1rem;
            }
            
            .btn-continue,
            .btn-checkout {
                width: 100%;
                text-align: center;
            }
            
            .table-responsive {
                border-radius: 15px;
                box-shadow: 0 2px 10px rgba(0,0,0,0.1);
            }
        }

        /* Loading Animation */
        .loading {
            display: inline-block;
            width: 20px;
            height: 20px;
            border: 3px solid rgba(139, 195, 74, 0.3);
            border-radius: 50%;
            border-top-color: var(--accent);
            animation: spin 1s ease-in-out infinite;
        }

        @keyframes spin {
            to { transform: rotate(360deg); }
        }

        /* Custom Popup Modal */
        .modal-overlay {
            position: fixed;
            top: 0;
            left: 0;
            width: 100%;
            height: 100%;
            background: rgba(0, 0, 0, 0.5);
            display: none;
            justify-content: center;
            align-items: center;
            z-index: 9999;
            backdrop-filter: blur(5px);
            animation: fadeIn 0.3s ease-in-out;
        }

        .modal-overlay.show {
            display: flex;
        }

        .modal-content {
            background: var(--white);
            border-radius: 20px;
            padding: 2rem;
            max-width: 400px;
            width: 90%;
            text-align: center;
            box-shadow: 0 20px 40px rgba(0, 0, 0, 0.3);
            transform: scale(0.8);
            animation: popIn 0.3s ease-out forwards;
        }

        @keyframes fadeIn {
            from { opacity: 0; }
            to { opacity: 1; }
        }

        @keyframes popIn {
            to { transform: scale(1); }
        }

        .modal-icon {
            font-size: 4rem;
            color: #dc3545;
            margin-bottom: 1rem;
            animation: bounce 0.6s ease-in-out;
        }

        @keyframes bounce {
            0%, 20%, 50%, 80%, 100% { transform: translateY(0); }
            40% { transform: translateY(-10px); }
            60% { transform: translateY(-5px); }
        }

        .modal-title {
            font-size: 1.5rem;
            font-weight: 700;
            color: var(--primary);
            margin-bottom: 1rem;
        }

        .modal-message {
            color: var(--secondary);
            margin-bottom: 2rem;
            font-size: 1rem;
            line-height: 1.5;
        }

        .modal-product-name {
            font-weight: 600;
            color: var(--primary);
            background: var(--green-light);
            padding: 0.5rem 1rem;
            border-radius: 10px;
            display: inline-block;
            margin: 0.5rem 0;
        }

        .modal-actions {
            display: flex;
            gap: 1rem;
            justify-content: center;
        }

        .modal-btn {
            padding: 0.8rem 1.5rem;
            border: none;
            border-radius: 25px;
            font-weight: 600;
            cursor: pointer;
            transition: all 0.3s ease;
            min-width: 120px;
        }

        .modal-btn-cancel {
            background: var(--light-gray);
            color: var(--secondary);
        }

        .modal-btn-cancel:hover {
            background: var(--border-color);
            transform: translateY(-2px);
        }

        .modal-btn-confirm {
            background: linear-gradient(135deg, #dc3545 0%, #c82333 100%);
            color: white;
            box-shadow: 0 3px 12px rgba(220, 53, 69, 0.3);
        }

        .modal-btn-confirm:hover {
            transform: translateY(-2px);
            box-shadow: 0 6px 20px rgba(220, 53, 69, 0.4);
        }
    </style>
</head>
<body>
    <!-- Navigation -->
    <nav class="navbar navbar-expand-lg">
        <div class="container">
            <a class="navbar-brand" href="home.jsp">
                <i class="fas fa-tractor"></i>
                FarmStock
            </a>
        </div>
    </nav>

    <div class="container">
        <!-- Page Header -->
        <div class="page-header">
            <h2><i class="fas fa-shopping-cart"></i> Keranjang Belanja</h2>
            <p class="subtitle">Kelola produk pilihan Anda sebelum melakukan pembelian</p>
        </div>
        
        <%
            // Database connection
            String url = "jdbc:mysql://localhost:3306/webcapstone";
            String user = "root";
            String dbpass = "";
            Connection conn = null;
            PreparedStatement pstmt = null;
            ResultSet rs = null;
            
            double totalHarga = 0;
            int totalItem = 0;
            boolean hasItems = false;
            
            try {
                Class.forName("com.mysql.cj.jdbc.Driver");
                conn = DriverManager.getConnection(url, user, dbpass);
                
                // Ambil data keranjang user
                String sql = "SELECT k.id as keranjang_id, k.barang_id, k.quantity, " +
                           "b.nama_barang, b.harga, b.quantity as stok " +
                           "FROM keranjang k " +
                           "JOIN barang b ON k.barang_id = b.id " +
                           "WHERE k.user_id = ? " +
                           "ORDER BY k.created_at DESC";
                
                pstmt = conn.prepareStatement(sql, ResultSet.TYPE_SCROLL_INSENSITIVE, ResultSet.CONCUR_READ_ONLY);
                pstmt.setInt(1, userId);
                rs = pstmt.executeQuery();
                
                // Cek apakah ada item
                if (!rs.next()) {
        %>
                    <div class="empty-cart">
                        <div class="empty-cart-icon">
                            <i class="fas fa-shopping-cart"></i>
                        </div>
                        <h4>Keranjang Belanja Kosong</h4>
                        <p>Anda belum menambahkan produk apapun ke keranjang belanja. Mari mulai berbelanja dan temukan produk terbaik untuk Anda!</p>
                        <a href="home.jsp" class="btn-checkout">
                            <i class="fas fa-shopping-bag"></i> Mulai Belanja Sekarang
                        </a>
                    </div>
        <%
                } else {
                    hasItems = true;
                    // Reset cursor
                    rs.beforeFirst();
        %>
                    <div class="cart-wrapper">
                        <div class="table-responsive">
                            <table class="table">
                                <thead>
                                    <tr>
                                        <th><i class="fas fa-box"></i> Nama Barang</th>
                                        <th><i class="fas fa-tag"></i> Harga</th>
                                        <th><i class="fas fa-sort-numeric-up"></i> Jumlah</th>
                                        <th><i class="fas fa-calculator"></i> Subtotal</th>
                                        <th><i class="fas fa-cogs"></i> Aksi</th>
                                    </tr>
                                </thead>
                                <tbody>
        <%
                    while (rs.next()) {
                        int keranjangId = rs.getInt("keranjang_id");
                        int barangId = rs.getInt("barang_id");
                        String namaBarang = rs.getString("nama_barang");
                        double harga = rs.getDouble("harga");
                        int quantity = rs.getInt("quantity");
                        int stok = rs.getInt("stok");
                        double subtotal = harga * quantity;
                        
                        totalHarga += subtotal;
                        totalItem += quantity;
        %>
                            <tr>
                                <td class="product-name"><%= namaBarang %></td>
                                <td class="price">Rp <%= String.format("%,.0f", harga) %></td>
                                <td>
                                    <div class="quantity-controls">
                                        <button class="quantity-btn" 
                                                onclick="updateQuantity(<%= keranjangId %>, <%= quantity - 1 %>)"
                                                <%= quantity <= 1 ? "disabled" : "" %>>
                                            <i class="fas fa-minus"></i>
                                        </button>
                                        <span class="quantity-display"><%= quantity %></span>
                                        <button class="quantity-btn" 
                                                onclick="updateQuantity(<%= keranjangId %>, <%= quantity + 1 %>)"
                                                <%= quantity >= stok ? "disabled" : "" %>>
                                            <i class="fas fa-plus"></i>
                                        </button>
                                    </div>
                                    <div class="stock-info">
                                        <i class="fas fa-warehouse"></i> Stok tersedia: <%= stok %>
                                    </div>
                                </td>
                                <td class="subtotal">Rp <%= String.format("%,.0f", subtotal) %></td>
                                <td>
                                    <button class="btn-remove" onclick="removeItem(<%= keranjangId %>, '<%= namaBarang %>')">
                                        <i class="fas fa-trash-alt"></i> Hapus
                                    </button>
                                </td>
                            </tr>
        <%
                    }
        %>
                                </tbody>
                                <tfoot>
                                    <tr>
                                        <th colspan="2">
                                            <i class="fas fa-receipt"></i> Total Pembelian
                                        </th>
                                        <th>
                                            <i class="fas fa-shopping-basket"></i> <%= totalItem %> item
                                        </th>
                                        <th class="total-amount">
                                            Rp <%= String.format("%,.0f", totalHarga) %>
                                        </th>
                                        <th></th>
                                    </tr>
                                </tfoot>
                            </table>
                        </div>
                        
                        <div class="action-buttons">
                            <a href="home.jsp" class="btn-continue">
                                <i class="fas fa-arrow-left"></i> Lanjut Belanja
                            </a>
                            <a href="checkout.jsp" class="btn-checkout">
                                <i class="fas fa-credit-card"></i> Checkout - Rp <%= String.format("%,.0f", totalHarga) %>
                            </a>
                        </div>
                    </div>
        <%
                }
            } catch (Exception e) {
                out.println("<div class='alert alert-danger'><i class='fas fa-exclamation-triangle'></i> <strong>Error:</strong> " + e.getMessage() + "</div>");
            } finally {
                if (rs != null) try { rs.close(); } catch (SQLException e) { e.printStackTrace(); }
                if (pstmt != null) try { pstmt.close(); } catch (SQLException e) { e.printStackTrace(); }
                if (conn != null) try { conn.close(); } catch (SQLException e) { e.printStackTrace(); }
            }
        %>
    </div>

    <!-- Custom Delete Confirmation Modal -->
    <div class="modal-overlay" id="deleteModal">
        <div class="modal-content">
            <div class="modal-icon">
                <i class="fas fa-trash-alt"></i>
            </div>
            <h3 class="modal-title">Hapus Item dari Keranjang?</h3>
            <div class="modal-message">
                Apakah Anda yakin ingin menghapus
                <div class="modal-product-name" id="productToDelete"></div>
                dari keranjang belanja Anda?
            </div>
            <div class="modal-actions">
                <button class="modal-btn modal-btn-cancel" onclick="closeDeleteModal()">
                    <i class="fas fa-times"></i> Batal
                </button>
                <button class="modal-btn modal-btn-confirm" onclick="confirmDelete()">
                    <i class="fas fa-check"></i> Ya, Hapus
                </button>
            </div>
        </div>
    </div>

    <script src="https://cdnjs.cloudflare.com/ajax/libs/bootstrap/5.0.2/js/bootstrap.bundle.min.js"></script>
    <script>
        let deleteData = {};

        function updateQuantity(keranjangId, newQuantity) {
            if (newQuantity <= 0) {
                showCustomAlert('Jumlah minimal 1. Gunakan tombol Hapus untuk menghapus item.');
                return;
            }
            
            // Show loading state
            const button = event.target.closest('button');
            const originalContent = button.innerHTML;
            button.innerHTML = '<div class="loading"></div>';
            button.disabled = true;
            
            window.location.href = 'updateKeranjangUser.jsp?keranjang_id=' + keranjangId + '&quantity=' + newQuantity;
        }
        
        function removeItem(keranjangId, namaBarang) {
            // Store delete data
            deleteData = {
                keranjangId: keranjangId,
                namaBarang: namaBarang
            };
            
            // Show custom modal
            document.getElementById('productToDelete').textContent = namaBarang;
            document.getElementById('deleteModal').classList.add('show');
        }

        function closeDeleteModal() {
            document.getElementById('deleteModal').classList.remove('show');
            deleteData = {};
        }

        function confirmDelete() {
            if (deleteData.keranjangId) {
                window.location.href = 'hapusKeranjangUser.jsp?keranjang_id=' + deleteData.keranjangId;
            }
        }

        function showCustomAlert(message) {
            // Create temporary alert modal
            const alertModal = document.createElement('div');
            alertModal.className = 'modal-overlay show';
            alertModal.innerHTML = `
                <div class="modal-content">
                    <div class="modal-icon" style="color: var(--gold);">
                        <i class="fas fa-exclamation-triangle"></i>
                    </div>
                    <h3 class="modal-title">Perhatian</h3>
                    <div class="modal-message">${message}</div>
                    <div class="modal-actions">
                        <button class="modal-btn modal-btn-confirm" onclick="this.closest('.modal-overlay').remove()">
                            <i class="fas fa-check"></i> OK
                        </button>
                    </div>
                </div>
            `;
            document.body.appendChild(alertModal);
        }

        // Close modal when clicking outside
        document.addEventListener('click', function(event) {
            const modal = document.getElementById('deleteModal');
            if (event.target === modal) {
                closeDeleteModal();
            }
        });

        // Close modal with Escape key
        document.addEventListener('keydown', function(event) {
            if (event.key === 'Escape') {
                closeDeleteModal();
            }
        });

        // Add smooth scroll behavior
        document.documentElement.style.scrollBehavior = 'smooth';

        // Add fade-in animation on page load
        window.addEventListener('load', function() {
            document.body.style.opacity = '0';
            document.body.style.transition = 'opacity 0.5s ease-in-out';
            setTimeout(() => {
                document.body.style.opacity = '1';
            }, 100);
        });
    </script>
</body>
</html>