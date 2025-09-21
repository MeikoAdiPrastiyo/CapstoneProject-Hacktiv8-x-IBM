<%-- pembayaran.jsp (Formulir & Logika Proses dalam Satu File) --%>
<%@ page import="java.sql.*, java.io.*, jakarta.servlet.http.Part, java.util.*, java.text.SimpleDateFormat, java.nio.file.*" %>
<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%
    // ===================================================================================
    // BAGIAN LOGIKA PROSES (Hanya berjalan saat form di-submit dengan metode POST)
    // ===================================================================================
    if ("POST".equalsIgnoreCase(request.getMethod())) {
        
        Connection conn = null;
        String buktiFileName = null;

        try {
            Integer userId = (Integer) session.getAttribute("id");
            if (userId == null) throw new Exception("Sesi tidak valid.");

            // Ambil semua data dari form yang disubmit
            int transaksiId = Integer.parseInt(request.getParameter("transaksiId"));
            String namaPengirim = request.getParameter("namaPengirim");
            Part filePart = request.getPart("buktiTransfer");

            if (namaPengirim == null || namaPengirim.trim().isEmpty() || filePart == null || filePart.getSize() == 0) {
                throw new Exception("Semua data wajib diisi, termasuk file bukti transfer.");
            }

            // Koneksi & Mulai Transaksi
            Class.forName("com.mysql.cj.jdbc.Driver");
            conn = DriverManager.getConnection("jdbc:mysql://localhost:3306/webcapstone", "root", "");
            conn.setAutoCommit(false);

            // Simpan File
            String originalFileName = filePart.getSubmittedFileName();
            String fileExtension = originalFileName.substring(originalFileName.lastIndexOf("."));
            buktiFileName = "bukti_" + transaksiId + "_" + System.currentTimeMillis() + fileExtension;
            
            String uploadPath = application.getRealPath("/uploads/bukti_pembayaran");
            File uploadDir = new File(uploadPath);
            if (!uploadDir.exists()) uploadDir.mkdirs();

            try (InputStream input = filePart.getInputStream()) {
                Files.copy(input, new File(uploadDir, buktiFileName).toPath(), StandardCopyOption.REPLACE_EXISTING);
            }

            // Insert ke Database
            String insertSql = "INSERT INTO bukti_pembayaran (transaksi_id, bukti_transfer, nomor_rekening, nama_pengirim, tanggal_transfer) VALUES (?, ?, ?, ?, ?)";
            PreparedStatement pstmt = conn.prepareStatement(insertSql);
            pstmt.setInt(1, transaksiId);
            pstmt.setString(2, buktiFileName);
            pstmt.setString(3, request.getParameter("nomorRekening"));
            pstmt.setString(4, namaPengirim);
            pstmt.setTimestamp(5, new Timestamp(new SimpleDateFormat("yyyy-MM-dd'T'HH:mm").parse(request.getParameter("tanggalTransfer")).getTime()));
            pstmt.executeUpdate();
            
            // Update status di tabel transaksi
            String updateSql = "UPDATE transaksi SET status_pembayaran = 'paid', status_pesanan = 'menunggu_verifikasi' WHERE id = ? AND user_id = ?";
            pstmt = conn.prepareStatement(updateSql);
            pstmt.setInt(1, transaksiId);
            pstmt.setInt(2, userId);
            pstmt.executeUpdate();

            conn.commit(); // Simpan semua perubahan
            
            // Jika berhasil, arahkan kembali ke riwayat dengan pesan sukses
            response.sendRedirect("riwayatTransaksi.jsp?status=pembayaran_sukses");
            return; // Penting untuk menghentikan eksekusi setelah redirect

        } catch (Exception e) {
            if (conn != null) try { conn.rollback(); } catch (SQLException se) {}
            if (buktiFileName != null) {
                try { new File(application.getRealPath("/uploads/bukti_pembayaran/"), buktiFileName).delete(); } catch (Exception cleanupEx) {}
            }
            // Jika gagal, arahkan kembali ke halaman ini dengan pesan error
            response.sendRedirect("pembayaran.jsp?id=" + request.getParameter("transaksiId") + "&error=" + java.net.URLEncoder.encode(e.getMessage(), "UTF-8"));
            e.printStackTrace();
            return; // Penting

        } finally {
            if (conn != null) try { conn.close(); } catch (SQLException e) {}
        }
    }

    // ===================================================================================
    // BAGIAN TAMPILAN (Hanya berjalan saat halaman diakses pertama kali dengan metode GET)
    // ===================================================================================
    String transaksiId = request.getParameter("id");
    String errorMessage = request.getParameter("error");
%>
<!DOCTYPE html>
<html lang="id">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Formulir Pembayaran - Transaksi #<%= transaksiId %></title>
    <link href="https://cdnjs.cloudflare.com/ajax/libs/bootstrap/5.1.3/css/bootstrap.min.css" rel="stylesheet">
</head>
<body class="bg-light">
    <div class="container py-5">
        <div class="row justify-content-center">
            <div class="col-lg-7">
                <div class="card shadow-sm">
                    <div class="card-header bg-primary text-white">
                        <h3 class="mb-0">Konfirmasi Pembayaran</h3>
                    </div>
                    <div class="card-body p-4">
                        <p class="card-text">Untuk Transaksi ID: <strong class="text-primary">#<%= transaksiId %></strong></p>
                        <hr>
                        <% if (errorMessage != null) { %>
                            <div class="alert alert-danger"><%= errorMessage %></div>
                        <% } %>
                        <form method="POST" action="pembayaran.jsp" enctype="multipart/form-data">
                            <input type="hidden" name="transaksiId" value="<%= transaksiId %>">
                            <div class="mb-3">
                                <label class="form-label fw-bold">Nama Pengirim</label>
                                <input type="text" class="form-control" name="namaPengirim" required>
                            </div>
                            <div class="mb-3">
                                <label class="form-label fw-bold">Nomor Rekening</label>
                                <input type="text" class="form-control" name="nomorRekening" required>
                            </div>
                            <div class="mb-3">
                                <label class="form-label fw-bold">Tanggal Transfer</label>
                                <input type="datetime-local" class="form-control" name="tanggalTransfer" required>
                            </div>
                            <div class="mb-3">
                                <label class="form-label fw-bold">Bukti Transfer (JPG, PNG)</label>
                                <input type="file" class="form-control" name="buktiTransfer" accept="image/*" required>
                            </div>
                            <div class="d-grid">
                                <button type="submit" class="btn btn-primary btn-lg">Kirim Konfirmasi</button>
                            </div>
                        </form>
                    </div>
                </div>
            </div>
        </div>
    </div>
</body>
</html>