<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="java.sql.*, java.util.*, java.text.SimpleDateFormat" %>

<%
// --- Security Check & Session Info ---
if (session.getAttribute("userId") == null) {
    response.sendRedirect("index.html");
    return;
}
Integer userId = (Integer) session.getAttribute("userId");
String fullName = (String) session.getAttribute("fullName");
String userBloodGroup = "";
int totalDonations = 0;
int totalRequestsFulfilled = 0; // New variable for fulfilled requests

// --- Database Connection & Data Fetching ---
String dbUrl = "jdbc:mysql://localhost:3306/blood_bank_db?useSSL=false";
String dbUser = "root";
String dbPass = "";
Connection conn = null;

try {
    conn = DriverManager.getConnection(dbUrl, dbUser, dbPass);

    // Fetch user's blood group
    try (PreparedStatement pstmt = conn.prepareStatement("SELECT bloodGroup FROM users WHERE id = ?")) {
        pstmt.setInt(1, userId);
        ResultSet rs = pstmt.executeQuery();
        if (rs.next()) userBloodGroup = rs.getString("bloodGroup");
    }

    // Fetch user's total fulfilled donations (donations they made)
    try (PreparedStatement pstmt = conn.prepareStatement("SELECT COUNT(*) FROM appointments WHERE donor_id = ? AND status = 'Fulfilled'")) {
        pstmt.setInt(1, userId);
        ResultSet rs = pstmt.executeQuery();
        if (rs.next()) totalDonations = rs.getInt(1);
    }

    // *** NEW: Fetch total units received for the user's requests ***
    String requestsSql = "SELECT COUNT(*) FROM appointments a JOIN blood_requests br ON a.request_id = br.id WHERE br.requester_id = ? AND a.status = 'Fulfilled'";
    try (PreparedStatement pstmt = conn.prepareStatement(requestsSql)) {
        pstmt.setInt(1, userId);
        ResultSet rs = pstmt.executeQuery();
        if (rs.next()) {
            totalRequestsFulfilled = rs.getInt(1);
        }
    }

} catch (SQLException e) {
    e.printStackTrace();
}
%>

<!DOCTYPE html>
<html lang="en">
<head>
    <title>Dashboard - LifeFlow</title>
    <script src="https://cdn.tailwindcss.com"></script>
    <link href="https://fonts.googleapis.com/css2?family=Inter:wght@400;500;600;700&display=swap" rel="stylesheet">
    <link rel="icon" href="favicon.ico" type="image/x-icon">
    <link rel="shortcut icon" href="favicon.ico" type="image/x-icon">
