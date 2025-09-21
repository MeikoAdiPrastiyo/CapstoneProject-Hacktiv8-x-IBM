<%-- google-login-handler.jsp --%>
<%@ page import="java.sql.*" %>
<%@ page contentType="text/html; charset=UTF-8" %>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Processing Google Login</title>
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
    // Get Google login parameters
    String googleUid = request.getParameter("google_uid");
    String googleName = request.getParameter("google_name");
    String googleEmail = request.getParameter("google_email");
    String googlePhoto = request.getParameter("google_photo");
    String loginType = request.getParameter("login_type");
    
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
        Class.forName("com.mysql.cj.jdbc.Driver");
        conn = DriverManager.getConnection(url, user, dbpass);
        
        // Validate Google login parameters
        if (googleUid == null || googleName == null || googleEmail == null || googleUid.isEmpty() || googleName.isEmpty() || googleEmail.isEmpty()) {
            iconClass = "fas fa-exclamation-triangle popup-error";
            title = "Google Login Failed";
            message = "Invalid Google login data received. Please try again.";
            redirectUrl = "login.html?error=google_login_failed";
            isSuccess = false;
        } else if ("google".equals(loginType)) {
            // Check if user already exists in database
            String checkSql = "SELECT * FROM `user` WHERE email = ? OR google_uid = ?";
            pstmt = conn.prepareStatement(checkSql);
            pstmt.setString(1, googleEmail);
            pstmt.setString(2, googleUid);
            rs = pstmt.executeQuery();
            
            if (rs.next()) {
                // User exists, update their Google information and get their role
                String userRole = rs.getString("role");
                rs.close();
                pstmt.close();
                
                String updateSql = "UPDATE `user` SET google_uid = ?, nama = ?, google_photo = ?, login_type = 'google', last_login = NOW() WHERE email = ?";
                pstmt = conn.prepareStatement(updateSql);
                pstmt.setString(1, googleUid);
                pstmt.setString(2, googleName);
                pstmt.setString(3, googlePhoto);
                pstmt.setString(4, googleEmail);
                pstmt.executeUpdate();
                
                // Set session attributes
                session.setAttribute("username", googleName);
                session.setAttribute("email", googleEmail);
                session.setAttribute("google_uid", googleUid);
                session.setAttribute("google_photo", googlePhoto);
                session.setAttribute("login_type", "google");
                session.setAttribute("role", userRole);
                
                iconClass = "fas fa-check-circle popup-success";
                title = "Welcome Back!";
                message = "Hi <strong style=\"color: #000; font-weight: 700;\">" + googleName + "</strong>! You have successfully signed in with Google.";
                
                // Redirect based on role
                if ("admin".equals(userRole)) {
                    redirectUrl = "dashboard.jsp";
                } else {
                    redirectUrl = "dashboarduser.jsp";
                }
                
                isSuccess = true;
                
            } else {
                // New user, create account with login_type = 'google' and default role = 'user'
                rs.close();
                pstmt.close();
                
                String insertSql = "INSERT INTO `user` (nama, email, google_uid, google_photo, login_type, role, created_at, last_login) VALUES (?, ?, ?, ?, 'google', 'user', NOW(), NOW())";
                pstmt = conn.prepareStatement(insertSql);
                pstmt.setString(1, googleName);
                pstmt.setString(2, googleEmail);
                pstmt.setString(3, googleUid);
                pstmt.setString(4, googlePhoto);
                pstmt.executeUpdate();
                
                // Set session attributes
                session.setAttribute("username", googleName);
                session.setAttribute("email", googleEmail);
                session.setAttribute("google_uid", googleUid);
                session.setAttribute("google_photo", googlePhoto);
                session.setAttribute("login_type", "google");
                session.setAttribute("role", "user"); // New users get 'user' role by default
                
                iconClass = "fas fa-user-check popup-success";
                title = "Account Created!";
                message = "Welcome <strong style=\"color: #000; font-weight: 700;\">" + googleName + "</strong>! Your account has been created and you are now signed in.";
                redirectUrl = "dashboarduser.jsp"; // New users go to user dashboard
                isSuccess = true;
            }
            
        } else {
            // Invalid Google login data
            iconClass = "fas fa-exclamation-triangle popup-error";
            title = "Google Login Failed";
            message = "Invalid Google login data received. Please try again.";
            redirectUrl = "login.html?error=google_login_failed";
            isSuccess = false;
        }
        
    } catch (SQLException e) {
        iconClass = "fas fa-exclamation-triangle popup-error";
        title = "Database Error";
        message = "An error occurred while connecting to the database. Please try again later.";
        redirectUrl = "login.html?error=google_login_failed";
        isSuccess = false;
        e.printStackTrace();
    } catch (Exception e) {
        iconClass = "fas fa-exclamation-triangle popup-error";
        title = "System Error";
        message = "An unexpected error occurred: " + e.getMessage();
        redirectUrl = "login.html?error=google_login_failed";
        isSuccess = false;
        e.printStackTrace();
    } finally {
        if (rs != null) try { rs.close(); } catch (SQLException e) { e.printStackTrace(); }
        if (pstmt != null) try { pstmt.close(); } catch (SQLException e) { e.printStackTrace(); }
        if (conn != null) try { conn.close(); } catch (SQLException e) { e.printStackTrace(); }
    }
%>

<div class="popup-container">
    <i class="<%= iconClass %> popup-icon"></i>
    <h2 class="popup-title"><%= title %></h2>
    <p class="popup-message"><%= message %></p>
    <button class="popup-button" onclick="window.location.href='<%= redirectUrl %>'">
        <%= isSuccess ? "Continue to Dashboard" : "Try Again" %>
    </button>
</div>

</body>
</html>