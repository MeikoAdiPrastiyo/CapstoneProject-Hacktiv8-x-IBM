<%-- selesaikanTransaksi.jsp - Updated UI with image preview --%>
<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="java.sql.*" %>
<%@ page import="java.text.SimpleDateFormat" %>
<%@ page import="java.text.DecimalFormat" %>
<%
    // Check if user is logged in
    String username = (String) session.getAttribute("username");
    String userRole = (String) session.getAttribute("role");
    String email = (String) session.getAttribute("email");
    if (username == null) {
        response.sendRedirect("login.html");
        return;
    }
    
    // Get transaction ID from parameter
    String transaksiIdParam = request.getParameter("id");
    if (transaksiIdParam == null || transaksiIdParam.trim().isEmpty()) {
        response.sendRedirect("riwayatTransaksi.jsp");
        return;
    }
    
    int transaksiId = 0;
    try {
        transaksiId = Integer.parseInt(transaksiIdParam);
    } catch (NumberFormatException e) {
        response.sendRedirect("riwayatTransaksi.jsp");
        return;
    }
    
    // Database connection
    String url = "jdbc:mysql://localhost:3306/webcapstone";
    String user = "root";
    String dbpass = "";
    Connection conn = null;
    PreparedStatement pstmt = null;
    ResultSet rs = null;
    
    // Transaction details
    double totalHarga = 0;
    String metodePembayaran = "";
    String statusPembayaran = "";
    String statusPesanan = "";
    String alamatPengiriman = "";
    Timestamp createdAt = null;
    int userId = 0;
    boolean transactionExists = false;
%>

