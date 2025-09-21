<%-- transaksi.jsp --%>
<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="java.sql.*" %>
<%@ page import="java.text.SimpleDateFormat" %>
<%@ page import="java.util.*" %>
<%@ page import="java.util.Date, java.text.SimpleDateFormat, java.util.Locale" %>

<%
    // Check if user is logged in and is admin
    String username = (String) session.getAttribute("username");
    String userRole = (String) session.getAttribute("role");
    if (username == null || !"admin".equals(userRole)) {
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
    
    List<Map<String, Object>> transaksiList = new ArrayList<>();
    
    // Handle POST requests for status updates
    if ("POST".equals(request.getMethod())) {
        String action = request.getParameter("action");
        String transaksiId = request.getParameter("transaksi_id");
        
        if (action != null && transaksiId != null) {
            try {
                Class.forName("com.mysql.cj.jdbc.Driver");
                conn = DriverManager.getConnection(url, user, dbpass);
                
                if ("approve_payment".equals(action)) {
                    // Update payment status to paid and order status to processing
                    String updateSql = "UPDATE transaksi SET status_pembayaran = 'paid', status_pesanan = 'processing' WHERE id = ?";
                    pstmt = conn.prepareStatement(updateSql);
                    pstmt.setInt(1, Integer.parseInt(transaksiId));
                    pstmt.executeUpdate();
                    pstmt.close();
                    
                    // Update bukti pembayaran verification
                    String updateBuktiSql = "UPDATE bukti_pembayaran SET status_verifikasi = 'approved', verified_by = (SELECT id FROM user WHERE nama = ? LIMIT 1), verified_at = NOW() WHERE transaksi_id = ?";
                    pstmt = conn.prepareStatement(updateBuktiSql);
                    pstmt.setString(1, username);
                    pstmt.setInt(2, Integer.parseInt(transaksiId));
                    pstmt.executeUpdate();
                    
                } else if ("reject_payment".equals(action)) {
                    // Update payment status to failed and order status to cancelled
                    String updateSql = "UPDATE transaksi SET status_pembayaran = 'failed', status_pesanan = 'cancelled' WHERE id = ?";
                    pstmt = conn.prepareStatement(updateSql);
                    pstmt.setInt(1, Integer.parseInt(transaksiId));
                    pstmt.executeUpdate();
                    pstmt.close();
                    
                    // Update bukti pembayaran verification
                    String updateBuktiSql = "UPDATE bukti_pembayaran SET status_verifikasi = 'rejected', verified_by = (SELECT id FROM user WHERE nama = ? LIMIT 1), verified_at = NOW() WHERE transaksi_id = ?";
                    pstmt = conn.prepareStatement(updateBuktiSql);
                    pstmt.setString(1, username);
                    pstmt.setInt(2, Integer.parseInt(transaksiId));
                    pstmt.executeUpdate();
                    
                } else if ("ship_order".equals(action)) {
                    String updateSql = "UPDATE transaksi SET status_pesanan = 'shipped' WHERE id = ?";
                    pstmt = conn.prepareStatement(updateSql);
                    pstmt.setInt(1, Integer.parseInt(transaksiId));
                    pstmt.executeUpdate();
                    
                } else if ("deliver_order".equals(action)) {
                    String updateSql = "UPDATE transaksi SET status_pesanan = 'delivered' WHERE id = ?";
                    pstmt = conn.prepareStatement(updateSql);
                    pstmt.setInt(1, Integer.parseInt(transaksiId));
                    pstmt.executeUpdate();
                    
                } else if ("cancel_order".equals(action)) {
                    String updateSql = "UPDATE transaksi SET status_pesanan = 'cancelled' WHERE id = ?";
                    pstmt = conn.prepareStatement(updateSql);
                    pstmt.setInt(1, Integer.parseInt(transaksiId));
                    pstmt.executeUpdate();
                }
                
                if (pstmt != null) pstmt.close();
                if (conn != null) conn.close();
                
                // Redirect to avoid form resubmission
                response.sendRedirect("transaksi.jsp");
                return;
                
            } catch (Exception e) {
                out.println("<!-- Error updating transaction: " + e.getMessage() + " -->");
            }
        }
    }
%>

<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>Admin - Kelola Transaksi</title>
  <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.5.0/css/all.min.css"/>
  <link href="https://cdnjs.cloudflare.com/ajax/libs/bootstrap/5.0.2/css/bootstrap.min.css" rel="stylesheet">
  <style>
    :root {
      --primary-color: #2f6c3b;
      --hover-color: #255b30;
      --sidebar-bg: #343a40;
      --sidebar-text: #ffffff;
      --transition: all 0.3s ease;
    }

    * {
      margin: 0;
      padding: 0;
      box-sizing: border-box;
    }

    body {
      font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
      background-color: #f2f2f2;
      display: flex;
      min-height: 100vh;
    }

    /* Sidebar */
    .sidebar {
      background-color: var(--sidebar-bg);
      width: 250px;
      color: var(--sidebar-text);
      display: flex;
      flex-direction: column;
      position: fixed;
      height: 100vh;
      overflow-y: auto;
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
      transition: var(--transition);
    }

    .sidebar-menu a:hover, .sidebar-menu a.active {
      background-color: rgba(255, 255, 255, 0.1);
      border-left: 4px solid var(--primary-color);
    }

    .sidebar-menu i {
      margin-right: 10px;
      width: 20px;
      text-align: center;
    }

    /* Main Content */
    .main-content {
      flex-grow: 1;
      margin-left: 250px;
      padding: 20px;
      background-color: #f8f9fa;
    }

    .header {
      display: flex;
      justify-content: space-between;
      align-items: center;
      margin-bottom: 30px;
      background: white;
      padding: 20px;
      border-radius: 10px;
      box-shadow: 0 2px 10px rgba(0, 0, 0, 0.1);
    }

    .welcome-text {
      font-size: 28px;
      color: #333;
      font-weight: 600;
    }

    /* Header Actions */
    .header-actions {
      display: flex;
      align-items: center;
      gap: 10px;
    }

    .export-btn {
      background-color: #28a745;
      color: white;
      border: none;
      border-radius: 8px;
      padding: 10px 15px;
      cursor: pointer;
      transition: background-color 0.3s;
      font-size: 14px;
      text-decoration: none;
      display: inline-flex;
      align-items: center;
      gap: 5px;
    }

    .export-btn:hover {
      background-color: #218838;
      color: white;
      text-decoration: none;
    }

    .export-btn.pdf {
      background-color: #dc3545;
    }

    .export-btn.pdf:hover {
      background-color: #c82333;
    }

    .logout-btn {
      background-color: #dc3545;
      color: white;
      border: none;
      border-radius: 8px;
      padding: 10px 20px;
      cursor: pointer;
      transition: background-color 0.3s;
      font-size: 14px;
    }

    .logout-btn:hover {
      background-color: #5a6268;
    }

    /* Transaction Cards */
    .transaction-section {
      background: white;
      border-radius: 10px;
      box-shadow: 0 2px 10px rgba(0, 0, 0, 0.1);
      padding: 25px;
    }

    .section-title {
      color: var(--primary-color);
      margin-bottom: 20px;
      font-size: 20px;
      font-weight: 600;
      display: flex;
      align-items: center;
      gap: 10px;
    }

    .transaction-card {
      background: #f8f9fa;
      border-radius: 10px;
      padding: 20px;
      margin-bottom: 20px;
      border-left: 4px solid #e9ecef;
      transition: all 0.3s ease;
    }

    .transaction-card:hover {
      transform: translateY(-2px);
      box-shadow: 0 4px 15px rgba(0, 0, 0, 0.1);
    }

    .transaction-card.pending {
      border-left-color: #ffc107;
      background: #fff9e6;
    }

    .transaction-card.processing {
      border-left-color: #007bff;
      background: #e6f3ff;
    }

    .transaction-card.shipped {
      border-left-color: #17a2b8;
      background: #e6f9fc;
    }

    .transaction-card.delivered {
      border-left-color: #28a745;
      background: #e6f7e6;
    }

    .transaction-card.cancelled {
      border-left-color: #dc3545;
      background: #ffe6e6;
    }

    .transaction-header {
      display: flex;
      justify-content: space-between;
      align-items: start;
      margin-bottom: 15px;
    }

    .transaction-id {
      font-weight: 600;
      color: var(--primary-color);
      font-size: 1.1rem;
    }

    .transaction-user {
      color: #666;
      font-size: 0.9rem;
      margin-top: 5px;
    }

    .transaction-date {
      color: #6c757d;
      font-size: 0.85rem;
      text-align: right;
    }

    .transaction-details {
      display: grid;
      grid-template-columns: repeat(auto-fit, minmax(150px, 1fr));
      gap: 15px;
      margin-bottom: 15px;
    }

    .detail-item {
      text-align: center;
    }

    .detail-label {
      font-size: 0.8rem;
      color: #6c757d;
      margin-bottom: 5px;
    }

    .detail-value {
      font-weight: 600;
      color: #333;
    }

    .status-badge {
      padding: 4px 8px;
      border-radius: 12px;
      font-size: 0.75rem;
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
      background-color: #d1ecf1;
      color: #0c5460;
    }

    .status-delivered {
      background-color: #d4edda;
      color: #155724;
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

    /* Action Buttons */
    .action-buttons {
      display: flex;
      flex-wrap: wrap;
      gap: 8px;
      margin-top: 15px;
      padding-top: 15px;
      border-top: 1px solid #dee2e6;
    }

    .btn-action {
      padding: 6px 12px;
      border: none;
      border-radius: 6px;
      font-size: 0.8rem;
      cursor: pointer;
      transition: all 0.3s;
      text-decoration: none;
      display: inline-flex;
      align-items: center;
      gap: 5px;
    }

    .btn-view {
      background-color: #6c757d;
      color: white;
    }

    .btn-view:hover {
      background-color: #5a6268;
      color: white;
    }

    .btn-approve {
      background-color: #28a745;
      color: white;
    }

    .btn-approve:hover {
      background-color: #218838;
    }

    .btn-reject {
      background-color: #dc3545;
      color: white;
    }

    .btn-reject:hover {
      background-color: #c82333;
    }

    .btn-ship {
      background-color: #17a2b8;
      color: white;
    }

    .btn-ship:hover {
      background-color: #138496;
    }

    .btn-deliver {
      background-color: #007bff;
      color: white;
    }

    .btn-deliver:hover {
      background-color: #0056b3;
    }

    .btn-cancel {
      background-color: #6c757d;
      color: white;
    }

    .btn-cancel:hover {
      background-color: #5a6268;
    }

    /* No data style */
    .no-data {
      text-align: center;
      padding: 40px;
      color: #6c757d;
    }

    .no-data i {
      font-size: 3rem;
      margin-bottom: 20px;
    }

    /* Loading overlay */
    .loading-overlay {
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
    }

    .loading-spinner {
      color: white;
      font-size: 2rem;
    }

    /* Responsive */
    @media (max-width: 768px) {
      .sidebar {
        transform: translateX(-100%);
        z-index: 1000;
      }
      
      .main-content {
        margin-left: 0;
      }

      .header-actions {
        flex-direction: column;
        gap: 5px;
      }

      .transaction-details {
        grid-template-columns: 1fr;
      }

      .transaction-header {
        flex-direction: column;
        gap: 10px;
      }

      .action-buttons {
        justify-content: center;
      }
    }
  </style>
</head>
<body>
  <%
  try {
      Class.forName("com.mysql.cj.jdbc.Driver");
      conn = DriverManager.getConnection(url, user, dbpass);
      
      // Get all transactions with user details and payment proof info
      String transaksiSql = "SELECT t.*, u.nama, u.email, " +
                           "bp.id as bukti_id, bp.status_verifikasi, bp.bukti_transfer " +
                           "FROM transaksi t " +
                           "JOIN user u ON t.user_id = u.id " +
                           "LEFT JOIN bukti_pembayaran bp ON t.id = bp.transaksi_id " +
                           "ORDER BY t.created_at DESC";
      pstmt = conn.prepareStatement(transaksiSql);
      rs = pstmt.executeQuery();
      
      while (rs.next()) {
          Map<String, Object> transaksi = new HashMap<>();
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
          transaksi.put("updated_at", rs.getTimestamp("updated_at"));
          transaksi.put("bukti_id", rs.getObject("bukti_id"));
          transaksi.put("status_verifikasi", rs.getString("status_verifikasi"));
          transaksi.put("bukti_transfer", rs.getString("bukti_transfer"));
          transaksiList.add(transaksi);
      }
      rs.close();
      pstmt.close();
      
  } catch(Exception e) {
      out.println("<!-- Error loading data: " + e.getMessage() + " -->");
  } finally {
      if (rs != null) try { rs.close(); } catch (SQLException e) { e.printStackTrace(); }
      if (pstmt != null) try { pstmt.close(); } catch (SQLException e) { e.printStackTrace(); }
      if (conn != null) try { conn.close(); } catch (SQLException e) { e.printStackTrace(); }
  }
  %>

  <!-- Loading Overlay -->
  <div class="loading-overlay" id="loadingOverlay">
    <div class="loading-spinner">
      <i class="fas fa-spinner fa-spin"></i>
    </div>
  </div>

  <!-- Sidebar -->
  <div class="sidebar">
    <div class="sidebar-header">
      Dashboard
    </div>
    <div class="sidebar-menu">
      <a href="dashboard.jsp">
        <i class="fas fa-home"></i> Home
      </a>
      <a href="data-register.jsp">
        <i class="fas fa-users"></i> Data Register
      </a>
      <a href="MasterBarang.jsp">
        <i class="fas fa-boxes"></i> Master Barang
      </a>
      <a href="transaksi.jsp" class="active">
        <i class="fas fa-receipt"></i> Transaksi
      </a>
    </div>
  </div>

  <!-- Main Content -->
  <div class="main-content">
    <div class="header">
      <h1 class="welcome-text">
        <i class="fas fa-receipt"></i> 
        Kelola Transaksi - <span style="color: var(--primary-color);"><%= username %></span>
      </h1>
      <div class="header-actions">
        <a href="exportexcel.jsp" class="export-btn excel" onclick="showExportLoading()">
          <i class="fas fa-file-excel"></i> Export Excel
        </a>
        <a href="exportpdf.jsp" class="export-btn pdf" onclick="showExportLoading()">
          <i class="fas fa-file-pdf"></i> Export PDF
        </a>
        <form action="logout.jsp" method="post" style="margin: 0;">
          <button type="submit" class="logout-btn">
            <i class="fas fa-sign-out-alt"></i> Logout
          </button>
        </form>
      </div>
    </div>

    <!-- Transactions List -->
    <div class="transaction-section">
      <h2 class="section-title">
        <i class="fas fa-list"></i> Daftar Transaksi (<%= transaksiList.size() %>)
      </h2>
      
      <% if (transaksiList.isEmpty()) { %>
        <div class="no-data">
          <i class="fas fa-inbox"></i>
          <h4>Belum Ada Transaksi</h4>
          <p>Belum ada transaksi yang perlu dikelola.</p>
        </div>
      <% } else { %>
        <% 
        SimpleDateFormat sdf = new SimpleDateFormat("dd MMM yyyy, HH:mm", new Locale("id", "ID"));
        for (Map<String, Object> transaksi : transaksiList) {
            String statusPembayaran = (String)transaksi.get("status_pembayaran");
            String statusPesanan = (String)transaksi.get("status_pesanan");
            String metodePembayaran = (String)transaksi.get("metode_pembayaran");
            Object buktiId = transaksi.get("bukti_id");
            String statusVerifikasi = (String)transaksi.get("status_verifikasi");
        %>
        <div class="transaction-card <%= statusPesanan %>">
          <div class="transaction-header">
            <div>
              <div class="transaction-id">
                <i class="fas fa-receipt"></i> Transaksi #<%= (Integer)transaksi.get("id") %>
              </div>
              <div class="transaction-user">
                <i class="fas fa-user"></i> <%= (String)transaksi.get("nama") %> (<%= (String)transaksi.get("email") %>)
              </div>
            </div>
            <div class="transaction-date">
              <i class="fas fa-calendar"></i> <%= sdf.format((Timestamp)transaksi.get("created_at")) %>
            </div>
          </div>
          
          <div class="transaction-details">
            <div class="detail-item">
              <div class="detail-label">Total</div>
              <div class="detail-value" style="color: var(--primary-color); font-size: 1.1rem;">
                Rp <%= String.format("%,.0f", (Double)transaksi.get("total_harga")) %>
              </div>
            </div>
            <div class="detail-item">
              <div class="detail-label">Pembayaran</div>
              <div class="detail-value">
                <span class="status-badge payment-<%= statusPembayaran %>">
                  <%= statusPembayaran.toUpperCase() %>
                </span>
              </div>
            </div>
            <div class="detail-item">
              <div class="detail-label">Status Pesanan</div>
              <div class="detail-value">
                <span class="status-badge status-<%= statusPesanan %>">
                  <%= statusPesanan.toUpperCase() %>
                </span>
              </div>
            </div>
            <div class="detail-item">
              <div class="detail-label">Metode</div>
              <div class="detail-value">
                <%= metodePembayaran.replace("_", " ").toUpperCase() %>
              </div>
            </div>
          </div>

          <!-- Action Buttons -->
          <div class="action-buttons">
            <!-- View Detail Button -->
            <a href="detailTransaksi.jsp?id=<%= (Integer)transaksi.get("id") %>" class="btn-action btn-view">
              <i class="fas fa-eye"></i> Detail
            </a>

            <% if ("transfer_bank".equals(metodePembayaran) && buktiId != null) { %>
              <!-- Payment Approval Buttons for Transfer Bank -->
              <% if ("pending".equals(statusPembayaran) && "pending".equals(statusVerifikasi)) { %>
                <button class="btn-action btn-approve" onclick="updateTransaction(<%= (Integer)transaksi.get("id") %>, 'approve_payment')">
                  <i class="fas fa-check"></i> Setujui Pembayaran
                </button>
                <button class="btn-action btn-reject" onclick="updateTransaction(<%= (Integer)transaksi.get("id") %>, 'reject_payment')">
                  <i class="fas fa-times"></i> Tolak Pembayaran
                </button>
              <% } %>
            <% } %>

            <!-- Order Status Management -->
            <% if ("paid".equals(statusPembayaran) && "processing".equals(statusPesanan)) { %>
              <button class="btn-action btn-ship" onclick="updateTransaction(<%= (Integer)transaksi.get("id") %>, 'ship_order')">
                <i class="fas fa-shipping-fast"></i> Kirim Pesanan
              </button>
            <% } %>

            <% if ("shipped".equals(statusPesanan)) { %>
              <button class="btn-action btn-deliver" onclick="updateTransaction(<%= (Integer)transaksi.get("id") %>, 'deliver_order')">
                <i class="fas fa-check-circle"></i> Pesanan Terkirim
              </button>
            <% } %>

            <!-- Cancel Order (only if not delivered or cancelled) -->
            <% if (!"delivered".equals(statusPesanan) && !"cancelled".equals(statusPesanan)) { %>
              <button class="btn-action btn-cancel" onclick="confirmCancelOrder(<%= (Integer)transaksi.get("id") %>)">
                <i class="fas fa-ban"></i> Batalkan
              </button>
            <% } %>
          </div>
        </div>
        <% } %>
      <% } %>
    </div>
  </div>

  <script src="https://cdnjs.cloudflare.com/ajax/libs/bootstrap/5.0.2/js/bootstrap.bundle.min.js"></script>
  <script>
    function showLoading() {
      document.getElementById('loadingOverlay').style.display = 'flex';
    }

    function hideLoading() {
      document.getElementById('loadingOverlay').style.display = 'none';
    }

    function showExportLoading() {
      showLoading();
      // Hide loading after 3 seconds (adjust based on your export processing time)
      setTimeout(hideLoading, 3000);
    }

    function updateTransaction(transaksiId, action) {
      if (confirm('Apakah Anda yakin ingin melakukan aksi ini?')) {
        showLoading();
        
        // Create form and submit
        const form = document.createElement('form');
        form.method = 'POST';
        form.action = 'transaksi.jsp';
        
        const actionInput = document.createElement('input');
        actionInput.type = 'hidden';
        actionInput.name = 'action';
        actionInput.value = action;
        
        const idInput = document.createElement('input');
        idInput.type = 'hidden';
        idInput.name = 'transaksi_id';
        idInput.value = transaksiId;
        
        form.appendChild(actionInput);
        form.appendChild(idInput);
        document.body.appendChild(form);
        form.submit();
      }
    }

    function confirmCancelOrder(transaksiId) {
      if (confirm('Apakah Anda yakin ingin membatalkan pesanan ini? Tindakan ini tidak dapat dibatalkan.')) {
        updateTransaction(transaksiId, 'cancel_order');
      }
    }

    // Hide loading on page load
    window.addEventListener('load', function() {
      hideLoading();
    });
  </script>
</body>
</html>