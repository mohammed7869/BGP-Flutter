import 'package:burhaniguardsapp/ui/screens/admin/membersListScreen.dart';
import 'package:burhaniguardsapp/ui/widgets/adminAppBarforPages.dart';
import 'package:burhaniguardsapp/ui/widgets/adminBottomNavigationBar.dart';
import 'package:burhaniguardsapp/ui/widgets/memberBottomNavigationBar.dart';
import 'package:flutter/material.dart';

class EnrolledMiqaatScreen extends StatefulWidget {
  const EnrolledMiqaatScreen({Key? key}) : super(key: key);

  @override
  State<EnrolledMiqaatScreen> createState() => _EnrolledMiqaatScreenState();
}

class _EnrolledMiqaatScreenState extends State<EnrolledMiqaatScreen> {
  int _selectedIndex = 0;
  String selectedFilter = 'Enrolled Miqaats';
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
                  // const Padding(
                  //   padding: EdgeInsets.all(20),
                  //   child: Text(
                  //     'Enrolled Miqaat\'s',
                  //     style: TextStyle(
                  //       fontSize: 18,
                  //       fontWeight: FontWeight.w600,
                  //       color: Colors.black,
                  //     ),
                  //   ),
                  // ),

                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 10),
                    child: Row(
                      children: [
                        _buildFilterChip('Enrolled Miqaats'),
                        const SizedBox(width: 8),
                        _buildFilterChip('Saved Miqaats'),
                        // const SizedBox(width: 8),
                        // _buildFilterChip('Rejected'),
                        // const SizedBox(width: 8),
                        // _buildFilterChip('Pending'),
                      ],
                    ),
                  ),

                  // Miqaat Cards List
                  Expanded(
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 24),
                          if (selectedFilter == 'Enrolled Miqaats') ...[
                            _buildMiqaatSection(),
                          ],
                          if (selectedFilter == 'Saved Miqaats') ...[
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 20),
                              child: Column(
                                children: [
                                  _buildSavedMiqaatCard(
                                    '1ST MAY- SAT -2:00 PM',
                                    'Urs Mubarak',
                                    'Ayyam',
                                    'Mumbai, Santa Cruz',
                                  ),
                                  _buildSavedMiqaatCard(
                                    '1ST MAY- SAT -2:00 PM',
                                    'Urs Mubarak',
                                    'Ayyam',
                                    'Mumbai, Santa Cruz',
                                  ),
                                  _buildSavedMiqaatCard(
                                    '1ST MAY- SAT -2:00 PM',
                                    'Women\'s leadership',
                                    'Ayyam',
                                    'Mumbai, Santa Cruz',
                                  ),
                                  _buildSavedMiqaatCard(
                                    '1ST MAY- SAT -2:00 PM',
                                    'Urs Mubarak',
                                    'Ayyam',
                                    'Mumbai, Santa Cruz',
                                  ),
                                ],
                              ),
                            ),
                          ],
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
      bottomNavigationBar: const CustomBottomNavBarMember(),
    );
  }

  Widget _buildMiqaatSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildMiqaatCard(
            title: 'Urs Mubarak Ayyam',
            dateRange: 'ENROLLED FROM 2ND OCT - 9TH OCT 2023',
            location: 'Mumbai, Santa Cruz',
          ),
          const SizedBox(height: 12),
          _buildMiqaatCard(
            title: 'Urs Mubarak Ayyam',
            dateRange: 'ENROLLED FROM 2ND OCT - 9TH OCT 2023',
            location: 'Mumbai, Santa Cruz',
          ),
          _buildMiqaatCard(
            title: 'Urs Mubarak Ayyam',
            dateRange: 'ENROLLED FROM 2ND OCT - 9TH OCT 2023',
            location: 'Mumbai, Santa Cruz',
          ),
          const SizedBox(height: 12),
          _buildMiqaatCard(
            title: 'Urs Mubarak Ayyam',
            dateRange: 'ENROLLED FROM 2ND OCT - 9TH OCT 2023',
            location: 'Mumbai, Santa Cruz',
          ),
          _buildMiqaatCard(
            title: 'Urs Mubarak Ayyam',
            dateRange: 'ENROLLED FROM 2ND OCT - 9TH OCT 2023',
            location: 'Mumbai, Santa Cruz',
          ),
          const SizedBox(height: 12),
          _buildMiqaatCard(
            title: 'Urs Mubarak Ayyam',
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
                  'Contact Admin',
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

  Widget _buildSavedMiqaatCard(
    String date,
    String title,
    String subtitle,
    String location,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!, width: 1),
      ),
      child: Row(
        children: [
          // Left side - Event details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Date
                Text(
                  date,
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 6),
                // Title
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                if (subtitle.isNotEmpty) ...[
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.black,
                    ),
                  ),
                ],
                if (location.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  // Location
                  Row(
                    children: [
                      const Icon(
                        Icons.location_on,
                        size: 14,
                        color: Colors.orange,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        location,
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),

          // Right side - Bookmark icon
          const Icon(
            Icons.bookmark,
            color: Colors.orange,
            size: 24,
          ),
        ],
      ),
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
}
