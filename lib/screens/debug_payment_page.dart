import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../service/user_session_service.dart';
import 'upload_contract_page.dart';
import '../api/payment_api.dart';
import '../models/userPaymentModel.dart';


final paymentStateProvider = StateNotifierProvider<PaymentNotifier, PaymentState>((ref) {
  return PaymentNotifier();
});

class PaymentState {
  final bool isProcessing;
  final int secondsLeft;
  final String? error;

  PaymentState({
    this.isProcessing = false,
    this.secondsLeft = 5,
    this.error,
  });
}

class PaymentNotifier extends StateNotifier<PaymentState> {
  PaymentNotifier() : super(PaymentState());

  Future<void> startPayment({
    required String upiId,
    required String planName,
    required BuildContext context,
  }) async {
    state = PaymentState(isProcessing: true, secondsLeft: 5);

    final userService = UserSessionService();
    final userId = userService.userId;

    if (userId == null) {
      state = PaymentState(error: "User not logged in");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("User not logged in")),
      );
      return;
    }

    final paymentModel = UserPaymentModel(
      userId: userId,
      planName: planName,
      paymentStatus: "Success",
      amount: 199.00,
      transactionId: "TXN${Random().nextInt(999999)}",
    );

    final success = await ApiService().submitUserPayment(paymentModel);

    if (!success) {
      state = PaymentState(error: "Payment failed");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Payment failed.")),
      );
      return;
    }

    Timer.periodic(const Duration(seconds: 1), (timer) {
      if (state.secondsLeft == 0) {
        timer.cancel();
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const UploadContractPage()),
        );
      } else {
        state = PaymentState(
          isProcessing: true,
          secondsLeft: state.secondsLeft - 1,
        );
      }
    });
  }
}


class DebugPaymentPage extends HookConsumerWidget {
  final String planName;
  const DebugPaymentPage({super.key, required this.planName});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final upiController = useTextEditingController();
    final state = ref.watch(paymentStateProvider);
    final notifier = ref.read(paymentStateProvider.notifier);

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
              elevation: 3,
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      "Pay for $planName",
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
                      controller: upiController,
                      decoration: InputDecoration(
                        labelText: "Enter your UPI ID",
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        filled: true,
                        fillColor: Colors.white,
                      ),
                      keyboardType: TextInputType.emailAddress,
                    ),
                    const SizedBox(height: 24),
                    state.isProcessing
                        ? Column(
                      children: [
                        const CircularProgressIndicator(color: Colors.deepPurple),
                        const SizedBox(height: 12),
                        Text(
                          "Processing in ${state.secondsLeft} sec...",
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
                        onPressed: () {
                          if (upiController.text.trim().isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Please enter a valid UPI ID')),
                            );
                            return;
                          }
                          notifier.startPayment(
                            upiId: upiController.text,
                            planName: planName,
                            context: context,
                          );
                        },
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