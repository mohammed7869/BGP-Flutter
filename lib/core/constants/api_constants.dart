class ApiConstants {
  // IMPORTANT: For physical device connected via USB:
  // 1. Find your laptop's IP address: Run 'ipconfig' in Command Prompt
  // 2. Look for "IPv4 Address" (e.g., 192.168.1.100)
  // 3. Replace 'YOUR_IP_ADDRESS' below with your actual IP
  // 4. Make sure your phone and laptop are on the same Wi-Fi network
  //
  // Examples:
  // - Physical device (same Wi-Fi): http://192.168.1.100:5000
  // - Android emulator: http://10.0.2.2:5000
  // - iOS simulator: http://localhost:5000
  static const String baseUrl = 'http://192.168.31.97:5000';

  // API Endpoints - Unified users table
  static const String login = '/api/1/login';

  static const String changePassword = '/api/1/change-password';
}
