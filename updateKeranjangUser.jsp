<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="java.sql.*" %>
<%
    // Cek login
    Integer userId = (Integer) session.getAttribute("user_id");
    if (userId == null) {
        response.sendRedirect("login.html");
        return;
    }
    
    String keranjangIdStr = request.getParameter("keranjang_id");
    String quantityStr = request.getParameter("quantity");
    
    if (keranjangIdStr == null || quantityStr == null) {
        response.sendRedirect("keranjangUser.jsp?error=Parameter tidak lengkap");
        return;
    }
    
    int keranjangId = Integer.parseInt(keranjangIdStr);
    int newQuantity = Integer.parseInt(quantityStr);
    
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
        
        // Cek stok barang
        String checkSql = "SELECT b.quantity as stok, b.nama_barang " +
                         "FROM keranjang k " +
                         "JOIN barang b ON k.barang_id = b.id " +
                         "WHERE k.id = ? AND k.user_id = ?";
        
        pstmt = conn.prepareStatement(checkSql);
        pstmt.setInt(1, keranjangId);
        pstmt.setInt(2, userId);
        rs = pstmt.executeQuery();
        
        if (rs.next()) {
            int stokTersedia = rs.getInt("stok");
            String namaBarang = rs.getString("nama_barang");
            rs.close();
            pstmt.close();
            
            if (newQuantity <= stokTersedia && newQuantity > 0) {
                String updateSql = "UPDATE keranjang SET quantity = ? WHERE id = ? AND user_id = ?";
                pstmt = conn.prepareStatement(updateSql);
                pstmt.setInt(1, newQuantity);
                pstmt.setInt(2, keranjangId);
                pstmt.setInt(3, userId);
                
                int updated = pstmt.executeUpdate();
                if (updated > 0) {
                    response.sendRedirect("keranjangUser.jsp?success=Berhasil update " + namaBarang);
                } else {
                    response.sendRedirect("keranjangUser.jsp?error=Gagal update keranjang");
                }
            } else {
                response.sendRedirect("keranjangUser.jsp?error=Stok tidak mencukupi. Stok tersedia: " + stokTersedia);
            }
        } else {
            response.sendRedirect("keranjangUser.jsp?error=Item keranjang tidak ditemukan");
        }
        
    } catch (Exception e) {
        response.sendRedirect("keranjangUser.jsp?error=Terjadi kesalahan: " + e.getMessage());
    } finally {
        if (rs != null) try { rs.close(); } catch (SQLException e) { e.printStackTrace(); }
        if (pstmt != null) try { pstmt.close(); } catch (SQLException e) { e.printStackTrace(); }
        if (conn != null) try { conn.close(); } catch (SQLException e) { e.printStackTrace(); }
    }
%>