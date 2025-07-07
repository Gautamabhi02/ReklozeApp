import 'package:flutter/material.dart';
import '../widgets/custom_navbar.dart';
import '../widgets/navbar_page.dart';
import '../screens/debug_payment_page.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  final List<Map<String, dynamic>> paymentPlans = const [
    {
      'title': 'Basic Plan',
      'desc': 'Essential features',
      'color': Colors.blue
    },
    {
      'title': 'Standard Plan',
      'desc': 'Most popular',
      'color': Colors.red
    },
    {
      'title': 'Advanced Plan',
      'desc': 'All features unlocked',
      'color': Colors.green
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const NavbarPage(),
      drawer: const CustomNavbar(),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 600),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Welcome to Rekloze!',
                    style: TextStyle(fontSize: 26, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    "Choose a payment plan to proceed.",
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                  const SizedBox(height: 24),
                  Wrap(
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
                  )
                ],
              ),
            ),
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
    return GestureDetector(
      onTap: () async {
        bool? confirmed = await showDialog(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text("Confirm Payment"),
            content: const Text("Are you sure you want to proceed with this plan?"),
            actions: [
              TextButton(
                child: const Text("No"),
                onPressed: () => Navigator.of(context).pop(false),
              ),
              ElevatedButton(
                child: const Text("Yes"),
                onPressed: () => Navigator.of(context).pop(true),
              ),
            ],
          ),
        );

        if (confirmed == true && context.mounted) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => DebugPaymentPage(planName: title),
            ),
          );
        }
      },
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
            Text(title,
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: color)),
            const SizedBox(height: 4),
            Text(desc,
                style: const TextStyle(fontSize: 13, color: Colors.black54)),
          ],
        ),
      ),
    );
  }
}
