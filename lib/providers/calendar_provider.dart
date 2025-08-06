import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/contract_date_note.dart';
import '../service/calendar_service.dart';


class CalendarNotifier extends StateNotifier<List<ContractDateNote>> {
  final CalendarService _service;

  CalendarNotifier(this._service) : super([]) {
    fetchOpportunityValue();
  }

  List<Map<String, String>> dropdownOptions = [];
  String selectedOptionValue = '';

  Future<void> fetchOpportunityValue() async {
    dropdownOptions = await _service.fetchOpportunityValue();
  }

  Future<void> fetchOpportunityDates(String opportunityId) async {
    final dates = await _service.fetchOpportunityDates(opportunityId);
    state = dates;
  }

  List<String> get contractNames => dropdownOptions.map((e) => e['label'] ?? '').toList();
}

final calendarServiceProvider = Provider<CalendarService>((ref) {
  return CalendarService();
});

final calendarProvider = StateNotifierProvider<CalendarNotifier, List<ContractDateNote>>((ref) {
  final service = ref.read(calendarServiceProvider);
  return CalendarNotifier(service);
});

final selectedContractProvider = StateProvider<String?>((ref) => null);