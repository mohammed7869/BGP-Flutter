import 'package:burhaniguardsapp/core/services/user_service.dart';
import 'package:burhaniguardsapp/core/services/miqaat_service.dart';
import 'package:burhaniguardsapp/core/services/local_storage_service.dart';
import 'package:burhaniguardsapp/ui/screens/admin/membersListScreen.dart';
import 'package:flutter/material.dart';

class AddUserScreen extends StatefulWidget {
  const AddUserScreen({Key? key}) : super(key: key);

  @override
  State<AddUserScreen> createState() => _AddUserScreenState();
}

class _AddUserScreenState extends State<AddUserScreen> {
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
  final TextEditingController _passwordController = TextEditingController();

  String? _selectedRank = 'Member';
  String? _selectedGender;
  String? _selectedJamiyat;
  String? _selectedJamaat;

  List<JamiyatItem> _jamiyats = [];
  List<JamaatItem> _jamaats = [];
  bool _isLoadingJamiyatJamaat = false;

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
    _loadJamiyatJamaat();
  }

  Future<void> _loadJamiyatJamaat() async {
    setState(() {
      _isLoadingJamiyatJamaat = true;
    });

    try {
      final response = await _miqaatService.getJamiyatJamaatWithCounts();
      if (response != null) {
        setState(() {
          _jamiyats = response.jamiyats;
          _jamaats = response.jamaats;
          _isLoadingJamiyatJamaat = false;
        });
      }
    } catch (e) {
      setState(() {
        _isLoadingJamiyatJamaat = false;
      });
    }
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

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
        password: _passwordController.text.trim().isNotEmpty
            ? _passwordController.text.trim()
            : null,
      );

      if (mounted) {
        // Check if current user is Captain (role = 2)
        final userData = await _localStorage.getUserData();
        final isCaptain = userData?.roles == 2;
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isCaptain 
                ? 'Member Created Awaiting Admin Approval'
                : 'Member created successfully'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true); // Return true to indicate success
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to create member: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          // Custom AppBar with curved bottom
          Container(
            decoration: const BoxDecoration(
              color: Color(0xFF4A1C1C),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(30),
                bottomRight: Radius.circular(30),
              ),
            ),
            child: SafeArea(
              bottom: false,
              child: Column(
                children: [
                  // Header buttons
                  Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        IconButton(
                          icon:
                              const Icon(Icons.arrow_back, color: Colors.white),
                          onPressed: () => Navigator.pop(context),
                        ),
                        const Text(
                          'Add Member',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 48), // Balance the back button
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),

          // Form Container
          Expanded(
            child: Container(
              color: Colors.white,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Member Information',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF4A1C1C),
                        ),
                      ),
                      const SizedBox(height: 20),
                      _buildTextField('ITS ID *', _itsIdController,
                          keyboardType: TextInputType.number, maxLength: 8),
                      const SizedBox(height: 16),
                      _buildTextField('Full Name *', _fullNameController),
                      const SizedBox(height: 16),
                      _buildTextField('Email *', _emailController,
                          keyboardType: TextInputType.emailAddress),
                      const SizedBox(height: 16),
                      _buildTextField('Contact', _contactController,
                          keyboardType: TextInputType.phone),
                      const SizedBox(height: 16),
                      _buildDropdownField('Rank', _selectedRank, _ranks,
                          (value) => setState(() => _selectedRank = value)),
                      const SizedBox(height: 16),
                      _buildDropdownField('Gender', _selectedGender, _genders,
                          (value) => setState(() => _selectedGender = value)),
                      const SizedBox(height: 16),
                      _buildTextField('Age', _ageController,
                          keyboardType: TextInputType.number),
                      const SizedBox(height: 16),
                      _buildJamiyatDropdown(),
                      const SizedBox(height: 16),
                      _buildJamaatDropdown(),
                      const SizedBox(height: 16),
                      _buildTextField('Password', _passwordController,
                          obscureText: true),
                      const SizedBox(height: 30),
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _submitForm,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF4A1C1C),
                            disabledBackgroundColor: Colors.grey,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: _isLoading
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
                                  'Add Member',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                  ),
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

  Widget _buildTextField(String label, TextEditingController controller,
      {TextInputType? keyboardType, bool obscureText = false, int? maxLength}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          obscureText: obscureText,
          maxLength: maxLength,
          decoration: InputDecoration(
            label: Text(label),
            filled: true,
            fillColor: Colors.white,
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey[300]!, width: 1),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFF4A1C1C), width: 1),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Colors.red, width: 1),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Colors.red, width: 1),
            ),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 20),
          ),
          style: const TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.w500,
          ),
          validator: (value) {
            if (label.contains('*') && (value == null || value.isEmpty)) {
              return 'This field is required';
            }
            if (label.contains('ITS ID') && value != null && value.isNotEmpty) {
              // Validate ITS ID must be exactly 8 digits (same as login screen)
              if (!RegExp(r'^\d+$').hasMatch(value)) {
                return 'Only numerical values are allowed';
              }
              if (value.length < 8) {
                return 'ITS ID must be exactly 8 digits';
              }
              if (value.length > 8) {
                return 'ITS ID must be maximum 8 characters';
              }
            }
            if (label.contains('Email') && value != null && value.isNotEmpty) {
              if (!value.contains('@') || !value.contains('.')) {
                return 'Please enter a valid email';
              }
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildDropdownField(String label, String? value, List<String> items,
      Function(String?) onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DropdownButtonFormField<String>(
          value: value,
          decoration: InputDecoration(
            label: Text(label),
            filled: true,
            fillColor: Colors.white,
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey[300]!, width: 1),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFF4A1C1C), width: 1),
            ),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 20),
          ),
          items: items.map((String item) {
            return DropdownMenuItem<String>(
              value: item,
              child: Text(item),
            );
          }).toList(),
          onChanged: onChanged,
        ),
      ],
    );
  }

  Widget _buildJamiyatDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DropdownButtonFormField<String>(
          value: _selectedJamiyat,
          decoration: InputDecoration(
            label: const Text('Jamiyat'),
            filled: true,
            fillColor: Colors.white,
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey[300]!, width: 1),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFF4A1C1C), width: 1),
            ),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 20),
          ),
          items: _jamiyats.map((JamiyatItem item) {
            return DropdownMenuItem<String>(
              value: item.name,
              child: Text(item.displayName),
            );
          }).toList(),
          onChanged: (value) {
            setState(() {
              _selectedJamiyat = value;
              // Clear jamaat when jamiyat changes
              _selectedJamaat = null;
            });
          },
        ),
      ],
    );
  }

  Widget _buildJamaatDropdown() {
    // Filter jamaats based on selected jamiyat if needed
    final filteredJamaats = _jamaats;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DropdownButtonFormField<String>(
          value: _selectedJamaat,
          decoration: InputDecoration(
            label: const Text('Jamaat'),
            filled: true,
            fillColor: Colors.white,
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey[300]!, width: 1),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFF4A1C1C), width: 1),
            ),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 20),
          ),
          items: filteredJamaats.map((JamaatItem item) {
            return DropdownMenuItem<String>(
              value: item.name,
              child: Text(item.displayName),
            );
          }).toList(),
          onChanged: (value) {
            setState(() {
              _selectedJamaat = value;
            });
          },
        ),
      ],
    );
  }

  @override
  void dispose() {
    _itsIdController.dispose();
    _fullNameController.dispose();
    _emailController.dispose();
    _contactController.dispose();
    _ageController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
}
