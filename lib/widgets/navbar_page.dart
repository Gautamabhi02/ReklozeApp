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
      actions: [
        IconButton(
          icon: const Icon(Icons.notifications_none, color: Colors.white),
          onPressed: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("No new notifications")),
            );
          },
        ),
        IconButton(
          icon: const Icon(Icons.account_circle, color: Colors.white),
          onPressed: () {
            Navigator.pushNamed(context, '/profile');
          },
        ),
      ],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
