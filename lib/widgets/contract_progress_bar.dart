import 'package:flutter/material.dart';

class ContractProgressBar extends StatelessWidget {
  final int currentStep; // 0 = initial state, 1 = upload, 2 = review, 3 = submit

  const ContractProgressBar({
    super.key,
    required this.currentStep,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildStep(1, "Upload", currentStep > 0),
              _buildStep(2, "Review", currentStep > 1),
              _buildStep(3, "Submit", currentStep > 2),
            ],
          ),
          const SizedBox(height: 8),
          Stack(
            children: [
              Container(
                height: 6,
                width: double.infinity,
                color: Colors.grey[200],
              ),
              FractionallySizedBox(
                widthFactor: {
                  0: 0.0,
                  1: 0.03,
                  2: 0.50,
                  3: 1.0,
                }[currentStep] ?? 0.0,
                child: Container(
                  height: 6,
                  color: Colors.lightGreen,
                ),
              ),
            ],
          ),

        ],
      ),
    );
  }

  Widget _buildStep(int stepNumber, String label, bool isActive) {
    return Column(
      children: [
        Container(
          width: 30,
          height: 30,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isActive ? Colors.lightGreen : Colors.grey[400],
          ),
          child: Center(
            child: Text(
              stepNumber.toString(),
              style: TextStyle(
                color: isActive ? Colors.white : Colors.grey[600],
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            color: isActive ? Colors.lightGreen : Colors.grey[600],
            fontWeight: FontWeight.normal,
          ),
        ),
      ],
    );
  }
}