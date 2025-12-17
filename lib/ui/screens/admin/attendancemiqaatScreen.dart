import 'package:burhaniguardsapp/ui/widgets/adminBottomNavigationBar.dart';
import 'package:burhaniguardsapp/core/services/miqaat_service.dart';
import 'package:burhaniguardsapp/core/services/local_storage_service.dart';
import 'package:burhaniguardsapp/ui/screens/admin/adminDashboard.dart';
import 'package:flutter/material.dart';

class AttendanceMiqaatScreen extends StatefulWidget {
  final String? initialFilter;

  const AttendanceMiqaatScreen({Key? key, this.initialFilter})
      : super(key: key);

  @override
  State<AttendanceMiqaatScreen> createState() => _AttendanceMiqaatScreenState();
}

class _AttendanceMiqaatScreenState extends State<AttendanceMiqaatScreen> {
  late String selectedFilter;

  final MiqaatService _miqaatService = MiqaatService();
  final LocalStorageService _localStorage = LocalStorageService();
  List<Miqaat> _miqaats = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    selectedFilter = widget.initialFilter ?? 'Miqaats';
    _loadMiqaats();

    // Show development message if opened with Attendance History filter
    if (widget.initialFilter == 'Attendance History') {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showDevelopmentMessage(context);
        // Switch back to Miqaats after showing message
        setState(() {
          selectedFilter = 'Miqaats';
        });
      });
    }
  }

  Future<void> _loadMiqaats() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final user = await _localStorage.getUserData();
      final miqaats = await _miqaatService.getAllMiqaats();

      // If member (not captain), show only miqaats of their jamaat
      List<Miqaat> filtered = miqaats;
      if (user != null && user.roles != 2 && user.jamaat != null) {
        final userJamaat = user.jamaat!.toLowerCase();
        filtered = miqaats
            .where((m) => (m.jamaat).toLowerCase() == userJamaat)
            .toList();
      }

      setState(() {
        _miqaats = filtered;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString().replaceAll('Exception: ', '');
        _isLoading = false;
      });
    }
  }

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

  void _handleBackNavigation(BuildContext context) {
    // Always navigate to Dashboard to prevent going back to CreateMiqaatScreen
    // This ensures proper navigation flow after creating a miqaat
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const AdminDashboardScreen()),
    );
  }

  void _showDevelopmentMessage(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Under Development'),
        content: const Text('This page is under development.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvoked: (bool didPop) {
        if (!didPop) {
          _handleBackNavigation(context);
        }
      },
      child: Scaffold(
        body: Column(
          children: [
            // Custom AppBar with curved bottom
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
              decoration: const BoxDecoration(
                color: Color(0xFF4A1C1C),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(20),
                  bottomRight: Radius.circular(20),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back,
                        color: Colors.white, size: 28),
                    onPressed: () {
                      _handleBackNavigation(context);
                    },
                  ),
                  Image.asset('assets/images/burhani guards logo.png',
                      height: 52),
                  IconButton(
                    icon: const Icon(Icons.notifications_outlined,
                        color: Colors.white, size: 28),
                    onPressed: () {},
                  ),
                ],
              ),
            ),

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
                        child: _isLoading
                            ? const Center(
                                child: CircularProgressIndicator(),
                              )
                            : _errorMessage != null
                                ? Center(
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Text(
                                          _errorMessage!,
                                          style: const TextStyle(
                                            color: Colors.red,
                                            fontSize: 14,
                                          ),
                                          textAlign: TextAlign.center,
                                        ),
                                        const SizedBox(height: 16),
                                        ElevatedButton(
                                          onPressed: _loadMiqaats,
                                          child: const Text('Retry'),
                                        ),
                                      ],
                                    ),
                                  )
                                : _miqaats.isEmpty
                                    ? const Center(
                                        child: Text(
                                          'No miqaats found',
                                          style: TextStyle(
                                            fontSize: 16,
                                            color: Colors.grey,
                                          ),
                                        ),
                                      )
                                    : RefreshIndicator(
                                        onRefresh: _loadMiqaats,
                                        child: ListView.builder(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 20),
                                          itemCount: _miqaats.length,
                                          itemBuilder: (context, index) {
                                            return _buildMiqaatCard(
                                                _miqaats[index]);
                                          },
                                        ),
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
      ),
    );
  }

  Widget _buildFilterChip(String label) {
    final isSelected = selectedFilter == label;
    return GestureDetector(
      onTap: () {
        if (label == 'Attendance History') {
          // Show development message for Attendance History
          _showDevelopmentMessage(context);
        } else {
          setState(() {
            selectedFilter = label;
          });
        }
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

  String _formatDate(DateTime date) {
    final months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec'
    ];
    final day = date.day.toString().padLeft(2, '0');
    final month = months[date.month - 1];
    final year = date.year;
    return '$day $month $year';
  }

  Widget _buildMiqaatCard(Miqaat miqaat) {
    // Format date for display
    final fromDateStr = _formatDate(miqaat.fromDate);
    final tillDateStr = _formatDate(miqaat.tillDate);
    final dateDisplay = fromDateStr == tillDateStr
        ? fromDateStr
        : '$fromDateStr - $tillDateStr';

    // Get approval status color
    Color statusColor;
    String statusText;
    switch (miqaat.adminApproval.toLowerCase()) {
      case 'approved':
        statusColor = Colors.green;
        statusText = 'Approved';
        break;
      case 'rejected':
        statusColor = Colors.red;
        statusText = 'Rejected';
        break;
      default:
        statusColor = Colors.orange;
        statusText = 'Pending';
    }

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
                  dateDisplay,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                // Title
                Text(
                  miqaat.miqaatName,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 4),
                // Location (Jamaat)
                Row(
                  children: [
                    const Icon(
                      Icons.location_on,
                      size: 16,
                      color: Colors.orange,
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        miqaat.jamaat,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                // Jamiyat
                Text(
                  miqaat.jamiyat,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[500],
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          ),

          // Right side - Status badge
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: statusColor,
              shape: BoxShape.circle,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  miqaat.volunteerLimit.toString(),
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  statusText,
                  style: const TextStyle(
                    fontSize: 10,
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
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
