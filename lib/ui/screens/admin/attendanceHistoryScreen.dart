import 'package:flutter/material.dart';

class AttendanceHistoryScreen extends StatefulWidget {
  const AttendanceHistoryScreen({Key? key}) : super(key: key);

  @override
  State<AttendanceHistoryScreen> createState() =>
      _AttendanceHistoryScreenState();
}

class _AttendanceHistoryScreenState extends State<AttendanceHistoryScreen> {
  final List<Map<String, dynamic>> attendanceHistory = [
    {
      'dateRange': 'ENROLLED FROM 2ND OCT - 9TH OCT 2023',
      'eventName': 'Urs Mubarak Ayyam',
      'totalEnrolled': 1000,
      'totalApproved': 500,
      'totalPresent': 480,
      'absentCount': 50,
    },
    {
      'dateRange': 'ENROLLED FROM 2ND OCT - 9TH OCT 2023',
      'eventName': 'Urs Mubarak Ayyam',
      'totalEnrolled': 1000,
      'totalApproved': 500,
      'totalPresent': 480,
      'absentCount': 50,
    },
    {
      'dateRange': 'ENROLLED FROM 2ND OCT - 9TH OCT 2023',
      'eventName': 'Urs Mubarak Ayyam',
      'totalEnrolled': 1000,
      'totalApproved': 500,
      'totalPresent': 480,
      'absentCount': 50,
    },
    {
      'dateRange': 'ENROLLED FROM 2ND OCT - 9TH OCT 2023',
      'eventName': 'Urs Mubarak Ayyam',
      'totalEnrolled': 1000,
      'totalApproved': 500,
      'totalPresent': 480,
      'absentCount': 50,
    },
    {
      'dateRange': 'ENROLLED FROM 2ND OCT - 9TH OCT 2023',
      'eventName': 'Urs Mubarak Ayyam',
      'totalEnrolled': 1000,
      'totalApproved': 500,
      'totalPresent': 480,
      'absentCount': 50,
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: Column(
        children: [
          // Custom AppBar with curved bottom
          Container(
            decoration: const BoxDecoration(
              color: Color(0xFF4A1C1C),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(30),
                bottomRight: Radius.circular(30),
              ),
            ),
            child: SafeArea(
              bottom: false,
              child: Column(
                children: [
                  // Header with back, logo, and notification
                  Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        IconButton(
                          icon:
                              const Icon(Icons.arrow_back, color: Colors.white),
                          onPressed: () => Navigator.pop(context),
                        ),
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.business_center,
                            color: Color(0xFF4A1C1C),
                            size: 24,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.notifications_outlined,
                              color: Colors.white),
                          onPressed: () {},
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),

          // Content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.all(20),
                  child: Text(
                    'Attendance History',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                ),

                // Attendance History List
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    itemCount: attendanceHistory.length,
                    itemBuilder: (context, index) {
                      final item = attendanceHistory[index];
                      return _buildAttendanceCard(
                        dateRange: item['dateRange'],
                        eventName: item['eventName'],
                        totalEnrolled: item['totalEnrolled'],
                        totalApproved: item['totalApproved'],
                        totalPresent: item['totalPresent'],
                        absentCount: item['absentCount'],
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAttendanceCard({
    required String dateRange,
    required String eventName,
    required int totalEnrolled,
    required int totalApproved,
    required int totalPresent,
    required int absentCount,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Left side - Event details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Date Range
                Text(
                  dateRange,
                  style: const TextStyle(
                    fontSize: 11,
                    color: Colors.orange,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 8),

                // Event Name
                Text(
                  eventName,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 12),

                // Statistics
                _buildStatRow('Total People Enrolled', totalEnrolled),
                const SizedBox(height: 6),
                _buildStatRow('Total People Approved', totalApproved),
                const SizedBox(height: 6),
                _buildStatRow('Total People Present', totalPresent),
              ],
            ),
          ),

          const SizedBox(width: 16),

          // Right side - Absent badge
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: Colors.orange,
              shape: BoxShape.circle,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  absentCount.toString(),
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 2),
                const Text(
                  'Absent',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatRow(String label, int value) {
    return Row(
      children: [
        Text(
          '$label - ',
          style: TextStyle(
            fontSize: 13,
            color: Colors.grey[700],
            fontWeight: FontWeight.w500,
          ),
        ),
        Text(
          value.toString(),
          style: const TextStyle(
            fontSize: 13,
            color: Colors.black,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
