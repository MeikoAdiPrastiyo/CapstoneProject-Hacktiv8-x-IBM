<%-- exportpdf.jsp --%>
<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
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
    String timestamp = new SimpleDateFormat("yyyyMMdd_HHmmss").format(new Date());
%>

<!DOCTYPE html>
<html lang="id">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Laporan Transaksi PDF</title>
    <style>
        @page {
            size: A4 landscape;
            margin: 1cm;
        }
        
        * {
            margin: 0;
            padding: 0;
            box-sizing: border-box;
        }
        
        body {
            font-family: Arial, sans-serif;
            font-size: 10px;
            line-height: 1.4;
            color: #333;
        }
        
        .header {
            text-align: center;
            margin-bottom: 20px;
            border-bottom: 2px solid #333;
            padding-bottom: 15px;
        }
        
        .header h1 {
            font-size: 18px;
            font-weight: bold;
            margin-bottom: 10px;
            color: #2f6c3b;
        }
        
        .header .info {
            font-size: 11px;
            margin: 3px 0;
        }
        
        .summary {
            display: flex;
            justify-content: space-between;
            margin-bottom: 20px;
            background-color: #f8f9fa;
            padding: 10px;
            border-radius: 5px;
        }
        
        .summary-item {
            text-align: center;
        }
        
        .summary-item .label {
            font-size: 9px;
            color: #666;
        }
        
        .summary-item .value {
            font-size: 14px;
            font-weight: bold;
            color: #2f6c3b;
        }
        
        table {
            width: 100%;
            border-collapse: collapse;
            margin-bottom: 20px;
            font-size: 9px;
        }
        
        th, td {
            border: 1px solid #ddd;
            padding: 6px 4px;
            text-align: left;
            vertical-align: top;
        }
        
        th {
            background-color: #2f6c3b;
            color: white;
            font-weight: bold;
            text-align: center;
            font-size: 9px;
        }
        
        tr:nth-child(even) {
            background-color: #f9f9f9;
        }
        
        tr:hover {
            background-color: #f5f5f5;
        }
        
        .status-badge {
            padding: 2px 6px;
            border-radius: 3px;
            font-size: 8px;
            font-weight: bold;
            text-transform: uppercase;
        }
        
        .status-pending {
            background-color: #fff3cd;
            color: #856404;
        }
        
        .status-processing {
            background-color: #cce5ff;
            color: #004085;
        }
        
        .status-shipped {
            background-color: #d1ecf1;
            color: #0c5460;
        }
        
        .status-delivered {
            background-color: #d4edda;
            color: #155724;
        }
        
        .status-cancelled {
            background-color: #f8d7da;
            color: #721c24;
        }
        
        .payment-pending {
            background-color: #fff3cd;
            color: #856404;
        }
        
        .payment-paid {
            background-color: #d4edda;
            color: #155724;
        }
        
        .payment-failed {
            background-color: #f8d7da;
            color: #721c24;
        }
        
        .footer {
            margin-top: 30px;
            border-top: 1px solid #ddd;
            padding-top: 15px;
        }
        
        .footer h3 {
            font-size: 12px;
            margin-bottom: 10px;
            color: #2f6c3b;
        }
        
        .footer ul {
            list-style-type: none;
            padding-left: 0;
        }
        
        .footer li {
            margin-bottom: 5px;
            font-size: 9px;
        }
        
        .no-data {
            text-align: center;
            padding: 40px;
            color: #666;
            font-style: italic;
        }
        
        .text-center {
            text-align: center;
        }
        
        .text-right {
            text-align: right;
        }
        
        .currency {
            font-weight: bold;
            color: #2f6c3b;
        }
        
        @media print {
            body {
                -webkit-print-color-adjust: exact;
                print-color-adjust: exact;
            }
        }
    </style>
