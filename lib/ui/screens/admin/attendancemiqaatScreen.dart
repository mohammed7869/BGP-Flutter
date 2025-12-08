import 'package:burhaniguardsapp/ui/widgets/adminAppBarforPages.dart';
import 'package:burhaniguardsapp/ui/widgets/adminBottomNavigationBar.dart';
import 'package:flutter/material.dart';

class AttendanceMiqaatScreen extends StatefulWidget {
  const AttendanceMiqaatScreen({Key? key}) : super(key: key);

  @override
  State<AttendanceMiqaatScreen> createState() => _AttendanceMiqaatScreenState();
}

class _AttendanceMiqaatScreenState extends State<AttendanceMiqaatScreen> {
  int _selectedIndex = 0;
  String selectedFilter = 'Miqaats';

  final List<Map<String, dynamic>> miqaats = [
    {
      'date': '1ST MAY- SAT -2:00 PM',
      'title': 'Urs Mubarak',
      'subtitle': 'Ayyam',
      'location': 'Mumbai, Santa Cruz',
      'approved': 50,
    },
    {
      'date': '1ST MAY- SAT -2:00 PM',
      'title': 'Urs Mubarak',
      'subtitle': 'Ayyam',
      'location': 'Mumbai, Santa Cruz',
      'approved': 50,
    },
    {
      'date': '1ST MAY- SAT -2:00 PM',
      'title': 'Urs Mubarak',
      'subtitle': 'Ayyam',
      'location': 'Mumbai, Santa Cruz',
      'approved': 50,
    },
    {
      'date': '1ST MAY- SAT -2:00 PM',
      'title': 'Urs Mubarak',
      'subtitle': 'Ayyam',
      'location': 'Mumbai, Santa Cruz',
      'approved': 50,
    },
  ];

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
      body: Column(
        children: [
          // Custom AppBar with curved bottom
          buildAppBarWithBackButton(context),

          // Content
          Expanded(
            child: Container(
              color: Colors.white,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.all(20),
                    child: Text(
                      'Attendance / Miqaat\'s',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Colors.black,
                      ),
                    ),
                  ),

                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Row(
                      children: [
                        _buildFilterChip('Miqaats'),
                        const SizedBox(width: 8),
                        _buildFilterChip('Attendance History'),
                        // const SizedBox(width: 8),
                        // _buildFilterChip('Rejected'),
                        // const SizedBox(width: 8),
                        // _buildFilterChip('Pending'),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  // Miqaat Cards List

                  if (selectedFilter == 'Miqaats') ...[
                    Expanded(
                      child: ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        itemCount: miqaats.length,
                        itemBuilder: (context, index) {
                          return _buildMiqaatCard(miqaats[index]);
                        },
                      ),
                    ),
                  ],

                  if (selectedFilter == 'Attendance History') ...[
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
                  ]
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: const CustomBottomNavBarCaptain(),
    );
  }

  Widget _buildFilterChip(String label) {
    final isSelected = selectedFilter == label;
    return GestureDetector(
      onTap: () {
        setState(() {
          selectedFilter = label;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF4A1C1C) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: const Color(0xFF4A1C1C),
            width: 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.black,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _buildMiqaatCard(Map<String, dynamic> miqaat) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!, width: 1),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Left side - Event details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Date
                Text(
                  miqaat['date'],
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                // Title
                Text(
                  miqaat['title'],
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                // Subtitle
                Text(
                  miqaat['subtitle'],
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 8),
                // Location
                Row(
                  children: [
                    const Icon(
                      Icons.location_on,
                      size: 16,
                      color: Colors.orange,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      miqaat['location'],
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Right side - Approved badge
          Container(
            padding: const EdgeInsets.all(12),
            decoration: const BoxDecoration(
              color: Colors.orange,
              shape: BoxShape.circle,
            ),
            child: Column(
              children: [
                Text(
                  miqaat['approved'].toString(),
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const Text(
                  'Approved',
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
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
