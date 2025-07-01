// lib/api/api_service.dart
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../constants/env.dart';
import '../models/userPaymentModel.dart';


class ApiService {
  Future<bool> submitUserPayment(UserPaymentModel model) async {
    final url = Uri.parse('${Env.baseUrl}/payment');

    try {
      print("Sending payment data: ${model.toJson()}");

      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(model.toJson()),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return true;
      } else {
        print('Payment submission failed: ${response.body}');
        return false;
      }
    } catch (e) {
      print('Payment API error: $e');
      return false;
    }
  }

}
