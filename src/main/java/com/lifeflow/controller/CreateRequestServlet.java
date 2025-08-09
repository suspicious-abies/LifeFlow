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

@WebServlet("/createRequest")
public class CreateRequestServlet extends HttpServlet {
    private static final long serialVersionUID = 1L;

    protected void doPost(HttpServletRequest request, HttpServletResponse response) throws ServletException, IOException {
        HttpSession session = request.getSession(false);
        if (session == null || session.getAttribute("userId") == null) {
            response.sendRedirect("index.html");
            return;
        }

        int requesterId = (Integer) session.getAttribute("userId");
        String patientName = request.getParameter("patient_name");
        String bloodGroup = request.getParameter("required_blood_group");
        int unitsRequired = Integer.parseInt(request.getParameter("units_required"));
        String hospitalName = request.getParameter("hospital_name");
        String hospitalLocation = request.getParameter("hospital_location");
        String contactPerson = request.getParameter("contact_person");
        String contactPhone = request.getParameter("contact_phone");

        String sql = "INSERT INTO blood_requests (requester_id, patient_name, required_blood_group, units_required, hospital_name, hospital_location, contact_person, contact_phone) VALUES (?, ?, ?, ?, ?, ?, ?, ?)";

        try (Connection conn = DriverManager.getConnection("jdbc:mysql://localhost:3306/blood_bank_db", "root", "");
             PreparedStatement pstmt = conn.prepareStatement(sql)) {

            pstmt.setInt(1, requesterId);
            pstmt.setString(2, patientName);
            pstmt.setString(3, bloodGroup);
            pstmt.setInt(4, unitsRequired);
            pstmt.setString(5, hospitalName);
            pstmt.setString(6, hospitalLocation);
            pstmt.setString(7, contactPerson);
            pstmt.setString(8, contactPhone);

            pstmt.executeUpdate();
            response.sendRedirect("dashboard.jsp");

        } catch (SQLException e) {
            e.printStackTrace();
            // Handle error
            response.getWriter().write("Error creating request.");
        }
    }
}
