import 'package:burhaniguardsapp/core/constants/app_colors.dart';
import 'package:burhaniguardsapp/core/models/qardan_hasana_model.dart';
import 'package:burhaniguardsapp/core/services/qardan_hasana_service.dart';
import 'package:burhaniguardsapp/core/services/local_storage_service.dart';
import 'package:burhaniguardsapp/ui/screens/qardan_hasana/qardan_list_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class QardanApplyScreen extends StatefulWidget {
  const QardanApplyScreen({Key? key}) : super(key: key);

  @override
  State<QardanApplyScreen> createState() => _QardanApplyScreenState();
}

class _QardanApplyScreenState extends State<QardanApplyScreen> {
  final _formKey = GlobalKey<FormState>();
  final _scrollController = ScrollController();
  final QardanHasanaService _service = QardanHasanaService();
  final LocalStorageService _localStorage = LocalStorageService();

  // Keys for scrolling to invalid fields
  final _nameKey = GlobalKey();
  final _occupationKey = GlobalKey();
  final _mobileKey = GlobalKey();
  final _reasonKey = GlobalKey();
  final _amountKey = GlobalKey();
  final _guarantorKey = GlobalKey();
  final _termsKey = GlobalKey();

  // Auto-filled fields
  String _date = '';
  String _mohallah = '';
  String _itsNo = '';

  // User input fields
  final _nameController = TextEditingController();
  final _occupationController = TextEditingController();
  final _mobileController = TextEditingController();
  final _reasonController = TextEditingController();
  final _amountController = TextEditingController();

  // Guarantors
  List<JamaatMember> _jamaatMembers = [];
  JamaatMember? _selectedGuarantor1;
  JamaatMember? _selectedGuarantor2;

  bool _termsAccepted = false;
  bool _isLoading = true;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    try {
      // Set date
      final now = DateTime.now();
      _date =
          '${now.day.toString().padLeft(2, '0')}-${now.month.toString().padLeft(2, '0')}-${now.year}';

      // Get user profile data
      final userData = await _localStorage.getUserData();
      if (userData != null) {
        _mohallah = userData.jamaat ?? '';
        _itsNo = userData.itsId ?? '';
      }

      // Get members for guarantor dropdowns
      _jamaatMembers = await _service.getMembersByJamaat();

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading data: ${e.toString()}'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  void _scrollToField(GlobalKey key) {
    final context = key.currentContext;
    if (context != null) {
      Scrollable.ensureVisible(
        context,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
        alignment: 0.3,
      );
    }
  }