<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>E-Shop - Selesaikan Pembayaran</title>
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
            min-height: 100vh;
            display: flex;
            align-items: center;
            justify-content: center;
            padding: 20px 0;
        }

        .payment-container {
            background: white;
            border-radius: 15px;
            box-shadow: 0 10px 30px rgba(0, 0, 0, 0.1);
            max-width: 800px;
            width: 100%;
            margin: 20px;
        }

        .payment-header {
            background: linear-gradient(135deg, var(--primary-color), var(--hover-color));
            color: white;
            padding: 30px;
            border-radius: 15px 15px 0 0;
            text-align: center;
        }

        .payment-body {
            padding: 30px;
        }

        .transaction-info {
            background: #f8f9fa;
            border-radius: 10px;
            padding: 20px;
            margin-bottom: 25px;
            border-left: 4px solid var(--primary-color);
        }

        .info-row {
            display: flex;
            justify-content: space-between;
            margin-bottom: 10px;
            padding-bottom: 5px;
            border-bottom: 1px solid #dee2e6;
        }

        .info-row:last-child {
            border-bottom: none;
            font-weight: bold;
            font-size: 1.2rem;
        }

        .info-label {
            font-weight: 500;
            color: #6c757d;
        }

        .info-value {
            font-weight: 600;
            color: #333;
        }

        .total-amount {
            color: var(--primary-color) !important;
        }

        .payment-method-section {
            margin-bottom: 25px;
        }

        .bank-info {
            background: linear-gradient(135deg, #e3f2fd, #bbdefb);
            border-radius: 10px;
            padding: 20px;
            margin-bottom: 20px;
            border-left: 4px solid #2196f3;
        }

        .bank-boxes {
            display: flex;
            flex-direction: column;
            gap: 16px;
            margin-top: 16px;
        }

        .bank-card {
            display: flex;
            align-items: center;
            background: #fff;
            border: 1px solid #e0e0e0;
            border-radius: 10px;
            padding: 12px 16px;
            box-shadow: 0 4px 8px rgba(0,0,0,0.06);
            justify-content: space-between;
            flex-wrap: wrap;
        }

        .bank-logo {
            width: 60px;
            height: auto;
            margin-right: 16px;
        }

        .bank-text {
            flex-grow: 1;
            min-width: 220px;
        }

        .copy-btn {
            background-color: #2196f3;
            color: white;
            border: none;
            border-radius: 6px;
            padding: 8px 14px;
            cursor: pointer;
            font-size: 14px;
            transition: background 0.3s;
        }

        .copy-btn:hover {
            background-color: #1976d2;
        }

        .upload-area {
            border: 2px dashed #dee2e6;
            border-radius: 10px;
            padding: 40px 20px;
            text-align: center;
            transition: all 0.3s ease;
            cursor: pointer;
            margin-bottom: 20px;
        }

        .upload-area:hover, .upload-area.dragover {
            border-color: var(--primary-color);
            background: #f8f9fa;
        }

        .upload-area.has-file {
            border-color: #28a745;
            background: #f8fff9;
        }

        .file-info {
            display: none;
            background: #d4edda;
            color: #155724;
            padding: 15px;
            border-radius: 8px;
            margin-bottom: 15px;
        }

        /* Preview Image Styles */
        .preview-container {
            display: none;
            margin-top: 15px;
            text-align: center;
        }

        .preview-image {
            max-width: 100%;
            max-height: 300px;
            border-radius: 8px;
            box-shadow: 0 4px 15px rgba(0, 0, 0, 0.1);
            border: 2px solid #28a745;
        }

        .preview-pdf {
            background: #f8f9fa;
            border: 2px solid #6c757d;
            border-radius: 8px;
            padding: 20px;
            margin-top: 15px;
        }

        .pdf-icon {
            font-size: 3rem;
            color: #dc3545;
            margin-bottom: 10px;
        }

        .remove-preview {
            position: absolute;
            top: 10px;
            right: 10px;
            background: rgba(220, 53, 69, 0.9);
            color: white;
            border: none;
            border-radius: 50%;
            width: 30px;
            height: 30px;
            display: flex;
            align-items: center;
            justify-content: center;
            cursor: pointer;
            font-size: 14px;
            transition: all 0.3s ease;
        }

        .remove-preview:hover {
            background: #dc3545;
            transform: scale(1.1);
        }

        .preview-wrapper {
            position: relative;
            display: inline-block;
            margin-top: 15px;
        }

        .btn-payment {
            background: var(--primary-color);
            border: none;
            color: white;
            padding: 12px 30px;
            border-radius: 8px;
            font-weight: 600;
            width: 100%;
            margin-top: 20px;
            transition: all 0.3s ease;
        }

        .btn-payment:hover {
            background: var(--hover-color);
            transform: translateY(-2px);
            box-shadow: 0 4px 15px rgba(47, 108, 59, 0.3);
        }

        .btn-back {
            background: #6c757d;
            border: none;
            color: white;
            padding: 12px 30px;
            border-radius: 8px;
            font-weight: 600;
            width: 100%;
            margin-top: 10px;
            transition: all 0.3s ease;
        }

        .btn-back:hover {
            background: #5a6268;
        }

        .form-control:focus {
            border-color: var(--primary-color);
            box-shadow: 0 0 0 0.2rem rgba(47, 108, 59, 0.25);
        }

        .form-label {
            font-weight: 600;
            color: #333;
            margin-bottom: 8px;
        }

        .loading {
            display: none;
            text-align: center;
            padding: 20px;
        }

        .spinner-border {
            color: var(--primary-color);
        }

        .message {
            position: fixed;
            top: 20px;
            right: 20px;
            z-index: 1050;
            min-width: 300px;
            display: none;
        }

        .alert {
            border-radius: 10px;
            padding: 20px;
            margin-bottom: 20px;
        }

        .table-responsive {
            border-radius: 8px;
            overflow: hidden;
            margin-bottom: 20px;
        }

        .table {
            margin-bottom: 0;
        }

        .table th {
            background-color: var(--primary-color);
            color: white;
            border: none;
            font-weight: 600;
        }

        @media (max-width: 768px) {
            .bank-details {
                flex-direction: column;
                align-items: flex-start;
                gap: 10px;
            }
            
            .payment-container {
                margin: 10px;
            }
            
            .payment-header {
                padding: 20px;
            }
            
            .payment-body {
                padding: 20px;
            }

            .preview-image {
                max-height: 200px;
            }
        }
    </style>
</head>
<body>
    <!-- Success/Error Message -->
    <div id="message" class="alert message"></div>

    <div class="payment-container">
        <div class="payment-header">
            <h3><i class="fas fa-credit-card"></i> Selesaikan Pembayaran</h3>
            <p class="mb-0">Upload bukti pembayaran untuk transaksi Anda</p>
        </div>
        
        <div class="payment-body">
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
                
                // Get transaction details
                String getTransaksiSql = "SELECT * FROM transaksi WHERE id = ? AND user_id = ?";
                pstmt = conn.prepareStatement(getTransaksiSql);
                pstmt.setInt(1, transaksiId);
                pstmt.setInt(2, userId);
                rs = pstmt.executeQuery();
                
                if (rs.next()) {
                    transactionExists = true;
                    totalHarga = rs.getDouble("total_harga");
                    metodePembayaran = rs.getString("metode_pembayaran");
                    statusPembayaran = rs.getString("status_pembayaran");
                    statusPesanan = rs.getString("status_pesanan");
                    alamatPengiriman = rs.getString("alamat_pengiriman");
                    createdAt = rs.getTimestamp("created_at");
                }
                
                if (!transactionExists) {
            %>
            <div class="alert alert-danger">
                <i class="fas fa-exclamation-triangle"></i> Transaksi tidak ditemukan atau bukan milik Anda.
                <div class="mt-3">
                    <button class="btn-back" onclick="window.location.href='riwayatTransaksi.jsp'">
                        <i class="fas fa-arrow-left"></i> Kembali ke Riwayat Transaksi
                    </button>
                </div>
            </div>
            <%
                } else if (!statusPembayaran.equals("pending")) {
            %>
            <div class="alert alert-info">
                <i class="fas fa-info-circle"></i> Pembayaran untuk transaksi ini sudah <%= statusPembayaran.equals("paid") ? "lunas" : "gagal" %>.
                <div class="mt-3">
                    <button class="btn-back" onclick="window.location.href='riwayatTransaksi.jsp'">
                        <i class="fas fa-arrow-left"></i> Kembali ke Riwayat Transaksi
                    </button>
                </div>
            </div>
            <%
                } else {
                    SimpleDateFormat sdf = new SimpleDateFormat("dd MMM yyyy, HH:mm");
                    DecimalFormat df = new DecimalFormat("#,###");
            %>

            <!-- Transaction Info -->
            <div class="transaction-info">
                <h5 class="mb-3"><i class="fas fa-receipt"></i> Ringkasan Transaksi</h5>
                <div class="info-row">
                    <span class="info-label">ID Transaksi:</span>
                    <span class="info-value">#<%= transaksiId %></span>
                </div>
                <div class="info-row">
                    <span class="info-label">Tanggal:</span>
                    <span class="info-value"><%= sdf.format(createdAt) %></span>
                </div>
                <div class="info-row">
                    <span class="info-label">Metode Pembayaran:</span>
                    <span class="info-value"><%= metodePembayaran.replace("_", " ").toUpperCase() %></span>
                </div>
                <div class="info-row">
                    <span class="info-label">Total Pembayaran:</span>
                    <span class="info-value total-amount">Rp <%= df.format(totalHarga) %></span>
                </div>
            </div>

            <!-- Product Details -->
            <div class="mb-4">
                <h5><i class="fas fa-box"></i> Detail Barang</h5>
                <div class="table-responsive">
                    <table class="table table-striped">
                        <thead>
                            <tr>
                                <th>Nama Barang</th>
                                <th>Harga</th>
                                <th>Qty</th>
                                <th>Subtotal</th>
                            </tr>
                        </thead>
                        <tbody>
                            <%
                            PreparedStatement pstmtDetail = conn.prepareStatement(
                                "SELECT * FROM detail_transaksi WHERE transaksi_id = ?");
                            pstmtDetail.setInt(1, transaksiId);
                            ResultSet rsDetail = pstmtDetail.executeQuery();
                            
                            while (rsDetail.next()) {
                                String namaBarang = rsDetail.getString("nama_barang");
                                double harga = rsDetail.getDouble("harga");
                                int quantity = rsDetail.getInt("quantity");
                                double subtotal = rsDetail.getDouble("subtotal");
                            %>
                            <tr>
                                <td><%= namaBarang %></td>
                                <td>Rp <%= df.format(harga) %></td>
                                <td><%= quantity %></td>
                                <td>Rp <%= df.format(subtotal) %></td>
                            </tr>
                            <%
                            }
                            rsDetail.close();
                            pstmtDetail.close();
                            %>
                        </tbody>
                    </table>
                </div>
            </div>

            <!-- Payment Instructions -->
            <div class="payment-method-section">
                <h5><i class="fas fa-university"></i> Informasi Pembayaran</h5>
                
                <% if (metodePembayaran.equals("transfer_bank")) { %>
                <div class="bank-info">
                    <h6><i class="fas fa-university"></i> Transfer Bank</h6>
                    <div class="bank-boxes">
                        <!-- BANK BCA -->
                        <div class="bank-card">
                            <img src="https://upload.wikimedia.org/wikipedia/commons/thumb/5/5c/Bank_Central_Asia.svg/2560px-Bank_Central_Asia.svg.png" class="bank-logo" alt="BCA">
                            <div class="bank-text">
                                <strong>Bank BCA</strong><br>
                                <span id="rekBCA">No. Rekening: 1231231230</span><br>
                                <span>Atas Nama: PT Ternak Indonesia</span>
                            </div>
                            <button class="copy-btn" onclick="copyToClipboard('1231231230')">
                                <i class="fas fa-copy"></i> Copy
                            </button>
                        </div>

                        <!-- BANK BNI -->
                        <div class="bank-card">
                            <img src="https://upload.wikimedia.org/wikipedia/id/thumb/5/55/BNI_logo.svg/2560px-BNI_logo.svg.png" class="bank-logo" alt="BNI">
                            <div class="bank-text">
                                <strong>Bank BNI</strong><br>
                                <span id="rekBNI">No. Rekening: 4564564560</span><br>
                                <span>Atas Nama: PT Ternak Indonesia</span>
                            </div>
                            <button class="copy-btn" onclick="copyToClipboard('4564564560')">
                                <i class="fas fa-copy"></i> Copy
                            </button>
                        </div>

                        <!-- BANK MANDIRI -->
                        <div class="bank-card">
                            <img src="https://upload.wikimedia.org/wikipedia/commons/thumb/a/ad/Bank_Mandiri_logo_2016.svg/2560px-Bank_Mandiri_logo_2016.svg.png" class="bank-logo" alt="Mandiri">
                            <div class="bank-text">
                                <strong>Bank MANDIRI</strong><br>
                                <span id="rekMandiri">No. Rekening: 7897897890</span><br>
                                <span>Atas Nama: PT Ternak Indonesia</span>
                            </div>
                            <button class="copy-btn" onclick="copyToClipboard('7897897890')">
                                <i class="fas fa-copy"></i> Copy
                            </button>
                        </div>
                    </div>
                </div>

                <% } else if (metodePembayaran.equals("e_wallet")) { %>
                <div class="bank-info">
                    <h6><i class="fas fa-mobile-alt"></i> E-Wallet</h6>
                    <div class="bank-details">
                        <div>
                            <strong>OVO/GoPay/DANA</strong><br>
                            <span>No. HP: 081234567890</span><br>
                            <span>Atas Nama: E-Shop Indonesia</span>
                        </div>
                        <button class="copy-btn" onclick="copyToClipboard('081234567890')" title="Copy Nomor HP">
                            <i class="fas fa-copy"></i> Copy
                        </button>
                    </div>
                </div>
                <% } %>

                <div class="alert alert-warning">
                    <i class="fas fa-exclamation-triangle"></i>
                    <strong>Penting:</strong> Transfer sesuai dengan nominal yang tertera. Upload bukti pembayaran yang jelas untuk mempercepat verifikasi.
                </div>
            </div>

            <!-- Upload Form -->
            <div class="payment-method-section">
                <h5><i class="fas fa-upload"></i> Upload Bukti Pembayaran</h5>
                
                <form id="paymentForm" enctype="multipart/form-data">
                    <input type="hidden" name="transaksiId" value="<%= transaksiId %>">
                    
                    <div class="mb-3">
                        <label class="form-label">Bukti Transfer/Screenshot <span class="text-danger">*</span></label>
                        <div class="upload-area" id="uploadArea" onclick="document.getElementById('buktiFile').click()">
                            <i class="fas fa-cloud-upload-alt fa-3x text-muted mb-3"></i>
                            <p class="text-muted mb-1">Klik untuk memilih file atau drag & drop</p>
                            <small class="text-muted">Format: JPG, PNG, PDF (Max: 2MB)</small>
                        </div>
                        <input type="file" id="buktiFile" name="buktiFile" accept=".jpg,.jpeg,.png,.pdf" style="display: none;" required>
                        
                        <!-- File Info -->
                        <div class="file-info" id="fileInfo">
                            <i class="fas fa-check-circle"></i>
                            <span id="fileName"></span>
                            <button type="button" class="btn btn-sm btn-outline-danger float-end" onclick="removeFile()">
                                <i class="fas fa-times"></i> Hapus
                            </button>
                        </div>

                        <!-- Preview Container -->
                        <div class="preview-container" id="previewContainer">
                            <div class="preview-wrapper" id="previewWrapper">
                                <button type="button" class="remove-preview" onclick="removeFile()" title="Hapus file">
                                    <i class="fas fa-times"></i>
                                </button>
                                <img id="previewImage" class="preview-image" style="display: none;" alt="Preview">
                                <div id="previewPdf" class="preview-pdf" style="display: none;">
                                    <i class="fas fa-file-pdf pdf-icon"></i>
                                    <p class="mb-0"><strong>File PDF berhasil dipilih</strong></p>
                                    <small class="text-muted" id="pdfFileName"></small>
                                </div>
                            </div>
                        </div>
                    </div>

                    <div class="row">
                        <div class="col-md-6">
                            <div class="mb-3">
                                <label class="form-label">Nomor Rekening/HP Pengirim <span class="text-danger">*</span></label>
                                <input type="text" class="form-control" name="nomorRekening" required>
                            </div>
                        </div>
                        <div class="col-md-6">
                            <div class="mb-3">
                                <label class="form-label">Nama Pengirim <span class="text-danger">*</span></label>
                                <input type="text" class="form-control" name="namaPengirim" required>
                            </div>
                        </div>
                    </div>

                    <div class="mb-3">
                        <label class="form-label">Tanggal Transfer <span class="text-danger">*</span></label>
                        <input type="datetime-local" class="form-control" name="tanggalTransfer" required>
                    </div>

                    <div class="mb-3">
                        <label class="form-label">Catatan (Opsional)</label>
                        <textarea class="form-control" name="catatan" rows="3" placeholder="Tambahan informasi..."></textarea>
                    </div>

                    <!-- Loading -->
                    <div class="loading" id="loading">
                        <div class="spinner-border" role="status">
                            <span class="visually-hidden">Memproses...</span>
                        </div>
                        <p class="mt-2">Sedang memproses pembayaran...</p>
                    </div>

                    <button type="submit" class="btn-payment" id="submitBtn">
                        <i class="fas fa-paper-plane"></i> Submit Bukti Pembayaran
                    </button>
                    
                    <button type="button" class="btn-back" onclick="window.location.href='riwayatTransaksi.jsp'">
                        <i class="fas fa-arrow-left"></i> Kembali
                    </button>
                </form>
            </div>

            <%
                }
            } catch(Exception e) {
                out.println("<div class='alert alert-danger'><i class='fas fa-exclamation-triangle'></i> Error: " + e.getMessage() + "</div>");
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
        // File upload handling elements
        const uploadArea = document.getElementById('uploadArea');
        const fileInput = document.getElementById('buktiFile');
        const fileInfo = document.getElementById('fileInfo');
        const fileName = document.getElementById('fileName');
        const previewContainer = document.getElementById('previewContainer');
        const previewImage = document.getElementById('previewImage');
        const previewPdf = document.getElementById('previewPdf');
        const pdfFileName = document.getElementById('pdfFileName');

        // Drag and drop events
        uploadArea.addEventListener('dragover', (e) => {
            e.preventDefault();
            uploadArea.classList.add('dragover');
        });

        uploadArea.addEventListener('dragleave', () => {
            uploadArea.classList.remove('dragover');
        });

        uploadArea.addEventListener('drop', (e) => {
            e.preventDefault();
            uploadArea.classList.remove('dragover');
            const files = e.dataTransfer.files;
            if (files.length > 0) {
                handleFileSelect(files[0]);
            }
        });

        // File input change
        fileInput.addEventListener('change', (e) => {
            if (e.target.files.length > 0) {
                handleFileSelect(e.target.files[0]);
            }
        });

        function handleFileSelect(file) {
            // Validate file type
            const allowedTypes = ['image/jpeg', 'image/jpg', 'image/png', 'application/pdf'];
            if (!allowedTypes.includes(file.type)) {
                showMessage('File harus berformat JPG, PNG, atau PDF', false);
                return;
            }

            // Validate file size (2MB)
            if (file.size > 2 * 1024 * 1024) {
                showMessage('Ukuran file maksimal 2MB', false);
                return;
            }

            // Show file info
            fileName.textContent = file.name + ' (' + formatFileSize(file.size) + ')';
            fileInfo.style.display = 'block';
            uploadArea.classList.add('has-file');

            // Show preview
            showPreview(file);
        }

        function showPreview(file) {
            const reader = new FileReader();
            
            reader.onload = function(e) {
                previewContainer.style.display = 'block';
                
                if (file.type.startsWith('image/')) {
                    // Show image preview
                    previewImage.src = e.target.result;
                    previewImage.style.display = 'block';
                    previewPdf.style.display = 'none';
                } else if (file.type === 'application/pdf') {
                    // Show PDF preview
                    previewPdf.style.display = 'block';
                    previewImage.style.display = 'none';
                    pdfFileName.textContent = file.name;
                }
            };
            
            if (file.type.startsWith('image/')) {
                reader.readAsDataURL(file);
            } else if (file.type === 'application/pdf') {
                // For PDF, we don't need to read the file, just show the info
                previewContainer.style.display = 'block';
                previewPdf.style.display = 'block';
                previewImage.style.display = 'none';
                pdfFileName.textContent = file.name;
            }
        }

function removeFile() {
            fileInput.value = '';
            fileInfo.style.display = 'none';
            previewContainer.style.display = 'none';
            previewImage.style.display = 'none';
            previewPdf.style.display = 'none';
            previewImage.src = '';
            uploadArea.classList.remove('has-file');
        }

        function formatFileSize(bytes) {
            if (bytes === 0) return '0 Bytes';
            const k = 1024;
            const sizes = ['Bytes', 'KB', 'MB', 'GB'];
            const i = Math.floor(Math.log(bytes) / Math.log(k));
            return parseFloat((bytes / Math.pow(k, i)).toFixed(2)) + ' ' + sizes[i];
        }

        // Copy to clipboard function
        function copyToClipboard(text) {
            navigator.clipboard.writeText(text).then(function() {
                showMessage('Nomor rekening berhasil disalin', true);
            }).catch(function(err) {
                // Fallback for older browsers
                const textArea = document.createElement('textarea');
                textArea.value = text;
                document.body.appendChild(textArea);
                textArea.select();
                document.execCommand('copy');
                document.body.removeChild(textArea);
                showMessage('Nomor rekening berhasil disalin', true);
            });
        }

        // Form submission
        document.getElementById('paymentForm').addEventListener('submit', function(e) {
            e.preventDefault();
            
            // Validate file
            if (!fileInput.files.length) {
                showMessage('Silakan pilih file bukti pembayaran', false);
                return;
            }

            // Show loading
            document.getElementById('loading').style.display = 'block';
            document.getElementById('submitBtn').disabled = true;

            // Create FormData
            const formData = new FormData(this);

            // Submit using fetch
            fetch('processPayment.jsp', {
                method: 'POST',
                body: formData
            })
            .then(response => response.text())
            .then(data => {
                document.getElementById('loading').style.display = 'none';
                document.getElementById('submitBtn').disabled = false;
                
                if (data.includes('success')) {
                    showMessage('Bukti pembayaran berhasil diupload! Transaksi Anda sedang diverifikasi.', true);
                    setTimeout(() => {
                        window.location.href = 'riwayatTransaksi.jsp';
                    }, 2000);
                } else {
                    showMessage('Gagal mengupload bukti pembayaran. Silakan coba lagi.', false);
                }
            })
            .catch(error => {
                document.getElementById('loading').style.display = 'none';
                document.getElementById('submitBtn').disabled = false;
                showMessage('Terjadi kesalahan. Silakan coba lagi.', false);
                console.error('Error:', error);
            });
        });

        // Show message function
        function showMessage(text, isSuccess) {
            const messageDiv = document.getElementById('message');
            messageDiv.className = 'alert message ' + (isSuccess ? 'alert-success' : 'alert-danger');
            messageDiv.innerHTML = '<i class="fas fa-' + (isSuccess ? 'check-circle' : 'exclamation-triangle') + '"></i> ' + text;
            messageDiv.style.display = 'block';
            
            // Auto hide after 5 seconds
            setTimeout(() => {
                messageDiv.style.display = 'none';
            }, 5000);
        }

        // Set default datetime to now
        document.addEventListener('DOMContentLoaded', function() {
            const now = new Date();
            const year = now.getFullYear();
            const month = String(now.getMonth() + 1).padStart(2, '0');
            const day = String(now.getDate()).padStart(2, '0');
            const hours = String(now.getHours()).padStart(2, '0');
            const minutes = String(now.getMinutes()).padStart(2, '0');
            
            const defaultDateTime = `${year}-${month}-${day}T${hours}:${minutes}`;
            document.querySelector('input[name="tanggalTransfer"]').value = defaultDateTime;
        });

        // Prevent form submission on Enter key for file input
        fileInput.addEventListener('keydown', function(e) {
            if (e.key === 'Enter') {
                e.preventDefault();
            }
        });

        // Auto-fill sender name from session if available
        <% if (username != null) { %>
        document.addEventListener('DOMContentLoaded', function() {
            const namaPengirimInput = document.querySelector('input[name="namaPengirim"]');
            if (namaPengirimInput && !namaPengirimInput.value) {
                namaPengirimInput.value = '<%= username %>';
            }
        });
        <% } %>
    </script>
</body>
</html>