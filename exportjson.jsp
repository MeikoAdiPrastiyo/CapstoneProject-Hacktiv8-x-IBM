<%@ page language="java" contentType="application/json; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="java.sql.*" %>
<%@ page import="java.text.SimpleDateFormat" %>
<%@ page import="java.util.Date" %>
<%
    // Check if user is logged in
    String username = (String) session.getAttribute("username");
    if (username == null) {
        response.sendRedirect("login.html");
        return;
    }

    // Set response headers for JSON download
    String timestamp = new SimpleDateFormat("yyyy-MM-dd_HH-mm-ss").format(new Date());
    String filename = "Data_Barang_" + timestamp + ".json";
    response.setHeader("Content-Disposition", "attachment; filename=\"" + filename + "\"");
    response.setContentType("application/json");

    // Database connection
    String url = "jdbc:mysql://localhost:3306/webcapstone";
    String user = "root";
    String dbpass = "";
    Connection conn = null;
    PreparedStatement pstmt = null;
    ResultSet rs = null;
    
    // Start JSON output
    out.print("{");
    out.print("\"export_info\": {");
    out.print("\"tanggal_export\": \"" + new SimpleDateFormat("yyyy-MM-dd HH:mm:ss").format(new Date()) + "\",");
    out.print("\"exported_by\": \"" + username + "\",");
    out.print("\"format\": \"JSON\",");
    out.print("\"sistem\": \"Sistem Manajemen Inventory\"");
    out.print("},");
    
    out.print("\"company_info\": {");
    out.print("\"nama\": \"PT. Master Barang Indonesia\",");
    out.print("\"alamat\": \"Jl. Contoh No. 123, Jakarta\",");
    out.print("\"telepon\": \"(021) 123-4567\",");
    out.print("\"email\": \"info@masterbarang.com\"");
    out.print("},");
    
    out.print("\"data_barang\": [");
    
    boolean firstItem = true;
    int totalBarang = 0;
    int totalQuantity = 0;
    double totalNilai = 0;
    
    try {
        Class.forName("com.mysql.cj.jdbc.Driver");
        conn = DriverManager.getConnection(url, user, dbpass);
        String sql = "SELECT * FROM barang ORDER BY id ASC";
        pstmt = conn.prepareStatement(sql);
        rs = pstmt.executeQuery();
        
        while(rs.next()) {
            if (!firstItem) {
                out.print(",");
            }
            firstItem = false;
            
            String barangId = rs.getString("id");
            String namaBarang = rs.getString("nama_barang");
            String gambar = rs.getString("gambar");
            int quantity = rs.getInt("quantity");
            double harga = rs.getDouble("harga");
            double nilaiTotal = quantity * harga;
            
            // Escape special characters for JSON
            namaBarang = namaBarang.replace("\"", "\\\"").replace("\\", "\\\\").replace("\n", "\\n").replace("\r", "\\r");
            if (gambar != null) {
                gambar = gambar.replace("\"", "\\\"").replace("\\", "\\\\");
            }
            
            // Determine stock status
            String stockStatus = quantity <= 10 ? "Low Stock" : quantity <= 50 ? "Medium Stock" : "High Stock";
            
            totalBarang++;
            totalQuantity += quantity;
            totalNilai += nilaiTotal;
            
            out.print("{");
            out.print("\"id\": \"" + barangId + "\",");
            out.print("\"nama_barang\": \"" + namaBarang + "\",");
            out.print("\"gambar\": " + (gambar != null ? "\"" + gambar + "\"" : "null") + ",");
            out.print("\"quantity\": " + quantity + ",");
            out.print("\"harga\": " + harga + ",");
            out.print("\"nilai_total\": " + nilaiTotal + ",");
            out.print("\"stock_status\": \"" + stockStatus + "\",");
            out.print("\"harga_formatted\": \"Rp " + String.format("%,.0f", harga).replace(",", ".") + "\",");
            out.print("\"nilai_total_formatted\": \"Rp " + String.format("%,.0f", nilaiTotal).replace(",", ".") + "\"");
            out.print("}");
        }
    } catch(Exception e) {
        if (!firstItem) {
            out.print(",");
        }
        out.print("{");
        out.print("\"error\": \"" + e.getMessage().replace("\"", "\\\"") + "\"");
        out.print("}");
    } finally {
        if (rs != null) try { rs.close(); } catch (SQLException e) { e.printStackTrace(); }
        if (pstmt != null) try { pstmt.close(); } catch (SQLException e) { e.printStackTrace(); }
        if (conn != null) try { conn.close(); } catch (SQLException e) { e.printStackTrace(); }
    }
    
    out.print("],");
    
    // Add summary information
    out.print("\"summary\": {");
    out.print("\"total_jenis_barang\": " + totalBarang + ",");
    out.print("\"total_quantity\": " + totalQuantity + ",");
    out.print("\"total_nilai_inventory\": " + totalNilai + ",");
    out.print("\"rata_rata_nilai_per_item\": " + (totalBarang > 0 ? (totalNilai / totalBarang) : 0) + ",");
    out.print("\"total_nilai_formatted\": \"Rp " + String.format("%,.0f", totalNilai).replace(",", ".") + "\",");
    out.print("\"rata_rata_formatted\": \"Rp " + (totalBarang > 0 ? String.format("%,.0f", totalNilai / totalBarang).replace(",", ".") : "0") + "\"");
    out.print("},");
    
    // Add statistics
    out.print("\"statistics\": {");
    
    // Count items by stock level
    int lowStock = 0, mediumStock = 0, highStock = 0;
    double minPrice = Double.MAX_VALUE, maxPrice = 0;
    String minPriceItem = "", maxPriceItem = "";
    
    try {
        conn = DriverManager.getConnection(url, user, dbpass);
        pstmt = conn.prepareStatement("SELECT * FROM barang");
        rs = pstmt.executeQuery();
        
        while(rs.next()) {
            int qty = rs.getInt("quantity");
            double price = rs.getDouble("harga");
            String name = rs.getString("nama_barang");
            
            if (qty <= 10) lowStock++;
            else if (qty <= 50) mediumStock++;
            else highStock++;
            
            if (price < minPrice) {
                minPrice = price;
                minPriceItem = name;
            }
            if (price > maxPrice) {
                maxPrice = price;
                maxPriceItem = name;
            }
        }
    } catch(Exception e) {
        // Handle error silently for statistics
    } finally {
        if (rs != null) try { rs.close(); } catch (SQLException e) { e.printStackTrace(); }
        if (pstmt != null) try { pstmt.close(); } catch (SQLException e) { e.printStackTrace(); }
        if (conn != null) try { conn.close(); } catch (SQLException e) { e.printStackTrace(); }
    }
    
    out.print("\"stock_levels\": {");
    out.print("\"low_stock\": " + lowStock + ",");
    out.print("\"medium_stock\": " + mediumStock + ",");
    out.print("\"high_stock\": " + highStock);
    out.print("},");
    
    out.print("\"price_range\": {");
    out.print("\"min_price\": " + (minPrice != Double.MAX_VALUE ? minPrice : 0) + ",");
    out.print("\"max_price\": " + maxPrice + ",");
    out.print("\"min_price_item\": \"" + (minPriceItem.replace("\"", "\\\"")) + "\",");
    out.print("\"max_price_item\": \"" + (maxPriceItem.replace("\"", "\\\"")) + "\",");
    out.print("\"min_price_formatted\": \"Rp " + (minPrice != Double.MAX_VALUE ? String.format("%,.0f", minPrice).replace(",", ".") : "0") + "\",");
    out.print("\"max_price_formatted\": \"Rp " + String.format("%,.0f", maxPrice).replace(",", ".") + "\"");
    out.print("}");
    
    out.print("},");
    
    // Add metadata
    out.print("\"metadata\": {");
    out.print("\"version\": \"1.0\",");
    out.print("\"generated_at\": \"" + new SimpleDateFormat("yyyy-MM-dd'T'HH:mm:ss'Z'").format(new Date()) + "\",");
    out.print("\"total_records\": " + totalBarang + ",");
    out.print("\"data_source\": \"MySQL Database\",");
    out.print("\"schema_version\": \"1.0\"");
    out.print("}");
    
    out.print("}");
%>