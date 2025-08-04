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
        ContractDateNote(date: DateTime(2025, 7, 2), note: 'Effective Date'),
        ContractDateNote(date: DateTime(2025, 7, 5), note: 'Escrow Date'),
        ContractDateNote(date: DateTime(2025, 7, 10), note: 'Loan Approval'),
        ContractDateNote(date: DateTime(2025, 7, 15), note: 'Inspection'),
        ContractDateNote(date: DateTime(2025, 7, 20), note: 'Closing Date'),
      ],
      'Contract #002': [
        ContractDateNote(date: DateTime(2025, 7, 4), note: 'Effective Date'),
        ContractDateNote(date: DateTime(2025, 7, 6), note: 'Closing Date'),
        ContractDateNote(date: DateTime(2025, 7, 12), note: 'Loan Approval'),
      ],
      'Contract #003': [
        ContractDateNote(date: DateTime(2025, 7, 8), note: 'Effective Date'),
        ContractDateNote(
          date: DateTime(2025, 7, 18),
          note: 'Escrow Date',
        ),
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
  CalendarFormat _calendarFormat = CalendarFormat.month;
  String? _hoveredNote;

  // Colors for different note types
  final Map<String, Color> _noteColors = {
    'Effective Date': Colors.blue.shade400,
    'Escrow Date': Colors.purple.shade400,
    'Loan Approval': Colors.green.shade400,
    'Inspection': Colors.orange.shade400,
    'Closing Date': Colors.red.shade400,
    'Site Visit': Colors.teal.shade400,
    'Permit Approval': Colors.indigo.shade400,
    'Final Walkthrough': Colors.amber.shade600,
  };

  Color _getNoteColor(String note) {
    return _noteColors[note] ?? Colors.grey.shade400;
  }

  @override
  Widget build(BuildContext context) {
    final appointments = ref.watch(calendarProvider);
    final selectedContract = ref.watch(selectedContractProvider);
    final contractList = ref.read(calendarProvider.notifier).contractNames;
    final isMobile = MediaQuery.of(context).size.width < 768;

    if (appointments.isNotEmpty && _selectedDay == null) {
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
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(isMobile ? 8 : 16),
          child: Column(
            children: [
              // Contract Dropdown
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade300),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.1),
                      spreadRadius: 2,
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: DropdownButtonFormField<String>(
                  value: selectedContract,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    contentPadding: EdgeInsets.symmetric(vertical: 12),
                    border: InputBorder.none,
                  ),
                  hint: const Text('🔍 Select Contract'),
                  items: contractList
                      .map(
                        (name) => DropdownMenuItem(
                      value: name,
                      child: Text(
                        name,
                        style: TextStyle(fontSize: isMobile ? 14 : 16),
                      ),
                    ),
                  )
                      .toList(),
                  onChanged: (val) {
                    ref.read(selectedContractProvider.notifier).state = val;
                    ref.read(calendarProvider.notifier).filterByContract(val);
                  },
                ),
              ),
              const SizedBox(height: 16),

              // Main Layout
              Expanded(
                child: isMobile
                    ? _buildMobileLayout(groupedDates)
                    : _buildDesktopLayout(groupedDates),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDesktopLayout(Map<DateTime, List<ContractDateNote>> groupedDates) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Calendar (Left Side)
        Flexible(
          flex: 2,
          child: Container(
            height: double.infinity,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey.shade300),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.1),
                  spreadRadius: 2,
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            padding: const EdgeInsets.all(12),
            child: TableCalendar(
              firstDay: DateTime(2020),
              lastDay: DateTime(2030),
              focusedDay: _focusedDay,
              calendarFormat: _calendarFormat,
              selectedDayPredicate: (d) => isSameDay(d, _selectedDay),
              eventLoader: (day) {
                return ref
                    .watch(calendarProvider)
                    .where((e) => isSameDay(e.date, day))
                    .toList();
              },
              onDaySelected: (selected, focused) {
                setState(() {
                  _selectedDay = selected;
                  _focusedDay = focused;
                });
              },
              onFormatChanged: (format) {
                setState(() {
                  _calendarFormat = format;
                });
              },
              headerStyle: HeaderStyle(
                formatButtonVisible: true,
                titleCentered: true,
                formatButtonDecoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                formatButtonTextStyle: TextStyle(color: Colors.blue.shade700),
                titleTextStyle: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: Colors.black87,
                ),
                leftChevronIcon: Icon(
                  Icons.chevron_left,
                  color: Colors.blue.shade700,
                ),
                rightChevronIcon: Icon(
                  Icons.chevron_right,
                  color: Colors.blue.shade700,
                ),
              ),
              calendarStyle: CalendarStyle(
                todayDecoration: BoxDecoration(
                  color: Colors.blue.shade100,
                  shape: BoxShape.circle,
                ),
                selectedDecoration: BoxDecoration(
                  color: Colors.blue.shade400,
                  shape: BoxShape.circle,
                ),
                weekendTextStyle: const TextStyle(color: Colors.black),
                holidayTextStyle: const TextStyle(color: Colors.black),
                defaultTextStyle: const TextStyle(color: Colors.black),
                outsideTextStyle: TextStyle(color: Colors.grey.shade400),
              ),
              calendarBuilders: CalendarBuilders(
                defaultBuilder: (context, day, focusedDay) {
                  return _buildCalendarDayCell(day, focusedDay, false);
                },
                todayBuilder: (context, day, focusedDay) {
                  return _buildCalendarDayCell(day, focusedDay, true);
                },
                selectedBuilder: (context, day, focusedDay) {
                  return _buildCalendarDayCell(day, focusedDay, false, true);
                },
              ),
            ),
          ),
        ),

        const SizedBox(width: 20),

        // Event List (Right Side)
        Flexible(flex: 3, child: _buildEventList(groupedDates)),
      ],
    );
  }

  Widget _buildMobileLayout(Map<DateTime, List<ContractDateNote>> groupedDates) {
    return Column(
      children: [
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.shade300),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.1),
                spreadRadius: 2,
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          padding: const EdgeInsets.all(8),
          child: TableCalendar(
            firstDay: DateTime(2020),
            lastDay: DateTime(2030),
            focusedDay: _focusedDay,
            calendarFormat: _calendarFormat,
            availableCalendarFormats: const {
              CalendarFormat.month: 'Month',
              CalendarFormat.week: 'Week',
            },
            daysOfWeekHeight: 32,
            rowHeight: 48,
            headerVisible: true,
            headerStyle: HeaderStyle(
              titleCentered: true,
              titleTextStyle: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
              formatButtonVisible: true,
              formatButtonShowsNext: false,
              formatButtonDecoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              formatButtonTextStyle: TextStyle(
                color: Colors.blue.shade700,
                fontSize: 12,
              ),
              leftChevronIcon: Icon(
                Icons.chevron_left,
                size: 20,
                color: Colors.blue.shade700,
              ),
              rightChevronIcon: Icon(
                Icons.chevron_right,
                size: 20,
                color: Colors.blue.shade700,
              ),
            ),
            calendarStyle: CalendarStyle(
              todayDecoration: BoxDecoration(
                color: Colors.blue.shade100,
                shape: BoxShape.circle,
              ),
              selectedDecoration: BoxDecoration(
                color: Colors.blue.shade400,
                shape: BoxShape.circle,
              ),
              defaultTextStyle: const TextStyle(fontSize: 14),
              weekendTextStyle: const TextStyle(color: Colors.black),
              holidayTextStyle: const TextStyle(color: Colors.black),
              outsideTextStyle: TextStyle(color: Colors.grey.shade400),
              cellMargin: const EdgeInsets.all(2),
              cellPadding: const EdgeInsets.all(4),
            ),
            daysOfWeekStyle: DaysOfWeekStyle(
              weekdayStyle: const TextStyle(fontSize: 12),
              weekendStyle: const TextStyle(fontSize: 12),
            ),
            selectedDayPredicate: (d) => isSameDay(d, _selectedDay),
            eventLoader: (day) {
              return ref
                  .watch(calendarProvider)
                  .where((e) => isSameDay(e.date, day))
                  .toList();
            },
            onDaySelected: (selected, focused) {
              setState(() {
                _selectedDay = selected;
                _focusedDay = focused;
              });
            },
            onFormatChanged: (format) {
              setState(() {
                _calendarFormat = format;
              });
            },
            calendarBuilders: CalendarBuilders(
              defaultBuilder: (context, day, focusedDay) {
                return _buildCalendarDayCell(day, focusedDay, false);
              },
              todayBuilder: (context, day, focusedDay) {
                return _buildCalendarDayCell(day, focusedDay, true);
              },
              selectedBuilder: (context, day, focusedDay) {
                return _buildCalendarDayCell(day, focusedDay, false, true);
              },
            ),
          ),
        ),

        const SizedBox(height: 16),

        // Event list in mobile view
        Expanded(child: _buildEventList(groupedDates)),
      ],
    );
  }

  Widget _buildCalendarDayCell(
      DateTime day,
      DateTime focusedDay,
      bool isToday, [
        bool isSelected = false,
      ]) {
    final appointments = ref.watch(calendarProvider);
    final matches = appointments.where((e) => isSameDay(e.date, day)).toList();
    final isMobile = MediaQuery.of(context).size.width < 768;

    return MouseRegion(
      onEnter: (event) {
        if (matches.isNotEmpty) {
          setState(() {
            _hoveredNote = matches.first.note;
          });
        }
      },
      onExit: (event) {
        setState(() {
          _hoveredNote = null;
        });
      },
      child: Container(
        margin: const EdgeInsets.all(2),
        decoration: BoxDecoration(
          color: isSelected
              ? Colors.blue.shade400
              : isToday
              ? Colors.blue.shade100
              : Colors.white,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '${day.day}',
              style: TextStyle(
                fontSize: isMobile ? 14 : 16,
                fontWeight: FontWeight.bold,
                color: isSelected ? Colors.white : Colors.black,
              ),
            ),
            if (matches.isNotEmpty)
              Column(
                children: matches.take(2).map((e) {
                  final color = _getNoteColor(e.note);
                  return Tooltip(
                    message: e.note,
                    child: Container(
                      margin: const EdgeInsets.only(top: 2),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 2,
                        vertical: 1,
                      ),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? color.withOpacity(0.8)
                            : color.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        e.note.split(' ').first,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: isMobile ? 10 : 8,
                          color: isSelected ? Colors.white : color,
                          height: 1.1,
                          fontWeight: FontWeight.w600,
                        ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                    ),
                  );
                }).toList(),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildEventList(Map<DateTime, List<ContractDateNote>> groupedDates) {
    final isMobile = MediaQuery.of(context).size.width < 768;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade300),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 2,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: EdgeInsets.all(isMobile ? 8 : 16),
      child: groupedDates.isEmpty
          ? Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.calendar_today,
              size: 48,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              "No events found for this contract",
              style: TextStyle(
                fontSize: isMobile ? 14 : 16,
                fontWeight: FontWeight.w500,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      )
          : ListView.builder(
        padding: EdgeInsets.zero,
        itemCount: groupedDates.length,
        itemBuilder: (context, index) {
          final date = groupedDates.keys.elementAt(index);
          final notes = groupedDates[date]!;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  vertical: 8,
                  horizontal: 12,
                ),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.calendar_today,
                      size: 16,
                      color: Colors.blue.shade700,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      DateFormat('EEE, MMM d, yyyy').format(date),
                      style: TextStyle(
                        fontSize: isMobile ? 14 : 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue.shade800,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              ...notes.map(
                    (e) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: _getNoteColor(e.note).withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          _getNoteIcon(e.note),
                          size: 18,
                          color: _getNoteColor(e.note),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              e.note,
                              style: TextStyle(
                                fontSize: isMobile ? 14 : 16,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF212121),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              DateFormat('h:mm a').format(e.date),
                              style: TextStyle(
                                fontSize: isMobile ? 12 : 13,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              if (index != groupedDates.length - 1)
                const Divider(
                  height: 16,
                  thickness: 0.5,
                  color: Colors.grey,
                ),
            ],
          );
        },
      ),
    );
  }

  IconData _getNoteIcon(String note) {
    switch (note) {
      case 'Effective Date':
        return Icons.star;
      case 'Escrow Date':
        return Icons.account_balance;
      case 'Loan Application Date':
        return Icons.monetization_on;
      case 'Inspection Period Date':
        return Icons.home_work;
      case 'Closing Date':
        return Icons.gavel;
      case 'Title Evidence Date':
        return Icons.location_on;
      case 'Loan Approval Date':
        return Icons.assignment_turned_in;
      case 'Title Evidence Date':
        return Icons.directions_walk;
      default:
        return Icons.event;
    }
  }
}