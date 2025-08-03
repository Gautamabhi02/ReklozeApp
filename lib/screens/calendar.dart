import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../widgets/custom_navbar.dart';
import '../widgets/navbar_page.dart';

class ContractAppointment {
  final DateTime effectiveDate;
  final String contractName;

  ContractAppointment({
    required this.effectiveDate,
    required this.contractName,
  });
}

class CalendarNotifier extends StateNotifier<List<ContractAppointment>> {

  CalendarNotifier():super([]){
    _loadAppointments();
  }

  List<ContractAppointment> _allAppointments = [];


  void _loadAppointments() {
    _allAppointments = [
      ContractAppointment(
        effectiveDate: DateTime(2025, 8, 1),
        contractName: 'Alpha Contract',
      ),
      ContractAppointment(
        effectiveDate: DateTime(2025, 8, 3),
        contractName: 'Beta Agreement',
      ),
      ContractAppointment(
        effectiveDate: DateTime(2025, 8, 5),
        contractName: 'Gamma Deal',
      ),
      ContractAppointment(
        effectiveDate: DateTime(2025, 8, 7),
        contractName: 'Alpha Contract',
      ),
      ContractAppointment(
        effectiveDate: DateTime(2025, 8, 10),
        contractName: 'Delta Transaction',
      ),
    ];
    state = _allAppointments;
  }

  void filterAppointments({String? contract, DateTime? date}) {
    state = _allAppointments.where((a) {
      final matchesContract = contract == null || a.contractName == contract;
      final matchesDate = date == null ||
          (a.effectiveDate.year == date.year &&
              a.effectiveDate.month == date.month &&
              a.effectiveDate.day == date.day);
      return matchesContract && matchesDate;
    }).toList();
  }

  void clearFilters() {
    state = _allAppointments;
  }
}

final calendarProvider =
StateNotifierProvider<CalendarNotifier, List<ContractAppointment>>((ref) {
  return CalendarNotifier();
});

final contractFilterProvider = StateProvider<String?>((ref) => null);
final dateFilterProvider = StateProvider<DateTime?>((ref) => null);

class CalendarPage extends ConsumerWidget {
  const CalendarPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appointments = ref.watch(calendarProvider);

    return Scaffold(
      appBar: const NavbarPage(),
      drawer: const CustomNavbar(),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '📅 Upcoming Contracts',
              style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),

            // Filters Section
            _buildFilterSection(context, ref),
            const SizedBox(height: 24),

            if (appointments.isEmpty)
              const Center(
                  child: Text(
                    'No contracts found for selected filters.',
                    style: TextStyle(fontSize: 16),
                  ))
            else
              ...appointments.map((a) => _buildCard(context, a)),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterSection(BuildContext context, WidgetRef ref) {
    final contractFilter = ref.watch(contractFilterProvider);
    final dateFilter = ref.watch(dateFilterProvider);

    final contractNames = [
      ...{
        for (var a in ref.read(calendarProvider.notifier)._allAppointments)
          a.contractName
      }
    ];

    final dateList = List.generate(
      10,
          (index) => DateTime(2025, 8, 1 + index),
    );

    return LayoutBuilder(builder: (context, constraints) {
      final isMobile = constraints.maxWidth < 500;

      return isMobile
          ? Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildDropdown(
            hint: 'Filter by Contract',
            value: contractFilter,
            items: contractNames,
            onChanged: (val) {
              ref.read(contractFilterProvider.notifier).state = val;
              ref
                  .read(calendarProvider.notifier)
                  .filterAppointments(contract: val, date: dateFilter);
            },
          ),
          const SizedBox(height: 12),
          _buildDateDropdown(
            hint: 'Filter by Date',
            value: dateFilter,
            dates: dateList,
            onChanged: (val) {
              ref.read(dateFilterProvider.notifier).state = val;
              ref
                  .read(calendarProvider.notifier)
                  .filterAppointments(contract: contractFilter, date: val);
            },
          ),
          const SizedBox(height: 12),
          ElevatedButton(
            onPressed: () {
              ref.read(contractFilterProvider.notifier).state = null;
              ref.read(dateFilterProvider.notifier).state = null;
              ref.read(calendarProvider.notifier).clearFilters();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.grey.shade300,
              foregroundColor: Colors.black,
            ),
            child: const Text('Clear'),
          ),
        ],
      )
          : Row(
        children: [
          Expanded(
            child: _buildDropdown(
              hint: 'Filter by Contract',
              value: contractFilter,
              items: contractNames,
              onChanged: (val) {
                ref.read(contractFilterProvider.notifier).state = val;
                ref.read(calendarProvider.notifier).filterAppointments(
                  contract: val,
                  date: dateFilter,
                );
              },
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildDateDropdown(
              hint: 'Filter by Date',
              value: dateFilter,
              dates: dateList,
              onChanged: (val) {
                ref.read(dateFilterProvider.notifier).state = val;
                ref.read(calendarProvider.notifier).filterAppointments(
                  contract: contractFilter,
                  date: val,
                );
              },
            ),
          ),
          const SizedBox(width: 12),
          ElevatedButton(
            onPressed: () {
              ref.read(contractFilterProvider.notifier).state = null;
              ref.read(dateFilterProvider.notifier).state = null;
              ref.read(calendarProvider.notifier).clearFilters();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.grey.shade300,
              foregroundColor: Colors.black,
            ),
            child: const Text('Clear'),
          ),
        ],
      );
    });
  }

  Widget _buildDropdown({
    required String hint,
    required String? value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    return DropdownButtonFormField<String>(
      isExpanded: true,
      value: value,
      hint: Text(hint),
      decoration: InputDecoration(
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
      items: items.map((name) {
        return DropdownMenuItem(value: name, child: Text(name));
      }).toList(),
      onChanged: onChanged,
    );
  }

  Widget _buildDateDropdown({
    required String hint,
    required DateTime? value,
    required List<DateTime> dates,
    required ValueChanged<DateTime?> onChanged,
  }) {
    return DropdownButtonFormField<DateTime>(
      isExpanded: true,
      value: value,
      hint: Text(hint),
      decoration: InputDecoration(
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
      items: dates.map((date) {
        return DropdownMenuItem(
          value: date,
          child: Text(DateFormat('dd MMM yyyy').format(date)),
        );
      }).toList(),
      onChanged: onChanged,
    );
  }

  Widget _buildCard(BuildContext context, ContractAppointment a) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.blue.shade100, Colors.blue.shade50],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            const Icon(Icons.insert_drive_file_rounded,
                size: 40, color: Colors.blue),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    a.contractName,
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Effective Date: ${DateFormat('dd MMM yyyy').format(a.effectiveDate)}',
                    style:
                    const TextStyle(fontSize: 14, color: Colors.black87),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
