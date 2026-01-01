class ApiConstants {
  // Production API base URL
  // Swagger UI documentation: https://bgp.baawanerp.com/SWAGGER/index.html
   static const String baseUrl = 'https://bgp.baawanerp.com'; //Live URL
  // static const String baseUrl = 'http://192.168.141.207:5000';
  // static const String baseUrl = 'http://192.168.1.4:5000'; //Local URL
//   static const String baseUrl = 'http://192.168.141.207:5000'; //Local URL
  // API Endpoints - Unified users table
  static const String login = '/api/1/login';

  static const String changePassword = '/api/1/change-password';

  // API Endpoints - Miqaat
  static const String createMiqaat = '/api/1/miqaat';
  static const String getAllMiqaats = '/api/1/miqaat';
  static const String getMemberMiqaats = '/api/1/miqaat/member';
  static const String updateMemberMiqaatStatus = '/api/1/miqaat';
  static const String getEnrolledMembers = '/api/1/miqaat';

  // API Endpoints - Users
  static const String getJamiyatJamaat = '/api/1/users/jamiyat-jamaat';
}
