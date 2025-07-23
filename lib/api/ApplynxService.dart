

import 'dart:convert';
import 'package:http/http.dart' as http;

import '../constants/env.dart';

class ApiApplynxService {
  final String baseUrl = "https://services.leadconnectorhq.com";
  final String apiKey = "pit-283031da-ffca-40fc-8303-4b8400ce6dab";
  final String locationId = "cyI1tRyaF0oYq5jaPVOP";
  static const String pipelineId = 'B2abziQpwJBYSr4qzopT';

  Future<Map<String, dynamic>> upsertContact(Map<String, dynamic> contactData) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/contacts/upsert'),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $apiKey',
          'Content-Type': 'application/json',
          'Version': '2021-07-28',
        },
        body: jsonEncode(contactData),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to upsert contact. Status: ${response.statusCode}, Body: ${response.body}');
      }
    } catch (e) {
      throw Exception('Failed to upsert contact: $e');
    }
  }

  Future<Map<String, dynamic>> upsertOpportunity(Map<String, dynamic> opportunityData) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/opportunities/upsert'),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $apiKey',
          'Content-Type': 'application/json',
          'Version': '2021-07-28',
        },
        body: jsonEncode(opportunityData),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to upsert opportunity. Status: ${response.statusCode}, Body: ${response.body}');
      }
    } catch (e) {
      throw Exception('Failed to upsert opportunity: $e');
    }
  }


  Future<Map<String, dynamic>> updateContactCustomFields(
      String contactId, List<Map<String, dynamic>> customFields) async {
    final url = Uri.parse('$baseUrl/contacts/$contactId');
    final response = await http.put(
      url,
      headers: {
        'Authorization': 'Bearer $apiKey',
        'Content-Type': 'application/json',
        'Version': '2021-07-28',
      },
      body: jsonEncode({'customFields': customFields}),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to update contact custom fields');
    }
  }

  Future<Map<String, dynamic>> updateCustomValue(String newContractNumber) async {
    final url = Uri.parse('$baseUrl/locations/$locationId/customValues/lV6EY3V00K7rPNi3KdxB');
    final response = await http.put(
      url,
      headers: {
        'Authorization': 'Bearer $apiKey',
        'Content-Type': 'application/json',
        'Version': '2021-07-28',
        'Accept': 'application/json',
      },
      body: jsonEncode({
        'name': 'contract_contract_type',
        'value': 'Contract $newContractNumber'
      }),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to update custom value: ${response.statusCode} - ${response.body}');
    }
  }

  // Future<Map<String, dynamic>> getLastContractNumber() async {
  //   // final url = Uri.parse('https://localhost:44318/api/AIOcr/lastContractNumber');
  //   final url = Uri.parse('${Env.baseUrl}/AIOcr/lastContractNumber');
  //   final response = await http.get(url);
  //
  //   if (response.statusCode == 200) {
  //     return jsonDecode(response.body);
  //   } else {
  //     throw Exception('Failed to get last contract number');
  //   }
  // }
  Future<Map<String, dynamic>> getLastContractNumber() async {
    final url = Uri.parse('${Env.baseUrl}/AIOcr/lastContractNumber');
    final response = await http.get(url);

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      // Find the contract_contract_type in customValues list
      final contractEntry = (data['customValues'] as List).firstWhere(
            (item) => item['name'] == 'contract_contract_type',
        orElse: () => {'value': 'Contract 0000'},
      );
      return {'value': contractEntry['value']};
    } else {
      throw Exception('Failed to get last contract number');
    }
  }



  Future<Map<String, dynamic>> getTestData() async {
    final url = Uri.parse('https://localhost:44318/api/AIOcr/TestData');

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({}),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to fetch test data (Status: ${response.statusCode})');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

// Add to your ApiApplynxService class
  Future<Map<String, dynamic>> fetchOpportunityDates(String opportunityId) async {
    if (opportunityId.isEmpty) {
      throw Exception('Opportunity ID cannot be empty');
    }

    try {
      final response = await http.get(
        Uri.parse('$baseUrl/opportunities/$opportunityId'),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $apiKey',
          'Version': '2021-07-28',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        // Process the opportunity data
        final opportunity = data['opportunity'];
        final customFields = opportunity['customFields'] as List? ?? [];

        // Extract all dates from custom fields
        final dates = <String, String>{};
        for (final field in customFields) {
          if (field['fieldValue'] != null) {
            dates[field['id']] = field['fieldValue'].toString();
          }
        }

        // Extract contact information
        final contact = opportunity['contact'] ?? {};

        return {
          'dates': dates,
          'contact': contact,
          'opportunity': opportunity,
        };
      } else {
        throw Exception('Failed to load opportunity data: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to fetch opportunity details: $e');
    }
  }

}
