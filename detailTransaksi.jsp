<%-- detailTransaksi.jsp --%>
<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="java.sql.*" %>
<%@ page import="java.text.SimpleDateFormat" %>
<%@ page import="java.util.*" %>
<%@ page import="java.util.Date, java.text.SimpleDateFormat, java.util.Locale" %>

<%
    // Check authentication
    String username = (String) session.getAttribute("username");
    String userRole = (String) session.getAttribute("role");
    if (username == null || !"admin".equals(userRole)) {
        response.sendRedirect("login.html");
        return;
    }
    
    // Get transaction ID
    String transaksiIdStr = request.getParameter("id");
    if (transaksiIdStr == null) {
        response.sendRedirect("transaksi.jsp");
        return;
    }
    
    int transaksiId = Integer.parseInt(transaksiIdStr);
    
    // Database connection
    String url = "jdbc:mysql://localhost:3306/webcapstone";
    String user = "root";
    String dbpass = "";
    
    Map<String, Object> transaksi = null;
    Map<String, Object> buktiPembayaran = null;
    List<Map<String, Object>> detailItems = new ArrayList<>();
    
    try (Connection conn = DriverManager.getConnection(url, user, dbpass)) {
        Class.forName("com.mysql.cj.jdbc.Driver");
        
        // Get transaction with user info
        String sql = "SELECT t.*, u.nama, u.email FROM transaksi t " +
                    "JOIN user u ON t.user_id = u.id WHERE t.id = ?";
        try (PreparedStatement pstmt = conn.prepareStatement(sql)) {
            pstmt.setInt(1, transaksiId);
            try (ResultSet rs = pstmt.executeQuery()) {
                if (rs.next()) {
                    transaksi = new HashMap<>();
                    transaksi.put("id", rs.getInt("id"));
                    transaksi.put("user_id", rs.getInt("user_id"));
                    transaksi.put("nama", rs.getString("nama"));
                    transaksi.put("email", rs.getString("email"));
                    transaksi.put("total_harga", rs.getDouble("total_harga"));
                    transaksi.put("metode_pembayaran", rs.getString("metode_pembayaran"));
                    transaksi.put("status_pembayaran", rs.getString("status_pembayaran"));
                    transaksi.put("status_pesanan", rs.getString("status_pesanan"));
                    transaksi.put("alamat_pengiriman", rs.getString("alamat_pengiriman"));
                    transaksi.put("created_at", rs.getTimestamp("created_at"));
                }
            }
        }
        
        if (transaksi == null) {
            response.sendRedirect("transaksi.jsp");
            return;
        }
        
        // Get payment proof
        sql = "SELECT * FROM bukti_pembayaran WHERE transaksi_id = ?";
        try (PreparedStatement pstmt = conn.prepareStatement(sql)) {
            pstmt.setInt(1, transaksiId);
            try (ResultSet rs = pstmt.executeQuery()) {
                if (rs.next()) {
                    buktiPembayaran = new HashMap<>();
                    buktiPembayaran.put("bukti_transfer", rs.getString("bukti_transfer"));
                    buktiPembayaran.put("nomor_rekening", rs.getString("nomor_rekening"));
                    buktiPembayaran.put("nama_pengirim", rs.getString("nama_pengirim"));
                    buktiPembayaran.put("tanggal_transfer", rs.getTimestamp("tanggal_transfer"));
                    buktiPembayaran.put("catatan", rs.getString("catatan"));
                    buktiPembayaran.put("status_verifikasi", rs.getString("status_verifikasi"));
                }
            }
        }
        
        // Get transaction items
        sql = "SELECT dt.*, b.gambar FROM detail_transaksi dt " +
              "LEFT JOIN barang b ON dt.barang_id = b.id " +
              "WHERE dt.transaksi_id = ?";
        try (PreparedStatement pstmt = conn.prepareStatement(sql)) {
            pstmt.setInt(1, transaksiId);
            try (ResultSet rs = pstmt.executeQuery()) {
                while (rs.next()) {
                    Map<String, Object> item = new HashMap<>();
                    item.put("nama_barang", rs.getString("nama_barang"));
                    item.put("harga", rs.getDouble("harga"));
                    item.put("quantity", rs.getInt("quantity"));
                    item.put("subtotal", rs.getDouble("subtotal"));
                    item.put("gambar", rs.getString("gambar"));
                    detailItems.add(item);
                }
            }
        }
        
    } catch(Exception e) {
        out.println("<!-- Error: " + e.getMessage() + " -->");
        response.sendRedirect("transaksi.jsp");
        return;
    }
    
    SimpleDateFormat sdf = new SimpleDateFormat("dd MMM yyyy, HH:mm", new Locale("id", "ID"));
