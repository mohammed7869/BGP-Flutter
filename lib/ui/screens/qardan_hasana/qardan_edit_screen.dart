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

      // Pre-select current Guarantor 1 (stored in captain_member_id)
      final currentG1Id = widget.application.captainMemberId;
      _selectedGuarantor1 = _jamaatMembers.cast<JamaatMember?>().firstWhere(
            (m) => m?.id == currentG1Id,
            orElse: () => null,
          );

      // Pre-select current Guarantor 2
      final currentG2Id = widget.application.guarantorMemberId;
      _selectedGuarantor2 = _jamaatMembers.cast<JamaatMember?>().firstWhere(
            (m) => m?.id == currentG2Id,
            orElse: () => null,
          );

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
                        color: AppColors.info.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(12),
                        border:
                            Border.all(color: AppColors.info.withOpacity(0.2)),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.info_outline,
                              color: AppColors.info, size: 20),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'Editing ${widget.application.applicationNo}. Changes will reset guarantor approvals.',
                              style: const TextStyle(
                                  fontSize: 13, color: AppColors.textSecondary),
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

                    // Guarantor 1 Dropdown
                    const SizedBox(height: 4),
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
                              final isDisabled = _selectedGuarantor2 != null &&
                                  _selectedGuarantor2!.id == m.id;
                              return DropdownMenuItem<JamaatMember>(
                                value: m,
                                enabled: !isDisabled,
                                child: Text('${m.fullName} (${m.itsId})',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: isDisabled
                                          ? Colors.grey.shade400
                                          : null,
                                    )),
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
                    const SizedBox(height: 12),

                    // Guarantor 2 Dropdown
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
                              final isDisabled = _selectedGuarantor1 != null &&
                                  _selectedGuarantor1!.id == m.id;
                              return DropdownMenuItem<JamaatMember>(
                                value: m,
                                enabled: !isDisabled,
                                child: Text('${m.fullName} (${m.itsId})',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: isDisabled
                                          ? Colors.grey.shade400
                                          : null,
                                    )),
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
