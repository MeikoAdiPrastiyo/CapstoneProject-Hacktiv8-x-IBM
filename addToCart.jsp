<%-- addToCart.jsp --%>
<%@ page language="java" contentType="application/json; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="java.sql.*" %>
<%
    // Set response type to JSON
    response.setContentType("application/json");
    response.setCharacterEncoding("UTF-8");
    
    // Check if user is logged in
    String username = (String) session.getAttribute("username");
    if (username == null) {
        out.print("{\"success\": false, \"message\": \"Silakan login terlebih dahulu\"}");
        return;
    }
    
    // Get user ID from session/database
    String email = (String) session.getAttribute("email");
    String barangIdStr = request.getParameter("barangId");
    String quantityStr = request.getParameter("quantity");
    
    // Validate parameters
    if (barangIdStr == null || quantityStr == null || barangIdStr.trim().isEmpty() || quantityStr.trim().isEmpty()) {
        out.print("{\"success\": false, \"message\": \"Parameter tidak lengkap\"}");
        return;
    }
    
    int barangId = 0;
    int quantity = 0;
    
    try {
        barangId = Integer.parseInt(barangIdStr);
        quantity = Integer.parseInt(quantityStr);
        
        if (quantity <= 0) {
            out.print("{\"success\": false, \"message\": \"Jumlah harus lebih dari 0\"}");
            return;
        }
    } catch (NumberFormatException e) {
        out.print("{\"success\": false, \"message\": \"Parameter tidak valid\"}");
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
        String getUserSql = "SELECT id FROM user WHERE email = ?";
        pstmt = conn.prepareStatement(getUserSql);
        pstmt.setString(1, email);
        rs = pstmt.executeQuery();
        
        int userId = 0;
        if (rs.next()) {
            userId = rs.getInt("id");
        } else {
            out.print("{\"success\": false, \"message\": \"User tidak ditemukan\"}");
            return;
        }
        
        rs.close();
        pstmt.close();
        
        // Check if product exists and has enough stock
        String checkProductSql = "SELECT nama_barang, quantity FROM barang WHERE id = ?";
        pstmt = conn.prepareStatement(checkProductSql);
        pstmt.setInt(1, barangId);
        rs = pstmt.executeQuery();
        
        String namaBarang = "";
        int availableStock = 0;
        
        if (rs.next()) {
            namaBarang = rs.getString("nama_barang");
            availableStock = rs.getInt("quantity");
        } else {
            out.print("{\"success\": false, \"message\": \"Barang tidak ditemukan\"}");
            return;
        }
        
        if (availableStock < quantity) {
            out.print("{\"success\": false, \"message\": \"Stok tidak mencukupi. Stok tersedia: " + availableStock + "\"}");
            return;
        }
        
        rs.close();
        pstmt.close();
        
        // Check if item already exists in cart
        String checkCartSql = "SELECT id, quantity FROM keranjang WHERE user_id = ? AND barang_id = ?";
        pstmt = conn.prepareStatement(checkCartSql);
        pstmt.setInt(1, userId);
        pstmt.setInt(2, barangId);
        rs = pstmt.executeQuery();
        
        if (rs.next()) {
            // Item exists in cart, update quantity
            int existingCartId = rs.getInt("id");
            int existingQuantity = rs.getInt("quantity");
            int newQuantity = existingQuantity + quantity;
            
            // Check if new total quantity exceeds available stock
            if (newQuantity > availableStock) {
                out.print("{\"success\": false, \"message\": \"Jumlah di keranjang akan melebihi stok. Stok tersedia: " + availableStock + ", sudah di keranjang: " + existingQuantity + "\"}");
                return;
            }
            
            rs.close();
            pstmt.close();
            
            String updateCartSql = "UPDATE keranjang SET quantity = ? WHERE id = ?";
            pstmt = conn.prepareStatement(updateCartSql);
            pstmt.setInt(1, newQuantity);
            pstmt.setInt(2, existingCartId);
            pstmt.executeUpdate();
            
            conn.commit();
            out.print("{\"success\": true, \"message\": \"" + namaBarang + " berhasil diperbarui di keranjang (+" + quantity + ")\"}");
            
        } else {
            // Item doesn't exist in cart, insert new
            rs.close();
            pstmt.close();
            
            String insertCartSql = "INSERT INTO keranjang (user_id, barang_id, quantity) VALUES (?, ?, ?)";
            pstmt = conn.prepareStatement(insertCartSql);
            pstmt.setInt(1, userId);
            pstmt.setInt(2, barangId);
            pstmt.setInt(3, quantity);
            pstmt.executeUpdate();
            
            conn.commit();
            out.print("{\"success\": true, \"message\": \"" + namaBarang + " berhasil ditambahkan ke keranjang\"}");
        }
        
    } catch (SQLException e) {
        if (conn != null) {
            try {
                conn.rollback();
            } catch (SQLException ex) {
                ex.printStackTrace();
            }
        }
        out.print("{\"success\": false, \"message\": \"Database error: " + e.getMessage() + "\"}");
    } catch (ClassNotFoundException e) {
        out.print("{\"success\": false, \"message\": \"Driver database tidak ditemukan\"}");
    } catch (Exception e) {
        if (conn != null) {
            try {
                conn.rollback();
            } catch (SQLException ex) {
                ex.printStackTrace();
            }
        }
        out.print("{\"success\": false, \"message\": \"Terjadi kesalahan: " + e.getMessage() + "\"}");
    } finally {
        if (rs != null) try { rs.close(); } catch (SQLException e) { e.printStackTrace(); }
        if (pstmt != null) try { pstmt.close(); } catch (SQLException e) { e.printStackTrace(); }
        if (conn != null) {
            try {
                conn.setAutoCommit(true);
                conn.close();
            } catch (SQLException e) {
                e.printStackTrace();
            }
        }
    }
%>