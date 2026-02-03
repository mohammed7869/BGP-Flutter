import 'package:burhaniguardsapp/ui/widgets/adminBottomNavigationBar.dart';
import 'package:burhaniguardsapp/core/services/miqaat_service.dart';
import 'package:burhaniguardsapp/core/services/local_storage_service.dart';
import 'package:burhaniguardsapp/ui/screens/admin/adminDashboard.dart';
import 'package:burhaniguardsapp/ui/screens/admin/miqaatAttendanceScreen.dart';
import 'package:burhaniguardsapp/ui/screens/admin/memberMiqaatHistoryScreen.dart';
import 'package:flutter/material.dart';

class AttendanceMiqaatScreen extends StatefulWidget {
  final String? initialFilter;

  const AttendanceMiqaatScreen({Key? key, this.initialFilter})
      : super(key: key);

  @override
  State<AttendanceMiqaatScreen> createState() => _AttendanceMiqaatScreenState();
}

class _AttendanceMiqaatScreenState extends State<AttendanceMiqaatScreen> {
  bool _isCaptain = false;

  final MiqaatService _miqaatService = MiqaatService();
  final LocalStorageService _localStorage = LocalStorageService();
  List<Miqaat> _miqaats = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadMiqaats();
  }

  Future<void> _loadMiqaats() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final user = await _localStorage.getUserData();
      final miqaats = await _miqaatService.getAllMiqaats();
      final isCaptain = user != null && user.roles == 2;

      // Show only miqaats of the logged-in user's jamaat (for both members and captains)
      List<Miqaat> filtered = miqaats;
      if (user != null && user.jamaat != null) {
        final userJamaat = user.jamaat!.toLowerCase();
        filtered = miqaats
            .where((m) => (m.jamaat).toLowerCase() == userJamaat)
            .toList();
      }

      setState(() {
        _miqaats = filtered;
        _isCaptain = isCaptain;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString().replaceAll('Exception: ', '');
        _isLoading = false;
        _isCaptain = false;
      });
    }
  }

  void _handleBackNavigation(BuildContext context) {
    // Always navigate to Dashboard to prevent going back to CreateMiqaatScreen
    // This ensures proper navigation flow after creating a miqaat
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const AdminDashboardScreen()),
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
                                              _miqaats[index], context);
                                        },
                                      ),
                                    ),
                    )
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

  Widget _buildMiqaatCard(Miqaat miqaat, BuildContext context) {
    // Format date for display
    final fromDateStr = _formatDate(miqaat.fromDate);
    final tillDateStr = _formatDate(miqaat.tillDate);
    final dateDisplay = fromDateStr == tillDateStr
        ? fromDateStr
        : '$fromDateStr - $tillDateStr';
    final durationDisplay = '${miqaat.durationLabel}';

    // Get approval status style (captains only)
    String statusText = 'Pending';
    Color backgroundColor = const Color(0xFFFFF3E0);
    Color textColor = const Color(0xFFE65100);
    if (miqaat.adminApproval.toLowerCase() == 'approved') {
      statusText = 'Approved';
      backgroundColor = Colors.green;
      textColor = Colors.white;
    } else if (miqaat.adminApproval.toLowerCase() == 'rejected') {
      statusText = 'Rejected';
      backgroundColor = Colors.red;
      textColor = Colors.white;
    }

    return GestureDetector(
      onTap: () async {
        final user = await _localStorage.getUserData();
        if (user == null) return;

        if (user.roles == 2 &&
            miqaat.adminApproval.toLowerCase() == 'approved') {
          // Navigate to attendance marking screen (Captain)
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => MiqaatAttendanceScreen(miqaat: miqaat),
            ),
          );
        } else if (user.roles != 2) {
          // Navigate to member history screen (Member)
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => MemberMiqaatHistoryScreen(
                memberId: user.id,
                fullName: user.fullName,
                itsId: user.itsId,
                miqaatId: miqaat.id,
              ),
            ),
          );
        }
      },
      child: Container(
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
                    '$dateDisplay • $durationDisplay',
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
                          _isCaptain
                              ? '${miqaat.jamaat} (${miqaat.jamiyat})'
                              : miqaat.jamaat,
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
                  if (!_isCaptain) ...[
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
                  if (_isCaptain) ...[
                    const SizedBox(height: 6),
                    Text(
                      'Volunteer Limit: ${miqaat.volunteerLimit}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (_isCaptain)
              Padding(
                padding: const EdgeInsets.only(left: 12, top: 2),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: backgroundColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    statusText,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: textColor,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

}
