<%-- getTransactionDetail.jsp --%>
<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="java.sql.*" %>
<%@ page import="java.text.SimpleDateFormat" %>
<%@ page import="java.util.*" %>
<%
    // Check if user is logged in
    String username = (String) session.getAttribute("username");
    String email = (String) session.getAttribute("email");
    
    if (username == null || email == null) {
        out.print("<div class='alert alert-danger'>Sesi telah berakhir. Silakan login kembali.</div>");
        return;
    }
    
    // Get transaction ID
    String transaksiIdParam = request.getParameter("id");
    if (transaksiIdParam == null || transaksiIdParam.trim().isEmpty()) {
        out.print("<div class='alert alert-danger'>ID transaksi tidak valid.</div>");
        return;
    }
    
    int transaksiId = 0;
    try {
        transaksiId = Integer.parseInt(transaksiIdParam);
    } catch (NumberFormatException e) {
        out.print("<div class='alert alert-danger'>ID transaksi tidak valid.</div>");
        return;
    }
    
    // Database connection
    String url = "jdbc:mysql://localhost:3306/webcapstone";
    String user = "root";
    String dbpass = "";
    Connection conn = null;
    PreparedStatement pstmt = null;
    ResultSet rs = null;
    
    try {
        Class.forName("com.mysql.cj.jdbc.Driver");
        conn = DriverManager.getConnection(url, user, dbpass);
        
        // Get user ID
        int userId = 0;
        String getUserSql = "SELECT id FROM user WHERE email = ?";
        pstmt = conn.prepareStatement(getUserSql);
        pstmt.setString(1, email);
        rs = pstmt.executeQuery();
        
        if (rs.next()) {
            userId = rs.getInt("id");
        } else {
            out.print("<div class='alert alert-danger'>User tidak ditemukan.</div>");
            return;
        }
        rs.close();
        pstmt.close();
        
        // Get transaction details
        String getTransaksiSql = "SELECT * FROM transaksi WHERE id = ? AND user_id = ?";
        pstmt = conn.prepareStatement(getTransaksiSql);
        pstmt.setInt(1, transaksiId);
        pstmt.setInt(2, userId);
        rs = pstmt.executeQuery();
        
        if (!rs.next()) {
            out.print("<div class='alert alert-danger'>Transaksi tidak ditemukan.</div>");
            return;
        }
        
        // Get transaction data
        double totalHarga = rs.getDouble("total_harga");
        String metodePembayaran = rs.getString("metode_pembayaran");
        String statusPembayaran = rs.getString("status_pembayaran");
        String statusPesanan = rs.getString("status_pesanan");
        String alamatPengiriman = rs.getString("alamat_pengiriman");
        Timestamp createdAt = rs.getTimestamp("created_at");
        Timestamp updatedAt = rs.getTimestamp("updated_at");
        
        SimpleDateFormat sdfDisplay = new SimpleDateFormat("dd MMM yyyy, HH:mm");
        String displayCreatedDate = sdfDisplay.format(createdAt);
        String displayUpdatedDate = updatedAt != null ? sdfDisplay.format(updatedAt) : "-";
        
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
                paymentMethodDisplay = "COD (Cash on Delivery)";
                break;
            default:
                paymentMethodDisplay = metodePembayaran;
        }
        
        rs.close();
        pstmt.close();
%>

