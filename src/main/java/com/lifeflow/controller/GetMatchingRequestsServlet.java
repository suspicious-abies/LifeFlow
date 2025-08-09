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
import javax.servlet.http.HttpSession;

import org.json.JSONArray;
import org.json.JSONObject;

@WebServlet("/getMatchingRequests")
public class GetMatchingRequestsServlet extends HttpServlet {
    private static final long serialVersionUID = 1L;

    protected void doGet(HttpServletRequest request, HttpServletResponse response) throws ServletException, IOException {
        HttpSession session = request.getSession(false);
        if (session == null || session.getAttribute("userId") == null) {
            response.setStatus(HttpServletResponse.SC_UNAUTHORIZED);
            return;
        }

        // We need to fetch the user's blood group from the DB to ensure it's current
        String userBloodGroup = "";
        int userId = (Integer) session.getAttribute("userId");

        String getUserSql = "SELECT bloodGroup FROM users WHERE id = ?";
        String getRequestsSql = "SELECT * FROM blood_requests WHERE required_blood_group = ? AND status = 'Open' AND units_required > 0";

        JSONArray results = new JSONArray();

        try (Connection conn = DriverManager.getConnection("jdbc:mysql://localhost:3306/blood_bank_db", "root", "")) {

            // First, get the current user's blood group
            try (PreparedStatement userPstmt = conn.prepareStatement(getUserSql)) {
                userPstmt.setInt(1, userId);
                ResultSet userRs = userPstmt.executeQuery();
                if (userRs.next()) {
                    userBloodGroup = userRs.getString("bloodGroup");
                }
            }

            // If we found a blood group, search for matching requests
            if (!userBloodGroup.isEmpty()) {
                try (PreparedStatement requestsPstmt = conn.prepareStatement(getRequestsSql)) {
                    requestsPstmt.setString(1, userBloodGroup);
                    ResultSet rs = requestsPstmt.executeQuery();
                    while (rs.next()) {
                        JSONObject req = new JSONObject();
                        req.put("id", rs.getInt("id"));
                        req.put("hospital_name", rs.getString("hospital_name"));
                        req.put("hospital_location", rs.getString("hospital_location"));
                        req.put("units_required", rs.getInt("units_required"));
                        results.put(req);
                    }
                }
            }

        } catch (SQLException e) {
            e.printStackTrace();
            response.setStatus(HttpServletResponse.SC_INTERNAL_SERVER_ERROR);
            return;
        }

        response.setContentType("application/json");
        response.setCharacterEncoding("UTF-8");
        PrintWriter out = response.getWriter();
        out.print(results.toString());
        out.flush();
    }
}
