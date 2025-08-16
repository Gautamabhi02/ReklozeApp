import 'package:http/http.dart' as http;
import 'package:rekloze/service/user_session_service.dart';
import 'dart:convert';
import '../api/api_service.dart';
import '../models/contract_date_note.dart';

class CalendarService {
  final String apiToken = 'pit-283031da-ffca-40fc-8303-4b8400ce6dab';
  final String locationID = 'cyI1tRyaF0oYq5jaPVOP';

  // Date mapping
  final Map<String, String> dateMapping = {
    'UQOtoJHeY1ikdNMOtOP8': 'Effective Contract Date',
    'lNjUhxgyjvPE93VOom0D': 'Initial escrow deposit Due Date',
    'q8rFDRTqcCN8HuTUnVvr': 'Loan Application Due Date',
    'dihbH6mRnD9Nn55HbJw7': 'Additional Escrow Deposit Due Date',
    'Z6d5wDjRcZndCWb4ivvS': 'Inspection Period Ends',
    'AKOW6LsV6AzD1ckux7e5': 'Loan Approval Period Ends',
    'N9kjRvTu52WE2sL2BPmQ': 'Title Evidence Due Date',
    '64mrgnBSraTKciXBaPzf': 'Closing Date',
  };


  Future<List<Map<String, String>>> fetchOpportunityValue() async {
    final userId = UserSessionService().userId;
    if (userId == null) return [];

    try {
      // 1. Get user's saved opportunities from your API
      final userOppsResponse = await ApiService.getOpportunitiesByUserId(userId.toString());
      if (userOppsResponse == null || userOppsResponse.statusCode != 200) {
        return [];
      }

      // 2. Parse response
      final responseBody = json.decode(userOppsResponse.body);
      if (responseBody is List && responseBody.isEmpty) {
        return [];
      }
      if (responseBody is Map &&
          (responseBody['data'] == null ||
              (responseBody['data'] is List && responseBody['data'].isEmpty))) {
        return [];
      }
      List<dynamic> userOppsData = [];

      if (responseBody is List) {
        userOppsData = responseBody;
      } else if (responseBody is Map && responseBody.containsKey('data')) {
        userOppsData = responseBody['data'] is List ? responseBody['data'] : [];
      }

      // 3. Extract user's opportunity IDs
      final userOppIds = userOppsData
          .where((item) => item is Map && item['oppurtunityId'] != null)
          .map((item) => item['oppurtunityId'].toString())
          .toSet();

      if (userOppIds.isEmpty) return [];

      // 4. Fetch all contacts from GHL
      final ghlResponse = await http.get(
        Uri.parse('https://services.leadconnectorhq.com/contacts/?locationId=$locationID'),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $apiToken',
          'Version': '2021-07-28',
        },
      );

      if (ghlResponse.statusCode != 200) return [];

      final ghlData = json.decode(ghlResponse.body);
      final contacts = ghlData['contacts'] as List? ?? [];

      // 5. Filter and map to dropdown options
      return contacts
          .where((contact) {
        final fields = (contact['customFields'] as List? ?? [])
            .whereType<Map<String, dynamic>>()
            .toList();

        if (fields.length >= 2) {
          final oppId = fields[0]['value']?.toString() ?? '';
          return userOppIds.contains(oppId);
        }
        return false;
      })
          .map<Map<String, String>>((contact) {
        final fields = (contact['customFields'] as List? ?? [])
            .whereType<Map<String, dynamic>>()
            .toList();

        return {
          'value': fields[0]['value']?.toString() ?? '',
          'label': fields[1]['value']?.toString() ?? 'Unnamed Contract',
        };
      })
          .toList();
    } catch (error) {
      print('Error fetching opportunities: $error');
      return [];
    }
  }

  Future<List<ContractDateNote>> fetchOpportunityDates(String opportunityId) async {
    try {
      final response = await http.get(
        Uri.parse('https://services.leadconnectorhq.com/opportunities/$opportunityId'),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $apiToken',
          'Version': '2021-07-28',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final fields = data['opportunity']['customFields'] as List? ?? [];

        return fields
            .where((field) {
          final fieldId = field['id']?.toString() ?? '';
          final fieldValue = field['fieldValue']?.toString() ?? '';
          return dateMapping.containsKey(fieldId) && fieldValue.isNotEmpty;
        })
            .map((field) {
          final fieldId = field['id']?.toString() ?? '';
          return ContractDateNote(
            date: DateTime.parse(field['fieldValue']),
            note: dateMapping[fieldId]!,
          );
        })
            .toList();
      }
      return [];
    } catch (error) {
      print('Error fetching opportunity dates: $error');
      return [];
    }
  }
}