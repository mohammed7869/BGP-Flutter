import 'dart:convert';
import 'dart:io';
import 'package:burhaniguardsapp/core/constants/api_constants.dart';
import 'package:burhaniguardsapp/core/constants/app_colors.dart';
import 'package:burhaniguardsapp/core/services/local_storage_service.dart';
import 'package:burhaniguardsapp/core/services/miqaat_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:burhaniguardsapp/ui/screens/admin/memberMiqaatHistoryScreen.dart';
import 'package:burhaniguardsapp/ui/screens/common/bohraCalendarScreen.dart';
import 'package:burhaniguardsapp/ui/screens/admin/adminDashboard.dart';
import 'package:burhaniguardsapp/ui/screens/common/unified_login_screen.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;

class MiqaatAttendanceScreen extends StatefulWidget {
  final Miqaat miqaat;

  const MiqaatAttendanceScreen({Key? key, required this.miqaat})
      : super(key: key);

  @override
  State<MiqaatAttendanceScreen> createState() => _MiqaatAttendanceScreenState();
}

class _MiqaatAttendanceScreenState extends State<MiqaatAttendanceScreen> {
  final MiqaatService _miqaatService = MiqaatService();
  final LocalStorageService _localStorage = LocalStorageService();
  List<EnrolledMember> _members = [];
  final Set<int> _selectedMemberIds = {};
  bool _isLoading = true;
  bool _isMarkingAttendance = false;
  String? _errorMessage;
  int _selectedDay = 1;
  AttendanceWindowInfo? _windowInfo;

  DateTime _getSelectedDayDate() {
    return widget.miqaat.fromDate.add(Duration(days: _selectedDay - 1));
  }

