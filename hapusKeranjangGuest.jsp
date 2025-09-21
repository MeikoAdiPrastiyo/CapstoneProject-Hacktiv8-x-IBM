<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="java.util.*" %>
<%
    String barangIdStr = request.getParameter("barang_id");
    
    if (barangIdStr == null) {
        response.sendRedirect("keranjangGuest.jsp?error=Parameter tidak lengkap");
        return;
    }
    
    int barangId = Integer.parseInt(barangIdStr);
    
    // Ambil cart dari session
    Map<Integer, Integer> cart = (Map<Integer, Integer>) session.getAttribute("cart");
    if (cart != null && cart.containsKey(barangId)) {
        cart.remove(barangId);
        session.setAttribute("cart", cart);
        response.sendRedirect("keranjangGuest.jsp?success=Barang berhasil dihapus dari keranjang");
    } else {
        response.sendRedirect("keranjangGuest.jsp?error=Barang tidak ditemukan di keranjang");
    }
%>