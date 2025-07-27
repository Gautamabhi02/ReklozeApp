import 'package:flutter/material.dart';
import '../widgets/contract_progress_bar.dart';
import '../widgets/custom_navbar.dart';
import '../widgets/navbar_page.dart';

class SubmitPage extends StatefulWidget {
  final bool isOpportunityCreated;
  final List<String>? processingErrors;

  const SubmitPage({
    super.key,
    required this.isOpportunityCreated,
    this.processingErrors,
  });

  @override
  State<SubmitPage> createState() => _SubmitPageState();
}

class _SubmitPageState extends State<SubmitPage> {
  int _countdown = 4;
  bool _showCountdown = false;

  @override
  void initState() {
    super.initState();
    // Start countdown after a brief delay to let the page render
    Future.delayed(const Duration(seconds: 1), () {
      if (mounted) {
        setState(() {
          _showCountdown = true;
        });
        _startCountdown();
      }
    });
  }

  void _startCountdown() {
    Future.delayed(const Duration(seconds: 1), () {
      if (!mounted) return;

      setState(() {
        _countdown--;
      });

      if (_countdown > 0) {
        _startCountdown();
      } else {
        // Navigate to editContractTimeline page when countdown reaches 0
        Navigator.pushNamedAndRemoveUntil(
          context,
          '/editContractTimeline',
          (route) => false,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 600;
    final successColor = Colors.green;
    final errorColor = Colors.red;

    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: Colors.white,
      appBar: const NavbarPage(),
      drawer: const CustomNavbar(),
      body: SafeArea(
        bottom: true,
        minimum: const EdgeInsets.only(bottom: 24),
        child: Stack(
          children: [
            Container(
              width: double.infinity,
              height: double.infinity,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFFE3F2FD), Color(0xFFF3E5F5)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Column(
                children: [
                  // Progress bar at the top
                  const ContractProgressBar(currentStep: 3),

                  // Centered content
                  Expanded(
                    child: SingleChildScrollView(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                widget.isOpportunityCreated
                                    ? Icons.check_circle
                                    : Icons.error,
                                color:
                                    widget.isOpportunityCreated
                                        ? successColor
                                        : errorColor,
                                size: 60,
                              ),
                              const SizedBox(height: 20),
                              Text(
                                widget.isOpportunityCreated
                                    ? 'Transaction Completed Successfully!'
                                    : 'Transaction Not Fully Completed',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color:
                                      widget.isOpportunityCreated
                                          ? successColor
                                          : errorColor,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              if (!widget.isOpportunityCreated) ...[
                                const SizedBox(height: 10),
                                const Text(
                                  'Opportunity was not created',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.black54,
                                  ),
                                ),
                              ],
                              if (widget.processingErrors != null &&
                                  widget.processingErrors!.isNotEmpty) ...[
                                const SizedBox(height: 20),
                                const Text(
                                  'Errors occurred:',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 10),
                                SizedBox(
                                  height: 100,
                                  child: ListView.builder(
                                    itemCount: widget.processingErrors!.length,
                                    itemBuilder: (context, index) {
                                      return Padding(
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 4.0,
                                        ),
                                        child: Text(
                                          '• ${widget.processingErrors![index]}',
                                          style: const TextStyle(
                                            color: Colors.red,
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              ],
                              const SizedBox(height: 40),
                              ElevatedButton.icon(
                                onPressed: () {
                                  Navigator.pushNamedAndRemoveUntil(
                                    context,
                                    '/contract',
                                    (route) => false,
                                  );
                                },
                                icon: const Icon(Icons.home),
                                label: const Text('Return Home'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.white,
                                  foregroundColor: Colors.blue[800],
                                  elevation: 3,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 24,
                                    vertical: 12,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(30),
                                    side: const BorderSide(color: Colors.blue),
                                  ),
                                  textStyle: TextStyle(
                                    fontSize: isMobile ? 14 : 16,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            if (_showCountdown)
              Center(
                child: Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.7),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Center(
                    child: Text(
                      '$_countdown',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 48,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
