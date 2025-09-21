<%-- processPayment.jsp --%>
<%@ page language="java" contentType="text/plain; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="java.sql.*, java.io.*, java.util.*" %>
<%@ page import="jakarta.servlet.http.Part" %>
<%@ page import="java.nio.file.Paths" %>
<%@ page import="java.text.SimpleDateFormat" %>
<%
    response.setContentType("text/plain");
    
    // Check if user is logged in
    String username = (String) session.getAttribute("username");
    String email = (String) session.getAttribute("email");
    if (username == null || email == null) {
        out.print("error: User not logged in");
        return;
    }
    
    // Database connection
    String url = "jdbc:mysql://localhost:3306/webcapstone";
    String user = "root";
    String dbpass = "";
    Connection conn = null;
    PreparedStatement pstmt = null;
    ResultSet rs = null;
    
    try {
        // Get form parameters
        String transaksiIdParam = request.getParameter("transaksiId");
        String nomorRekening = request.getParameter("nomorRekening");
        String namaPengirim = request.getParameter("namaPengirim");
        String tanggalTransferParam = request.getParameter("tanggalTransfer");
        String catatan = request.getParameter("catatan");
        
        // Validate required parameters
        if (transaksiIdParam == null || transaksiIdParam.trim().isEmpty() ||
            nomorRekening == null || nomorRekening.trim().isEmpty() ||
            namaPengirim == null || namaPengirim.trim().isEmpty() ||
            tanggalTransferParam == null || tanggalTransferParam.trim().isEmpty()) {
            out.print("error: Data tidak lengkap");
            return;
        }
        
        int transaksiId = Integer.parseInt(transaksiIdParam);
        
        // Parse tanggal transfer
        SimpleDateFormat sdf = new SimpleDateFormat("yyyy-MM-dd'T'HH:mm");
        java.util.Date tanggalTransfer = sdf.parse(tanggalTransferParam);
        Timestamp tanggalTransferTimestamp = new Timestamp(tanggalTransfer.getTime());
        
        // Connect to database
        Class.forName("com.mysql.cj.jdbc.Driver");
        conn = DriverManager.getConnection(url, user, dbpass);
        
        // Start transaction
        conn.setAutoCommit(false);
        
        // Get user ID
        int userId = 0;
        String getUserSql = "SELECT id FROM user WHERE email = ?";
        pstmt = conn.prepareStatement(getUserSql);
        pstmt.setString(1, email);
        rs = pstmt.executeQuery();
        
        if (rs.next()) {
            userId = rs.getInt("id");
        } else {
            out.print("error: User not found");
            return;
        }
        rs.close();
        pstmt.close();
        
        // Verify transaction belongs to user and is pending
        String verifyTransaksiSql = "SELECT status_pembayaran FROM transaksi WHERE id = ? AND user_id = ?";
        pstmt = conn.prepareStatement(verifyTransaksiSql);
        pstmt.setInt(1, transaksiId);
        pstmt.setInt(2, userId);
        rs = pstmt.executeQuery();
        
        if (!rs.next()) {
            out.print("error: Transaksi tidak ditemukan");
            conn.rollback();
            return;
        }
        
        String statusPembayaran = rs.getString("status_pembayaran");
        if (!statusPembayaran.equals("pending")) {
            out.print("error: Transaksi sudah diproses");
            conn.rollback();
            return;
        }
        rs.close();
        pstmt.close();
        
        // Handle file upload
        String uploadPath = application.getRealPath("") + File.separator + "uploads" + File.separator + "bukti_pembayaran";
        File uploadDir = new File(uploadPath);
        if (!uploadDir.exists()) {
            uploadDir.mkdirs();
        }
        
        String fileName = null;
        String originalFileName = null;
        
        // Check if request is multipart
        String contentType = request.getContentType();
        if (contentType != null && contentType.indexOf("multipart/form-data") >= 0) {
            Collection<Part> parts = request.getParts();
            
            for (Part part : parts) {
                if (part.getName().equals("buktiFile")) {
                    String submittedFileName = part.getSubmittedFileName();
                    if (submittedFileName != null && !submittedFileName.trim().isEmpty()) {
                        originalFileName = submittedFileName;
                        
                        // Validate file type
                        String fileExtension = "";
                        int lastDotIndex = originalFileName.lastIndexOf(".");
                        if (lastDotIndex > 0) {
                            fileExtension = originalFileName.substring(lastDotIndex + 1).toLowerCase();
                        }
                        
                        if (!fileExtension.equals("jpg") && !fileExtension.equals("jpeg") && 
                            !fileExtension.equals("png") && !fileExtension.equals("pdf")) {
                            out.print("error: Format file tidak didukung. Gunakan JPG, PNG, atau PDF");
                            conn.rollback();
                            return;
                        }
                        
                        // Validate file size (2MB)
                        if (part.getSize() > 2 * 1024 * 1024) {
                            out.print("error: Ukuran file maksimal 2MB");
                            conn.rollback();
                            return;
                        }
                        
                        // Generate unique filename
                        String timestamp = String.valueOf(System.currentTimeMillis());
                        fileName = "bukti_" + transaksiId + "_" + timestamp + "." + fileExtension;
                        String filePath = uploadPath + File.separator + fileName;
                        
                        // Save file
                        try (InputStream input = part.getInputStream();
                             FileOutputStream output = new FileOutputStream(filePath)) {
                            
                            byte[] buffer = new byte[1024];
                            int bytesRead;
                            while ((bytesRead = input.read(buffer)) != -1) {
                                output.write(buffer, 0, bytesRead);
                            }
                        }
                        break;
                    }
                }
            }
        }
        
        if (fileName == null) {
            out.print("error: File bukti pembayaran tidak ditemukan");
            conn.rollback();
            return;
        }
        
        // Check if bukti_pembayaran already exists for this transaction
        String checkBuktiSql = "SELECT id FROM bukti_pembayaran WHERE transaksi_id = ?";
        pstmt = conn.prepareStatement(checkBuktiSql);
        pstmt.setInt(1, transaksiId);
        rs = pstmt.executeQuery();
        
        boolean buktiExists = rs.next();
        rs.close();
        pstmt.close();
        
        if (buktiExists) {
            // Update existing record
            String updateBuktiSql = "UPDATE bukti_pembayaran SET bukti_transfer = ?, nomor_rekening = ?, " +
                                  "nama_pengirim = ?, tanggal_transfer = ?, catatan = ?, " +
                                  "status_verifikasi = 'approved', created_at = CURRENT_TIMESTAMP " +
                                  "WHERE transaksi_id = ?";
            pstmt = conn.prepareStatement(updateBuktiSql);
            pstmt.setString(1, fileName);
            pstmt.setString(2, nomorRekening);
            pstmt.setString(3, namaPengirim);
            pstmt.setTimestamp(4, tanggalTransferTimestamp);
            pstmt.setString(5, catatan);
            pstmt.setInt(6, transaksiId);
            
            int updateResult = pstmt.executeUpdate();
            pstmt.close();
            
            if (updateResult <= 0) {
                out.print("error: Gagal mengupdate bukti pembayaran");
                conn.rollback();
                return;
            }
        } else {
            // Insert new record
            String insertBuktiSql = "INSERT INTO bukti_pembayaran (transaksi_id, bukti_transfer, " +
                                  "nomor_rekening, nama_pengirim, tanggal_transfer, catatan, " +
                                  "status_verifikasi, created_at) VALUES (?, ?, ?, ?, ?, ?, 'approved', CURRENT_TIMESTAMP)";
            pstmt = conn.prepareStatement(insertBuktiSql);
            pstmt.setInt(1, transaksiId);
            pstmt.setString(2, fileName);
            pstmt.setString(3, nomorRekening);
            pstmt.setString(4, namaPengirim);
            pstmt.setTimestamp(5, tanggalTransferTimestamp);
            pstmt.setString(6, catatan);
            
            int insertResult = pstmt.executeUpdate();
            pstmt.close();
            
            if (insertResult <= 0) {
                out.print("error: Gagal menyimpan bukti pembayaran");
                conn.rollback();
                return;
            }
        }
        
        // Update transaction status to 'paid' (automatically approve payment)
        String updateTransaksiSql = "UPDATE transaksi SET status_pembayaran = 'paid', " +
                                  "status_pesanan = 'processing', " +
                                  "updated_at = CURRENT_TIMESTAMP WHERE id = ? AND user_id = ?";
        pstmt = conn.prepareStatement(updateTransaksiSql);
        pstmt.setInt(1, transaksiId);
        pstmt.setInt(2, userId);
        
        int updateTransaksiResult = pstmt.executeUpdate();
        pstmt.close();
        
        if (updateTransaksiResult > 0) {
            // Commit all changes
            conn.commit();
            out.print("success");
        } else {
            out.print("error: Gagal mengkonfirmasi pembayaran");
            conn.rollback();
        }
        
    } catch (NumberFormatException e) {
        if (conn != null) conn.rollback();
        out.print("error: ID transaksi tidak valid");
    } catch (java.text.ParseException e) {
        if (conn != null) conn.rollback();
        out.print("error: Format tanggal tidak valid");
    } catch (SQLException e) {
        if (conn != null) conn.rollback();
        out.print("error: Database error - " + e.getMessage());
    } catch (Exception e) {
        if (conn != null) conn.rollback();
        out.print("error: " + e.getMessage());
    } finally {
        if (rs != null) {
            try { rs.close(); } catch (SQLException e) { e.printStackTrace(); }
        }
        if (pstmt != null) {
            try { pstmt.close(); } catch (SQLException e) { e.printStackTrace(); }
        }
        if (conn != null) {
            try { 
                conn.setAutoCommit(true); // Reset auto-commit
                conn.close(); 
            } catch (SQLException e) { e.printStackTrace(); }
        }
    }
%>