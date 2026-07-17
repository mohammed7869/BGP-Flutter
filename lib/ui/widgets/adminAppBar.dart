import 'package:burhaniguardsapp/core/constants/app_colors.dart';
import 'package:burhaniguardsapp/core/services/local_storage_service.dart';
import 'package:burhaniguardsapp/core/services/signalr_service.dart';
import 'package:burhaniguardsapp/ui/screens/common/bohraCalendarScreen.dart';
import 'package:burhaniguardsapp/ui/screens/common/unified_login_screen.dart';
import 'package:burhaniguardsapp/ui/widgets/notification_bell_widget.dart';
import 'package:flutter/material.dart';

Widget buildAppBar(BuildContext context, GlobalKey<ScaffoldState> scaffoldKey) {
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
    decoration: BoxDecoration(
      gradient: AppColors.heroGradient,
      borderRadius: const BorderRadius.only(
        bottomLeft: Radius.circular(24),
        bottomRight: Radius.circular(24),
      ),
      boxShadow: [
        BoxShadow(
          color: AppColors.primaryDark.withOpacity(0.30),
          blurRadius: 16,
          offset: const Offset(0, 6),
        ),
      ],
    ),
    child: Row(
      children: [
        SizedBox(
          width: 96,
          child: Align(
            alignment: Alignment.centerLeft,
            child: IconButton(
              icon: const Icon(Icons.menu_rounded, color: Colors.white, size: 28),
              onPressed: () {
                scaffoldKey.currentState?.openDrawer();
              },
            ),
          ),
        ),
        Expanded(
          child: Center(
            child: Image.asset('assets/images/burhani guards logo.png',
                height: 52),
          ),
        ),
        SizedBox(
          width: 136,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            mainAxisSize: MainAxisSize.min,
            children: [
              const NotificationBellWidget(),
              IconButton(
                icon: const Icon(Icons.calendar_month_outlined,
                    color: Colors.white, size: 26),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const BohraCalendarScreen()),
                  );
                },
              ),
              IconButton(
                icon: const Icon(Icons.logout_rounded,
                    color: Colors.white, size: 26),
                onPressed: () async {
                  final shouldLogout = await showDialog<bool>(
                    context: context,
                    barrierDismissible: false,
                    builder: (dialogContext) => AlertDialog(
                      title: const Text('Log Out'),
                      content: const Text('Are you sure you want to log out?'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(dialogContext, false),
                          child: const Text('Cancel'),
                        ),
                        TextButton(
                          onPressed: () => Navigator.pop(dialogContext, true),
                          child: const Text(
                            'Log Out',
                            style: TextStyle(color: Colors.red),
                          ),
                        ),
                      ],
                    ),
                  );
                  if (shouldLogout == true) {
                    final localStorage = LocalStorageService();
                    await localStorage.clearAll();
                    // Disconnect SignalR on logout
                    await SignalRService().disconnect();
                    if (context.mounted) {
                      Navigator.of(context, rootNavigator: true)
                          .pushAndRemoveUntil(
                        MaterialPageRoute(
                            builder: (context) => const UnifiedLoginScreen()),
                        (route) => false,
                      );
                    }
                  }
                },
              ),
            ],
          ),
        ),
      ],
    ),
  );
}
