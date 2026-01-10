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
  List<Map<String, dynamic>> _jamaatMembers = [];

  bool _isLoading = false;
  bool _isCaptain = false;
  String? _userJamaat;

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  Future<void> _initializeData() async {
    await _checkUserRole();
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
      final members =
          await _miqaatService.getEnrolledMembersByMiqaatId(widget.miqaat!.id);
      setState(() {
        _enrolledMembers = members;
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
                          child: Text(
                            widget.miqaat != null
                                ? 'Enrolled Members - ${widget.miqaat!.miqaatName}'
                                : 'Members List',
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                            ),
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

                  const SizedBox(height: 20),

                  // Members List
                  Expanded(
                    child: _isLoading
                        ? const Center(child: CircularProgressIndicator())
                        : widget.miqaat != null
                            ? (_enrolledMembers.isEmpty
                                ? const Center(
                                    child: Padding(
                                      padding: EdgeInsets.all(20.0),
                                      child: Text(
                                        'No enrolled members found',
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
                                    itemCount: _enrolledMembers.length,
                                    itemBuilder: (context, index) {
                                      final member = _enrolledMembers[index];
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

  Widget _buildMemberCard(int number, EnrolledMember member) {
    final finalStatus = member.finalStatus;
    final isApproved = finalStatus == 'Approved';
    final isRejected = finalStatus == 'Rejected';

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
                  member.fullName,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 4),
                if (isApproved)
                  const Text(
                    'Approved by Captain',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.green,
                      fontWeight: FontWeight.w500,
                    ),
                  )
                else if (isRejected)
                  const Text(
                    'Rejected by Captain',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.red,
                      fontWeight: FontWeight.w500,
                    ),
                  )
                else
                  const Text(
                    'Enrolled - Pending Captain Approval',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.orange,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
              ],
            ),
          ),

          // Action Buttons (only show if miqaat is provided and not yet approved/rejected)
          if (widget.miqaat != null && !isApproved && !isRejected)
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: const BoxDecoration(
                    color: Colors.green,
                    shape: BoxShape.circle,
                  ),
                  child: InkWell(
                    onTap: () => _handleApprove(member),
                    child: const Icon(
                      Icons.check,
                      color: Colors.white,
                      size: 18,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: const BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                  ),
                  child: InkWell(
                    onTap: () => _handleReject(member),
                    child: const Icon(
                      Icons.close,
                      color: Colors.white,
                      size: 18,
                    ),
                  ),
                ),
              ],
            ),
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
