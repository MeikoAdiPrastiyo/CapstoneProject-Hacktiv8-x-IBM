<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="java.util.*, java.sql.*" %>
<%
    String barangIdStr = request.getParameter("barang_id");
    String quantityStr = request.getParameter("quantity");
    
    if (barangIdStr == null || quantityStr == null) {
        response.sendRedirect("keranjangGuest.jsp?error=Parameter tidak lengkap");
        return;
    }
    
    int barangId = Integer.parseInt(barangIdStr);
    int newQuantity = Integer.parseInt(quantityStr);
    
    // Ambil cart dari session
    Map<Integer, Integer> cart = (Map<Integer, Integer>) session.getAttribute("cart");
    if (cart == null) {
        response.sendRedirect("keranjangGuest.jsp?error=Keranjang kosong");
        return;
    }
    
    // Cek stok dari database
    String url = "jdbc:mysql://localhost:3306/webcapstone";
    String user = "root";
    String dbpass = "";
    Connection conn = null;
    PreparedStatement pstmt = null;
    ResultSet rs = null;
    
    try {
        Class.forName("com.mysql.cj.jdbc.Driver");
        conn = DriverManager.getConnection(url, user, dbpass);
        
        String sql = "SELECT quantity, nama_barang FROM barang WHERE id = ?";
        pstmt = conn.prepareStatement(sql);
        pstmt.setInt(1, barangId);
        rs = pstmt.executeQuery();
        
        if (rs.next()) {
            int stokTersedia = rs.getInt("quantity");
            String namaBarang = rs.getString("nama_barang");
            
            if (newQuantity <= stokTersedia && newQuantity > 0) {
                cart.put(barangId, newQuantity);
                session.setAttribute("cart", cart);
                response.sendRedirect("keranjangGuest.jsp?success=Berhasil update " + namaBarang);
            } else {
                response.sendRedirect("keranjangGuest.jsp?error=Stok tidak mencukupi. Stok tersedia: " + stokTersedia);
            }
        } else {
            response.sendRedirect("keranjangGuest.jsp?error=Barang tidak ditemukan");
        }
        
    } catch (Exception e) {
        response.sendRedirect("keranjangGuest.jsp?error=Terjadi kesalahan: " + e.getMessage());
    } finally {
        if (rs != null) try { rs.close(); } catch (SQLException e) { e.printStackTrace(); }
        if (pstmt != null) try { pstmt.close(); } catch (SQLException e) { e.printStackTrace(); }
        if (conn != null) try { conn.close(); } catch (SQLException e) { e.printStackTrace(); }
    }
%>