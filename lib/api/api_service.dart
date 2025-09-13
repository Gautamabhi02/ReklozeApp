// lib/api/api_service.dart
import 'dart:convert';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import '../constants/env.dart';
import '../models/signup_model.dart';
import 'package:http_parser/http_parser.dart';
import '../models/userPaymentModel.dart';
import 'dart:typed_data';


class ApiService {
  Future<String?> signup(SignupModel model) async {
    final url = Uri.parse('${Env.baseUrl}/Login/signup');

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(model.toJson()),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return null; // Success - no error message
      } else {
        // Try to parse the error message from response body
        try {
          final errorMessage = jsonDecode(response.body) as String;
          return errorMessage;
        } catch (e) {
          // If parsing fails, return the raw response body
          return response.body.isNotEmpty
              ? response.body
              : 'Signup failed (${response.statusCode})';
        }
      }
    } catch (e) {
      return 'Network error: $e';
    }
  }
  Future<Map<String, dynamic>?> login(String username, String password) async {
    final url = Uri.parse('${Env.baseUrl}/Login/login');
    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          "UserName": username,
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
      }
      else if (response.statusCode == 401) {
        return {'error': 'Invalid credentials'};
      }
      else {
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
    try {
      Uint8List fileBytes;

      if (selectedFile.bytes != null) {
        fileBytes = selectedFile.bytes!;
      } else if (selectedFile.path != null) {
        fileBytes = await File(selectedFile.path!).readAsBytes();
      } else {
        throw Exception("No file bytes or path available.");
      }

      final uri = Uri.parse('${Env.baseUrl}/AIOcr/getTextfromChatgpt')
          .replace(queryParameters: {'prompt': promptText});

      var request = http.MultipartRequest('POST', uri);

      request.files.add(http.MultipartFile.fromBytes(
        'file',
        fileBytes,
        filename: selectedFile.name,
        contentType: MediaType('application', 'pdf'),
      ));

      var streamedResponse = await request.send();
      return await http.Response.fromStream(streamedResponse);
    } catch (e) {
      // debugPrint("Upload error: $e");
      return null;
    }
  }


  Future<bool> uploadContractImages(Map<String, dynamic> body) async {
    final url = Uri.parse('${Env.baseUrl}/ContractTimelineImage/upload');

    final headers = {
      'Content-Type': 'application/json',
    };

    final response = await http.post(
      url,
      headers: headers,
      body: jsonEncode(body),
    );

    return response.statusCode == 200;
  }

  Future<Map<String, dynamic>> getContractTimelineImages(int userId) async {
    final url = Uri.parse('${Env.baseUrl}/ContractTimelineImage/getContractTimelineImages/$userId');

    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to load images');
      }
    } catch (e) {
      throw Exception('Failed to fetch images: $e');
    }
  }
  Future<bool> saveContractTextBlocks({
    required int userId,
    required String introductionText,
    required String middleContentText,
    required String afterMilestoneText,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('${Env.baseUrl}/ContractTimelineImage/saveText'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'userId': userId,
          'introductionText': introductionText,
          'middleContentText': middleContentText,
          'afterMilestoneText': afterMilestoneText,
        }),
      );

      return response.statusCode == 200;
    } catch (e) {
      print('Error saving text blocks: $e');
      return false;
    }
  }

  Future<Map<String, String>?> getContractTextBlocks(int userId) async {
    try {
      final response = await http.get(
        Uri.parse('${Env.baseUrl}/ContractTimelineImage/getByUser/$userId'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true && data['data'] != null) {
          return {
            'introductionText': data['data']['introductionText'] ?? '',
            'middleContentText': data['data']['middleContentText'] ?? '',
            'afterMilestoneText': data['data']['afterMilestoneText'] ?? ''
          };
        }
      }
      return null;
    } catch (e) {
      print('Error fetching text blocks: $e');
      return null;
    }
  }

  static Future<http.Response?> saveOpportunity(
      String userId,
      String opportunityId,
      String opportunityName,
      Map<String, DateTime?> dateFields 
      ) async {
    try {
      final url = Uri.parse('${Env.baseUrl}/UserOpportunity/save');
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'userOppId': 0,
          'userId': int.tryParse(userId) ?? 0,
          'oppurtunityId': opportunityId,
          'oppurtunityName': opportunityName,
          // Add all date fields
          'effective_date': dateFields['Effective Date']?.toIso8601String(),
          'initial_escrow_deposit_due_date': dateFields['Initial Escrow Deposit Due Date']?.toIso8601String(),
          'loan_application_due_date': dateFields['Loan Application Due Date']?.toIso8601String(),
          'additional_escrow_deposit_due_date': dateFields['Additional Escrow Deposit Due Date']?.toIso8601String(),
          'inspection_period_deadline': dateFields['Inspection Period Deadline']?.toIso8601String(),
          'loan_approval_due_date': dateFields['Loan Approval Due Date']?.toIso8601String(),
          'title_evidence_due_date': dateFields['Title Evidence Due Date']?.toIso8601String(),
          'closing_date': dateFields['Closing Date']?.toIso8601String(),
        }),
      );
      return response;
    } catch (e) {
      print('Error saving opportunity: $e');
      return null;
    }

  }

  static Future<http.Response?> getOpportunitiesByUserId(String userId) async {
    try {
      final url = Uri.parse('${Env.baseUrl}/UserOpportunity/list?userId=$userId');
      final response = await http.get(
        url,
        headers: {'Content-Type': 'application/json'},
      );
      return response;
    } catch (e) {
      print('Error getting opportunities: $e');
      return null;
    }

  }

}