  GlobalKey? _findFirstInvalidField() {
    if (_nameController.text.trim().isEmpty) return _nameKey;
    if (_occupationController.text.trim().isEmpty) return _occupationKey;
    if (_mobileController.text.trim().isEmpty ||
        _mobileController.text.trim().length < 10) return _mobileKey;
    if (_reasonController.text.trim().isEmpty) return _reasonKey;
    final amount = int.tryParse(_amountController.text.trim());
    if (_amountController.text.trim().isEmpty ||
        amount == null || amount <= 0 || amount > 20000) return _amountKey;
    if (_selectedGuarantor1 == null || _selectedGuarantor2 == null) return _guarantorKey;
    return null;
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) {
      final invalidKey = _findFirstInvalidField();
      if (invalidKey != null) {
        _scrollToField(invalidKey);
      }
      return;
    }
    if (_selectedGuarantor1 == null) {
      _scrollToField(_guarantorKey);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select Guarantor 1'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }
    if (_selectedGuarantor2 == null) {
      _scrollToField(_guarantorKey);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select Guarantor 2'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }
    if (_selectedGuarantor1!.id == _selectedGuarantor2!.id) {
      _scrollToField(_guarantorKey);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Guarantor 1 and Guarantor 2 cannot be the same person'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }
    if (!_termsAccepted) {
      _scrollToField(_termsKey);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please accept the Terms & Conditions'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      await _service.createApplication(
        applicantName: _nameController.text.trim(),
        applicantOccupation: _occupationController.text.trim(),
        applicantMobile: _mobileController.text.trim(),
        reason: _reasonController.text.trim().isEmpty
            ? null
            : _reasonController.text.trim(),
        amountRequested: double.parse(_amountController.text.trim()),
        termsAccepted: _termsAccepted,
        guarantor1MemberId: _selectedGuarantor1!.id,
        guarantorMemberId: _selectedGuarantor2!.id,
      );

      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (ctx) => AlertDialog(
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.success.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.check_circle,
                      color: AppColors.success, size: 28),
                ),
                const SizedBox(width: 12),
                const Text('Success!'),
              ],
            ),
            content: const Text(
              'Your Qardan Hasana application has been submitted successfully.\n\n'
              'Emails have been sent to both your Guarantors for digital approval.\n\n'
              'Once both Guarantors approve, the application will be forwarded to the Resource Admin for sanctioning.',
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const QardanListScreen()),
                  );
                },
                child: const Text('View My Applications'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceAll('Exception: ', '')),
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
    _scrollController.dispose();
    _nameController.dispose();
    _occupationController.dispose();
    _mobileController.dispose();
    _reasonController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        title: const Text('Qardan Hasana Application',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
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
                    // Header Card
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        gradient: AppColors.primaryGradient,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: AppColors.headerShadow,
                      ),
                      child: Column(
                        children: [
                          const Icon(Icons.account_balance_wallet,
                              color: Colors.white, size: 36),
                          const SizedBox(height: 8),
                          const Text(
                            'Qardan Hasana',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          // const SizedBox(height: 4),
                          // Text(
                          //   'Interest-Free Loan • Max ₹20,000',
                          //   style: TextStyle(
                          //     color: Colors.white.withOpacity(0.8),
                          //     fontSize: 13,
                          //   ),
                          // ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // ── APPLICANT INFORMATION ──
                    _buildSectionHeader(
                        'Applicant Information', Icons.person_outline),
                    const SizedBox(height: 12),
                    _buildCard([
                      _buildReadOnlyField('Date', _date),
                      _buildReadOnlyField('Mohallah', _mohallah),
                      _buildReadOnlyField('ITS No', _itsNo),
                      Container(
                        key: _nameKey,
                        child: _buildTextField(
                          controller: _nameController,
                          label: 'Name (As Per Bank) *',
                          icon: Icons.badge_outlined,
                          validator: (v) =>
                              v == null || v.trim().isEmpty ? 'Required' : null,
                        ),
                      ),
                      Container(
                        key: _occupationKey,
                        child: _buildTextField(
                          controller: _occupationController,
                          label: 'Occupation *',
                          icon: Icons.work_outline,
                          validator: (v) =>
                              v == null || v.trim().isEmpty ? 'Required' : null,
                        ),
                      ),
                      Container(
                        key: _mobileKey,
                        child: _buildTextField(
                          controller: _mobileController,
                          label: 'Mobile No *',
                          icon: Icons.phone_outlined,
                          keyboardType: TextInputType.phone,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                            LengthLimitingTextInputFormatter(10),
                          ],
                          validator: (v) {
                            if (v == null || v.trim().isEmpty) return 'Required';
                            if (v.trim().length < 10) return 'Enter 10 digits';
                            return null;
                          },
                        ),
                      ),
                      Container(
                        key: _reasonKey,
                        child: _buildTextField(
                          controller: _reasonController,
                          label: 'Reason for Qardan *',
                          icon: Icons.note_alt_outlined,
                          maxLines: 3,
                          validator: (v) =>
                              v == null || v.trim().isEmpty ? 'Required' : null,
                        ),
                      ),
                      Container(
                        key: _amountKey,
                        child: _buildTextField(
                          controller: _amountController,
                          label: 'Amount (In Figure) *',
                          icon: Icons.currency_rupee,
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                            LengthLimitingTextInputFormatter(5),
                          ],
                          prefix: '₹ ',
                          validator: (v) {
                            if (v == null || v.trim().isEmpty) return 'Required';
                            final amount = int.tryParse(v.trim());
                            if (amount == null || amount <= 0) {
                              return 'Enter valid amount';
                            }
                            if (amount > 20000) {
                              return 'Maximum ₹20,000';
                            }
                            return null;
                          },
                        ),
                      ),
                    ]),
                    const SizedBox(height: 20),

                    // ── GUARANTOR SECTION ──
                    Container(
                      key: _guarantorKey,
                      child: _buildSectionHeader(
                        'Guarantor Section', Icons.verified_user_outlined),
                    ),
                    const SizedBox(height: 12),
                    _buildCard([
                      // Guarantor 1
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                              color: AppColors.primary.withOpacity(0.15)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: AppColors.primary,
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: const Text('Guarantor 1',
                                      style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600)),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            DropdownButtonFormField<JamaatMember>(
                              value: _selectedGuarantor1,
                              isExpanded: true,
                              decoration: InputDecoration(
                                labelText: 'Select Guarantor 1 *',
                                prefixIcon: const Icon(Icons.person_search,
                                    color: AppColors.primary, size: 20),
                                border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10)),
                                contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 14, vertical: 14),
                                filled: true,
                                fillColor: Colors.white,
                              ),
                              items: _jamaatMembers.map((member) {
                                final isDisabled = _selectedGuarantor2 != null &&
                                    _selectedGuarantor2!.id == member.id;
                                return DropdownMenuItem<JamaatMember>(
                                  value: member,
                                  enabled: !isDisabled,
                                  child: Text(
                                    '${member.fullName} (${member.itsId})',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: isDisabled
                                          ? Colors.grey.shade400
                                          : null,
                                    ),
                                  ),
                                );
                              }).toList(),
                              onChanged: (value) {
                                setState(() {
                                  _selectedGuarantor1 = value;
                                });
                              },
                              validator: (v) =>
                                  v == null ? 'Please select Guarantor 1' : null,
                            ),
                            if (_selectedGuarantor1 != null) ...[
                              const SizedBox(height: 8),
                              _buildReadOnlyField('Mobile',
                                  _selectedGuarantor1!.contact ?? 'N/A'),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Guarantor 2
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.accentGold.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                              color: AppColors.accentGold.withOpacity(0.25)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: AppColors.accentGold,
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: const Text('Guarantor 2',
                                      style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600)),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            DropdownButtonFormField<JamaatMember>(
                              value: _selectedGuarantor2,
                              isExpanded: true,
                              decoration: InputDecoration(
                                labelText: 'Select Guarantor 2 *',
                                prefixIcon: const Icon(Icons.person_search,
                                    color: AppColors.primary, size: 20),
                                border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10)),
                                contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 14, vertical: 14),
                                filled: true,
                                fillColor: Colors.white,
                              ),
                              items: _jamaatMembers.map((member) {
                                final isDisabled = _selectedGuarantor1 != null &&
                                    _selectedGuarantor1!.id == member.id;
                                return DropdownMenuItem<JamaatMember>(
                                  value: member,
                                  enabled: !isDisabled,
                                  child: Text(
                                    '${member.fullName} (${member.itsId})',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: isDisabled
                                          ? Colors.grey.shade400
                                          : null,
                                    ),
                                  ),
                                );
                              }).toList(),
                              onChanged: (value) {
                                setState(() {
                                  _selectedGuarantor2 = value;
                                });
                              },
                              validator: (v) =>
                                  v == null ? 'Please select Guarantor 2' : null,
                            ),
                            if (_selectedGuarantor2 != null) ...[
                              const SizedBox(height: 8),
                              _buildReadOnlyField('Mobile',
                                  _selectedGuarantor2!.contact ?? 'N/A'),
                            ],
                          ],
                        ),
                      ),
                    ]),
                    const SizedBox(height: 20),

                    // ── TERMS & CONDITIONS ──
                    Container(
                      key: _termsKey,
                      child: _buildSectionHeader(
                          'Terms & Conditions', Icons.description_outlined),
                    ),
                    const SizedBox(height: 12),
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
                          Container(
                            height: 200,
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppColors.background,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: SingleChildScrollView(
                              child: RichText(
                                text: TextSpan(
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: AppColors.textSecondary,
                                    height: 1.5,
                                  ),
                                  children: [
                                    const TextSpan(
                                      text: '1. Nature of Qardan\n',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Colors.black,
                                      ),
                                    ),
                                    const TextSpan(
                                      text: 'The amount given under this scheme is Qardan Hasana (interest-free), strictly for need-based assistance. '
                                          'No interest, profit, service charge, or benefit (monetary or non-monetary) shall be charged by BGP.\n\n',
                                    ),
                                    const TextSpan(
                                      text: '2. Eligibility\n',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Colors.black,
                                      ),
                                    ),
                                    const TextSpan(
                                      text: 'Only registered BGP members are eligible to apply. The applicant must belong to the same Mohallah under which the application is submitted. '
                                          'Applicants must have no pending dues or unresolved disciplinary matters with BGP.\n\n',
                                    ),
                                    const TextSpan(
                                      text: '3. Qardan Amount\n',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Colors.black,
                                      ),
                                    ),
                                    const TextSpan(
                                      text: 'Maximum Qardan amount permissible: ₹20,000 (Rupees Twenty Thousand Only). '
                                          'Sanctioned amount may be less than the requested amount, based on BGP assessment.\n\n',
                                    ),
                                    const TextSpan(
                                      text: '4. Purpose of Qardan\n',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Colors.black,
                                      ),
                                    ),
                                    const TextSpan(
                                      text: 'The Qardan must be used only for genuine and lawful purposes. '
                                          'BGP reserves the right to seek clarification regarding the purpose of the qardan.\n\n',
                                    ),
                                    const TextSpan(
                                      text: '5. Guarantors\n',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Colors.black,
                                      ),
                                    ),
                                    const TextSpan(
                                      text: 'Two guarantors are mandatory from the same Mohallah as the applicant. '
                                          'Guarantors must be financially responsible. Have no outstanding Qardan Hasana dues. '
                                          'Guarantors accept joint responsibility for repayment in case of default.\n\n',
                                    ),
                                    const TextSpan(
                                      text: '6. Repayment Terms\n',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Colors.black,
                                      ),
                                    ),
                                    const TextSpan(
                                      text: 'Repayment shall be made without delay as per the mutually agreed schedule. '
                                          'Repayment may be: Lump sum, or Monthly installments (as approved by BGP). '
                                          'Early repayment is allowed and encouraged. No extension shall be granted without prior written approval of BGP.\n\n',
                                    ),
                                    const TextSpan(
                                      text: '7. Default & Recovery\n',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Colors.black,
                                      ),
                                    ),
                                    const TextSpan(
                                      text: 'In case of failure to repay: Applicant shall be reminded verbally and/or in writing. '
                                          'Guarantors shall be informed and requested to intervene. '
                                          'If the applicant continues to default: Guarantors shall be liable to repay the outstanding amount. '
                                          'No interest or penalty shall be imposed under any circumstances.\n\n',
                                    ),
                                    const TextSpan(
                                      text: '8. Discipline & Conduct\n',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Colors.black,
                                      ),
                                    ),
                                    const TextSpan(
                                      text: 'Repeated default may result in: Temporary or permanent disqualification from future BGP benefits. '
                                          'Reporting to Mohallah committee for resolution. '
                                          'Any false information provided shall result in immediate cancellation of the qardan.\n\n',
                                    ),
                                    const TextSpan(
                                      text: '9. Documentation & Records\n',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Colors.black,
                                      ),
                                    ),
                                    const TextSpan(
                                      text: 'Applicant and guarantors must submit: Valid ID proof (as required by BGP). '
                                          'Signatures/thumb impressions on the application form. BGP shall maintain records for internal accountability.\n\n',
                                    ),
                                    const TextSpan(
                                      text: '10. Discretion of BGP\n',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Colors.black,
                                      ),
                                    ),
                                    const TextSpan(
                                      text: 'Approval or rejection of the qardan is at the sole discretion of BGP. '
                                          'BGP reserves the right to modify the scheme rules with prior notice.\n\n',
                                    ),
                                    const TextSpan(
                                      text: '11. Declaration\n',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Colors.black,
                                      ),
                                    ),
                                    const TextSpan(
                                      text: 'I hereby declare that all information provided by me is true and correct. '
                                          'I understand that this amount is a Qardan Hasana, entrusted to me as an amanat, '
                                          'and I take full moral and financial responsibility to repay it within the agreed time.',
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              SizedBox(
                                height: 24,
                                width: 24,
                                child: Checkbox(
                                  value: _termsAccepted,
                                  onChanged: (v) {
                                    setState(
                                        () => _termsAccepted = v ?? false);
                                  },
                                  activeColor: AppColors.primary,
                                ),
                              ),
                              const SizedBox(width: 10),
                              const Expanded(
                                child: Text(
                                  'I accept the Terms & Conditions and declare that all information provided is true and correct.',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 28),

                    // ── SUBMIT BUTTON ──
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        onPressed: _isSubmitting ? null : _submitForm,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                          elevation: 2,
                        ),
                        child: _isSubmitting
                            ? const SizedBox(
                                height: 22,
                                width: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Text(
                                'Submit Application',
                                style: TextStyle(
                                    fontSize: 16, fontWeight: FontWeight.w600),
                              ),
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
    );
  }

  // ─── Helper Widgets ──────────────────────────

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: AppColors.primary, size: 22),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
      ],
    );
  }

  Widget _buildCard(List<Widget> children) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: AppColors.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }

  Widget _buildReadOnlyField(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w500)),
          const SizedBox(height: 4),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.divider),
            ),
            child: Text(
              value.isEmpty ? '—' : value,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    IconData? icon,
    String? prefix,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        inputFormatters: inputFormatters,
        maxLines: maxLines,
        validator: validator,
        style: const TextStyle(fontSize: 14),
        decoration: InputDecoration(
          labelText: label,
          prefixIcon:
              icon != null ? Icon(icon, color: AppColors.primary, size: 20) : null,
          prefixText: prefix,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          filled: true,
          fillColor: Colors.white,
        ),
      ),
    );
  }
}
