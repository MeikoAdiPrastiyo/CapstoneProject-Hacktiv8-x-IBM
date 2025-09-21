<%-- updateUserProfile.jsp --%>
<%@ page import="java.sql.*, java.io.*, jakarta.servlet.http.Part, java.security.MessageDigest, java.nio.charset.StandardCharsets" %>
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
    String photoUrl = "";
    
    try {
        // Check if user is logged in
        String username = (String) session.getAttribute("username");
        if (username == null) {
            success = false;
            message = "Session expired. Please login again.";
        } else {
            // Get form parameters
            String userId = request.getParameter("userId");
            String nama = request.getParameter("nama");
            String email = request.getParameter("email");
            String namaLengkap = request.getParameter("namaLengkap");
            String nomorHp = request.getParameter("nomorHp");
            String alamat = request.getParameter("alamat");
            String kota = request.getParameter("kota");
            String kodePos = request.getParameter("kodePos");
            String tanggalLahir = request.getParameter("tanggalLahir");
            String jenisKelamin = request.getParameter("jenisKelamin");
            String bio = request.getParameter("bio");
            String currentPassword = request.getParameter("currentPassword");
            String newPassword = request.getParameter("newPassword");
            
            // Validate required fields
            if (userId == null || userId.trim().isEmpty() ||
                nama == null || nama.trim().isEmpty() ||
                email == null || email.trim().isEmpty()) {
                success = false;
                message = "Data user tidak valid!";
            } else {
                Class.forName("com.mysql.cj.jdbc.Driver");
                conn = DriverManager.getConnection(url, user, dbpass);
                
                // Handle photo upload first
                String fileName = null;
                Part filePart = request.getPart("fotoProfil");
                
                if (filePart != null && filePart.getSize() > 0) {
                    fileName = filePart.getSubmittedFileName();
                    
                    // Validate file type
                    String contentType = filePart.getContentType();
                    if (contentType == null || !contentType.startsWith("image/")) {
                        success = false;
                        message = "File harus berupa gambar!";
                    } else if (filePart.getSize() > 5 * 1024 * 1024) {
                        success = false;
                        message = "Ukuran file maksimal 5MB!";
                    } else {
                        // Create upload directory if not exists
                        String uploadPath = application.getRealPath("/") + "uploads";
                        File uploadDir = new File(uploadPath);
                        if (!uploadDir.exists()) {
                            uploadDir.mkdirs();
                        }
                        
                        // Generate unique filename
                        String fileExtension = fileName.substring(fileName.lastIndexOf("."));
                        fileName = "profile_" + userId + "_" + System.currentTimeMillis() + fileExtension;
                        
                        // Save file
                        File file = new File(uploadDir, fileName);
                        try (InputStream input = filePart.getInputStream();
                             FileOutputStream output = new FileOutputStream(file)) {
                            byte[] buffer = new byte[1024];
                            int bytesRead;
                            while ((bytesRead = input.read(buffer)) != -1) {
                                output.write(buffer, 0, bytesRead);
                            }
                        }
                        photoUrl = fileName;
                    }
                }
                
                // Continue only if no file upload errors
                if (success == false && message.isEmpty()) {
                    // Handle password change if requested
                    boolean passwordChanged = false;
                    if (currentPassword != null && !currentPassword.trim().isEmpty() &&
                        newPassword != null && !newPassword.trim().isEmpty()) {
                        
                        // Verify current password
                        String verifySql = "SELECT password FROM user WHERE id = ?";
                        pstmt = conn.prepareStatement(verifySql);
                        pstmt.setString(1, userId);
                        rs = pstmt.executeQuery();
                        
                        if (rs.next()) {
                            String storedPassword = rs.getString("password");
                            boolean passwordMatch = false;
                            
                            // Debug: Log password comparison (remove in production)
                            System.out.println("DEBUG - Stored password: " + storedPassword);
                            System.out.println("DEBUG - Input password: " + currentPassword);
                            
                            // Try multiple password formats to determine what's stored in DB
                            
                            // 1. Check if password is stored as plain text (not recommended but common in development)
                            if (storedPassword.equals(currentPassword)) {
                                passwordMatch = true;
                                System.out.println("DEBUG - Password matched as plain text");
                            }
                            
                            // 2. Check if password is stored as SHA-256 hash
                            if (!passwordMatch) {
                                MessageDigest md = MessageDigest.getInstance("SHA-256");
                                byte[] hashedBytes = md.digest(currentPassword.getBytes(StandardCharsets.UTF_8));
                                StringBuilder sb = new StringBuilder();
                                for (byte b : hashedBytes) {
                                    sb.append(String.format("%02x", b));
                                }
                                String hashedCurrentPassword = sb.toString();
                                System.out.println("DEBUG - SHA-256 hash: " + hashedCurrentPassword);
                                
                                if (storedPassword.equals(hashedCurrentPassword)) {
                                    passwordMatch = true;
                                    System.out.println("DEBUG - Password matched as SHA-256");
                                }
                            }
                            
                            // 3. Check if password is stored as MD5 hash (legacy)
                            if (!passwordMatch) {
                                MessageDigest md5 = MessageDigest.getInstance("MD5");
                                byte[] md5Bytes = md5.digest(currentPassword.getBytes(StandardCharsets.UTF_8));
                                StringBuilder md5Sb = new StringBuilder();
                                for (byte b : md5Bytes) {
                                    md5Sb.append(String.format("%02x", b));
                                }
                                String md5Hash = md5Sb.toString();
                                System.out.println("DEBUG - MD5 hash: " + md5Hash);
                                
                                if (storedPassword.equals(md5Hash)) {
                                    passwordMatch = true;
                                    System.out.println("DEBUG - Password matched as MD5");
                                }
                            }
                            
                            if (!passwordMatch) {
                                success = false;
                                message = "Password saat ini salah! Debug: Stored='" + storedPassword + "', Input='" + currentPassword + "'";
                            } else {
                                // Hash new password using the same method as stored password
                                // Determine the hashing method based on what matched above
                                String hashedNewPassword;
                                
                                if (storedPassword.equals(currentPassword)) {
                                    // Store as plain text (match existing format)
                                    hashedNewPassword = newPassword;
                                } else if (storedPassword.length() == 32) {
                                    // Likely MD5 hash (32 characters)
                                    MessageDigest md5 = MessageDigest.getInstance("MD5");
                                    byte[] md5Bytes = md5.digest(newPassword.getBytes(StandardCharsets.UTF_8));
                                    StringBuilder md5Sb = new StringBuilder();
                                    for (byte b : md5Bytes) {
                                        md5Sb.append(String.format("%02x", b));
                                    }
                                    hashedNewPassword = md5Sb.toString();
                                } else {
                                    // Default to SHA-256 hash (64 characters)
                                    MessageDigest sha256 = MessageDigest.getInstance("SHA-256");
                                    byte[] sha256Bytes = sha256.digest(newPassword.getBytes(StandardCharsets.UTF_8));
                                    StringBuilder sha256Sb = new StringBuilder();
                                    for (byte b : sha256Bytes) {
                                        sha256Sb.append(String.format("%02x", b));
                                    }
                                    hashedNewPassword = sha256Sb.toString();
                                }
                                
                                // Update password
                                rs.close();
                                pstmt.close();
                                
                                String updatePasswordSql = "UPDATE user SET password = ? WHERE id = ?";
                                pstmt = conn.prepareStatement(updatePasswordSql);
                                pstmt.setString(1, hashedNewPassword);
                                pstmt.setString(2, userId);
                                pstmt.executeUpdate();
                                passwordChanged = true;
                                pstmt.close();
                            }
                        } else {
                            success = false;
                            message = "User tidak ditemukan!";
                        }
                        
                        if (rs != null) rs.close();
                        if (pstmt != null) pstmt.close();
                    }
                    
                    // Continue if no password error
                    if (success == false && message.isEmpty()) {
                        // Update user basic info (nama and email)
                        String updateUserSql = "UPDATE user SET nama = ?, email = ? WHERE id = ?";
                        pstmt = conn.prepareStatement(updateUserSql);
                        pstmt.setString(1, nama);
                        pstmt.setString(2, email);
                        pstmt.setString(3, userId);
                        int userRowsUpdated = pstmt.executeUpdate();
                        pstmt.close();
                        
                        // Check if profile exists
                        String checkProfileSql = "SELECT id FROM user_profile WHERE user_id = ?";
                        pstmt = conn.prepareStatement(checkProfileSql);
                        pstmt.setString(1, userId);
                        rs = pstmt.executeQuery();
                        boolean profileExists = rs.next();
                        rs.close();
                        pstmt.close();
                        
                        int profileRowsAffected = 0;
                        
                        if (profileExists) {
                            // Update existing profile
                            String updateProfileSql;
                            if (fileName != null) {
                                updateProfileSql = "UPDATE user_profile SET nama_lengkap = ?, nomor_hp = ?, alamat = ?, " +
                                                 "kota = ?, kode_pos = ?, tanggal_lahir = ?, jenis_kelamin = ?, " +
                                                 "foto_profil = ?, bio = ?, updated_at = NOW() WHERE user_id = ?";
                                pstmt = conn.prepareStatement(updateProfileSql);
                                pstmt.setString(1, namaLengkap);
                                pstmt.setString(2, nomorHp);
                                pstmt.setString(3, alamat);
                                pstmt.setString(4, kota);
                                pstmt.setString(5, kodePos);
                                pstmt.setString(6, tanggalLahir);
                                pstmt.setString(7, jenisKelamin);
                                pstmt.setString(8, fileName);
                                pstmt.setString(9, bio);
                                pstmt.setString(10, userId);
                            } else {
                                updateProfileSql = "UPDATE user_profile SET nama_lengkap = ?, nomor_hp = ?, alamat = ?, " +
                                                 "kota = ?, kode_pos = ?, tanggal_lahir = ?, jenis_kelamin = ?, " +
                                                 "bio = ?, updated_at = NOW() WHERE user_id = ?";
                                pstmt = conn.prepareStatement(updateProfileSql);
                                pstmt.setString(1, namaLengkap);
                                pstmt.setString(2, nomorHp);
                                pstmt.setString(3, alamat);
                                pstmt.setString(4, kota);
                                pstmt.setString(5, kodePos);
                                pstmt.setString(6, tanggalLahir);
                                pstmt.setString(7, jenisKelamin);
                                pstmt.setString(8, bio);
                                pstmt.setString(9, userId);
                            }
                            profileRowsAffected = pstmt.executeUpdate();
                            pstmt.close();
                        } else {
                            // Insert new profile
                            String insertProfileSql = "INSERT INTO user_profile (user_id, nama_lengkap, nomor_hp, alamat, " +
                                                     "kota, kode_pos, tanggal_lahir, jenis_kelamin, foto_profil, bio, " +
                                                     "created_at, updated_at) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, NOW(), NOW())";
                            pstmt = conn.prepareStatement(insertProfileSql);
                            pstmt.setString(1, userId);
                            pstmt.setString(2, namaLengkap);
                            pstmt.setString(3, nomorHp);
                            pstmt.setString(4, alamat);
                            pstmt.setString(5, kota);
                            pstmt.setString(6, kodePos);
                            pstmt.setString(7, tanggalLahir);
                            pstmt.setString(8, jenisKelamin);
                            pstmt.setString(9, fileName);
                            pstmt.setString(10, bio);
                            profileRowsAffected = pstmt.executeUpdate();
                            pstmt.close();
                        }
                        
                        // Check if updates were successful
                        if (userRowsUpdated > 0 || profileRowsAffected > 0) {
                            success = true;
                            message = "Profil berhasil diperbarui!";
                            if (passwordChanged) {
                                message += " Password juga berhasil diubah.";
                            }
                        } else {
                            success = false;
                            message = "Tidak ada perubahan data!";
                        }
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
    
    // Build JSON response
    StringBuilder jsonResponse = new StringBuilder();
    jsonResponse.append("{");
    jsonResponse.append("\"success\": ").append(success).append(",");
    jsonResponse.append("\"message\": \"").append(message).append("\"");
    if (!photoUrl.isEmpty()) {
        jsonResponse.append(",\"photoUrl\": \"").append(photoUrl).append("\"");
    }
    jsonResponse.append("}");
%>
<%= jsonResponse.toString() %>