package com.lifeflow.controller;

import java.io.IOException;
import java.io.PrintWriter;
import java.sql.Connection;
import java.sql.DriverManager;
import java.sql.PreparedStatement;
import java.sql.SQLException;

import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;

// This annotation maps the servlet to the URL pattern "/register"
// It replaces the need for mapping in web.xml for Servlet 3.0+ containers like Tomcat 7+
@WebServlet("/register")
public class RegisterServlet extends HttpServlet {
    private static final long serialVersionUID = 1L;

    // Database connection details
    // IMPORTANT: Replace with your actual database URL, user, and password.
    private static final String DB_URL = "jdbc:mysql://localhost:3306/blood_bank_db?useSSL=false";
    private static final String DB_USER = "root"; // Change to your MySQL username
    private static final String DB_PASSWORD = ""; // Change to your MySQL password

    @Override
    public void init() throws ServletException {
        // Load the MySQL JDBC driver when the servlet is initialized
        try {
            Class.forName("com.mysql.cj.jdbc.Driver");
        } catch (ClassNotFoundException e) {
            // This is a critical error, so we throw a ServletException
            throw new ServletException("Failed to load MySQL JDBC driver", e);
        }
    }

    /**
     * Handles the HTTP POST request from the registration form.
     */
    protected void doPost(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        // Set response content type
        response.setContentType("text/html");
        PrintWriter out = response.getWriter();

        // Retrieve form parameters from the request
        String fullName = request.getParameter("fullName");
        String email = request.getParameter("email");
        String password = request.getParameter("password"); // Note: In a real app, hash this password!
        String phone = request.getParameter("phone");
        String bloodGroup = request.getParameter("bloodGroup");
        String city = request.getParameter("city");

        Connection conn = null;
        PreparedStatement pstmt = null;

        try {
            // 1. Establish a connection to the database
            conn = DriverManager.getConnection(DB_URL, DB_USER, DB_PASSWORD);

            // 2. Create a SQL INSERT statement
            // Using a PreparedStatement is crucial to prevent SQL injection attacks.
            String sql = "INSERT INTO users (fullName, email, password, phone, bloodGroup, city, registrationDate) VALUES (?, ?, ?, ?, ?, ?, CURDATE())";
            pstmt = conn.prepareStatement(sql);

            // 3. Set the parameters for the PreparedStatement
            pstmt.setString(1, fullName);
            pstmt.setString(2, email);
            pstmt.setString(3, password); // Hashing the password should be done here
            pstmt.setString(4, phone);
            pstmt.setString(5, bloodGroup);
            pstmt.setString(6, city);


            // 4. Execute the query
            int rowsAffected = pstmt.executeUpdate();

            // 5. Check if the insertion was successful and send a response
            if (rowsAffected > 0) {
                // Redirect to a success page or show a success message
                response.sendRedirect("registration_success.html");
            } else {
                out.println("<html><body><h1>Registration failed. Please try again.</h1></body></html>");
            }

        } catch (SQLException e) {
            // Handle database errors (e.g., duplicate email)
            response.setStatus(HttpServletResponse.SC_INTERNAL_SERVER_ERROR);
            out.println("<html><body><h1>Database Error</h1><p>An error occurred: " + e.getMessage() + "</p></body></html>");
            // Log the exception for debugging
            e.printStackTrace();
        } finally {
            // 6. Close the resources in a finally block to ensure they are always closed
            try {
                if (pstmt != null) pstmt.close();
                if (conn != null) conn.close();
            } catch (SQLException e) {
                e.printStackTrace();
            }
        }
    }
}
