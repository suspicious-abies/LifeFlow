package com.lifeflow.controller;

import java.io.IOException;
import java.sql.Connection;
import java.sql.DriverManager;
import java.sql.PreparedStatement;
import java.sql.SQLException;
import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import javax.servlet.http.HttpSession;

@WebServlet("/updateProfile")
public class UpdateProfileServlet extends HttpServlet {
    private static final long serialVersionUID = 1L;

    protected void doPost(HttpServletRequest request, HttpServletResponse response) throws ServletException, IOException {
        HttpSession session = request.getSession(false);
        if (session == null || session.getAttribute("userId") == null) {
            response.sendRedirect("index.html");
            return;
        }

        Integer userId = (Integer) session.getAttribute("userId");
        String fullName = request.getParameter("fullName");
        String bloodGroup = request.getParameter("bloodGroup");
        String city = request.getParameter("city");

        String sql = "UPDATE users SET fullName = ?, bloodGroup = ?, city = ? WHERE id = ?";

        try (Connection conn = DriverManager.getConnection("jdbc:mysql://localhost:3306/blood_bank_db", "root", "");
             PreparedStatement pstmt = conn.prepareStatement(sql)) {

            pstmt.setString(1, fullName);
            pstmt.setString(2, bloodGroup);
            pstmt.setString(3, city);
            pstmt.setInt(4, userId);

            int rowsAffected = pstmt.executeUpdate();

            if (rowsAffected > 0) {
                // IMPORTANT: Update the name in the session so it reflects immediately in the header
                session.setAttribute("fullName", fullName);
            }

            // Redirect back to the dashboard to see the changes
            response.sendRedirect("dashboard.jsp");

        } catch (SQLException e) {
            e.printStackTrace();
            // Optionally, redirect to an error page
            response.getWriter().write("Error updating profile.");
        }
    }
}
