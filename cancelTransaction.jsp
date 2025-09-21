<%-- cancelTransaction.jsp --%>
<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="java.sql.*" %>
<%
    // Check if user is logged in
    String username = (String) session.getAttribute("username");
    String email = (String) session.getAttribute("email");
    
    if (username == null || email == null) {
        out.print("error");
        return;
    }
    
    // Check if request is POST
    if (!"POST".equals(request.getMethod())) {
        out.print("error");
        return;
    }
    
    // Get transaction ID
    String transaksiIdParam = request.getParameter("transaksiId");
    if (transaksiIdParam == null || transaksiIdParam.trim().isEmpty()) {
        out.print("error");
        return;
    }
    
    int transaksiId = 0;
    try {
        transaksiId = Integer.parseInt(transaksiIdParam);
    } catch (NumberFormatException e) {
        out.print("error");
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
        conn.setAutoCommit(false); // Start transaction
        
        // Get user ID
        int userId = 0;
        String getUserSql = "SELECT id FROM user WHERE email = ?";
        pstmt = conn.prepareStatement(getUserSql);
        pstmt.setString(1, email);
        rs = pstmt.executeQuery();
        
        if (rs.next()) {
            userId = rs.getInt("id");
        } else {
            out.print("error");
            return;
        }
        rs.close();
        pstmt.close();
        
        // Check if transaction exists and belongs to user
        String checkTransaksiSql = "SELECT status_pesanan, status_pembayaran FROM transaksi WHERE id = ? AND user_id = ?";
        pstmt = conn.prepareStatement(checkTransaksiSql);
        pstmt.setInt(1, transaksiId);
        pstmt.setInt(2, userId);
        rs = pstmt.executeQuery();
        
        if (!rs.next()) {
            out.print("error");
            return;
        }
        
        String statusPesanan = rs.getString("status_pesanan");
        String statusPembayaran = rs.getString("status_pembayaran");
        
        // Check if transaction can be cancelled (only pending orders can be cancelled)
        if (!"pending".equals(statusPesanan)) {
            out.print("error");
            return;
        }
        
        rs.close();
        pstmt.close();
        
        // Get transaction details to restore stock
        String getDetailsSql = "SELECT dt.barang_id, dt.quantity FROM detail_transaksi dt WHERE dt.transaksi_id = ?";
        pstmt = conn.prepareStatement(getDetailsSql);
        pstmt.setInt(1, transaksiId);
        rs = pstmt.executeQuery();
        
        // Restore stock for each item
        while (rs.next()) {
            int barangId = rs.getInt("barang_id");
            int quantity = rs.getInt("quantity");
            
            // Update stock in barang table
            PreparedStatement updateStockStmt = conn.prepareStatement(
                "UPDATE barang SET quantity = quantity + ? WHERE id = ?"
            );
            updateStockStmt.setInt(1, quantity);
            updateStockStmt.setInt(2, barangId);
            updateStockStmt.executeUpdate();
            updateStockStmt.close();
        }
        
        rs.close();
        pstmt.close();
        
        // Update transaction status
        String updateTransaksiSql = "UPDATE transaksi SET status_pesanan = 'cancelled', updated_at = CURRENT_TIMESTAMP WHERE id = ? AND user_id = ?";
        pstmt = conn.prepareStatement(updateTransaksiSql);
        pstmt.setInt(1, transaksiId);
        pstmt.setInt(2, userId);
        
        int updatedRows = pstmt.executeUpdate();
        
        if (updatedRows > 0) {
            conn.commit(); // Commit transaction
            out.print("success");
        } else {
            conn.rollback(); // Rollback transaction
            out.print("error");
        }
        
    } catch(Exception e) {
        try {
            if (conn != null) {
                conn.rollback(); // Rollback on error
            }
        } catch (SQLException se) {
            se.printStackTrace();
        }
        out.print("error");
        e.printStackTrace();
    } finally {
        try {
            if (conn != null) {
                conn.setAutoCommit(true); // Reset auto commit
            }
        } catch (SQLException e) {
            e.printStackTrace();
        }
        
        if (rs != null) try { rs.close(); } catch (SQLException e) { e.printStackTrace(); }
        if (pstmt != null) try { pstmt.close(); } catch (SQLException e) { e.printStackTrace(); }
        if (conn != null) try { conn.close(); } catch (SQLException e) { e.printStackTrace(); }
    }
%>