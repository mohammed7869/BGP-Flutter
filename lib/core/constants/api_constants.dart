class ApiConstants {
  // Production API base URL
  // Swagger UI documentation: https://bgp.baawanerp.com/SWAGGER/index.html
  static const String baseUrl = 'https://bgp.baawanerp.com'; //Live URL
  // static const String baseUrl = 'http://192.168.141.207:5000';
  // static const String baseUrl = 'http://192.168.31.97:5000'; //Local URL
  // static const String baseUrl = 'http://192.168.1.5:5000'; //Local URL
  // static const String baseUrl = 'http://10.243.56.246:5000'; //Local URL
  // static const String baseUrl = 'http://192.168.71.203:5000'; //Local URL
  // API Endpoints - Unified users table
  static const String login = '/api/1/login';

  static const String changePassword = '/api/1/change-password';
  static const String forgotPassword = '/api/1/forgot-password';
  static const String verifyOtp = '/api/1/verify-otp';
  static const String resetPassword = '/api/1/reset-password';
  static const String updateProfile = '/api/1/update-profile';
  static const String getUserProfile = '/api/1/user-profile';

  // API Endpoints - Miqaat
  static const String createMiqaat = '/api/1/miqaat';
  static const String getAllMiqaats = '/api/1/miqaat';
  static const String getMemberMiqaats = '/api/1/miqaat/member';
  static const String updateMemberMiqaatStatus = '/api/1/miqaat';
  static const String getEnrolledMembers = '/api/1/miqaat';
  static const String getMiqaatPoints = '/api/1/miqaat/points';

  // API Endpoints - Users
  static const String getJamiyatJamaat = '/api/1/users/jamiyat-jamaat';
  static const String createUser = '/api/1/users';
  static const String approveMember = '/api/1/users';
  static const String getMembersByJamaat = '/api/1/users/jamaat';
  static const String getHierarchyMembers = '/api/1/users/hierarchy';
  static const String getMemberEnrollmentDays = '/api/1/miqaat';

  // API Endpoints - Survey
  static const String submitSurvey = '/api/1/survey';
  static const String hasSubmittedSurvey = '/api/1/survey/has-submitted';
  static const String mySurvey = '/api/1/survey/my-survey';

  // Image URLs
  static String get miqaatImagesBaseUrl => '$baseUrl/bgp_uploads/miqaat_images';

  // API Endpoints - Notifications
  static const String notifications = '/api/1/notifications';
  static const String unreadCount = '/api/1/notifications/unread-count';
  static const String markRead = '/api/1/notifications/mark-read';
  static const String markAllRead = '/api/1/notifications/mark-all-read';
  static const String sendNotification = '/api/1/notifications/send';

  // SignalR Hub URL
  static String get notificationHubUrl => '$baseUrl/hubs/notification';

  // FCM Token Registration
  static const String registerFcmToken = '/api/1/users/fcm-token';
}
