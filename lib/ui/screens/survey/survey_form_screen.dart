import 'package:burhaniguardsapp/core/constants/app_colors.dart';
import 'package:burhaniguardsapp/core/constants/survey_constants.dart';
import 'package:burhaniguardsapp/core/services/local_storage_service.dart';
import 'package:burhaniguardsapp/core/services/survey_service.dart';
import 'package:burhaniguardsapp/core/utils/session_manager.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class SurveyFormScreen extends StatefulWidget {
  /// If true, show in preview/read-only mode
  final bool isPreview;

  const SurveyFormScreen({super.key, this.isPreview = false});

  @override
  State<SurveyFormScreen> createState() => _SurveyFormScreenState();
}

class _SurveyFormScreenState extends State<SurveyFormScreen>
    with SingleTickerProviderStateMixin {
  final SurveyService _surveyService = SurveyService();
  final LocalStorageService _localStorage = LocalStorageService();

  // Auto-filled fields
  String _itsId = '';
  String _fullName = '';
  String _contact = '';

  // Dropdown selections
  int? _selectedDepartmentId;
  int? _selectedZoneId;

  bool _isLoading = true;
  bool _isSubmitting = false;

  // Preview data
  Map<String, dynamic>? _surveyData;
  bool _hasSubmitted = false;

  late AnimationController _animController;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();

    _animController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _fadeAnim = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOut,
    );

    _loadData();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    try {
      final userData = await _localStorage.getUserData();
      if (userData == null) return;

      setState(() {
        _itsId = userData.itsId ?? '';
        _fullName = userData.fullName;
        _contact = userData.contact ?? '';
      });

      // Check if already submitted
      final hasSubmitted = await _surveyService.hasSubmitted();

      if (hasSubmitted || widget.isPreview) {
        // Load existing survey data
        final surveyData = await _surveyService.getMySurvey();
        setState(() {
          _hasSubmitted = true;
          _surveyData = surveyData;
          if (surveyData != null) {
            _selectedDepartmentId = surveyData['department'] as int?;
            _selectedZoneId = surveyData['zone'] as int?;
          }
          _isLoading = false;
        });
      } else {
        setState(() {
          _isLoading = false;
        });
      }

      _animController.forward();
    } catch (e) {
      setState(() => _isLoading = false);
      _animController.forward();
    }
  }

  Future<void> _submitSurvey() async {
    if (_selectedDepartmentId == null) {
      _showSnackBar('Please select a Department', Colors.red);
      return;
    }
    // Zone required only if department is NOT "Not Assigned Any Khidmat" (id=1)
    final isNotAssigned = _selectedDepartmentId == 1;
    if (!isNotAssigned && _selectedZoneId == null) {
      _showSnackBar('Please select a Zone', Colors.red);
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      await _surveyService.submitSurvey(
        department: _selectedDepartmentId!,
        zone: isNotAssigned ? 0 : _selectedZoneId!,
      );

      if (mounted) {
        _showSnackBar('Form submitted successfully!', Colors.green);
        // Go back after a short delay
        Future.delayed(const Duration(seconds: 1), () {
          if (mounted) Navigator.pop(context, true);
        });
      }
    } catch (e) {
      if (mounted) {
        if (SessionManager.isSessionExpired(e)) {
          SessionManager.handleSessionExpiry(context);
          return;
        }
        _showSnackBar(
          e.toString().replaceAll('Exception: ', ''),
          Colors.red,
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool showPreview = _hasSubmitted || widget.isPreview;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_rounded,
              color: AppColors.primaryDark, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Khidmat Survey',
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        centerTitle: true,
      ),
      body: _isLoading
          ? Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            )
          : FadeTransition(
              opacity: _fadeAnim,
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header Card
                    _buildHeaderCard(),
                    const SizedBox(height: 24),

                    // Auto-filled Member Info
                    _buildSectionTitle('Member Information'),
                    const SizedBox(height: 12),
                    _buildReadOnlyField('ITS', _itsId, Icons.badge_rounded),
                    const SizedBox(height: 12),
                    _buildReadOnlyField(
                        'Name', _fullName, Icons.person_rounded),
                    const SizedBox(height: 12),
                    _buildReadOnlyField(
                        'Mobile No', _contact, Icons.phone_rounded),
                    const SizedBox(height: 24),

                    // Department & Zone
                    _buildSectionTitle('Khidmat Details'),
                    const SizedBox(height: 12),

                    if (showPreview) ...[
                      _buildReadOnlyField(
                        'Department',
                        SurveyConstants.getDepartmentText(
                            _selectedDepartmentId ?? 0),
                        Icons.work_rounded,
                      ),
                      const SizedBox(height: 12),
                      _buildReadOnlyField(
                        'Zone',
                        SurveyConstants.getZoneText(_selectedZoneId ?? 0),
                        Icons.location_on_rounded,
                      ),
                    ] else ...[
                      _buildDropdown<int>(
                        label: 'Department',
                        icon: Icons.work_rounded,
                        value: _selectedDepartmentId,
                        items: SurveyConstants.departments
                            .map((d) => DropdownMenuItem<int>(
                                  value: d.id,
                                  child: Text(
                                    d.text,
                                    style: GoogleFonts.poppins(fontSize: 14),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ))
                            .toList(),
                        onChanged: (val) {
                          setState(() {
                            _selectedDepartmentId = val;
                            // Clear zone when "Not Assigned" is selected
                            if (val == 1) _selectedZoneId = null;
                          });
                        },
                        hint: 'Select Department',
                      ),
                      const SizedBox(height: 12),
                      // Zone dropdown — disabled when dept=1
                      IgnorePointer(
                        ignoring: _selectedDepartmentId == 1,
                        child: Opacity(
                          opacity: _selectedDepartmentId == 1 ? 0.45 : 1.0,
                          child: _buildDropdown<int>(
                            label: 'Zone',
                            icon: Icons.location_on_rounded,
                            value: _selectedDepartmentId == 1 ? null : _selectedZoneId,
                            items: SurveyConstants.zones
                                .map((z) => DropdownMenuItem<int>(
                                      value: z.id,
                                      child: Text(
                                        z.text,
                                        style: GoogleFonts.poppins(fontSize: 14),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ))
                                .toList(),
                            onChanged: (val) =>
                                setState(() => _selectedZoneId = val),
                            hint: _selectedDepartmentId == 1
                                ? 'Not applicable'
                                : 'Select Zone',
                          ),
                        ),
                      ),
                    ],

                    const SizedBox(height: 32),

                    // Submit Button (only if not preview)
                    if (!showPreview) _buildSubmitButton(),

                    if (showPreview)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE8F5E9),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: Colors.green.withOpacity(0.3),
                          ),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.check_circle_rounded,
                                color: Colors.green, size: 24),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'You have already submitted this survey. '
                                'Please Contact Jamiat Admin for any edits.',
                                style: GoogleFonts.poppins(
                                  fontSize: 14,
                                  color: Colors.green[800],
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildHeaderCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primaryDark, AppColors.primary],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.assignment_rounded,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Ashara Mubaraka Poona 1448',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            'Khidmat Allocation Status',
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w400,
              color: Colors.white.withOpacity(0.9),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: GoogleFonts.poppins(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
      ),
    );
  }

  Widget _buildReadOnlyField(String label, String value, IconData icon) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppColors.primary, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value.isNotEmpty ? value : '-',
                  style: GoogleFonts.poppins(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
          Icon(Icons.lock_rounded, color: Colors.grey[400], size: 16),
        ],
      ),
    );
  }

  Widget _buildDropdown<T>({
    required String label,
    required IconData icon,
    required T? value,
    required List<DropdownMenuItem<T>> items,
    required void Function(T?) onChanged,
    required String hint,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey[300]!),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(icon, color: AppColors.primary, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textSecondary,
                  ),
                ),
                DropdownButtonHideUnderline(
                  child: DropdownButton<T>(
                    value: value,
                    items: items,
                    onChanged: onChanged,
                    isExpanded: true,
                    hint: Text(
                      hint,
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: Colors.grey[400],
                      ),
                    ),
                    icon: Icon(Icons.keyboard_arrow_down_rounded,
                        color: AppColors.primary),
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: AppColors.textPrimary,
                    ),
                    isDense: true,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        onPressed: _isSubmitting ? null : _submitSurvey,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 4,
          shadowColor: AppColors.primary.withOpacity(0.3),
        ),
        child: _isSubmitting
            ? const SizedBox(
                height: 22,
                width: 22,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2.5,
                ),
              )
            : Text(
                'Submit Survey',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
      ),
    );
  }
}
