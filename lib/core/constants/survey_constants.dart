/// Static arrays for Survey form dropdowns
/// Department and Zone stored as id in database

class SurveyDepartment {
  final int id;
  final String text;

  const SurveyDepartment({required this.id, required this.text});
}

class SurveyZone {
  final int id;
  final String text;

  const SurveyZone({required this.id, required this.text});
}

class SurveyConstants {
  static const List<SurveyDepartment> departments = [
    SurveyDepartment(id: 1, text: 'Not Assigned Any Khidmat'),
    SurveyDepartment(id: 2, text: 'PMO'),
    SurveyDepartment(id: 3, text: 'Human Resources'),
    SurveyDepartment(id: 4, text: 'PR / Govt Relations'),
    SurveyDepartment(id: 5, text: 'Construction'),
    SurveyDepartment(id: 6, text: 'Mawaid'),
    SurveyDepartment(id: 7, text: 'Procurement'),
    SurveyDepartment(id: 8, text: 'Finance'),
    SurveyDepartment(id: 9, text: 'AVRP (Audio/Video/Relay/Photography)'),
    SurveyDepartment(id: 10, text: 'Flow Management'),
    SurveyDepartment(id: 11, text: 'Transport'),
    SurveyDepartment(id: 12, text: 'Nazafat'),
    SurveyDepartment(id: 13, text: 'IT Services'),
    SurveyDepartment(id: 14, text: 'Zones'),
    SurveyDepartment(id: 15, text: 'ITS'),
    SurveyDepartment(id: 16, text: 'Medical'),
    SurveyDepartment(id: 17, text: 'Tazyeen'),
    SurveyDepartment(id: 18, text: 'Communications'),
    SurveyDepartment(id: 19, text: 'Mumineen Mehmaan Reception'),
    SurveyDepartment(id: 20, text: 'Central Office'),
    SurveyDepartment(id: 21, text: 'Fire Safety / HSE (Health, Safety, Environment)'),
    SurveyDepartment(id: 22, text: 'Accommodation'),
    SurveyDepartment(id: 23, text: 'Security'),
    SurveyDepartment(id: 24, text: 'Karamat'),
    SurveyDepartment(id: 25, text: 'Food Hygiene & Safety'),
    SurveyDepartment(id: 26, text: 'QA Support Management'),
    SurveyDepartment(id: 27, text: 'Waaz Talaqqi & Ohbat'),
    SurveyDepartment(id: 28, text: 'Al-Vazarat Follow Up'),
    SurveyDepartment(id: 29, text: 'Signage & Maps'),
    SurveyDepartment(id: 30, text: 'Zakereen'),
    SurveyDepartment(id: 31, text: 'Bethak'),
    SurveyDepartment(id: 32, text: 'Mazaraat'),
    SurveyDepartment(id: 33, text: 'Laundry'),
  ];

  static const List<SurveyZone> zones = [
    SurveyZone(id: 3, text: 'CMZ'),
    SurveyZone(id: 1, text: 'Ashara City'),
    SurveyZone(id: 8, text: 'Inamdaar(Azam Campus)'),
    SurveyZone(id: 2, text: 'Burhani Mohalla'),
    SurveyZone(id: 4, text: 'Fakhri Mohalla'),
    SurveyZone(id: 5, text: 'Fatemi Mohalla'),
    SurveyZone(id: 6, text: 'Hasanjinagar'),
    SurveyZone(id: 7, text: 'Imadi Mohalla (Hadapsar)'),
    SurveyZone(id: 9, text: 'Jamali Mohalla (Undri)'),
    SurveyZone(id: 10, text: 'Kalimi Mohalla'),
    SurveyZone(id: 11, text: 'Mohammadi Mohalla'),
    SurveyZone(id: 12, text: 'Mufaddal Mohalla'),
    SurveyZone(id: 13, text: 'Taiyebi Mohalla'),
    SurveyZone(id: 14, text: 'Vajihi Mohalla (Kasarwadi)'),
    SurveyZone(id: 15, text: 'Zainee Mohalla'),
  ];

  /// Get department text by id
  static String getDepartmentText(int id) {
    try {
      return departments.firstWhere((d) => d.id == id).text;
    } catch (_) {
      return 'Unknown';
    }
  }

  /// Get zone text by id
  static String getZoneText(int id) {
    try {
      return zones.firstWhere((z) => z.id == id).text;
    } catch (_) {
      return 'Unknown';
    }
  }
}
