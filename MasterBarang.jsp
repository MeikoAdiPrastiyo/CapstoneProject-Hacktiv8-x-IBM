<%-- MasterBarang.jsp --%>
<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="java.sql.*" %>
<%
    // Check if user is logged in
    String username = (String) session.getAttribute("username");
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
%>
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>Master Barang</title>
  <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.5.0/css/all.min.css"/>
  <style>
    :root {
      --primary-color: #2f6c3b;
      --hover-color: #255b30;
      --sidebar-bg: #343a40;
      --sidebar-text: #ffffff;
      --transition: all 0.3s ease;
    }

    * {
      margin: 0;
      padding: 0;
      box-sizing: border-box;
    }

    body {
      font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
      background-color: #f2f2f2;
      display: flex;
      min-height: 100vh;
    }

    /* Sidebar */
    .sidebar {
      background-color: var(--sidebar-bg);
      width: 250px;
      color: var(--sidebar-text);
      display: flex;
      flex-direction: column;
    }

    .sidebar-header {
      padding: 20px;
      font-size: 24px;
      font-weight: bold;
      border-bottom: 1px solid rgba(255, 255, 255, 0.1);
      text-align: center;
    }

    .sidebar-menu {
      margin-top: 20px;
    }

    .sidebar-menu a {
      display: flex;
      align-items: center;
      padding: 15px 20px;
      color: var(--sidebar-text);
      text-decoration: none;
      transition: var(--transition);
    }

    .sidebar-menu a:hover, .sidebar-menu a.active {
      background-color: rgba(255, 255, 255, 0.1);
      border-left: 4px solid var(--primary-color);
    }

    .sidebar-menu i {
      margin-right: 10px;
      width: 20px;
      text-align: center;
    }

    /* Main Content */
    .main-content {
      flex-grow: 1;
      padding: 20px;
      background-color: #f2f2f2;
    }

    .header {
      display: flex;
      justify-content: space-between;
      align-items: center;
      margin-bottom: 20px;
    }

    .welcome-text {
      font-size: 24px;
      color: #333;
    }

    .logout-btn {
      background-color: #dc3545;
      color: white;
      border: none;
      border-radius: 5px;
      padding: 8px 15px;
      cursor: pointer;
      transition: background-color 0.3s;
    }

    .logout-btn:hover {
      background-color: #c82333;
    }

    
    .header-actions {
  display: flex;
  gap: 10px;
  align-items: center;
}

.export-btn {
  display: inline-flex;
  align-items: center;
  padding: 8px 12px;
  border-radius: 5px;
  font-size: 14px;
  text-decoration: none;
  font-weight: 500;
  transition: background-color 0.3s;
}

.export-btn i {
  margin-right: 6px;
}

/* Style khusus untuk Word dan JSON */
.export-btn.word {
  background-color: #007bff;
  color: white;
}

.export-btn.word:hover {
  background-color: #0056b3;
}

.export-btn.json {
  background-color: #17a2b8;
  color: white;
}

