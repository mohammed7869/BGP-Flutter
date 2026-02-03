import 'dart:convert';
import 'dart:io';
import 'package:burhaniguardsapp/core/constants/api_constants.dart';
import 'package:burhaniguardsapp/core/services/local_storage_service.dart';
import 'package:burhaniguardsapp/core/services/miqaat_service.dart';
import 'package:flutter/material.dart';
import 'package:burhaniguardsapp/ui/screens/admin/memberMiqaatHistoryScreen.dart';
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
      final members = await _miqaatService.getApprovedMembersForAttendance(
        widget.miqaat.id,
        day: _selectedDay,
      );
      setState(() {
        _members = members;
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

  void _showReportDialog() {
    // Check if report already exists
    final hasExistingReport = widget.miqaat.miqaatImage1 != null ||
        widget.miqaat.miqaatImage2 != null ||
        (widget.miqaat.notes != null && widget.miqaat.notes!.isNotEmpty);

    if (hasExistingReport) {
      
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          // Custom AppBar with curved bottom
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
            decoration: const BoxDecoration(
              color: Color(0xFF4A1C1C),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(20),
                bottomRight: Radius.circular(20),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back,
                      color: Colors.white, size: 28),
                  onPressed: () {
                    Navigator.pop(context);
                  },
                ),
                Image.asset('assets/images/burhani guards logo.png',
                    height: 52),
                IconButton(
                  icon: const Icon(Icons.notifications_outlined,
                      color: Colors.white, size: 28),
                  onPressed: () {},
                ),
              ],
            ),
          ),

          // Content
          Expanded(
            child: Container(
              color: Colors.white,
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
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.black,
                                ),
                              ),
                            ),
                            Container(
                              decoration: BoxDecoration(
                                color: const Color(0xFF4A1C1C).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: IconButton(
                                icon: const Icon(
                                  Icons.note_add_outlined,
                                  color: Color(0xFF4A1C1C),
                                  size: 22,
                                ),
                                onPressed: _showReportDialog,
                                tooltip: 'Submit Report',
                                padding: const EdgeInsets.all(8),
                                constraints: const BoxConstraints(),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Attendance - Approved Members',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                        if (widget.miqaat.miqaatDays > 1) ...[
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Text(
                                'Day:',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[700],
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
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.grey[600],
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),

                  if (_isLoading)
                    const Expanded(
                      child: Center(
                        child: CircularProgressIndicator(),
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
                              style: const TextStyle(
                                color: Colors.red,
                                fontSize: 14,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: _loadMembers,
                              child: const Text('Retry'),
                            ),
                          ],
                        ),
                      ),
                    )
                  else if (_members.isEmpty)
                    const Expanded(
                      child: Center(
                        child: Text(
                          'No approved members found',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey,
                          ),
                        ),
                      ),
                    )
                  else
                    Expanded(
                      child: RefreshIndicator(
                        onRefresh: _loadMembers,
                        child: ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
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
          ),
        ],
      ),
      bottomNavigationBar: _selectedMemberIds.isNotEmpty
          ? Container(
              padding: const EdgeInsets.all(16),
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
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isMarkingAttendance ? null : _markAttendance,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF4A1C1C),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
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
                        : const Text(
                            'Mark Attended',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                  ),
                ),
              ),
            )
          : null,
    );
  }

  Widget _buildMemberCard(EnrolledMember member, bool isSelected) {
    final isAttended = member.isAttended == true;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isSelected ? const Color(0xFF4A1C1C) : Colors.grey[300]!,
          width: isSelected ? 2 : 1,
        ),
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: isAttended ? null : () => _toggleMemberSelection(member.id),
            child: isAttended
                ? const Icon(
                    Icons.check_circle,
                    color: Colors.green,
                    size: 26,
                  )
                : Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isSelected
                            ? const Color(0xFF4A1C1C)
                            : Colors.grey[700]!,
                        width: 2,
                      ),
                      color: Colors.white,
                    ),
                    child: isSelected
                        ? Center(
                            child: Container(
                              width: 12,
                              height: 12,
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                color: Color(0xFF4A1C1C),
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
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 4),
                  if (member.itsId != null && member.itsId!.isNotEmpty)
                    Text(
                      'ITS ID: ${member.itsId}',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                ],
              ),
            ),
          ),
          if (isAttended)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.green,
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Text(
                'Attended',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
        ],
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
  File? _image1;
  File? _image2;
  bool _isSubmitting = false;

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
            _image1 = File(pickedFile.path);
          } else {
            _image2 = File(pickedFile.path);
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
        request.files.add(await http.MultipartFile.fromPath(
          'Image1',
          _image1!.path,
        ));
      }
      if (_image2 != null) {
        request.files.add(await http.MultipartFile.fromPath(
          'Image2',
          _image2!.path,
        ));
      }

      // Add notes if available
      if (_notesController.text.isNotEmpty) {
        request.fields['Notes'] = _notesController.text;
      }

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        if (mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(widget.parentContext).showSnackBar(
            const SnackBar(
              content: Text('Report submitted successfully'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 3),
            ),
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

  Widget _buildImagePicker(int imageNumber, File? image) {
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
                    child: Image.file(
                      image,
                      fit: BoxFit.cover,
                    ),
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
