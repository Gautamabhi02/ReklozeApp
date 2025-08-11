import 'package:flutter/material.dart';
import '../service/user_session_service.dart';

class CustomNavbar extends StatelessWidget {
  const CustomNavbar({super.key});

  void _navigateTo(BuildContext context, String route) {
    Navigator.pushReplacementNamed(context, route);
  }

  @override
  Widget build(BuildContext context) {
    final session = UserSessionService();

    final username = session.username?.isNotEmpty==true ? session.username
        :'';
    final email = session.email?.isNotEmpty==true ? session.email
        :'';

    print('username:$username');

    print('Email:$email');

    return Drawer(
      child: Column(
        children: [
          Stack(
            children: [
              UserAccountsDrawerHeader(
                decoration: const BoxDecoration(color: Colors.blue),
                accountName:  Text(username ?? ''),
                accountEmail: Text(email ?? ''),
                currentAccountPicture: const CircleAvatar(
                  backgroundColor: Colors.white,
                  child: Icon(Icons.person, size: 40, color: Colors.blue),
                ),
              ),
              Positioned(
                right: 8,
                top: 8,
                child: GestureDetector(
                  onTap: () => Navigator.pop(context), // Closes the drawer
                  child: const Icon(Icons.close, color: Colors.white),
                ),
              ),
            ],
          ),
          Expanded(
            child: ListView(
              children: [
                ListTile(
                  leading: const Icon(Icons.home),
                  title: const Text('Home'),
                  onTap: () => _navigateTo(context, '/homePage'),
                ),
                ListTile(
                  leading: const Icon(Icons.upload_file),
                  title: const Text('Upload'),
                  onTap: () => _navigateTo(context, '/contract'),
                ),
                ListTile(
                  leading: const Icon(Icons.edit_document),
                  title: const Text('Timelines'),
                  onTap: () => _navigateTo(context, '/editContractTimeline'),
                ),
                ListTile(
                  leading: const Icon(Icons.calendar_today),
                  title: const Text('Calendar'),
                  onTap: () => _navigateTo(context, '/calender'),
                ),
                ListTile(
                  leading: const Icon(Icons.settings),
                  title: const Text('Settings'),
                  onTap: () => _navigateTo(context, '/settingsPage'),
                ),
                const Divider(),
                ListTile(
                  leading: const Icon(Icons.logout),
                  title: const Text('Logout'),
                  onTap: () => _navigateTo(context, '/loginPage'),
                ),
              ],
            ),
          ),
          const Padding(
            padding: EdgeInsets.all(12.0),
            child: Text(
              '© 2025 Rekloze Inc.',
              style: TextStyle(color: Colors.grey, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
}
