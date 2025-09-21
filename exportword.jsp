<%@ page language="java" contentType="application/msword; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="java.sql.*" %>
<%@ page import="java.text.SimpleDateFormat" %>
<%@ page import="java.util.Date" %>
<%@ page import="java.io.File" %>
<%@ page import="java.nio.file.Files" %>
<%@ page import="java.nio.file.Path" %>
<%@ page import="java.nio.file.Paths" %>
<%@ page import="java.util.Base64" %>
<%@ page import="java.text.NumberFormat" %>
<%@ page import="java.util.Locale" %>
<%
    // Check if user is logged in
    String username = (String) session.getAttribute("username");
    if (username == null) {
        response.sendRedirect("login.html");
        return;
    }

    // Set response headers for Word document download
    String timestamp = new SimpleDateFormat("yyyy-MM-dd_HH-mm-ss").format(new Date());
    String filename = "Data_Barang_" + timestamp + ".doc";
    response.setHeader("Content-Disposition", "attachment; filename=\"" + filename + "\"");
    response.setContentType("application/msword");

    // Database connection
    String url = "jdbc:mysql://localhost:3306/webcapstone";
    String user = "root";
    String dbpass = "";
    Connection conn = null;
    PreparedStatement pstmt = null;
    ResultSet rs = null;
