<%-- addCartUser.jsp (dihapus tidak apa-apa) --%>
<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="java.sql.*" %>
<%
    // Set response content type
    response.setContentType("text/plain");
    
    // Cek apakah user sudah login
    Integer userId = (Integer) session.getAttribute("userId");
    if (userId == null) {
        out.print("login_required");
        return;
    }
    
    // Ambil parameter dari request
    String cartIdStr = request.getParameter("cartId");
    String quantityStr = request.getParameter("quantity");
    
    if (cartIdStr == null || quantityStr == null) {
        out.print("missing_parameters");
        return;
    }
    
    int cartId = 0;
    int quantity = 0;
    
    try {
        cartId = Integer.parseInt(cartIdStr);
        quantity = Integer.parseInt(quantityStr);
    } catch (NumberFormatException e) {
        out.print("invalid_parameters");
        return;
    }
    
    if (quantity <= 0) {
        out.print("invalid_quantity");
        return;
    }
    
    // Database connection
    String url = "jdbc:mysql://localhost:3306/webcapstone";
    String username = "root";
    String password = "";
    
    Connection conn = null;
    PreparedStatement pstmt = null;
    ResultSet rs = null;
    
    try {
        conn = DriverManager.getConnection(url, username, password);
        
        // Cek apakah item keranjang milik user yang sedang login dan ambil barang_id
        String checkSql = "SELECT k.user_id, k.barang_id, b.quantity as stock " +
                         "FROM keranjang k " +
                         "JOIN barang b ON k.barang_id = b.id " +
                         "WHERE k.id = ?";
        pstmt = conn.prepareStatement(checkSql);
        pstmt.setInt(1, cartId);
        rs = pstmt.executeQuery();
        
        if (!rs.next()) {
            out.print("cart_item_not_found");
            return;
        }
        
        int cartUserId = rs.getInt("user_id");
        int barangId = rs.getInt("barang_id");
        int availableStock = rs.getInt("stock");
        
        if (cartUserId != userId) {
            out.print("unauthorized");
            return;
        }
        
        // Cek apakah quantity yang diminta tidak melebihi stock
        if (quantity > availableStock) {
            out.print("insufficient_stock");
            return;
        }
        
        // Update quantity di keranjang
        String updateSql = "UPDATE keranjang SET quantity = ? WHERE id = ?";
        pstmt = conn.prepareStatement(updateSql);
        pstmt.setInt(1, quantity);
        pstmt.setInt(2, cartId);
        
        int rowsUpdated = pstmt.executeUpdate();
        if (rowsUpdated > 0) {
            out.print("success");
        } else {
            out.print("update_failed");
        }
        
    } catch (SQLException e) {
        e.printStackTrace();
        out.print("database_error");
    } catch (Exception e) {
        e.printStackTrace();
        out.print("server_error");
    } finally {
        // Close resources
        try {
            if (rs != null) rs.close();
            if (pstmt != null) pstmt.close();
            if (conn != null) conn.close();
        } catch (SQLException e) {
            e.printStackTrace();
        }
    }
%>