<%-- koneksidb.jsp --%>
<%@ page import="java.sql.*" %>
<%@ page import="java.util.*" %>
<%@ page contentType="text/html; charset=UTF-8" %>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Processing</title>
    <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.5.0/css/all.min.css"/>
    <style>
        :root {
            --primary-color: #2f6c3b;
            --hover-color: #255b30;
            --transition: all 0.3s ease;
        }
        
        body {
            margin: 0;
            padding: 0;
            font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
            background-color: rgba(0, 0, 0, 0.3);
            display: flex;
            justify-content: center;
            align-items: center;
            height: 100vh;
        }
        
        .popup-container {
            background: white;
            border-radius: 10px;
            padding: 30px;
            box-shadow: 0 5px 20px rgba(0, 0, 0, 0.2);
            text-align: center;
            max-width: 400px;
            width: 90%;
            position: relative;
            animation: fadeIn 0.3s;
        }
        
        @keyframes fadeIn {
            from {
                opacity: 0;
                transform: translateY(-20px);
            }
            to {
                opacity: 1;
                transform: translateY(0);
            }
        }
        
        .popup-icon {
            font-size: 50px;
            margin-bottom: 20px;
        }
        
        .popup-success {
            color: #28a745;
        }
        
        .popup-error {
            color: #dc3545;
        }
        
        .popup-title {
            font-size: 24px;
            margin-bottom: 15px;
            color: #333;
        }
        
        .popup-message {
            color: #666;
            margin-bottom: 20px;
            line-height: 1.5;
        }
        
        .popup-button {
            background-color: var(--primary-color);
            color: white;
            border: none;
            border-radius: 6px;
            padding: 10px 20px;
            font-size: 16px;
            cursor: pointer;
            transition: var(--transition);
        }
        
        .popup-button:hover {
            background-color: var(--hover-color);
        }
    </style>
