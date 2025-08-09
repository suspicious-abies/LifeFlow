<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="java.sql.*, java.util.*, java.text.SimpleDateFormat, java.net.URLEncoder" %>

<%
// --- Security Check & Session Info ---
if (session.getAttribute("userId") == null) {
    response.sendRedirect("index.html");
    return;
}
String fullName = (String) session.getAttribute("fullName");

// --- Database Connection ---
String dbUrl = "jdbc:mysql://localhost:3306/blood_bank_db?useSSL=false";
String dbUser = "root";
String dbPass = "";
Connection conn = null;
%>

<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>All Open Requests - LifeFlow</title>
    <script src="https://cdn.tailwindcss.com"></script>
    <link href="https://fonts.googleapis.com/css2?family=Inter:wght@400;500;600;700&display=swap" rel="stylesheet">
</head>
<body class="bg-gray-100 font-sans">
    <!-- Header -->
    <header class="bg-white shadow-md">
        <nav class="container mx-auto px-6 py-4 flex justify-between items-center">
            <a href="dashboard.jsp" class="text-2xl font-bold text-red-600">LifeFlow</a>
            <div class="flex items-center">
                <span class="text-gray-700 mr-4">Welcome, <%= fullName %>!</span>
                <a href="dashboard.jsp" class="text-sm text-blue-600 hover:underline mr-4">Back to Dashboard</a>
                <a href="logout" class="px-4 py-2 text-white bg-red-600 rounded-full hover:bg-red-700 text-sm">Logout</a>
            </div>
        </nav>
    </header>

    <!-- Main Content -->
    <main class="flex-grow container mx-auto p-6">
        <div class="bg-white p-8 rounded-lg shadow">
            <h1 class="text-3xl font-bold text-gray-800 mb-6">All Open Blood Requests</h1>
            <div class="overflow-x-auto">
                <table class="min-w-full bg-white">
                    <thead class="bg-gray-200">
                        <tr>
                            <th class="py-3 px-4 text-left text-sm font-semibold text-gray-600 uppercase">Patient</th>
                            <th class="py-3 px-4 text-left text-sm font-semibold text-gray-600 uppercase">Blood Group</th>
                            <th class="py-3 px-4 text-left text-sm font-semibold text-gray-600 uppercase">Location</th>
                            <th class="py-3 px-4 text-left text-sm font-semibold text-gray-600 uppercase">Contact</th>
                            <th class="py-3 px-4 text-left text-sm font-semibold text-gray-600 uppercase">Action</th>
                        </tr>
                    </thead>
                    <tbody class="text-gray-700">
                        <%
                            try {
                                conn = DriverManager.getConnection(dbUrl, dbUser, dbPass);
                                String allRequestsSql = "SELECT * FROM blood_requests WHERE status = 'Open' AND units_required > 0 ORDER BY request_date DESC";
                                try (PreparedStatement pstmt = conn.prepareStatement(allRequestsSql)) {
                                    ResultSet rs = pstmt.executeQuery();
                                    if (!rs.isBeforeFirst()) {
                                        out.println("<tr><td colspan='5' class='py-4 px-4 text-center text-gray-500'>No open blood requests at the moment.</td></tr>");
                                    } else {
                                        while (rs.next()) {
                                            String message = "Urgent blood needed! \n" +
                                                             "Patient: " + rs.getString("patient_name") + "\n" +
                                                             "Blood Group: " + rs.getString("required_blood_group") + "\n" +
                                                             "Hospital: " + rs.getString("hospital_name") + ", " + rs.getString("hospital_location") + "\n" +
                                                             "Contact: " + rs.getString("contact_person") + " at " + rs.getString("contact_phone") + "\n\n" +
                                                             "Shared via LifeFlow App. \n" +
                                                             "https://lifeflow.co.in";
                                            String encodedMessage = URLEncoder.encode(message, "UTF-8");
                                            String whatsappLink = "https://wa.me/?text=" + encodedMessage;
                        %>
                        <tr class="border-b border-gray-200">
                            <td class="py-3 px-4"><%= rs.getString("patient_name") %></td>
                            <td class="py-3 px-4"><%= rs.getString("required_blood_group") %></td>
                            <td class="py-3 px-4"><%= rs.getString("hospital_name") %>, <%= rs.getString("hospital_location") %></td>
                            <td class="py-3 px-4"><%= rs.getString("contact_person") %> (<%= rs.getString("contact_phone") %>)</td>
                            <td class="py-3 px-4">
                                <a href="<%= whatsappLink %>" target="_blank" class="inline-flex items-center bg-green-500 text-white px-3 py-1 rounded text-sm hover:bg-green-600">
                                    <svg class="w-4 h-4 mr-2" fill="currentColor" viewBox="0 0 24 24"><path d="M.057 24l1.687-6.163c-1.041-1.804-1.588-3.849-1.587-5.946.003-6.556 5.338-11.891 11.893-11.891 3.181.001 6.167 1.24 8.413 3.488 2.245 2.248 3.481 5.236 3.48 8.414-.003 6.557-5.338 11.892-11.894 11.892-1.99-.001-3.951-.5-5.688-1.448l-6.305 1.654zm6.597-3.807c1.676.995 3.276 1.591 5.392 1.592 5.448 0 9.886-4.434 9.889-9.885.002-5.462-4.415-9.89-9.881-9.892-5.452 0-9.887 4.434-9.889 9.886-.001 2.267.651 4.383 1.905 6.344l-1.225 4.485 4.62-1.212zM12 7.75c.414 0 .75.336.75.75v3.5h3.5c.414 0 .75.336.75.75s-.336.75-.75.75h-3.5v3.5c0 .414-.336.75-.75.75s-.75-.336-.75-.75v-3.5h-3.5c-.414 0-.75-.336-.75-.75s.336-.75.75-.75h3.5v-3.5c0-.414.336-.75.75.75z"/></svg>
                                    Spread the Word
                                </a>
                            </td>
                        </tr>
                        <%
                                        }
                                    }
                                }
                            } catch (SQLException e) {
                                e.printStackTrace();
                            } finally {
                                if (conn != null) try { conn.close(); } catch (SQLException e) { e.printStackTrace(); }
                            }
                        %>
                    </tbody>
                </table>
            </div>
        </div>
    </main>
</body>
</html>
