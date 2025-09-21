<%-- deleteUser.jsp --%>
<%@ page language="java" contentType="application/json; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="java.sql.*" %>
<%
    // Check if user is logged in
    String username = (String) session.getAttribute("username");
    if (username == null) {
        response.sendRedirect("login.html");
        return;
    }
    
    // Get user ID to delete
    String userId = request.getParameter("userId");
    
    // Initialize response object
    boolean success = false;
    String message = "";
    
    // Validate input
    if (userId == null || userId.trim().isEmpty()) {
        message = "ID pengguna tidak valid";
    } else {
        // Database connection
        String url = "jdbc:mysql://localhost:3306/webcapstone";
        String user = "root";
        String dbpass = "";
        Connection conn = null;
        PreparedStatement pstmt = null;
        
        try {
            Class.forName("com.mysql.cj.jdbc.Driver");
            conn = DriverManager.getConnection(url, user, dbpass);
            
            // Delete user from database
            String sql = "DELETE FROM user WHERE id = ?";
            pstmt = conn.prepareStatement(sql);
            pstmt.setString(1, userId);
            
            int result = pstmt.executeUpdate();
            
            if (result > 0) {
                success = true;
                message = "Pengguna berhasil dihapus";
            } else {
                message = "Pengguna tidak ditemukan atau gagal dihapus";
            }
            
        } catch(Exception e) {
            message = "Error: " + e.getMessage();
            e.printStackTrace(); // Print stack trace for debugging
        } finally {
            if (pstmt != null) try { pstmt.close(); } catch (SQLException e) { e.printStackTrace(); }
            if (conn != null) try { conn.close(); } catch (SQLException e) { e.printStackTrace(); }
        }
    }
    
    // Build JSON response
    String jsonResponse = "{\"success\":" + success + ",\"message\":\"" + message.replace("\"", "\\\"") + "\"}";
    
    // Send JSON response
    out.print(jsonResponse);
%>