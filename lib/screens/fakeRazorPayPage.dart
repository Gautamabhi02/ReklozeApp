import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../service/user_session_service.dart';
import 'upload_contract_page.dart';
import '../api/payment_api.dart';
import '../models/userPaymentModel.dart';


class FakeRazorPayPage extends StatefulWidget {
  final String planName;
  const FakeRazorPayPage({super.key, required this.planName});

  @override
  State<FakeRazorPayPage> createState() => _FakeRazorPayPageState();
}

class _FakeRazorPayPageState extends State<FakeRazorPayPage> {
  final TextEditingController _upiController = TextEditingController();
  bool isProcessing = false;
  int secondsLeft = 5;
  Timer? _timer;

  Future<void> _startPayment() async {
    if (_upiController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid UPI ID')),
      );
      return;
    }

    setState(() => isProcessing = true);

    // SharedPreferences prefs = await SharedPreferences.getInstance();
    // int? userId = prefs.getInt('userId');

    var userService = UserSessionService();
    int? userId = userService.userId;
    print(userService.userId);
    print(userService.username);
    print(userService.email);
    print(userService.isActive);

    if (userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("User not logged in")),
      );
      return;
    }
    double amount = 199.00;
    String transactionId = "TXN${Random().nextInt(999999)}";

    UserPaymentModel paymentModel = UserPaymentModel(
      userId: userId,
      planName: widget.planName,
      paymentStatus: "Success",
      amount: amount,
      transactionId: transactionId,
    );

    // ✅ Call API
    bool success = await ApiService().submitUserPayment(paymentModel);

    if (success) {
      _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (secondsLeft == 0) {
          timer.cancel();
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const UploadContractPage()),
          );
        } else {
          setState(() {
            secondsLeft--;
          });
        }
      });
    } else {
      setState(() => isProcessing = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Payment failed.")),
      );
    }

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (secondsLeft == 0) {
        timer.cancel();
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const UploadContractPage()),
        );
      } else {
        setState(() {
          secondsLeft--;
        });
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _upiController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: const Text("RazorPay"),
        backgroundColor: Colors.indigo,
        centerTitle: true,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 500),
            child: Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              elevation: 3, // lowered elevation
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      "Pay for ${widget.planName}",
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.deepPurple,
                      ),
                    ),
                    const SizedBox(height: 16),
                    QrImageView(
                      data: "upi://pay?pa=upi-id@bank&pn=Rekloze&am=199&cu=INR",
                      version: QrVersions.auto,
                      size: 200,
                      backgroundColor: Colors.white,
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      "or enter UPI ID below",
                      style: TextStyle(color: Colors.grey),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: _upiController,
                      decoration: InputDecoration(
                        labelText: "Enter your UPI ID",
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        filled: true,
                        fillColor: Colors.white,
                      ),
                      keyboardType: TextInputType.emailAddress,
                    ),
                    const SizedBox(height: 24),
                    isProcessing
                        ? Column(
                      children: [
                        const CircularProgressIndicator(color: Colors.deepPurple),
                        const SizedBox(height: 12),
                        Text(
                          "Processing in $secondsLeft sec...",
                          style: const TextStyle(color: Colors.black54),
                        ),
                      ],
                    )
                        : SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.payment_rounded, color: Colors.black),
                        label: const Text(
                          "Pay Now",
                          style: TextStyle(
                            color: Colors.black,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        onPressed: _startPayment,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          backgroundColor: Colors.deepPurple.shade400,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
