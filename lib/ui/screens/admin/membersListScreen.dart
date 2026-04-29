import 'package:burhaniguardsapp/core/services/miqaat_service.dart';
import 'package:burhaniguardsapp/core/services/local_storage_service.dart';
import 'package:burhaniguardsapp/core/services/user_service.dart';
import 'package:burhaniguardsapp/core/constants/api_constants.dart';
import 'package:burhaniguardsapp/ui/widgets/adminAppBarforPages.dart';
import 'package:burhaniguardsapp/ui/screens/admin/addUserScreen.dart';
import 'package:flutter/material.dart';

class MembersListScreen extends StatefulWidget {
  final Miqaat? miqaat;

  const MembersListScreen({Key? key, this.miqaat}) : super(key: key);

  @override
  State<MembersListScreen> createState() => _MembersListScreenState();
}

class _MembersListScreenState extends State<MembersListScreen> {
  final MiqaatService _miqaatService = MiqaatService();
  final LocalStorageService _localStorage = LocalStorageService();
  final UserService _userService = UserService();
  List<EnrolledMember> _enrolledMembers = [];
  List<EnrolledMember> _allMembers = [];
  List<Map<String, dynamic>> _jamaatMembers = [];

  bool _isLoading = false;
  bool _isCaptain = false;
  bool _isCheckingRole = true;
  String? _userJamaat;

  int _selectedTab = 0;

  // Brand Colors
  static const Color _brandDark = Color(0xFF461D17);
  static const Color _brandLight = Color(0xFFFFF7EF);
  static const Color _goldAccent = Color(0xFFD4A574);
  static const Color _goldShimmer = Color(0xFFE8C99B);
  static const Color _textDark = Color(0xFF1A1A2E);
  static const Color _textMuted = Color(0xFF6B7280);

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  Future<void> _initializeData() async {
    await _checkUserRole();
    if (!_isCaptain) {
      setState(() => _isCheckingRole = false);
      return;
    }
    if (widget.miqaat != null) {
      _loadEnrolledMembers();
    } else {
      _loadJamaatMembers();
    }
  }

  Future<void> _checkUserRole() async {
    final userData = await _localStorage.getUserData();
    setState(() {
      _isCaptain = userData?.roles == 2;
      _userJamaat = userData?.jamaat;
      _isCheckingRole = false;
    });
  }

