<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="java.sql.*" %>
<%
    // Cek apakah user sudah login
    Integer userId = (Integer) session.getAttribute("user_id");
    if (userId == null) {
        response.sendRedirect("login.html");
        return;
    }
    
    // Ambil parameter
    String barangIdStr = request.getParameter("barang_id");
    String quantityStr = request.getParameter("quantity");
    
    if (barangIdStr == null || quantityStr == null) {
        response.sendRedirect("home.jsp?error=Parameter tidak lengkap");
        return;
    }
    
    int barangId = Integer.parseInt(barangIdStr);
    int quantity = Integer.parseInt(quantityStr);
    
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
        String checkStokSql = "SELECT quantity, nama_barang FROM barang WHERE id = ?";
        pstmt = conn.prepareStatement(checkStokSql);
        pstmt.setInt(1, barangId);
        rs = pstmt.executeQuery();
        
        if (rs.next()) {
            int stokTersedia = rs.getInt("quantity");
            String namaBarang = rs.getString("nama_barang");
            rs.close();
            pstmt.close();
            
            // Cek apakah barang sudah ada di keranjang user
            String checkCartSql = "SELECT quantity FROM keranjang WHERE user_id = ? AND barang_id = ?";
            pstmt = conn.prepareStatement(checkCartSql);
            pstmt.setInt(1, userId);
            pstmt.setInt(2, barangId);
            rs = pstmt.executeQuery();
            
            if (rs.next()) {
                // Barang sudah ada, update quantity
                int quantityLama = rs.getInt("quantity");
                int quantityBaru = quantityLama + quantity;
                rs.close();
                pstmt.close();
                
                if (quantityBaru <= stokTersedia) {
                    String updateSql = "UPDATE keranjang SET quantity = ? WHERE user_id = ? AND barang_id = ?";
                    pstmt = conn.prepareStatement(updateSql);
                    pstmt.setInt(1, quantityBaru);
                    pstmt.setInt(2, userId);
                    pstmt.setInt(3, barangId);
                    pstmt.executeUpdate();
                    
                    response.sendRedirect("home.jsp?success=Berhasil menambahkan " + namaBarang + " ke keranjang");
                } else {
                    response.sendRedirect("home.jsp?error=Stok tidak mencukupi. Stok tersedia: " + stokTersedia);
                }
            } else {
                // Barang belum ada, insert baru
                rs.close();
                pstmt.close();
                
                if (quantity <= stokTersedia) {
                    String insertSql = "INSERT INTO keranjang (user_id, barang_id, quantity) VALUES (?, ?, ?)";
                    pstmt = conn.prepareStatement(insertSql);
                    pstmt.setInt(1, userId);
                    pstmt.setInt(2, barangId);
                    pstmt.setInt(3, quantity);
                    pstmt.executeUpdate();
                    
                    response.sendRedirect("home.jsp?success=Berhasil menambahkan " + namaBarang + " ke keranjang");
                } else {
                    response.sendRedirect("home.jsp?error=Stok tidak mencukupi. Stok tersedia: " + stokTersedia);
                }
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