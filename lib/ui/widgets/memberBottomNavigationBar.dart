import 'package:burhaniguardsapp/ui/screens/admin/addUserScreen.dart';
import 'package:burhaniguardsapp/ui/screens/user/attendanceScreen.dart';
import 'package:burhaniguardsapp/ui/screens/user/memberDashboard.dart';
import 'package:burhaniguardsapp/ui/screens/user/miqaatListScreen.dart';
import 'package:burhaniguardsapp/ui/screens/user/profileScreen.dart';

import 'package:flutter/material.dart';

class CustomBottomNavBarMember extends StatefulWidget {
  final int selectedIndex;
  final ValueChanged<int>? onItemSelected;

  const CustomBottomNavBarMember({
    super.key,
    this.selectedIndex = 0,
    this.onItemSelected,
  });

  @override
  State<CustomBottomNavBarMember> createState() =>
      _CustomBottomNavBarMemberState();
}

class _CustomBottomNavBarMemberState extends State<CustomBottomNavBarMember> {
  late int _selectedIndex;

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.selectedIndex;
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });

    // Perform navigation
    if (index == 0) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const HomeMiqaatScreen()),
      );
    } else if (index == 1) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const MiqaatListScreen()),
      );
    } else if (index == 3) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const AttendanceMemberListScreen()),
      );
    } else if (index == 4) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const UserProfileScreen()),
      );
    }

    // Notify parent (optional)
    widget.onItemSelected?.call(index);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(Icons.home_filled, 'Home', 0),
              _buildNavItem(Icons.calendar_month, 'Miqaats', 1),
              // _buildNavItem(Icons.event_note_outlined, 'Lawazam', 3),
              _buildNavItem(Icons.bar_chart, 'Attendance', 3),
              _buildNavItem(Icons.person, 'Profile', 4),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(IconData icon, String label, int index) {
    final isSelected = _selectedIndex == index;
    return InkWell(
      onTap: () => _onItemTapped(index),
      child: SizedBox(
        height: 80,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(12),
              child: Icon(
                icon,
                color: isSelected
                    ? const Color(0xFF4A1C1C)
                    : const Color(0xFF999999),
                size: 28,
              ),
            ),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: isSelected
                    ? const Color(0xFF4A1C1C)
                    : const Color(0xFF999999),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCenterButton() {
    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        color: const Color(0xFF4A1C1C),
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF4A1C1C).withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: IconButton(
        icon: const Icon(Icons.add_box_outlined, color: Colors.white, size: 32),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AddUserScreen()),
          );
        },
      ),
    );
  }
}