  String _formatShortDate(DateTime date) {
    const months = [
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
    return '$day $month ${date.year}';
  }

  @override
  void initState() {
    super.initState();
    _loadMembers();
  }

  Future<void> _loadMembers() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final result = await _miqaatService.getApprovedMembersForAttendance(
        widget.miqaat.id,
        day: _selectedDay,
      );
      setState(() {
        _members = result.members;
        _windowInfo = result.windowInfo;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString().replaceAll('Exception: ', '');
        _isLoading = false;
      });
    }
  }

  void _toggleMemberSelection(int memberId) {
    // Don't allow selection if window is closed
    if (_windowInfo != null && !_windowInfo!.isOpen) return;
    
    setState(() {
      if (_selectedMemberIds.contains(memberId)) {
        _selectedMemberIds.remove(memberId);
      } else {
        _selectedMemberIds.add(memberId);
      }
    });
  }

  Future<void> _markAttendance() async {
    if (_selectedMemberIds.isEmpty) {
      return;
    }

    setState(() {
      _isMarkingAttendance = true;
      _errorMessage = null;
    });

    try {
      await _miqaatService.markAttendanceBatch(
        miqaatId: widget.miqaat.id,
        day: _selectedDay,
        memberIds: _selectedMemberIds.toList(),
      );

      // Refresh the list to update attendance status
      await _loadMembers();

      // Clear selection after successful marking
      setState(() {
        _selectedMemberIds.clear();
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Attendance marked successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      setState(() {
        _errorMessage = e.toString().replaceAll('Exception: ', '');
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_errorMessage ?? 'Failed to mark attendance'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() {
        _isMarkingAttendance = false;
      });
    }
  }

  bool _hasExistingReport() {
    return widget.miqaat.isReportSubmitted;
  }

  void _showReportDialog() {
    if (_hasExistingReport()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Report already submitted for this miqaat'),
          backgroundColor: Colors.orange,
          duration: Duration(seconds: 3),
        ),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => MiqaatReportBottomSheet(
        miqaatId: widget.miqaat.id,
        miqaatName: widget.miqaat.miqaatName,
        parentContext: this.context,
      ),
    );
  }

  void _showViewReportDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => MiqaatViewReportBottomSheet(
        miqaat: widget.miqaat,
      ),
    );
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
            child: const Text('Log Out',
                style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (shouldLogout == true && mounted) {
      await _localStorage.clearAll();
      if (mounted) {
        Navigator.of(context, rootNavigator: true).pushAndRemoveUntil(
          MaterialPageRoute(
              builder: (context) => const UnifiedLoginScreen()),
          (route) => false,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          // Premium AppBar with Calendar + Logout
          SafeArea(
            bottom: false,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
              decoration: BoxDecoration(
                gradient: widget.miqaat.isInternational
                    ? const LinearGradient(
                        colors: [Color(0xFF8B6914), Color(0xFFB8860B)],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      )
                    : AppColors.heroGradient,
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(24),
                  bottomRight: Radius.circular(24),
                ),
                boxShadow: [
                  BoxShadow(
                    color: (widget.miqaat.isInternational
                            ? const Color(0xFFB8860B)
                            : AppColors.primaryDark)
                        .withOpacity(0.30),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_rounded,
                        color: Colors.white, size: 28),
                    onPressed: () => Navigator.pop(context),
                  ),
                  Expanded(
                    child: Center(
                      child: Image.asset('assets/images/burhani guards logo.png',
                          height: 52),
                    ),
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.calendar_month_outlined,
                            color: Colors.white, size: 26),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  const BohraCalendarScreen(),
                            ),
                          );
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.logout_rounded,
                            color: Colors.white, size: 26),
                        onPressed: () => _handleLogout(context),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // Content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              widget.miqaat.miqaatName,
                              style: GoogleFonts.poppins(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ),
                          Container(
                            decoration: BoxDecoration(
                              color: _hasExistingReport()
                                  ? Colors.green.withOpacity(0.1)
                                  : AppColors.primary.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: IconButton(
                              icon: Icon(
                                _hasExistingReport()
                                    ? Icons.info_outline
                                    : Icons.note_add_outlined,
                                color: _hasExistingReport()
                                    ? Colors.green
                                    : AppColors.primary,
                                size: 22,
                              ),
                              onPressed: _hasExistingReport()
                                  ? _showViewReportDialog
                                  : _showReportDialog,
                              tooltip: _hasExistingReport()
                                  ? 'View Report'
                                  : 'Submit Report',
                              padding: const EdgeInsets.all(8),
                              constraints: const BoxConstraints(),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Attendance - Approved Members',
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      if (widget.miqaat.miqaatDays > 1) ...[
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Text(
                              'Day:',
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                color: AppColors.textPrimary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(width: 12),
                            DropdownButton<int>(
                              value: _selectedDay,
                              items: List.generate(
                                widget.miqaat.miqaatDays,
                                (i) => DropdownMenuItem(
                                  value: i + 1,
                                  child: Text(
                                    'Day ${i + 1} - ${_formatShortDate(widget.miqaat.fromDate.add(Duration(days: i)))}',
                                    style: GoogleFonts.poppins(fontSize: 13),
                                  ),
                                ),
                              ),
                              onChanged: (value) async {
                                if (value == null) return;
                                setState(() {
                                  _selectedDay = value;
                                  _selectedMemberIds.clear();
                                });
                                await _loadMembers();
                              },
                            ),
                            const SizedBox(width: 12),
                            Text(
                              _formatShortDate(_getSelectedDayDate()),
                              style: GoogleFonts.poppins(
                                fontSize: 13,
                                color: AppColors.textSecondary,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ],
                      // ── Attendance Window Info Banner ──
                      if (_windowInfo != null) ...[
                        const SizedBox(height: 12),
                        _buildWindowInfoBanner(),
                      ],
                      // ── Attendance Rules Note ──
                      const SizedBox(height: 8),
                      _buildAttendanceRulesNote(),
                    ],
                  ),
                ),

                if (_isLoading)
                  Expanded(
                    child: Center(
                      child: CircularProgressIndicator(
                        color: AppColors.primary,
                        strokeWidth: 3,
                      ),
                    ),
                  )
                else if (_errorMessage != null)
                  Expanded(
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            _errorMessage!,
                            style: GoogleFonts.poppins(
                              color: Colors.red,
                              fontSize: 14,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: _loadMembers,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: const Text('Retry'),
                          ),
                        ],
                      ),
                    ),
                  )
                else if (_members.isEmpty)
                  Expanded(
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.people_outline_rounded,
                            size: 56,
                            color: AppColors.primary.withOpacity(0.2),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'No approved members found',
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  Expanded(
                    child: RefreshIndicator(
                      onRefresh: _loadMembers,
                      color: AppColors.primary,
                      child: ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: _members.length,
                        itemBuilder: (context, index) {
                          final member = _members[index];
                          final isSelected = _selectedMemberIds.contains(member.id);
                          return _buildMemberCard(member, isSelected);
                        },
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomBar(),
    );
  }

  Widget? _buildBottomBar() {
    final bool windowClosed = _windowInfo != null && !_windowInfo!.isOpen;

    if (windowClosed) {
      // Show closed window message at bottom
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.red.shade50,
          border: Border(top: BorderSide(color: Colors.red.shade200)),
        ),
        child: SafeArea(
          child: Row(
            children: [
              Icon(Icons.lock_clock, color: Colors.red.shade700, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  _windowInfo?.isExpired == true
                      ? 'Attendance window has closed. Marking is no longer allowed.'
                      : 'Attendance window has not opened yet.',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: Colors.red.shade700,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_selectedMemberIds.isEmpty) return null;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      child: SafeArea(
        child: SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _isMarkingAttendance ? null : _markAttendance,
            style: ElevatedButton.styleFrom(
              backgroundColor: widget.miqaat.isInternational
                  ? const Color(0xFFB8860B)
                  : AppColors.primary,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              elevation: 4,
            ),
            child: _isMarkingAttendance
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor:
                          AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : Text(
                    'Mark Attended',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
          ),
        ),
      ),
    );
  }

  /// Builds the attendance window status banner
  Widget _buildWindowInfoBanner() {
    final info = _windowInfo!;
    Color bgColor;
    Color borderColor;
    Color iconColor;
    IconData icon;

    if (info.isOpen) {
      bgColor = const Color(0xFFE8F5E9);
      borderColor = const Color(0xFF66BB6A);
      iconColor = const Color(0xFF2E7D32);
      icon = Icons.check_circle_outline;
    } else if (info.isUpcoming) {
      bgColor = const Color(0xFFFFF8E1);
      borderColor = const Color(0xFFFFCA28);
      iconColor = const Color(0xFFF57F17);
      icon = Icons.schedule;
    } else {
      bgColor = const Color(0xFFFFEBEE);
      borderColor = const Color(0xFFEF5350);
      iconColor = const Color(0xFFC62828);
      icon = Icons.lock_clock;
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor.withOpacity(0.5)),
      ),
      child: Row(
        children: [
          Icon(icon, color: iconColor, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              info.message,
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: iconColor,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Builds the attendance rules note for captains
  Widget _buildAttendanceRulesNote() {
    final isSingleDay = widget.miqaat.miqaatDays == 1;
    final ruleText = isSingleDay
        ? 'For single-day miqaat: Attendance can be marked from ${_formatShortDate(widget.miqaat.fromDate)} until 24 hours after the miqaat ends.'
        : 'For multi-day miqaat: Attendance for each day can be marked starting from that day until 24 hours after that day ends.';

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.blue.shade100),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline, size: 16, color: Colors.blue.shade700),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              ruleText,
              style: GoogleFonts.poppins(
                fontSize: 11,
                color: Colors.blue.shade800,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMemberCard(EnrolledMember member, bool isSelected) {
    final isAttended = member.isAttended == true;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: isAttended
            ? const Color(0xFFF0FAF0)
            : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isSelected
              ? AppColors.primary
              : isAttended
                  ? Colors.green.withOpacity(0.3)
                  : Colors.grey.withOpacity(0.12),
          width: isSelected ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            GestureDetector(
              onTap: isAttended ? null : () => _toggleMemberSelection(member.id),
              child: isAttended
                  ? Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF2E7D32), Color(0xFF43A047)],
                        ),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.green.withOpacity(0.3),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.check_rounded,
                        color: Colors.white,
                        size: 18,
                      ),
                    )
                  : Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isSelected
                              ? AppColors.primary
                              : Colors.grey[400]!,
                          width: 2,
                        ),
                        color: Colors.white,
                      ),
                      child: isSelected
                          ? Center(
                              child: Container(
                                width: 12,
                                height: 12,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: AppColors.primary,
                                ),
                              ),
                            )
                          : null,
                    ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: InkWell(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => MemberMiqaatHistoryScreen(
                        memberId: member.id,
                        fullName: member.fullName,
                        itsId: member.itsId,
                        miqaatId: widget.miqaat.id,
                      ),
                    ),
                  );
                },
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      member.fullName,
                      style: GoogleFonts.poppins(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    if (member.itsId != null && member.itsId!.isNotEmpty) ...[
                      const SizedBox(height: 3),
                      Text(
                        'ITS ID: ${member.itsId}',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            if (isAttended)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF2E7D32), Color(0xFF43A047)],
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.green.withOpacity(0.25),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Text(
                  'Attended',
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class MiqaatReportBottomSheet extends StatefulWidget {
  final int miqaatId;
  final String miqaatName;
  final BuildContext parentContext;

  const MiqaatReportBottomSheet({
    Key? key,
    required this.miqaatId,
    required this.miqaatName,
    required this.parentContext,
  }) : super(key: key);

  @override
  State<MiqaatReportBottomSheet> createState() =>
      _MiqaatReportBottomSheetState();
}

class _MiqaatReportBottomSheetState extends State<MiqaatReportBottomSheet> {
  final LocalStorageService _localStorage = LocalStorageService();
  final TextEditingController _notesController = TextEditingController();
  final ImagePicker _picker = ImagePicker();
  XFile? _image1;
  XFile? _image2;
  bool _isSubmitting = false;

  // Khidmat options
  final List<String> _khidmatOptions = [
    'Flow Management',
    'Mawaid',
    'Parking',
    'Scanning',
    'Masjid Tanzeem',
    'Qasar Security',
    'Qadam Ziyafat',
    'Traffic',
    'Wajebat Bethak',
    'Audio Video Relay',
    'Other',
  ];

  // Selected khidmat map
  final Map<String, bool> _selectedKhidmat = {};

  @override
  void initState() {
    super.initState();
    // Initialize all khidmat options to false
    for (var option in _khidmatOptions) {
      _selectedKhidmat[option] = false;
    }
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(int imageNumber, ImageSource source) async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 80,
      );

      if (pickedFile != null) {
        setState(() {
          if (imageNumber == 1) {
            _image1 = pickedFile;
          } else {
            _image2 = pickedFile;
          }
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to pick image: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showImageSourceDialog(int imageNumber) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Select Image Source',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildSourceOption(
                    icon: Icons.camera_alt,
                    label: 'Camera',
                    onTap: () {
                      Navigator.pop(context);
                      _pickImage(imageNumber, ImageSource.camera);
                    },
                  ),
                  _buildSourceOption(
                    icon: Icons.photo_library,
                    label: 'Gallery',
                    onTap: () {
                      Navigator.pop(context);
                      _pickImage(imageNumber, ImageSource.gallery);
                    },
                  ),
                ],
              ),
              const SizedBox(height: 10),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSourceOption({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
        decoration: BoxDecoration(
          color: const Color(0xFF4A1C1C).withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(icon, size: 36, color: const Color(0xFF4A1C1C)),
            const SizedBox(height: 8),
            Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Color(0xFF4A1C1C),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submitReport() async {
    // Validate all fields are provided
    if (_image1 == null) {
      ScaffoldMessenger.of(widget.parentContext).showSnackBar(
        const SnackBar(
          content: Text('Image 1 is required'),
          backgroundColor: Colors.orange,
          duration: Duration(seconds: 3),
        ),
      );
      return;
    }
    if (_image2 == null) {
      ScaffoldMessenger.of(widget.parentContext).showSnackBar(
        const SnackBar(
          content: Text('Image 2 is required'),
          backgroundColor: Colors.orange,
          duration: Duration(seconds: 3),
        ),
      );
      return;
    }
    if (_notesController.text.trim().isEmpty) {
      ScaffoldMessenger.of(widget.parentContext).showSnackBar(
        const SnackBar(
          content: Text('Notes is required'),
          backgroundColor: Colors.orange,
          duration: Duration(seconds: 3),
        ),
      );
      return;
    }

    // Validate at least one khidmat is selected
    final selectedKhidmatList = _selectedKhidmat.entries
        .where((e) => e.value)
        .map((e) => e.key)
        .toList();
    if (selectedKhidmatList.isEmpty) {
      ScaffoldMessenger.of(widget.parentContext).showSnackBar(
        const SnackBar(
          content: Text('Please select at least one Khidmat'),
          backgroundColor: Colors.orange,
          duration: Duration(seconds: 3),
        ),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      final token = await _localStorage.getToken();
      if (token == null) {
        throw Exception('User not authenticated');
      }

      final url = Uri.parse(
          '${ApiConstants.baseUrl}${ApiConstants.createMiqaat}/${widget.miqaatId}/report');

      // Create multipart request
      var request = http.MultipartRequest('POST', url);
      request.headers['Authorization'] = 'Bearer $token';

      // Add images if available
      if (_image1 != null) {
        request.files.add(http.MultipartFile.fromBytes(
          'Image1',
          await _image1!.readAsBytes(),
          filename: _image1!.name,
        ));
      }
      if (_image2 != null) {
        request.files.add(http.MultipartFile.fromBytes(
          'Image2',
          await _image2!.readAsBytes(),
          filename: _image2!.name,
        ));
      }

      // Add notes if available
      if (_notesController.text.isNotEmpty) {
        request.fields['Notes'] = _notesController.text;
      }

      // Add khidmat done as JSON string
      request.fields['KhidmatDone'] = jsonEncode(selectedKhidmatList);

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        if (mounted) {
          Navigator.pop(context); // Close the bottom sheet
          ScaffoldMessenger.of(widget.parentContext).showSnackBar(
            const SnackBar(
              content: Text('Report submitted successfully'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 3),
            ),
          );
          // Navigate to Dashboard after successful report submission
          Navigator.of(widget.parentContext).pushAndRemoveUntil(
            MaterialPageRoute(builder: (_) => const AdminDashboardScreen()),
            (route) => false,
          );
        }
      } else {
        String errorMessage = 'Failed to submit report';
        try {
          final errorBody = jsonDecode(response.body);
          if (errorBody is Map && errorBody.containsKey('message')) {
            errorMessage = errorBody['message'] as String? ?? errorMessage;
          }
        } catch (_) {
          // If JSON parsing fails, use status code to determine error
          if (response.statusCode == 400) {
            errorMessage = 'Invalid request. Please check all fields.';
          } else if (response.statusCode == 403) {
            errorMessage = 'You do not have permission to submit reports.';
          } else if (response.statusCode == 404) {
            errorMessage = 'Miqaat not found.';
          }
        }
        throw Exception(errorMessage);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(widget.parentContext).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceAll('Exception: ', '')),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  void _clearForm() {
    setState(() {
      _image1 = null;
      _image2 = null;
      _notesController.clear();
      // Reset khidmat selections
      for (var option in _khidmatOptions) {
        _selectedKhidmat[option] = false;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: DraggableScrollableSheet(
        initialChildSize: 0.85,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) => SingleChildScrollView(
          controller: scrollController,
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handle bar
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              // Title
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFF4A1C1C).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.assignment_outlined,
                      color: Color(0xFF4A1C1C),
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Submit Report',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                        Text(
                          widget.miqaatName,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              // Image Section
              const Text(
                'Upload Images',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Add up to 2 images from camera or gallery',
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(child: _buildImagePicker(1, _image1)),
                  const SizedBox(width: 12),
                  Expanded(child: _buildImagePicker(2, _image2)),
                ],
              ),
              const SizedBox(height: 24),
              // Notes Section
              const Text(
                'Notes',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _notesController,
                maxLines: 4,
                decoration: InputDecoration(
                  hintText: 'Add any notes about this miqaat...',
                  hintStyle: TextStyle(color: Colors.grey[400]),
                  filled: true,
                  fillColor: Colors.grey[50],
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey[300]!),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey[300]!),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFF4A1C1C)),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              // Khidmat Done Section
              const Text(
                'Khidmat Done',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Select all khidmat performed during this miqaat',
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 12),
              // Khidmat checkboxes in a wrapped layout
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: _khidmatOptions.map((option) {
                  return SizedBox(
                    width: (MediaQuery.of(context).size.width - 56) / 2,
                    child: CheckboxListTile(
                      title: Text(
                        option,
                        style: const TextStyle(fontSize: 13),
                      ),
                      value: _selectedKhidmat[option] ?? false,
                      onChanged: (bool? value) {
                        setState(() {
                          _selectedKhidmat[option] = value ?? false;
                        });
                      },
                      controlAffinity: ListTileControlAffinity.leading,
                      contentPadding: EdgeInsets.zero,
                      dense: true,
                      activeColor: const Color(0xFF4A1C1C),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 32),
              // Buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _isSubmitting ? null : _clearForm,
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        side: const BorderSide(color: Color(0xFF4A1C1C)),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Clear',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF4A1C1C),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      onPressed: _isSubmitting ? null : _submitReport,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF4A1C1C),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: _isSubmitting
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor:
                                    AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.send, color: Colors.white, size: 20),
                                SizedBox(width: 8),
                                Text(
                                  'Submit Report',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImagePicker(int imageNumber, XFile? image) {
    return GestureDetector(
      onTap: () => _showImageSourceDialog(imageNumber),
      child: Container(
        height: 140,
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: image != null ? const Color(0xFF4A1C1C) : Colors.grey[300]!,
            width: image != null ? 2 : 1,
          ),
        ),
        child: image != null
            ? Stack(
                fit: StackFit.expand,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(11),
                    child: kIsWeb
                        ? Image.network(image.path, fit: BoxFit.cover)
                        : Image.file(File(image.path), fit: BoxFit.cover),
                  ),
                  Positioned(
                    top: 4,
                    right: 4,
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          if (imageNumber == 1) {
                            _image1 = null;
                          } else {
                            _image2 = null;
                          }
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.close,
                          color: Colors.white,
                          size: 16,
                        ),
                      ),
                    ),
                  ),
                ],
              )
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.add_photo_alternate_outlined,
                    size: 40,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Image $imageNumber',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey[500],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Tap to add',
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey[400],
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

// View Report Bottom Sheet - Premium view-only display
class MiqaatViewReportBottomSheet extends StatefulWidget {
  final Miqaat miqaat;

  const MiqaatViewReportBottomSheet({
    Key? key,
    required this.miqaat,
  }) : super(key: key);

  @override
  State<MiqaatViewReportBottomSheet> createState() =>
      _MiqaatViewReportBottomSheetState();
}

class _MiqaatViewReportBottomSheetState
    extends State<MiqaatViewReportBottomSheet>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  int _currentImageIndex = 0;
  final PageController _pageController = PageController();

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
      ),
    );

    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.1), end: Offset.zero).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.2, 1.0, curve: Curves.easeOutCubic),
      ),
    );

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  List<String> get _images {
    final images = <String>[];
    if (widget.miqaat.miqaatImage1 != null) {
      images.add(widget.miqaat.miqaatImage1!);
    }
    if (widget.miqaat.miqaatImage2 != null) {
      images.add(widget.miqaat.miqaatImage2!);
    }
    return images;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: DraggableScrollableSheet(
        initialChildSize: 0.85,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) => FadeTransition(
          opacity: _fadeAnimation,
          child: SlideTransition(
            position: _slideAnimation,
            child: SingleChildScrollView(
              controller: scrollController,
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Handle bar
                  Center(
                    child: Container(
                      width: 48,
                      height: 5,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  // Title with success indicator
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.green.shade400,
                              Colors.green.shade600,
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.green.withOpacity(0.3),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.check_circle_outline,
                          color: Colors.white,
                          size: 28,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Report Submitted',
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              widget.miqaat.miqaatName,
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[600],
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 28),

                  // Images Section
                  if (_images.isNotEmpty) ...[
                    _buildSectionHeader(Icons.photo_library_outlined, 'Photos'),
                    const SizedBox(height: 12),
                    Container(
                      height: 220,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.08),
                            blurRadius: 16,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Stack(
                        children: [
                          PageView.builder(
                            controller: _pageController,
                            onPageChanged: (index) {
                              setState(() {
                                _currentImageIndex = index;
                              });
                            },
                            itemCount: _images.length,
                            itemBuilder: (context, index) {
                              return Container(
                                margin:
                                    const EdgeInsets.symmetric(horizontal: 2),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(16),
                                  child: Image.network(
                                    '${ApiConstants.miqaatImagesBaseUrl}/${_images[index]}',
                                    fit: BoxFit.contain,
                                    loadingBuilder:
                                        (context, child, loadingProgress) {
                                      if (loadingProgress == null) return child;
                                      return Container(
                                        color: Colors.grey[100],
                                        child: Center(
                                          child: CircularProgressIndicator(
                                            value: loadingProgress
                                                        .expectedTotalBytes !=
                                                    null
                                                ? loadingProgress
                                                        .cumulativeBytesLoaded /
                                                    loadingProgress
                                                        .expectedTotalBytes!
                                                : null,
                                            color: const Color(0xFF4A1C1C),
                                          ),
                                        ),
                                      );
                                    },
                                    errorBuilder: (context, error, stackTrace) {
                                      return Container(
                                        color: Colors.grey[200],
                                        child: Column(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            Icon(Icons.broken_image_outlined,
                                                size: 48,
                                                color: Colors.grey[400]),
                                            const SizedBox(height: 8),
                                            Text(
                                              'Image not available',
                                              style: TextStyle(
                                                  color: Colors.grey[500]),
                                            ),
                                          ],
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              );
                            },
                          ),
                          // Page indicator
                          if (_images.length > 1)
                            Positioned(
                              bottom: 12,
                              left: 0,
                              right: 0,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: List.generate(
                                  _images.length,
                                  (index) => AnimatedContainer(
                                    duration: const Duration(milliseconds: 300),
                                    margin: const EdgeInsets.symmetric(
                                        horizontal: 4),
                                    width:
                                        _currentImageIndex == index ? 24 : 8,
                                    height: 8,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(4),
                                      color: _currentImageIndex == index
                                          ? Colors.white
                                          : Colors.white.withOpacity(0.5),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.2),
                                          blurRadius: 4,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],

                  // Notes Section
                  if (widget.miqaat.notes != null &&
                      widget.miqaat.notes!.isNotEmpty) ...[
                    _buildSectionHeader(Icons.notes_outlined, 'Notes'),
                    const SizedBox(height: 12),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.grey[50],
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: Colors.grey[200]!),
                      ),
                      child: Text(
                        widget.miqaat.notes!,
                        style: TextStyle(
                          fontSize: 15,
                          color: Colors.grey[800],
                          height: 1.5,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],

                  // Khidmat Section
                  if (widget.miqaat.khidmatDone != null &&
                      widget.miqaat.khidmatDone!.isNotEmpty) ...[
                    _buildSectionHeader(Icons.volunteer_activism_outlined,
                        'Khidmat Performed'),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: widget.miqaat.khidmatDone!.asMap().entries.map(
                        (entry) {
                          final index = entry.key;
                          final khidmat = entry.value;
                          return TweenAnimationBuilder<double>(
                            tween: Tween(begin: 0.0, end: 1.0),
                            duration: Duration(milliseconds: 400 + (index * 80)),
                            curve: Curves.easeOutBack,
                            builder: (context, value, child) {
                              return Transform.scale(
                                scale: value,
                                child: Opacity(
                                  opacity: value.clamp(0.0, 1.0),
                                  child: child,
                                ),
                              );
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 10),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    const Color(0xFF4A1C1C),
                                    const Color(0xFF6B2D2D),
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                borderRadius: BorderRadius.circular(25),
                                boxShadow: [
                                  BoxShadow(
                                    color:
                                        const Color(0xFF4A1C1C).withOpacity(0.25),
                                    blurRadius: 8,
                                    offset: const Offset(0, 3),
                                  ),
                                ],
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.check_circle,
                                    color: Colors.white,
                                    size: 18,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    khidmat,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ).toList(),
                    ),
                    const SizedBox(height: 24),
                  ],

                  // Close Button
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.grey[100],
                        foregroundColor: Colors.grey[700],
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        elevation: 0,
                      ),
                      child: const Text(
                        'Close',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(IconData icon, String title) {
    return Row(
      children: [
        Icon(
          icon,
          color: const Color(0xFF4A1C1C),
          size: 22,
        ),
        const SizedBox(width: 10),
        Text(
          title,
          style: const TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
      ],
    );
  }
}
