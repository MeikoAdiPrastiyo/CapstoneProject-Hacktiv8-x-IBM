<%-- deleteProfilePhoto.jsp - Handler for deleting profile photos --%>
<%@ page import="java.sql.*" %>
<%@ page import="java.io.*" %>
<%@ page language="java" contentType="application/json; charset=UTF-8" pageEncoding="UTF-8"%>
<%
    response.setContentType("application/json");
    response.setCharacterEncoding("UTF-8");
    
    // Check if user is logged in
    String username = (String) session.getAttribute("username");
    if (username == null) {
        out.print("{\"success\": false, \"message\": \"Sesi tidak valid, silakan login kembali\"}");
        return;
    }
    
    String userId = request.getParameter("userId");
    
    if (userId == null || userId.trim().isEmpty()) {
        out.print("{\"success\": false, \"message\": \"User ID tidak ditemukan\"}");
        return;
    }
    
    String url = "jdbc:mysql://localhost:3306/webcapstone";
    String dbUser = "root";
    String dbPass = "";
    Connection conn = null;
    PreparedStatement pstmt = null;
    ResultSet rs = null;
    
    try {
        Class.forName("com.mysql.cj.jdbc.Driver");
        conn = DriverManager.getConnection(url, dbUser, dbPass);
        
        // Get current photo filename before deleting
        String getCurrentPhotoSql = "SELECT foto_profil FROM user_profile WHERE user_id = ?";
        pstmt = conn.prepareStatement(getCurrentPhotoSql);
        pstmt.setString(1, userId);
        rs = pstmt.executeQuery();
        
        String currentPhotoFilename = null;
        if (rs.next()) {
            currentPhotoFilename = rs.getString("foto_profil");
        }
        
        rs.close();
        pstmt.close();
        
        // Update database - set foto_profil to NULL
        String updateSql = "UPDATE user_profile SET foto_profil = NULL WHERE user_id = ?";
        pstmt = conn.prepareStatement(updateSql);
        pstmt.setString(1, userId);
        
        int rowsAffected = pstmt.executeUpdate();
        
        if (rowsAffected > 0) {
            // Try to delete the physical file if it exists
            if (currentPhotoFilename != null && !currentPhotoFilename.trim().isEmpty()) {
                try {
                    String uploadsPath = application.getRealPath("/") + "uploads/";
                    File photoFile = new File(uploadsPath + currentPhotoFilename);
                    
                    if (photoFile.exists()) {
                        boolean deleted = photoFile.delete();
                        if (deleted) {
                            out.print("{\"success\": true, \"message\": \"Foto profil berhasil dihapus dan file dihapus dari server\"}");
                        } else {
                            out.print("{\"success\": true, \"message\": \"Foto profil berhasil dihapus dari database, tetapi file tidak dapat dihapus dari server\"}");
                        }
                    } else {
                        out.print("{\"success\": true, \"message\": \"Foto profil berhasil dihapus (file tidak ditemukan di server)\"}");
                    }
                } catch (Exception fileException) {
                    // File deletion failed, but database update succeeded
                    out.print("{\"success\": true, \"message\": \"Foto profil berhasil dihapus dari database, tetapi terjadi error saat menghapus file: " + fileException.getMessage() + "\"}");
                }
            } else {
                out.print("{\"success\": true, \"message\": \"Foto profil berhasil dihapus\"}");
            }
        } else {
            out.print("{\"success\": false, \"message\": \"Tidak ada foto yang dihapus atau profil tidak ditemukan\"}");
        }
        
    } catch (ClassNotFoundException e) {
        out.print("{\"success\": false, \"message\": \"Driver database tidak ditemukan: " + e.getMessage() + "\"}");
    } catch (SQLException e) {
        out.print("{\"success\": false, \"message\": \"Error database: " + e.getMessage() + "\"}");
    } catch (Exception e) {
        out.print("{\"success\": false, \"message\": \"Terjadi kesalahan: " + e.getMessage() + "\"}");
    } finally {
        try {
            if (rs != null) rs.close();
            if (pstmt != null) pstmt.close();
            if (conn != null) conn.close();
        } catch (SQLException e) {
            // Log error but don't change response
        }
    }
%>