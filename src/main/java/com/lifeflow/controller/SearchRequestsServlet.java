package com.lifeflow.controller;

import java.io.IOException;
import java.io.PrintWriter;
import java.sql.Connection;
import java.sql.DriverManager;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import org.json.JSONArray;
import org.json.JSONObject;

@WebServlet("/searchRequests")
public class SearchRequestsServlet extends HttpServlet {
    private static final long serialVersionUID = 1L;

    protected void doGet(HttpServletRequest request, HttpServletResponse response) throws ServletException, IOException {
        String location = request.getParameter("location");
        String bloodGroup = request.getParameter("bloodGroup");

        String sql = "SELECT * FROM blood_requests WHERE hospital_location LIKE ? AND required_blood_group = ? AND status = 'Open' AND units_required > 0";
        JSONArray results = new JSONArray();

        try (Connection conn = DriverManager.getConnection("jdbc:mysql://localhost:3306/blood_bank_db", "root", "");
             PreparedStatement pstmt = conn.prepareStatement(sql)) {

            pstmt.setString(1, "%" + location + "%");
            pstmt.setString(2, bloodGroup);

            ResultSet rs = pstmt.executeQuery();
            while (rs.next()) {
                JSONObject req = new JSONObject();
                req.put("id", rs.getInt("id"));
                req.put("patient_name", rs.getString("patient_name"));
                req.put("hospital_name", rs.getString("hospital_name"));
                req.put("hospital_location", rs.getString("hospital_location"));
                req.put("units_required", rs.getInt("units_required"));
                results.put(req);
            }
        } catch (SQLException e) {
            e.printStackTrace();
        }

        response.setContentType("application/json");
        response.setCharacterEncoding("UTF-8");
        PrintWriter out = response.getWriter();
        out.print(results.toString());
        out.flush();
    }
}
