import 'package:flutter/material.dart';
import 'upload_contract_page.dart';
import '../widgets/navbar_page.dart';
import '../widgets/custom_navbar.dart';

class SubscriptionPage extends StatelessWidget {
  const SubscriptionPage({super.key});

  final List<Map<String, dynamic>> paymentPlans = const [
    {
      'title': 'Basic Plan',
      'desc': 'Essential Feature',
      'color': Colors.blue
    },
    {
      'title': 'Standard Plan',
      'desc': 'Most Popular',
      'color': Colors.red
    },
    {
      'title': 'Advanced Plan',
      'desc': 'All Feature Unlocked',
      'color': Colors.green
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const NavbarPage(),
      drawer: const CustomNavbar(),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Center(
          child: Wrap(
            spacing: 16,
            runSpacing: 16,
            children: paymentPlans.map((item) {
              return _buildPlanCard(
                context: context,
                title: item['title'] as String,
                desc: item['desc'] as String,
                color: item['color'] as Color,
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  Widget _buildPlanCard({
    required BuildContext context,
    required String title,
    required String desc,
    required Color color,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () async {
          bool? confirmed = await showDialog(
            context: context,
            builder: (_) => AlertDialog(
              title: const Text("Confirm Payment"),
              content:
              Text("Do you want to proceed with the $title?"),
              actions: [
                TextButton(
                  child: const Text("Cancel"),
                  onPressed: () => Navigator.of(context).pop(false),
                ),
                ElevatedButton(
                  child: const Text("Confirm"),
                  onPressed: () => Navigator.of(context).pop(true),
                ),
              ],
            ),
          );

          if (confirmed == true && context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text("$title selected")),
            );
            await Future.delayed(const Duration(milliseconds: 300));
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const UploadContractPage()),
            );
          }
        },
        borderRadius: BorderRadius.circular(16),
        child: Container(
          width: 170,
          height: 160,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [color.withOpacity(0.2), color.withOpacity(0.05)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            border: Border.all(color: color, width: 2),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(0.2),
                blurRadius: 10,
                offset: const Offset(2, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.workspace_premium_outlined, color: color, size: 36),
              const SizedBox(height: 10),
              Text(
                title,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: color,
                ),
              ),
              const SizedBox(height: 4),
              Text(desc,
                  style:
                  const TextStyle(fontSize: 13, color: Colors.black54)),
            ],
          ),
        ),
      ),
    );
  }
}
