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
    
    if (keranjangIdStr == null) {
        response.sendRedirect("keranjangUser.jsp?error=Parameter tidak lengkap");
        return;
    }
    
    int keranjangId = Integer.parseInt(keranjangIdStr);
    
    // Database connection
    String url = "jdbc:mysql://localhost:3306/webcapstone";
    String user = "root";
    String dbpass = "";
    Connection conn = null;
    PreparedStatement pstmt = null;
    
    try {
        Class.forName("com.mysql.cj.jdbc.Driver");
        conn = DriverManager.getConnection(url, user, dbpass);
        
        String sql = "DELETE FROM keranjang WHERE id = ? AND user_id = ?";
        pstmt = conn.prepareStatement(sql);
        pstmt.setInt(1, keranjangId);
        pstmt.setInt(2, userId);
        
        int deleted = pstmt.executeUpdate();
        if (deleted > 0) {
            response.sendRedirect("keranjangUser.jsp?success=Barang berhasil dihapus dari keranjang");
        } else {
            response.sendRedirect("keranjangUser.jsp?error=Gagal menghapus barang dari keranjang");
        }
        
    } catch (Exception e) {
        response.sendRedirect("keranjangUser.jsp?error=Terjadi kesalahan: " + e.getMessage());
    } finally {
        if (pstmt != null) try { pstmt.close(); } catch (SQLException e) { e.printStackTrace(); }
        if (conn != null) try { conn.close(); } catch (SQLException e) { e.printStackTrace(); }
    }
%>