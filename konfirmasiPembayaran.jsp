<%-- konfirmasiPembayaran.jsp --%>
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
    
    // Get transaction ID
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
            return;
        }
        rs.close();
        pstmt.close();
        
        // Verify transaction belongs to user and check current status
        String checkTransaksiSql = "SELECT status_pembayaran, status_pesanan FROM transaksi WHERE id = ? AND user_id = ?";
        pstmt = conn.prepareStatement(checkTransaksiSql);
        pstmt.setInt(1, transaksiId);
        pstmt.setInt(2, userId);
        rs = pstmt.executeQuery();
        
        if (!rs.next()) {
            out.print("error: Transaksi tidak ditemukan atau bukan milik Anda");
            return;
        }
        
        String currentStatusPembayaran = rs.getString("status_pembayaran");
        String currentStatusPesanan = rs.getString("status_pesanan");
        
        rs.close();
        pstmt.close();
        
        // Check if payment is still pending
        if (!currentStatusPembayaran.equals("pending")) {
            out.print("error: Pembayaran sudah " + currentStatusPembayaran);
            return;
        }
        
        // Update payment status to 'paid'
        String updatePembayaranSql = "UPDATE transaksi SET status_pembayaran = 'paid', updated_at = CURRENT_TIMESTAMP WHERE id = ? AND user_id = ?";
        pstmt = conn.prepareStatement(updatePembayaranSql);
        pstmt.setInt(1, transaksiId);
        pstmt.setInt(2, userId);
        
        int updateResult = pstmt.executeUpdate();
        pstmt.close();
        
        if (updateResult > 0) {
            out.print("success");
        } else {
            out.print("error: Gagal mengkonfirmasi pembayaran");
        }
        
    } catch (SQLException e) {
        out.print("error: Database error - " + e.getMessage());
    } catch (Exception e) {
        out.print("error: " + e.getMessage());
    } finally {
        if (rs != null) {
            try { rs.close(); } catch (SQLException e) { e.printStackTrace(); }
        }
        if (pstmt != null) {
            try { pstmt.close(); } catch (SQLException e) { e.printStackTrace(); }
        }
        if (conn != null) {
            try { conn.close(); } catch (SQLException e) { e.printStackTrace(); }
        }
    }
%>