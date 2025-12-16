import 'package:burhaniguardsapp/ui/screens/common/unified_login_screen.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
// Temporarily disabled PWA install due to web compatibility issues
// import 'package:pwa_install/pwa_install.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // Setup global error handlers
  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.presentError(details);
    debugPrint('Flutter Error: ${details.exception}');
  };

  // PWA install setup disabled temporarily due to web compatibility issues
  // The pwa_install package is causing initialization errors on web
  // TODO: Re-enable once pwa_install package is updated or alternative solution is found
  /*
  if (kIsWeb) {
    try {
      PWAInstall().setup(installCallback: () {
        debugPrint('APP INSTALLED!');
      });
    } catch (e) {
      debugPrint('PWA Install setup error: $e');
    }
  }
  */

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Burhani Guards',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
        textTheme: _getTextTheme(),
      ),
      home: const UnifiedLoginScreen(),
    );
  }

  // Helper method to get text theme with fallback
  static TextTheme _getTextTheme() {
    try {
      return GoogleFonts.poppinsTextTheme();
    } catch (e) {
      debugPrint('Error loading Google Fonts: $e');
      // Return default text theme as fallback
      return Typography.material2021().black;
    }
  }
}
