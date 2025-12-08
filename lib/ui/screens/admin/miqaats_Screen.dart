import 'package:burhaniguardsapp/ui/screens/admin/membersListScreen.dart';
import 'package:burhaniguardsapp/ui/widgets/adminAppBarforPages.dart';
import 'package:burhaniguardsapp/ui/widgets/adminBottomNavigationBar.dart';
import 'package:flutter/material.dart';

class MiqaatScreen extends StatefulWidget {
  const MiqaatScreen({Key? key}) : super(key: key);

  @override
  State<MiqaatScreen> createState() => _MiqaatScreenState();
}

class _MiqaatScreenState extends State<MiqaatScreen> {
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
                      'Miqaat\'s',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Colors.black,
                      ),
                    ),
                  ),

                  // Miqaat Cards List
                  Expanded(
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 24),
                          _buildMiqaatSection(),
                          const SizedBox(height: 100),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: const CustomBottomNavBarCaptain(),
    );
  }

  Widget _buildMiqaatSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildMiqaatCard(
            title: 'Eid E Milood Un Nabi',
            dateRange: 'ENROLLED FROM 2ND OCT - 9TH OCT 2023',
            location: 'Mumbai, Santa Cruz',
          ),
          const SizedBox(height: 12),
          _buildMiqaatCard(
            title: 'Eid E Milood Un Nabi',
            dateRange: 'ENROLLED FROM 2ND OCT - 9TH OCT 2023',
            location: 'Mumbai, Santa Cruz',
          ),
        ],
      ),
    );
  }

  Widget _buildMiqaatCard({
    required String title,
    required String dateRange,
    required String location,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF3E0),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        dateRange,
                        style: const TextStyle(
                          fontSize: 9,
                          color: Color(0xFFE65100),
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFD97706),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.settings,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF333333),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(
                      Icons.location_on,
                      size: 16,
                      color: Color(0xFF666666),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      location,
                      style: const TextStyle(
                        fontSize: 13,
                        color: Color(0xFF666666),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: const BoxDecoration(
              color: Color(0xFF4A1C1C),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(18),
                bottomRight: Radius.circular(18),
              ),
            ),
            child: InkWell(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const MembersListScreen()),
                  );
                },
                child: Text(
                  'Check Members List',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                )),
          ),
        ],
      ),
    );
  }
}
