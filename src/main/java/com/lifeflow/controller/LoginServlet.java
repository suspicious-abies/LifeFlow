package com.lifeflow.controller;

import java.io.IOException;
import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;
import java.security.NoSuchAlgorithmException;
import java.sql.Connection;
import java.sql.DriverManager;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.util.Base64;

import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.Cookie;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import javax.servlet.http.HttpSession;

@WebServlet("/login")
public class LoginServlet extends HttpServlet {
    private static final long serialVersionUID = 1L;

    // --- Database connection details ---
    private static final String DB_URL = "jdbc:mysql://localhost:3306/blood_bank_db?useSSL=false";
    private static final String DB_USER = "root";
    private static final String DB_PASSWORD = "";

    // --- A secret key for hashing. In a real app, store this securely! ---
    private static final String SECRET_KEY = "LifeFlow-8858-secretkey-2025";

    @Override
    public void init() throws ServletException {
        try {
            Class.forName("com.mysql.cj.jdbc.Driver");
        } catch (ClassNotFoundException e) {
            throw new ServletException("Failed to load MySQL JDBC driver", e);
        }
    }

    protected void doPost(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        String email = request.getParameter("email");
        String password = request.getParameter("password");

        try (Connection conn = DriverManager.getConnection(DB_URL, DB_USER, DB_PASSWORD)) {
            String sql = "SELECT * FROM users WHERE email = ? AND password = ?";
            try (PreparedStatement pstmt = conn.prepareStatement(sql)) {
                pstmt.setString(1, email);
                pstmt.setString(2, password);

                try (ResultSet rs = pstmt.executeQuery()) {
                    if (rs.next()) {
                        // --- User authenticated successfully ---
                        int userId = rs.getInt("id");
                        String fullName = rs.getString("fullName");

                        // --- Create a session for immediate use ---
                        HttpSession session = request.getSession();
                        session.setAttribute("userId", userId);
                        session.setAttribute("fullName", fullName);

                        // --- Generate a secure token for the "Remember Me" cookie ---
                        String token = generateToken(userId);

                        // --- Store the token in the database ---
                        storeTokenInDatabase(conn, userId, token);

                        // --- Create and set the cookie ---
                        Cookie userCookie = new Cookie("session_token", token);
                        userCookie.setMaxAge(60 * 60 * 24 * 30); // 30 days
                        userCookie.setPath("/"); // Make cookie available for the whole app
                        response.addCookie(userCookie);

                        // --- Redirect to the dashboard ---
                        response.sendRedirect("dashboard.jsp");
                    } else {
                        // --- Authentication failed ---
                        response.sendRedirect("login_failure.html");
                    }
                }
            }
        } catch (SQLException | NoSuchAlgorithmException e) {
            e.printStackTrace();
            response.sendRedirect("login_failure.html");
        }
    }

    /**
     * Generates a secure hash token for the user session.
     */
    private String generateToken(int userId) throws NoSuchAlgorithmException {
        String dataToHash = userId + ":" + System.currentTimeMillis() + ":" + SECRET_KEY;
        MessageDigest digest = MessageDigest.getInstance("SHA-256");
        byte[] hash = digest.digest(dataToHash.getBytes(StandardCharsets.UTF_8));
        return Base64.getEncoder().encodeToString(hash);
    }

    /**
     * Stores the session token in the database.
     */
    private void storeTokenInDatabase(Connection conn, int userId, String token) throws SQLException {
        // First, delete any old tokens for this user
        String deleteSql = "DELETE FROM sessions WHERE user_id = ?";
        try (PreparedStatement deletePstmt = conn.prepareStatement(deleteSql)) {
            deletePstmt.setInt(1, userId);
            deletePstmt.executeUpdate();
        }

        // Then, insert the new token
        String insertSql = "INSERT INTO sessions (user_id, token) VALUES (?, ?)";
        try (PreparedStatement insertPstmt = conn.prepareStatement(insertSql)) {
            insertPstmt.setInt(1, userId);
            insertPstmt.setString(2, token);
            insertPstmt.executeUpdate();
        }
    }
}