  Future<void> _loadJamaatMembers() async {
    if (_userJamaat == null || _userJamaat!.isEmpty) return;
    setState(() => _isLoading = true);

    try {
      final members = await _userService.getMembersByJamaat(_userJamaat!);
      setState(() {
        _jamaatMembers = members;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load members: ${e.toString()}'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    }
  }

  /// Filters members to only show those whose jamaat matches the captain's jamaat.
  List<EnrolledMember> _filterMembersByCaptainJamaat(List<EnrolledMember> members) {
    if (!_isCaptain || _userJamaat == null || _userJamaat!.isEmpty) {
      return members;
    }
    final captainJamaat = _userJamaat!.trim().toLowerCase();
    return members.where((m) {
      final memberJamaat = (m.jamaat ?? '').trim().toLowerCase();
      return memberJamaat == captainJamaat;
    }).toList();
  }

  Future<void> _loadEnrolledMembers() async {
    if (widget.miqaat == null) return;
    setState(() => _isLoading = true);

    try {
      final members =
          await _miqaatService.getAllMembersByMiqaatId(widget.miqaat!.id);
      // Captain should only see members from their own jamaat
      final filteredMembers = _filterMembersByCaptainJamaat(members);
      setState(() {
        _allMembers = filteredMembers;
        _enrolledMembers =
            filteredMembers.where((m) => m.statusCategory == 'Enrolled').toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load members: ${e.toString()}'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    }
  }

  List<EnrolledMember> get _filteredMembers {
    switch (_selectedTab) {
      case 0:
        return _allMembers
            .where((m) => m.statusCategory == 'Enrolled')
            .toList();
      case 1:
        return _allMembers
            .where((m) => m.statusCategory == 'Pending')
            .toList();
      case 2:
        return _allMembers
            .where((m) => m.statusCategory == 'Rejected')
            .toList();
      default:
        return _allMembers;
    }
  }

  String _calculateAge(dynamic dob) {
    if (dob == null) return '';
    try {
      String dobStr = dob.toString();
      final birthDate = DateTime.parse(dobStr);
      final today = DateTime.now();
      int age = today.year - birthDate.year;
      if (today.month < birthDate.month ||
          (today.month == birthDate.month && today.day < birthDate.day)) {
        age--;
      }
      return age > 0 ? '$age yrs' : '';
    } catch (_) {
      return '';
    }
  }

  String _formatContact(dynamic contact) {
    if (contact == null) return '';
    String phone = contact.toString();
    if (phone.isEmpty) return '';
    if (phone.startsWith('91') && phone.length > 10) {
      return '+91 ${phone.substring(2)}';
    }
    return phone;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _brandLight,
      body: Column(
        children: [
          // ── Premium Header ──
          Container(
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
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(32),
                bottomRight: Radius.circular(32),
              ),
              boxShadow: [
                BoxShadow(
                  color: Color(0x40461D17),
                  blurRadius: 16,
                  offset: Offset(0, 6),
                ),
              ],
            ),
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                child: Row(
                  children: [
                    IconButton(
                      icon: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.arrow_back_ios_new,
                            color: Colors.white, size: 16),
                      ),
                      onPressed: () => Navigator.pop(context),
                    ),
                    Expanded(
                      child: Text(
                        widget.miqaat != null
                            ? 'Miqaat Members'
                            : 'Members List',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ),
                    const SizedBox(width: 48),
                  ],
                ),
              ),
            ),
          ),

          // ── Content ──
          Expanded(
            child: Column(
              children: [
                // Top info bar
                Padding(
                  padding: const EdgeInsets.fromLTRB(18, 16, 18, 0),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.miqaat != null
                                  ? 'Enrolled members for attendance'
                                  : 'My Jamaat Members',
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: _textDark,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              widget.miqaat != null
                                  ? '${_filteredMembers.length} members'
                                  : '${_jamaatMembers.length} members',
                              style: TextStyle(
                                fontSize: 12,
                                color: _textMuted,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (_isCaptain && widget.miqaat == null)
                        ElevatedButton.icon(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const AddUserScreen(),
                              ),
                            ).then((_) {
                              if (widget.miqaat != null) {
                                _loadEnrolledMembers();
                              } else {
                                _loadJamaatMembers();
                              }
                            });
                          },
                          icon: const Icon(Icons.person_add, size: 16),
                          label: const Text('Add',
                              style: TextStyle(fontWeight: FontWeight.w600)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _brandDark,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 10),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                            elevation: 4,
                            shadowColor: _brandDark.withOpacity(0.3),
                          ),
                        ),
                    ],
                  ),
                ),

                if (widget.miqaat != null)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(18, 12, 18, 0),
                    child: _buildMiqaatInfoCard(widget.miqaat!),
                  ),

                if (widget.miqaat != null &&
                    _isCaptain &&
                    !_isCheckingRole)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(18, 12, 18, 0),
                    child: _buildTabCapsules(),
                  ),

                const SizedBox(height: 12),