.export-btn.json:hover {
  background-color: #117a8b;
}

    .user-name {
      color: var(--primary-color);
      font-weight: 600;
    }

    /* Data Table Styling */
    .data-table-container {
      background-color: white;
      border-radius: 8px;
      box-shadow: 0 2px 10px rgba(0, 0, 0, 0.1);
      padding: 20px;
      margin-top: 20px;
      overflow-x: auto;
    }

    .table-title {
      color: var(--primary-color);
      margin-bottom: 20px;
      font-size: 22px;
      font-weight: 600;
    }

    .data-table {
      width: 100%;
      border-collapse: collapse;
      margin-top: 10px;
    }

    .data-table th {
      background-color: var(--primary-color);
      color: white;
      padding: 12px 15px;
      text-align: left;
      font-weight: 600;
    }

    .data-table td {
      padding: 12px 15px;
      border-bottom: 1px solid #ddd;
      vertical-align: middle;
    }

    .data-table tr:hover {
      background-color: #f5f5f5;
    }

    .add-btn {
      background-color: var(--primary-color);
      color: white;
      border: none;
      border-radius: 4px;
      padding: 10px 20px;
      cursor: pointer;
      font-size: 16px;
      transition: background-color 0.3s;
      margin-bottom: 20px;
    }

    .add-btn:hover {
      background-color: var(--hover-color);
    }

    .edit-btn {
      background-color: #ffc107;
      color: #212529;
      border: none;
      border-radius: 4px;
      padding: 6px 12px;
      cursor: pointer;
      font-size: 14px;
      transition: background-color 0.3s;
    }

    .edit-btn:hover {
      background-color: #e0a800;
    }
    
    .delete-btn {
      background-color: #dc3545;
      color: white;
      border: none;
      border-radius: 4px;
      padding: 6px 12px;
      margin-left: 5px;
      cursor: pointer;
      font-size: 14px;
      transition: background-color 0.3s;
    }

    .delete-btn:hover {
      background-color: #c82333;
    }

    .table-controls {
      display: flex;
      justify-content: space-between;
      margin-bottom: 20px;
      align-items: center;
    }

    .search-box {
      display: flex;
      align-items: center;
    }

    .search-box input {
      padding: 8px 12px;
      border: 1px solid #ddd;
      border-radius: 4px;
      width: 250px;
    }

    .search-box button {
      background-color: var(--primary-color);
      color: white;
      border: none;
      border-radius: 0 4px 4px 0;
      padding: 8px 15px;
      margin-left: -1px;
      cursor: pointer;
    }

    /* Product Image */
    .product-image {
      width: 60px;
      height: 60px;
      object-fit: cover;
      border-radius: 4px;
      border: 1px solid #ddd;
    }

    /* Price formatting */
    .price {
      font-weight: 600;
      color: var(--primary-color);
    }

    /* Stock indicator */
    .stock {
      padding: 4px 8px;
      border-radius: 12px;
      font-size: 12px;
      font-weight: 600;
    }

    .stock.low {
      background-color: #fff3cd;
      color: #856404;
    }

    .stock.medium {
      background-color: #d1ecf1;
      color: #0c5460;
    }

    .stock.high {
      background-color: #d4edda;
      color: #155724;
    }

    /* Modal Styles */
    .modal-backdrop {
      position: fixed;
      top: 0;
      left: 0;
      width: 100%;
      height: 100%;
      background-color: rgba(0, 0, 0, 0.5);
      display: flex;
      justify-content: center;
      align-items: center;
      z-index: 1000;
      visibility: hidden;
      opacity: 0;
      transition: all 0.3s;
    }
    
    .modal-backdrop.active {
      visibility: visible;
      opacity: 1;
    }
    
    .modal-container {
      background-color: white;
      border-radius: 8px;
      box-shadow: 0 5px 20px rgba(0, 0, 0, 0.2);
      width: 90%;
      max-width: 600px;
      padding: 25px;
      position: relative;
      transform: translateY(-20px);
      transition: transform 0.3s;
      max-height: 90vh;
      overflow-y: auto;
    }
    
    .modal-backdrop.active .modal-container {
      transform: translateY(0);
    }
    
    .modal-header {
      display: flex;
      justify-content: space-between;
      align-items: center;
      margin-bottom: 20px;
    }
    
    .modal-title {
      font-size: 20px;
      color: var(--primary-color);
      font-weight: 600;
    }
    
    .modal-close {
      font-size: 22px;
      color: #666;
      background: none;
      border: none;
      cursor: pointer;
    }
    
    .modal-body {
      margin-bottom: 20px;
    }
    
    .form-group {
      margin-bottom: 15px;
    }
    
    .form-group label {
      display: block;
      margin-bottom: 5px;
      font-weight: 500;
      color: #333;
    }
    
    .form-group input[type="text"],
    .form-group input[type="number"] {
      width: 100%;
      padding: 10px;
      border: 1px solid #ddd;
      border-radius: 4px;
      font-size: 14px;
    }

    /* Drag and Drop Styles */
    .image-upload-area {
      border: 2px dashed #ddd;
      border-radius: 8px;
      padding: 40px 20px;
      text-align: center;
      transition: all 0.3s ease;
      cursor: pointer;
      background-color: #fafafa;
    }

    .image-upload-area.dragover {
      border-color: var(--primary-color);
      background-color: #f0f8f0;
    }

    .image-upload-area i {
      font-size: 48px;
      color: #ccc;
      margin-bottom: 10px;
    }

    .image-upload-area p {
      color: #666;
      margin: 0;
    }

    .image-preview {
      max-width: 200px;
      max-height: 200px;
      margin: 10px auto;
      border-radius: 8px;
      box-shadow: 0 2px 8px rgba(0,0,0,0.1);
    }

    .modal-footer {
      display: flex;
      justify-content: flex-end;
      gap: 10px;
    }
    
    .cancel-btn {
      background-color: #6c757d;
      color: white;
      border: none;
      border-radius: 4px;
      padding: 8px 16px;
      cursor: pointer;
      transition: background-color 0.3s;
    }
    
    .cancel-btn:hover {
      background-color: #5a6268;
    }
    
    .save-btn {
      background-color: var(--primary-color);
      color: white;
      border: none;
      border-radius: 4px;
      padding: 8px 16px;
      cursor: pointer;
      transition: background-color 0.3s;
    }
    
    .save-btn:hover {
      background-color: var(--hover-color);
    }

    /* Message Styles */
    .message {
      padding: 10px 15px;
      margin-bottom: 15px;
      border-radius: 4px;
      display: none;
      font-weight: 600;
      text-align: center;
    }
    
    .success-message {
      background-color: #d4edda;
      color: #155724;
      border: 1px solid #c3e6cb;
    }
    
    .error-message {
      background-color: #f8d7da;
      color: #721c24;
      border: 1px solid #f5c6cb;
    }
  </style>
