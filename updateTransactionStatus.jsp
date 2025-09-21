<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="java.sql.*" %>
<%@ page import="java.util.*" %>

<%
    // Check if user is logged in and is admin
    String username = (String) session.getAttribute("username");
    String userRole = (String) session.getAttribute("role");
    if (username == null || !"admin".equals(userRole)) {
        response.sendRedirect("login.html");
        return;
    }

    // Database connection parameters
    String url = "jdbc:mysql://localhost:3306/webcapstone";
    String user = "root";
    String dbpass = "";
    Connection conn = null;
    PreparedStatement pstmt = null;
    ResultSet rs = null;
    
    String message = "";
    boolean success = false;
    
    // Get parameters
    String transaksiIdStr = request.getParameter("transaksi_id");
    String newStatus = request.getParameter("new_status");
    String action = request.getParameter("action");
    
    if (transaksiIdStr != null && newStatus != null && action != null) {
        try {
            int transaksiId = Integer.parseInt(transaksiIdStr);
            
            Class.forName("com.mysql.cj.jdbc.Driver");
            conn = DriverManager.getConnection(url, user, dbpass);
            
            // First, check if transaction exists and get current status
            String checkSql = "SELECT status_pesanan, status_pembayaran FROM transaksi WHERE id = ?";
            pstmt = conn.prepareStatement(checkSql);
            pstmt.setInt(1, transaksiId);
            rs = pstmt.executeQuery();
            
            if (rs.next()) {
                String currentOrderStatus = rs.getString("status_pesanan");
                String currentPaymentStatus = rs.getString("status_pembayaran");
                
                // Validate status transitions
                boolean canUpdate = false;
                String statusMessage = "";
                
                switch (action) {
                    case "approve":
                        if ("pending".equals(currentOrderStatus)) {
                            canUpdate = true;
                            statusMessage = "Transaksi berhasil disetujui";
                        } else {
                            statusMessage = "Transaksi sudah tidak dalam status pending";
                        }
                        break;
                    case "reject":
                        if ("pending".equals(currentOrderStatus)) {
                            canUpdate = true;
                            statusMessage = "Transaksi berhasil ditolak";
                        } else {
                            statusMessage = "Transaksi sudah tidak dalam status pending";
                        }
                        break;
                    case "ship":
                        if ("processing".equals(currentOrderStatus)) {
                            canUpdate = true;
                            statusMessage = "Status berhasil diubah menjadi shipped";
                        } else {
                            statusMessage = "Transaksi harus dalam status processing untuk dapat dikirim";
                        }
                        break;
                    case "deliver":
                        if ("shipped".equals(currentOrderStatus)) {
                            canUpdate = true;
                            statusMessage = "Pesanan berhasil ditandai sebagai delivered";
                        } else {
                            statusMessage = "Pesanan harus dalam status shipped untuk dapat ditandai delivered";
                        }
                        break;
                    default:
                        statusMessage = "Aksi tidak dikenali";
                }
                
                if (canUpdate) {
                    // Close previous statement
                    rs.close();
                    pstmt.close();
                    
                    // Update transaction status
                    String updateSql = "UPDATE transaksi SET status_pesanan = ?, updated_at = CURRENT_TIMESTAMP WHERE id = ?";
                    pstmt = conn.prepareStatement(updateSql);
                    pstmt.setString(1, newStatus);
                    pstmt.setInt(2, transaksiId);
                    
                    int rowsAffected = pstmt.executeUpdate();
                    
                    if (rowsAffected > 0) {
                        success = true;
                        message = statusMessage;
                        
                        // If approving, also update payment status to paid for certain payment methods
                        if ("approve".equals(action) && "cod".equals(getCurrentPaymentMethod(conn, transaksiId))) {
                            updatePaymentStatus(conn, transaksiId, "paid");
                        }
                        
                        // Log the status change (optional)
                        logStatusChange(conn, transaksiId, currentOrderStatus, newStatus, username, action);
                        
                    } else {
                        message = "Gagal memperbarui status transaksi";
                    }
                } else {
                    message = statusMessage;
                }
            } else {
                message = "Transaksi tidak ditemukan";
            }
            
        } catch (NumberFormatException e) {
            message = "ID transaksi tidak valid";
        } catch (SQLException e) {
            message = "Error database: " + e.getMessage();
        } catch (Exception e) {
            message = "Error: " + e.getMessage();
        } finally {
            if (rs != null) try { rs.close(); } catch (SQLException e) { e.printStackTrace(); }
            if (pstmt != null) try { pstmt.close(); } catch (SQLException e) { e.printStackTrace(); }
            if (conn != null) try { conn.close(); } catch (SQLException e) { e.printStackTrace(); }
        }
    } else {
        message = "Parameter tidak lengkap";
    }
    
    // Redirect back to transaksi.jsp with message
    String encodedMessage = java.net.URLEncoder.encode(message, "UTF-8");
    response.sendRedirect("transaksi.jsp?message=" + encodedMessage + "&success=" + success);
%>

<%!
    // Helper method to get current payment method
    private String getCurrentPaymentMethod(Connection conn, int transaksiId) {
        try {
            PreparedStatement pstmt = conn.prepareStatement("SELECT metode_pembayaran FROM transaksi WHERE id = ?");
            pstmt.setInt(1, transaksiId);
            ResultSet rs = pstmt.executeQuery();
            if (rs.next()) {
                return rs.getString("metode_pembayaran");
            }
        } catch (SQLException e) {
            e.printStackTrace();
        }
        return "";
    }
    
    // Helper method to update payment status
    private void updatePaymentStatus(Connection conn, int transaksiId, String paymentStatus) {
        try {
            PreparedStatement pstmt = conn.prepareStatement("UPDATE transaksi SET status_pembayaran = ? WHERE id = ?");
            pstmt.setString(1, paymentStatus);
            pstmt.setInt(2, transaksiId);
            pstmt.executeUpdate();
            pstmt.close();
        } catch (SQLException e) {
            e.printStackTrace();
        }
    }
    
    // Helper method to log status changes (optional)
    private void logStatusChange(Connection conn, int transaksiId, String oldStatus, String newStatus, String adminUser, String action) {
        try {
            // You can create a log table for audit trail if needed
            // For now, we'll just print to console
            System.out.println("Status changed for transaction " + transaksiId + 
                             " from " + oldStatus + " to " + newStatus + 
                             " by admin " + adminUser + " (action: " + action + ")");
        } catch (Exception e) {
            e.printStackTrace();
        }
    }
%>