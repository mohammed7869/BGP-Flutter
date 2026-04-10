import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';

/// Data returned from the Bohra Calendar when used in picker mode.
class BohraCalendarSelection {
  final String? miqaatName;
  final DateTime? fromDate;
  final DateTime? tillDate;

  BohraCalendarSelection({this.miqaatName, this.fromDate, this.tillDate});
}

class BohraCalendarScreen extends StatefulWidget {
  /// When true, shows input fields at the bottom for the captain to enter
  /// miqaat name and dates after browsing the calendar, and returns
  /// a [BohraCalendarSelection] via Navigator.pop().
  final bool pickerMode;

  const BohraCalendarScreen({super.key, this.pickerMode = false});

  @override
  State<BohraCalendarScreen> createState() => _BohraCalendarScreenState();
}

class _BohraCalendarScreenState extends State<BohraCalendarScreen> {
  WebViewController? _controller;
  bool _isLoading = true;
  bool _showPickerPanel = false;

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _fromDateController = TextEditingController();
  final TextEditingController _tillDateController = TextEditingController();
  DateTime? _selectedFromDate;
  DateTime? _selectedTillDate;

  @override
  void initState() {
    super.initState();
    if (!kIsWeb) {
      _controller = WebViewController()
        ..setJavaScriptMode(JavaScriptMode.unrestricted)
        ..setBackgroundColor(const Color(0x00000000))
        ..setNavigationDelegate(
          NavigationDelegate(
            onProgress: (int progress) {
              // Update loading bar.
            },
            onPageStarted: (String url) {
              if (mounted) {
                setState(() {
                  _isLoading = true;
                });
              }
            },
            onPageFinished: (String url) {
              if (mounted) {
                setState(() {
                  _isLoading = false;
                });
              }
            },
            onWebResourceError: (WebResourceError error) {},
            onNavigationRequest: (NavigationRequest request) {
              // Allow all internal navigation.
              return NavigationDecision.navigate;
            },
          ),
        )
        ..loadRequest(Uri.parse('https://bohracalendar.com/'));
    } else {
      _isLoading = false;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _fromDateController.dispose();
    _tillDateController.dispose();
    super.dispose();
  }

  String _formatDateDisplay(DateTime date) {
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  Future<void> _pickDate(bool isFrom) async {
    final today = DateTime.now();
    final initial = isFrom
        ? (_selectedFromDate ?? today)
        : (_selectedTillDate ?? _selectedFromDate ?? today);
    final firstDate = isFrom ? today : (_selectedFromDate ?? today);

    final picked = await showDatePicker(
      context: context,
      initialDate: initial.isBefore(firstDate) ? firstDate : initial,
      firstDate: firstDate,
      lastDate: DateTime(2030),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF8B6914),
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        if (isFrom) {
          _selectedFromDate = picked;
          _fromDateController.text = _formatDateDisplay(picked);
          // Reset till date if it's before the new from date
          if (_selectedTillDate != null && _selectedTillDate!.isBefore(picked)) {
            _selectedTillDate = null;
            _tillDateController.clear();
          }
        } else {
          _selectedTillDate = picked;
          _tillDateController.text = _formatDateDisplay(picked);
        }
      });
    }
  }

  void _applySelection() {
    final selection = BohraCalendarSelection(
      miqaatName: _nameController.text.trim().isEmpty ? null : _nameController.text.trim(),
      fromDate: _selectedFromDate,
      tillDate: _selectedTillDate,
    );

    // At least one field should be filled
    if (selection.miqaatName == null && selection.fromDate == null && selection.tillDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter at least a miqaat name or select dates'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    Navigator.pop(context, selection);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF8B6914),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          widget.pickerMode ? 'Select from Calendar' : 'Bohra Calendar',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: widget.pickerMode
            ? [
                IconButton(
                  icon: Icon(
                    _showPickerPanel ? Icons.keyboard_arrow_down : Icons.edit_note_rounded,
                    color: Colors.white,
                  ),
                  tooltip: _showPickerPanel ? 'Hide panel' : 'Fill details',
                  onPressed: () {
                    setState(() {
                      _showPickerPanel = !_showPickerPanel;
                    });
                  },
                ),
              ]
            : null,
      ),
      body: Column(
        children: [
          // Picker mode hint bar
          if (widget.pickerMode && !_showPickerPanel)
            GestureDetector(
              onTap: () {
                setState(() {
                  _showPickerPanel = true;
                });
              },
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFFFFF8E1), Color(0xFFFFF3E0)],
                  ),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.touch_app_rounded, size: 16, color: Color(0xFF8B6914)),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Browse the calendar, then tap the ✏️ icon to fill in Miqaat details',
                        style: TextStyle(
                          fontSize: 12,
                          color: Color(0xFF8B6914),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    Icon(Icons.arrow_upward_rounded, size: 14, color: Color(0xFF8B6914)),
                  ],
                ),
              ),
            ),

          // WebView
          Expanded(
            child: Stack(
              children: [
                if (!kIsWeb && _controller != null)
                  WebViewWidget(controller: _controller!),
                if (kIsWeb)
                  Center(
                    child: SingleChildScrollView(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.public, size: 64, color: Color(0xFF8B6914)),
                          const SizedBox(height: 16),
                          const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 24),
                            child: Text(
                              'In-app calendar browsing is not fully supported on the web version.',
                              style: TextStyle(fontSize: 16, color: Color(0xFF333333)),
                              textAlign: TextAlign.center,
                            ),
                          ),
                          const SizedBox(height: 24),
                          ElevatedButton.icon(
                            onPressed: () async {
                              final url = Uri.parse('https://bohracalendar.com/');
                              if (await canLaunchUrl(url)) {
                                await launchUrl(url, mode: LaunchMode.externalApplication);
                              }
                            },
                            icon: const Icon(Icons.open_in_new),
                            label: const Text('Open Calendar in New Tab'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF8B6914),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                if (_isLoading)
                  const Center(
                    child: CircularProgressIndicator(
                      color: Color(0xFF8B6914),
                    ),
                  ),
              ],
            ),
          ),

          // Picker panel (bottom sheet-style)
          if (widget.pickerMode && _showPickerPanel)
            _buildPickerPanel(),
        ],
      ),
    );
  }

  Widget _buildPickerPanel() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Container(
            margin: const EdgeInsets.only(top: 10),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.calendar_month_rounded, size: 18, color: Color(0xFF8B6914)),
                    SizedBox(width: 8),
                    Text(
                      'Fill Miqaat Details from Calendar',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF333333),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'Enter the miqaat name and/or dates you found, or type your own.',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 14),

                // Miqaat Name
                TextFormField(
                  controller: _nameController,
                  decoration: InputDecoration(
                    labelText: 'Miqaat Name',
                    hintText: 'e.g. Ashara Mubaraka, Urus Mubarak...',
                    hintStyle: TextStyle(fontSize: 12, color: Colors.grey[400]),
                    filled: true,
                    fillColor: const Color(0xFFFFFBF0),
                    prefixIcon: const Icon(Icons.event_note_rounded, size: 18, color: Color(0xFF8B6914)),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: Colors.amber.shade200),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: Color(0xFF8B6914), width: 1.5),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  ),
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF333333),
                  ),
                ),
                const SizedBox(height: 12),

                // Date fields
                Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () => _pickDate(true),
                        child: AbsorbPointer(
                          child: TextFormField(
                            controller: _fromDateController,
                            decoration: InputDecoration(
                              labelText: 'From Date',
                              hintText: 'Select',
                              hintStyle: TextStyle(fontSize: 12, color: Colors.grey[400]),
                              filled: true,
                              fillColor: const Color(0xFFFFFBF0),
                              suffixIcon: const Icon(Icons.calendar_today, size: 16, color: Color(0xFF8B6914)),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: BorderSide(color: Colors.amber.shade200),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: const BorderSide(color: Color(0xFF8B6914), width: 1.5),
                              ),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                            ),
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: Color(0xFF333333),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: GestureDetector(
                        onTap: () => _pickDate(false),
                        child: AbsorbPointer(
                          child: TextFormField(
                            controller: _tillDateController,
                            decoration: InputDecoration(
                              labelText: 'Till Date',
                              hintText: 'Select',
                              hintStyle: TextStyle(fontSize: 12, color: Colors.grey[400]),
                              filled: true,
                              fillColor: const Color(0xFFFFFBF0),
                              suffixIcon: const Icon(Icons.calendar_today, size: 16, color: Color(0xFF8B6914)),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: BorderSide(color: Colors.amber.shade200),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: const BorderSide(color: Color(0xFF8B6914), width: 1.5),
                              ),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                            ),
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: Color(0xFF333333),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Apply button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _applySelection,
                    icon: const Icon(Icons.check_circle_outline, size: 18),
                    label: const Text(
                      'Use These Details',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF8B6914),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 2,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