</head>
<body>
  <!-- Sidebar -->
  <div class="sidebar">
    <div class="sidebar-header">Dashboard</div>
    <div class="sidebar-menu">
      <a href="dashboard.jsp">
        <i class="fas fa-home"></i> Home
      </a>
      <a href="data-register.jsp">
        <i class="fas fa-users"></i> Data Register
      </a>
      <a href="MasterBarang.jsp" class="active">
        <i class="fas fa-boxes"></i> Master Barang
      </a>
      <a href="transaksi.jsp">
        <i class="fas fa-receipt"></i> Transaksi
      </a>
    </div>
  </div>

  <!-- Main Content -->
  <div class="main-content">
<div class="header">
  <h1 class="welcome-text">
    Master Barang - <span class="user-name"><%= username %></span>
  </h1>
  <div class="header-actions">
    <a href="exportword.jsp" class="export-btn word">
      <i class="fas fa-file-word"></i> Export Word
    </a>
    <a href="exportjson.jsp" class="export-btn json">
      <i class="fas fa-code"></i> Export JSON
    </a>
    <form action="logout.jsp" method="post" style="margin: 0;">
      <button type="submit" class="logout-btn">
        <i class="fas fa-sign-out-alt"></i> Logout
      </button>
    </form>
  </div>
</div>

    <div class="data-table-container">
      <h2 class="table-title">Data Barang</h2>
      
      <!-- Success/Error Message -->
      <div id="message" class="message"></div>
      
      <div class="table-controls">
        <button class="add-btn" onclick="openAddModal()">
          <i class="fas fa-plus"></i> Tambah Barang
        </button>
        <div class="search-box">
          <input type="text" id="searchInput" placeholder="Cari barang...">
          <button type="button" onclick="searchTable()"><i class="fas fa-search"></i></button>
        </div>
      </div>
      
      <table class="data-table" id="dataTable">
        <thead>
          <tr>
            <th>No</th>
            <th>Gambar</th>
            <th>Nama Barang</th>
            <th>Quantity</th>
            <th>Harga</th>
            <th>Aksi</th>
          </tr>
        </thead>
        <tbody>
          <%
            try {
                Class.forName("com.mysql.cj.jdbc.Driver");
                conn = DriverManager.getConnection(url, user, dbpass);
                String sql = "SELECT * FROM barang ORDER BY id ASC";
                pstmt = conn.prepareStatement(sql);
                rs = pstmt.executeQuery();
                
                int counter = 1;
                while(rs.next()) {
                    String barangId = rs.getString("id");
                    String namaBarang = rs.getString("nama_barang");
                    String gambar = rs.getString("gambar");
                    int quantity = rs.getInt("quantity");
                    double harga = rs.getDouble("harga");
                    
                    // Determine stock level
                    String stockClass = quantity <= 10 ? "low" : quantity <= 50 ? "medium" : "high";
          %>
          <tr>
            <td><%= counter++ %></td>
            <td>
              <% if (gambar != null && !gambar.trim().isEmpty()) { %>
                <img src="uploads/<%= gambar %>" alt="<%= namaBarang %>" class="product-image" onerror="this.src='https://via.placeholder.com/60x60?text=No+Image'">
              <% } else { %>
                <img src="https://via.placeholder.com/60x60?text=No+Image" alt="No Image" class="product-image">
              <% } %>
            </td>
            <td><%= namaBarang %></td>
            <td>
              <span class="stock <%= stockClass %>"><%= quantity %></span>
            </td>
            <td class="price">Rp <%= String.format("%,.0f", harga) %></td>
            <td>
              <button class="edit-btn" onclick="openEditModal('<%= barangId %>', '<%= namaBarang %>', '<%= quantity %>', '<%= harga %>', '<%= gambar != null ? gambar : "" %>')">Edit</button>
              <button class="delete-btn" onclick="confirmDelete('<%= barangId %>', '<%= namaBarang %>')">Delete</button>
            </td>
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
        </tbody>
      </table>
    </div>
  </div>
  
  <!-- Add/Edit Modal -->
  <div class="modal-backdrop" id="barangModal">
    <div class="modal-container">
      <div class="modal-header">
        <h3 class="modal-title" id="modalTitle">Tambah Barang</h3>
        <button class="modal-close" onclick="closeModal()">&times;</button>
      </div>
      <div class="modal-body">
        <form id="barangForm" enctype="multipart/form-data">
          <input type="hidden" id="barangId" name="barangId">
          <input type="hidden" id="isEdit" name="isEdit" value="false">
          
          <div class="form-group">
            <label for="namaBarang">Nama Barang</label>
            <input type="text" id="namaBarang" name="namaBarang" required>
          </div>
          
          <div class="form-group">
            <label>Gambar Barang</label>
            <div class="image-upload-area" id="imageUploadArea" onclick="document.getElementById('imageInput').click()">
              <i class="fas fa-cloud-upload-alt"></i>
              <p>Klik atau drag & drop gambar di sini</p>
              <p style="font-size: 12px; color: #999;">Maksimal 10MB (JPG, PNG, GIF)</p>
            </div>
            <input type="file" id="imageInput" name="gambarBarang" accept="image/*" style="display: none;">
            <img id="imagePreview" class="image-preview" style="display: none;">
          </div>
          
          <div class="form-group">
            <label for="quantity">Quantity</label>
            <input type="number" id="quantity" name="quantity" min="0" required>
          </div>
          
          <div class="form-group">
            <label for="harga">Harga</label>
            <input type="number" id="harga" name="harga" min="0" step="0.01" required>
          </div>
        </form>
      </div>
      <div class="modal-footer">
        <button class="cancel-btn" onclick="closeModal()">Cancel</button>
        <button class="save-btn" onclick="saveBarang()">Save</button>
      </div>
    </div>
  </div>
  
  <!-- Delete Confirmation Modal -->
  <div class="modal-backdrop" id="deleteModal">
    <div class="modal-container">
      <div class="modal-header">
        <h3 class="modal-title">Konfirmasi Hapus</h3>
        <button class="modal-close" onclick="closeDeleteModal()">&times;</button>
      </div>
      <div class="modal-body">
        <p>Apakah Anda yakin ingin menghapus barang: <span id="deleteBarangName" style="font-weight: bold;"></span>?</p>
        <p style="color: #dc3545;">Tindakan ini tidak dapat dibatalkan.</p>
        <input type="hidden" id="deleteBarangId">
      </div>
      <div class="modal-footer">
        <button class="cancel-btn" onclick="closeDeleteModal()">Batal</button>
        <button class="delete-btn" onclick="deleteBarang()">Hapus</button>
      </div>
    </div>
  </div>

  <script>
    let currentImageFile = null;

    // Image upload and drag & drop functionality
    document.addEventListener('DOMContentLoaded', function() {
      const uploadArea = document.getElementById('imageUploadArea');
      const imageInput = document.getElementById('imageInput');
      const imagePreview = document.getElementById('imagePreview');

      // Prevent default drag behaviors
      ['dragenter', 'dragover', 'dragleave', 'drop'].forEach(eventName => {
        uploadArea.addEventListener(eventName, preventDefaults, false);
        document.body.addEventListener(eventName, preventDefaults, false);
      });

      // Highlight drop area when item is dragged over it
      ['dragenter', 'dragover'].forEach(eventName => {
        uploadArea.addEventListener(eventName, highlight, false);
      });

      ['dragleave', 'drop'].forEach(eventName => {
        uploadArea.addEventListener(eventName, unhighlight, false);
      });

      // Handle dropped files
      uploadArea.addEventListener('drop', handleDrop, false);
      imageInput.addEventListener('change', handleFileSelect, false);

      function preventDefaults(e) {
        e.preventDefault();
        e.stopPropagation();
      }

      function highlight() {
        uploadArea.classList.add('dragover');
      }

      function unhighlight() {
        uploadArea.classList.remove('dragover');
      }

      function handleDrop(e) {
        const dt = e.dataTransfer;
        const files = dt.files;
        handleFiles(files);
      }

      function handleFileSelect(e) {
        const files = e.target.files;
        handleFiles(files);
      }

      function handleFiles(files) {
        if (files.length > 0) {
          const file = files[0];
          if (file.type.startsWith('image/')) {
            currentImageFile = file;
            previewImage(file);
          } else {
            showMessage('File harus berupa gambar!', false);
          }
        }
      }

      function previewImage(file) {
        const reader = new FileReader();
        reader.onload = function(e) {
          imagePreview.src = e.target.result;
          imagePreview.style.display = 'block';
          uploadArea.innerHTML = '<img src="' + e.target.result + '" style="max-width: 100%; max-height: 200px; border-radius: 4px;">';
        };
        reader.readAsDataURL(file);
      }
    });

    // Modal functions
    function openAddModal() {
      document.getElementById('modalTitle').textContent = 'Tambah Barang';
      document.getElementById('isEdit').value = 'false';
      document.getElementById('barangForm').reset();
      document.getElementById('barangId').value = '';
      resetImageUpload();
      document.getElementById('barangModal').classList.add('active');
    }

    function openEditModal(id, nama, quantity, harga, gambar) {
      document.getElementById('modalTitle').textContent = 'Edit Barang';
      document.getElementById('isEdit').value = 'true';
      document.getElementById('barangId').value = id;
      document.getElementById('namaBarang').value = nama;
      document.getElementById('quantity').value = quantity;
      document.getElementById('harga').value = harga;
      
      // Show existing image if available
      if (gambar && gambar.trim() !== '') {
        const imagePreview = document.getElementById('imagePreview');
        const uploadArea = document.getElementById('imageUploadArea');
        imagePreview.src = 'uploads/' + gambar;
        imagePreview.style.display = 'block';
        uploadArea.innerHTML = '<img src="uploads/' + gambar + '" style="max-width: 100%; max-height: 200px; border-radius: 4px;">';
      } else {
        resetImageUpload();
      }
      
      document.getElementById('barangModal').classList.add('active');
    }

    function closeModal() {
      document.getElementById('barangModal').classList.remove('active');
      currentImageFile = null;
    }

    function resetImageUpload() {
      const uploadArea = document.getElementById('imageUploadArea');
      const imagePreview = document.getElementById('imagePreview');
      uploadArea.innerHTML = '<i class="fas fa-cloud-upload-alt"></i><p>Klik atau drag & drop gambar di sini</p><p style="font-size: 12px; color: #999;">Maksimal 10MB (JPG, PNG, GIF)</p>';
      imagePreview.style.display = 'none';
      document.getElementById('imageInput').value = '';
      currentImageFile = null;
    }

    // Save barang function
    function saveBarang() {
      const formData = new FormData();
      const isEdit = document.getElementById('isEdit').value === 'true';
      
      formData.append('isEdit', isEdit);
      if (isEdit) {
        formData.append('barangId', document.getElementById('barangId').value);
      }
      formData.append('namaBarang', document.getElementById('namaBarang').value);
      formData.append('quantity', document.getElementById('quantity').value);
      formData.append('harga', document.getElementById('harga').value);
      
      if (currentImageFile) {
        formData.append('gambarBarang', currentImageFile);
      }

      const xhr = new XMLHttpRequest();
      xhr.open('POST', 'processBarang.jsp', true);
      
      xhr.onload = function() {
        if (xhr.status === 200) {
          try {
            const response = JSON.parse(xhr.responseText);
            showMessage(response.message, response.success);
            
            if (response.success) {
              closeModal();
              setTimeout(function() {
                location.reload();
              }, 1500);
            }
          } catch (e) {
            showMessage('Terjadi kesalahan saat memproses respons', false);
          }
        }
      };
      
      xhr.send(formData);
    }

    // Delete functions
    function confirmDelete(id, nama) {
      document.getElementById('deleteBarangId').value = id;
      document.getElementById('deleteBarangName').textContent = nama;
      document.getElementById('deleteModal').classList.add('active');
    }

    function closeDeleteModal() {
      document.getElementById('deleteModal').classList.remove('active');
    }

    function deleteBarang() {
      const barangId = document.getElementById('deleteBarangId').value;
      
      const xhr = new XMLHttpRequest();
      xhr.open('POST', 'deleteBarang.jsp', true);
      xhr.setRequestHeader('Content-Type', 'application/x-www-form-urlencoded');
      
      xhr.onload = function() {
        if (xhr.status === 200) {
          try {
            const response = JSON.parse(xhr.responseText);
            showMessage(response.message, response.success);
            
            if (response.success) {
              closeDeleteModal();
              setTimeout(function() {
                location.reload();
              }, 1000);
            }
          } catch (e) {
            showMessage('Terjadi kesalahan saat memproses respons', false);
          }
        }
      };
      
      xhr.send('barangId=' + encodeURIComponent(barangId));
    }

    // Search function
    function searchTable() {
      const input = document.getElementById('searchInput');
      const filter = input.value.toUpperCase();
      const table = document.getElementById('dataTable');
      const rows = table.getElementsByTagName('tr');
      
      for (let i = 1; i < rows.length; i++) {
        let found = false;
        const cells = rows[i].getElementsByTagName('td');
        
        for (let j = 2; j < cells.length - 1; j++) { // Skip image and actions columns
          const cellText = cells[j].textContent || cells[j].innerText;
          
          if (cellText.toUpperCase().indexOf(filter) > -1) {
            found = true;
            break;
          }
        }
        
        rows[i].style.display = found ? '' : 'none';
      }
    }

    // Show message function
    function showMessage(message, isSuccess) {
      const messageDiv = document.getElementById('message');
      messageDiv.innerHTML = message;
      messageDiv.className = 'message ' + (isSuccess ? 'success-message' : 'error-message');
      messageDiv.style.display = 'block';
      
      setTimeout(function() {
        messageDiv.style.display = 'none';
      }, 3000);
    }

    // Close modal when clicking outside
    window.onclick = function(event) {
      const barangModal = document.getElementById('barangModal');
      const deleteModal = document.getElementById('deleteModal');
      if (event.target === barangModal) {
        closeModal();
      }
      if (event.target === deleteModal) {
        closeDeleteModal();
      }
    };
  </script>
</body>
</html>