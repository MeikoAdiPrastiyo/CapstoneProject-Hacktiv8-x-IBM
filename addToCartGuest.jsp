<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="java.util.*, java.sql.*" %>
<%
    // Ambil parameter dari form
    String barangIdStr = request.getParameter("barang_id");
    String quantityStr = request.getParameter("quantity");
    
    if (barangIdStr == null || quantityStr == null) {
        response.sendRedirect("home.jsp?error=Parameter tidak lengkap");
        return;
    }
    
    int barangId = Integer.parseInt(barangIdStr);
    int quantity = Integer.parseInt(quantityStr);
    
    // Ambil cart dari session (untuk guest)
    Map<Integer, Integer> cart = (Map<Integer, Integer>) session.getAttribute("cart");
    if (cart == null) {
        cart = new HashMap<Integer, Integer>();
    }
    
    // Cek stok barang dari database
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
        String sql = "SELECT quantity, nama_barang FROM barang WHERE id = ?";
        pstmt = conn.prepareStatement(sql);
        pstmt.setInt(1, barangId);
        rs = pstmt.executeQuery();
        
        if (rs.next()) {
            int stokTersedia = rs.getInt("quantity");
            String namaBarang = rs.getString("nama_barang");
            
            // Cek quantity yang sudah ada di cart
            int quantityDiCart = cart.getOrDefault(barangId, 0);
            int totalQuantity = quantityDiCart + quantity;
            
            if (totalQuantity <= stokTersedia) {
                // Update cart
                cart.put(barangId, totalQuantity);
                session.setAttribute("cart", cart);
                
                response.sendRedirect("home.jsp?success=Berhasil menambahkan " + namaBarang + " ke keranjang");
            } else {
                response.sendRedirect("home.jsp?error=Stok tidak mencukupi. Stok tersedia: " + stokTersedia);
            }
        } else {
            response.sendRedirect("home.jsp?error=Barang tidak ditemukan");
        }
        
    } catch (Exception e) {
        response.sendRedirect("home.jsp?error=Terjadi kesalahan: " + e.getMessage());
    } finally {
        if (rs != null) try { rs.close(); } catch (SQLException e) { e.printStackTrace(); }
        if (pstmt != null) try { pstmt.close(); } catch (SQLException e) { e.printStackTrace(); }
        if (conn != null) try { conn.close(); } catch (SQLException e) { e.printStackTrace(); }
    }
%>