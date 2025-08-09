<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="java.sql.*" %>

<%
// --- Security Check & Session Info ---
if (session.getAttribute("userId") == null) {
    response.sendRedirect("index.html");
    return;
}
Integer userId = (Integer) session.getAttribute("userId");
String currentFullName = "";
String currentBloodGroup = "";
String currentCity = "";

// --- Database Connection & Data Fetching ---
String dbUrl = "jdbc:mysql://localhost:3306/blood_bank_db?useSSL=false";
String dbUser = "root";
String dbPass = "";

try (Connection conn = DriverManager.getConnection(dbUrl, dbUser, dbPass)) {
    String sql = "SELECT fullName, bloodGroup, city FROM users WHERE id = ?";
    try (PreparedStatement pstmt = conn.prepareStatement(sql)) {
        pstmt.setInt(1, userId);
        ResultSet rs = pstmt.executeQuery();
        if (rs.next()) {
            currentFullName = rs.getString("fullName");
            currentBloodGroup = rs.getString("bloodGroup");
            currentCity = rs.getString("city");
        } else {
            // Handle case where user is not found, though unlikely if session exists
            response.sendRedirect("logout");
            return;
        }
    }
} catch (SQLException e) {
    e.printStackTrace();
}
%>

<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Edit Profile - LifeFlow</title>
    <script src="https://cdn.tailwindcss.com"></script>
    <link href="https://fonts.googleapis.com/css2?family=Inter:wght@400;500;600;700&display=swap" rel="stylesheet">
    <link rel="icon" href="favicon.ico" type="image/x-icon">
    <link rel="shortcut icon" href="favicon.ico" type="image/x-icon">
</head>
<body class="bg-gray-100 font-sans">
    <!-- Header -->
    <header class="bg-white shadow-md">
        <nav class="container mx-auto px-6 py-4 flex justify-between items-center">
            <div>
                <img src="images/LifeFlowIcon.jpg" alt="LifeFlow Logo" class="h-10 w-10 rounded-full mr-4 float-left">
                <a href="dashboard.jsp" class="text-2xl font-bold text-red-600">LifeFlow</a>
            </div>
            <div>
                <a href="dashboard.jsp" class="text-sm text-blue-600 hover:underline mr-4">Back to Dashboard</a>
                <a href="logout" class="px-4 py-2 text-white bg-red-600 rounded-full hover:bg-red-700 text-sm">Logout</a>
            </div>
        </nav>
    </header>

    <!-- Main Content -->
    <main class="flex-grow container mx-auto p-6">
        <div class="max-w-lg mx-auto bg-white p-8 rounded-lg shadow">
            <h1 class="text-3xl font-bold text-gray-800 mb-6">Edit Your Profile</h1>
            <form action="updateProfile" method="POST" class="space-y-6">
                <div>
                    <label for="fullName" class="block text-sm font-medium text-gray-700">Full Name</label>
                    <input type="text" name="fullName" id="fullName" value="<%= currentFullName %>" class="mt-1 block w-full px-3 py-2 border border-gray-300 rounded-md shadow-sm focus:outline-none focus:ring-red-500 focus:border-red-500" required>
                </div>
                <div>
                    <label for="bloodGroup" class="block text-sm font-medium text-gray-700">Blood Group</label>
                    <select id="bloodGroup" name="bloodGroup" class="mt-1 block w-full pl-3 pr-10 py-2 border-gray-300 focus:outline-none focus:ring-red-500 focus:border-red-500 rounded-md" required>
                        <%
                            String[] bloodGroups = {"A+", "A-", "B+", "B-", "AB+", "AB-", "O+", "O-"};
                            for (String bg : bloodGroups) {
                                String selected = bg.equals(currentBloodGroup) ? "selected" : "";
                                out.println("<option " + selected + ">" + bg + "</option>");
                            }
                        %>
                    </select>
                </div>
                <div>
                    <label for="city" class="block text-sm font-medium text-gray-700">City</label>
                    <input type="text" name="city" id="city" value="<%= currentCity %>" class="mt-1 block w-full px-3 py-2 border border-gray-300 rounded-md shadow-sm focus:outline-none focus:ring-red-500 focus:border-red-500" required>
                </div>
                <div class="pt-4">
                    <button type="submit" class="w-full flex justify-center py-3 px-4 border border-transparent rounded-md shadow-sm text-lg font-medium text-white bg-green-600 hover:bg-green-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-green-500">
                        Save Changes
                    </button>
                </div>
            </form>
        </div>
    </main>
</body>
</html>