                // Members List
                Expanded(
                  child: _isCheckingRole
                      ? const Center(
                          child: CircularProgressIndicator(color: _brandDark))
                      : !_isCaptain
                          ? _buildAccessDenied()
                          : _isLoading
                              ? const Center(
                                  child: CircularProgressIndicator(
                                      color: _brandDark))
                              : widget.miqaat != null
                                  ? _buildMiqaatMembersList()
                                  : _buildJamaatMembersList(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─── Access Denied ────────────────────────────────────────────

  Widget _buildAccessDenied() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Container(
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                  color: Colors.red.withOpacity(0.08),
                  blurRadius: 16,
                  offset: const Offset(0, 4)),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.red[50],
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.block, size: 48, color: Colors.red[400]),
              ),
              const SizedBox(height: 16),
              const Text(
                'Only Captains can view this page',
                style: TextStyle(
                    fontSize: 16, fontWeight: FontWeight.w700, color: Colors.red),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'You do not have permission to access the members list.',
                style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─── Tab Capsules ─────────────────────────────────────────────

  Widget _buildTabCapsules() {
    final enrolledCount =
        _allMembers.where((m) => m.statusCategory == 'Enrolled').length;
    final pendingCount =
        _allMembers.where((m) => m.statusCategory == 'Pending').length;
    final rejectedCount =
        _allMembers.where((m) => m.statusCategory == 'Rejected').length;

    return Row(
      children: [
        _buildTabCapsule(0, 'Enrolled', enrolledCount, const Color(0xFF2E7D32)),
        const SizedBox(width: 6),
        _buildTabCapsule(1, 'Pending', pendingCount, Colors.orange),
        const SizedBox(width: 6),
        _buildTabCapsule(2, 'Rejected', rejectedCount, Colors.red),
      ],
    );
  }

  Widget _buildTabCapsule(int index, String label, int count, Color color) {
    final isSelected = _selectedTab == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedTab = index),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? _brandDark : Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isSelected ? _brandDark : Colors.grey[300]!,
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                        color: _brandDark.withOpacity(0.2),
                        blurRadius: 8,
                        offset: const Offset(0, 2)),
                  ]
                : [],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 7,
                height: 7,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              ),
              const SizedBox(width: 5),
              Flexible(
                child: Text(
                  '$label ($count)',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: isSelected ? Colors.white : _textDark,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─── Miqaat Info Card ─────────────────────────────────────────

  String _formatDate(DateTime date) {
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${date.day.toString().padLeft(2, '0')} ${months[date.month - 1]} ${date.year}';
  }

  Widget _buildMiqaatInfoCard(Miqaat miqaat) {
    final fromDateStr = _formatDate(miqaat.fromDate);
    final tillDateStr = _formatDate(miqaat.tillDate);
    final dateDisplay = fromDateStr == tillDateStr
        ? fromDateStr
        : '$fromDateStr - $tillDateStr';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [_brandDark, Color(0xFF6B2D2D)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: _brandDark.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            miqaat.miqaatName,
            style: const TextStyle(
                fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              const Icon(Icons.calendar_today, color: Colors.white70, size: 13),
              const SizedBox(width: 5),
              Text(dateDisplay,
                  style:
                      const TextStyle(fontSize: 12, color: Colors.white)),
              const SizedBox(width: 16),
              const Icon(Icons.access_time, color: Colors.white70, size: 13),
              const SizedBox(width: 5),
              Text(miqaat.durationLabel,
                  style:
                      const TextStyle(fontSize: 12, color: Colors.white)),
            ],
          ),
        ],
      ),
    );
  }

  // ─── Miqaat Members List ──────────────────────────────────────

  Widget _buildMiqaatMembersList() {
    if (_filteredMembers.isEmpty) {
      return _buildEmptyState(
        _selectedTab == 0
            ? 'No enrolled members'
            : _selectedTab == 1
                ? 'No pending members'
                : 'No rejected members',
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 18),
      physics: const BouncingScrollPhysics(),
      itemCount: _filteredMembers.length,
      itemBuilder: (context, index) =>
          _buildMemberCard(index + 1, _filteredMembers[index]),
    );
  }

  // ─── Jamaat Members List ──────────────────────────────────────

  Widget _buildJamaatMembersList() {
    if (_jamaatMembers.isEmpty) {
      return _buildEmptyState('No members found');
    }
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 18),
      physics: const BouncingScrollPhysics(),
      itemCount: _jamaatMembers.length,
      itemBuilder: (context, index) =>
          _buildJamaatMemberCard(index + 1, _jamaatMembers[index]),
    );
  }

  Widget _buildEmptyState(String message) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.people_outline,
                size: 48, color: Colors.grey[400]),
          ),
          const SizedBox(height: 16),
          Text(message,
              style: TextStyle(fontSize: 15, color: _textMuted, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  // ─── Miqaat Member Card ───────────────────────────────────────

  Widget _buildMemberCard(int number, EnrolledMember member) {
    final finalStatus = member.finalStatus;
    final isApproved = finalStatus == 'Approved';
    final isRejected = finalStatus == 'Rejected';

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: _brandDark.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(color: _goldAccent.withOpacity(0.15)),
      ),
      child: Row(
        children: [
          // Number badge
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: _brandDark.withOpacity(0.08),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Text(
                number.toString().padLeft(2, '0'),
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: _brandDark,
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          // Avatar
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: _goldAccent.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.person, color: _brandDark.withOpacity(0.4), size: 20),
          ),
          const SizedBox(width: 10),
          // Name + Status
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  member.fullName,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: _textDark,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (member.statusCategory == 'Enrolled') ...[
                  const SizedBox(height: 2),
                  if (isApproved)
                    _buildStatusChip('Captain Approved', Colors.green)
                  else if (isRejected)
                    _buildStatusChip('Captain Rejected', Colors.red)
                  else
                    _buildStatusChip('Pending Approval', Colors.orange),
                ],
              ],
            ),
          ),
          // Info button
          if (widget.miqaat != null)
            _buildCircleBtn(Icons.info_outline, Colors.blue, () => _showEnrollmentDaysDialog(member)),
          // Approve/Reject
          if (widget.miqaat != null &&
              _selectedTab == 0 &&
              !isApproved &&
              !isRejected) ...[
            const SizedBox(width: 4),
            _buildCircleBtn(Icons.check, Colors.green, () => _handleApprove(member)),
            const SizedBox(width: 4),
            _buildCircleBtn(Icons.close, Colors.red, () => _handleReject(member)),
          ],
        ],
      ),
    );
  }

  Widget _buildStatusChip(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 10,
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildCircleBtn(IconData icon, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: color, size: 15),
      ),
    );
  }

  // ─── Jamaat Member Card (PREMIUM) ─────────────────────────────

  Widget _buildJamaatMemberCard(int number, Map<String, dynamic> member) {
    final fullName = member['fullName'] as String? ??
        member['FullName'] as String? ??
        'N/A';
    final contact = member['contact'] as String? ??
        member['Contact'] as String?;
    final profile = member['profile'] as String? ??
        member['Profile'] as String?;
    final isApproved = member['isApproved'] as bool? ??
        member['IsApproved'] as bool? ??
        true;
    final rank = member['rank'] as String? ??
        member['Rank'] as String? ??
        '';
    final dob = member['dateOfBirth'] ?? member['DateOfBirth'] ?? member['date_of_birth'];
    final age = member['age'] ?? member['Age'];

    final formattedContact = _formatContact(contact);
    String ageDisplay = _calculateAge(dob);
    if (ageDisplay.isEmpty && age != null) {
      ageDisplay = '$age yrs';
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: _brandDark.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(color: _goldAccent.withOpacity(0.15)),
      ),
      child: Row(
        children: [
          // Number badge
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [_brandDark.withOpacity(0.1), _goldAccent.withOpacity(0.1)],
              ),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Center(
              child: Text(
                number.toString().padLeft(2, '0'),
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: _brandDark,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),

          // Profile Image
          _buildProfileImage(profile),
          const SizedBox(width: 12),

          // Info section
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Name row
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        fullName,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: _textDark,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (ageDisplay.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: _goldAccent.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          ageDisplay,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: _brandDark,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                // Contact + Rank row
                Row(
                  children: [
                    if (formattedContact.isNotEmpty) ...[
                      Icon(Icons.phone_outlined,
                          size: 12, color: _textMuted),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          formattedContact,
                          style: TextStyle(
                            fontSize: 12,
                            color: _textMuted,
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                    if (rank.isNotEmpty) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: _brandDark.withOpacity(0.06),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          rank,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: _brandDark.withOpacity(0.7),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                // Approval status
                if (!isApproved) ...[
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: Colors.orange.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      'Awaiting Admin Approval',
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.orange,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─── Profile Image ────────────────────────────────────────────

  Widget _buildProfileImage(String? profilePath) {
    String? imageUrl;
    if (profilePath != null && profilePath.isNotEmpty) {
      if (profilePath.startsWith('http://') ||
          profilePath.startsWith('https://')) {
        imageUrl = profilePath;
      } else {
        String cleanPath =
            profilePath.startsWith('/') ? profilePath.substring(1) : profilePath;
        if (!cleanPath.startsWith('bgp_uploads/')) {
          cleanPath = 'bgp_uploads/profile/$cleanPath';
        }
        imageUrl = '${ApiConstants.baseUrl}/$cleanPath';
      }
    }

    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: [_goldAccent.withOpacity(0.3), _goldShimmer.withOpacity(0.2)],
        ),
        boxShadow: [
          BoxShadow(
            color: _goldAccent.withOpacity(0.15),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Container(
        margin: const EdgeInsets.all(2),
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white,
        ),
        child: imageUrl != null
            ? ClipOval(
                child: Image.network(
                  imageUrl,
                  fit: BoxFit.cover,
                  width: 40,
                  height: 40,
                  errorBuilder: (_, __, ___) => Icon(
                    Icons.person,
                    color: _brandDark.withOpacity(0.4),
                    size: 22,
                  ),
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return const Center(
                      child: SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                            strokeWidth: 1.5, color: _brandDark),
                      ),
                    );
                  },
                ),
              )
            : Icon(Icons.person, color: _brandDark.withOpacity(0.4), size: 22),
      ),
    );
  }

  // ─── Handlers ─────────────────────────────────────────────────

  Future<void> _handleApprove(EnrolledMember member) async {
    // Redirect to day-wise dialog for approval
    _showEnrollmentDaysDialog(member);
  }

  Future<void> _handleReject(EnrolledMember member) async {
    // Redirect to day-wise dialog for rejection
    _showEnrollmentDaysDialog(member);
  }

  Future<void> _showEnrollmentDaysDialog(EnrolledMember member) async {
    if (widget.miqaat == null) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) =>
          const Center(child: CircularProgressIndicator(color: _brandDark)),
    );

    try {
      final enrollmentDays = await _miqaatService.getMemberEnrollmentDays(
        miqaatId: widget.miqaat!.id,
        memberId: member.id,
      );

      if (mounted) {
        Navigator.of(context).pop(); // Close loading

        _showDayWiseCaptainDialog(member, enrollmentDays);
      }
    } catch (e) {
      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load enrollment days: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showDayWiseCaptainDialog(EnrolledMember member, List<MemberEnrollmentDay> enrollmentDays) {
    final approvedDays = enrollmentDays.where((d) => d.status == 'Approved').toList();

    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    member.fullName,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: _brandDark),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: _brandDark.withOpacity(0.06),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      'Enrolled Days: ${approvedDays.length} / ${enrollmentDays.length}',
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                    ),
                  ),
                  const Divider(height: 16),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE3F2FD),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.info_outline, size: 14, color: Color(0xFF1565C0)),
                        SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            'Approve or reject each day individually. Finalized days cannot be changed.',
                            style: TextStyle(fontSize: 10, color: Color(0xFF1565C0)),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              content: SizedBox(
                width: double.maxFinite,
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxHeight: MediaQuery.of(context).size.height * 0.5,
                  ),
                  child: enrollmentDays.isEmpty
                      ? const Center(
                          child: Text('No enrollment data', style: TextStyle(color: _textMuted)),
                        )
                      : ListView.builder(
                          shrinkWrap: true,
                          itemCount: enrollmentDays.length,
                          itemBuilder: (context, index) {
                            final day = enrollmentDays[index];
                            final isEnrolled = day.status == 'Approved';
                            final isRejected = day.status == 'Rejected';
                            final isCaptainFinalized = day.finalStatus != null &&
                                day.finalStatus!.isNotEmpty &&
                                (day.finalStatus == 'Approved' || day.finalStatus == 'Rejected');

                            final statusColor = isEnrolled
                                ? Colors.green
                                : isRejected
                                    ? Colors.red
                                    : Colors.orange;

                            Color cardColor;
                            Color borderColor;
                            if (isCaptainFinalized) {
                              cardColor = day.finalStatus == 'Approved'
                                  ? Colors.green.withOpacity(0.08)
                                  : Colors.red.withOpacity(0.08);
                              borderColor = day.finalStatus == 'Approved'
                                  ? Colors.green.withOpacity(0.3)
                                  : Colors.red.withOpacity(0.3);
                            } else {
                              cardColor = statusColor.withOpacity(0.06);
                              borderColor = statusColor.withOpacity(0.2);
                            }

                            return Container(
                              margin: const EdgeInsets.only(bottom: 10),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: cardColor,
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(color: borderColor),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Day header
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: _brandDark,
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: Text(
                                          'Day ${day.day}',
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 11,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        day.miqaatDate,
                                        style: TextStyle(fontSize: 12, color: Colors.grey[700]),
                                      ),
                                      const Spacer(),
                                      // Member status pill
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                        decoration: BoxDecoration(
                                          color: statusColor,
                                          borderRadius: BorderRadius.circular(10),
                                        ),
                                        child: Text(
                                          isEnrolled ? 'Enrolled' : isRejected ? 'Rejected' : 'Pending',
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 10,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  // Captain status row
                                  if (isCaptainFinalized) ...[
                                    const SizedBox(height: 8),
                                    Row(
                                      children: [
                                        Icon(
                                          day.finalStatus == 'Approved' ? Icons.verified : Icons.block,
                                          size: 14,
                                          color: day.finalStatus == 'Approved' ? Colors.green : Colors.red,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          'Captain ${day.finalStatus}',
                                          style: TextStyle(
                                            fontSize: 11,
                                            color: day.finalStatus == 'Approved'
                                                ? Colors.green[700]
                                                : Colors.red[700],
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                  // Admin status row for International / multi-jamaat Local miqaats (only when captain approved)
                                  if (widget.miqaat != null &&
                                      (widget.miqaat!.isInternational || widget.miqaat!.isMultiJamaatLocal) &&
                                      isCaptainFinalized &&
                                      day.finalStatus == 'Approved') ...[
                                    const SizedBox(height: 6),
                                    Row(
                                      children: [
                                        Icon(
                                          day.adminStatus == 'Approved'
                                              ? Icons.admin_panel_settings
                                              : day.adminStatus == 'Rejected'
                                                  ? Icons.block
                                                  : Icons.hourglass_top_rounded,
                                          size: 14,
                                          color: day.adminStatus == 'Approved'
                                              ? Colors.green
                                              : day.adminStatus == 'Rejected'
                                                  ? Colors.red
                                                  : const Color(0xFFB8860B),
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          'Admin: ${day.adminStatus ?? 'Pending'}',
                                          style: TextStyle(
                                            fontSize: 11,
                                            color: day.adminStatus == 'Approved'
                                                ? Colors.green[700]
                                                : day.adminStatus == 'Rejected'
                                                    ? Colors.red[700]
                                                    : const Color(0xFFB8860B),
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                  // Captain action buttons (only for enrolled days, not yet finalized by captain)
                                  if (isEnrolled && !isCaptainFinalized) ...[
                                    const SizedBox(height: 10),
                                    Row(
                                      children: [
                                        Expanded(
                                          child: ElevatedButton.icon(
                                            onPressed: () async {
                                              await _updateDayFinalStatus(
                                                member, day.day, 'Approved',
                                                setDialogState, enrollmentDays, index,
                                              );
                                            },
                                            icon: const Icon(Icons.check_circle_outline, size: 16),
                                            label: const Text('Approve', style: TextStyle(fontSize: 12)),
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: Colors.green,
                                              foregroundColor: Colors.white,
                                              shape: RoundedRectangleBorder(
                                                borderRadius: BorderRadius.circular(8),
                                              ),
                                              padding: const EdgeInsets.symmetric(vertical: 8),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: ElevatedButton.icon(
                                            onPressed: () async {
                                              await _updateDayFinalStatus(
                                                member, day.day, 'Rejected',
                                                setDialogState, enrollmentDays, index,
                                              );
                                            },
                                            icon: const Icon(Icons.cancel_outlined, size: 16),
                                            label: const Text('Reject', style: TextStyle(fontSize: 12)),
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: Colors.red,
                                              foregroundColor: Colors.white,
                                              shape: RoundedRectangleBorder(
                                                borderRadius: BorderRadius.circular(8),
                                              ),
                                              padding: const EdgeInsets.symmetric(vertical: 8),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ],
                              ),
                            );
                          },
                        ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: const Text('Close',
                      style: TextStyle(color: _brandDark, fontWeight: FontWeight.w600)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _updateDayFinalStatus(
    EnrolledMember member,
    int dayNumber,
    String finalStatus,
    void Function(void Function()) setDialogState,
    List<MemberEnrollmentDay> enrollmentDays,
    int index,
  ) async {
    if (widget.miqaat == null) return;

    try {
      await _miqaatService.updateFinalStatus(
        miqaatId: widget.miqaat!.id,
        memberId: member.id,
        finalStatus: finalStatus,
        days: [dayNumber],
      );

      // Update local state for immediate feedback
      setDialogState(() {
        enrollmentDays[index] = MemberEnrollmentDay(
          day: dayNumber,
          status: enrollmentDays[index].status,
          finalStatus: finalStatus,
          adminStatus: enrollmentDays[index].adminStatus,
          miqaatDate: enrollmentDays[index].miqaatDate,
        );
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              finalStatus == 'Approved'
                  ? 'Day $dayNumber approved for ${member.fullName}'
                  : 'Day $dayNumber rejected for ${member.fullName}',
            ),
            backgroundColor: finalStatus == 'Approved' ? Colors.green : Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            duration: const Duration(seconds: 2),
          ),
        );
      }

      // Reload members in background
      _loadEnrolledMembers();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}

