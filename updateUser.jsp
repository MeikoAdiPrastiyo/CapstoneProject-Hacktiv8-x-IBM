<%-- updateUser.jsp --%>
<%@ page language="java" contentType="application/json; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="java.sql.*" %>
<%
    // Check if user is logged in
    String username = (String) session.getAttribute("username");
    if (username == null) {
        response.sendRedirect("login.html");
        return;
    }
    
    // Get form data
    String userId = request.getParameter("userId");
    String editName = request.getParameter("editName");
    String editEmail = request.getParameter("editEmail");
    String editPassword = request.getParameter("editPassword");
    
    // For debugging
    System.out.println("userId: " + userId);
    System.out.println("editName: " + editName);
    System.out.println("editEmail: " + editEmail);
    
    // Initialize response object
    boolean success = false;
    String message = "";
    
    // Validate input
    if (userId == null || userId.trim().isEmpty() || 
        editName == null || editName.trim().isEmpty() || 
        editEmail == null || editEmail.trim().isEmpty()) {
        
        message = "Semua field harus diisi kecuali password";
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
            
            // SQL query depends on whether password is being updated
            String sql;
            if (editPassword != null && !editPassword.trim().isEmpty()) {
                sql = "UPDATE user SET nama = ?, email = ?, password = ? WHERE id = ?";
                pstmt = conn.prepareStatement(sql);
                pstmt.setString(1, editName);
                pstmt.setString(2, editEmail);
                pstmt.setString(3, editPassword);
                pstmt.setString(4, userId);
            } else {
                sql = "UPDATE user SET nama = ?, email = ? WHERE id = ?";
                pstmt = conn.prepareStatement(sql);
                pstmt.setString(1, editName);
                pstmt.setString(2, editEmail);
                pstmt.setString(3, userId);
            }
            
            int result = pstmt.executeUpdate();
            
            if (result > 0) {
                success = true;
                message = "Data pengguna berhasil diperbarui";
            } else {
                message = "Gagal memperbarui data pengguna";
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