<%-- removeFromCart.jsp --%>
<%@ page language="java" contentType="application/json; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="java.sql.*" %>
<%@ page import="com.google.gson.Gson" %>
<%@ page import="java.util.HashMap" %>
<%@ page import="java.util.Map" %>
<%
    response.setContentType("application/json");
    
    // Create response map
    Map<String, Object> responseMap = new HashMap<>();
    Gson gson = new Gson();
    
    try {
        // Check if user is logged in
        String email = (String) session.getAttribute("email");
        if (email == null) {
            responseMap.put("success", false);
            responseMap.put("message", "Silakan login terlebih dahulu");
            out.print(gson.toJson(responseMap));
            return;
        }
        
        // Get parameters
        String keranjangIdStr = request.getParameter("keranjangId");
        
        if (keranjangIdStr == null) {
            responseMap.put("success", false);
            responseMap.put("message", "Parameter tidak lengkap");
            out.print(gson.toJson(responseMap));
            return;
        }
        
        int keranjangId = Integer.parseInt(keranjangIdStr);
        
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
            String getUserSql = "SELECT id FROM user WHERE email = ?";
            pstmt = conn.prepareStatement(getUserSql);
            pstmt.setString(1, email);
            rs = pstmt.executeQuery();
            
            int userId = 0;
            if (rs.next()) {
                userId = rs.getInt("id");
            } else {
                responseMap.put("success", false);
                responseMap.put("message", "User tidak ditemukan");
                out.print(gson.toJson(responseMap));
                return;
            }
            rs.close();
            pstmt.close();
            
            // Get item name before deleting
            String getItemSql = "SELECT b.nama_barang " +
                               "FROM keranjang k " +
                               "JOIN barang b ON k.barang_id = b.id " +
                               "WHERE k.id = ? AND k.user_id = ?";
            pstmt = conn.prepareStatement(getItemSql);
            pstmt.setInt(1, keranjangId);
            pstmt.setInt(2, userId);
            rs = pstmt.executeQuery();
            
            String namaBarang = "";
            if (rs.next()) {
                namaBarang = rs.getString("nama_barang");
            } else {
                responseMap.put("success", false);
                responseMap.put("message", "Item keranjang tidak ditemukan");
                out.print(gson.toJson(responseMap));
                return;
            }
            rs.close();
            pstmt.close();
            
            // Delete cart item
            String deleteSql = "DELETE FROM keranjang WHERE id = ? AND user_id = ?";
            pstmt = conn.prepareStatement(deleteSql);
            pstmt.setInt(1, keranjangId);
            pstmt.setInt(2, userId);
            
            int rowsAffected = pstmt.executeUpdate();
            
            if (rowsAffected > 0) {
                responseMap.put("success", true);
                responseMap.put("message", namaBarang + " berhasil dihapus dari keranjang");
            } else {
                responseMap.put("success", false);
                responseMap.put("message", "Gagal menghapus item dari keranjang");
            }
            
        } catch (Exception e) {
            responseMap.put("success", false);
            responseMap.put("message", "Error database: " + e.getMessage());
        } finally {
            if (rs != null) try { rs.close(); } catch (SQLException e) { e.printStackTrace(); }
            if (pstmt != null) try { pstmt.close(); } catch (SQLException e) { e.printStackTrace(); }
            if (conn != null) try { conn.close(); } catch (SQLException e) { e.printStackTrace(); }
        }
        
    } catch (Exception e) {
        responseMap.put("success", false);
        responseMap.put("message", "Error: " + e.getMessage());
    }
    
    out.print(gson.toJson(responseMap));
%>