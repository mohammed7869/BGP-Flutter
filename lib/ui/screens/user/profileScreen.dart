import 'package:flutter/material.dart';
import 'package:burhaniguardsapp/core/services/local_storage_service.dart';
import 'package:burhaniguardsapp/core/models/auth_models.dart';
import 'package:burhaniguardsapp/core/constants/api_constants.dart';
import 'package:burhaniguardsapp/ui/screens/admin/adminDashboard.dart';

class UserProfileScreen extends StatefulWidget {
  const UserProfileScreen({Key? key}) : super(key: key);

  @override
  State<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen> {
  final LocalStorageService _localStorage = LocalStorageService();
  UserData? _userData;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    try {
      final userData = await _localStorage.getUserData();
      setState(() {
        _userData = userData;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  String _formatPhoneNumber(String? phone) {
    if (phone == null || phone.isEmpty) return 'N/A';
    // Remove country code "91" if present at the start
    if (phone.startsWith('91') && phone.length > 10) {
      return phone.substring(2);
    }
    return phone;
  }

  String _formatJamaat(String? jamaat) {
    if (jamaat == null || jamaat.isEmpty) return 'N/A';
    // Remove "(POONA)" suffix if present
    return jamaat.replaceAll(' (POONA)', '').replaceAll('(POONA)', '');
  }

  Widget _buildDefaultAvatar() {
    return Container(
      width: 100,
      height: 100,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.grey[300],
        border: Border.all(color: Colors.white, width: 4),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Head/face circle
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.grey[400],
            ),
            child: Icon(
              Icons.person,
              size: 50,
              color: Colors.grey[700],
            ),
          ),
          // Beard (positioned at bottom)
          Positioned(
            bottom: 12,
            child: Container(
              width: 55,
              height: 22,
              decoration: BoxDecoration(
                color: Colors.grey[800],
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(25),
                  bottomRight: Radius.circular(25),
                  topLeft: Radius.circular(8),
                  topRight: Radius.circular(8),
                ),
              ),
            ),
          ),
          // Mustache
          Positioned(
            bottom: 28,
            child: Container(
              width: 40,
              height: 8,
              decoration: BoxDecoration(
                color: Colors.grey[800],
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getProfileImageUrl(String? profilePath) {
    if (profilePath == null || profilePath.isEmpty) {
      return '';
    }
    // If the profile path already contains http/https, return as is
    if (profilePath.startsWith('http://') ||
        profilePath.startsWith('https://')) {
      return profilePath;
    }
    // Otherwise, prepend the base URL
    final baseUrl = ApiConstants.baseUrl;
    // Handle both old format (just filename) and new format (bgp_uploads/filename or bgp_uploads/profile/filename)
    String cleanPath = profilePath.startsWith('/') 
        ? profilePath.substring(1) 
        : profilePath;
    
    // If it doesn't start with bgp_uploads/, it's an old format (just filename)
    // Prepend bgp_uploads/profile/ to the path
    if (!cleanPath.startsWith('bgp_uploads/')) {
      cleanPath = 'bgp_uploads/profile/$cleanPath';
    }
    
    return '$baseUrl/$cleanPath';
  }

  Widget _buildProfileImage() {
    if (_userData?.profile != null && _userData!.profile!.isNotEmpty) {
      final imageUrl = _getProfileImageUrl(_userData!.profile);
      return Container(
        width: 100,
        height: 100,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: 4),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: ClipOval(
          child: Container(
            color: Colors.grey[200],
            child: Image.network(
              imageUrl,
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) => _buildDefaultAvatar(),
              loadingBuilder: (context, child, loadingProgress) {
                if (loadingProgress == null) return child;
                return Center(
                  child: CircularProgressIndicator(
                    value: loadingProgress.expectedTotalBytes != null
                        ? loadingProgress.cumulativeBytesLoaded /
                            loadingProgress.expectedTotalBytes!
                        : null,
                  ),
                );
              },
            ),
          ),
        ),
      );
    }
    return _buildDefaultAvatar();
  }

  void _handleBackNavigation(BuildContext context) {
    if (Navigator.canPop(context)) {
      Navigator.pop(context);
    } else {
      // If we can't pop (e.g., screen was opened via pushReplacement),
      // navigate to dashboard explicitly
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const AdminDashboardScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_userData == null) {
      return Scaffold(
        body: Center(
          child: Text('No user data found'),
        ),
      );
    }

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
            // Custom Header with Profile Image
            Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  height: 160,
                  decoration: const BoxDecoration(
                    color: Color(0xFF4A1C1C),
                    borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(30),
                      bottomRight: Radius.circular(30),
                    ),
                  ),
                  child: SafeArea(
                    bottom: false,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.arrow_back,
                                color: Colors.white),
                            onPressed: () {
                              _handleBackNavigation(context);
                            },
                          ),
                          IconButton(
                            icon: const Icon(Icons.notifications_outlined,
                                color: Colors.white),
                            onPressed: () {},
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                // Profile Image positioned at bottom center
                Positioned(
                  bottom: -50,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: _buildProfileImage(),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 60),

            // Title
            Center(
              child: Text(
                _userData!.fullName,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
            ),

            const SizedBox(height: 20),

            // User Information
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  children: [
                    _buildInfoField(
                        'Phone No', _formatPhoneNumber(_userData!.contact)),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: _buildInfoField(
                              'ITS Number', _userData!.itsId ?? 'N/A'),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildInfoField(
                              'Jamiyat', _userData!.jamiyat ?? 'N/A'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _buildInfoField('Email', _userData!.email),
                    const SizedBox(height: 16),
                    _buildInfoField('Jamaat', _userData!.jamaat ?? 'N/A'),
                    const SizedBox(height: 16),
                    _buildInfoField('Rank', _userData!.rank),
                    if (_userData!.gender != null ||
                        _userData!.age != null) ...[
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          if (_userData!.gender != null)
                            Expanded(
                              child:
                                  _buildInfoField('Gender', _userData!.gender!),
                            ),
                          if (_userData!.gender != null &&
                              _userData!.age != null)
                            const SizedBox(width: 12),
                          if (_userData!.age != null)
                            Expanded(
                              child: _buildInfoField(
                                  'Age', _userData!.age.toString()),
                            ),
                          if (_userData!.gender == null &&
                              _userData!.age == null)
                            const Expanded(child: SizedBox()),
                        ],
                      ),
                    ],
                    const SizedBox(height: 30),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoField(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey[300]!, width: 1),
          ),
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              color: Colors.black,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }
}
