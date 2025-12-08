import 'package:flutter/material.dart';

class CalendarAttendanceScreen extends StatefulWidget {
  const CalendarAttendanceScreen({Key? key}) : super(key: key);

  @override
  State<CalendarAttendanceScreen> createState() =>
      _CalendarAttendanceScreenState();
}

class _CalendarAttendanceScreenState extends State<CalendarAttendanceScreen> {
  DateTime _currentMonth = DateTime(2022, 8, 1);
  DateTime _selectedDate = DateTime(2022, 8, 4);

  // Attendance data - date: status
  final Map<DateTime, String> _attendanceData = {
    DateTime(2022, 8, 8): 'present',
    DateTime(2022, 8, 9): 'absent',
    DateTime(2022, 8, 10): 'present',
    // DateTime(2022, 8, 4): 'selected',
    // DateTime(2022, 8, 11): 'selected',
    // DateTime(2022, 8, 18): 'selected',
    // DateTime(2022, 8, 25): 'selected',
    // DateTime(2022, 8, 1): 'selected',
  };

  void _previousMonth() {
    setState(() {
      _currentMonth = DateTime(_currentMonth.year, _currentMonth.month - 1);
    });
  }

  void _nextMonth() {
    setState(() {
      _currentMonth = DateTime(_currentMonth.year, _currentMonth.month + 1);
    });
  }

  void _selectDate(DateTime date) {
    setState(() {
      _selectedDate = date;
    });
  }

  Color? _getDateColor(DateTime date) {
    final dateKey = DateTime(date.year, date.month, date.day);
    if (_attendanceData.containsKey(dateKey)) {
      switch (_attendanceData[dateKey]) {
        case 'present':
          return Colors.orange;
        case 'absent':
          return Colors.red;
        case 'selected':
          return Colors.blue[100];
        default:
          return null;
      }
    }
    return null;
  }

  bool _isSelected(DateTime date) {
    return date.year == _selectedDate.year &&
        date.month == _selectedDate.month &&
        date.day == _selectedDate.day;
  }

  List<DateTime> _getDaysInMonth() {
    final firstDay = DateTime(_currentMonth.year, _currentMonth.month, 1);
    final lastDay = DateTime(_currentMonth.year, _currentMonth.month + 1, 0);

    List<DateTime> days = [];

    // Add empty days for alignment
    int weekday = firstDay.weekday % 7; // Convert to 0-6 (Sun-Sat)
    for (int i = 0; i < weekday; i++) {
      days.add(firstDay.subtract(Duration(days: weekday - i)));
    }

    // Add all days of the month
    for (int i = 0; i < lastDay.day; i++) {
      days.add(DateTime(_currentMonth.year, _currentMonth.month, i + 1));
    }

    return days;
  }

  String _getMonthYear() {
    const months = [
      'JANUARY',
      'FEBRUARY',
      'MARCH',
      'APRIL',
      'MAY',
      'JUNE',
      'JULY',
      'AUGUST',
      'SEPTEMBER',
      'OCTOBER',
      'NOVEMBER',
      'DECEMBER'
    ];
    return '${months[_currentMonth.month - 1]} ${_currentMonth.year}';
  }

  int _getAbsentCount() {
    int count = 0;
    _attendanceData.forEach((date, status) {
      if (status == 'absent' &&
          date.month == _currentMonth.month &&
          date.year == _currentMonth.year) {
        count++;
      }
    });
    return count;
  }

  @override
  Widget build(BuildContext context) {
    final days = _getDaysInMonth();

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: Column(
        children: [
          // Custom AppBar
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
                  // Header with back, logo, and notification
                  Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        IconButton(
                          icon:
                              const Icon(Icons.arrow_back, color: Colors.white),
                          onPressed: () => Navigator.pop(context),
                        ),
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.business_center,
                            color: Color(0xFF4A1C1C),
                            size: 24,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.notifications_outlined,
                              color: Colors.white),
                          onPressed: () {},
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),

          // Content
          Expanded(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    // Event Card
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 10,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '1ST MAY- SAT -2:00 PM',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey[600],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'Urs Mubarak Ayyam',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Calendar Container
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 10,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          // Month Navigation
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.chevron_left),
                                onPressed: _previousMonth,
                              ),
                              Text(
                                _getMonthYear(),
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black,
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.chevron_right),
                                onPressed: _nextMonth,
                              ),
                            ],
                          ),

                          const SizedBox(height: 16),

                          // Weekday Headers
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              _buildWeekdayHeader('Mo'),
                              _buildWeekdayHeader('Tu'),
                              _buildWeekdayHeader('We'),
                              _buildWeekdayHeader('Th'),
                              _buildWeekdayHeader('Fr'),
                              _buildWeekdayHeader('Sa'),
                              _buildWeekdayHeader('Su'),
                            ],
                          ),

                          const SizedBox(height: 16),

                          // Calendar Grid
                          GridView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            gridDelegate:
                                const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 7,
                              mainAxisSpacing: 8,
                              crossAxisSpacing: 8,
                              childAspectRatio: 1,
                            ),
                            itemCount: days.length,
                            itemBuilder: (context, index) {
                              final date = days[index];
                              final isCurrentMonth =
                                  date.month == _currentMonth.month;
                              final dateColor = _getDateColor(date);

                              return GestureDetector(
                                onTap: () => _selectDate(date),
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: dateColor,
                                    shape: BoxShape.circle,
                                    border: _isSelected(date)
                                        ? Border.all(
                                            color: const Color(0xFF4A1C1C),
                                            width: 2,
                                          )
                                        : null,
                                  ),
                                  child: Center(
                                    child: Text(
                                      '${date.day}',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                        color: isCurrentMonth
                                            ? (dateColor != null
                                                ? Colors.white
                                                : Colors.black)
                                            : Colors.grey[400],
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Absent Counter
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey[300]!),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(2),
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
                          const SizedBox(width: 12),
                          const Expanded(
                            child: Text(
                              'Absent',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Colors.black,
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.red[50],
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Text(
                              '${_getAbsentCount().toString().padLeft(2, '0')}',
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: Colors.red,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWeekdayHeader(String day) {
    return SizedBox(
      width: 40,
      child: Text(
        day,
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: Colors.grey[600],
        ),
      ),
    );
  }
}
