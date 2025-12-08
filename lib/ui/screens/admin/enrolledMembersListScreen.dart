import 'package:burhaniguardsapp/ui/widgets/adminAppBarforPages.dart';
import 'package:flutter/material.dart';

class EnrolledMembersListScreen extends StatefulWidget {
  const EnrolledMembersListScreen({Key? key}) : super(key: key);

  @override
  State<EnrolledMembersListScreen> createState() =>
      _EnrolledMembersListScreenState();
}

class _EnrolledMembersListScreenState extends State<EnrolledMembersListScreen> {
  String selectedFilter = 'All';

  final List<Map<String, dynamic>> members = [
    {
      'name': 'Hatim Ghadiyali',
      'status': 'Approved',
      'image': 'assets/avatar.png'
    },
    {
      'name': 'Henry Itondo',
      'status': 'Rejected',
      'image': 'assets/avatar.png'
    },
    {
      'name': 'Henry Itondo',
      'status': 'Approved',
      'image': 'assets/avatar.png'
    },
    {
      'name': 'Henry Itondo',
      'status': 'Approved',
      'image': 'assets/avatar.png'
    },
    {
      'name': 'Henry Itondo',
      'status': 'Approved',
      'image': 'assets/avatar.png'
    },
    {
      'name': 'Henry Itondo',
      'status': 'Approved',
      'image': 'assets/avatar.png'
    },
    {
      'name': 'Henry Itondo',
      'status': 'Approved',
      'image': 'assets/avatar.png'
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          // Custom AppBar with curved bottom
          buildAppBarWithBackButton(context),

          // Members List Content
          Expanded(
            child: Container(
              color: Colors.white,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.all(20),
                    child: Text(
                      'Members List',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                  ),

                  // Filter Chips
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Row(
                      children: [
                        _buildFilterChip('All'),
                        const SizedBox(width: 8),
                        _buildFilterChip('Accepted'),
                        const SizedBox(width: 8),
                        _buildFilterChip('Rejected'),
                        const SizedBox(width: 8),
                        _buildFilterChip('Pending'),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Members List
                  Expanded(
                    child: ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      itemCount: members.length,
                      itemBuilder: (context, index) {
                        return _buildMemberCard(
                          index + 1,
                          members[index]['name'],
                          members[index]['status'],
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
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

  Widget _buildMemberCard(int number, String name, String status) {
    final isRejected = status == 'Rejected';
    final statusColor = isRejected ? Colors.red : Colors.green;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!, width: 1),
      ),
      child: Row(
        children: [
          // Number
          Text(
            number.toString().padLeft(2, '0'),
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          const SizedBox(width: 12),

          // Avatar
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.person, color: Colors.grey, size: 24),
          ),
          const SizedBox(width: 12),

          // Name and Status
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Text(
                      'Status : ',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey,
                      ),
                    ),
                    Text(
                      status,
                      style: TextStyle(
                        fontSize: 12,
                        color: statusColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Action Buttons
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: const BoxDecoration(
                  color: Colors.orange,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.verified,
                  color: Colors.white,
                  size: 18,
                ),
              ),
              if (isRejected) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: const BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.close,
                    color: Colors.white,
                    size: 18,
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}