%>
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <style>
        body { font-family: Arial, sans-serif; margin: 20px; }
        .header { text-align: center; margin-bottom: 30px; border-bottom: 2px solid #2f6c3b; padding-bottom: 15px; }
        .company-info { margin-bottom: 30px; }
        .export-info { margin-bottom: 20px; font-size: 12px; color: #666; }
        table { width: 100%; border-collapse: collapse; margin-top: 20px; }
        th { background-color: #2f6c3b; color: white; padding: 12px 8px; text-align: left; border: 1px solid #000; font-weight: bold; }
        td { padding: 10px 8px; border: 1px solid #666; vertical-align: middle; }
        tr:nth-child(even) { background-color: #f9f9f9; }
        .price { text-align: right; font-weight: bold; }
        .quantity { text-align: center; }
        .footer { margin-top: 30px; text-align: center; font-size: 12px; color: #666; border-top: 1px solid #ccc; padding-top: 15px; }
        .total-row { background-color: #e8f5e8 !important; font-weight: bold; }
        .summary { margin-top: 20px; padding: 15px; background-color: #f0f8f0; border: 1px solid #2f6c3b; }
    </style>
</head>
<body>
    <div class="header">
        <h1>LAPORAN DATA BARANG</h1>
        <h3>Sistem Manajemen Inventory</h3>
    </div>

    <div class="company-info">
        <strong>PT. Master Barang Indonesia</strong><br>
        Jl. Contoh No. 123, Jakarta<br>
        Telp: (021) 123-4567 | Email: info@masterbarang.com
    </div>

    <div class="export-info">
        <strong>Tanggal Export:</strong> <%= new SimpleDateFormat("dd MMMM yyyy HH:mm:ss", new Locale("id", "ID")).format(new Date()) %><br>
        <strong>Diekspor oleh:</strong> <%= username %><br>
    </div>

    <table>
        <thead>
            <tr>
                <th style="width: 5%;">No</th>
                <th style="width: 15%;">Gambar</th>
                <th style="width: 30%;">Nama Barang</th>
                <th style="width: 15%;">Quantity</th>
                <th style="width: 15%;">Harga Satuan</th>
                <th style="width: 20%;">Total Nilai</th>
            </tr>
        </thead>
        <tbody>
            <%
                int totalBarang = 0;
                int totalQuantity = 0;
                double totalNilai = 0;
                int counter = 1;
                NumberFormat formatRupiah = NumberFormat.getInstance(new Locale("id", "ID"));
                
                try {
                    Class.forName("com.mysql.cj.jdbc.Driver");
                    conn = DriverManager.getConnection(url, user, dbpass);
                    String sql = "SELECT * FROM barang ORDER BY nama_barang ASC";
                    pstmt = conn.prepareStatement(sql);
                    rs = pstmt.executeQuery();
                    
                    while(rs.next()) {
                        String namaBarang = rs.getString("nama_barang");
                        String gambarFilename = rs.getString("gambar");
                        int quantity = rs.getInt("quantity");
                        double harga = rs.getDouble("harga");
                        double nilaiTotal = quantity * harga;
                        
                        String base64Image = null;
                        if (gambarFilename != null && !gambarFilename.trim().isEmpty()) {
                            String uploadPath = getServletContext().getRealPath("/") + "uploads" + File.separator + gambarFilename;
                            File imageFile = new File(uploadPath);

                            if (imageFile.exists() && !imageFile.isDirectory()) {
                                try {
                                    byte[] imageBytes = Files.readAllBytes(imageFile.toPath());
                                    base64Image = Base64.getEncoder().encodeToString(imageBytes);
                                } catch (Exception e) {
                                    // Abaikan jika file tidak bisa dibaca, akan ditampilkan (No Image)
                                }
                            }
                        }
                        
                        totalBarang++;
                        totalQuantity += quantity;
                        totalNilai += nilaiTotal;
            %>
            <tr>
                <td style="text-align: center;"><%= counter++ %></td>
                <td style="text-align: center;">
                    <% if (base64Image != null) { %>
                        <img src="data:image/jpeg;base64,<%= base64Image %>" width="80" alt="Gambar Produk">
                    <% } else { %>
                        (No Image)
                    <% } %>
                </td>
                <td><%= namaBarang %></td>
                <td class="quantity"><%= quantity %></td>
                <td class="price">Rp <%= formatRupiah.format(harga) %></td>
                <td class="price">Rp <%= formatRupiah.format(nilaiTotal) %></td>
            </tr>
            <%
                    }
                } catch(Exception e) {
                    out.println("<tr><td colspan='6'>Error: " + e.getMessage() + "</td></tr>");
                } finally {
                    if (rs != null) try { rs.close(); } catch (SQLException e) { e.printStackTrace(); }
                    if (pstmt != null) try { pstmt.close(); } catch (SQLException e) { e.printStackTrace(); }
                    if (conn != null) try { conn.close(); } catch (SQLException e) { e.printStackTrace(); }
                }
            %>
            <tr class="total-row">
                <td colspan="3" style="text-align: center;"><strong>TOTAL</strong></td>
                <td class="quantity"><strong><%= totalQuantity %></strong></td>
                <td style="text-align: center;"><strong>-</strong></td>
                <td class="price"><strong>Rp <%= formatRupiah.format(totalNilai) %></strong></td>
            </tr>
        </tbody>
    </table>

    <div class="summary">
        <h4>RINGKASAN INVENTORY</h4>
        <table style="width: 100%; border: none;">
             <tr><td style="border: none; width: 50%;"><strong>Total Jenis Barang:</strong></td><td style="border: none;"><%= totalBarang %> item</td></tr>
             <tr><td style="border: none;"><strong>Total Quantity:</strong></td><td style="border: none;"><%= totalQuantity %> unit</td></tr>
             <tr><td style="border: none;"><strong>Total Nilai Inventory:</strong></td><td style="border: none; font-weight: bold; color: #2f6c3b;">Rp <%= formatRupiah.format(totalNilai) %></td></tr>
             <tr><td style="border: none;"><strong>Rata-rata Nilai per Item:</strong></td><td style="border: none;">Rp <%= totalBarang > 0 ? formatRupiah.format(totalNilai / totalBarang) : "0" %></td></tr>
        </table>
    </div>

    <div class="footer">
        <p>Dokumen ini digenerate otomatis oleh Sistem Manajemen Inventory</p>
        <p>© 2025 PT. Master Barang Indonesia. All rights reserved.</p>
    </div>
</body>
</html>