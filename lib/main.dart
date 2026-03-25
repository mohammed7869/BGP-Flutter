import 'package:burhaniguardsapp/core/services/auth_service.dart';
import 'package:burhaniguardsapp/ui/screens/admin/adminDashboard.dart';
import 'package:burhaniguardsapp/ui/screens/common/unified_login_screen.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // Setup global error handlers
  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.presentError(details);
    debugPrint('Flutter Error: ${details.exception}');
  };

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Burhani Guards',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF0D7377),
          brightness: Brightness.light,
        ),
        useMaterial3: true,
        textTheme: _getTextTheme(),
      ),
      home: const SplashScreen(),
    );
  }

  static TextTheme _getTextTheme() {
    try {
      return GoogleFonts.poppinsTextTheme();
    } catch (e) {
      debugPrint('Error loading Google Fonts: $e');
      return Typography.material2021().black;
    }
  }
}

/// Splash screen that checks login status and navigates accordingly
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkLoginStatus();
  }

  Future<void> _checkLoginStatus() async {
    try {
      final authService = AuthService();
      final hasValidSession = await authService.validateStoredSession();

      if (!mounted) return;

      if (hasValidSession) {
        // User is already logged in, go directly to dashboard
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => const AdminDashboardScreen(),
          ),
        );
      } else {
        // User is not logged in, show login screen
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => const UnifiedLoginScreen(),
          ),
        );
      }
    } catch (e) {
      debugPrint('Error checking login status: $e');
      if (!mounted) return;
      // On error, default to login screen
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => const UnifiedLoginScreen(),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
}