</head>
<body class="bg-gray-100 font-sans">
    <!-- Header -->
    <header class="bg-grey-100 shadow-md">
        <nav class="container mx-auto px-6 py-4 flex justify-between items-center">
        <div>
            <img src="images/LifeFlowIcon.jpg" alt="LifeFlow Logo" class="h-10 w-10 rounded-full mr-4 float-left">
            <a href="dashboard.jsp" class="text-2xl font-bold text-red-600">LifeFlow</a>
        </div>
            <div class="flex items-center">
                <span class="text-gray-700 mr-4">Welcome, <%= fullName %>!</span>
                <!-- *** ADDED: View All Requests Link *** -->
                <a href="all_requests.jsp" class="text-sm text-blue-600 hover:underline mr-4">View All Requests</a>
                <a href="edit_profile.jsp" class="text-sm text-blue-600 hover:underline mr-4">Edit Profile</a>
                <a href="logout" class="px-4 py-2 text-white bg-red-600 rounded-full hover:bg-red-700 text-sm">Logout</a>
            </div>
        </nav>
    </header>

    <!-- Main Content -->
    <main class="flex-grow container mx-auto p-6">
        <h1 class="text-3xl font-bold text-gray-800 mb-4">User Dashboard</h1>

        <!-- Summary Section -->
        <div class="grid md:grid-cols-3 gap-6 mb-6">
            <div class="bg-white p-6 rounded-lg shadow text-center">
                <h2 class="text-xl text-gray-700 mb-2">Your Blood Group</h2>
                <p class="text-4xl font-bold text-red-600"><%= userBloodGroup %></p>
            </div>
            <div class="bg-white p-6 rounded-lg shadow text-center">
                <h2 class="text-xl text-gray-700 mb-2">Your Donations Fulfilled</h2>
                <p class="text-4xl font-bold text-red-600"><%= totalDonations %></p>
            </div>
            <!-- *** NEW CARD: Your Requests Fulfilled *** -->
            <div class="bg-white p-6 rounded-lg shadow text-center">
                <h2 class="text-xl text-gray-700 mb-2">Your Requests Fulfilled</h2>
                <p class="text-4xl font-bold text-blue-600"><%= totalRequestsFulfilled %> <span class="text-2xl">units</span></p>
            </div>
        </div>

        <!-- Actions Section -->
        <div class="grid md:grid-cols-2 gap-6 mb-8">
            <!-- Request Blood Card -->
            <div class="bg-white p-8 rounded-lg shadow">
                <h2 class="text-2xl font-bold text-gray-800 mb-4">I Need Blood</h2>
                <p class="text-gray-600 mb-6">Create a public request for blood that will be visible to potential donors.</p>
                <button id="request-blood-btn" class="bg-blue-600 text-white font-bold py-3 px-6 rounded-lg hover:bg-blue-700">Request Blood</button>
            </div>
            <!-- Give Blood Card -->
            <div class="bg-white p-8 rounded-lg shadow">
                <h2 class="text-2xl font-bold text-gray-800 mb-4">I Want to Give Blood</h2>
                <p class="text-gray-600 mb-6">View all available requests that match your blood type and save a life today.</p>
                <button id="give-blood-btn" class="bg-green-600 text-white font-bold py-3 px-6 rounded-lg hover:bg-green-700">Give Blood</button>
            </div>
        </div>

        <!-- My Blood Requests Section -->
        <div class="bg-white p-8 rounded-lg shadow mb-8">
            <h2 class="text-2xl font-bold text-gray-800 mb-4">My Blood Requests</h2>
            <div class="overflow-x-auto">
                <table class="min-w-full bg-white">
                    <thead class="bg-gray-200">
                        <tr>
                            <th class="py-3 px-4 text-left text-sm font-semibold text-gray-600 uppercase">Patient</th>
                            <th class="py-3 px-4 text-left text-sm font-semibold text-gray-600 uppercase">Hospital</th>
                            <th class="py-3 px-4 text-left text-sm font-semibold text-gray-600 uppercase">Blood Group</th>
                            <th class="py-3 px-4 text-left text-sm font-semibold text-gray-600 uppercase">Status</th>
                            <th class="py-3 px-4 text-left text-sm font-semibold text-gray-600 uppercase">Waiting Time</th>
                        </tr>
                    </thead>
                    <tbody class="text-gray-700">
                        <%
                            String myRequestsSql = "SELECT *, TIMESTAMPDIFF(HOUR, request_date, NOW()) as waiting_hours FROM blood_requests WHERE requester_id = ? ORDER BY request_date DESC";
                            try (PreparedStatement pstmt = conn.prepareStatement(myRequestsSql)) {
                                pstmt.setInt(1, userId);
                                ResultSet rs = pstmt.executeQuery();
                                if (!rs.isBeforeFirst() ) {
                                    out.println("<tr><td colspan='5' class='py-4 px-4 text-center text-gray-500'>You have not made any requests yet.</td></tr>");
                                } else {
                                    while (rs.next()) {
                                        long hours = rs.getLong("waiting_hours");
                                        long days = hours / 24;
                                        hours = hours % 24;
                                        String waitingTime = days + "d " + hours + "h";
                        %>
                        <tr class="border-b border-gray-200">
                            <td class="py-3 px-4"><%= rs.getString("patient_name") %></td>
                            <td class="py-3 px-4"><%= rs.getString("hospital_name") %>, <%= rs.getString("hospital_location") %></td>
                            <td class="py-3 px-4"><%= rs.getString("required_blood_group") %></td>
                            <td class="py-3 px-4">
                                <span class="px-2 py-1 text-xs font-semibold rounded-full <%= "Open".equals(rs.getString("status")) ? "bg-yellow-200 text-yellow-800" : "bg-green-200 text-green-800" %>">
                                    <%= rs.getString("status") %> (<%= rs.getInt("units_required") %> units left)
                                </span>
                            </td>
                            <td class="py-3 px-4"><%= waitingTime %></td>
                        </tr>
                        <%
                                    }
                                }
                            } catch (SQLException e) {
                                e.printStackTrace();
                            }
                        %>
                    </tbody>
                </table>
            </div>
        </div>

        <!-- Scheduled Appointments for My Requests Section -->
        <div class="bg-white p-8 rounded-lg shadow">
            <h2 class="text-2xl font-bold text-gray-800 mb-4">Scheduled Donations for Your Requests</h2>
            <div class="overflow-x-auto">
                <table class="min-w-full bg-white">
                    <thead class="bg-gray-200">
                        <tr>
                            <th class="py-3 px-4 text-left text-sm font-semibold text-gray-600 uppercase">Donor Name</th>
                            <th class="py-3 px-4 text-left text-sm font-semibold text-gray-600 uppercase">For Patient</th>
                            <th class="py-3 px-4 text-left text-sm font-semibold text-gray-600 uppercase">Appointment Date</th>
                            <th class="py-3 px-4 text-left text-sm font-semibold text-gray-600 uppercase">Status</th>
                            <th class="py-3 px-4 text-left text-sm font-semibold text-gray-600 uppercase">Action</th>
                        </tr>
                    </thead>
                     <tbody class="text-gray-700">
                        <%
                            String appointmentsSql = "SELECT a.id, a.request_id, u.fullName AS donor_name, br.patient_name, a.appointment_date, a.status FROM appointments a JOIN users u ON a.donor_id = u.id JOIN blood_requests br ON a.request_id = br.id WHERE br.requester_id = ? ORDER BY a.appointment_date DESC";
                            try (PreparedStatement pstmt = conn.prepareStatement(appointmentsSql)) {
                                pstmt.setInt(1, userId);
                                ResultSet rs = pstmt.executeQuery();
                                if (!rs.isBeforeFirst()) {
                                    out.println("<tr><td colspan='5' class='py-4 px-4 text-center text-gray-500'>No donors have scheduled an appointment for your requests yet.</td></tr>");
                                } else {
                                    while (rs.next()) {
                        %>
                        <tr class="border-b border-gray-200">
                            <td class="py-3 px-4"><%= rs.getString("donor_name") %></td>
                            <td class="py-3 px-4"><%= rs.getString("patient_name") %></td>
                            <td class="py-3 px-4"><%= new SimpleDateFormat("dd MMM, yyyy").format(rs.getDate("appointment_date")) %></td>
                            <td class="py-3 px-4">
                                <span class="px-2 py-1 text-xs font-semibold rounded-full <%= "Scheduled".equals(rs.getString("status")) ? "bg-yellow-200 text-yellow-800" : "bg-green-200 text-green-800" %>">
                                    <%= rs.getString("status") %>
                                </span>
                            </td>
                            <td class="py-3 px-4">
                                <% if ("Scheduled".equals(rs.getString("status"))) { %>
                                    <form action="markFulfilled" method="POST" class="inline">
                                        <input type="hidden" name="appointmentId" value="<%= rs.getInt("id") %>">
                                        <input type="hidden" name="requestId" value="<%= rs.getInt("request_id") %>">
                                        <button type="submit" class="bg-green-500 text-white px-3 py-1 rounded text-sm hover:bg-green-600">Mark as Fulfilled</button>
                                    </form>
                                <% } %>
                            </td>
                        </tr>
                        <%
                                    }
                                }
                            } catch (SQLException e) {
                                e.printStackTrace();
                            }
                        %>
                    </tbody>
                </table>
            </div>
        </div>
    </main>

    <!-- MODALS -->
    <!-- Request Blood Modal -->
    <div id="request-blood-modal" class="hidden fixed inset-0 bg-gray-800 bg-opacity-75 flex items-center justify-center z-50">
        <div class="bg-white p-8 rounded-lg shadow-xl w-full max-w-lg">
            <h2 class="text-2xl font-bold mb-4">Create Blood Request</h2>
            <form action="createRequest" method="POST" class="space-y-4">
                <input type="text" name="patient_name" placeholder="Patient's Full Name" required class="w-full p-2 border rounded">
                <select name="required_blood_group" class="w-full p-2 border rounded">
                    <option>A+</option><option>A-</option><option>B+</option><option>B-</option>
                    <option>AB+</option><option>AB-</option><option>O+</option><option>O-</option>
                </select>
                <input type="number" name="units_required" placeholder="Units Required" required class="w-full p-2 border rounded">
                <input type="text" name="hospital_name" placeholder="Hospital Name" required class="w-full p-2 border rounded">
                <input type="text" name="hospital_location" placeholder="Hospital Location (City)" required class="w-full p-2 border rounded">
                <input type="text" name="contact_person" placeholder="Contact Person" required class="w-full p-2 border rounded">
                <input type="tel" name="contact_phone" placeholder="Contact Phone" required class="w-full p-2 border rounded">
                <div class="flex justify-end space-x-4 pt-4">
                    <button type="button" class="modal-close-btn px-4 py-2 bg-gray-300 rounded">Cancel</button>
                    <button type="submit" class="px-4 py-2 bg-blue-600 text-white rounded">Submit Request</button>
                </div>
            </form>
        </div>
    </div>

    <!-- Give Blood (Available Requests) Modal -->
    <div id="give-blood-modal" class="hidden fixed inset-0 bg-gray-800 bg-opacity-75 flex items-center justify-center z-50">
        <div class="bg-white p-8 rounded-lg shadow-xl w-full max-w-3xl">
            <h2 class="text-2xl font-bold mb-4">Available Requests Matching Your Blood Type (<%= userBloodGroup %>)</h2>
            <div id="requests-container" class="max-h-96 overflow-y-auto">
                <!-- AJAX content will be loaded here -->
            </div>
            <div class="flex justify-end mt-4">
                <button type="button" class="modal-close-btn px-4 py-2 bg-gray-300 rounded">Close</button>
            </div>
        </div>
    </div>

    <!-- *** NEW: Schedule Appointment Modal *** -->
    <div id="schedule-modal" class="hidden fixed inset-0 bg-gray-800 bg-opacity-75 flex items-center justify-center z-50">
        <div class="bg-white p-8 rounded-lg shadow-xl w-full max-w-sm">
            <h2 class="text-2xl font-bold mb-4">Schedule Your Donation</h2>
            <form id="schedule-form" class="space-y-4">
                <input type="hidden" id="schedule-request-id">
                <div>
                    <label for="appointment-date" class="block text-sm font-medium text-gray-700">Select a Date:</label>
                    <input type="date" id="appointment-date" name="appointmentDate" class="mt-1 block w-full px-3 py-2 border border-gray-300 rounded-md shadow-sm focus:outline-none focus:ring-red-500 focus:border-red-500" required>
                </div>
                <div class="flex justify-end space-x-4 pt-4">
                    <button type="button" class="modal-close-btn px-4 py-2 bg-gray-300 rounded">Cancel</button>
                    <button type="submit" class="px-4 py-2 bg-green-600 text-white rounded">Confirm Appointment</button>
                </div>
            </form>
        </div>
    </div>

    <% if (conn != null) try { conn.close(); } catch (SQLException e) { e.printStackTrace(); } %>

