<%-- riwayatTransaksi.jsp --%>
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
    List<Map<String, Object>> transaksiList = new ArrayList<>();
%>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>E-Shop - Riwayat Transaksi</title>
    <link href="https://cdnjs.cloudflare.com/ajax/libs/bootstrap/5.0.2/css/bootstrap.min.css" rel="stylesheet">
    <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.5.0/css/all.min.css"/>
    <style>
        :root {
            --primary-color: #2f6c3b;
            --hover-color: #255b30;
        }

        body {
            font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
            background-color: #f8f9fa;
        }

        .container-fluid {
            height: 100vh;
        }

        .sidebar {
            background-color: #343a40;
            height: 100vh;
            color: white;
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
            color: white;
            text-decoration: none;
            transition: all 0.3s ease;
        }

        .sidebar-menu a:hover, .sidebar-menu a.active {
            background-color: rgba(255, 255, 255, 0.1);
            border-left: 4px solid var(--primary-color);
            color: white;
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

        .transaction-card {
            background: white;
            border-radius: 10px;
            box-shadow: 0 2px 10px rgba(0, 0, 0, 0.1);
            margin-bottom: 20px;
            transition: transform 0.3s ease;
        }

        .transaction-card:hover {
            transform: translateY(-2px);
            box-shadow: 0 4px 20px rgba(0, 0, 0, 0.15);
        }

        .transaction-header {
            padding: 20px;
            border-bottom: 1px solid #e9ecef;
            display: flex;
            justify-content: space-between;
            align-items: center;
        }

        .transaction-id {
            font-weight: 600;
            color: var(--primary-color);
            font-size: 1.1rem;
        }

        .transaction-date {
            color: #6c757d;
            font-size: 0.9rem;
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

        .payment-pending {
            background-color: #fff3cd;
            color: #856404;
        }

        .payment-paid {
            background-color: #d4edda;
            color: #155724;
        }

        .payment-failed {
            background-color: #f8d7da;
            color: #721c24;
        }

        .transaction-body {
            padding: 20px;
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


.transaction-details {
    display: flex;
    justify-content: space-between;
    align-items: center;
    margin-bottom: 20px;
}
.detail-item {
    flex: 1;
    text-align: center;
    margin: 0;  /* Remove margins */
}

        .detail-label {
            font-size: 0.9rem;
            color: #6c757d;
            margin-bottom: 5px;
        }

        .detail-value {
            font-weight: 600;
            color: #333;
        }

.total-amount {
    font-size: 1.5rem;  /* Increase font size for emphasis */
    color: #2e7d32
}

        .transaction-actions {
            display: flex;
            gap: 10px;
            margin-top: 15px;
            justify-content: space-between;
        }

        .btn-detail {
            background-color: var(--primary-color);
            border-color: var(--primary-color);
            color: white;
            padding: 8px 16px;
            font-size: 0.9rem;
        }

        .btn-detail:hover {
            background-color: var(--hover-color);
            border-color: var(--hover-color);
            color: white;
        }

        .btn-cancel {
            background-color: #dc3545;
            border-color: #dc3545;
            color: white;
            padding: 8px 16px;
            font-size: 0.9rem;
        }

        .btn-cancel:hover {
            background-color: #c82333;
            border-color: #bd2130;
            color: white;
        }

        .btn-complete {
            background-color: #28a745;
            border-color: #28a745;
            color: white;
            padding: 8px 16px;
            font-size: 0.9rem;
        }

        .btn-complete:hover {
            background-color: #218838;
            border-color: #1e7e34;
            color: white;
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

        .message {
            position: fixed;
            top: 20px;
            right: 20px;
            z-index: 1050;
            min-width: 300px;
            display: none;
        }

.item-image {
    max-width: 60px;
    max-height: 60px;
    object-fit: cover;
}

        .product-info {
            display: flex;
            align-items: center;
            justify-content: center;
            flex-direction: column;
        }

        .product-details {
            display: flex;
            align-items: center;
            margin-bottom: 10px;
            margin-left: -100px;
        }

        .product-name {
            font-weight: 600;
            color: #333;
            margin-left: 10px;
        }

        .search-section {
            background: white;
            border-radius: 10px;
            padding: 20px;
            margin-bottom: 20px;
            box-shadow: 0 2px 10px rgba(0, 0, 0, 0.1);
        }

        .search-section h5 {
            color: var(--primary-color);
            margin-bottom: 15px;
        }

        .btn-search {
            background-color: var(--primary-color);
            border-color: var(--primary-color);
            color: white;
        }

        .btn-search:hover {
            background-color: var(--hover-color);
            border-color: var(--hover-color);
            color: white;
        }

        @media (max-width: 768px) {
            .transaction-details {
                grid-template-columns: 1fr;
                gap: 15px;
            }

            .transaction-header {
                flex-direction: column;
                gap: 10px;
                text-align: center;
            }

            .transaction-actions {
                justify-content: center;
            }

            .product-details {
                flex-direction: column;
                text-align: center;
            }

            .item-image {
                margin-right: 0;
                margin-bottom: 10px;
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
                        <a href="riwayatTransaksi.jsp" class="active">
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
                    <div class="page-header">
                        <h2><i class="fas fa-history"></i> Riwayat Transaksi</h2>
                        <p class="mb-0">Lihat semua riwayat pembelian Anda, <%= username %>!</p>
                    </div>

                    <!-- Success/Error Message -->
                    <div id="message" class="alert message"></div>

                    <!-- Search Section -->
                    <div class="search-section">
                        <h5><i class="fas fa-search"></i> Cari Transaksi</h5>
                        <div class="input-group">
                            <input type="text" class="form-control" id="searchInput" placeholder="Masukkan ID Transaksi atau Nama Barang">
                            <button class="btn btn-search" onclick="searchTransaksi()">
                                <i class="fas fa-search"></i> Cari
                            </button>
                        </div>
                    </div>

                    <!-- Transactions List -->
                    <div id="transactionsList">
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
                            
                            // Get transactions with product details
                            String getTransaksiSql = "SELECT DISTINCT t.id, t.total_harga, t.metode_pembayaran, " +
                                                   "t.status_pembayaran, t.status_pesanan, t.created_at " +
                                                   "FROM transaksi t " +
                                                   "WHERE t.user_id = ? " +
                                                   "ORDER BY t.created_at DESC";
                            pstmt = conn.prepareStatement(getTransaksiSql);
                            pstmt.setInt(1, userId);
                            rs = pstmt.executeQuery();
                            
                            SimpleDateFormat sdfDisplay = new SimpleDateFormat("dd MMM yyyy, HH:mm");
                            
                            boolean hasTransactions = false;
                            
                            while (rs.next()) {
                                hasTransactions = true;
                                int transaksiId = rs.getInt("id");
                                double totalHarga = rs.getDouble("total_harga");
                                String metodePembayaran = rs.getString("metode_pembayaran");
                                String statusPembayaran = rs.getString("status_pembayaran");
                                String statusPesanan = rs.getString("status_pesanan");
                                Timestamp createdAt = rs.getTimestamp("created_at");
                                
                                String displayDate = sdfDisplay.format(createdAt);
                                
                                // Get product details for this transaction
                                PreparedStatement pstmtDetail = null;
                                ResultSet rsDetail =null;
                                                                pstmtDetail = conn.prepareStatement("SELECT dt.*, b.gambar FROM detail_transaksi dt " +
                                                                    "JOIN barang b ON dt.barang_id = b.id " +
                                                                    "WHERE dt.transaksi_id = ?");
                                pstmtDetail.setInt(1, transaksiId);
                                rsDetail = pstmtDetail.executeQuery();
                                
                                // Prepare to display transaction details
                        %>
                        
                        <div class="transaction-card">
                            <div class="transaction-header">
                                <div>
                                    <div class="transaction-id">
                                        <i class="fas fa-receipt"></i> Transaksi #<%= transaksiId %>
                                    </div>
                                    <div class="transaction-date">
                                        <i class="fas fa-calendar"></i> <%= displayDate %>
                                    </div>
                                </div>
                                <div class="d-flex gap-2 flex-wrap">
                                    <span class="status-badge payment-<%= statusPembayaran %>">
                                        <%= statusPembayaran.toUpperCase() %>
                                    </span>
                                    <span class="status-badge status-<%= statusPesanan %>">
                                        <%= statusPesanan.toUpperCase() %>
                                    </span>
                                </div>
                            </div>
                            
                            <div class="transaction-body">
<div class="transaction-details">
    <div class="detail-item">
        <div class="detail-label">Nama Barang</div>
        <div class="detail-value">
            <%
            while (rsDetail.next()) {
                String namaBarang = rsDetail.getString("nama_barang");
                String gambar = rsDetail.getString("gambar");
                int quantity = rsDetail.getInt("quantity");
            %>
<div class="product-info">
    <div class="product-details" style="justify-content: flex-start; text-align: left;">
        <img src="uploads/<%= gambar %>" alt="<%= namaBarang %>" class="item-image" onerror="this.src='https://via.placeholder.com/60x60?text=No+Image'">
        <span class="product-name" style="margin-left: 10px;"><%= namaBarang %> (x<%= quantity %>)</span>
    </div>
</div>
            <%
            }
            %>
        </div>
    </div>
    <div class="detail-item">
        <div class="detail-label">Total Pembayaran</div>
        <div class="detail-value total-amount">Rp <%= String.format("%,.0f", totalHarga) %></div>
    </div>
    <div class="detail-item">
        <div class="detail-label">Metode Pembayaran</div>
        <div class="detail-value">
            <i class="fas fa-<%= metodePembayaran.equals("transfer_bank") ? "university" : (metodePembayaran.equals("e_wallet") ? "mobile-alt" : "hand-holding-usd") %>"></i>
            <%= metodePembayaran.substring(0, 1).toUpperCase() + metodePembayaran.substring(1) %>
        </div>
    </div>
    <div class="detail-item">
        <div class="detail-label">Status Pengiriman</div>
        <div class="detail-value">
            <i class="fas fa-<%= statusPesanan.equals("pending") ? "clock" : (statusPesanan.equals("processing") ? "cog" : (statusPesanan.equals("shipped") ? "truck" : (statusPesanan.equals("delivered") ? "check-circle" : "times-circle"))) %>"></i>
            <%= statusPesanan.substring(0, 1).toUpperCase() + statusPesanan.substring(1) %>
        </div>
    </div>
</div>
                                
                                <div class="transaction-actions">
                                    <button class="btn btn-detail" onclick="showTransactionDetail(<%= transaksiId %>)">
                                        <i class="fas fa-eye"></i> Lihat Detail
                                    </button>
                                    <div class="ms-auto d-flex gap-2">
                                        <% if (statusPesanan.equals("pending")) { %>
                                        <button class="btn btn-cancel" onclick="cancelTransaction(<%= transaksiId %>)">
                                            <i class="fas fa-times"></i> Batalkan
                                        </button>
                                        <button class="btn btn-complete" onclick="window.location.href='selesaikanTransaksi.jsp?id=<%= transaksiId %>'">
                                            <i class="fas fa-money-bill-wave"></i> Bayar
                                        </button>
                                        <% } %>
                                        <% if (statusPesanan.equals("shipped")) { %>
                                        <button class="btn btn-complete" onclick="selesaikanTransaksi(<%= transaksiId %>)">
                                            <i class="fas fa-check-circle"></i> Selesaikan Pesanan
                                        </button>
                                        <% } %>
                                    </div>
                                </div>
                            </div>
                        </div>
                        
                        <%
                                // Close the detail result set and statement
                                rsDetail.close();
                                pstmtDetail.close();
                            }
                            
                            if (!hasTransactions) {
                        %>
                        
                        <div class="empty-state">
                            <i class="fas fa-receipt"></i>
                            <h4>Belum Ada Transaksi</h4>
                            <p>Anda belum memiliki riwayat transaksi. Mulai berbelanja sekarang!</p>
                            <a href="daftarBarang.jsp" class="btn btn-detail">
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

    <!-- Transaction Detail Modal -->
    <div class="modal fade" id="detailModal" tabindex="-1">
        <div class="modal-dialog modal-lg">
            <div class="modal-content">
                <div class="modal-header">
                    <h5 class="modal-title">
                        <i class="fas fa-receipt"></i> Detail Transaksi
                    </h5>
                    <button type="button" class="btn-close" data-bs-dismiss="modal"></button>
                </div>
                <div class="modal-body" id="modalBody">
                    <!-- Detail content will be loaded here -->
                </div>
                <div class="modal-footer">
                    <button type="button" class="btn btn-secondary" data-bs-dismiss="modal">Tutup</button>
                </div>
            </div>
        </div>
    </div>

    <script src="https://cdnjs.cloudflare.com/ajax/libs/bootstrap/5.0.2/js/bootstrap.bundle.min.js"></script>
    <script>
        // Show transaction detail
        function showTransactionDetail(transaksiId) {
            const xhr = new XMLHttpRequest();
            xhr.open('GET', 'getTransactionDetail.jsp?id=' + transaksiId, true);
            
            xhr.onload = function() {
                if (xhr.status === 200) {
                    document.getElementById('modalBody').innerHTML = xhr.responseText;
                    const modal = new bootstrap.Modal(document.getElementById('detailModal'));
                    modal.show();
                } else {
                    showMessage('Gagal memuat detail transaksi.', false);
                }
            };
            
            xhr.onerror = function() {
                showMessage('Terjadi kesalahan saat memuat detail.', false);
            };
            
            xhr.send();
        }

        // Cancel transaction
        function cancelTransaction(transaksiId) {
            if (!confirm('Yakin ingin membatalkan transaksi ini?')) {
                return;
            }
            
            const xhr = new XMLHttpRequest();
            xhr.open('POST', 'cancelTransaction.jsp', true);
            xhr.setRequestHeader('Content-Type', 'application/x-www-form-urlencoded');
            
            xhr.onload = function() {
                if (xhr.status === 200) {
                    const response = xhr.responseText.trim();
                    if (response === 'success') {
                        showMessage('Transaksi berhasil dibatalkan.', true);
                        setTimeout(() => {
                            location.reload();
                        }, 1500);
                    } else {
                        showMessage('Gagal membatalkan transaksi.', false);
                    }
                } else {
                    showMessage('Gagal menghubungi server.', false);
                }
            };
            
            xhr.onerror = function() {
                showMessage('Terjadi kesalahan jaringan.', false);
            };
            
            xhr.send('transaksiId=' + transaksiId);
        }

        // Complete transaction
        function selesaikanTransaksi(transaksiId) {
            if (!confirm('Anda yakin sudah menerima pesanan ini? Aksi ini tidak dapat dibatalkan.')) {
                return;
            }

            const xhr = new XMLHttpRequest();
            xhr.open('POST', 'selesaikanTransaksi.jsp', true);
            xhr.setRequestHeader('Content-Type', 'application/x-www-form-urlencoded');

            xhr.onload = function() {
                if (xhr.status === 200) {
                    const response = xhr.responseText.trim();
                    if (response === 'success') {
                        showMessage('Pesanan telah diselesaikan. Terima kasih!', true);
                        setTimeout(() => {
                            location.reload();
                        }, 1500);
                    } else {
                        showMessage('Gagal menyelesaikan pesanan. Silakan coba lagi.', false);
                    }
                } else {
                    showMessage('Gagal menghubungi server.', false);
                }
            };
            
            xhr.onerror = function() {
                showMessage('Terjadi kesalahan jaringan.', false);
            };
            
            xhr.send('transaksiId=' + transaksiId);
        }

        // Search transactions
        function searchTransaksi() {
            const searchInput = document.getElementById('searchInput').value.toLowerCase();
            const cards = document.querySelectorAll('.transaction-card');

            cards.forEach(card => {
                const transactionId = card.querySelector('.transaction-id').textContent.toLowerCase();
                const detailValues = card.querySelectorAll('.detail-value');
                let found = false;

                // Check transaction ID
                if (transactionId.includes(searchInput)) {
                    found = true;
                }

                // Check detail values (payment method, status, etc.)
                detailValues.forEach(detail => {
                    if (detail.textContent.toLowerCase().includes(searchInput)) {
                        found = true;
                    }
                });

                if (found || searchInput === '') {
                    card.style.display = 'block';
                } else {
                    card.style.display = 'none';
                }
            });
        }
        

        // Show message function
        function showMessage(message, isSuccess) {
            const messageDiv = document.getElementById('message');
            messageDiv.innerHTML = '<i class="fas fa-' + (isSuccess ? 'check-circle' : 'exclamation-triangle') + '"></i> ' + message;
            messageDiv.className = 'alert message ' + (isSuccess ? 'alert-success' : 'alert-danger');
            messageDiv.style.display = 'block';
            
            setTimeout(function() {
                messageDiv.style.display = 'none';
            }, 5000);
        }

        // Add event listener for Enter key in search input
        document.addEventListener('DOMContentLoaded', function() {
            const searchInput = document.getElementById('searchInput');
            if (searchInput) {
                searchInput.addEventListener('keypress', function(e) {
                    if (e.key === 'Enter') {
                        searchTransaksi();
                    }
                });
            }
        });
        // Complete transaction function - diperbaiki
function selesaikanTransaksi(transaksiId) {
    if (!confirm('Anda yakin sudah menerima pesanan ini? Aksi ini tidak dapat dibatalkan.')) {
        return;
    }

    // Show loading message
    showMessage('Memproses pesanan...', true);

    const xhr = new XMLHttpRequest();
    xhr.open('POST', 'completeTransaction.jsp', true);
    xhr.setRequestHeader('Content-Type', 'application/x-www-form-urlencoded');

    xhr.onload = function() {
        if (xhr.status === 200) {
            const response = xhr.responseText.trim();
            console.log('Server response:', response); // Debug log
            
            if (response === 'success') {
                showMessage('Pesanan telah diselesaikan. Terima kasih!', true);
                setTimeout(() => {
                    location.reload();
                }, 2000);
            } else if (response.startsWith('error:')) {
                const errorMsg = response.substring(6);
                showMessage('Gagal menyelesaikan pesanan: ' + errorMsg, false);
            } else {
                showMessage('Gagal menyelesaikan pesanan. Silakan coba lagi.', false);
            }
        } else {
            showMessage('Gagal menghubungi server. Status: ' + xhr.status, false);
        }
    };
    
    xhr.onerror = function() {
        showMessage('Terjadi kesalahan jaringan. Silakan periksa koneksi internet Anda.', false);
    };

    xhr.send('transaksiId=' + encodeURIComponent(transaksiId));
}

// Show transaction detail
function showTransactionDetail(transaksiId) {
    const xhr = new XMLHttpRequest();
    xhr.open('GET', 'getTransactionDetail.jsp?id=' + encodeURIComponent(transaksiId), true);
    
    xhr.onload = function() {
        if (xhr.status === 200) {
            document.getElementById('modalBody').innerHTML = xhr.responseText;
            const modal = new bootstrap.Modal(document.getElementById('detailModal'));
            modal.show();
        } else {
            showMessage('Gagal memuat detail transaksi.', false);
        }
    };
    
    xhr.onerror = function() {
        showMessage('Terjadi kesalahan saat memuat detail.', false);
    };
    
    xhr.send();
}

// Cancel transaction
function cancelTransaction(transaksiId) {
    if (!confirm('Yakin ingin membatalkan transaksi ini?')) {
        return;
    }
    
    showMessage('Membatalkan transaksi...', true);
    
    const xhr = new XMLHttpRequest();
    xhr.open('POST', 'cancelTransaction.jsp', true);
    xhr.setRequestHeader('Content-Type', 'application/x-www-form-urlencoded');
    
    xhr.onload = function() {
        if (xhr.status === 200) {
            const response = xhr.responseText.trim();
            if (response === 'success') {
                showMessage('Transaksi berhasil dibatalkan.', true);
                setTimeout(() => {
                    location.reload();
                }, 2000);
            } else if (response.startsWith('error:')) {
                const errorMsg = response.substring(6);
                showMessage('Gagal membatalkan transaksi: ' + errorMsg, false);
            } else {
                showMessage('Gagal membatalkan transaksi.', false);
            }
        } else {
            showMessage('Gagal menghubungi server.', false);
        }
    };
    
    xhr.onerror = function() {
        showMessage('Terjadi kesalahan jaringan.', false);
    };
    
    xhr.send('transaksiId=' + encodeURIComponent(transaksiId));
}

// Search transactions
function searchTransaksi() {
    const searchInput = document.getElementById('searchInput').value.toLowerCase();
    const cards = document.querySelectorAll('.transaction-card');

    cards.forEach(card => {
        const transactionId = card.querySelector('.transaction-id').textContent.toLowerCase();
        const detailValues = card.querySelectorAll('.detail-value');
        let found = false;

        // Check transaction ID
        if (transactionId.includes(searchInput)) {
            found = true;
        }

        // Check detail values (payment method, status, etc.)
        detailValues.forEach(detail => {
            if (detail.textContent.toLowerCase().includes(searchInput)) {
                found = true;
            }
        });

        if (found || searchInput === '') {
            card.style.display = 'block';
        } else {
            card.style.display = 'none';
        }
    });
}

// Show message function - diperbaiki
function showMessage(message, isSuccess) {
    let messageDiv = document.getElementById('message');
    
    // Create message div if it doesn't exist
    if (!messageDiv) {
        messageDiv = document.createElement('div');
        messageDiv.id = 'message';
        messageDiv.style.position = 'fixed';
        messageDiv.style.top = '20px';
        messageDiv.style.right = '20px';
        messageDiv.style.zIndex = '9999';
        messageDiv.style.maxWidth = '400px';
        document.body.appendChild(messageDiv);
    }
    
    messageDiv.innerHTML = '<i class="fas fa-' + (isSuccess ? 'check-circle' : 'exclamation-triangle') + '"></i> ' + message;
    messageDiv.className = 'alert message ' + (isSuccess ? 'alert-success' : 'alert-danger');
    messageDiv.style.display = 'block';
    
    setTimeout(function() {
        messageDiv.style.display = 'none';
    }, 5000);
}

// Add event listener for Enter key in search input
document.addEventListener('DOMContentLoaded', function() {
    const searchInput = document.getElementById('searchInput');
    if (searchInput) {
        searchInput.addEventListener('keypress', function(e) {
            if (e.key === 'Enter') {
                searchTransaksi();
            }
        });
    }
    
    // Add some debugging
    console.log('Transaction script loaded successfully');
});
    </script>
</body>
</html>