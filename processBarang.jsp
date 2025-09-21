<%-- processBarang.jsp --%>
<%@ page import="java.sql.*, java.io.*, jakarta.servlet.http.Part" %>
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
            // Get form parameters
            String isEditStr = request.getParameter("isEdit");
            boolean isEdit = "true".equals(isEditStr);
            String barangId = request.getParameter("barangId");
            String namaBarang = request.getParameter("namaBarang");
            String quantityStr = request.getParameter("quantity");
            String hargaStr = request.getParameter("harga");
            
            // Validate required fields
            if (namaBarang == null || namaBarang.trim().isEmpty() ||
                quantityStr == null || quantityStr.trim().isEmpty() ||
                hargaStr == null || hargaStr.trim().isEmpty()) {
                success = false;
                message = "Semua field wajib diisi!";
            } else {
                int quantity = Integer.parseInt(quantityStr);
                double harga = Double.parseDouble(hargaStr);
                
                // Handle file upload
                String fileName = null;
                Part filePart = request.getPart("gambarBarang");
                
                if (filePart != null && filePart.getSize() > 0) {
                    fileName = filePart.getSubmittedFileName();
                    
                    // Validate file type
                    String contentType = filePart.getContentType();
                    if (contentType == null || !contentType.startsWith("image/")) {
                        success = false;
                        message = "File harus berupa gambar!";
                    } else if (filePart.getSize() > 10 * 1024 * 1024) {
                        success = false;
                        message = "Ukuran file maksimal 10MB!";
                    } else {
                        // Create upload directory if not exists
                        String uploadPath = application.getRealPath("/") + "uploads";
                        File uploadDir = new File(uploadPath);
                        if (!uploadDir.exists()) {
                            uploadDir.mkdirs();
                        }
                        
                        // Generate unique filename
                        String fileExtension = fileName.substring(fileName.lastIndexOf("."));
                        fileName = System.currentTimeMillis() + "_" + fileName.replaceAll("[^a-zA-Z0-9.]", "_");
                        
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
                    }
                }
                
                // Database operations (only if no file upload errors)
                if (success == false && message.isEmpty()) {
                    Class.forName("com.mysql.cj.jdbc.Driver");
                    conn = DriverManager.getConnection(url, user, dbpass);
                    
                    if (isEdit) {
                        // UPDATE operation
                        if (barangId == null || barangId.trim().isEmpty()) {
                            success = false;
                            message = "ID barang tidak valid!";
                        } else {
                            String sql;
                            if (fileName != null) {
                                sql = "UPDATE barang SET nama_barang = ?, gambar = ?, quantity = ?, harga = ? WHERE id = ?";
                                pstmt = conn.prepareStatement(sql);
                                pstmt.setString(1, namaBarang);
                                pstmt.setString(2, fileName);
                                pstmt.setInt(3, quantity);
                                pstmt.setDouble(4, harga);
                                pstmt.setString(5, barangId);
                            } else {
                                sql = "UPDATE barang SET nama_barang = ?, quantity = ?, harga = ? WHERE id = ?";
                                pstmt = conn.prepareStatement(sql);
                                pstmt.setString(1, namaBarang);
                                pstmt.setInt(2, quantity);
                                pstmt.setDouble(3, harga);
                                pstmt.setString(4, barangId);
                            }
                            
                            int rowsUpdated = pstmt.executeUpdate();
                            if (rowsUpdated > 0) {
                                success = true;
                                message = "Data barang berhasil diupdate!";
                            } else {
                                success = false;
                                message = "Gagal mengupdate data barang!";
                            }
                        }
                    } else {
                        // INSERT operation
                        String sql = "INSERT INTO barang (nama_barang, gambar, quantity, harga) VALUES (?, ?, ?, ?)";
                        pstmt = conn.prepareStatement(sql);
                        pstmt.setString(1, namaBarang);
                        pstmt.setString(2, fileName);
                        pstmt.setInt(3, quantity);
                        pstmt.setDouble(4, harga);
                        
                        int rowsInserted = pstmt.executeUpdate();
                        if (rowsInserted > 0) {
                            success = true;
                            message = "Data barang berhasil ditambahkan!";
                        } else {
                            success = false;
                            message = "Gagal menambahkan data barang!";
                        }
                    }
                }
            }
        }
        
    } catch (NumberFormatException e) {
        success = false;
        message = "Format angka tidak valid!";
    } catch (SQLException e) {
        success = false;
        message = "Database error: " + e.getMessage();
    } catch (Exception e) {
        success = false;
        message = "Error: " + e.getMessage();
    } finally {
        try {
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