import 'package:burhaniguardsapp/core/services/auth_service.dart';
import 'package:burhaniguardsapp/core/services/miqaat_service.dart';
import 'package:burhaniguardsapp/ui/screens/admin/attendancemiqaatScreen.dart';
import 'package:flutter/material.dart';

class CreateMiqaatScreen extends StatefulWidget {
  const CreateMiqaatScreen({Key? key}) : super(key: key);

  @override
  State<CreateMiqaatScreen> createState() => _CreateMiqaatScreenState();
}

class _CreateMiqaatScreenState extends State<CreateMiqaatScreen> {
  final _formKey = GlobalKey<FormState>();
  final _miqaatService = MiqaatService();
  final _authService = AuthService();
  bool _isLoading = false;
  bool _isCaptain = false;
  DateTime? _fromDate;
  DateTime? _tillDate;
  bool _isLoadingData = false;

  // Jamiyat and Jamaat data
  List<JamiyatItem> _jamiyats = [];
  List<JamaatItem> _jamaats = [];
  String? _selectedJamiyat;
  String? _selectedJamaat;

  final TextEditingController _miqaatNameController = TextEditingController();
  final TextEditingController _fromDateController = TextEditingController();
  final TextEditingController _tillDateController = TextEditingController();
  final TextEditingController _volunteerLimitController =
      TextEditingController();
  final TextEditingController _aboutController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _checkUserRole();
  }

  Future<void> _checkUserRole() async {
    final userData = await _authService.getStoredUser();
    final isCaptain =
        userData?.roles == 2 || userData?.rank.toLowerCase() == 'captain';
    setState(() {
      _isCaptain = isCaptain;
    });

    // If user is captain, fetch jamiyat and jamaat data
    if (isCaptain) {
      await _fetchJamiyatJamaatData();
    }
  }

  Future<void> _fetchJamiyatJamaatData() async {
    setState(() {
      _isLoadingData = true;
    });

    try {
      final response = await _miqaatService.getJamiyatJamaatWithCounts();
      if (response != null && mounted) {
        setState(() {
          _jamiyats = response.jamiyats;
          _jamaats = response.jamaats;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                'Failed to load jamiyat/jamaat data: ${e.toString().replaceFirst('Exception: ', '')}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingData = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Create Miqaat',
          style: TextStyle(
            color: Colors.black,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildTextField('Miqaat Name', _miqaatNameController),
              const SizedBox(height: 16),
              _buildJamaatDropdown(),
              const SizedBox(height: 16),
              _buildJamiyatDropdown(),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _buildDateField('From', _fromDateController),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildDateField('Till', _tillDateController),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _buildTextField('Volunteer Limit', _volunteerLimitController,
                  keyboardType: TextInputType.number),
              const SizedBox(height: 16),
              _buildMultilineTextField('About Miqaat', _aboutController),
              const SizedBox(height: 30),
              if (_isCaptain)
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _createMiqaat,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF4A1C1C),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      disabledBackgroundColor: Colors.grey,
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
                            'Add Miqaat',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                  ),
                )
              else
                const SizedBox(
                  width: double.infinity,
                  child: Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Text(
                      'Only Captains can create miqaats',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.grey,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller,
      {TextInputType? keyboardType}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Text(
        //   label,
        //   style: const TextStyle(
        //     color: Colors.grey,
        //     fontSize: 12,
        //   ),
        // ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          decoration: InputDecoration(
            filled: true,
            label: Text(label),
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
                const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
          ),
          style: const TextStyle(
            color: Colors.orange,
            fontWeight: FontWeight.w500,
            fontSize: 14,
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'This field is required';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildDateField(String label, TextEditingController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Text(
        //   label,
        //   style: const TextStyle(
        //     color: Colors.grey,
        //     fontSize: 12,
        //   ),
        // ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          readOnly: true,
          decoration: InputDecoration(
            filled: true,
            label: Text(label),
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
                const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
            suffixIcon: const Icon(
              Icons.calendar_today,
              size: 18,
              color: Colors.grey,
            ),
          ),
          style: const TextStyle(
            color: Colors.orange,
            fontWeight: FontWeight.w500,
            fontSize: 14,
          ),
          onTap: () async {
            // Set minimum date to today to prevent backdated selections
            final today = DateTime.now();
            final minDate = label == 'From'
                ? today
                : (_fromDate != null && _fromDate!.isAfter(today))
                    ? _fromDate!
                    : today;

            DateTime? pickedDate = await showDatePicker(
              context: context,
              initialDate: label == 'From'
                  ? (_fromDate ?? today)
                  : (_tillDate ?? (_fromDate ?? today)),
              firstDate: minDate,
              lastDate: DateTime(2030),
            );
            if (pickedDate != null) {
              // Format date as needed
              controller.text =
                  '${pickedDate.day}${_getDaySuffix(pickedDate.day)} ${_getMonthName(pickedDate.month)} ${pickedDate.year}';

              // Store the actual DateTime
              if (label == 'From') {
                setState(() {
                  _fromDate = pickedDate;
                });
              } else {
                setState(() {
                  _tillDate = pickedDate;
                });
              }
            }
          },
        ),
      ],
    );
  }

  Widget _buildMultilineTextField(
      String label, TextEditingController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Text(
        //   label,
        //   style: const TextStyle(
        //     color: Colors.grey,
        //     fontSize: 12,
        //   ),
        // ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          maxLines: 5,
          maxLength: 500,
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
                const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
            counterStyle: const TextStyle(
              color: Colors.grey,
              fontSize: 12,
            ),
          ),
          style: const TextStyle(
            color: Colors.orange,
            fontWeight: FontWeight.w500,
            fontSize: 14,
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'This field is required';
            }
            return null;
          },
        ),
      ],
    );
  }

  String _getDaySuffix(int day) {
    if (day >= 11 && day <= 13) {
      return 'th';
    }
    switch (day % 10) {
      case 1:
        return 'st';
      case 2:
        return 'nd';
      case 3:
        return 'rd';
      default:
        return 'th';
    }
  }

  String _getMonthName(int month) {
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
    return months[month - 1];
  }

  DateTime? _parseDate(String dateString) {
    try {
      // Parse format like "12th Oct 2023"
      final parts = dateString.split(' ');
      if (parts.length >= 3) {
        final dayStr = parts[0].replaceAll(RegExp(r'[^0-9]'), '');
        final monthStr = parts[1];
        final yearStr = parts[2];

        final day = int.parse(dayStr);
        final year = int.parse(yearStr);

        const months = {
          'Jan': 1,
          'Feb': 2,
          'Mar': 3,
          'Apr': 4,
          'May': 5,
          'Jun': 6,
          'Jul': 7,
          'Aug': 8,
          'Sep': 9,
          'Oct': 10,
          'Nov': 11,
          'Dec': 12
        };

        final month = months[monthStr] ?? 1;
        return DateTime(year, month, day);
      }
    } catch (e) {
      // If parsing fails, try to parse as ISO string
      try {
        return DateTime.parse(dateString);
      } catch (e2) {
        return null;
      }
    }
    return null;
  }

  Future<void> _createMiqaat() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // Validate dates
    if (_fromDate == null) {
      _fromDate = _parseDate(_fromDateController.text);
    }
    if (_tillDate == null) {
      _tillDate = _parseDate(_tillDateController.text);
    }

    if (_fromDate == null || _tillDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select valid dates'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_tillDate!.isBefore(_fromDate!)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Till date must be after From date'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final volunteerLimit = int.tryParse(_volunteerLimitController.text);
      if (volunteerLimit == null) {
        throw Exception('Invalid volunteer limit');
      }

      if (_selectedJamaat == null || _selectedJamiyat == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please select both Jamaat and Jamiyat'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      await _miqaatService.createMiqaat(
        miqaatName: _miqaatNameController.text.trim(),
        jamaat: _selectedJamaat!,
        jamiyat: _selectedJamiyat!,
        fromDate: _fromDate!,
        tillDate: _tillDate!,
        volunteerLimit: volunteerLimit,
        aboutMiqaat: _aboutController.text.trim().isEmpty
            ? null
            : _aboutController.text.trim(),
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Miqaat Created Successfully'),
            backgroundColor: Colors.green,
          ),
        );

        Navigator.push(
          context,
          MaterialPageRoute(
              builder: (context) => const AttendanceMiqaatScreen()),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceFirst('Exception: ', '')),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
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

  Widget _buildJamiyatDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: _selectedJamiyat,
          decoration: InputDecoration(
            filled: true,
            label: const Text('Jamiyat'),
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
                const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
          ),
          style: const TextStyle(
            color: Colors.orange,
            fontWeight: FontWeight.w500,
            fontSize: 14,
          ),
          hint: _isLoadingData
              ? const Text('Loading...')
              : const Text('Select Jamiyat'),
          items: _jamiyats.map((jamiyat) {
            return DropdownMenuItem<String>(
              value: jamiyat.name,
              child: Text(jamiyat.displayName),
            );
          }).toList(),
          onChanged: _isLoadingData
              ? null
              : (String? value) {
                  setState(() {
                    _selectedJamiyat = value;
                  });
                },
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'This field is required';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildJamaatDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: _selectedJamaat,
          decoration: InputDecoration(
            filled: true,
            label: const Text('Jamaat'),
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
                const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
          ),
          style: const TextStyle(
            color: Colors.orange,
            fontWeight: FontWeight.w500,
            fontSize: 14,
          ),
          hint: _isLoadingData
              ? const Text('Loading...')
              : const Text('Select Jamaat'),
          items: _jamaats.map((jamaat) {
            return DropdownMenuItem<String>(
              value: jamaat.name,
              child: Text(jamaat.displayName),
            );
          }).toList(),
          onChanged: _isLoadingData
              ? null
              : (String? value) {
                  setState(() {
                    _selectedJamaat = value;
                  });
                },
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'This field is required';
            }
            return null;
          },
        ),
      ],
    );
  }

  @override
  void dispose() {
    _miqaatNameController.dispose();
    _fromDateController.dispose();
    _tillDateController.dispose();
    _volunteerLimitController.dispose();
    _aboutController.dispose();
    super.dispose();
  }
}
