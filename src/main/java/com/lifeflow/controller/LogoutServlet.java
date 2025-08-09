package com.lifeflow.controller;

import java.io.IOException;
import java.sql.Connection;
import java.sql.DriverManager;
import java.sql.PreparedStatement;
import java.sql.SQLException;

import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.Cookie;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import javax.servlet.http.HttpSession;

@WebServlet("/logout")
public class LogoutServlet extends HttpServlet {
    private static final long serialVersionUID = 1L;

    protected void doGet(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        // --- Invalidate the session ---
        HttpSession session = request.getSession(false);
        if (session != null) {
            session.invalidate();
        }

        // --- Invalidate the cookie ---
        Cookie[] cookies = request.getCookies();
        if (cookies != null) {
            for (Cookie cookie : cookies) {
                if (cookie.getName().equals("session_token")) {
                    String token = cookie.getValue();
                    // Delete token from database
                    deleteTokenFromDatabase(token);

                    // Expire the cookie
                    cookie.setMaxAge(0);
                    cookie.setPath("/");
                    response.addCookie(cookie);
                    break;
                }
            }
        }

        // --- Redirect to the homepage ---
        response.sendRedirect("index.html");
    }

    private void deleteTokenFromDatabase(String token) {
        String sql = "DELETE FROM sessions WHERE token = ?";
        try (Connection conn = DriverManager.getConnection("jdbc:mysql://localhost:3306/blood_bank_db", "root", "");
             PreparedStatement pstmt = conn.prepareStatement(sql)) {
            pstmt.setString(1, token);
            pstmt.executeUpdate();
        } catch (SQLException e) {
            e.printStackTrace();
        }
    }
}
