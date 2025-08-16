import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/contract_date_note.dart';
import '../service/calendar_service.dart';

class CalendarNotifier extends StateNotifier<List<ContractDateNote>> {
  final CalendarService _service;
  List<Map<String, String>> dropdownOptions = [];
  bool isLoading = true;
  bool _contractsLoaded = false;
  String? error;

  CalendarNotifier(this._service) : super([]) {
    _init();
  }

  Future<void> _init() async {
    await fetchOpportunityValue();
  }

  Future<void> fetchOpportunityValue() async {
    try {
      isLoading = true;
      if (!_contractsLoaded) {
        isLoading = true;
      }
      error = null;
      state = []; // Clear existing events

      // Force fresh data fetch
      dropdownOptions = await _service.fetchOpportunityValue();
      print("Dropdown options after fetch: ${dropdownOptions.length}");

      if (dropdownOptions.isEmpty) {
        error = 'No contracts found for this user';
      }
      _contractsLoaded = true;
    } catch (e) {
      error = 'Failed to load contracts';
      dropdownOptions = [];
    } finally {
      isLoading = false;
    }
  }

  Future<void> fetchOpportunityDates(String opportunityId) async {
    try {
      isLoading = true;
      final dates = await _service.fetchOpportunityDates(opportunityId);
      state = dates;
      error = null;
    } catch (e) {
      error = 'Failed to load contract dates';
      state = [];
    } finally {
      isLoading = false;
    }
  }

  List<String> get contractNames => dropdownOptions
      .map((e) => e['label'] ?? '')
      .where((label) => label.isNotEmpty)
      .toList();
}

// Providers should be defined outside the class
final calendarServiceProvider = Provider<CalendarService>((ref) {
  return CalendarService();
});

final calendarProvider = StateNotifierProvider<CalendarNotifier, List<ContractDateNote>>((ref) {
  final service = ref.read(calendarServiceProvider);
  return CalendarNotifier(service);
});

final selectedContractProvider = StateProvider<String?>((ref) => null);

final calendarLoadingProvider = Provider<bool>((ref) {
  return ref.watch(calendarProvider.notifier).isLoading;
});

final calendarErrorProvider = Provider<String?>((ref) {
  return ref.watch(calendarProvider.notifier).error;
});