import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';
import '../widgets/custom_navbar.dart';
import '../widgets/navbar_page.dart';

// ---------------------- MODEL ----------------------
class ContractDateNote {
  final DateTime date;
  final String note;

  ContractDateNote({required this.date, required this.note});
}

// ---------------------- NOTIFIER ----------------------
class CalendarNotifier extends StateNotifier<List<ContractDateNote>> {
  CalendarNotifier() : super([]) {
    _loadContracts();
  }

  final Map<String, List<ContractDateNote>> _contractMap = {};

  void _loadContracts() {
    _contractMap.addAll({
      'Contract #001': [
        ContractDateNote(date: DateTime(2025, 7, 2), note: '📜 Effective Date'),
        ContractDateNote(date: DateTime(2025, 7, 5), note: '💼 Escrow Date'),
        ContractDateNote(date: DateTime(2025, 7, 10), note: '🏦 Loan Approval'),
      ],
      'Contract #002': [
        ContractDateNote(date: DateTime(2025, 7, 4), note: '📜 Effective Date'),
        ContractDateNote(date: DateTime(2025, 7, 6), note: '🏡 Site Visit'),
      ],
      'Contract #003': [
        ContractDateNote(date: DateTime(2025, 7, 8), note: '📜 Effective Date'),
      ],
    });
    state = [];
  }

  void filterByContract(String? contractId) {
    state = _contractMap[contractId] ?? [];
  }

  List<String> get contractNames => _contractMap.keys.toList();
}

// ---------------------- PROVIDERS ----------------------
final calendarProvider =
StateNotifierProvider<CalendarNotifier, List<ContractDateNote>>((ref) {
  return CalendarNotifier();
});
final selectedContractProvider = StateProvider<String?>((ref) => null);

// ---------------------- MAIN WIDGET ----------------------
class CalendarPage extends ConsumerStatefulWidget {
  const CalendarPage({super.key});

  @override
  ConsumerState<CalendarPage> createState() => _CalendarPageState();
}

class _CalendarPageState extends ConsumerState<CalendarPage> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  @override
  Widget build(BuildContext context) {
    final appointments = ref.watch(calendarProvider);
    final selectedContract = ref.watch(selectedContractProvider);
    final contractList = ref.read(calendarProvider.notifier).contractNames;

    if (appointments.isNotEmpty) {
      _focusedDay = appointments
          .map((e) => e.date)
          .reduce((a, b) => a.isBefore(b) ? a : b);
    }

    final Map<DateTime, List<ContractDateNote>> groupedDates = {};
    for (var note in appointments) {
      final day = DateTime(note.date.year, note.date.month, note.date.day);
      groupedDates.putIfAbsent(day, () => []).add(note);
    }

    return Scaffold(
      appBar: const NavbarPage(),
      drawer: const CustomNavbar(),
      backgroundColor: const Color(0xFFF5F7FA),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // -------------------- CONTRACT DROPDOWN --------------------
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade300),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: DropdownButtonFormField<String>(
                value: selectedContract,
                isExpanded: true,
                decoration: const InputDecoration(
                  contentPadding: EdgeInsets.symmetric(vertical: 18),
                  border: InputBorder.none,
                ),
                hint: const Text(
                  '🔍 Select Contract',
                  style: TextStyle(fontSize: 16),
                ),
                items: contractList
                    .map((name) =>
                    DropdownMenuItem(value: name, child: Text(name)))
                    .toList(),
                onChanged: (val) {
                  ref.read(selectedContractProvider.notifier).state = val;
                  ref.read(calendarProvider.notifier).filterByContract(val);
                },
              ),
            ),
            const SizedBox(height: 20),

            // -------------------- MAIN LAYOUT --------------------
            Expanded(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // -------------------- CALENDAR --------------------
                  Container(
                    width: 300,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    padding: const EdgeInsets.all(8),
                    child: TableCalendar(
                      firstDay: DateTime(2020),
                      lastDay: DateTime(2030),
                      focusedDay: _focusedDay,
                      calendarFormat: CalendarFormat.month,
                      selectedDayPredicate: (d) => isSameDay(d, _selectedDay),
                      eventLoader: (day) {
                        return appointments
                            .where((e) => isSameDay(e.date, day))
                            .toList();
                      },
                      onDaySelected: (selected, focused) {
                        setState(() {
                          _selectedDay = selected;
                          _focusedDay = focused;
                        });
                      },
                      headerStyle: const HeaderStyle(
                        formatButtonVisible: false,
                        titleCentered: true,
                        titleTextStyle: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: Colors.black87,
                        ),
                      ),
                      calendarStyle: CalendarStyle(
                        todayDecoration: BoxDecoration(
                          color: Colors.blue.shade400,
                          shape: BoxShape.circle,
                        ),
                        selectedDecoration: const BoxDecoration(
                          color: Colors.orange,
                          shape: BoxShape.circle,
                        ),
                        markerDecoration: BoxDecoration(
                          color: Colors.deepPurpleAccent.shade100,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(width: 20),

                  // -------------------- EVENT LIST --------------------
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: groupedDates.isEmpty
                          ? const Center(
                        child: Text(
                          "😕 No events found for this contract",
                          style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500),
                        ),
                      )
                          : ListView.builder(
                        itemCount: groupedDates.length,
                        itemBuilder: (context, index) {
                          final date = groupedDates.keys.elementAt(index);
                          final notes = groupedDates[date]!;

                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                    vertical: 10),
                                child: Text(
                                  DateFormat('EEEE, MMM d, yyyy')
                                      .format(date),
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF333C4D),
                                  ),
                                ),
                              ),
                              ...notes.map(
                                    (e) => Container(
                                  margin: const EdgeInsets.only(bottom: 8),
                                  padding: const EdgeInsets.symmetric(
                                      vertical: 10, horizontal: 12),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    border: Border(
                                      left: BorderSide(
                                        color: Colors.indigo,
                                        width: 4,
                                      ),
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(Icons.event_note,
                                          color: Colors.indigo, size: 20),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: Text(
                                          e.note,
                                          style: const TextStyle(
                                              fontSize: 15,
                                              color: Color(0xFF212121)),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              const Divider(
                                  height: 24, thickness: 0.5),
                            ],
                          );
                        },
                      ),
                    ),
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
