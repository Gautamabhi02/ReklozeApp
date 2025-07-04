// lib/api/api_service.dart
import 'dart:convert';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import '../constants/env.dart';
import '../models/signup_model.dart';
import '../models/userPaymentModel.dart';


class ApiService {
  Future<bool> signup(SignupModel model) async {
    final url = Uri.parse('${Env.baseUrl}/Login/signup');

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(model.toJson()),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return true;
      } else {
        print('Signup failed: ${response.body}');
        return false;
      }
    } catch (e) {
      print('Error: $e');
      return false;
    }
  }
  Future<Map<String, dynamic>?> login(String username, String password) async {
    final url = Uri.parse('${Env.baseUrl}/Login/login');
    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          "Name": username,
          "password": password,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data is Map<String, dynamic>) {
          print('my result is:${data}');
          return data;
        }
        return null;
      } else {
        print('Login Failed: ${response.body}');
        return null;
      }
    } catch (e) {
      print('Login Exception: $e');
      return null;
    }
  }

    // static const String _baseUrl = 'https://localhost:44318/api/AIOcr/getTextfromChatgpt';
  static String get _baseUrl => '${Env.baseUrl}/AIOcr/getTextfromChatgpt';

    static Future<http.Response?> uploadContractWithPrompt({
      required PlatformFile selectedFile,
      required String promptText,
    }) async {
      final uri = Uri.parse("$_baseUrl?prompt=${Uri.encodeComponent(promptText)}");

      final request = http.MultipartRequest("POST", uri);

      // Web-compatible: use file.bytes
      if (selectedFile.bytes == null) return null;

      request.files.add(
        http.MultipartFile.fromBytes(
          'file',
          selectedFile.bytes!,
          filename: selectedFile.name,
          contentType: MediaType('application', 'pdf'),
        ),
      );

      try {
        final streamedResponse = await request.send();
        final response = await http.Response.fromStream(streamedResponse);
        return response;
      } catch (e) {
        print("Upload error: $e");
        return null;
      }
    }


}
