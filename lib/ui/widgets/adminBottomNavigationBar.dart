import 'package:burhaniguardsapp/core/constants/app_colors.dart';
import 'package:burhaniguardsapp/ui/screens/admin/adminDashboard.dart';
import 'package:burhaniguardsapp/ui/screens/admin/attendancemiqaatScreen.dart';
import 'package:burhaniguardsapp/ui/screens/admin/createMiqaatScreen.dart';
import 'package:burhaniguardsapp/ui/screens/common/hierarchyScreen.dart';
import 'package:burhaniguardsapp/ui/screens/common/underDevelopmentScreen.dart';
import 'package:burhaniguardsapp/ui/screens/qardan_hasana/qardan_list_screen.dart';
import 'package:burhaniguardsapp/ui/screens/user/profileScreen.dart';

import 'package:flutter/material.dart';

class CustomBottomNavBarCaptain extends StatefulWidget {
  final int selectedIndex;
  final ValueChanged<int>? onItemSelected;

  const CustomBottomNavBarCaptain({
    super.key,
    this.selectedIndex = 0,
    this.onItemSelected,
  });

  @override
  State<CustomBottomNavBarCaptain> createState() =>
      _CustomBottomNavBarCaptainState();
}

class _CustomBottomNavBarCaptainState extends State<CustomBottomNavBarCaptain> {
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
        MaterialPageRoute(builder: (_) => const AdminDashboardScreen()),
      );
    } else if (index == 1) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const HierarchyScreen()),
      );
    } else if (index == 3) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
            builder: (context) => const QardanListScreen()),
      );
    } else if (index == 4) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const UserProfileScreen()),
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
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(Icons.home_rounded, 'Home', 0),
              _buildNavItem(Icons.account_tree_rounded, 'Hierarchy', 1),
              _buildCenterButton(),
              _buildNavItem(Icons.currency_rupee_rounded, 'Qardan', 3),
              _buildNavItem(Icons.person_outline_rounded, 'Profile', 4),
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
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeInOut,
        width: 64,
        padding: const EdgeInsets.symmetric(vertical: 6),
        decoration: isSelected
            ? BoxDecoration(
                color: AppColors.primary.withOpacity(0.08),
                borderRadius: BorderRadius.circular(12),
              )
            : null,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isSelected ? AppColors.primary : const Color(0xFFADB5BD),
              size: 26,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                color:
                    isSelected ? AppColors.primary : const Color(0xFFADB5BD),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCenterButton() {
    return Container(
      width: 60,
      height: 60,
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.50),
            blurRadius: 18,
            spreadRadius: 2,
            offset: const Offset(0, 6),
          ),
          BoxShadow(
            color: AppColors.primary.withOpacity(0.20),
            blurRadius: 30,
            spreadRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.white.withOpacity(0.30),
              Colors.white.withOpacity(0.05),
              Colors.transparent,
            ],
            stops: const [0.0, 0.4, 1.0],
          ),
        ),
        child: IconButton(
          icon: const Icon(Icons.add_rounded, color: Colors.white, size: 32),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const CreateMiqaatScreen()),
            );
          },
        ),
      ),
    );
  }
}
