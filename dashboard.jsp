<%-- dashboard.jsp --%>
<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="java.sql.*" %>
<%@ page import="java.text.SimpleDateFormat" %>
<%@ page import="java.util.*" %>
<%@ page import="java.util.Date, java.text.SimpleDateFormat, java.util.Locale" %>

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
    
    // Statistics variables
    int totalUsers = 0;
    int totalTransaksi = 0;
    int totalBarang = 0;
    int stokRendah = 0;
    double totalPendapatan = 0.0;
    int transaksiHariIni = 0;
    int userBaruBulanIni = 0;
    
    // Lists for recent activities
    List<String> recentTransactions = new ArrayList<>();
    List<String> lowStockItems = new ArrayList<>();
    List<String> recentNotifications = new ArrayList<>();
%>
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>Admin Dashboard</title>
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
      position: fixed;
      height: 100vh;
      overflow-y: auto;
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
      margin-left: 250px;
      padding: 20px;
      background-color: #f8f9fa;
    }

    .header {
      display: flex;
      justify-content: space-between;
      align-items: center;
      margin-bottom: 30px;
      background: white;
      padding: 20px;
      border-radius: 10px;
      box-shadow: 0 2px 10px rgba(0, 0, 0, 0.1);
    }

    .welcome-text {
      font-size: 28px;
      color: #333;
      font-weight: 600;
    }

    .logout-btn {
      background-color: #dc3545;
      color: white;
      border: none;
      border-radius: 8px;
      padding: 10px 20px;
      cursor: pointer;
      transition: background-color 0.3s;
      font-size: 14px;
    }

    .logout-btn:hover {
      background-color: #c82333;
    }

    /* Stats Cards */
    .stats-grid {
      display: grid;
      grid-template-columns: repeat(auto-fit, minmax(250px, 1fr));
      gap: 20px;
      margin-bottom: 30px;
    }

    .stat-card {
      background: white;
      border-radius: 10px;
      padding: 25px;
      box-shadow: 0 2px 10px rgba(0, 0, 0, 0.1);
      transition: transform 0.3s ease;
      position: relative;
      overflow: hidden;
    }

    .stat-card:hover {
      transform: translateY(-5px);
    }

    .stat-card::before {
      content: '';
      position: absolute;
      top: 0;
      left: 0;
      width: 4px;
      height: 100%;
      background: var(--primary-color);
    }

    .stat-card.users::before { background: #007bff; }
    .stat-card.revenue::before { background: #28a745; }
    .stat-card.products::before { background: #ffc107; }
    .stat-card.transactions::before { background: #17a2b8; }
    .stat-card.low-stock::before { background: #dc3545; }
    .stat-card.today::before { background: #6f42c1; }

    .stat-icon {
      position: absolute;
      top: 20px;
      right: 20px;
      font-size: 2.5rem;
      opacity: 0.2;
    }

    .stat-number {
      font-size: 2.5rem;
      font-weight: bold;
      margin-bottom: 10px;
      color: #333;
    }

    .stat-label {
      color: #666;
      font-size: 14px;
      font-weight: 500;
    }

    .stat-change {
      font-size: 12px;
      margin-top: 5px;
    }

    .stat-change.positive {
      color: #28a745;
    }

    .stat-change.negative {
      color: #dc3545;
    }

    /* Content Cards */
    .content-grid {
      display: grid;
      grid-template-columns: 2fr 1fr;
      gap: 20px;
      margin-bottom: 20px;
    }

    .content-card {
      background-color: white;
      border-radius: 10px;
      box-shadow: 0 2px 10px rgba(0, 0, 0, 0.1);
      padding: 25px;
    }

    .card-title {
      color: var(--primary-color);
      margin-bottom: 20px;
      font-size: 20px;
      font-weight: 600;
      display: flex;
      align-items: center;
      gap: 10px;
    }

    .card-text {
      color: #555;
      line-height: 1.6;
    }

    /* Recent Activities */
    .activity-item {
      padding: 15px;
      border-left: 3px solid #e9ecef;
      margin-bottom: 15px;
      background: #f8f9fa;
      border-radius: 0 8px 8px 0;
      transition: all 0.3s ease;
    }

    .activity-item:hover {
      border-left-color: var(--primary-color);
      background: #f1f3f4;
    }

    .activity-time {
      font-size: 12px;
      color: #6c757d;
      margin-bottom: 5px;
    }

    .activity-desc {
      font-size: 14px;
      color: #333;
    }

    /* Low Stock Items */
    .stock-item {
      display: flex;
      justify-content: space-between;
      align-items: center;
      padding: 12px 0;
      border-bottom: 1px solid #e9ecef;
    }

    .stock-item:last-child {
      border-bottom: none;
    }

    .stock-name {
      font-weight: 500;
      color: #333;
    }

    .stock-count {
      background: #dc3545;
      color: white;
      padding: 4px 8px;
      border-radius: 12px;
      font-size: 12px;
      font-weight: 500;
    }

    /* Notifications */
    .notification-item {
      display: flex;
      align-items: start;
      gap: 15px;
      padding: 15px;
      background: #f8f9fa;
      border-radius: 8px;
      margin-bottom: 10px;
      transition: all 0.3s ease;
    }

    .notification-item:hover {
      background: #e9ecef;
    }

    .notification-icon {
      width: 40px;
      height: 40px;
      border-radius: 50%;
      display: flex;
      align-items: center;
      justify-content: center;
      font-size: 16px;
      color: white;
    }

    .notification-icon.user { background: #007bff; }
    .notification-icon.product { background: #28a745; }
    .notification-icon.cancel { background: #dc3545; }

    .notification-content {
      flex: 1;
    }

    .notification-title {
      font-weight: 500;
      color: #333;
      margin-bottom: 5px;
    }

    .notification-time {
      font-size: 12px;
      color: #6c757d;
    }

    .user-name {
      color: var(--primary-color);
      font-weight: 600;
    }

    /* Responsive */
    @media (max-width: 768px) {
      .sidebar {
        transform: translateX(-100%);
        z-index: 1000;
      }
      
      .main-content {
        margin-left: 0;
      }
      
      .content-grid {
        grid-template-columns: 1fr;
      }
      
      .stats-grid {
        grid-template-columns: 1fr;
      }
    }

    /* Loading Animation */
    .loading {
      display: inline-block;
      width: 20px;
      height: 20px;
      border: 3px solid rgba(255,255,255,.3);
      border-radius: 50%;
      border-top-color: #fff;
      animation: spin 1s ease-in-out infinite;
    }

    @keyframes spin {
      to { transform: rotate(360deg); }
    }

    /* Quick Actions */
    .quick-actions {
      display: flex;
      gap: 15px;
      margin-bottom: 30px;
      flex-wrap: wrap;
    }

    .quick-action-btn {
      background: var(--primary-color);
      color: white;
      padding: 12px 20px;
      border: none;
      border-radius: 8px;
      text-decoration: none;
      font-size: 14px;
      font-weight: 500;
      transition: all 0.3s ease;
      display: flex;
      align-items: center;
      gap: 8px;
    }

    .quick-action-btn:hover {
      background: var(--hover-color);
      color: white;
      text-decoration: none;
      transform: translateY(-2px);
    }
  </style>
</head>
<body>
  <%
  try {
      Class.forName("com.mysql.cj.jdbc.Driver");
      conn = DriverManager.getConnection(url, user, dbpass);
      
      // Get total users
      String userSql = "SELECT COUNT(*) as total FROM user";
      pstmt = conn.prepareStatement(userSql);
      rs = pstmt.executeQuery();
      if (rs.next()) {
          totalUsers = rs.getInt("total");
      }
      rs.close();
      pstmt.close();
      
      // Get total transactions and revenue
      String transaksiSql = "SELECT COUNT(*) as total, COALESCE(SUM(total_harga), 0) as revenue FROM transaksi";
      pstmt = conn.prepareStatement(transaksiSql);
      rs = pstmt.executeQuery();
      if (rs.next()) {
          totalTransaksi = rs.getInt("total");
          totalPendapatan = rs.getDouble("revenue");
      }
      rs.close();
      pstmt.close();
      
      // Get total products
      String barangSql = "SELECT COUNT(*) as total FROM barang";
      pstmt = conn.prepareStatement(barangSql);
      rs = pstmt.executeQuery();
      if (rs.next()) {
          totalBarang = rs.getInt("total");
      }
      rs.close();
      pstmt.close();
      
      // Get low stock items (stock < 10)
      String lowStockSql = "SELECT COUNT(*) as low_stock FROM barang WHERE stok < 10";
      pstmt = conn.prepareStatement(lowStockSql);
      rs = pstmt.executeQuery();
      if (rs.next()) {
          stokRendah = rs.getInt("low_stock");
      }
      rs.close();
      pstmt.close();
      
      // Get today's transactions
      String todaySql = "SELECT COUNT(*) as today FROM transaksi WHERE DATE(tanggal_transaksi) = CURDATE()";
      pstmt = conn.prepareStatement(todaySql);
      rs = pstmt.executeQuery();
      if (rs.next()) {
          transaksiHariIni = rs.getInt("today");
      }
      rs.close();
      pstmt.close();
      
      // Get new users this month
      String newUserSql = "SELECT COUNT(*) as new_users FROM user WHERE MONTH(created_at) = MONTH(CURDATE()) AND YEAR(created_at) = YEAR(CURDATE())";
      pstmt = conn.prepareStatement(newUserSql);
      rs = pstmt.executeQuery();
      if (rs.next()) {
          userBaruBulanIni = rs.getInt("new_users");
      }
      rs.close();
      pstmt.close();
      
      // Get recent transactions (last 5)
      String recentTransSql = "SELECT t.id, u.username, t.total_harga, t.tanggal_transaksi, t.status_pesanan FROM transaksi t JOIN user u ON t.user_id = u.id ORDER BY t.tanggal_transaksi DESC LIMIT 5";
      pstmt = conn.prepareStatement(recentTransSql);
      rs = pstmt.executeQuery();
      while (rs.next()) {
          String transInfo = "Order #" + rs.getInt("id") + " - " + rs.getString("username") + 
                           " - Rp " + String.format("%,.0f", rs.getDouble("total_harga")) + 
                           " - " + rs.getString("status_pesanan");
          recentTransactions.add(transInfo);
      }
      rs.close();
      pstmt.close();
      
      // Get low stock items details (limit 5)
      String lowStockDetailSql = "SELECT nama_barang, stok FROM barang WHERE stok < 10 ORDER BY stok ASC LIMIT 5";
      pstmt = conn.prepareStatement(lowStockDetailSql);
      rs = pstmt.executeQuery();
      while (rs.next()) {
          String stockInfo = rs.getString("nama_barang") + "|" + rs.getInt("stok");
          lowStockItems.add(stockInfo);
      }
      rs.close();
      pstmt.close();
      
      // Generate recent notifications (mock data based on real data)
      if (userBaruBulanIni > 0) {
          recentNotifications.add("user|" + userBaruBulanIni + " pengguna baru mendaftar bulan ini|2 jam yang lalu");
      }
      if (stokRendah > 0) {
          recentNotifications.add("product|" + stokRendah + " barang memiliki stok rendah|1 jam yang lalu");
      }
      
      // Check for cancelled orders today
      String cancelledSql = "SELECT COUNT(*) as cancelled FROM transaksi WHERE DATE(tanggal_transaksi) = CURDATE() AND status_pesanan = 'cancelled'";
      pstmt = conn.prepareStatement(cancelledSql);
      rs = pstmt.executeQuery();
      if (rs.next() && rs.getInt("cancelled") > 0) {
          recentNotifications.add("cancel|" + rs.getInt("cancelled") + " pesanan dibatalkan hari ini|30 menit yang lalu");
      }
      rs.close();
      pstmt.close();
      
  } catch(Exception e) {
      out.println("<!-- Error loading data: " + e.getMessage() + " -->");
  } finally {
      if (rs != null) try { rs.close(); } catch (SQLException e) { e.printStackTrace(); }
      if (pstmt != null) try { pstmt.close(); } catch (SQLException e) { e.printStackTrace(); }
      if (conn != null) try { conn.close(); } catch (SQLException e) { e.printStackTrace(); }
  }
  %>

  <!-- Sidebar -->
  <div class="sidebar">
    <div class="sidebar-header">
      Dashboard
    </div>
    <div class="sidebar-menu">
      <a href="dashboard.jsp" class="active">
        <i class="fas fa-home"></i> Home
      </a>
      <a href="data-register.jsp">
        <i class="fas fa-users"></i> Data Register
      </a>
      <a href="MasterBarang.jsp">
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
        <i class="fas fa-chart-pie"></i> 
        Dashboard Admin - <span class="user-name"><%= username %></span>
      </h1>
      <form action="logout.jsp" method="post" style="margin: 0;">
        <button type="submit" class="logout-btn">
          <i class="fas fa-sign-out-alt"></i> Logout
        </button>
      </form>
    </div>

    <!-- Quick Actions -->
    <div class="quick-actions">
      <a href="MasterBarang.jsp" class="quick-action-btn">
        <i class="fas fa-plus"></i> Tambah Barang
      </a>
      <a href="data-register.jsp" class="quick-action-btn">
        <i class="fas fa-users"></i> Kelola User
      </a>
      <a href="transaksi.jsp" class="quick-action-btn">
        <i class="fas fa-eye"></i> Lihat Transaksi
      </a>
    </div>

    <!-- Statistics Cards -->
    <div class="stats-grid" id="statsGrid">
      <div class="stat-card users">
        <i class="fas fa-users stat-icon"></i>
        <div class="stat-number" data-target="<%= totalUsers %>">0</div>
        <div class="stat-label">Total Pengguna</div>
        <div class="stat-change positive">
          <i class="fas fa-arrow-up"></i> +<%= userBaruBulanIni %> bulan ini
        </div>
      </div>

      <div class="stat-card revenue">
        <i class="fas fa-money-bill-wave stat-icon"></i>
        <div class="stat-number">Rp <span data-target="<%= (int)totalPendapatan %>">0</span></div>
        <div class="stat-label">Total Pendapatan</div>
        <div class="stat-change positive">
          <i class="fas fa-arrow-up"></i> All time
        </div>
      </div>

      <div class="stat-card products">
        <i class="fas fa-boxes stat-icon"></i>
        <div class="stat-number" data-target="<%= totalBarang %>">0</div>
        <div class="stat-label">Total Produk</div>
        <div class="stat-change <%= stokRendah > 0 ? "negative" : "positive" %>">
          <i class="fas fa-<%= stokRendah > 0 ? "exclamation-triangle" : "check" %>"></i> 
          <%= stokRendah > 0 ? stokRendah + " stok rendah" : "Stok aman" %>
        </div>
      </div>

      <div class="stat-card transactions">
        <i class="fas fa-shopping-cart stat-icon"></i>
        <div class="stat-number" data-target="<%= totalTransaksi %>">0</div>
        <div class="stat-label">Total Transaksi</div>
        <div class="stat-change positive">
          <i class="fas fa-arrow-up"></i> All time
        </div>
      </div>

      <div class="stat-card today">
        <i class="fas fa-calendar-day stat-icon"></i>
        <div class="stat-number" data-target="<%= transaksiHariIni %>">0</div>
        <div class="stat-label">Transaksi Hari Ini</div>
        <div class="stat-change positive">
          <i class="fas fa-clock"></i> Real time
        </div>
      </div>

      <div class="stat-card low-stock">
        <i class="fas fa-exclamation-triangle stat-icon"></i>
        <div class="stat-number" data-target="<%= stokRendah %>">0</div>
        <div class="stat-label">Stok Rendah</div>
        <div class="stat-change <%= stokRendah > 0 ? "negative" : "positive" %>">
          <i class="fas fa-<%= stokRendah > 0 ? "warning" : "check" %>"></i> 
          <%= stokRendah > 0 ? "Perlu restock" : "Semua aman" %>
        </div>
      </div>
    </div>

    <!-- Content Grid -->
    <div class="content-grid">
      <!-- Recent Transactions -->
      <div class="content-card">
        <h2 class="card-title">
          <i class="fas fa-history"></i> Transaksi Terbaru
        </h2>
        <div id="recentTransactions">
          <% if (recentTransactions.isEmpty()) { %>
            <p class="card-text">Belum ada transaksi.</p>
          <% } else { %>
            <% for (String transaction : recentTransactions) { %>
              <div class="activity-item">
                <div class="activity-time">
                  <%= new SimpleDateFormat("dd MMM yyyy HH:mm", new Locale("id", "ID")).format(new Date()) %>
                </div>
                <div class="activity-desc"><%= transaction %></div>
              </div>
            <% } %>
          <% } %>
        </div>
      </div>

      <!-- Notifications -->
      <div class="content-card">
        <h2 class="card-title">
          <i class="fas fa-bell"></i> Notifikasi Terbaru
        </h2>
        <div id="notifications">
          <% if (recentNotifications.isEmpty()) { %>
            <p class="card-text">Tidak ada notifikasi baru.</p>
          <% } else { %>
            <% for (String notification : recentNotifications) { %>
              <% String[] parts = notification.split("\\|"); %>
              <div class="notification-item">
                <div class="notification-icon <%= parts[0] %>">
                  <i class="fas fa-<%= parts[0].equals("user") ? "user-plus" : parts[0].equals("product") ? "box" : "times" %>"></i>
                </div>
                <div class="notification-content">
                  <div class="notification-title"><%= parts[1] %></div>
                  <div class="notification-time"><%= parts[2] %></div>
                </div>
              </div>
            <% } %>
          <% } %>
        </div>
      </div>
    </div>

    <!-- Low Stock Items -->
    <% if (!lowStockItems.isEmpty()) { %>
    <div class="content-card">
      <h2 class="card-title">
        <i class="fas fa-exclamation-triangle"></i> Barang Stok Rendah
      </h2>
      <div>
        <% for (String stockItem : lowStockItems) { %>
          <% String[] parts = stockItem.split("\\|"); %>
          <div class="stock-item">
            <span class="stock-name"><%= parts[0] %></span>
            <span class="stock-count"><%= parts[1] %> tersisa</span>
          </div>
        <% } %>
      </div>
    </div>
    <% } %>
  </div>
  
  <script>
    // Animate numbers on page load
    document.addEventListener('DOMContentLoaded', function() {
      const numberElements = document.querySelectorAll('[data-target]');
      
      numberElements.forEach(element => {
        const target = parseInt(element.getAttribute('data-target'));
        if (target > 0) {
          let current = 0;
          const increment = Math.ceil(target / 50);
          const timer = setInterval(() => {
            current += increment;
            if (current >= target) {
              current = target;
              clearInterval(timer);
            }
            element.textContent = current.toLocaleString('id-ID');
          }, 20);
        }
      });
      
      // Add hover effects to cards
      const cards = document.querySelectorAll('.stat-card, .content-card');
      cards.forEach(card => {
        card.addEventListener('mouseenter', function() {
          this.style.transform = 'translateY(-5px)';
        });
        
        card.addEventListener('mouseleave', function() {
          this.style.transform = 'translateY(0)';
        });
      });
    });

    // Auto refresh data every 5 minutes
    function refreshDashboard() {
      console.log('Dashboard refreshed at:', new Date().toLocaleTimeString('id-ID'));
      // You can add AJAX calls here to refresh specific sections
    }

    // Set interval for auto refresh (5 minutes)
    setInterval(refreshDashboard, 300000);

    // Show current time
    function updateTime() {
      const now = new Date();
      const timeString = now.toLocaleTimeString('id-ID', {
        hour: '2-digit',
        minute: '2-digit',
        second: '2-digit'
      });
      
      // Update any time displays if needed
      const timeElements = document.querySelectorAll('.current-time');
      timeElements.forEach(el => el.textContent = timeString);
    }

    // Update time every second
    setInterval(updateTime, 1000);
    updateTime(); // Initial call

    // Mobile sidebar toggle (if needed)
    function toggleSidebar() {
      const sidebar = document.querySelector('.sidebar');
      sidebar.style.transform = sidebar.style.transform === 'translateX(0px)' ? 
        'translateX(-100%)' : 'translateX(0px)';
    }

    // Add click listeners for interactive elements
    document.addEventListener('click', function(e) {
      // Handle notification clicks
      if (e.target.closest('.notification-item')) {
        const notification = e.target.closest('.notification-item');
        notification.style.opacity = '0.7';
        setTimeout(() => {
          notification.style.opacity = '1';
        }, 200);
      }
      
      // Handle stat card clicks
      if (e.target.closest('.stat-card')) {
        const card = e.target.closest('.stat-card');
        card.style.transform = 'scale(0.98)';
        setTimeout(() => {
          card.style.transform = 'translateY(-5px)';
        }, 100);
      }
    });
  </script>
</body>
</html>