<script>
document.addEventListener('DOMContentLoaded', function() {
    const requestBloodModal = document.getElementById('request-blood-modal');
    const giveBloodModal = document.getElementById('give-blood-modal');
    const scheduleModal = document.getElementById('schedule-modal');

    const openModal = (modal) => modal.classList.remove('hidden');
    const closeModal = (modal) => {
        if(modal) modal.classList.add('hidden');
    };

    // Event listeners for opening modals
    document.getElementById('request-blood-btn')?.addEventListener('click', () => openModal(requestBloodModal));
    document.getElementById('give-blood-btn')?.addEventListener('click', () => {
        fetch('getMatchingRequests')
            .then(response => response.json())
            .then(data => {
                const container = document.getElementById('requests-container');
                container.innerHTML = '';
                if (data.length === 0) {
                    container.innerHTML = '<p>No open requests currently match your blood type. Thank you for checking!</p>';
                } else {
                    const table = document.createElement('table');
                    table.className = 'min-w-full';
                    table.innerHTML = `<thead class="bg-gray-200"><tr><th class="py-2 px-4 text-left">Hospital</th><th class="py-2 px-4 text-left">Location</th><th class="py-2 px-4 text-left">Units Needed</th><th class="py-2 px-4 text-left">Action</th></tr></thead>`;
                    const tbody = document.createElement('tbody');
                    data.forEach(req => {
                        const row = document.createElement('tr');
                        row.className = 'border-b';
                        row.innerHTML = `<td class="py-2 px-4">${req.hospital_name}</td><td class="py-2 px-4">${req.hospital_location}</td><td class="py-2 px-4">${req.units_required}</td><td class="py-2 px-4"><button class="schedule-btn bg-blue-500 text-white px-3 py-1 rounded text-sm" data-request-id="${req.id}">Schedule</button></td>`;
                        tbody.appendChild(row);
                    });
                    table.appendChild(tbody);
                    container.appendChild(table);
                }
                openModal(giveBloodModal);
            });
    });

    // Event listeners for closing modals
    document.querySelectorAll('.modal-close-btn').forEach(btn => {
        btn.addEventListener('click', () => {
            closeModal(requestBloodModal);
            closeModal(giveBloodModal);
            closeModal(scheduleModal);
        });
    });

    // Handle "Schedule" button click inside the "Give Blood" modal
    document.getElementById('requests-container').addEventListener('click', function(e) {
        if (e.target.classList.contains('schedule-btn')) {
            const requestId = e.target.dataset.requestId;
            document.getElementById('schedule-request-id').value = requestId;
            openModal(scheduleModal);
        }
    });

    // Handle the submission of the new schedule form
    document.getElementById('schedule-form')?.addEventListener('submit', function(e) {
        e.preventDefault();
        const requestId = document.getElementById('schedule-request-id').value;
        const appointmentDate = document.getElementById('appointment-date').value;

        if (appointmentDate) {
            const formData = new FormData();
            formData.append('requestId', requestId);
            formData.append('appointmentDate', appointmentDate);

            fetch('scheduleAppointment', { method: 'POST', body: new URLSearchParams(formData) })
                .then(response => {
                    if (response.ok) {
                        alert('Appointment scheduled successfully! Thank you.');
                        closeModal(scheduleModal);
                        closeModal(giveBloodModal);
                    } else {
                        alert('Error: Could not schedule appointment.');
                    }
                });
        }
    });
});
</script>
</body>
</html>
