package com.lifeflow.filter;

import java.io.IOException;
import java.sql.Connection;
import java.sql.DriverManager;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;

import javax.servlet.Filter;
import javax.servlet.FilterChain;
import javax.servlet.FilterConfig;
import javax.servlet.ServletException;
import javax.servlet.ServletRequest;
import javax.servlet.ServletResponse;
import javax.servlet.annotation.WebFilter;
import javax.servlet.http.Cookie;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import javax.servlet.http.HttpSession;

@WebFilter("/*")
public class AuthenticationFilter implements Filter {

    @Override
    public void init(FilterConfig filterConfig) throws ServletException {
        try {
            Class.forName("com.mysql.cj.jdbc.Driver");
        } catch (ClassNotFoundException e) {
            throw new ServletException("Failed to load MySQL JDBC driver for filter", e);
        }
    }

    @Override
    public void doFilter(ServletRequest req, ServletResponse res, FilterChain chain)
            throws IOException, ServletException {

        HttpServletRequest request = (HttpServletRequest) req;
        HttpServletResponse response = (HttpServletResponse) res;
        HttpSession session = request.getSession(false);

        String path = request.getRequestURI().substring(request.getContextPath().length());

        // --- Allow access to static resources, login/register pages, and servlets ---
        if (path.startsWith("/css/") || path.startsWith("/js/") || path.equals("/index.html") ||
                path.equals("/login") || path.equals("/register") || path.equals("/login_failure.html") ||
                path.equals("/registration_success.html")) {
            chain.doFilter(request, response);
            return;
        }
        // First, check if the user is logged in, either by an active session or a valid cookie.
        boolean isLoggedIn = (session != null && session.getAttribute("userId") != null);
        if (!isLoggedIn) {
            Cookie[] cookies = request.getCookies();
            if (cookies != null) {
                for (Cookie cookie : cookies) {
                    if (cookie.getName().equals("session_token")) {
                        if (validateToken(cookie.getValue(), request)) {
                            isLoggedIn = true;
                        }
                        break;
                    }
                }
            }
        }

        // --- Routing Logic ---

        // CASE 1: User is LOGGED IN
        if (isLoggedIn) {
            // If a logged-in user tries to access the homepage, redirect them to the dashboard.
            if (path.equals("/index.html") || path.equals("/")) {
                response.sendRedirect("dashboard.jsp");
                return;
            }
        }
        // CASE 2: User is NOT LOGGED IN
        else {
            // If a logged-out user tries to access a protected page (like the dashboard), redirect them to the homepage.
            if (path.equals("dashboard.jsp")) {
                response.sendRedirect("index.html");
                return;
            }
        }

        // For all other cases (e.g., accessing CSS, JS, login/register servlets), let the request proceed.
        chain.doFilter(request, response);
    }

    private boolean validateToken(String token, HttpServletRequest request) {
        // This method checks if the token from the cookie is valid in the database.
        // If it is, it creates a new session for the user.
        String sql = "SELECT u.id, u.fullName FROM users u JOIN sessions s ON u.id = s.user_id WHERE s.token = ?";
        try (Connection conn = DriverManager.getConnection("jdbc:mysql://localhost:3306/blood_bank_db", "root", "");
             PreparedStatement pstmt = conn.prepareStatement(sql)) {

            pstmt.setString(1, token);
            try (ResultSet rs = pstmt.executeQuery()) {
                if (rs.next()) {
                    // Token is valid, create a new session.
                    HttpSession session = request.getSession(true);
                    session.setAttribute("userId", rs.getInt("id"));
                    session.setAttribute("fullName", rs.getString("fullName"));
                    return true;
                }
            }
        } catch (SQLException e) {
            e.printStackTrace();
        }
        return false;
    }

    @Override
    public void destroy() {}
}
