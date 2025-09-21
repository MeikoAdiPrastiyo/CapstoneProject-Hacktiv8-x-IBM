<%-- completeTransaction.jsp --%>
<%@ page language="java" contentType="text/plain; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="java.sql.*" %>
<%
    response.setContentType("text/plain");
    
    // Check if user is logged in
    String username = (String) session.getAttribute("username");
    String email = (String) session.getAttribute("email");
    if (username == null || email == null) {
        out.print("error: User not logged in");
        return;
    }
    
    // Get transaction ID from parameter
    String transaksiIdParam = request.getParameter("transaksiId");
    if (transaksiIdParam == null || transaksiIdParam.trim().isEmpty()) {
        out.print("error: ID transaksi tidak valid");
        return;
    }
    
    int transaksiId = 0;
    try {
        transaksiId = Integer.parseInt(transaksiIdParam);
    } catch (NumberFormatException e) {
        out.print("error: ID transaksi tidak valid");
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
        
        // Start transaction
        conn.setAutoCommit(false);
        
        // Get user ID
        int userId = 0;
        String getUserSql = "SELECT id FROM user WHERE email = ?";
        pstmt = conn.prepareStatement(getUserSql);
        pstmt.setString(1, email);
        rs = pstmt.executeQuery();
        
        if (rs.next()) {
            userId = rs.getInt("id");
        } else {
            out.print("error: User tidak ditemukan");
            conn.rollback();
            return;
        }
        rs.close();
        pstmt.close();
        
        // Verify transaction belongs to user and check current status
        String verifyTransaksiSql = "SELECT status_pembayaran, status_pesanan FROM transaksi WHERE id = ? AND user_id = ?";
        pstmt = conn.prepareStatement(verifyTransaksiSql);
        pstmt.setInt(1, transaksiId);
        pstmt.setInt(2, userId);
        rs = pstmt.executeQuery();
        
        if (!rs.next()) {
            out.print("error: Transaksi tidak ditemukan atau bukan milik Anda");
            conn.rollback();
            return;
        }
        
        String statusPembayaran = rs.getString("status_pembayaran");
        String statusPesanan = rs.getString("status_pesanan");
        
        // Check if transaction can be completed
        if (!statusPembayaran.equals("paid")) {
            out.print("error: Pembayaran belum lunas");
            conn.rollback();
            return;
        }
        
        if (!statusPesanan.equals("shipped")) {
            out.print("error: Pesanan belum dalam status dikirim. Status saat ini: " + statusPesanan);
            conn.rollback();
            return;
        }
        
        rs.close();
        pstmt.close();
        
        // Update transaction status to 'delivered'
        String updateTransaksiSql = "UPDATE transaksi SET status_pesanan = 'delivered', updated_at = CURRENT_TIMESTAMP WHERE id = ? AND user_id = ?";
        pstmt = conn.prepareStatement(updateTransaksiSql);
        pstmt.setInt(1, transaksiId);
        pstmt.setInt(2, userId);
        
        int updateResult = pstmt.executeUpdate();
        pstmt.close();
        
        if (updateResult > 0) {
            // Commit the transaction
            conn.commit();
            out.print("success");
        } else {
            out.print("error: Gagal menyelesaikan pesanan");
            conn.rollback();
        }
        
    } catch (SQLException e) {
        if (conn != null) {
            try {
                conn.rollback();
            } catch (SQLException ex) {
                ex.printStackTrace();
            }
        }
        out.print("error: Database error - " + e.getMessage());
    } catch (Exception e) {
        if (conn != null) {
            try {
                conn.rollback();
            } catch (SQLException ex) {
                ex.printStackTrace();
            }
        }
        out.print("error: " + e.getMessage());
    } finally {
        if (rs != null) {
            try { rs.close(); } catch (SQLException e) { e.printStackTrace(); }
        }
        if (pstmt != null) {
            try { pstmt.close(); } catch (SQLException e) { e.printStackTrace(); }
        }
        if (conn != null) {
            try { 
                conn.setAutoCommit(true); // Reset auto-commit
                conn.close(); 
            } catch (SQLException e) { e.printStackTrace(); }
        }
    }
%>