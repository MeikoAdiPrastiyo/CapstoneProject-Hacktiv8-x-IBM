<%-- checkout.jsp --%>
<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="java.sql.*" %>
<%
    // Check if user is logged in
    String username = (String) session.getAttribute("username");
    String userRole = (String) session.getAttribute("role");
    String email = (String) session.getAttribute("email");
    if (username == null) {
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
    
    // Get user ID
    int userId = 0;
    double totalHarga = 0;
    int totalItems = 0;
    boolean hasCartItems = false;
%>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>E-Shop - Checkout</title>
    <link href="https://cdnjs.cloudflare.com/ajax/libs/bootstrap/5.0.2/css/bootstrap.min.css" rel="stylesheet">
    <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.5.0/css/all.min.css"/>
    <style>
        :root {
            --primary-color: #2f6c3b;
            --hover-color: #255b30;
        }

        body {
            font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
            background-color: #f8f9fa;
        }

        .main-content {
            padding: 20px;
        }

        .page-header {
            background: linear-gradient(135deg, var(--primary-color), var(--hover-color));
            color: white;
            border-radius: 10px;
            padding: 20px;
            margin-bottom: 20px;
        }

        .checkout-section {
            background: white;
            border-radius: 10px;
            padding: 20px;
            box-shadow: 0 2px 10px rgba(0, 0, 0, 0.1);
            margin-bottom: 20px;
        }

        .order-summary {
            background: #f8f9fa;
            border-radius: 8px;
            padding: 15px;
            margin-bottom: 20px;
        }

        .order-item {
            display: flex;
            align-items: center;
            padding: 10px 0;
            border-bottom: 1px solid #e9ecef;
        }

        .order-item:last-child {
            border-bottom: none;
        }

        .item-image {
            width: 60px;
            height: 60px;
            object-fit: cover;
            border-radius: 6px;
            margin-right: 15px;
        }

        .item-details {
            flex: 1;
        }

        .item-name {
            font-weight: 600;
            color: #333;
            margin-bottom: 5px;
        }

        .item-price {
            color: #6c757d;
            font-size: 0.9rem;
        }

        .item-quantity {
            color: #6c757d;
            font-size: 0.9rem;
        }

        .item-total {
            font-weight: 600;
            color: var(--primary-color);
            text-align: right;
            min-width: 100px;
        }

        .total-summary {
            background: white;
            border: 2px solid var(--primary-color);
            border-radius: 8px;
            padding: 20px;
            margin-top: 20px;
        }

        .total-row {
            display: flex;
            justify-content: space-between;
            margin-bottom: 10px;
            padding: 5px 0;
        }

        .total-row.final {
            border-top: 2px solid var(--primary-color);
            margin-top: 15px;
            padding-top: 15px;
            font-size: 1.25rem;
            font-weight: 700;
            color: var(--primary-color);
        }

        .form-section {
            margin-bottom: 30px;
        }

        .form-section h5 {
            color: var(--primary-color);
            border-bottom: 2px solid var(--primary-color);
            padding-bottom: 10px;
            margin-bottom: 20px;
        }

        .form-control:focus {
            border-color: var(--primary-color);
            box-shadow: 0 0 0 0.2rem rgba(47, 108, 59, 0.25);
        }

        .payment-method {
            border: 2px solid #e9ecef;
            border-radius: 8px;
            padding: 15px;
            margin-bottom: 10px;
            cursor: pointer;
            transition: all 0.3s ease;
        }

        .payment-method:hover {
            border-color: var(--primary-color);
            background-color: rgba(47, 108, 59, 0.05);
        }

        .payment-method.active {
            border-color: var(--primary-color);
            background-color: rgba(47, 108, 59, 0.1);
        }

        .payment-method input[type="radio"] {
            margin-right: 10px;
        }

        .payment-icon {
            font-size: 1.5rem;
            margin-right: 10px;
            color: var(--primary-color);
        }

        .btn-custom {
            background-color: var(--primary-color);
            border-color: var(--primary-color);
            color: white;
            padding: 12px 30px;
            font-size: 1.1rem;
            font-weight: 600;
        }

        .btn-custom:hover {
            background-color: var(--hover-color);
            border-color: var(--hover-color);
            color: white;
        }

        .btn-secondary-custom {
            background-color: #6c757d;
            border-color: #6c757d;
            color: white;
        }

        .btn-secondary-custom:hover {
            background-color: #5a6268;
            border-color: #545b62;
            color: white;
        }

        .message {
            position: fixed;
            top: 20px;
            right: 20px;
            z-index: 1050;
            min-width: 300px;
            display: none;
        }

        .empty-checkout {
            text-align: center;
            padding: 60px 20px;
            color: #6c757d;
        }

        .empty-checkout i {
            font-size: 4rem;
            color: #dee2e6;
            margin-bottom: 20px;
        }

        .loading-overlay {
            display: none;
            position: fixed;
            top: 0;
            left: 0;
            width: 100%;
            height: 100%;
            background-color: rgba(0, 0, 0, 0.5);
            z-index: 9999;
            justify-content: center;
            align-items: center;
        }

        .loading-spinner {
            background: white;
            padding: 30px;
            border-radius: 10px;
            text-align: center;
        }

        .spinner-border {
            color: var(--primary-color);
        }

        @media (max-width: 768px) {
            .order-item {
                flex-direction: column;
                text-align: center;
            }

            .item-image {
                margin: 0 0 10px 0;
            }

            .item-total {
                text-align: center;
                margin-top: 10px;
            }
        }
    </style>
</head>
<body>
    <!-- Loading Overlay -->
    <div id="loadingOverlay" class="loading-overlay">
        <div class="loading-spinner">
            <div class="spinner-border" role="status">
                <span class="visually-hidden">Loading...</span>
            </div>
            <p class="mt-3">Memproses checkout...</p>
        </div>
    </div>

    <div class="container-fluid">
        <div class="main-content">
            <!-- Page Header -->
            <div class="page-header">
                <h2><i class="fas fa-credit-card"></i> Checkout</h2>
                <p class="mb-0">Selesaikan pembelian Anda, <%= username %>!</p>
            </div>

            <!-- Success/Error Message -->
            <div id="message" class="alert message"></div>

            <%
              try {
                  Class.forName("com.mysql.cj.jdbc.Driver");
                  conn = DriverManager.getConnection(url, user, dbpass);
                  
                  // Get user ID
                  String getUserSql = "SELECT id FROM user WHERE email = ?";
                  pstmt = conn.prepareStatement(getUserSql);
                  pstmt.setString(1, email);
                  rs = pstmt.executeQuery();
                  
                  if (rs.next()) {
                      userId = rs.getInt("id");
                  }
                  rs.close();
                  pstmt.close();
                  
                  // Get cart items
                  String sql = "SELECT k.id as keranjang_id, k.barang_id, k.quantity, " +
                              "b.nama_barang, b.gambar, b.harga, b.quantity as stok " +
                              "FROM keranjang k " +
                              "JOIN barang b ON k.barang_id = b.id " +
                              "WHERE k.user_id = ? " +
                              "ORDER BY k.created_at DESC";
                  
                  pstmt = conn.prepareStatement(sql);
                  pstmt.setInt(1, userId);
                  rs = pstmt.executeQuery();
                  
                  StringBuilder orderItemsHtml = new StringBuilder();
                  
                  while(rs.next()) {
                      hasCartItems = true;
                      int barangId = rs.getInt("barang_id");
                      String namaBarang = rs.getString("nama_barang");
                      String gambar = rs.getString("gambar");
                      double harga = rs.getDouble("harga");
                      int quantity = rs.getInt("quantity");
                      double subtotal = harga * quantity;
                      
                      totalHarga += subtotal;
                      totalItems += quantity;
                      
                      orderItemsHtml.append("<div class='order-item'>");
                      
                      // Product Image
                      if (gambar != null && !gambar.trim().isEmpty()) {
                          orderItemsHtml.append("<img src='uploads/").append(gambar).append("' alt='").append(namaBarang).append("' class='item-image' onerror=\"this.src='https://via.placeholder.com/60x60?text=No+Image'\">");
                      } else {
                          orderItemsHtml.append("<img src='https://via.placeholder.com/60x60?text=No+Image' alt='No Image' class='item-image'>");
                      }
                      
                      // Product Details
                      orderItemsHtml.append("<div class='item-details'>");
                      orderItemsHtml.append("<div class='item-name'>").append(namaBarang).append("</div>");
                      orderItemsHtml.append("<div class='item-price'>Rp ").append(String.format("%,.0f", harga)).append(" per item</div>");
                      orderItemsHtml.append("<div class='item-quantity'>Jumlah: ").append(quantity).append("</div>");
                      orderItemsHtml.append("</div>");
                      
                      // Total
                      orderItemsHtml.append("<div class='item-total'>Rp ").append(String.format("%,.0f", subtotal)).append("</div>");
                      
                      orderItemsHtml.append("</div>");
                  }
                  
                  if (hasCartItems) {
            %>
            
            <div class="row">
                <!-- Checkout Form -->
                <div class="col-lg-8">
                    <div class="checkout-section">
                        <form id="checkoutForm">
                            <!-- Shipping Address Section -->
                            <div class="form-section">
                                <h5><i class="fas fa-map-marker-alt"></i> Alamat Pengiriman</h5>
                                <div class="row">
                                    <div class="col-md-6 mb-3">
                                        <label for="namaLengkap" class="form-label">Nama Lengkap *</label>
                                        <input type="text" class="form-control" id="namaLengkap" name="namaLengkap" required>
                                    </div>
                                    <div class="col-md-6 mb-3">
                                        <label for="nomorTelepon" class="form-label">Nomor Telepon *</label>
                                        <input type="tel" class="form-control" id="nomorTelepon" name="nomorTelepon" required>
                                    </div>
                                </div>
                                <div class="mb-3">
                                    <label for="alamatLengkap" class="form-label">Alamat Lengkap *</label>
                                    <textarea class="form-control" id="alamatLengkap" name="alamatLengkap" rows="3" placeholder="Jalan, No. Rumah, RT/RW" required></textarea>
                                </div>
                                <div class="row">
                                    <div class="col-md-4 mb-3">
                                        <label for="kota" class="form-label">Kota *</label>
                                        <input type="text" class="form-control" id="kota" name="kota" required>
                                    </div>
                                    <div class="col-md-4 mb-3">
                                        <label for="provinsi" class="form-label">Provinsi *</label>
                                        <input type="text" class="form-control" id="provinsi" name="provinsi" required>
                                    </div>
                                    <div class="col-md-4 mb-3">
                                        <label for="kodePos" class="form-label">Kode Pos *</label>
                                        <input type="text" class="form-control" id="kodePos" name="kodePos" pattern="[0-9]{5}" required>
                                    </div>
                                </div>
                            </div>
                            
                            <!-- Payment Method Section -->
                            <div class="form-section">
                                <h5><i class="fas fa-credit-card"></i> Metode Pembayaran</h5>
                                
                                <div class="payment-method" onclick="selectPayment('transfer_bank')">
                                    <label class="d-flex align-items-center w-100">
                                        <input type="radio" name="metodePembayaran" value="transfer_bank" required>
                                        <i class="fas fa-university payment-icon"></i>
                                        <div>
                                            <strong>Transfer Bank</strong>
                                            <p class="mb-0 text-muted">Transfer ke rekening bank yang tersedia</p>
                                        </div>
                                    </label>
                                </div>
                                
                                <div class="payment-method" onclick="selectPayment('e_wallet')">
                                    <label class="d-flex align-items-center w-100">
                                        <input type="radio" name="metodePembayaran" value="e_wallet" required>
                                        <i class="fas fa-mobile-alt payment-icon"></i>
                                        <div>
                                            <strong>E-Wallet</strong>
                                            <p class="mb-0 text-muted">Bayar menggunakan GoPay, OVO, DANA, dll</p>
                                        </div>
                                    </label>
                                </div>
                                
                                <div class="payment-method" onclick="selectPayment('cod')">
                                    <label class="d-flex align-items-center w-100">
                                        <input type="radio" name="metodePembayaran" value="cod" required>
                                        <i class="fas fa-hand-holding-usd payment-icon"></i>
                                        <div>
                                            <strong>Bayar di Tempat (COD)</strong>
                                            <p class="mb-0 text-muted">Bayar saat barang sampai di tujuan</p>
                                        </div>
                                    </label>
                                </div>
                            </div>
                        </form>
                    </div>
                </div>
                
                <!-- Order Summary -->
                <div class="col-lg-4">
                    <div class="checkout-section">
                        <h5><i class="fas fa-list"></i> Ringkasan Pesanan</h5>
                        
                        <div class="order-summary">
                            <%= orderItemsHtml.toString() %>
                        </div>
                        
                        <div class="total-summary">
                            <div class="total-row">
                                <span>Subtotal (<%= totalItems %> item):</span>
                                <span>Rp <%= String.format("%,.0f", totalHarga) %></span>
                            </div>
                            <div class="total-row">
                                <span>Biaya Pengiriman:</span>
                                <span>Gratis</span>
                            </div>
                            <div class="total-row final">
                                <span>Total Pembayaran:</span>
                                <span>Rp <%= String.format("%,.0f", totalHarga) %></span>
                            </div>
                        </div>
                        
                        <div class="d-grid gap-2 mt-3">
                            <button type="button" class="btn btn-custom" onclick="processCheckout()">
                                <i class="fas fa-check-circle"></i> Selesaikan Checkout
                            </button>
                            <a href="keranjang.jsp" class="btn btn-secondary-custom">
                                <i class="fas fa-arrow-left"></i> Kembali ke Keranjang
                            </a>
                        </div>
                    </div>
                </div>
            </div>
            
            <%
                  } else {
            %>
            
            <!-- Empty Checkout -->
            <div class="checkout-section">
                <div class="empty-checkout">
                    <i class="fas fa-shopping-cart"></i>
                    <h4>Tidak Ada Item untuk Checkout</h4>
                    <p class="text-muted">Keranjang belanja Anda kosong. Silakan tambahkan produk terlebih dahulu.</p>
                    <a href="daftarBarang.jsp" class="btn btn-custom">
                        <i class="fas fa-shopping-bag"></i> Mulai Belanja
                    </a>
                </div>
            </div>
            
            <%
                  }
              } catch(Exception e) {
                  out.println("<div class='checkout-section'><div class='alert alert-danger'><i class='fas fa-exclamation-triangle'></i> Error: " + e.getMessage() + "</div></div>");
              } finally {
                  if (rs != null) try { rs.close(); } catch (SQLException e) { e.printStackTrace(); }
                  if (pstmt != null) try { pstmt.close(); } catch (SQLException e) { e.printStackTrace(); }
                  if (conn != null) try { conn.close(); } catch (SQLException e) { e.printStackTrace(); }
              }
            %>
        </div>
    </div>

    <script src="https://cdnjs.cloudflare.com/ajax/libs/bootstrap/5.0.2/js/bootstrap.bundle.min.js"></script>
    <script>
        // Select payment method
        function selectPayment(method) {
            // Remove active class from all payment methods
            document.querySelectorAll('.payment-method').forEach(function(element) {
                element.classList.remove('active');
            });
            
            // Add active class to selected method
            document.querySelector('input[value="' + method + '"]').closest('.payment-method').classList.add('active');
            
            // Check the radio button
            document.querySelector('input[value="' + method + '"]').checked = true;
        }

        // Process checkout
        function processCheckout() {
            const form = document.getElementById('checkoutForm');
            
            // Validate form
            if (!form.checkValidity()) {
                form.reportValidity();
                return;
            }
            
            // Get form data
            const formData = new FormData(form);
            
            // Build complete address
            const alamatLengkap = formData.get('alamatLengkap') + ', ' + 
                                 formData.get('kota') + ', ' + 
                                 formData.get('provinsi') + ' ' + 
                                 formData.get('kodePos');
            
            // Show loading
            document.getElementById('loadingOverlay').style.display = 'flex';
            
            // Prepare checkout data
            const checkoutData = {
                namaLengkap: formData.get('namaLengkap'),
                nomorTelepon: formData.get('nomorTelepon'),
                alamatPengiriman: alamatLengkap,
                metodePembayaran: formData.get('metodePembayaran')
            };
            
            // Send checkout request
            const xhr = new XMLHttpRequest();
            xhr.open('POST', 'processCheckout.jsp', true);
            xhr.setRequestHeader('Content-Type', 'application/x-www-form-urlencoded');
            
            xhr.onload = function() {
                document.getElementById('loadingOverlay').style.display = 'none';
                
                if (xhr.status === 200) {
                    try {
                        const response = JSON.parse(xhr.responseText);
                        
                        if (response.success) {
                            showMessage('Checkout berhasil! Pesanan Anda telah diproses.', true);
                            
                            // Redirect to transaction history after 2 seconds
                            setTimeout(function() {
                                window.location.href = 'riwayatTransaksi.jsp';
                            }, 2000);
                        } else {
                            showMessage(response.message || 'Checkout gagal. Silakan coba lagi.', false);
                        }
                    } catch (e) {
                        showMessage('Terjadi kesalahan saat memproses checkout.', false);
                    }
                } else {
                    showMessage('Gagal menghubungi server. Silakan coba lagi.', false);
                }
            };
            
            xhr.onerror = function() {
                document.getElementById('loadingOverlay').style.display = 'none';
                showMessage('Terjadi kesalahan jaringan. Silakan coba lagi.', false);
            };
            
            // Send data
            const params = Object.keys(checkoutData)
                .map(key => key + '=' + encodeURIComponent(checkoutData[key]))
                .join('&');
            
            xhr.send(params);
        }

        // Show message function
        function showMessage(message, isSuccess) {
            const messageDiv = document.getElementById('message');
            messageDiv.innerHTML = '<i class="fas fa-' + (isSuccess ? 'check-circle' : 'exclamation-triangle') + '"></i> ' + message;
            messageDiv.className = 'alert message ' + (isSuccess ? 'alert-success' : 'alert-danger');
            messageDiv.style.display = 'block';
            
            setTimeout(function() {
                messageDiv.style.display = 'none';
            }, 5000);
        }

        // Add click event listeners to payment methods
        document.addEventListener('DOMContentLoaded', function() {
            document.querySelectorAll('.payment-method').forEach(function(element) {
                element.addEventListener('click', function() {
                    const radio = this.querySelector('input[type="radio"]');
                    if (radio) {
                        selectPayment(radio.value);
                    }
                });
            });
        });
    </script>
</body>
</html>