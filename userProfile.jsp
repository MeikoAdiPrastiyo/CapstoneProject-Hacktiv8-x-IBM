<%-- userProfile.jsp - Enhanced Version with Delete Photo Feature --%>
<%@ page import="java.sql.*" %>
<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<!DOCTYPE html>
<html lang="id">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Profil User</title>
    <style>
        * {
            margin: 0;
            padding: 0;
            box-sizing: border-box;
        }
        
        body {
            font-family: Arial, sans-serif;
            background-color: #f5f5f5;
            padding: 20px;
        }
        
        .container {
            max-width: 800px;
            margin: 0 auto;
            background: white;
            border-radius: 10px;
            box-shadow: 0 0 20px rgba(0,0,0,0.1);
            overflow: hidden;
        }
        
        .header {
            background: linear-gradient(135deg, #2f6c3b 0%, #255b30 100%);
            color: white;
            padding: 30px;
            text-align: center;
        }
        
        .profile-photo {
            width: 120px;
            height: 120px;
            border-radius: 50%;
            margin: 0 auto 20px;
            border: 4px solid white;
            object-fit: cover;
            display: block;
            box-shadow: 0 4px 8px rgba(0,0,0,0.2);
        }
        
        .profile-form {
            padding: 40px;
        }
        
        .form-group {
            margin-bottom: 25px;
        }
        
        label {
            display: block;
            margin-bottom: 8px;
            font-weight: bold;
            color: #333;
        }
        
        input[type="text"], 
        input[type="email"], 
        input[type="password"], 
        input[type="tel"], 
        input[type="date"],
        input[type="file"],
        select, 
        textarea {
            width: 100%;
            padding: 12px;
            border: 2px solid #ddd;
            border-radius: 5px;
            font-size: 16px;
            transition: border-color 0.3s;
        }
        
        input:focus, select:focus, textarea:focus {
            outline: none;
            border-color: #667eea;
        }
        
        textarea {
            height: 100px;
            resize: vertical;
        }
        
        .row {
            display: flex;
            gap: 20px;
        }
        
        .col {
            flex: 1;
        }
        
        .btn {
            background: linear-gradient(135deg, #2f6c3b 0%, #255b30 100%);
            color: white;
            padding: 12px 30px;
            border: none;
            border-radius: 5px;
            cursor: pointer;
            font-size: 16px;
            transition: transform 0.2s;
        }
        
        .btn:hover {
            transform: translateY(-2px);
        }
        
        .btn-secondary {
            background: #6c757d;
            margin-right: 10px;
        }
        
        .btn-danger {
            background: #dc3545;
            color: white;
            padding: 8px 15px;
            font-size: 14px;
            margin-left: 10px;
        }
        
        .btn-danger:hover {
            background: #c82333;
        }
        
        .alert {
            padding: 15px;
            margin-bottom: 20px;
            border-radius: 5px;
            display: none;
        }
        
        .alert-success {
            background-color: #d4edda;
            color: #155724;
            border: 1px solid #c3e6cb;
        }
        
        .alert-error {
            background-color: #f8d7da;
            color: #721c24;
            border: 1px solid #f5c6cb;
        }
        
        .password-section {
            border-top: 2px solid #eee;
            padding-top: 30px;
            margin-top: 30px;
        }
        
        .section-title {
            font-size: 18px;
            color: #333;
            margin-bottom: 20px;
            padding-bottom: 10px;
            border-bottom: 2px solid #667eea;
        }
        
        .google-photo-info {
            background-color: #e3f2fd;
            border: 1px solid #2196f3;
            border-radius: 5px;
            padding: 10px;
            margin-top: 10px;
            font-size: 14px;
            color: #1976d2;
        }
        
        .photo-source {
            margin-bottom: 15px;
            padding: 12px;
            background-color: #f8f9fa;
            border-left: 4px solid #667eea;
            border-radius: 0 5px 5px 0;
        }

        .photo-source.google {
            border-left-color: #4285f4;
            background-color: #e8f0fe;
        }

        .photo-source.local {
            border-left-color: #34a853;
            background-color: #e6f4ea;
        }

        .photo-source.default {
            border-left-color: #ea4335;
            background-color: #fce8e6;
        }

        .photo-status {
            display: flex;
            align-items: center;
            justify-content: space-between;
            gap: 8px;
            font-size: 14px;
            font-weight: 500;
        }

        .photo-status-left {
            display: flex;
            align-items: center;
            gap: 8px;
        }

        .status-icon {
            width: 16px;
            height: 16px;
            border-radius: 50%;
        }

        .status-icon.google { background-color: #4285f4; }
        .status-icon.local { background-color: #34a853; }
        .status-icon.default { background-color: #ea4335; }

        .photo-controls {
            display: flex;
            align-items: center;
            gap: 10px;
            margin-top: 10px;
        }

        .password-input-wrapper {
            position: relative;
        }

        .password-toggle {
            position: absolute;
            right: 12px;
            top: 50%;
            transform: translateY(-50%);
            background: none;
            border: none;
            color: #666;
            cursor: pointer;
            font-size: 18px;
            padding: 0;
            line-height: 1;
            z-index: 1;
        }

        .password-toggle:hover {
            color: #667eea;
        }

        .password-input-wrapper input[type="password"],
        .password-input-wrapper input[type="text"] {
            padding-right: 45px;
        }
    </style>
</head>
<body>
    <%
        // Check if user is logged in
        String username = (String) session.getAttribute("username");
        if (username == null) {
            response.sendRedirect("login.html");
            return;
        }
        
        // Get user data from database
        String url = "jdbc:mysql://localhost:3306/webcapstone";
        String dbUser = "root";
        String dbPass = "";
        Connection conn = null;
        PreparedStatement pstmt = null;
        ResultSet rs = null;
        
        // User data variables
        String userId = "";
        String nama = "";
        String email = "";
        String googlePhoto = "";
        String loginType = "";
        String namaLengkap = "";
        String nomorHp = "";
        String alamat = "";
        String kota = "";
        String kodePos = "";
        String tanggalLahir = "";
        String jenisKelamin = "";
        String fotoProfil = "";
        String bio = "";
        
        try {
            Class.forName("com.mysql.cj.jdbc.Driver");
            conn = DriverManager.getConnection(url, dbUser, dbPass);
            
            // Get user basic info including google_photo
            String userSql = "SELECT id, nama, email, google_photo, login_type FROM user WHERE nama = ?";
            pstmt = conn.prepareStatement(userSql);
            pstmt.setString(1, username);
            rs = pstmt.executeQuery();
            
            if (rs.next()) {
                userId = rs.getString("id");
                nama = rs.getString("nama");
                email = rs.getString("email");
                googlePhoto = rs.getString("google_photo") != null ? rs.getString("google_photo") : "";
                loginType = rs.getString("login_type") != null ? rs.getString("login_type") : "regular";
            }
            
            rs.close();
            pstmt.close();
            
            // Get user profile info
            String profileSql = "SELECT * FROM user_profile WHERE user_id = ?";
            pstmt = conn.prepareStatement(profileSql);
            pstmt.setString(1, userId);
            rs = pstmt.executeQuery();
            
            if (rs.next()) {
                namaLengkap = rs.getString("nama_lengkap") != null ? rs.getString("nama_lengkap") : "";
                nomorHp = rs.getString("nomor_hp") != null ? rs.getString("nomor_hp") : "";
                alamat = rs.getString("alamat") != null ? rs.getString("alamat") : "";
                kota = rs.getString("kota") != null ? rs.getString("kota") : "";
                kodePos = rs.getString("kode_pos") != null ? rs.getString("kode_pos") : "";
                tanggalLahir = rs.getString("tanggal_lahir") != null ? rs.getString("tanggal_lahir") : "";
                jenisKelamin = rs.getString("jenis_kelamin") != null ? rs.getString("jenis_kelamin") : "";
                fotoProfil = rs.getString("foto_profil") != null ? rs.getString("foto_profil") : "";
                bio = rs.getString("bio") != null ? rs.getString("bio") : "";
            }
            
        } catch (Exception e) {
            out.println("<script>alert('Error: " + e.getMessage() + "');</script>");
        } finally {
            try {
                if (rs != null) rs.close();
                if (pstmt != null) pstmt.close();
                if (conn != null) conn.close();
            } catch (Exception e) {}
        }
        
        // ENHANCED: Improved photo logic with better status tracking
        String displayPhoto = "";
        String photoSource = "";
        String photoSourceClass = "";
        String photoStatusText = "";
        boolean hasLocalPhoto = fotoProfil != null && !fotoProfil.trim().isEmpty();
        boolean hasGooglePhoto = "google".equals(loginType) && googlePhoto != null && !googlePhoto.trim().isEmpty();
        String fallbackPhoto = "https://via.placeholder.com/120x120/667eea/ffffff?text=" + 
                              (nama.length() > 0 ? nama.substring(0, 1).toUpperCase() : "U");
        
        // Priority 1: Local uploaded photo
        if (hasLocalPhoto) {
            displayPhoto = "uploads/" + fotoProfil;
            photoSource = "Foto profil yang diupload";
            photoSourceClass = "local";
            photoStatusText = "Foto lokal aktif";
        } 
        // Priority 2: Google photo (only if login type is google and photo exists)
        else if (hasGooglePhoto) {
            displayPhoto = googlePhoto;
            photoSource = "Foto dari akun Google";
            photoSourceClass = "google";
            photoStatusText = "Foto Google aktif";
        } 
        // Priority 3: Default placeholder
        else {
            displayPhoto = fallbackPhoto;
            photoSource = "Foto default sistem";
            photoSourceClass = "default";
            photoStatusText = "Tidak ada foto";
        }
    %>
    
    <div class="container">
        <div class="header">
            <img src="<%= displayPhoto %>" 
                 alt="Profile Photo" 
                 class="profile-photo" 
                 id="profilePhotoPreview"
                 onerror="handleImageError(this, '<%= fallbackPhoto %>')">
            <h1>Profil User</h1>
            <p>Kelola informasi profil Anda</p>
        </div>
        
        <div class="profile-form">
            <div class="alert alert-success" id="successAlert"></div>
            <div class="alert alert-error" id="errorAlert"></div>
            
            <form id="profileForm" enctype="multipart/form-data">
                <input type="hidden" name="userId" value="<%= userId %>">
                
                <div class="section-title">Informasi Akun</div>
                
                <div class="row">
                    <div class="col">
                        <div class="form-group">
                            <label for="nama">Username:</label>
                            <input type="text" id="nama" name="nama" value="<%= nama %>" required>
                        </div>
                    </div>
                    <div class="col">
                        <div class="form-group">
                            <label for="email">Email:</label>
                            <input type="email" id="email" name="email" value="<%= email %>" required>
                        </div>
                    </div>
                </div>
                
                <div class="form-group">
                    <label for="fotoProfil">Foto Profil:</label>
                    <div class="photo-source <%= photoSourceClass %>" id="photoSourceInfo">
                        <div class="photo-status">
                            <div class="photo-status-left">
                                <div class="status-icon <%= photoSourceClass %>" id="statusIcon"></div>
                                <span><strong id="statusText"><%= photoStatusText %></strong>: <span id="sourceText"><%= photoSource %></span></span>
                            </div>
                            <% if (hasLocalPhoto) { %>
                                <button type="button" class="btn btn-danger" id="deletePhotoBtn" onclick="deletePhoto()">
                                    🗑️ Hapus Foto
                                </button>
                            <% } %>
                        </div>
                        <% if ("google".equals(loginType)) { %>
                            <% if (hasGooglePhoto) { %>
                                <div class="google-photo-info" style="margin-top: 8px;">
                                    <i>ℹ️ Login dengan Google terdeteksi. Foto Google tersedia.</i>
                                    <br><small><%= hasLocalPhoto ? "Foto yang diupload saat ini menggantikan foto Google. Hapus foto lokal untuk kembali ke foto Google." : "Foto Google sedang digunakan." %></small>
                                </div>
                            <% } else { %>
                                <div class="google-photo-info" style="margin-top: 8px;">
                                    <i>⚠️ Login dengan Google terdeteksi tetapi tidak ada foto Google.</i>
                                    <br><small>Silakan upload foto profil atau periksa pengaturan foto di akun Google Anda.</small>
                                </div>
                            <% } %>
                        <% } %>
                    </div>
                    <input type="file" id="fotoProfil" name="fotoProfil" accept="image/*">
                </div>
                
                <div class="section-title">Informasi Pribadi</div>
                
                <div class="form-group">
                    <label for="namaLengkap">Nama Lengkap:</label>
                    <input type="text" id="namaLengkap" name="namaLengkap" value="<%= namaLengkap %>">
                </div>
                
                <div class="row">
                    <div class="col">
                        <div class="form-group">
                            <label for="nomorHp">No. HP:</label>
                            <input type="tel" id="nomorHp" name="nomorHp" value="<%= nomorHp %>">
                        </div>
                    </div>
                    <div class="col">
                        <div class="form-group">
                            <label for="tanggalLahir">Tanggal Lahir:</label>
                            <input type="date" id="tanggalLahir" name="tanggalLahir" value="<%= tanggalLahir %>">
                        </div>
                    </div>
                </div>
                
                <div class="form-group">
                    <label for="jenisKelamin">Jenis Kelamin:</label>
                    <select id="jenisKelamin" name="jenisKelamin">
                        <option value="">Pilih Jenis Kelamin</option>
                        <option value="L" <%= "L".equals(jenisKelamin) ? "selected" : "" %>>Laki-laki</option>
                        <option value="P" <%= "P".equals(jenisKelamin) ? "selected" : "" %>>Perempuan</option>
                    </select>
                </div>
                
                <div class="form-group">
                    <label for="alamat">Alamat:</label>
                    <textarea id="alamat" name="alamat"><%= alamat %></textarea>
                </div>
                
                <div class="row">
                    <div class="col">
                        <div class="form-group">
                            <label for="kota">Kota:</label>
                            <input type="text" id="kota" name="kota" value="<%= kota %>">
                        </div>
                    </div>
                    <div class="col">
                        <div class="form-group">
                            <label for="kodePos">Kode Pos:</label>
                            <input type="text" id="kodePos" name="kodePos" value="<%= kodePos %>">
                        </div>
                    </div>
                </div>
                
                <div class="form-group">
                    <label for="bio">Bio:</label>
                    <textarea id="bio" name="bio"><%= bio %></textarea>
                </div>
                
                <% if (!"google".equals(loginType)) { %>
                <div class="password-section">
                    <div class="section-title">Ubah Password</div>
                    
                    <div class="form-group">
                        <label for="currentPassword">Password Saat Ini:</label>
                        <div class="password-input-wrapper">
                            <input type="password" id="currentPassword" name="currentPassword">
                            <button type="button" class="password-toggle" onclick="togglePassword('currentPassword')">👁️</button>
                        </div>
                    </div>
                    
                    <div class="row">
                        <div class="col">
                            <div class="form-group">
                                <label for="newPassword">Password Baru:</label>
                                <div class="password-input-wrapper">
                                    <input type="password" id="newPassword" name="newPassword">
                                    <button type="button" class="password-toggle" onclick="togglePassword('newPassword')">👁️</button>
                                </div>
                            </div>
                        </div>
                        <div class="col">
                            <div class="form-group">
                                <label for="confirmPassword">Konfirmasi Password:</label>
                                <div class="password-input-wrapper">
                                    <input type="password" id="confirmPassword" name="confirmPassword">
                                    <button type="button" class="password-toggle" onclick="togglePassword('confirmPassword')">👁️</button>
                                </div>
                            </div>
                        </div>
                    </div>
                </div>
                <% } else { %>
                <div class="password-section">
                    <div class="google-photo-info">
                        <strong>ℹ️ Login Google:</strong> Password dikelola oleh Google dan tidak dapat diubah di sini.
                        <br><small>Untuk mengubah password, silakan kunjungi pengaturan akun Google Anda.</small>
                    </div>
                </div>
                <% } %>
                
                <div style="text-align: center; margin-top: 30px;">
                    <button type="button" class="btn btn-secondary" onclick="history.back()">Kembali</button>
                    <button type="submit" class="btn">Simpan Perubahan</button>
                </div>
            </form>
        </div>
    </div>
    
    <script>
        // Global variables to track photo state
        let hasGooglePhoto = <%= hasGooglePhoto %>;
        let googlePhotoUrl = '<%= googlePhoto %>';
        let loginType = '<%= loginType %>';
        let fallbackUrl = '<%= fallbackPhoto %>';
        
        // ENHANCED: Delete photo function
        function deletePhoto() {
            if (confirm('Apakah Anda yakin ingin menghapus foto profil yang diupload?')) {
                fetch('deleteProfilePhoto.jsp', {
                    method: 'POST',
                    headers: {
                        'Content-Type': 'application/x-www-form-urlencoded',
                    },
                    body: 'userId=<%= userId %>'
                })
                .then(response => response.text())
                .then(responseText => {
                    console.log('Delete response:', responseText);
                    
                    let data;
                    try {
                        const jsonMatch = responseText.match(/\{[\s\S]*\}/);
                        if (jsonMatch) {
                            data = JSON.parse(jsonMatch[0]);
                        } else {
                            throw new Error('No JSON found in response');
                        }
                    } catch (e) {
                        console.error('Failed to parse response:', e);
                        throw new Error('Server response format error');
                    }
                    
                    if (data.success) {
                        showAlert('success', data.message);
                        
                        // Update photo preview based on what's available
                        const profileImg = document.getElementById('profilePhotoPreview');
                        
                        if (hasGooglePhoto) {
                            // Switch to Google photo
                            profileImg.src = googlePhotoUrl;
                            updatePhotoSourceInfo('google', 'Foto dari akun Google', false);
                        } else {
                            // Switch to default photo
                            profileImg.src = fallbackUrl;
                            updatePhotoSourceInfo('default', 'Foto default sistem', false);
                        }
                        
                        // Clear file input
                        document.getElementById('fotoProfil').value = '';
                        
                    } else {
                        showAlert('error', data.message);
                    }
                })
                .catch(error => {
                    console.error('Error:', error);
                    showAlert('error', 'Terjadi kesalahan saat menghapus foto: ' + error.message);
                });
            }
        }
        
        // ENHANCED: Better image error handling
        function handleImageError(img, fallbackUrl) {
            console.log('Image failed to load:', img.src);
            img.src = fallbackUrl;
            updatePhotoSourceInfo('default', 'Foto default sistem (foto sebelumnya gagal dimuat)', false);
        }
        
        // Toggle password visibility
        function togglePassword(fieldId) {
            const field = document.getElementById(fieldId);
            const button = field.nextElementSibling;
            
            if (field.type === 'password') {
                field.type = 'text';
                button.textContent = '🙈';
            } else {
                field.type = 'password';
                button.textContent = '👁️';
            }
        }
        
        // Preview profile photo
        document.getElementById('fotoProfil').addEventListener('change', function(e) {
            const file = e.target.files[0];
            if (file) {
                // Validate file size (max 5MB)
                if (file.size > 5 * 1024 * 1024) {
                    showAlert('error', 'Ukuran file maksimal 5MB!');
                    this.value = '';
                    return;
                }
                
                // Validate file type
                if (!file.type.startsWith('image/')) {
                    showAlert('error', 'File harus berupa gambar!');
                    this.value = '';
                    return;
                }
                
                const reader = new FileReader();
                reader.onload = function(e) {
                    document.getElementById('profilePhotoPreview').src = e.target.result;
                    updatePhotoSourceInfo('local', 'Preview foto yang akan diupload', false);
                };
                reader.readAsDataURL(file);
            }
        });
        
        // Form submission
        document.getElementById('profileForm').addEventListener('submit', function(e) {
            e.preventDefault();
            
            // Validate tanggal lahir
            const tanggalLahir = document.getElementById('tanggalLahir').value;
            if (tanggalLahir === '') {
                document.getElementById('tanggalLahir').removeAttribute('name');
            }
            
            // Validate password fields only for non-Google users
            if (loginType !== 'google') {
                const currentPassword = document.getElementById('currentPassword').value;
                const newPassword = document.getElementById('newPassword').value;
                const confirmPassword = document.getElementById('confirmPassword').value;
                
                if (newPassword || confirmPassword || currentPassword) {
                    if (!currentPassword) {
                        showAlert('error', 'Password saat ini harus diisi!');
                        return;
                    }
                    if (newPassword !== confirmPassword) {
                        showAlert('error', 'Konfirmasi password tidak cocok!');
                        return;
                    }
                    if (newPassword.length < 6) {
                        showAlert('error', 'Password baru minimal 6 karakter!');
                        return;
                    }
                }
            }
            
            // Submit form
            const formData = new FormData(this);
            
            if (tanggalLahir === '') {
                formData.set('tanggalLahir', '');
            }
            
            // Show loading state
            const submitBtn = this.querySelector('button[type="submit"]');
            const originalText = submitBtn.textContent;
            submitBtn.textContent = 'Menyimpan...';
            submitBtn.disabled = true;
            
            fetch('updateUserProfile.jsp', {
                method: 'POST',
                body: formData
            })
            .then(response => response.text())
            .then(responseText => {
                console.log('Response:', responseText);
                
                // Parse response manually since it's not pure JSON
                let data;
                try {
                    // Extract JSON from response
                    const jsonMatch = responseText.match(/\{[\s\S]*\}/);
                    if (jsonMatch) {
                        data = JSON.parse(jsonMatch[0]);
                    } else {
                        throw new Error('No JSON found in response');
                    }
                } catch (e) {
                    console.error('Failed to parse response:', e);
                    throw new Error('Server response format error');
                }
                
                if (data.success) {
                    showAlert('success', data.message);
                    
                    // If photo was uploaded, update the preview
                    if (data.photoUrl) {
                        document.getElementById('profilePhotoPreview').src = 'uploads/' + data.photoUrl;
                        updatePhotoSourceInfo('local', 'Foto profil yang diupload', true);
                    }
                    
                    // Clear password fields for non-Google users
                    if (loginType !== 'google') {
                        document.getElementById('currentPassword').value = '';
                        document.getElementById('newPassword').value = '';
                        document.getElementById('confirmPassword').value = '';
                    }
                } else {
                    showAlert('error', data.message);
                }
            })
            .catch(error => {
                console.error('Error:', error);
                showAlert('error', 'Terjadi kesalahan: ' + error.message);
            })
            .finally(() => {
                // Reset button state
                submitBtn.textContent = originalText;
                submitBtn.disabled = false;
                
                // Restore tanggal lahir name attribute if removed
                if (tanggalLahir === '') {
                    document.getElementById('tanggalLahir').setAttribute('name', 'tanggalLahir');
                }
            });
        });
        
        // ENHANCED: Update photo source info with delete button management
        function updatePhotoSourceInfo(type, text, showDeleteBtn) {
            const photoSource = document.getElementById('photoSourceInfo');
            const statusIcon = document.getElementById('statusIcon');
            const statusText = document.getElementById('statusText');
            const sourceText = document.getElementById('sourceText');
            
            // Update classes
            photoSource.className = 'photo-source ' + type;
            statusIcon.className = 'status-icon ' + type;
            
            // Update text
            const statusTexts = {
                'local': 'Foto lokal aktif',
                'google': 'Foto Google aktif',
                'default': 'Tidak ada foto'
            };
            
            statusText.textContent = statusTexts[type];
            sourceText.textContent = text;
            
            // Manage delete button
            let deleteBtn = document.getElementById('deletePhotoBtn');
            
            if (type === 'local' && showDeleteBtn) {
                if (!deleteBtn) {
                    // Create delete button if it doesn't exist
                    deleteBtn = document.createElement('button');
                    deleteBtn.type = 'button';
                    deleteBtn.className = 'btn btn-danger';
                    deleteBtn.id = 'deletePhotoBtn';
                    deleteBtn.innerHTML = '🗑️ Hapus Foto';
                    deleteBtn.onclick = deletePhoto;
                    
                    const photoStatus = photoSource.querySelector('.photo-status');
                    photoStatus.appendChild(deleteBtn);
                }
                deleteBtn.style.display = 'inline-block';
            } else {
                if (deleteBtn) {
                    deleteBtn.style.display = 'none';
                }
            }
            
            // Update Google photo info
            const googleInfo = photoSource.querySelector('.google-photo-info');
            if (googleInfo && loginType === 'google') {
                const hasLocalPhoto = (type === 'local');
                const infoText = googleInfo.querySelector('small');
                
                if (hasGooglePhoto) {
                    if (hasLocalPhoto) {
                        infoText.textContent = 'Foto yang diupload saat ini menggantikan foto Google. Hapus foto lokal untuk kembali ke foto Google.';
                    } else {
                        infoText.textContent = 'Foto Google sedang digunakan.';
                    }
                } else {
                    infoText.textContent = 'Silakan upload foto profil atau periksa pengaturan foto di akun Google Anda.';
                }
            }
        }
        
        function showAlert(type, message) {
            const alertElement = document.getElementById(type === 'success' ? 'successAlert' : 'errorAlert');
            alertElement.textContent = message;
            alertElement.style.display = 'block';
            
            // Hide other alert
            const otherAlert = document.getElementById(type === 'success' ? 'errorAlert' : 'successAlert');
            otherAlert.style.display = 'none';
            
            // Auto hide after 5 seconds
            setTimeout(() => {
                alertElement.style.display = 'none';
            }, 5000);
            
            // Scroll to top to show alert
            window.scrollTo({ top: 0, behavior: 'smooth' });
        }
    </script>
</body>
</html>