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

@WebServlet("/markFulfilled")
public class MarkFulfilledServlet extends HttpServlet {
    private static final long serialVersionUID = 1L;

    protected void doPost(HttpServletRequest request, HttpServletResponse response) throws ServletException, IOException {
        int appointmentId = Integer.parseInt(request.getParameter("appointmentId"));
        int requestId = Integer.parseInt(request.getParameter("requestId"));

        String updateAppointmentSql = "UPDATE appointments SET status = 'Fulfilled' WHERE id = ?";
        String updateRequestSql = "UPDATE blood_requests SET units_required = units_required - 1 WHERE id = ?";

        Connection conn = null;
        try {
            conn = DriverManager.getConnection("jdbc:mysql://localhost:3306/blood_bank_db", "root", "");
            conn.setAutoCommit(false); // Start transaction

            // Step 1: Update appointment status
            try (PreparedStatement pstmt1 = conn.prepareStatement(updateAppointmentSql)) {
                pstmt1.setInt(1, appointmentId);
                pstmt1.executeUpdate();
            }

            // Step 2: Decrement units required in the original request
            try (PreparedStatement pstmt2 = conn.prepareStatement(updateRequestSql)) {
                pstmt2.setInt(1, requestId);
                pstmt2.executeUpdate();
            }

            conn.commit(); // Commit the transaction if both updates are successful
            response.sendRedirect("dashboard.jsp");

        } catch (SQLException e) {
            if (conn != null) {
                try {
                    conn.rollback(); // Rollback on error to ensure data consistency
                } catch (SQLException ex) {
                    ex.printStackTrace();
                }
            }
            e.printStackTrace();
            response.getWriter().write("Error fulfilling appointment.");
        } finally {
            if (conn != null) {
                try {
                    conn.setAutoCommit(true);
                    conn.close();
                } catch (SQLException e) {
                    e.printStackTrace();
                }
            }
        }
    }
}