%>

<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Detail Transaksi #<%= transaksiId %></title>
    <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.5.0/css/all.min.css"/>
    <link href="https://cdnjs.cloudflare.com/ajax/libs/bootstrap/5.0.2/css/bootstrap.min.css" rel="stylesheet">
    <style>
        :root {
            --primary: #2f6c3b;
            --primary-hover: #255b30;
            --sidebar-bg: #343a40;
            --sidebar-text: #ffffff;
            --success: #28a745;
            --danger: #dc3545;
            --warning: #ffc107;
            --info: #17a2b8;
        }

        * { margin: 0; padding: 0; box-sizing: border-box; }

        body {
            font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
            background: #f8f9fa;
            display: flex;
            min-height: 100vh;
        }

        /* Sidebar */
        .sidebar {
            background: var(--sidebar-bg);
            width: 250px;
            color: var(--sidebar-text);
            position: fixed;
            height: 100vh;
            overflow-y: auto;
            z-index: 1000;
        }

        .sidebar-header {
            padding: 20px;
            font-size: 24px;
            font-weight: bold;
            text-align: center;
            border-bottom: 1px solid rgba(255, 255, 255, 0.1);
        }

        .sidebar-menu { margin-top: 20px; }

        .sidebar-menu a {
            display: flex;
            align-items: center;
            padding: 15px 20px;
            color: var(--sidebar-text);
            text-decoration: none;
            transition: all 0.3s;
        }

        .sidebar-menu a:hover, .sidebar-menu a.active {
            background: rgba(255, 255, 255, 0.1);
            border-left: 4px solid var(--primary);
        }

        .sidebar-menu i { margin-right: 10px; width: 20px; }

        /* Main Content */
        .main-content {
            flex: 1;
            margin-left: 250px;
            padding: 20px;
        }

        .header {
            background: white;
            padding: 20px;
            border-radius: 10px;
            box-shadow: 0 2px 10px rgba(0,0,0,0.1);
            margin-bottom: 20px;
            display: flex;
            justify-content: space-between;
            align-items: center;
        }

        .section {
            background: white;
            border-radius: 10px;
            box-shadow: 0 2px 10px rgba(0,0,0,0.1);
            padding: 25px;
            margin-bottom: 20px;
        }

        .section-title {
            color: var(--primary);
            font-size: 20px;
            font-weight: 600;
            margin-bottom: 20px;
            display: flex;
            align-items: center;
            gap: 10px;
            border-bottom: 2px solid var(--primary);
            padding-bottom: 10px;
        }

        .info-grid {
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(250px, 1fr));
            gap: 20px;
        }

        .info-item {
            background: #f8f9fa;
            padding: 15px;
            border-radius: 8px;
            border-left: 4px solid var(--primary);
        }

        .info-label {
            font-size: 0.9rem;
            color: #6c757d;
            margin-bottom: 5px;
            font-weight: 500;
        }

        .info-value {
            font-weight: 600;
            color: #333;
        }

        .status-badge {
            padding: 6px 12px;
            border-radius: 20px;
            font-size: 0.8rem;
            font-weight: 600;
            text-transform: uppercase;
        }

        .status-pending { background: #fff3cd; color: #856404; }
        .status-processing { background: #cce5ff; color: #004085; }
        .status-shipped { background: #d1ecf1; color: #0c5460; }
        .status-delivered { background: #d4edda; color: #155724; }
        .status-cancelled { background: #f8d7da; color: #721c24; }
        .payment-pending { background: #fff3cd; color: #856404; }
        .payment-paid { background: #d4edda; color: #155724; }
        .payment-approved { background: #d4edda; color: #155724; }
        .payment-failed { background: #f8d7da; color: #721c24; }
        .payment-rejected { background: #f8d7da; color: #721c24; }

        .table-responsive {
            overflow-x: auto;
            margin-top: 15px;
        }

        .table {
            margin-bottom: 0;
        }

        .table th {
            background: #f8f9fa;
            color: var(--primary);
            font-weight: 600;
        }

        .proof-container {
            text-align: center;
            margin-top: 15px;
        }

        .proof-image {
            max-width: 100%;
            max-height: 400px;
            border-radius: 10px;
            box-shadow: 0 4px 15px rgba(0,0,0,0.1);
            cursor: pointer;
            transition: transform 0.3s;
            border: 2px solid #e9ecef;
        }

        .proof-image:hover { 
            transform: scale(1.02); 
            border-color: var(--primary);
        }

        .no-proof {
            color: #6c757d;
            font-style: italic;
            padding: 20px;
            text-align: center;
            background: #f8f9fa;
            border-radius: 8px;
            border: 2px dashed #dee2e6;
        }

        .btn {
            border-radius: 8px;
            padding: 10px 20px;
            font-size: 0.9rem;
            font-weight: 600;
            transition: all 0.3s;
        }

        .btn-primary { background: var(--primary); border-color: var(--primary); }
        .btn-primary:hover { background: var(--primary-hover); border-color: var(--primary-hover); }
        .btn-success:hover { background: #1e7e34; }
        .btn-danger:hover { background: #c82333; }
        .btn-info:hover { background: #138496; }
        .btn-secondary:hover { background: #5a6268; }

        .modal-content {
            border-radius: 15px;
            box-shadow: 0 10px 30px rgba(0,0,0,0.3);
        }

        .modal-header {
            background: var(--primary);
            color: white;
            border-top-left-radius: 15px;
            border-top-right-radius: 15px;
        }

        .modal-footer {
            border-top: 1px solid #e9ecef;
        }

        .action-buttons {
            display: flex;
            flex-wrap: wrap;
            gap: 10px;
            margin-top: 20px;
            padding-top: 20px;
            border-top: 1px solid #e9ecef;
        }

        /* Image Modal Styles */
        .modal-lg {
            max-width: 90vw;
        }

        .modal-body img {
            max-width: 100%;
            max-height: 80vh;
            object-fit: contain;
        }

        .image-actions {
            margin-top: 15px;
            display: flex;
            justify-content: center;
            gap: 10px;
        }

        .download-btn {
            background: var(--primary);
            color: white;
            border: none;
            padding: 8px 16px;
            border-radius: 5px;
            text-decoration: none;
            display: inline-flex;
            align-items: center;
            gap: 5px;
            transition: background 0.3s;
        }

        .download-btn:hover {
            background: var(--primary-hover);
            color: white;
        }

        /* Product image in table */
        .product-image {
            width: 50px;
            height: 50px;
            object-fit: cover;
            border-radius: 5px;
            border: 1px solid #dee2e6;
        }

        /* Responsive */
        @media (max-width: 768px) {
            .sidebar {
                transform: translateX(-100%);
                transition: transform 0.3s;
            }
            
            .sidebar.active {
                transform: translateX(0);
            }
            
            .main-content {
                margin-left: 0;
            }

            .info-grid {
                grid-template-columns: 1fr;
            }

            .header {
                flex-direction: column;
                gap: 15px;
                text-align: center;
            }

            .action-buttons {
                justify-content: center;
            }

            .modal-lg {
                max-width: 95vw;
            }
        }

        .mobile-menu-btn {
            display: none;
            position: fixed;
            top: 20px;
            left: 20px;
            z-index: 1001;
            background: var(--primary);
            color: white;
            border: none;
            padding: 10px;
            border-radius: 5px;
        }

        @media (max-width: 768px) {
            .mobile-menu-btn {
                display: block;
            }
        }

        /* Alert styles */
        .alert {
            border-radius: 8px;
            margin-bottom: 20px;
        }

        .verification-status {
            padding: 10px;
            border-radius: 8px;
            margin-bottom: 15px;
            font-weight: 500;
        }

        .verification-pending {
            background: #fff3cd;
            color: #856404;
            border: 1px solid #ffeaa7;
        }

        .verification-approved {
            background: #d4edda;
            color: #155724;
            border: 1px solid #c3e6cb;
        }

        .verification-rejected {
            background: #f8d7da;
            color: #721c24;
            border: 1px solid #f5c6cb;
        }
    </style>
</head>
<body>
    <!-- Mobile Menu Button -->
    <button class="mobile-menu-btn" onclick="toggleSidebar()">
        <i class="fas fa-bars"></i>
    </button>

    <!-- Sidebar -->
    <div class="sidebar" id="sidebar">
        <div class="sidebar-header">Dashboard</div>
        <div class="sidebar-menu">
            <a href="dashboard.jsp"><i class="fas fa-home"></i> Home</a>
            <a href="data-register.jsp"><i class="fas fa-users"></i> Data Register</a>
            <a href="MasterBarang.jsp"><i class="fas fa-boxes"></i> Master Barang</a>
            <a href="transaksi.jsp" class="active"><i class="fas fa-receipt"></i> Transaksi</a>
        </div>
    </div>

    <!-- Main Content -->
    <div class="main-content">
        <div class="header">
            <h1><i class="fas fa-file-invoice-dollar"></i> Detail Transaksi #<%= transaksiId %></h1>
            <a href="transaksi.jsp" class="btn btn-primary">
                <i class="fas fa-arrow-left"></i> Kembali
            </a>
        </div>

        <!-- Transaction Info -->
        <div class="section">
            <h2 class="section-title">
                <i class="fas fa-info-circle"></i> Informasi Transaksi
            </h2>
            
            <div class="info-grid">
                <div class="info-item">
                    <div class="info-label">ID Transaksi</div>
                    <div class="info-value">#<%= transaksi.get("id") %></div>
                </div>
                <div class="info-item">
                    <div class="info-label">Nama Pelanggan</div>
                    <div class="info-value"><%= transaksi.get("nama") %></div>
                </div>
                <div class="info-item">
                    <div class="info-label">Email</div>
                    <div class="info-value"><%= transaksi.get("email") %></div>
                </div>
                <div class="info-item">
                    <div class="info-label">Total Harga</div>
                    <div class="info-value" style="color: var(--primary); font-size: 1.2rem;">
                        Rp <%= String.format("%,.0f", (Double)transaksi.get("total_harga")) %>
                    </div>
                </div>
                <div class="info-item">
                    <div class="info-label">Metode Pembayaran</div>
                    <div class="info-value"><%= ((String)transaksi.get("metode_pembayaran")).replace("_", " ").toUpperCase() %></div>
                </div>
                <div class="info-item">
                    <div class="info-label">Status Pembayaran</div>
                    <div class="info-value">
                        <span class="status-badge payment-<%= transaksi.get("status_pembayaran") %>">
                            <%= ((String)transaksi.get("status_pembayaran")).toUpperCase() %>
                        </span>
                    </div>
                </div>
                <div class="info-item">
                    <div class="info-label">Status Pesanan</div>
                    <div class="info-value">
                        <span class="status-badge status-<%= transaksi.get("status_pesanan") %>">
                            <%= ((String)transaksi.get("status_pesanan")).toUpperCase() %>
                        </span>
                    </div>
                </div>
                <div class="info-item">
                    <div class="info-label">Tanggal Transaksi</div>
                    <div class="info-value"><%= sdf.format((Timestamp)transaksi.get("created_at")) %></div>
                </div>
            </div>

            <div class="info-item mt-3">
                <div class="info-label">Alamat Pengiriman</div>
                <div class="info-value"><%= transaksi.get("alamat_pengiriman") %></div>
            </div>
        </div>

        <!-- Transaction Items -->
        <div class="section">
            <h2 class="section-title">
                <i class="fas fa-shopping-cart"></i> Detail Barang
            </h2>
            
            <div class="table-responsive">
                <table class="table table-striped">
                    <thead>
                        <tr>
                            <th>Gambar</th>
                            <th>Nama Barang</th>
                            <th>Harga Satuan</th>
                            <th>Quantity</th>
                            <th>Subtotal</th>
                        </tr>
                    </thead>
                    <tbody>
                        <% for (Map<String, Object> item : detailItems) { %>
                        <tr>
                            <td>
                                <% if (item.get("gambar") != null && !((String)item.get("gambar")).isEmpty()) { %>
                                <img src="uploads/<%= item.get("gambar") %>" 
                                     alt="<%= item.get("nama_barang") %>" 
                                     class="product-image"
                                     onclick="showImageModal('uploads/<%= item.get("gambar") %>', '<%= item.get("nama_barang") %>')">
                                <% } else { %>
                                <div class="product-image d-flex align-items-center justify-content-center bg-light">
                                    <i class="fas fa-image text-muted"></i>
                                </div>
                                <% } %>
                            </td>
                            <td><%= item.get("nama_barang") %></td>
                            <td>Rp <%= String.format("%,.0f", (Double)item.get("harga")) %></td>
                            <td><%= item.get("quantity") %></td>
                            <td>Rp <%= String.format("%,.0f", (Double)item.get("subtotal")) %></td>
                        </tr>
                        <% } %>
                    </tbody>
                    <tfoot>
                        <tr class="table-primary">
                            <th colspan="4" class="text-end">Total:</th>
                            <th>Rp <%= String.format("%,.0f", (Double)transaksi.get("total_harga")) %></th>
                        </tr>
                    </tfoot>
                </table>
            </div>
        </div>

        <!-- Payment Proof -->
        <% if ("transfer_bank".equals(transaksi.get("metode_pembayaran"))) { %>
        <div class="section">
            <h2 class="section-title">
                <i class="fas fa-file-image"></i> Bukti Pembayaran
            </h2>
            
            <% if (buktiPembayaran != null) { %>
            
            <!-- Verification Status -->
            <div class="verification-status verification-<%= buktiPembayaran.get("status_verifikasi") %>">
                <i class="fas fa-info-circle"></i>
                Status Verifikasi: <strong><%= ((String)buktiPembayaran.get("status_verifikasi")).toUpperCase() %></strong>
                <% if ("pending".equals(buktiPembayaran.get("status_verifikasi"))) { %>
                - Menunggu verifikasi admin
                <% } else if ("approved".equals(buktiPembayaran.get("status_verifikasi"))) { %>
                - Pembayaran telah diverifikasi dan disetujui
                <% } else if ("rejected".equals(buktiPembayaran.get("status_verifikasi"))) { %>
                - Pembayaran ditolak, silakan upload ulang bukti yang valid
                <% } %>
            </div>

            <div class="info-grid">
                <div class="info-item">
                    <div class="info-label">Nama Pengirim</div>
                    <div class="info-value"><%= buktiPembayaran.get("nama_pengirim") != null ? buktiPembayaran.get("nama_pengirim") : "-" %></div>
                </div>
                <div class="info-item">
                    <div class="info-label">Nomor Rekening</div>
                    <div class="info-value"><%= buktiPembayaran.get("nomor_rekening") != null ? buktiPembayaran.get("nomor_rekening") : "-" %></div>
                </div>
                <div class="info-item">
                    <div class="info-label">Tanggal Transfer</div>
                    <div class="info-value">
                        <%= buktiPembayaran.get("tanggal_transfer") != null ? 
                            sdf.format((Timestamp)buktiPembayaran.get("tanggal_transfer")) : "-" %>
                    </div>
                </div>
                <div class="info-item">
                    <div class="info-label">Status Verifikasi</div>
                    <div class="info-value">
                        <span class="status-badge payment-<%= buktiPembayaran.get("status_verifikasi") %>">
                            <%= ((String)buktiPembayaran.get("status_verifikasi")).toUpperCase() %>
                        </span>
                    </div>
                </div>
            </div>

            <% if (buktiPembayaran.get("catatan") != null && !((String)buktiPembayaran.get("catatan")).trim().isEmpty()) { %>
            <div class="info-item mt-3">
                <div class="info-label">Catatan</div>
                <div class="info-value"><%= buktiPembayaran.get("catatan") %></div>
            </div>
            <% } %>

            <div class="proof-container">
                <% if (buktiPembayaran.get("bukti_transfer") != null && !((String)buktiPembayaran.get("bukti_transfer")).trim().isEmpty()) { %>
                <div class="mb-3">
                    <strong>Bukti Transfer:</strong>
                </div>
                <img src="uploads/<%= buktiPembayaran.get("bukti_transfer") %>" 
                     alt="Bukti Pembayaran" 
                     class="proof-image"
                     onclick="showImageModal('uploads/<%= buktiPembayaran.get("bukti_transfer") %>', 'Bukti Pembayaran')">
                <div class="image-actions">
                    <p class="text-muted mb-2">
                        <i class="fas fa-click"></i> Klik gambar untuk memperbesar
                    </p>
                    <a href="uploads/<%= buktiPembayaran.get("bukti_transfer") %>" 
                       download="bukti_pembayaran_<%= transaksiId %>.jpg" 
                       class="download-btn">
                        <i class="fas fa-download"></i> Download
                    </a>
                </div>
                <% } else { %>
                <div class="no-proof">
                    <i class="fas fa-image fa-3x mb-3"></i><br>
                    <strong>Bukti transfer tidak tersedia</strong><br>
                    <small>File bukti transfer belum diupload atau tidak ditemukan</small>
                </div>
                <% } %>
            </div>

            <!-- Payment Actions -->
            <% if ("pending".equals(buktiPembayaran.get("status_verifikasi")) && 
                   "pending".equals(transaksi.get("status_pembayaran"))) { %>
            <div class="action-buttons">
                <button class="btn btn-success" onclick="showConfirmModal('approve_payment', <%= transaksiId %>, 'Setujui Pembayaran', 'Apakah Anda yakin ingin menyetujui pembayaran ini? Status pembayaran akan berubah menjadi PAID.')">
                    <i class="fas fa-check"></i> Setujui Pembayaran
                </button>
                <button class="btn btn-danger" onclick="showConfirmModal('reject_payment', <%= transaksiId %>, 'Tolak Pembayaran', 'Apakah Anda yakin ingin menolak pembayaran ini? Pelanggan perlu mengupload ulang bukti pembayaran.')">
                    <i class="fas fa-times"></i> Tolak Pembayaran
                </button>
            </div>
            <% } %>

            <% } else { %>
            <div class="no-proof">
                <i class="fas fa-upload fa-3x mb-3"></i><br>
                <strong>Pelanggan belum mengupload bukti pembayaran</strong><br>
                <small>Menunggu pelanggan untuk mengupload bukti transfer</small>
            </div>
            <% } %>
        </div>
        <% } %>

        <!-- Order Management -->
        <div class="section">
            <h2 class="section-title">
                <i class="fas fa-cogs"></i> Kelola Pesanan
            </h2>
            
            <div class="row">
                <div class="col-md-6">
                    <h5>Status Saat Ini:</h5>
                    <p><strong>Pembayaran:</strong> 
                        <span class="status-badge payment-<%= transaksi.get("status_pembayaran") %>">
                            <%= ((String)transaksi.get("status_pembayaran")).toUpperCase() %>
                        </span>
                    </p>
                    <p><strong>Pesanan:</strong> 
                        <span class="status-badge status-<%= transaksi.get("status_pesanan") %>">
                            <%= ((String)transaksi.get("status_pesanan")).toUpperCase() %>
                        </span>
                    </p>
                </div>
                <div class="col-md-6">
                    <h5>Aksi yang Tersedia:</h5>
                    <div class="action-buttons">
                        <% 
                        String statusPembayaran = (String)transaksi.get("status_pembayaran");
                        String statusPesanan = (String)transaksi.get("status_pesanan");
                        %>
                        
                        <% if ("paid".equals(statusPembayaran) && "pending".equals(statusPesanan)) { %>
                        <button class="btn btn-info" onclick="showConfirmModal('process_order', <%= transaksiId %>, 'Proses Pesanan', 'Mulai memproses pesanan ini?')">
                            <i class="fas fa-cog"></i> Proses Pesanan
                        </button>
                        <% } %>

                        <% if ("paid".equals(statusPembayaran) && "processing".equals(statusPesanan)) { %>
                        <button class="btn btn-info" onclick="showConfirmModal('ship_order', <%= transaksiId %>, 'Kirim Pesanan', 'Kirim pesanan ini ke pelanggan?')">
                            <i class="fas fa-shipping-fast"></i> Kirim Pesanan
                        </button>
                        <% } %>

                        <% if ("shipped".equals(statusPesanan)) { %>
                        <button class="btn btn-primary" onclick="showConfirmModal('deliver_order', <%= transaksiId %>, 'Pesanan Terkirim', 'Tandai pesanan sebagai terkirim?')">
                            <i class="fas fa-check-circle"></i> Pesanan Terkirim
                        </button>
                        <% } %>

                        <% if (!"delivered".equals(statusPesanan) && !"cancelled".equals(statusPesanan)) { %>
                        <button class="btn btn-secondary" onclick="showConfirmModal('cancel_order', <%= transaksiId %>, 'Batalkan Pesanan', 'Batalkan pesanan ini? Tindakan ini tidak dapat dibatalkan.')">
                            <i class="fas fa-ban"></i> Batalkan Pesanan
                        </button>
                        <% } %>

                        <% if ("delivered".equals(statusPesanan) || "cancelled".equals(statusPesanan)) { %>
                        <div class="alert alert-info">
                            <i class="fas fa-info-circle"></i>
                            Pesanan sudah selesai. Tidak ada aksi yang tersedia.
                        </div>
                        <% } %>
                    </div>
                </div>
            </div>
        </div>

    <!-- Image Modal -->
    <div class="modal fade" id="imageModal" tabindex="-1">
        <div class="modal-dialog modal-lg modal-dialog-centered">
            <div class="modal-content">
                <div class="modal-header">
                    <h5 class="modal-title" id="imageModalTitle">Lihat Gambar</h5>
                    <button type="button" class="btn-close btn-close-white" data-bs-dismiss="modal"></button>
                </div>
                <div class="modal-body text-center">
                    <img id="modalImage" src="" alt="" class="img-fluid">
                    <div class="image-actions mt-3">
                        <a id="downloadLink" href="" download="" class="download-btn">
                            <i class="fas fa-download"></i> Download Gambar
                        </a>
                        <button type="button" class="btn btn-secondary ms-2" onclick="openImageInNewTab()">
                            <i class="fas fa-external-link-alt"></i> Buka di Tab Baru
                        </button>
                    </div>
                </div>
            </div>
        </div>
    </div>

    <!-- Confirmation Modal -->
    <div class="modal fade" id="confirmModal" tabindex="-1">
        <div class="modal-dialog modal-dialog-centered">
            <div class="modal-content">
                <div class="modal-header">
                    <h5 class="modal-title" id="confirmTitle"></h5>
                    <button type="button" class="btn-close btn-close-white" data-bs-dismiss="modal"></button>
                </div>
                <div class="modal-body">
                    <p id="confirmMessage"></p>
                </div>
                <div class="modal-footer">
                    <button type="button" class="btn btn-secondary" data-bs-dismiss="modal">Batal</button>
                    <button type="button" class="btn btn-primary" id="confirmButton">Konfirmasi</button>
                </div>
            </div>
        </div>
    </div>

    <!-- Form for Actions -->
    <form id="actionForm" method="POST" action="processTransaksi.jsp" style="display: none;">
        <input type="hidden" name="action" id="actionType">
        <input type="hidden" name="transaksi_id" id="actionTransaksiId">
    </form>

    <script src="https://cdnjs.cloudflare.com/ajax/libs/bootstrap/5.0.2/js/bootstrap.bundle.min.js"></script>
    <script>
        // Initialize modals
        const imageModal = new bootstrap.Modal(document.getElementById('imageModal'));
        const confirmModal = new bootstrap.Modal(document.getElementById('confirmModal'));
        
        let currentImageSrc = '';

        // Show image modal
        function showImageModal(imageSrc, title = 'Lihat Gambar') {
            currentImageSrc = imageSrc;
            document.getElementById('modalImage').src = imageSrc;
            document.getElementById('imageModalTitle').textContent = title;
            document.getElementById('downloadLink').href = imageSrc;
            
            // Set download filename
            const filename = imageSrc.split('/').pop();
            document.getElementById('downloadLink').download = filename;
            
            imageModal.show();
        }

        // Open image in new tab
        function openImageInNewTab() {
            if (currentImageSrc) {
                window.open(currentImageSrc, '_blank');
            }
        }

        // Show confirmation modal
        function showConfirmModal(action, transaksiId, title, message) {
            document.getElementById('confirmTitle').textContent = title;
            document.getElementById('confirmMessage').textContent = message;
            document.getElementById('actionType').value = action;
            document.getElementById('actionTransaksiId').value = transaksiId;
            
            // Set button color based on action
            const confirmBtn = document.getElementById('confirmButton');
            confirmBtn.className = 'btn ';
            
            switch(action) {
                case 'approve_payment':
                case 'process_order':
                case 'deliver_order':
                    confirmBtn.className += 'btn-success';
                    break;
                case 'ship_order':
                    confirmBtn.className += 'btn-info';
                    break;
                case 'reject_payment':
                case 'cancel_order':
                    confirmBtn.className += 'btn-danger';
                    break;
                default:
                    confirmBtn.className += 'btn-primary';
            }
            
            confirmBtn.onclick = function() {
                document.getElementById('actionForm').submit();
            };
            
            confirmModal.show();
        }

        // Toggle sidebar for mobile
        function toggleSidebar() {
            document.getElementById('sidebar').classList.toggle('active');
        }

        // Close sidebar when clicking outside on mobile
        document.addEventListener('click', function(e) {
            const sidebar = document.getElementById('sidebar');
            const menuBtn = document.querySelector('.mobile-menu-btn');
            
            if (window.innerWidth <= 768) {
                if (!sidebar.contains(e.target) && !menuBtn.contains(e.target)) {
                    sidebar.classList.remove('active');
                }
            }
        });

        // Handle window resize
        window.addEventListener('resize', function() {
            if (window.innerWidth > 768) {
                document.getElementById('sidebar').classList.remove('active');
            }
        });

        // Image error handling
        document.addEventListener('DOMContentLoaded', function() {
            const images = document.querySelectorAll('img');
            images.forEach(img => {
                img.onerror = function() {
                    this.style.display = 'none';
                    const parent = this.parentElement;
                    if (parent) {
                        const placeholder = document.createElement('div');
                        placeholder.className = 'product-image d-flex align-items-center justify-content-center bg-light';
                        placeholder.innerHTML = '<i class="fas fa-image text-muted"></i>';
                        parent.appendChild(placeholder);
                    }
                };
            });
        });
    </script>

    <style>
        /* Print styles */
        @media print {
            .sidebar, .mobile-menu-btn, .action-buttons, .btn {
                display: none !important;
            }
            
            .main-content {
                margin-left: 0 !important;
            }
            
            .section {
                box-shadow: none !important;
                border: 1px solid #dee2e6 !important;
            }
        }
    </style>
</body>
</html>