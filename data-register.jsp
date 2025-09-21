<%-- data-register.jsp --%>
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
  <title>Data Register</title>
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

    /* User greeting highlight */
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
    }

    .data-table tr:hover {
      background-color: #f5f5f5;
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

    /* Add search and filter controls */
    .table-controls {
      display: flex;
      justify-content: space-between;
      margin-bottom: 20px;
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
    
    /* Edit Modal Styles */
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
      max-width: 500px;
      padding: 25px;
      position: relative;
      transform: translateY(-20px);
      transition: transform 0.3s;
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
    
    .form-group input {
      width: 100%;
      padding: 10px;
      border: 1px solid #ddd;
      border-radius: 4px;
      font-size: 14px;
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

    /* Success Message */
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
      <a href="data-register.jsp" class="active">
        <i class="fas fa-users"></i> Data Register
      </a>
      <a href="MasterBarang.jsp" onclick="goToMasterBarang()">
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
      <h1 class="welcome-text">Selamat Datang, <span class="user-name"><%= username %></span></h1>
      <form action="logout.jsp" method="post">
        <button type="submit" class="logout-btn">Logout</button>
      </form>
    </div>

    <div class="data-table-container">
      <h2 class="table-title">Data Register</h2>
      
      <!-- Success/Error Message -->
      <div id="message" class="message"></div>
      
      <div class="table-controls">
        <div class="search-box">
          <input type="text" id="searchInput" placeholder="Cari pengguna...">
          <button type="button" onclick="searchTable()"><i class="fas fa-search"></i></button>
        </div>
      </div>
      
      <table class="data-table" id="dataTable">
        <thead>
          <tr>
            <th>No</th>
            <th>Nama</th>
            <th>Email</th>
            <th>Aksi</th>
          </tr>
        </thead>
        <tbody>
          <%
            try {
                Class.forName("com.mysql.cj.jdbc.Driver");
                conn = DriverManager.getConnection(url, user, dbpass);
                String sql = "SELECT * FROM user";
                pstmt = conn.prepareStatement(sql);
                rs = pstmt.executeQuery();
                
                int counter = 1;
                while(rs.next()) {
                    String userId = rs.getString("id");
                    String nama = rs.getString("nama");
                    String email = rs.getString("email");
          %>
          <tr>
            <td><%= counter++ %></td>
            <td><%= nama %></td>
            <td><%= email %></td>
            <td>
              <button class="edit-btn" onclick="openEditModal('<%= userId %>', '<%= nama %>', '<%= email %>')">Edit</button>
              <button class="delete-btn" onclick="confirmDelete('<%= userId %>', '<%= nama %>')">Delete</button>
            </td>
          </tr>
          <%
                }
            } catch(Exception e) {
                out.println("<tr><td colspan='4'>Error: " + e.getMessage() + "</td></tr>");
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
  
  <!-- Edit Modal -->
  <div class="modal-backdrop" id="editModal">
    <div class="modal-container">
      <div class="modal-header">
        <h3 class="modal-title">Edit User</h3>
        <button class="modal-close" onclick="closeEditModal()">&times;</button>
      </div>
      <div class="modal-body">
        <form id="editForm">
          <input type="hidden" id="userId" name="userId">
          
          <div class="form-group">
            <label for="editName">Nama</label>
            <input type="text" id="editName" name="editName" required>
          </div>
          
          <div class="form-group">
            <label for="editEmail">Email</label>
            <input type="email" id="editEmail" name="editEmail" required>
          </div>
          
          <div class="form-group">
            <label for="editPassword">Password Baru (kosongkan jika tidak diubah)</label>
            <input type="password" id="editPassword" name="editPassword">
          </div>
        </form>
      </div>
      <div class="modal-footer">
        <button class="cancel-btn" onclick="closeEditModal()">Cancel</button>
        <button class="save-btn" onclick="saveChanges()">Save Changes</button>
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
        <p>Apakah Anda yakin ingin menghapus pengguna: <span id="deleteUserName" class="fw-bold"></span>?</p>
        <p class="text-danger">Tindakan ini tidak dapat dibatalkan.</p>
        <input type="hidden" id="deleteUserId">
      </div>
      <div class="modal-footer">
        <button class="cancel-btn" onclick="closeDeleteModal()">Batal</button>
        <button class="delete-btn" onclick="deleteUser()">Hapus</button>
      </div>
    </div>
  </div>

  <script>
    // Open edit modal and populate with user data
    function openEditModal(id, name, email) {
      document.getElementById('userId').value = id;
      document.getElementById('editName').value = name;
      document.getElementById('editEmail').value = email;
      document.getElementById('editPassword').value = '';
      
      document.getElementById('editModal').classList.add('active');
    }
    
    // Close the edit modal
    function closeEditModal() {
      document.getElementById('editModal').classList.remove('active');
    }
    
    // Submit form using AJAX
    function saveChanges() {
      const userId = document.getElementById('userId').value;
      const editName = document.getElementById('editName').value;
      const editEmail = document.getElementById('editEmail').value;
      const editPassword = document.getElementById('editPassword').value;
      
      // Create AJAX request
      const xhr = new XMLHttpRequest();
      xhr.open('POST', 'updateUser.jsp', true);
      xhr.setRequestHeader('Content-Type', 'application/x-www-form-urlencoded');
      
      // Prepare data
      const data = 'userId=' + encodeURIComponent(userId) + 
                  '&editName=' + encodeURIComponent(editName) + 
                  '&editEmail=' + encodeURIComponent(editEmail) + 
                  '&editPassword=' + encodeURIComponent(editPassword);
      
      xhr.onload = function() {
        if (xhr.status === 200) {
          console.log("Response text:", xhr.responseText);  // Debug log
          
          try {
            const response = JSON.parse(xhr.responseText);
            
            // Display message
            const messageDiv = document.getElementById('message');
            messageDiv.innerHTML = response.message;
            messageDiv.className = 'message ' + (response.success ? 'success-message' : 'error-message');
            messageDiv.style.display = 'block';
            
            // Hide message after 3 seconds
            setTimeout(function() {
              messageDiv.style.display = 'none';
            }, 3000);
            
            // If successful, close modal and refresh page
            if (response.success) {
              closeEditModal();
              setTimeout(function() {
                location.reload();
              }, 3000);
            }
          } catch (e) {
            console.error('Error parsing response:', e);
            console.error('Response was:', xhr.responseText);
            
            // Still show error message
            const messageDiv = document.getElementById('message');
            messageDiv.innerHTML = "Terjadi kesalahan saat memproses respons dari server";
            messageDiv.className = 'message error-message';
            messageDiv.style.display = 'block';
          }
        }
      };
      
      xhr.send(data);
    }
    
    // Search functionality
    function searchTable() {
      const input = document.getElementById('searchInput');
      const filter = input.value.toUpperCase();
      const table = document.getElementById('dataTable');
      const rows = table.getElementsByTagName('tr');
      
      for (let i = 1; i < rows.length; i++) {
        let found = false;
        const cells = rows[i].getElementsByTagName('td');
        
        for (let j = 1; j < cells.length - 1; j++) { // Skip the counter column and actions column
          const cellText = cells[j].textContent || cells[j].innerText;
          
          if (cellText.toUpperCase().indexOf(filter) > -1) {
            found = true;
            break;
          }
        }
        
        rows[i].style.display = found ? '' : 'none';
      }
    }
    
    // Close modal when clicking outside
    window.onclick = function(event) {
      const editModal = document.getElementById('editModal');
      const deleteModal = document.getElementById('deleteModal');
      if (event.target === editModal) {
        closeEditModal();
      }
      if (event.target === deleteModal) {
        closeDeleteModal();
      }
    };
    
    // Open delete confirmation modal
    function confirmDelete(id, name) {
      document.getElementById('deleteUserId').value = id;
      document.getElementById('deleteUserName').textContent = name;
      document.getElementById('deleteModal').classList.add('active');
    }
    
    // Close delete modal
    function closeDeleteModal() {
      document.getElementById('deleteModal').classList.remove('active');
    }
    
    // Delete user
    function deleteUser() {
      const userId = document.getElementById('deleteUserId').value;
      
      // Create AJAX request
      const xhr = new XMLHttpRequest();
      xhr.open('POST', 'deleteUser.jsp', true);
      xhr.setRequestHeader('Content-Type', 'application/x-www-form-urlencoded');
      
      // Prepare data
      const data = 'userId=' + encodeURIComponent(userId);
      
      xhr.onload = function() {
        if (xhr.status === 200) {
          console.log("Delete response:", xhr.responseText);  // Debug log
          
          try {
            const response = JSON.parse(xhr.responseText);
            
            // Display message
            const messageDiv = document.getElementById('message');
            messageDiv.innerHTML = response.message;
            messageDiv.className = 'message ' + (response.success ? 'success-message' : 'error-message');
            messageDiv.style.display = 'block';
            
            // Hide message after 3 seconds
            setTimeout(function() {
              messageDiv.style.display = 'none';
            }, 3000);
            
            // If successful, close modal and refresh page
            if (response.success) {
              closeDeleteModal();
              setTimeout(function() {
                location.reload();
              }, 1000);
            }
          } catch (e) {
            console.error('Error parsing response:', e);
            console.error('Response was:', xhr.responseText);
            
            // Still show error message
            const messageDiv = document.getElementById('message');
            messageDiv.innerHTML = "Terjadi kesalahan saat memproses respons dari server";
            messageDiv.className = 'message error-message';
            messageDiv.style.display = 'block';
          }
        }
      };
      
      xhr.send(data);
    }
    
    // Function to navigate to Master Barang page
    function goToMasterBarang() {
      window.location.href = "MasterBarang.jsp";
    }
  </script>
</body>
</html>