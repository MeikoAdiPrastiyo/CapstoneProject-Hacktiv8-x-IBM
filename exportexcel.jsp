<%-- exportexcel.jsp --%>
<%@ page language="java" contentType="application/vnd.ms-excel; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="java.sql.*" %>
<%@ page import="java.text.SimpleDateFormat" %>
<%@ page import="java.util.*" %>
<%@ page import="java.util.Date, java.text.SimpleDateFormat, java.util.Locale" %>

<%
    // Check if user is logged in and is admin
    String username = (String) session.getAttribute("username");
    String userRole = (String) session.getAttribute("role");
    if (username == null || !"admin".equals(userRole)) {
        response.sendRedirect("login.html");
        return;
    }

    // Set response headers for Excel download
    String timestamp = new SimpleDateFormat("yyyyMMdd_HHmmss").format(new Date());
    String filename = "Laporan_Transaksi_" + timestamp + ".xls";
    response.setHeader("Content-Disposition", "attachment; filename=\"" + filename + "\"");
    response.setContentType("application/vnd.ms-excel");

    // Database connection
    String url = "jdbc:mysql://localhost:3306/webcapstone";
    String user = "root";
    String dbpass = "";
    Connection conn = null;
    PreparedStatement pstmt = null;
    ResultSet rs = null;
    
    List<Map<String, Object>> transaksiList = new ArrayList<>();
    
    try {
        Class.forName("com.mysql.cj.jdbc.Driver");
        conn = DriverManager.getConnection(url, user, dbpass);
        
        // Get all transactions with user details
        String transaksiSql = "SELECT t.*, u.nama, u.email, " +
                             "bp.status_verifikasi " +
                             "FROM transaksi t " +
                             "JOIN user u ON t.user_id = u.id " +
                             "LEFT JOIN bukti_pembayaran bp ON t.id = bp.transaksi_id " +
                             "ORDER BY t.created_at DESC";
        pstmt = conn.prepareStatement(transaksiSql);
        rs = pstmt.executeQuery();
        
        while (rs.next()) {
            Map<String, Object> transaksi = new HashMap<>();
            transaksi.put("id", rs.getInt("id"));
            transaksi.put("nama", rs.getString("nama"));
            transaksi.put("email", rs.getString("email"));
            transaksi.put("total_harga", rs.getDouble("total_harga"));
            transaksi.put("metode_pembayaran", rs.getString("metode_pembayaran"));
            transaksi.put("status_pembayaran", rs.getString("status_pembayaran"));
            transaksi.put("status_pesanan", rs.getString("status_pesanan"));
            transaksi.put("alamat_pengiriman", rs.getString("alamat_pengiriman"));
            transaksi.put("created_at", rs.getTimestamp("created_at"));
            transaksi.put("status_verifikasi", rs.getString("status_verifikasi"));
            transaksiList.add(transaksi);
        }
        
    } catch(Exception e) {
        out.println("<!-- Error loading data: " + e.getMessage() + " -->");
    } finally {
        if (rs != null) try { rs.close(); } catch (SQLException e) { e.printStackTrace(); }
        if (pstmt != null) try { pstmt.close(); } catch (SQLException e) { e.printStackTrace(); }
        if (conn != null) try { conn.close(); } catch (SQLException e) { e.printStackTrace(); }
    }
    
    SimpleDateFormat sdf = new SimpleDateFormat("dd/MM/yyyy HH:mm:ss");
%>

<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title>Laporan Transaksi</title>
    <style>
        table {
            border-collapse: collapse;
            width: 100%;
        }
        th, td {
            border: 1px solid #000;
            padding: 8px;
            text-align: left;
        }
        th {
            background-color: #f2f2f2;
            font-weight: bold;
        }
        .header {
            text-align: center;
            margin-bottom: 20px;
        }
        .info {
            margin-bottom: 10px;
        }
    </style>
</head>
<body>
    <div class="header">
        <h2>LAPORAN DATA TRANSAKSI</h2>
        <div class="info">Dicetak pada: <%= sdf.format(new Date()) %></div>
        <div class="info">Dicetak oleh: <%= username %></div>
        <div class="info">Total Transaksi: <%= transaksiList.size() %></div>
    </div>

    <table>
        <thead>
            <tr>
                <th>No</th>
                <th>ID Transaksi</th>
                <th>Nama Customer</th>
                <th>Email</th>
                <th>Total Harga</th>
                <th>Metode Pembayaran</th>
                <th>Status Pembayaran</th>
                <th>Status Pesanan</th>
                <th>Alamat Pengiriman</th>
                <th>Tanggal Transaksi</th>
                <th>Status Verifikasi</th>
            </tr>
        </thead>
        <tbody>
            <% 
            if (transaksiList.isEmpty()) { 
            %>
                <tr>
                    <td colspan="11" style="text-align: center;">Tidak ada data transaksi</td>
                </tr>
            <% 
            } else {
                int no = 1;
                for (Map<String, Object> transaksi : transaksiList) {
            %>
                <tr>
                    <td><%= no++ %></td>
                    <td><%= (Integer)transaksi.get("id") %></td>
                    <td><%= (String)transaksi.get("nama") %></td>
                    <td><%= (String)transaksi.get("email") %></td>
                    <td>Rp <%= String.format("%,.0f", (Double)transaksi.get("total_harga")) %></td>
                    <td><%= ((String)transaksi.get("metode_pembayaran")).replace("_", " ").toUpperCase() %></td>
                    <td><%= ((String)transaksi.get("status_pembayaran")).toUpperCase() %></td>
                    <td><%= ((String)transaksi.get("status_pesanan")).toUpperCase() %></td>
                    <td><%= (String)transaksi.get("alamat_pengiriman") %></td>
                    <td><%= sdf.format((Timestamp)transaksi.get("created_at")) %></td>
                    <td><%= transaksi.get("status_verifikasi") != null ? ((String)transaksi.get("status_verifikasi")).toUpperCase() : "-" %></td>
                </tr>
            <% 
                }
            } 
            %>
        </tbody>
    </table>

    <div style="margin-top: 30px;">
        <p><strong>Keterangan Status:</strong></p>
        <ul>
            <li><strong>Status Pembayaran:</strong> PENDING (Menunggu), PAID (Lunas), FAILED (Gagal)</li>
            <li><strong>Status Pesanan:</strong> PENDING (Menunggu), PROCESSING (Diproses), SHIPPED (Dikirim), DELIVERED (Terkirim), CANCELLED (Dibatalkan)</li>
            <li><strong>Status Verifikasi:</strong> PENDING (Menunggu), APPROVED (Disetujui), REJECTED (Ditolak)</li>
        </ul>
    </div>
</body>
</html>