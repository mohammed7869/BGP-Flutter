import 'package:burhaniguardsapp/core/services/user_service.dart';
import 'package:burhaniguardsapp/core/services/miqaat_service.dart';
import 'package:burhaniguardsapp/core/services/local_storage_service.dart';
import 'package:burhaniguardsapp/ui/screens/admin/membersListScreen.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class AddUserScreen extends StatefulWidget {
  const AddUserScreen({Key? key}) : super(key: key);

  @override
  State<AddUserScreen> createState() => _AddUserScreenState();
}

class _AddUserScreenState extends State<AddUserScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final UserService _userService = UserService();
  final MiqaatService _miqaatService = MiqaatService();
  final LocalStorageService _localStorage = LocalStorageService();
  bool _isLoading = false;

  final TextEditingController _itsIdController = TextEditingController();
  final TextEditingController _fullNameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _contactController = TextEditingController();
  final TextEditingController _ageController = TextEditingController();
  final TextEditingController _dobController = TextEditingController();
  final TextEditingController _passwordController =
      TextEditingController(text: '123456');

  String? _selectedRank = 'Member';
  String? _selectedGender;
  String? _selectedJamiyat;
  String? _selectedJamaat;
  DateTime? _selectedDOB;

  List<JamiyatItem> _jamiyats = [];
  List<JamaatItem> _jamaats = [];
  bool _isLoadingJamiyatJamaat = false;

  // Captain-specific
  bool _isCaptain = false;
  String? _captainJamiyat;
  String? _captainJamaat;

  late AnimationController _animController;
  late Animation<double> _fadeAnim;

  // Brand Colors
  static const Color _brandDark = Color(0xFF461D17);
  static const Color _brandLight = Color(0xFFFFF7EF);
  static const Color _goldAccent = Color(0xFFD4A574);
  static const Color _goldShimmer = Color(0xFFE8C99B);
  static const Color _textDark = Color(0xFF1A1A2E);
  static const Color _textMuted = Color(0xFF6B7280);

  final List<String> _ranks = [
    'Member',
    'Captain',
    'Vice Captain',
    'Asst. Group Leader',
    'Group Leader',
    'Major (Captain)',
    'Resource Admin',
    'Assistant Commander',
  ];

  final List<String> _genders = ['Male', 'Female'];

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnim = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeOut),
    );
    _loadJamiyatJamaat();
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    _itsIdController.dispose();
    _fullNameController.dispose();
    _emailController.dispose();
    _contactController.dispose();
    _ageController.dispose();
    _dobController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _calculateAge() {
    if (_selectedDOB == null) {
      _ageController.text = '';
      return;
    }
    final today = DateTime.now();
    int age = today.year - _selectedDOB!.year;
    if (today.month < _selectedDOB!.month ||
        (today.month == _selectedDOB!.month && today.day < _selectedDOB!.day)) {
      age--;
    }
    _ageController.text = age > 0 ? age.toString() : '0';
  }

  Future<void> _pickDateOfBirth() async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedDOB ?? DateTime(2000, 1, 1),
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
      setState(() {
        _selectedDOB = pickedDate;
        _dobController.text = DateFormat('dd MMM yyyy').format(pickedDate);
        _calculateAge();
      });
    }
  }

  Future<void> _loadJamiyatJamaat() async {
    setState(() => _isLoadingJamiyatJamaat = true);

    try {
      final userData = await _localStorage.getUserData();
      _isCaptain = (userData?.roles == 2 || userData?.roles == 6);
      _captainJamiyat = userData?.jamiyat;
      _captainJamaat = userData?.jamaat;

      final response = await _miqaatService.getJamiyatJamaatWithCounts();
      if (response != null) {
        setState(() {
          _jamiyats = response.jamiyats;
          _jamaats = response.jamaats;
          _isLoadingJamiyatJamaat = false;
          if (_isCaptain) {
            _selectedJamiyat = _captainJamiyat;
            _selectedJamaat = _captainJamaat;
          }
        });
      }
    } catch (e) {
      setState(() => _isLoadingJamiyatJamaat = false);
    }
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      await _userService.createMember(
        itsId: _itsIdController.text.trim(),
        fullName: _fullNameController.text.trim(),
        email: _emailController.text.trim(),
        contact: _contactController.text.trim().isNotEmpty
            ? _contactController.text.trim()
            : null,
        rank: _selectedRank,
        jamiyat: _selectedJamiyat,
        jamaat: _selectedJamaat,
        gender: _selectedGender,
        age: _ageController.text.trim().isNotEmpty
            ? int.tryParse(_ageController.text.trim())
            : null,
        password: '123456',
        dateOfBirth: _selectedDOB != null
            ? DateFormat('yyyy-MM-dd').format(_selectedDOB!)
            : null,
      );

      if (mounted) {
        final userData = await _localStorage.getUserData();
        final isCaptain = (userData?.roles == 2 || userData?.roles == 6);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white, size: 20),
                const SizedBox(width: 10),
                Text(isCaptain
                    ? 'Member Created – Awaiting Admin Approval'
                    : 'Member created successfully'),
              ],
            ),
            backgroundColor: const Color(0xFF2E7D32),
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to create member: ${e.toString()}'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
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
                    const Expanded(
                      child: Text(
                        'Add New Member',
                        textAlign: TextAlign.center,
                        style: TextStyle(
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

          // ── Form Content ──
          Expanded(
            child: FadeTransition(
              opacity: _fadeAnim,
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(18, 20, 18, 30),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Section Header
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: _brandDark.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(Icons.person_add_outlined,
                                color: _brandDark, size: 20),
                          ),
                          const SizedBox(width: 12),
                          const Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Member Information',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
                                  color: _textDark,
                                ),
                              ),
                              Text(
                                'Fill in the details below',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: _textMuted,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // Card wrapper for the form fields
                      Container(
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: _brandDark.withOpacity(0.05),
                              blurRadius: 16,
                              offset: const Offset(0, 4),
                            ),
                          ],
                          border: Border.all(
                              color: _goldAccent.withOpacity(0.15)),
                        ),
                        child: Column(
                          children: [
                            _buildPremiumField(
                              'ITS ID *',
                              _itsIdController,
                              icon: Icons.fingerprint,
                              keyboardType: TextInputType.number,
                              maxLength: 8,
                            ),
                            const SizedBox(height: 14),
                            _buildPremiumField(
                              'Full Name *',
                              _fullNameController,
                              icon: Icons.person_outline,
                            ),
                            const SizedBox(height: 14),
                            _buildPremiumField(
                              'Email *',
                              _emailController,
                              icon: Icons.email_outlined,
                              keyboardType: TextInputType.emailAddress,
                            ),
                            const SizedBox(height: 14),
                            _buildPremiumField(
                              'Contact',
                              _contactController,
                              icon: Icons.phone_outlined,
                              keyboardType: TextInputType.phone,
                            ),
                            const SizedBox(height: 14),
                            _buildPremiumDropdown(
                              'Rank',
                              _selectedRank,
                              _ranks,
                              Icons.military_tech_outlined,
                              (v) => setState(() => _selectedRank = v),
                            ),
                            const SizedBox(height: 14),
                            _buildPremiumDropdown(
                              'Gender',
                              _selectedGender,
                              _genders,
                              Icons.wc_outlined,
                              (v) => setState(() => _selectedGender = v),
                            ),
                            const SizedBox(height: 14),
                            // Date of Birth picker
                            _buildDOBField(),
                            const SizedBox(height: 14),
                            // Age (auto-calculated, read-only)
                            _buildPremiumField(
                              'Age',
                              _ageController,
                              icon: Icons.calendar_today_outlined,
                              readOnly: true,
                            ),
                            const SizedBox(height: 14),
                            _buildJamiyatDropdown(),
                            const SizedBox(height: 14),
                            _buildJamaatDropdown(),
                            const SizedBox(height: 14),
                            // Password (locked)
                            _buildLockedPasswordField(),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      // Submit button
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _submitForm,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _brandDark,
                            disabledBackgroundColor: Colors.grey[400],
                            foregroundColor: Colors.white,
                            elevation: 6,
                            shadowColor: _brandDark.withOpacity(0.4),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: _isLoading
                              ? const SizedBox(
                                  height: 22,
                                  width: 22,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.5,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                        Colors.white),
                                  ),
                                )
                              : const Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.person_add, size: 20),
                                    SizedBox(width: 8),
                                    Text(
                                      'Add Member',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w700,
                                        letterSpacing: 0.3,
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
          ),
        ],
      ),
    );
  }

  // ─── Premium Text Field ───────────────────────────────────────

  Widget _buildPremiumField(
    String label,
    TextEditingController controller, {
    IconData icon = Icons.edit,
    TextInputType? keyboardType,
    bool obscureText = false,
    int? maxLength,
    bool readOnly = false,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscureText,
      maxLength: maxLength,
      readOnly: readOnly,
      style: TextStyle(
        color: readOnly ? _textMuted : _textDark,
        fontWeight: FontWeight.w500,
        fontSize: 14,
      ),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(
          color: _textMuted,
          fontSize: 13,
          fontWeight: FontWeight.w500,
        ),
        prefixIcon: Icon(icon, size: 20, color: _brandDark.withOpacity(0.6)),
        filled: true,
        fillColor: readOnly ? Colors.grey[100] : _brandLight.withOpacity(0.5),
        counterText: '',
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: _goldAccent.withOpacity(0.3)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: _brandDark, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Colors.red, width: 1),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Colors.red, width: 1.5),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
      ),
      validator: (value) {
        if (label.contains('*') && (value == null || value.isEmpty)) {
          return 'This field is required';
        }
        if (label.contains('ITS ID') && value != null && value.isNotEmpty) {
          if (!RegExp(r'^\d+$').hasMatch(value)) {
            return 'Only numerical values are allowed';
          }
          if (value.length < 8) return 'ITS ID must be exactly 8 digits';
          if (value.length > 8) return 'ITS ID must be maximum 8 characters';
        }
        if (label.contains('Email') && value != null && value.isNotEmpty) {
          if (!value.contains('@') || !value.contains('.')) {
            return 'Please enter a valid email';
          }
        }
        return null;
      },
    );
  }

  // ─── DOB Field ────────────────────────────────────────────────

  Widget _buildDOBField() {
    return GestureDetector(
      onTap: _pickDateOfBirth,
      child: AbsorbPointer(
        child: TextFormField(
          controller: _dobController,
          style: const TextStyle(
            color: _textDark,
            fontWeight: FontWeight.w500,
            fontSize: 14,
          ),
          decoration: InputDecoration(
            labelText: 'Date of Birth',
            labelStyle: const TextStyle(
              color: _textMuted,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
            prefixIcon: Icon(Icons.cake_outlined,
                size: 20, color: _brandDark.withOpacity(0.6)),
            suffixIcon: Icon(Icons.calendar_month_outlined,
                size: 20, color: _goldAccent),
            filled: true,
            fillColor: _brandLight.withOpacity(0.5),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: _goldAccent.withOpacity(0.3)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: _brandDark, width: 1.5),
            ),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
            hintText: 'Select date of birth',
            hintStyle: const TextStyle(
              color: _textMuted,
              fontWeight: FontWeight.w400,
              fontSize: 14,
            ),
          ),
        ),
      ),
    );
  }

  // ─── Locked Password Field ────────────────────────────────────

  Widget _buildLockedPasswordField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextFormField(
          controller: _passwordController,
          obscureText: true,
          enabled: false,
          style: const TextStyle(
            color: _textMuted,
            fontWeight: FontWeight.w500,
            fontSize: 14,
          ),
          decoration: InputDecoration(
            labelText: 'Password (Default)',
            labelStyle: const TextStyle(
              color: _textMuted,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
            prefixIcon:
                Icon(Icons.lock_outline, size: 20, color: _textMuted),
            suffixIcon:
                Icon(Icons.lock, size: 18, color: _goldAccent),
            filled: true,
            fillColor: Colors.grey[100],
            disabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
          ),
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            Icon(Icons.info_outline, size: 13, color: _goldAccent),
            const SizedBox(width: 4),
            Text(
              'Default password: 123456',
              style: TextStyle(
                fontSize: 11,
                color: _textMuted,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ─── Premium Dropdown ─────────────────────────────────────────

  Widget _buildPremiumDropdown(String label, String? value,
      List<String> items, IconData icon, Function(String?) onChanged) {
    return DropdownButtonFormField<String>(
      value: value,
      style: const TextStyle(
        color: _textDark,
        fontWeight: FontWeight.w500,
        fontSize: 14,
      ),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(
          color: _textMuted,
          fontSize: 13,
          fontWeight: FontWeight.w500,
        ),
        prefixIcon: Icon(icon, size: 20, color: _brandDark.withOpacity(0.6)),
        filled: true,
        fillColor: _brandLight.withOpacity(0.5),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: _goldAccent.withOpacity(0.3)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: _brandDark, width: 1.5),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
      ),
      items: items.map((item) {
        return DropdownMenuItem<String>(
          value: item,
          child: Text(item),
        );
      }).toList(),
      onChanged: onChanged,
    );
  }

  // ─── Jamiyat Dropdown ─────────────────────────────────────────

  Widget _buildJamiyatDropdown() {
    final displayJamiyats = _isCaptain && _captainJamiyat != null
        ? _jamiyats.where((j) => j.name == _captainJamiyat).toList()
        : _jamiyats;

    return DropdownButtonFormField<String>(
      value: _selectedJamiyat,
      style: const TextStyle(
        color: _textDark,
        fontWeight: FontWeight.w500,
        fontSize: 14,
      ),
      decoration: InputDecoration(
        labelText: _isCaptain ? 'Jamiyat (Locked)' : 'Jamiyat',
        labelStyle: const TextStyle(
          color: _textMuted,
          fontSize: 13,
          fontWeight: FontWeight.w500,
        ),
        prefixIcon: Icon(Icons.account_balance_outlined,
            size: 20, color: _brandDark.withOpacity(0.6)),
        suffixIcon: _isCaptain
            ? Icon(Icons.lock, size: 16, color: _goldAccent)
            : null,
        filled: true,
        fillColor: _isCaptain ? Colors.grey[100] : _brandLight.withOpacity(0.5),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: _goldAccent.withOpacity(0.3)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: _brandDark, width: 1.5),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
      ),
      items: displayJamiyats.map((item) {
        return DropdownMenuItem<String>(
          value: item.name,
          child: Text(item.displayName),
        );
      }).toList(),
      onChanged: _isCaptain
          ? null
          : (value) {
              setState(() {
                _selectedJamiyat = value;
                _selectedJamaat = null;
              });
            },
    );
  }

  // ─── Jamaat Dropdown ──────────────────────────────────────────

  Widget _buildJamaatDropdown() {
    final displayJamaats = _isCaptain && _captainJamaat != null
        ? _jamaats.where((j) => j.name == _captainJamaat).toList()
        : _jamaats;

    return DropdownButtonFormField<String>(
      value: _selectedJamaat,
      style: const TextStyle(
        color: _textDark,
        fontWeight: FontWeight.w500,
        fontSize: 14,
      ),
      decoration: InputDecoration(
        labelText: _isCaptain ? 'Jamaat (Locked)' : 'Jamaat',
        labelStyle: const TextStyle(
          color: _textMuted,
          fontSize: 13,
          fontWeight: FontWeight.w500,
        ),
        prefixIcon: Icon(Icons.groups_outlined,
            size: 20, color: _brandDark.withOpacity(0.6)),
        suffixIcon: _isCaptain
            ? Icon(Icons.lock, size: 16, color: _goldAccent)
            : null,
        filled: true,
        fillColor: _isCaptain ? Colors.grey[100] : _brandLight.withOpacity(0.5),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: _goldAccent.withOpacity(0.3)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: _brandDark, width: 1.5),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
      ),
      items: displayJamaats.map((item) {
        return DropdownMenuItem<String>(
          value: item.name,
          child: Text(item.displayName),
        );
      }).toList(),
      onChanged: _isCaptain
          ? null
          : (value) {
              setState(() => _selectedJamaat = value);
            },
    );
  }
}
