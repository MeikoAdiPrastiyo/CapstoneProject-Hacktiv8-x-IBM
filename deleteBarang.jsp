<%-- deleteBarang.jsp --%>
<%@ page import="java.sql.*, java.io.File" %>
<%@ page language="java" contentType="application/json; charset=UTF-8" pageEncoding="UTF-8"%>
<%
    response.setContentType("application/json");
    response.setCharacterEncoding("UTF-8");
    
    // Database connection parameters
    String url = "jdbc:mysql://localhost:3306/webcapstone";
    String user = "root";
    String dbpass = "";
    Connection conn = null;
    PreparedStatement pstmt = null;
    ResultSet rs = null;
    
    // Variables for JSON response
    boolean success = false;
    String message = "";
    
    try {
        // Check if user is logged in
        String username = (String) session.getAttribute("username");
        if (username == null) {
            success = false;
            message = "Session expired. Please login again.";
        } else {
            // Get barang ID to delete
            String barangId = request.getParameter("barangId");
            
            if (barangId == null || barangId.trim().isEmpty()) {
                success = false;
                message = "ID barang tidak valid!";
            } else {
                // Database operations
                Class.forName("com.mysql.cj.jdbc.Driver");
                conn = DriverManager.getConnection(url, user, dbpass);
                
                // First, get the image filename to delete the file
                String selectSql = "SELECT gambar FROM barang WHERE id = ?";
                pstmt = conn.prepareStatement(selectSql);
                pstmt.setString(1, barangId);
                rs = pstmt.executeQuery();
                
                String imageName = null;
                if (rs.next()) {
                    imageName = rs.getString("gambar");
                } else {
                    success = false;
                    message = "Barang tidak ditemukan!";
                }
                
                if (message.isEmpty()) {
                    // Close the first statement
                    rs.close();
                    pstmt.close();
                    
                    // Delete the record from database
                    String deleteSql = "DELETE FROM barang WHERE id = ?";
                    pstmt = conn.prepareStatement(deleteSql);
                    pstmt.setString(1, barangId);
                    
                    int rowsDeleted = pstmt.executeUpdate();
                    
                    if (rowsDeleted > 0) {
                        // Delete the image file if it exists
                        if (imageName != null && !imageName.trim().isEmpty()) {
                            try {
                                String uploadPath = application.getRealPath("/") + "uploads";
                                File imageFile = new File(uploadPath, imageName);
                                if (imageFile.exists()) {
                                    boolean fileDeleted = imageFile.delete();
                                    if (!fileDeleted) {
                                        System.out.println("Warning: Could not delete image file: " + imageName);
                                    }
                                }
                            } catch (Exception e) {
                                System.out.println("Warning: Error deleting image file: " + e.getMessage());
                            }
                        }
                        
                        success = true;
                        message = "Data barang berhasil dihapus!";
                    } else {
                        success = false;
                        message = "Gagal menghapus data barang!";
                    }
                }
            }
        }
        
    } catch (SQLException e) {
        success = false;
        message = "Database error: " + e.getMessage();
    } catch (Exception e) {
        success = false;
        message = "Error: " + e.getMessage();
    } finally {
        try {
            if (rs != null) rs.close();
            if (pstmt != null) pstmt.close();
            if (conn != null) conn.close();
        } catch (Exception e) {
            // ignore
        }
    }
    
    // Manual JSON response (escape quotes in message)
    message = message.replace("\"", "\\\"").replace("\n", "\\n").replace("\r", "\\r");
%>
{
  "success": <%= success %>,
  "message": "<%= message %>"
}