</head>
<body>
<%
    // Get all possible parameters
    String nama = request.getParameter("nama");
    String email = request.getParameter("email");
    String passInput = request.getParameter("password");
    String userInput = request.getParameter("userInput"); // For login (username or email)
    
    String url = "jdbc:mysql://localhost:3306/webcapstone";
    String user = "root";
    String dbpass = ""; // Database password
    Connection conn = null;
    PreparedStatement pstmt = null;
    ResultSet rs = null;
    
    String iconClass = "";
    String title = "";
    String message = "";
    String redirectUrl = "";
    boolean isSuccess = false;
    
    try {
        Class.forName("com.mysql.cj.jdbc.Driver"); // MySQL 8+ driver
        conn = DriverManager.getConnection(url, user, dbpass);
        
        // Check if this is a registration request (has nama parameter)
        if (nama != null) {
            // This is a registration request
            String sql = "INSERT INTO user (nama, email, password, role, login_type, created_at) VALUES (?, ?, ?, 'user', 'regular', CURRENT_TIMESTAMP)";
            pstmt = conn.prepareStatement(sql);
            pstmt.setString(1, nama);
            pstmt.setString(2, email);
            pstmt.setString(3, passInput);
            pstmt.executeUpdate();
            
            iconClass = "fas fa-check-circle popup-success";
            title = "Registration Successful!";
            message = "Your account has been created successfully.";
            redirectUrl = "login.html";
            isSuccess = true;
        } 
        // Check if this is a login request (has userInput parameter)
        else if (userInput != null && passInput != null) {
            // This is a login request - check if the input is an email or username and get role
            String sql = "SELECT id, nama, email, role FROM user WHERE (nama = ? OR email = ?) AND password = ?";
            pstmt = conn.prepareStatement(sql);
            pstmt.setString(1, userInput);
            pstmt.setString(2, userInput);
            pstmt.setString(3, passInput);
            rs = pstmt.executeQuery();
            
            if (rs.next()) {
                // Login successful - Get user data from database
                int userId = rs.getInt("id");
                String userName = rs.getString("nama");
                String userEmail = rs.getString("email");
                String userRole = rs.getString("role");
                
                // ✅ PERBAIKAN: Set session attributes yang konsisten dengan home.jsp
                session.setAttribute("user_id", userId);      // Tambah user_id untuk keranjang
                session.setAttribute("username", userName);    // Konsisten dengan home.jsp
                session.setAttribute("email", userEmail);
                session.setAttribute("role", userRole);
                
                // Update last_login
                String updateLoginSql = "UPDATE user SET last_login = CURRENT_TIMESTAMP WHERE id = ?";
                PreparedStatement updatePstmt = conn.prepareStatement(updateLoginSql);
                updatePstmt.setInt(1, userId);
                updatePstmt.executeUpdate();
                updatePstmt.close();
                
                // ✅ PERBAIKAN: Pindahkan keranjang guest ke database jika ada
                if ("user".equals(userRole)) {
                    Map<Integer, Integer> guestCart = (Map<Integer, Integer>) session.getAttribute("cart");
                    
                    if (guestCart != null && !guestCart.isEmpty()) {
                        // Pindahkan keranjang guest ke database
                        for (Map.Entry<Integer, Integer> entry : guestCart.entrySet()) {
                            int barangId = entry.getKey();
                            int quantity = entry.getValue();
                            
                            // Cek apakah barang sudah ada di keranjang user
                            String checkCartSql = "SELECT quantity FROM keranjang WHERE user_id = ? AND barang_id = ?";
                            PreparedStatement checkPstmt = conn.prepareStatement(checkCartSql);
                            checkPstmt.setInt(1, userId);
                            checkPstmt.setInt(2, barangId);
                            ResultSet checkRs = checkPstmt.executeQuery();
                            
                            if (checkRs.next()) {
                                // Update quantity yang sudah ada
                                int existingQty = checkRs.getInt("quantity");
                                String updateCartSql = "UPDATE keranjang SET quantity = ? WHERE user_id = ? AND barang_id = ?";
                                PreparedStatement updateCartPstmt = conn.prepareStatement(updateCartSql);
                                updateCartPstmt.setInt(1, existingQty + quantity);
                                updateCartPstmt.setInt(2, userId);
                                updateCartPstmt.setInt(3, barangId);
                                updateCartPstmt.executeUpdate();
                                updateCartPstmt.close();
                            } else {
                                // Insert baru
                                String insertCartSql = "INSERT INTO keranjang (user_id, barang_id, quantity) VALUES (?, ?, ?)";
                                PreparedStatement insertCartPstmt = conn.prepareStatement(insertCartSql);
                                insertCartPstmt.setInt(1, userId);
                                insertCartPstmt.setInt(2, barangId);
                                insertCartPstmt.setInt(3, quantity);
                                insertCartPstmt.executeUpdate();
                                insertCartPstmt.close();
                            }
                            
                            checkRs.close();
                            checkPstmt.close();
                        }
                        
                        // Hapus keranjang guest dari session
                        session.removeAttribute("cart");
                        
                        message = "Welcome back, <strong style=\"color: #000; font-weight: 700;\">" + userName + "</strong>! Your guest cart has been transferred.";
                    } else {
                        message = "Welcome back, <strong style=\"color: #000; font-weight: 700;\">" + userName + "</strong>! You are now logged in.";
                    }
                } else {
                    message = "Welcome back, <strong style=\"color: #000; font-weight: 700;\">" + userName + "</strong>! You are now logged in.";
                }
                
                iconClass = "fas fa-check-circle popup-success";
                title = "Login Successful!";
                
                // Redirect based on role
                if ("admin".equals(userRole)) {
                    redirectUrl = "dashboard.jsp";
                } else {
                    redirectUrl = "home.jsp"; // ✅ PERBAIKAN: Redirect ke home.jsp bukan dashboarduser.jsp
                }
                
                isSuccess = true;
            } else {
                // Login failed
                iconClass = "fas fa-times-circle popup-error";
                title = "Login Failed";
                message = "Invalid username/email or password. Please try again.";
                redirectUrl = "login.html";
                isSuccess = false;
            }
        } else {
            // Neither login nor registration parameters provided
            iconClass = "fas fa-exclamation-triangle popup-error";
            title = "Invalid Request";
            message = "The system could not process your request.";
            redirectUrl = "login.html";
            isSuccess = false;
        }
    } catch (Exception e) {
        iconClass = "fas fa-exclamation-triangle popup-error";
        title = "Error";
        message = "An error occurred: " + e.getMessage();
        redirectUrl = "login.html";
        isSuccess = false;
    } finally {
        if (rs != null) try { rs.close(); } catch (SQLException e) { e.printStackTrace(); }
        if (pstmt != null) try { pstmt.close(); } catch (SQLException e) { e.printStackTrace(); }
        if (conn != null) try { conn.close(); } catch (SQLException e) { e.printStackTrace(); }
    }
%>

<div class="popup-container">
    <i class="<%= iconClass %> popup-icon"></i>
    <h2 class="popup-title"><%= title %></h2>
    <p class="popup-message"><%=message %></p>
    <button class="popup-button" onclick="window.location.href='<%= redirectUrl %>'">
        <%= isSuccess ? "Continue" : "Try Again" %>
    </button>
</div>

</body>
</html>