import 'package:flutter/material.dart';

Widget buildAppBar(BuildContext context, GlobalKey<ScaffoldState> scaffoldKey) {
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
    decoration: const BoxDecoration(
      color: Color(0xFF4A1C1C),
      borderRadius: BorderRadius.only(
        bottomLeft: Radius.circular(20),
        bottomRight: Radius.circular(20),
      ),
    ),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        IconButton(
          icon: const Icon(Icons.menu, color: Colors.white, size: 28),
          onPressed: () {
            // Use the scaffoldKey passed into this widget to open the drawer.
            // This avoids relying on Scaffold.of(context), which fails when
            // the context isn't a descendant of the Scaffold.
            scaffoldKey.currentState?.openDrawer();
          },
        ),
        Image.asset('assets/images/burhani guards logo.png', height: 52),
        IconButton(
          icon: const Icon(Icons.notifications_outlined,
              color: Colors.white, size: 28),
          onPressed: () {},
        ),
      ],
    ),
  );
}
