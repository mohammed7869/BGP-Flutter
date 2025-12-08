import 'package:burhaniguardsapp/ui/screens/admin/attendancemiqaatScreen.dart';
import 'package:flutter/material.dart';

class CreateMiqaatScreen extends StatefulWidget {
  const CreateMiqaatScreen({Key? key}) : super(key: key);

  @override
  State<CreateMiqaatScreen> createState() => _CreateMiqaatScreenState();
}

class _CreateMiqaatScreenState extends State<CreateMiqaatScreen> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _miqaatNameController =
      TextEditingController(text: 'Women\'s leadership conference');
  final TextEditingController _jamaatController =
      TextEditingController(text: 'Kalimi Mohalla (Poona)');
  final TextEditingController _jamiaatController =
      TextEditingController(text: 'Poona');
  final TextEditingController _fromDateController =
      TextEditingController(text: '12th Oct 2023');
  final TextEditingController _tillDateController =
      TextEditingController(text: '14th Oct 2023');
  final TextEditingController _volunteerLimitController =
      TextEditingController(text: '100');
  final TextEditingController _aboutController = TextEditingController(
      text:
          'Enjoy your favorite dishe and a lovely your friends and family and have a great time. Food from local food trucks will be available for purchase.');

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
              _buildTextField('Jamaat', _jamaatController),
              const SizedBox(height: 16),
              _buildTextField('jamiaat', _jamiaatController),
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
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: () {
                    if (_formKey.currentState!.validate()) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text('Miqaat Created Successfully')),
                      );

                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) =>
                                const AttendanceMiqaatScreen()),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4A1C1C),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Add Miqaat',
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
            DateTime? pickedDate = await showDatePicker(
              context: context,
              initialDate: DateTime.now(),
              firstDate: DateTime(2020),
              lastDate: DateTime(2030),
            );
            if (pickedDate != null) {
              // Format date as needed
              controller.text =
                  '${pickedDate.day}${_getDaySuffix(pickedDate.day)} ${_getMonthName(pickedDate.month)} ${pickedDate.year}';
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

  @override
  void dispose() {
    _miqaatNameController.dispose();
    _jamaatController.dispose();
    _jamiaatController.dispose();
    _fromDateController.dispose();
    _tillDateController.dispose();
    _volunteerLimitController.dispose();
    _aboutController.dispose();
    super.dispose();
  }
}
