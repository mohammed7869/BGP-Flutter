import 'package:burhaniguardsapp/core/constants/app_colors.dart';
import 'package:burhaniguardsapp/core/models/qardan_hasana_model.dart';
import 'package:burhaniguardsapp/core/services/qardan_hasana_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class QardanEditScreen extends StatefulWidget {
  final QardanHasanaApplication application;

  const QardanEditScreen({Key? key, required this.application})
      : super(key: key);

  @override
  State<QardanEditScreen> createState() => _QardanEditScreenState();
}

class _QardanEditScreenState extends State<QardanEditScreen> {
  final _formKey = GlobalKey<FormState>();
  final _scrollController = ScrollController();
  final QardanHasanaService _service = QardanHasanaService();

  // Controllers
  final _nameController = TextEditingController();
  final _occupationController = TextEditingController();
  final _mobileController = TextEditingController();
  final _reasonController = TextEditingController();
  final _amountController = TextEditingController();

  // Guarantors
  List<JamaatMember> _jamaatMembers = [];
  JamaatMember? _selectedGuarantor1;
  JamaatMember? _selectedGuarantor2;

  bool _isLoading = true;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _populateFields();
    _loadMembers();
  }

  void _populateFields() {
    final app = widget.application;
    _nameController.text = app.applicantName;
    _occupationController.text = app.applicantOccupation ?? '';
    _mobileController.text = app.applicantMobile;
    _reasonController.text = app.reason ?? '';
    _amountController.text = app.amountRequested.toStringAsFixed(0);
  }

  Future<void> _loadMembers() async {
    try {
      _jamaatMembers = await _service.getMembersByJamaat();

      final currentG1Id = widget.application.captainMemberId;
      final currentG2Id = widget.application.guarantorMemberId;

      final isG1Rejected = !widget.application.captainApproved &&
          (widget.application.rejectedGuarantorMemberIds.contains(currentG1Id) ||
              (widget.application.rejectionReason != null &&
                  widget.application.rejectionReason!.contains('Guarantor 1')));

      final isG2Rejected = !widget.application.guarantorApproved &&
          (widget.application.rejectedGuarantorMemberIds.contains(currentG2Id) ||
              (widget.application.rejectionReason != null &&
                  widget.application.rejectionReason!.contains('Guarantor 2')));

      // Pre-select Guarantor 1
      if (widget.application.captainApproved) {
        _selectedGuarantor1 = _jamaatMembers.cast<JamaatMember?>().firstWhere(
              (m) => m?.id == currentG1Id,
              orElse: () => JamaatMember(
                id: currentG1Id,
                fullName: widget.application.captainName,
                contact: widget.application.captainMobile,
                itsId: widget.application.captainItsId ?? '',
              ),
            );
      } else if (isG1Rejected) {
        _selectedGuarantor1 = null; // Force user to pick a new one
      } else {
        _selectedGuarantor1 = _jamaatMembers.cast<JamaatMember?>().firstWhere(
              (m) => m?.id == currentG1Id,
              orElse: () => null,
            );
      }

      // Pre-select Guarantor 2
      if (widget.application.guarantorApproved) {
        _selectedGuarantor2 = _jamaatMembers.cast<JamaatMember?>().firstWhere(
              (m) => m?.id == currentG2Id,
              orElse: () => JamaatMember(
                id: currentG2Id,
                fullName: widget.application.guarantorName,
                contact: widget.application.guarantorMobile,
                itsId: widget.application.guarantorItsId ?? '',
              ),
            );
      } else if (isG2Rejected) {
        _selectedGuarantor2 = null; // Force user to pick a new one
      } else {
        _selectedGuarantor2 = _jamaatMembers.cast<JamaatMember?>().firstWhere(
              (m) => m?.id == currentG2Id,
              orElse: () => null,
            );
      }

      setState(() => _isLoading = false);
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading members: ${e.toString()}'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Future<void> _submitEdit() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedGuarantor1 == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select Guarantor 1'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    if (_selectedGuarantor2 == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select Guarantor 2'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    if (_selectedGuarantor1!.id == _selectedGuarantor2!.id) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Guarantor 1 and Guarantor 2 cannot be the same person'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    if (!widget.application.captainApproved &&
        widget.application.rejectedGuarantorMemberIds.contains(_selectedGuarantor1!.id)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
              'Selected Guarantor 1 has already rejected this application. Please select a different member.'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    if (!widget.application.guarantorApproved &&
        widget.application.rejectedGuarantorMemberIds.contains(_selectedGuarantor2!.id)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
              'Selected Guarantor 2 has already rejected this application. Please select a different member.'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      await _service.updateApplication(
        applicationId: widget.application.id,
        applicantName: _nameController.text.trim(),
        applicantOccupation: _occupationController.text.trim(),
        applicantMobile: _mobileController.text.trim(),
        reason: _reasonController.text.trim().isEmpty
            ? null
            : _reasonController.text.trim(),
        amountRequested: double.parse(_amountController.text.trim()),
        guarantor1MemberId: _selectedGuarantor1!.id,
        guarantorMemberId: _selectedGuarantor2!.id,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Application updated successfully!'),
            backgroundColor: AppColors.success,
          ),
        );
        Navigator.pop(context, true); // Return true to indicate changes were made
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content:
                Text(e.toString().replaceAll('Exception: ', '')),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _occupationController.dispose();
    _mobileController.dispose();
    _reasonController.dispose();
    _amountController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isG1Approved = widget.application.captainApproved;
    final isG2Approved = widget.application.guarantorApproved;
    final currentG1Id = widget.application.captainMemberId;
    final currentG2Id = widget.application.guarantorMemberId;

    final isG1Rejected = !isG1Approved &&
        (widget.application.rejectedGuarantorMemberIds.contains(currentG1Id) ||
            (widget.application.rejectionReason != null &&
                widget.application.rejectionReason!.contains('Guarantor 1')));

    final isG2Rejected = !isG2Approved &&
        (widget.application.rejectedGuarantorMemberIds.contains(currentG2Id) ||
            (widget.application.rejectionReason != null &&
                widget.application.rejectionReason!.contains('Guarantor 2')));

    String bannerText;
    Color bannerColor = AppColors.info;
    IconData bannerIcon = Icons.info_outline;

    if (isG1Approved && !isG2Approved) {
      bannerText =
          'Guarantor 1 has already approved. You can change Guarantor 2 and update other details.';
    } else if (isG2Approved && !isG1Approved) {
      bannerText =
          'Guarantor 2 has already approved. You can change Guarantor 1 and update other details.';
    } else if (isG1Rejected || isG2Rejected) {
      bannerColor = AppColors.error;
      bannerIcon = Icons.error_outline;
      bannerText =
          'A guarantor rejected this application. Please select a different member.';
    } else {
      bannerText =
          'Editing ${widget.application.applicationNo}. Changes will notify guarantors for approval.';
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        title: const Text(
          'Edit Application',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
        ),
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primary))
          : SingleChildScrollView(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Info Banner
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: bannerColor.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: bannerColor.withOpacity(0.2)),
                      ),
                      child: Row(
                        children: [
                          Icon(bannerIcon, color: bannerColor, size: 20),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              bannerText,
                              style: TextStyle(
                                  fontSize: 13,
                                  color: bannerColor == AppColors.error
                                      ? AppColors.error
                                      : AppColors.textSecondary,
                                  fontWeight: bannerColor == AppColors.error
                                      ? FontWeight.w500
                                      : FontWeight.normal),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Read-only fields
                    _buildReadOnlyField(
                        'Mohallah', widget.application.applicantJamaat),
                    _buildReadOnlyField(
                        'ITS No', widget.application.applicantItsId),

                    const SizedBox(height: 8),
                    const Divider(),
                    const SizedBox(height: 8),

                    const Text(
                      'Editable Fields',
                      style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary),
                    ),
                    const SizedBox(height: 16),

                    // Name (As Per Bank)
                    _buildTextField(
                      controller: _nameController,
                      label: 'Name (As Per Bank) *',
                      icon: Icons.person_outline,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Name is required';
                        }
                        return null;
                      },
                    ),

                    // Occupation
                    _buildTextField(
                      controller: _occupationController,
                      label: 'Occupation *',
                      icon: Icons.work_outline,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Occupation is required';
                        }
                        return null;
                      },
                    ),

                    // Mobile No
                    _buildTextField(
                      controller: _mobileController,
                      label: 'Mobile No *',
                      icon: Icons.phone_outlined,
                      keyboardType: TextInputType.phone,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(10),
                      ],
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Mobile No is required';
                        }
                        if (value.trim().length < 10) {
                          return 'Enter a valid 10-digit mobile number';
                        }
                        return null;
                      },
                    ),

                    // Reason
                    _buildTextField(
                      controller: _reasonController,
                      label: 'Reason for Qardan',
                      icon: Icons.description_outlined,
                      maxLines: 3,
                    ),

                    // Amount
                    _buildTextField(
                      controller: _amountController,
                      label: 'Amount (In Figure) *',
                      icon: Icons.currency_rupee,
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                      ],
                      prefixText: '₹ ',
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Amount is required';
                        }
                        final amount = int.tryParse(value.trim());
                        if (amount == null || amount <= 0) {
                          return 'Enter a valid amount';
                        }
                        if (amount > 20000) {
                          return 'Maximum amount is ₹20,000';
                        }
                        return null;
                      },
                    ),

                    // Guarantor 1
                    const SizedBox(height: 4),
                    if (isG1Approved) ...[
                      _buildApprovedGuarantorCard(
                        roleLabel: 'Guarantor 1',
                        fullName: widget.application.captainName,
                        itsId: widget.application.captainItsId ?? '—',
                        contact: widget.application.captainMobile ?? '—',
                      ),
                    ] else ...[
                      if (isG1Rejected) ...[
                        Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: AppColors.error.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                                color: AppColors.error.withOpacity(0.2)),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.info_outline,
                                  color: AppColors.error, size: 16),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  'Guarantor 1 (${widget.application.captainName}) rejected. Please select a different member.',
                                  style: const TextStyle(
                                      fontSize: 12, color: AppColors.error),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: AppColors.cardShadow,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Row(
                              children: [
                                Icon(Icons.people_outline,
                                    color: AppColors.primary, size: 20),
                                SizedBox(width: 8),
                                Text('Guarantor 1 *',
                                    style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.textPrimary)),
                              ],
                            ),
                            const SizedBox(height: 12),
                            DropdownButtonFormField<JamaatMember>(
                              value: _selectedGuarantor1,
                              isExpanded: true,
                              decoration: InputDecoration(
                                border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10)),
                                contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 14, vertical: 12),
                                hintText: 'Select Guarantor 1',
                              ),
                              items: _jamaatMembers.map((m) {
                                final isOtherSelected = _selectedGuarantor2 != null &&
                                    _selectedGuarantor2!.id == m.id;
                                final hasRejected = widget
                                    .application.rejectedGuarantorMemberIds
                                    .contains(m.id);
                                final isDisabled = isOtherSelected || hasRejected;

                                String label = '${m.fullName} (${m.itsId})';
                                if (hasRejected) {
                                  label += ' (Rejected)';
                                } else if (isOtherSelected) {
                                  label += ' (Selected as G2)';
                                }

                                return DropdownMenuItem<JamaatMember>(
                                  value: m,
                                  enabled: !isDisabled,
                                  child: Text(
                                    label,
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: isDisabled
                                          ? (hasRejected
                                              ? AppColors.error.withOpacity(0.5)
                                              : Colors.grey.shade400)
                                          : null,
                                    ),
                                  ),
                                );
                              }).toList(),
                              onChanged: (value) {
                                setState(() => _selectedGuarantor1 = value);
                              },
                              validator: (value) {
                                if (value == null) {
                                  return 'Please select Guarantor 1';
                                }
                                return null;
                              },
                            ),
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: 12),

                    // Guarantor 2
                    if (isG2Approved) ...[
                      _buildApprovedGuarantorCard(
                        roleLabel: 'Guarantor 2',
                        fullName: widget.application.guarantorName,
                        itsId: widget.application.guarantorItsId ?? '—',
                        contact: widget.application.guarantorMobile ?? '—',
                      ),
                    ] else ...[
                      if (isG2Rejected) ...[
                        Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: AppColors.error.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                                color: AppColors.error.withOpacity(0.2)),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.info_outline,
                                  color: AppColors.error, size: 16),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  'Guarantor 2 (${widget.application.guarantorName}) rejected. Please select a different member.',
                                  style: const TextStyle(
                                      fontSize: 12, color: AppColors.error),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: AppColors.cardShadow,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Row(
                              children: [
                                Icon(Icons.people_outline,
                                    color: AppColors.accentGold, size: 20),
                                SizedBox(width: 8),
                                Text('Guarantor 2 *',
                                    style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.textPrimary)),
                              ],
                            ),
                            const SizedBox(height: 12),
                            DropdownButtonFormField<JamaatMember>(
                              value: _selectedGuarantor2,
                              isExpanded: true,
                              decoration: InputDecoration(
                                border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10)),
                                contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 14, vertical: 12),
                                hintText: 'Select Guarantor 2',
                              ),
                              items: _jamaatMembers.map((m) {
                                final isOtherSelected = _selectedGuarantor1 != null &&
                                    _selectedGuarantor1!.id == m.id;
                                final hasRejected = widget
                                    .application.rejectedGuarantorMemberIds
                                    .contains(m.id);
                                final isDisabled = isOtherSelected || hasRejected;

                                String label = '${m.fullName} (${m.itsId})';
                                if (hasRejected) {
                                  label += ' (Rejected)';
                                } else if (isOtherSelected) {
                                  label += ' (Selected as G1)';
                                }

                                return DropdownMenuItem<JamaatMember>(
                                  value: m,
                                  enabled: !isDisabled,
                                  child: Text(
                                    label,
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: isDisabled
                                          ? (hasRejected
                                              ? AppColors.error.withOpacity(0.5)
                                              : Colors.grey.shade400)
                                          : null,
                                    ),
                                  ),
                                );
                              }).toList(),
                              onChanged: (value) {
                                setState(() => _selectedGuarantor2 = value);
                              },
                              validator: (value) {
                                if (value == null) {
                                  return 'Please select Guarantor 2';
                                }
                                return null;
                              },
                            ),
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: 24),

                    // Submit Button
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton.icon(
                        onPressed: _isSubmitting ? null : _submitEdit,
                        icon: _isSubmitting
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2, color: Colors.white))
                            : const Icon(Icons.save_rounded),
                        label: Text(
                            _isSubmitting ? 'Saving...' : 'Save Changes',
                            style: const TextStyle(
                                fontSize: 16, fontWeight: FontWeight.w600)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                          elevation: 2,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildReadOnlyField(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          SizedBox(
            width: 100,
            child: Text(label,
                style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w500)),
          ),
          Expanded(
            child: Text(value,
                style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w500)),
          ),
        ],
      ),
    );
  }

  Widget _buildApprovedGuarantorCard({
    required String roleLabel,
    required String fullName,
    required String itsId,
    required String contact,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.lock_outline, color: Colors.grey.shade600, size: 18),
              const SizedBox(width: 8),
              Text(roleLabel,
                  style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey.shade700)),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.success.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.success.withOpacity(0.3)),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.check_circle, size: 14, color: AppColors.success),
                    SizedBox(width: 4),
                    Text(
                      'Approved',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: AppColors.success,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(fullName,
              style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary)),
          const SizedBox(height: 4),
          Text('ITS: $itsId  •  Mobile: $contact',
              style: const TextStyle(
                  fontSize: 13, color: AppColors.textSecondary)),
          const SizedBox(height: 8),
          Text(
            '$roleLabel has already approved and cannot be changed.',
            style: TextStyle(
                fontSize: 11,
                fontStyle: FontStyle.italic,
                color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
    String? prefixText,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        inputFormatters: inputFormatters,
        maxLines: maxLines,
        validator: validator,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, size: 20),
          prefixText: prefixText,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
          ),
          filled: true,
          fillColor: Colors.white,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
      ),
    );
  }
}