<style>
    .detail-section {
        margin-bottom: 25px;
    }
    
    .detail-section h6 {
        color: #2f6c3b;
        font-weight: 600;
        border-bottom: 2px solid #e9ecef;
        padding-bottom: 8px;
        margin-bottom: 15px;
    }
    
    .info-row {
        display: flex;
        justify-content: space-between;
        padding: 8px 0;
        border-bottom: 1px solid #f8f9fa;
    }
    
    .info-label {
        font-weight: 500;
        color: #6c757d;
    }
    
    .info-value {
        font-weight: 600;
        color: #333;
    }
    
    .status-badge {
        padding: 4px 8px;
        border-radius: 12px;
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
    
    .item-card {
        background: #f8f9fa;
        border-radius: 8px;
        padding: 15px;
        margin-bottom: 10px;
        border-left: 4px solid #2f6c3b;
    }
    
    .item-header {
        display: flex;
        justify-content: space-between;
        align-items: center;
        margin-bottom: 8px;
    }
    
    .item-name {
        font-weight: 600;
        color: #333;
    }
    
    .item-price {
        color: #2f6c3b;
        font-weight: 600;
    }
    
    .item-details {
        display: flex;
        justify-content: space-between;
        font-size: 0.9rem;
        color: #6c757d;
    }
    
    .total-section {
        background: linear-gradient(135deg, #2f6c3b, #255b30);
        color: white;
        padding: 20px;
        border-radius: 8px;
        text-align: center;
    }
    

    .total-amount {
        font-size: 1.5rem;
        font-weight: bold;
        margin: 10px 0;
        background: white;
        color: white;
        background: transparent;
    }

</style>

<!-- Transaction Information -->
<div class="detail-section">
    <h6><i class="fas fa-info-circle"></i> Informasi Transaksi</h6>
    <div class="info-row">
        <span class="info-label">ID Transaksi</span>
        <span class="info-value">#<%= transaksiId %></span>
    </div>
    <div class="info-row">
        <span class="info-label">Tanggal Transaksi</span>
        <span class="info-value"><%= displayCreatedDate %></span>
    </div>
    <div class="info-row">
        <span class="info-label">Terakhir Diperbarui</span>
        <span class="info-value"><%= displayUpdatedDate %></span>
    </div>
    <div class="info-row">
        <span class="info-label">Status Pembayaran</span>
        <span class="info-value">
            <span class="status-badge payment-<%= statusPembayaran %>">
                <%= statusPembayaran.toUpperCase() %>
            </span>
        </span>
    </div>
    <div class="info-row">
        <span class="info-label">Status Pesanan</span>
        <span class="info-value">
            <span class="status-badge status-<%= statusPesanan %>">
                <%= statusPesanan.toUpperCase() %>
            </span>
        </span>
    </div>
    <div class="info-row">
        <span class="info-label">Metode Pembayaran</span>
        <span class="info-value"><%= paymentMethodDisplay %></span>
    </div>
</div>

<!-- Shipping Address -->
<div class="detail-section">
    <h6><i class="fas fa-map-marker-alt"></i> Alamat Pengiriman</h6>
    <div style="background: #f8f9fa; padding: 15px; border-radius: 8px; border-left: 4px solid #2f6c3b;">
        <%= alamatPengiriman != null ? alamatPengiriman : "Alamat tidak tersedia" %>
    </div>
</div>

<!-- Items Purchased -->
<div class="detail-section">
    <h6><i class="fas fa-shopping-bag"></i> Barang yang Dibeli</h6>
    <%
        // Get transaction items
        String getItemsSql = "SELECT * FROM detail_transaksi WHERE transaksi_id = ?";
        pstmt = conn.prepareStatement(getItemsSql);
        pstmt.setInt(1, transaksiId);
        rs = pstmt.executeQuery();
        
        boolean hasItems = false;
        while (rs.next()) {
            hasItems = true;
            String namaBarang = rs.getString("nama_barang");
            double harga = rs.getDouble("harga");
            int quantity = rs.getInt("quantity");
            double subtotal = rs.getDouble("subtotal");
    %>
    
    <div class="item-card">
        <div class="item-header">
            <span class="item-name"><%= namaBarang %></span>
            <span class="item-price">Rp <%= String.format("%,.0f", subtotal) %></span>
        </div>
        <div class="item-details">
            <span>Harga satuan: Rp <%= String.format("%,.0f", harga) %></span>
            <span>Jumlah: <%= quantity %> pcs</span>
        </div>
    </div>
    
    <%
        }
        
        if (!hasItems) {
    %>
    <div class="alert alert-warning">
        <i class="fas fa-exclamation-triangle"></i> Detail barang tidak ditemukan.
    </div>
    <%
        }
        
        rs.close();
        pstmt.close();
    %>
</div>

<!-- Total Section -->
<div class="total-section">
    <h6 style="margin: 0; color: white; border: none;"><i class="fas fa-receipt"></i> Total Pembayaran</h6>
    <div class="total-amount">Rp <%= String.format("%,.0f", totalHarga) %></div>
    <small style="opacity: 0.8;">Sudah termasuk pajak dan biaya pengiriman</small>
</div>

<%
    } catch(Exception e) {
        out.print("<div class='alert alert-danger'><i class='fas fa-exclamation-triangle'></i> Error: " + e.getMessage() + "</div>");
        e.printStackTrace();
    } finally {
        if (rs != null) try { rs.close(); } catch (SQLException e) { e.printStackTrace(); }
        if (pstmt != null) try { pstmt.close(); } catch (SQLException e) { e.printStackTrace(); }
        if (conn != null) try { conn.close(); } catch (SQLException e) { e.printStackTrace(); }
    }
%>