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
  List<EnrolledMember> _allMembers = []; // All members with status categories
  List<Map<String, dynamic>> _jamaatMembers = [];

  bool _isLoading = false;
  bool _isCaptain = false;
  bool _isCheckingRole = true;
  String? _userJamaat;
  
  // Tab selection: 0 = Enrolled, 1 = Pending, 2 = Rejected
  int _selectedTab = 0;

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  Future<void> _initializeData() async {
    await _checkUserRole();
    
    // Only proceed if user is Captain
    if (!_isCaptain) {
      setState(() {
        _isCheckingRole = false;
      });
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
      _isCaptain = userData?.roles == 2; // Captain role = 2
      _userJamaat = userData?.jamaat;
      _isCheckingRole = false;
    });
  }

  Future<void> _loadJamaatMembers() async {
    if (_userJamaat == null || _userJamaat!.isEmpty) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final members = await _userService.getMembersByJamaat(_userJamaat!);
      setState(() {
        _jamaatMembers = members;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load members: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _loadEnrolledMembers() async {
    if (widget.miqaat == null) return;

    setState(() {
      _isLoading = true;
    });

    try {
      // Use getAllMembersByMiqaatId to get members with status categories
      final members =
          await _miqaatService.getAllMembersByMiqaatId(widget.miqaat!.id);
      setState(() {
        _allMembers = members;
        // Also populate _enrolledMembers for backward compatibility
        _enrolledMembers = members.where((m) => m.statusCategory == 'Enrolled').toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load members: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Get members filtered by selected tab
  List<EnrolledMember> get _filteredMembers {
    switch (_selectedTab) {
      case 0: // Enrolled
        return _allMembers.where((m) => m.statusCategory == 'Enrolled').toList();
      case 1: // Pending
        return _allMembers.where((m) => m.statusCategory == 'Pending').toList();
      case 2: // Rejected
        return _allMembers.where((m) => m.statusCategory == 'Rejected').toList();
      default:
        return _allMembers;
    }
  }

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
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.miqaat != null
                                    ? 'Approved Enrolled members to mark attendance'
                                    : 'Members List',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black,
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
                                // Reload members if needed
                                if (widget.miqaat != null) {
                                  _loadEnrolledMembers();
                                } else {
                                  _loadJamaatMembers();
                                }
                              });
                            },
                            icon: const Icon(Icons.add, size: 18),
                            label: const Text('Add Member'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF4A1C1C),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  if (widget.miqaat != null)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: _buildMiqaatInfoCard(widget.miqaat!),
                    ),

                  // Tab Capsules for miqaat context
                  if (widget.miqaat != null && _isCaptain && !_isCheckingRole)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      child: _buildTabCapsules(),
                    ),

                  const SizedBox(height: 8),

                  // Members List
                  Expanded(
                    child: _isCheckingRole
                        ? const Center(child: CircularProgressIndicator())
                        : !_isCaptain
                            ? Center(
                                child: Padding(
                                  padding: const EdgeInsets.all(20.0),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.block,
                                        size: 64,
                                        color: Colors.red[300],
                                      ),
                                      const SizedBox(height: 16),
                                      const Text(
                                        'Only Captains can view this page',
                                        style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.red,
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        'You do not have permission to access the members list.',
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: Colors.grey[600],
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                    ],
                                  ),
                                ),
                              )
                            : _isLoading
                                ? const Center(child: CircularProgressIndicator())
                                : widget.miqaat != null
                            ? (_filteredMembers.isEmpty
                                ? Center(
                                    child: Padding(
                                      padding: const EdgeInsets.all(20.0),
                                      child: Text(
                                        _selectedTab == 0 
                                            ? 'No enrolled members found'
                                            : _selectedTab == 1 
                                                ? 'No pending members found'
                                                : 'No rejected members found',
                                        style: const TextStyle(
                                          fontSize: 14,
                                          color: Colors.grey,
                                        ),
                                      ),
                                    ),
                                  )
                                : ListView.builder(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 20),
                                    itemCount: _filteredMembers.length,
                                    itemBuilder: (context, index) {
                                      final member = _filteredMembers[index];
                                      return _buildMemberCard(
                                        index + 1,
                                        member,
                                      );
                                    },
                                  ))
                            : (_jamaatMembers.isEmpty
                                ? const Center(
                                    child: Padding(
                                      padding: EdgeInsets.all(20.0),
                                      child: Text(
                                        'No members found',
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: Colors.grey,
                                        ),
                                      ),
                                    ),
                                  )
                                : ListView.builder(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 20),
                                    itemCount: _jamaatMembers.length,
                                    itemBuilder: (context, index) {
                                      final member = _jamaatMembers[index];
                                      return _buildJamaatMemberCard(
                                        index + 1,
                                        member,
                                      );
                                    },
                                  )),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabCapsules() {
    final enrolledCount = _allMembers.where((m) => m.statusCategory == 'Enrolled').length;
    final pendingCount = _allMembers.where((m) => m.statusCategory == 'Pending').length;
    final rejectedCount = _allMembers.where((m) => m.statusCategory == 'Rejected').length;

    return Row(
      children: [
        _buildTabCapsule(0, 'Enrolled', enrolledCount, Colors.green),
        const SizedBox(width: 4),
        _buildTabCapsule(1, 'Pending', pendingCount, Colors.orange),
        const SizedBox(width: 8),
        _buildTabCapsule(2, 'Rejected', rejectedCount, Colors.red),
      ],
    );
  }

  Widget _buildTabCapsule(int index, String label, int count, Color color) {
    final isSelected = _selectedTab == index;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _selectedTab = index;
          });
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFF4A1C1C) : Colors.grey[200],
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isSelected ? const Color(0xFF4A1C1C) : Colors.grey[300]!,
              width: 1,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  '$label ($count)',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: isSelected ? Colors.white : Colors.black87,
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

  Widget _buildMiqaatInfoCard(Miqaat miqaat) {
    final fromDateStr = _formatDate(miqaat.fromDate);
    final tillDateStr = _formatDate(miqaat.tillDate);
    final dateDisplay = fromDateStr == tillDateStr
        ? fromDateStr
        : '$fromDateStr - $tillDateStr';
    final durationDisplay = miqaat.durationLabel;

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 4),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF4A1C1C), Color(0xFF6B2D2D)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF4A1C1C).withOpacity(0.3),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Miqaat Name
          Text(
            miqaat.miqaatName,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 8),
          // Date Row
          Row(
            children: [
              const Icon(Icons.calendar_today, color: Colors.white70, size: 14),
              const SizedBox(width: 6),
              Text(
                dateDisplay,
                style: const TextStyle(fontSize: 12, color: Colors.white),
              ),
            ],
          ),
          const SizedBox(height: 4),
          // Days and Location Row
          Row(
            children: [
              // Days
              const Icon(Icons.access_time, color: Colors.white70, size: 14),
              const SizedBox(width: 6),
              Text(
                durationDisplay,
                style: const TextStyle(fontSize: 12, color: Colors.white),
              ),
              const SizedBox(width: 20),
              // Location
              const Icon(Icons.location_on, color: Colors.white70, size: 14),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  '${miqaat.jamaat}, ${miqaat.jamiyat}',
                  style: const TextStyle(fontSize: 12, color: Colors.white),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMemberCard(int number, EnrolledMember member) {
    final finalStatus = member.finalStatus;
    final isApproved = finalStatus == 'Approved';
    final isRejected = finalStatus == 'Rejected';

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey[300]!, width: 1),
      ),
      child: Row(
        children: [
          // Number
          Text(
            number.toString().padLeft(2, '0'),
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Colors.grey,
            ),
          ),
          const SizedBox(width: 8),

          // Avatar
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.person, color: Colors.grey, size: 18),
          ),
          const SizedBox(width: 10),

          // Name and Status
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  member.fullName,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.black,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                // Show captain approval status only for Enrolled members
                if (member.statusCategory == 'Enrolled') ...[
                  if (isApproved)
                    const Text(
                      'Captain Approved',
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.green,
                        fontWeight: FontWeight.w500,
                      ),
                    )
                  else if (isRejected)
                    const Text(
                      'Captain Rejected',
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.red,
                        fontWeight: FontWeight.w500,
                      ),
                    )
                  else
                    const Text(
                      'Pending Captain Approval',
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.orange,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                ],
              ],
            ),
          ),

          // Info Icon (show enrolled days)
          if (widget.miqaat != null)
            InkWell(
              onTap: () => _showEnrollmentDaysDialog(member),
              child: Container(
                padding: const EdgeInsets.all(5),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.info_outline,
                  color: Colors.blue,
                  size: 16,
                ),
              ),
            ),

          // Action Buttons (only show for Enrolled tab, and if not yet approved/rejected)
          if (widget.miqaat != null && _selectedTab == 0 && !isApproved && !isRejected) ...[
            const SizedBox(width: 6),
            InkWell(
              onTap: () => _handleApprove(member),
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: const BoxDecoration(
                  color: Colors.green,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check,
                  color: Colors.white,
                  size: 14,
                ),
              ),
            ),
            const SizedBox(width: 6),
            InkWell(
              onTap: () => _handleReject(member),
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: const BoxDecoration(
                  color: Colors.red,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.close,
                  color: Colors.white,
                  size: 14,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _handleApprove(EnrolledMember member) async {
    if (widget.miqaat == null) return;

    try {
      await _miqaatService.updateFinalStatus(
        miqaatId: widget.miqaat!.id,
        memberId: member.id,
        finalStatus: 'Approved',
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Member approved successfully'),
            backgroundColor: Colors.green,
          ),
        );
        // Reload members
        await _loadEnrolledMembers();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to approve member: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _handleReject(EnrolledMember member) async {
    if (widget.miqaat == null) return;

    try {
      await _miqaatService.updateFinalStatus(
        miqaatId: widget.miqaat!.id,
        memberId: member.id,
        finalStatus: 'Rejected',
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Member rejected successfully'),
            backgroundColor: Colors.red,
          ),
        );
        // Reload members
        await _loadEnrolledMembers();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to reject member: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _showEnrollmentDaysDialog(EnrolledMember member) async {
    if (widget.miqaat == null) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(),
      ),
    );

    try {
      final enrollmentDays = await _miqaatService.getMemberEnrollmentDays(
        miqaatId: widget.miqaat!.id,
        memberId: member.id,
      );

      if (mounted) {
        Navigator.of(context).pop(); // Close loading dialog

        final approvedDays =
            enrollmentDays.where((d) => d.status == 'Approved').toList();

        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(
              member.fullName,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
            content: SizedBox(
              width: double.maxFinite,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Enrolled Days: ${approvedDays.length}',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (enrollmentDays.isEmpty)
                    const Text(
                      'No enrollment data available',
                      style: TextStyle(color: Colors.grey),
                    )
                  else
                    ConstrainedBox(
                      constraints: BoxConstraints(
                        maxHeight: MediaQuery.of(context).size.height * 0.4,
                      ),
                      child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: enrollmentDays.length,
                        itemBuilder: (context, index) {
                          final day = enrollmentDays[index];
                          final isEnrolled = day.status == 'Approved';
                          final statusColor = isEnrolled
                              ? Colors.green
                              : day.status == 'Rejected'
                                  ? Colors.red
                                  : Colors.orange;
                          final statusText = isEnrolled
                              ? 'Enrolled'
                              : day.status == 'Rejected'
                                  ? 'Rejected'
                                  : 'Not Enrolled';
                          final finalStatusColor =
                              day.finalStatus == 'Approved'
                                  ? Colors.green
                                  : day.finalStatus == 'Rejected'
                                      ? Colors.red
                                      : Colors.grey;

                          return Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: statusColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: statusColor.withOpacity(0.3),
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Day ${day.day}',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 14,
                                      ),
                                    ),
                                    Text(
                                      day.miqaatDate,
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                  ],
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: statusColor,
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text(
                                        statusText,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 11,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                    // Show captain status only for Enrolled users (when member enrolled themselves)
                                    if (day.finalStatus != null && day.status == 'Approved')
                                      Padding(
                                        padding: const EdgeInsets.only(top: 4),
                                        child: Text(
                                          'Captain: ${day.finalStatus}',
                                          style: TextStyle(
                                            fontSize: 10,
                                            color: finalStatusColor,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Close'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.of(context).pop(); // Close loading dialog
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load enrollment days: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Widget _buildJamaatMemberCard(int number, Map<String, dynamic> member) {
    final fullName = member['fullName'] as String? ?? member['FullName'] as String? ?? 'N/A';
    final contact = member['contact'] as String? ?? member['Contact'] as String? ?? 'N/A';
    final profile = member['profile'] as String? ?? member['Profile'] as String?;
    final isApproved = member['isApproved'] as bool? ?? member['IsApproved'] as bool? ?? true;

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

          // Profile Image
          _buildProfileImage(profile),
          const SizedBox(width: 12),

          // Name, Contact and Status
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  fullName,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 4),
                if (contact != 'N/A' && contact.isNotEmpty)
                  Text(
                    contact,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[700],
                    ),
                  ),
                const SizedBox(height: 4),
                if (!isApproved)
                  const Text(
                    'Awaiting Admin Approval',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.orange,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileImage(String? profilePath) {
    String? imageUrl;
    if (profilePath != null && profilePath.isNotEmpty) {
      if (profilePath.startsWith('http://') || profilePath.startsWith('https://')) {
        imageUrl = profilePath;
      } else {
        String cleanPath = profilePath.startsWith('/') 
            ? profilePath.substring(1) 
            : profilePath;
        if (!cleanPath.startsWith('bgp_uploads/')) {
          cleanPath = 'bgp_uploads/profile/$cleanPath';
        }
        imageUrl = '${ApiConstants.baseUrl}/$cleanPath';
      }
    }

    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: Colors.grey[300],
        shape: BoxShape.circle,
      ),
      child: imageUrl != null
          ? ClipOval(
              child: Image.network(
                imageUrl,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => const Icon(
                  Icons.person,
                  color: Colors.grey,
                  size: 24,
                ),
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return const Center(
                    child: CircularProgressIndicator(strokeWidth: 2),
                  );
                },
              ),
            )
          : const Icon(Icons.person, color: Colors.grey, size: 24),
    );
  }
}
