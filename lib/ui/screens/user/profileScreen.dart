import 'package:flutter/material.dart';
import 'package:burhaniguardsapp/core/services/local_storage_service.dart';
import 'package:burhaniguardsapp/core/services/auth_service.dart';
import 'package:burhaniguardsapp/core/models/auth_models.dart';
import 'package:burhaniguardsapp/core/constants/api_constants.dart';
import 'package:burhaniguardsapp/ui/screens/admin/adminDashboard.dart';
import 'package:burhaniguardsapp/ui/screens/common/unified_login_screen.dart';
import 'package:intl/intl.dart';

class UserProfileScreen extends StatefulWidget {
  const UserProfileScreen({Key? key}) : super(key: key);

  @override
  State<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen>
    with SingleTickerProviderStateMixin {
  final LocalStorageService _localStorage = LocalStorageService();
  final AuthService _authService = AuthService();
  UserData? _userData;
  bool _isLoading = true;

  late AnimationController _animController;
  late Animation<double> _fadeAnim;

  // Brand colors
  static const Color _brandDark = Color(0xFF461D17);
  static const Color _brandMedium = Color(0xFF6B2F26);
  static const Color _brandLight = Color(0xFFFFF7EF);
  static const Color _goldAccent = Color(0xFFD4A574);
  static const Color _goldShimmer = Color(0xFFE8C99B);
  static const Color _textDark = Color(0xFF1A1A2E);
  static const Color _textMuted = Color(0xFF6B7280);
  static const Color _editBg = Color(0xFFF0E6D8);

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _fadeAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeOut),
    );
    _loadUserData();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  Future<void> _loadUserData() async {
    try {
      final userData = await _localStorage.getUserData();
      setState(() {
        _userData = userData;
        _isLoading = false;
      });
      _animController.forward();
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  String _formatPhoneNumber(String? phone) {
    if (phone == null || phone.isEmpty) return 'N/A';
    if (phone.startsWith('91') && phone.length > 10) {
      return '+91 ${phone.substring(2)}';
    }
    return phone;
  }

  String _formatJamaat(String? jamaat) {
    if (jamaat == null || jamaat.isEmpty) return 'N/A';
    return jamaat.replaceAll(' (POONA)', '').replaceAll('(POONA)', '');
  }

  String _formatDateOfBirth(String? dob) {
    if (dob == null || dob.isEmpty) return 'N/A';
    try {
      final date = DateTime.parse(dob);
      return DateFormat('dd MMM yyyy').format(date);
    } catch (_) {
      return dob;
    }
  }

  String _calculateAge(String? dob) {
    if (dob == null || dob.isEmpty) {
      if (_userData?.age != null) return '${_userData!.age} yrs';
      return 'N/A';
    }
    try {
      final birthDate = DateTime.parse(dob);
      final today = DateTime.now();
      int age = today.year - birthDate.year;
      if (today.month < birthDate.month ||
          (today.month == birthDate.month && today.day < birthDate.day)) {
        age--;
      }
      return age > 0 ? '$age yrs' : 'N/A';
    } catch (_) {
      if (_userData?.age != null) return '${_userData!.age} yrs';
      return 'N/A';
    }
  }

  String _getProfileImageUrl(String? profilePath) {
    if (profilePath == null || profilePath.isEmpty) return '';
    if (profilePath.startsWith('http://') || profilePath.startsWith('https://')) {
      return profilePath;
    }
    final baseUrl = ApiConstants.baseUrl;
    String cleanPath =
        profilePath.startsWith('/') ? profilePath.substring(1) : profilePath;
    if (!cleanPath.startsWith('bgp_uploads/')) {
      cleanPath = 'bgp_uploads/profile/$cleanPath';
    }
    return '$baseUrl/$cleanPath';
  }

  void _handleBackNavigation(BuildContext context) {
    if (Navigator.canPop(context)) {
      Navigator.pop(context);
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const AdminDashboardScreen()),
      );
    }
  }

  void _showEditDialog({
    required String title,
    required String currentValue,
    required String fieldType,
  }) {
    final controller = TextEditingController(
        text: currentValue == 'N/A' ? '' : currentValue.replaceAll('+91 ', ''));

    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        elevation: 16,
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Colors.white, _brandLight],
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: _brandDark.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      fieldType == 'email'
                          ? Icons.email_outlined
                          : Icons.phone_outlined,
                      color: _brandDark,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Edit $title',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: _brandDark,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              TextField(
                controller: controller,
                keyboardType: fieldType == 'email'
                    ? TextInputType.emailAddress
                    : TextInputType.phone,
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
                decoration: InputDecoration(
                  labelText: title,
                  labelStyle: const TextStyle(color: _textMuted, fontSize: 13),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(color: Colors.grey[300]!),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: _brandDark, width: 2),
                  ),
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                ),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text('Cancel',
                        style: TextStyle(
                            color: _textMuted, fontWeight: FontWeight.w600)),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: () async {
                      final newValue = controller.text.trim();
                      if (newValue.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('$title cannot be empty')),
                        );
                        return;
                      }
                      Navigator.pop(context);
                      await _updateProfileField(fieldType, newValue);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _brandDark,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 28, vertical: 12),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                      elevation: 4,
                    ),
                    child: const Text('Save',
                        style: TextStyle(fontWeight: FontWeight.w600)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showDatePickerDialog() async {
    DateTime initialDate = DateTime(2000, 1, 1);
    if (_userData?.dateOfBirth != null && _userData!.dateOfBirth!.isNotEmpty) {
      try {
        initialDate = DateTime.parse(_userData!.dateOfBirth!);
      } catch (_) {}
    }

    final pickedDate = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(1940),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: _brandDark,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );

    if (pickedDate != null) {
      final formattedDate = DateFormat('yyyy-MM-dd').format(pickedDate);
      await _updateProfileField('dateOfBirth', formattedDate);
    }
  }

  Future<void> _updateProfileField(String fieldType, String value) async {
    try {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: Colors.white),
                ),
                SizedBox(width: 12),
                Text('Updating profile...'),
              ],
            ),
            backgroundColor: _brandMedium,
            duration: const Duration(seconds: 3),
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }

      bool success = false;
      switch (fieldType) {
        case 'email':
          success = await _authService.updateProfile(email: value);
          break;
        case 'phone':
          success = await _authService.updateProfile(contact: value);
          break;
        case 'dateOfBirth':
          success = await _authService.updateProfile(dateOfBirth: value);
          break;
      }

      if (success) {
        await _loadUserData();
        if (mounted) {
          ScaffoldMessenger.of(context).hideCurrentSnackBar();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.white, size: 20),
                  SizedBox(width: 10),
                  Text('Profile updated successfully!'),
                ],
              ),
              backgroundColor: const Color(0xFF2E7D32),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                'Failed to update: ${e.toString().replaceAll('Exception: ', '')}'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    }
  }

  Future<void> _handleLogout(BuildContext context) async {
    final shouldLogout = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Log Out'),
        content: const Text('Are you sure you want to log out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text(
              'Log Out',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );

    if (shouldLogout == true && mounted) {
      try {
        await _localStorage.clearAll();
        if (mounted) {
          Navigator.of(context, rootNavigator: true).pushAndRemoveUntil(
            MaterialPageRoute(builder: (context) => const UnifiedLoginScreen()),
            (route) => false,
          );
        }
      } catch (e) {
        if (mounted) {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => const UnifiedLoginScreen()),
            (route) => false,
          );
        }
      }
    }
  }

  // ─── BUILD ───────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: _brandLight,
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(
                  width: 48,
                  height: 48,
                  child:
                      CircularProgressIndicator(strokeWidth: 3, color: _brandDark)),
              const SizedBox(height: 16),
              Text('Loading profile...',
                  style: TextStyle(color: _textMuted, fontSize: 14)),
            ],
          ),
        ),
      );
    }

    if (_userData == null) {
      return Scaffold(
        backgroundColor: _brandLight,
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.person_off_outlined, size: 56, color: _textMuted),
              const SizedBox(height: 12),
              Text('No user data found',
                  style: TextStyle(color: _textMuted, fontSize: 16)),
            ],
          ),
        ),
      );
    }

    return PopScope(
      canPop: false,
      onPopInvoked: (bool didPop) {
        if (!didPop) _handleBackNavigation(context);
      },
      child: Scaffold(
        backgroundColor: _brandLight,
        body: FadeTransition(
          opacity: _fadeAnim,
          child: CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              // ── SLIVER APP BAR with profile inside ──
              SliverAppBar(
                expandedHeight: 260,
                pinned: true,
                backgroundColor: _brandDark,
                leading: IconButton(
                  icon: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.arrow_back_ios_new,
                        color: Colors.white, size: 16),
                  ),
                  onPressed: () => _handleBackNavigation(context),
                ),
                title: const Text(
                  'My Profile',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    letterSpacing: 0.3,
                  ),
                ),
                centerTitle: true,
                actions: [
                  IconButton(
                    icon: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.settings_outlined,
                          color: Colors.white, size: 16),
                    ),
                    onPressed: () {},
                  ),
                ],
                flexibleSpace: FlexibleSpaceBar(
                  background: Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Color(0xFF3A1410),
                          _brandDark,
                          Color(0xFF6B2F26),
                        ],
                      ),
                    ),
                    child: Stack(
                      children: [
                        // Decorative circles
                        Positioned(
                          top: 30,
                          right: -30,
                          child: Container(
                            width: 100,
                            height: 100,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white.withOpacity(0.04),
                            ),
                          ),
                        ),
                        Positioned(
                          bottom: 40,
                          left: -20,
                          child: Container(
                            width: 70,
                            height: 70,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: _goldAccent.withOpacity(0.06),
                            ),
                          ),
                        ),
                        // Avatar + Name + Rank
                        SafeArea(
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.only(top: 48),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                _buildPremiumAvatar(),
                                const SizedBox(height: 12),
                                Text(
                                  _userData!.fullName,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w800,
                                    color: Colors.white,
                                    letterSpacing: -0.3,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 14, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: _goldAccent.withOpacity(0.25),
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(
                                        color: _goldShimmer.withOpacity(0.5)),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(Icons.military_tech,
                                          size: 14, color: _goldShimmer),
                                      const SizedBox(width: 4),
                                      Text(
                                        _userData!.rank,
                                        style: const TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                          color: _goldShimmer,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // ── BODY CONTENT ──
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(18, 20, 18, 30),
                  child: Column(
                    children: [
                      _buildContactInfoCard(),
                      const SizedBox(height: 14),
                      _buildDetailsCard(),
                      const SizedBox(height: 24),
                      // ── LOGOUT BUTTON ──
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: () => _handleLogout(context),
                          icon: const Icon(Icons.exit_to_app, size: 20),
                          label: const Text(
                            'Log Out',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.red,
                            side: const BorderSide(color: Colors.red, width: 1.5),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─── PREMIUM AVATAR ────────────────────────────────────────────

  Widget _buildPremiumAvatar() {
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [_goldAccent, _goldShimmer, _goldAccent],
        ),
        boxShadow: [
          BoxShadow(
            color: _goldAccent.withOpacity(0.4),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Container(
        width: 90,
        height: 90,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white,
          border: Border.all(color: Colors.white, width: 2.5),
        ),
        child: ClipOval(child: _buildAvatarContent()),
      ),
    );
  }

  Widget _buildAvatarContent() {
    if (_userData?.profile != null && _userData!.profile!.isNotEmpty) {
      final imageUrl = _getProfileImageUrl(_userData!.profile);
      return Image.network(
        imageUrl,
        fit: BoxFit.cover,
        width: 85,
        height: 85,
        errorBuilder: (_, __, ___) => _buildAvatarFallback(),
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return const Center(
            child: SizedBox(
              width: 22,
              height: 22,
              child:
                  CircularProgressIndicator(strokeWidth: 2, color: _brandDark),
            ),
          );
        },
      );
    }
    return _buildAvatarFallback();
  }

  Widget _buildAvatarFallback() {
    return Container(
      color: _editBg,
      child: Center(
        child: Text(
          _userData?.fullName.isNotEmpty == true
              ? _userData!.fullName.substring(0, 1).toUpperCase()
              : '?',
          style: const TextStyle(
            fontSize: 38,
            fontWeight: FontWeight.w700,
            color: _brandDark,
          ),
        ),
      ),
    );
  }

  // ─── CONTACT INFO CARD ────────────────────────────────────────

  Widget _buildContactInfoCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: _brandDark.withOpacity(0.06),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: _goldAccent.withOpacity(0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: _goldAccent.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.contact_mail_outlined,
                    size: 16, color: _brandDark),
              ),
              const SizedBox(width: 10),
              const Text(
                'Contact Information',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: _textDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          // Email (full width row)
          _buildEditableInfoTile(
            icon: Icons.email_outlined,
            label: 'Email',
            value: _userData!.email,
            onEdit: () => _showEditDialog(
              title: 'Email',
              currentValue: _userData!.email,
              fieldType: 'email',
            ),
          ),
          const SizedBox(height: 10),
          // Phone (full width row)
          _buildEditableInfoTile(
            icon: Icons.phone_outlined,
            label: 'Phone',
            value: _formatPhoneNumber(_userData!.contact),
            onEdit: () => _showEditDialog(
              title: 'Phone Number',
              currentValue: _formatPhoneNumber(_userData!.contact),
              fieldType: 'phone',
            ),
          ),
          const SizedBox(height: 10),
          // Date of Birth (full width row)
          _buildEditableInfoTile(
            icon: Icons.cake_outlined,
            label: 'Date of Birth',
            value: _formatDateOfBirth(_userData!.dateOfBirth),
            onEdit: _showDatePickerDialog,
          ),
        ],
      ),
    );
  }

  // ─── DETAILS CARD ─────────────────────────────────────────────

  Widget _buildDetailsCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: _brandDark.withOpacity(0.06),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: _goldAccent.withOpacity(0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: _brandDark.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(8),
                ),
                child:
                    const Icon(Icons.badge_outlined, size: 16, color: _brandDark),
              ),
              const SizedBox(width: 10),
              const Text(
                'Member Details',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: _textDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          // Row 1
          Row(
            children: [
              Expanded(
                child: _buildStaticInfoTile(
                    icon: Icons.fingerprint,
                    label: 'ITS Number',
                    value: _userData!.itsId ?? 'N/A'),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildStaticInfoTile(
                    icon: Icons.account_balance_outlined,
                    label: 'Jamiyat',
                    value: _userData!.jamiyat ?? 'N/A'),
              ),
            ],
          ),
          const SizedBox(height: 10),
          // Row 2
          Row(
            children: [
              Expanded(
                child: _buildStaticInfoTile(
                    icon: Icons.groups_outlined,
                    label: 'Jamaat',
                    value: _formatJamaat(_userData!.jamaat)),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildStaticInfoTile(
                    icon: Icons.military_tech_outlined,
                    label: 'Rank',
                    value: _userData!.rank),
              ),
            ],
          ),
          const SizedBox(height: 10),
          // Row 3
          Row(
            children: [
              Expanded(
                child: _buildStaticInfoTile(
                    icon: Icons.person_outline,
                    label: 'Gender',
                    value: _userData!.gender ?? 'N/A'),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildStaticInfoTile(
                    icon: Icons.calendar_today_outlined,
                    label: 'Age',
                    value: _calculateAge(_userData!.dateOfBirth)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ─── REUSABLE TILES ───────────────────────────────────────────

  Widget _buildEditableInfoTile({
    required IconData icon,
    required String label,
    required String value,
    required VoidCallback onEdit,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: _brandLight,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _goldAccent.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 20, color: _brandDark.withOpacity(0.6)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: _textMuted,
                    letterSpacing: 0.4,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: _textDark,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: onEdit,
            child: Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                color: _brandDark.withOpacity(0.08),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.edit_outlined, size: 15, color: _brandDark),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStaticInfoTile({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: _brandDark.withOpacity(0.5)),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: _textMuted,
                    letterSpacing: 0.4,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: _textDark,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
