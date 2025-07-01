// lib/widgets/navbar_page.dart
import 'package:flutter/material.dart';

class NavbarPage extends StatelessWidget implements PreferredSizeWidget {
  const NavbarPage({super.key});

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.indigo,
      elevation: 1,
      iconTheme: const IconThemeData(color: Colors.white),
      title: const Text(
        'Rekloze',
        style: TextStyle(color: Colors.white),
      ),
      actions: const [
        Icon(Icons.notifications_none, color: Colors.white),
        SizedBox(width: 10),
        Icon(Icons.account_circle, color: Colors.white),
        SizedBox(width: 10),
      ],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
