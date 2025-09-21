<%-- getUserProfile.jsp --%>
<%@ page import="java.sql.*" %>
<%@ page language="java" contentType="text/plain; charset=UTF-8" pageEncoding="UTF-8"%>
<%
    // Database connection parameters
    String url = "jdbc:mysql://localhost:3306/webcapstone";
    String dbUser = "root";
    String dbPass = "";
    Connection conn = null;
    PreparedStatement pstmt = null;
    ResultSet rs = null;
    
    // Variables for response
    boolean success = false;
    String message = "";
    
    try {
        // Check if user is logged in
        String username = (String) session.getAttribute("username");
        if (username == null) {
            success = false;
            message = "Session expired. Please login again.";
        } else {
            // Database operations
            Class.forName("com.mysql.cj.jdbc.Driver");
            conn = DriverManager.getConnection(url, dbUser, dbPass);
            
            // Get user data with profile information
            String sql = "SELECT u.id, u.nama, u.email, u.role, u.google_photo, u.login_type, " +
                        "up.nama_lengkap, up.nomor_hp, up.alamat, up.kota, up.kode_pos, " +
                        "up.tanggal_lahir, up.jenis_kelamin, up.foto_profil, up.bio, " +
                        "up.created_at, up.updated_at " +
                        "FROM user u " +
                        "LEFT JOIN user_profile up ON u.id = up.user_id " +
                        "WHERE u.nama = ?";
            
            pstmt = conn.prepareStatement(sql);
            pstmt.setString(1, username);
            rs = pstmt.executeQuery();
            
            if (rs.next()) {
                success = true;
                message = "Data profil berhasil diambil.";
                
                // Set user data to session or request attributes for use in other pages
                session.setAttribute("user_id", rs.getString("id"));
                session.setAttribute("user_nama", rs.getString("nama"));
                session.setAttribute("user_email", rs.getString("email"));
                session.setAttribute("user_role", rs.getString("role"));
                session.setAttribute("google_photo", rs.getString("google_photo"));
                session.setAttribute("login_type", rs.getString("login_type"));
                session.setAttribute("nama_lengkap", rs.getString("nama_lengkap"));
                session.setAttribute("nomor_hp", rs.getString("nomor_hp"));
                session.setAttribute("alamat", rs.getString("alamat"));
                session.setAttribute("kota", rs.getString("kota"));
                session.setAttribute("kode_pos", rs.getString("kode_pos"));
                session.setAttribute("tanggal_lahir", rs.getString("tanggal_lahir"));
                session.setAttribute("jenis_kelamin", rs.getString("jenis_kelamin"));
                session.setAttribute("foto_profil", rs.getString("foto_profil"));
                session.setAttribute("bio", rs.getString("bio"));
                session.setAttribute("profile_created_at", rs.getString("created_at"));
                session.setAttribute("profile_updated_at", rs.getString("updated_at"));
                
                // Determine display photo
                String fotoProfil = rs.getString("foto_profil");
                String googlePhoto = rs.getString("google_photo");
                String loginType = rs.getString("login_type");
                String displayPhoto = "";
                String photoSource = "";
                
                if (fotoProfil != null && !fotoProfil.trim().isEmpty()) {
                    displayPhoto = "uploads/" + fotoProfil;
                    photoSource = "local";
                } else if (googlePhoto != null && !googlePhoto.trim().isEmpty() && "google".equals(loginType)) {
                    displayPhoto = googlePhoto;
                    photoSource = "google";
                } else {
                    displayPhoto = "https://via.placeholder.com/120x120?text=No+Photo";
                    photoSource = "default";
                }
                
                session.setAttribute("display_photo", displayPhoto);
                session.setAttribute("photo_source", photoSource);
                
            } else {
                success = false;
                message = "User tidak ditemukan!";
            }
        }
        
    } catch (SQLException e) {
        success = false;
        message = "Database error: " + e.getMessage();
    } catch (Exception e) {
        success = false;
        message = "Error: " + e.getMessage();
    } finally {
        // Close resources
        try {
            if (rs != null) rs.close();
            if (pstmt != null) pstmt.close();
            if (conn != null) conn.close();
        } catch (Exception e) {
            // ignore
        }
    }
    
    // Set response attributes
    request.setAttribute("success", success);
    request.setAttribute("message", message);
    
    // Output simple response
    if (success) {
        out.print("SUCCESS: " + message);
    } else {
        out.print("ERROR: " + message);
    }
%>