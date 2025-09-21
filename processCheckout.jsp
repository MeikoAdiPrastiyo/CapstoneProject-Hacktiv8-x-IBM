<%-- processCheckout.jsp --%>
<%@ page language="java" contentType="application/json; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="java.sql.*" %>
<%@ page import="java.util.*" %>
<%
    // Set response type to JSON
    response.setContentType("application/json");
    
    // Check if user is logged in
    String username = (String) session.getAttribute("username");
    String email = (String) session.getAttribute("email");
    
    if (username == null || email == null) {
        out.print("{\"success\": false, \"message\": \"Sesi telah berakhir. Silakan login kembali.\"}");
        return;
    }
    
    // Get form parameters
    String namaLengkap = request.getParameter("namaLengkap");
    String nomorTelepon = request.getParameter("nomorTelepon");
    String alamatPengiriman = request.getParameter("alamatPengiriman");
    String metodePembayaran = request.getParameter("metodePembayaran");
    
    // Validate required parameters
    if (namaLengkap == null || namaLengkap.trim().isEmpty() ||
        nomorTelepon == null || nomorTelepon.trim().isEmpty() ||
        alamatPengiriman == null || alamatPengiriman.trim().isEmpty() ||
        metodePembayaran == null || metodePembayaran.trim().isEmpty()) {
        out.print("{\"success\": false, \"message\": \"Semua field wajib diisi.\"}");
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
        Class.forName("com.mysql.cj.jdbc.Driver");
        conn = DriverManager.getConnection(url, user, dbpass);
        conn.setAutoCommit(false); // Start transaction
        
        // Get user ID
        int userId = 0;
        String getUserSql = "SELECT id FROM user WHERE email = ?";
        pstmt = conn.prepareStatement(getUserSql);
        pstmt.setString(1, email);
        rs = pstmt.executeQuery();
        
        if (rs.next()) {
            userId = rs.getInt("id");
        } else {
            conn.rollback();
            out.print("{\"success\": false, \"message\": \"User tidak ditemukan.\"}");
            return;
        }
        rs.close();
        pstmt.close();
        
        // Get cart items and calculate total
        String getCartSql = "SELECT k.id as keranjang_id, k.barang_id, k.quantity, " +
                           "b.nama_barang, b.harga, b.quantity as stok " +
                           "FROM keranjang k " +
                           "JOIN barang b ON k.barang_id = b.id " +
                           "WHERE k.user_id = ?";
        
        pstmt = conn.prepareStatement(getCartSql);
        pstmt.setInt(1, userId);
        rs = pstmt.executeQuery();
        
        List<Map<String, Object>> cartItems = new ArrayList<>();
        double totalHarga = 0;
        
        while (rs.next()) {
            Map<String, Object> item = new HashMap<>();
            item.put("keranjang_id", rs.getInt("keranjang_id"));
            item.put("barang_id", rs.getInt("barang_id"));
            item.put("nama_barang", rs.getString("nama_barang"));
            item.put("harga", rs.getDouble("harga"));
            item.put("quantity", rs.getInt("quantity"));
            item.put("stok", rs.getInt("stok"));
            
            int quantity = rs.getInt("quantity");
            int stok = rs.getInt("stok");
            double harga = rs.getDouble("harga");
            
            // Check stock availability
            if (quantity > stok) {
                conn.rollback();
                out.print("{\"success\": false, \"message\": \"Stok " + rs.getString("nama_barang") + " tidak mencukupi.\"}");
                return;
            }
            
            double subtotal = harga * quantity;
            item.put("subtotal", subtotal);
            totalHarga += subtotal;
            
            cartItems.add(item);
        }
        rs.close();
        pstmt.close();
        
        // Check if cart is empty
        if (cartItems.isEmpty()) {
            conn.rollback();
            out.print("{\"success\": false, \"message\": \"Keranjang belanja kosong.\"}");
            return;
        }
        
        // Create full shipping address
        String fullAlamat = "Nama: " + namaLengkap + "\n" +
                           "Telepon: " + nomorTelepon + "\n" +
                           "Alamat: " + alamatPengiriman;
        
        // Insert into transaksi table
        String insertTransaksiSql = "INSERT INTO transaksi (user_id, total_harga, metode_pembayaran, " +
                                  "status_pembayaran, status_pesanan, alamat_pengiriman) " +
                                  "VALUES (?, ?, ?, 'pending', 'pending', ?)";
        
        pstmt = conn.prepareStatement(insertTransaksiSql, Statement.RETURN_GENERATED_KEYS);
        pstmt.setInt(1, userId);
        pstmt.setDouble(2, totalHarga);
        pstmt.setString(3, metodePembayaran);
        pstmt.setString(4, fullAlamat);
        
        int affectedRows = pstmt.executeUpdate();
        if (affectedRows == 0) {
            conn.rollback();
            out.print("{\"success\": false, \"message\": \"Gagal membuat transaksi.\"}");
            return;
        }
        
        // Get the generated transaction ID
        rs = pstmt.getGeneratedKeys();
        int transaksiId = 0;
        if (rs.next()) {
            transaksiId = rs.getInt(1);
        }
        rs.close();
        pstmt.close();
        
        // Insert into detail_transaksi table and update stock
        String insertDetailSql = "INSERT INTO detail_transaksi (transaksi_id, barang_id, nama_barang, " +
                               "harga, quantity, subtotal) VALUES (?, ?, ?, ?, ?, ?)";
        String updateStokSql = "UPDATE barang SET quantity = quantity - ? WHERE id = ?";
        
        PreparedStatement pstmtDetail = conn.prepareStatement(insertDetailSql);
        PreparedStatement pstmtUpdateStok = conn.prepareStatement(updateStokSql);
        
        for (Map<String, Object> item : cartItems) {
            // Insert detail transaksi
            pstmtDetail.setInt(1, transaksiId);
            pstmtDetail.setInt(2, (Integer) item.get("barang_id"));
            pstmtDetail.setString(3, (String) item.get("nama_barang"));
            pstmtDetail.setDouble(4, (Double) item.get("harga"));
            pstmtDetail.setInt(5, (Integer) item.get("quantity"));
            pstmtDetail.setDouble(6, (Double) item.get("subtotal"));
            pstmtDetail.executeUpdate();
            
            // Update stock
            pstmtUpdateStok.setInt(1, (Integer) item.get("quantity"));
            pstmtUpdateStok.setInt(2, (Integer) item.get("barang_id"));
            pstmtUpdateStok.executeUpdate();
        }
        
        pstmtDetail.close();
        pstmtUpdateStok.close();
        
        // Clear cart
        String clearCartSql = "DELETE FROM keranjang WHERE user_id = ?";
        pstmt = conn.prepareStatement(clearCartSql);
        pstmt.setInt(1, userId);
        pstmt.executeUpdate();
        pstmt.close();
        
        // Commit transaction
        conn.commit();
        
        // Return success response
        out.print("{\"success\": true, \"message\": \"Checkout berhasil! Pesanan Anda dengan ID #" + 
                 transaksiId + " telah diproses.\", \"transaksi_id\": " + transaksiId + "}");
        
    } catch (ClassNotFoundException e) {
        if (conn != null) {
            try { conn.rollback(); } catch (SQLException ex) { ex.printStackTrace(); }
        }
        out.print("{\"success\": false, \"message\": \"Driver database tidak ditemukan: " + e.getMessage() + "\"}");
    } catch (SQLException e) {
        if (conn != null) {
            try { conn.rollback(); } catch (SQLException ex) { ex.printStackTrace(); }
        }
        out.print("{\"success\": false, \"message\": \"Error database: " + e.getMessage() + "\"}");
    } catch (Exception e) {
        if (conn != null) {
            try { conn.rollback(); } catch (SQLException ex) { ex.printStackTrace(); }
        }
        out.print("{\"success\": false, \"message\": \"Terjadi kesalahan: " + e.getMessage() + "\"}");
    } finally {
        // Close connections
        if (rs != null) {
            try { rs.close(); } catch (SQLException e) { e.printStackTrace(); }
        }
        if (pstmt != null) {
            try { pstmt.close(); } catch (SQLException e) { e.printStackTrace(); }
        }
        if (conn != null) {
            try { 
                conn.setAutoCommit(true); // Reset auto commit
                conn.close(); 
            } catch (SQLException e) { 
                e.printStackTrace(); 
            }
        }
    }
%>