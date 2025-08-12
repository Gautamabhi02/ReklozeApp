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

    final firstName = session.firstName?.trim() ?? '';
    final middleName = session.middleName?.trim() ?? '';
    final lastName = session.lastName?.trim() ?? '';
    final username = session.username?.trim() ?? '';
    final email = session.email?.trim() ?? '';

    final paymentStatus = session.paymentStatus?.toLowerCase() ?? 'notpaid';


    final fullName = [firstName, middleName, lastName]
        .where((name) => name.isNotEmpty)
        .join(' ');

    return Drawer(
      child: Column(
        children: [
          Stack(
            children: [
              UserAccountsDrawerHeader(
                decoration: const BoxDecoration(color: Colors.blue),
                accountName: Text(fullName),
                accountEmail: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (username.isNotEmpty)
                      Text('@$username', style: const TextStyle(fontSize: 12)),
                    if (email.isNotEmpty)
                      Text(email, style: const TextStyle(fontSize: 12)),
                  ],
                ),
                // currentAccountPicture removed as requested
              ),
              Positioned(
                right: 8,
                top: 8,
                child: GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: const Icon(Icons.close, color: Colors.white),
                ),
              ),
            ],
          ),
          Expanded(
            child: ListView(
              children: [
                if (paymentStatus == 'notpaid') // Only show if not paid
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