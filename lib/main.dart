import 'package:burhaniguardsapp/core/services/auth_service.dart';
import 'package:burhaniguardsapp/core/services/fcm_service.dart';
import 'package:burhaniguardsapp/core/services/notification_navigator.dart';
import 'package:burhaniguardsapp/core/services/notification_service.dart';
import 'package:burhaniguardsapp/core/services/signalr_service.dart';
import 'package:burhaniguardsapp/ui/screens/admin/adminDashboard.dart';
import 'package:burhaniguardsapp/ui/screens/common/unified_login_screen.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:upgrader/upgrader.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:burhaniguardsapp/firebase_options.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase (must be done before any Firebase service)
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    // Register the background message handler (runs even when app is killed)
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
  } catch (e) {
    debugPrint('Firebase initialization failed: $e');
  }

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
      // Use the global navigator key for notification deep-linking
      navigatorKey: NotificationNavigator.navigatorKey,
      builder: (context, child) {
        return UpgradeAlert(
          upgrader: Upgrader(
            countryCode: 'IN',
          ),
          showIgnore: false,
          showLater: false,
          barrierDismissible: false,
          child: child ?? const SizedBox.shrink(),
        );
      },
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
        // Initialize notification services after confirmed login
        await _initializeNotifications();

        if (!mounted) return;
        // User is already logged in, go directly to dashboard
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => const AdminDashboardScreen(),
          ),
        );

        // Check if app was launched from a notification tap
        _handleInitialNotification();
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

  /// Initialize local notifications and connect to SignalR hub.
  Future<void> _initializeNotifications() async {
    try {
      // 1. Initialize local notification plugin & channels
      final localNotifications = LocalNotificationService();
      await localNotifications.initialize();

      // 2. Request notification permission (Android 13+)
      await localNotifications.requestPermission();

      // 3. Set up notification tap handler for deep-linking
      localNotifications.onNotificationTapped = (payload) {
        NotificationNavigator.handleNotificationTap(payload);
      };

      // 4. Connect to SignalR hub for real-time notifications (foreground)
      final signalR = SignalRService();
      signalR.connect().catchError((e) => debugPrint('SignalR init error: $e'));

      // 5. Initialize Firebase Cloud Messaging (background/killed state)
      try {
        final fcmService = FcmService();
        await fcmService.initialize();
      } catch (e) {
        debugPrint('FCM initialization failed: $e');
      }

      debugPrint('Notification services initialized successfully');
    } catch (e) {
      // Don't block app startup if notifications fail
      debugPrint('Error initializing notifications: $e');
    }
  }

  /// Check if the app was launched by tapping a notification.
  /// If so, navigate to the appropriate screen.
  Future<void> _handleInitialNotification() async {
    try {
      final localNotifications = LocalNotificationService();
      final payload = await localNotifications.getInitialNotificationPayload();
      if (payload != null) {
        debugPrint('App launched from notification: $payload');
        // Small delay to let the dashboard fully render first
        await Future.delayed(const Duration(milliseconds: 500));
        NotificationNavigator.handleNotificationTap(payload);
      }
    } catch (e) {
      debugPrint('Error handling initial notification: $e');
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