</head>
<body>
    <div class="header">
        <h1>LAPORAN DATA TRANSAKSI</h1>
        <div class="info">Dicetak pada: <%= sdf.format(new Date()) %></div>
        <div class="info">Dicetak oleh: <%= username %></div>
        <div class="info">Total Transaksi: <%= transaksiList.size() %> transaksi</div>
    </div>

    <%
        // Calculate summary statistics
        int totalTransaksi = transaksiList.size();
        double totalNilai = 0;
        int totalPending = 0;
        int totalPaid = 0;
        int totalDelivered = 0;
        
        for (Map<String, Object> transaksi : transaksiList) {
            totalNilai += (Double)transaksi.get("total_harga");
            String statusPembayaran = (String)transaksi.get("status_pembayaran");
            String statusPesanan = (String)transaksi.get("status_pesanan");
            
            if ("pending".equals(statusPembayaran)) totalPending++;
            if ("paid".equals(statusPembayaran)) totalPaid++;
            if ("delivered".equals(statusPesanan)) totalDelivered++;
        }
    %>

    <div class="summary">
        <div class="summary-item">
            <div class="label">Total Transaksi</div>
            <div class="value"><%= totalTransaksi %></div>
        </div>
        <div class="summary-item">
            <div class="label">Total Nilai</div>
            <div class="value">Rp <%= String.format("%,.0f", totalNilai) %></div>
        </div>
        <div class="summary-item">
            <div class="label">Pembayaran Pending</div>
            <div class="value"><%= totalPending %></div>
        </div>
        <div class="summary-item">
            <div class="label">Pembayaran Lunas</div>
            <div class="value"><%= totalPaid %></div>
        </div>
        <div class="summary-item">
            <div class="label">Pesanan Terkirim</div>
            <div class="value"><%= totalDelivered %></div>
        </div>
    </div>

    <% if (transaksiList.isEmpty()) { %>
        <div class="no-data">
            <h3>Tidak ada data transaksi untuk ditampilkan</h3>
        </div>
    <% } else { %>
        <table>
            <thead>
                <tr>
                    <th style="width: 3%;">No</th>
                    <th style="width: 6%;">ID</th>
                    <th style="width: 12%;">Customer</th>
                    <th style="width: 15%;">Email</th>
                    <th style="width: 10%;">Total</th>
                    <th style="width: 8%;">Metode</th>
                    <th style="width: 8%;">Pembayaran</th>
                    <th style="width: 8%;">Pesanan</th>
                    <th style="width: 20%;">Alamat</th>
                    <th style="width: 10%;">Tanggal</th>
                </tr>
            </thead>
            <tbody>
                <% 
                int no = 1;
                for (Map<String, Object> transaksi : transaksiList) {
                    String statusPembayaran = (String)transaksi.get("status_pembayaran");
                    String statusPesanan = (String)transaksi.get("status_pesanan");
                    String metodePembayaran = (String)transaksi.get("metode_pembayaran");
                %>
                    <tr>
                        <td class="text-center"><%= no++ %></td>
                        <td class="text-center">#<%= (Integer)transaksi.get("id") %></td>
                        <td><%= (String)transaksi.get("nama") %></td>
                        <td style="font-size: 8px;"><%= (String)transaksi.get("email") %></td>
                        <td class="text-right currency">Rp <%= String.format("%,.0f", (Double)transaksi.get("total_harga")) %></td>
                        <td class="text-center"><%= metodePembayaran.replace("_", " ").toUpperCase() %></td>
                        <td class="text-center">
                            <span class="status-badge payment-<%= statusPembayaran %>">
                                <%= statusPembayaran.toUpperCase() %>
                            </span>
                        </td>
                        <td class="text-center">
                            <span class="status-badge status-<%= statusPesanan %>">
                                <%= statusPesanan.toUpperCase() %>
                            </span>
                        </td>
                        <td style="font-size: 8px;"><%= (String)transaksi.get("alamat_pengiriman") %></td>
                        <td class="text-center" style="font-size: 8px;"><%= sdf.format((Timestamp)transaksi.get("created_at")) %></td>
                    </tr>
                <% } %>
            </tbody>
        </table>
    <% } %>

    <div class="footer">
        <h3>Keterangan Status:</h3>
        <ul>
            <li><strong>Status Pembayaran:</strong> PENDING (Menunggu Pembayaran), PAID (Sudah Dibayar), FAILED (Pembayaran Gagal)</li>
            <li><strong>Status Pesanan:</strong> PENDING (Menunggu), PROCESSING (Sedang Diproses), SHIPPED (Sudah Dikirim), DELIVERED (Sudah Diterima), CANCELLED (Dibatalkan)</li>
            <li><strong>Metode Pembayaran:</strong> TRANSFER BANK (Transfer Bank), COD (Bayar di Tempat)</li>
        </ul>
        
        <div style="margin-top: 20px; text-align: right; font-size: 9px;">
            <p>Laporan ini digenerate secara otomatis pada <%= sdf.format(new Date()) %></p>
        </div>
    </div>

    <script>
        // Auto print when page loads
        window.onload = function() {
            // Small delay to ensure content is fully loaded
            setTimeout(function() {
                window.print();
                // Optional: redirect back after printing
                setTimeout(function() {
                    window.location.href = 'transaksi.jsp';
                }, 1000);
            }, 500);
        };
    </script>
</body>
</html>