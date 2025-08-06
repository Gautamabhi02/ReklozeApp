import 'package:http/http.dart' as http;
import 'dart:convert';
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
    const apiUrl = 'https://services.leadconnectorhq.com/contacts/?locationId=cyI1tRyaF0oYq5jaPVOP';
    final headers = {
      'Accept': 'application/json',
      'Authorization': 'Bearer $apiToken',
      'Version': '2021-07-28',
    };

    try {
      final response = await http.get(Uri.parse(apiUrl), headers: headers);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final contacts = data['contacts'] as List? ?? [];

        return contacts.map((contact) {
          try {
            final fields = (contact['customFields'] as List? ?? [])
                .whereType<Map<String, dynamic>>()
                .toList();

            if (fields.length >= 2) {
              return {
                'value': fields[0]['value']?.toString() ?? '',
                'label': fields[1]['value']?.toString() ?? '',
              };
            }
          } catch (e) {
            print('Error processing contact: $e');
          }
          return {'value': '', 'label': ''};
        }).where((item) => item['value']?.isNotEmpty ?? false).toList();
      }
      return [];
    } catch (error) {
      print('Error fetching dropdown data: $error');
      return [];
    }
  }

  Future<List<ContractDateNote>> fetchOpportunityDates(String opportunityId) async {
    if (opportunityId.isEmpty) return [];

    final apiUrl = 'https://services.leadconnectorhq.com/opportunities/$opportunityId';
    final headers = {
      'Accept': 'application/json',
      'Authorization': 'Bearer $apiToken',
      'Version': '2021-07-28',
    };

    try {
      final response = await http.get(Uri.parse(apiUrl), headers: headers);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final fields = data['opportunity']['customFields'] as List? ?? [];

        final List<ContractDateNote> dates = [];

        for (final field in fields) {
          final fieldId = field['id']?.toString() ?? '';
          final fieldValue = field['fieldValue']?.toString() ?? '';

          final milestoneLabel = dateMapping[fieldId];
          if (milestoneLabel != null && fieldValue.isNotEmpty) {
            try {
              final date = DateTime.parse(fieldValue);
              dates.add(ContractDateNote(date: date, note: milestoneLabel));
            } catch (e) {
              print('Error parsing date $fieldValue: $e');
            }
          }
        }

        return dates;
      }
      return [];
    } catch (error) {
      print('Error fetching opportunity details: $error');
      return [];
    }
  }
}