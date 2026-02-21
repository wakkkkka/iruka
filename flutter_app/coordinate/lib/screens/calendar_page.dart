import 'package:table_calendar/table_calendar.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/selfie_api_service.dart';
import 'clothes_detail_mini.dart';

class CalendarPage extends StatefulWidget {
  const CalendarPage({super.key});

  @override
  State<CalendarPage> createState() => _CalendarPageState();
}

class _CalendarPageState extends State<CalendarPage> {
      Widget buildWearLogCard(Map<String, dynamic> log) {
        final selections = log['selections'];
        String selectionSummary = '';
        String summary = log['summary'] ?? '';
        String date = log['date'] ?? '';

        if (selections is Map) {
          final entries = selections.entries
              .map((e) => '${e.key}: ${e.value}')
              .where((e) => e.trim().isNotEmpty)
              .toList();
          selectionSummary = entries.isEmpty ? '' : entries.join(' / ');
        }

        return Card(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  date.isNotEmpty ? date : '日付不明',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 6),
                if (selectionSummary.isNotEmpty)
                  Text(selectionSummary, style: const TextStyle(fontSize: 12))
                else if (summary.isNotEmpty)
                  Text(summary, style: const TextStyle(fontSize: 12))
                else
                  const Text(
                    '—',
                    style: TextStyle(fontSize: 12, color: Colors.black54),
                  ),
              ],
            ),
          ),
        );
      }
    DateTime? _selectedDay;
    List<Map<String, dynamic>> _selectedDayLogs = const [];
    final List<Map<String, dynamic>> _items = [];
    // ...existing code...

  @override
  void initState() {
    super.initState();
    // ...existing code...
  }

  String _isoDateLocal(DateTime dt) {
    final y = dt.year.toString().padLeft(4, '0');
    final m = dt.month.toString().padLeft(2, '0');
    final d = dt.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  // ...existing code...

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(title: const Text('カレンダー')),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: TableCalendar(
                firstDay: DateTime.utc(2020, 1, 1),
                lastDay: DateTime.utc(2030, 12, 31),
                focusedDay: _selectedDay ?? DateTime.now(),
                selectedDayPredicate: (day) => _selectedDay != null && isSameDay(day, _selectedDay),
                calendarFormat: CalendarFormat.month,
                headerStyle: const HeaderStyle(
                  titleCentered: false,
                  formatButtonVisible: false,
                  leftChevronVisible: false,
                  rightChevronVisible: false,
                  titleTextFormatter: null,
                ),
                calendarBuilders: CalendarBuilders(
                  headerTitleBuilder: (context, day) {
                    final monthNumber = DateFormat.M().format(day);
                    final monthName = DateFormat.MMMM().format(day);
                    return Padding(
                      padding: const EdgeInsets.only(left: 16.0, top: 20, bottom: 10),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          Text(
                            monthNumber,
                            style: const TextStyle(
                              fontSize: 48,
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            monthName,
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w300,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                  defaultBuilder: (context, day, focusedDay) {
                    return Center(
                      child: Text(
                        '${day.day}',
                        style: const TextStyle(color: Colors.black),
                      ),
                    );
                  },
                ),
                calendarStyle: CalendarStyle(
                  todayDecoration: const BoxDecoration(
                    color: Colors.black,
                    shape: BoxShape.circle,
                  ),
                  selectedDecoration: BoxDecoration(
                    color: Colors.grey[800],
                    shape: BoxShape.circle,
                  ),
                  weekendTextStyle: const TextStyle(color: Colors.black),
                ),
                onDaySelected: (selectedDay, focusedDay) {
                  setState(() {
                    _selectedDay = selectedDay;
                    _selectedDayLogs = _items.where((item) {
                      final dateStr = item['date'] as String?;
                      if (dateStr == null) return false;
                      final date = DateTime.tryParse(dateStr);
                      return date != null &&
                        date.year == selectedDay.year &&
                        date.month == selectedDay.month &&
                        date.day == selectedDay.day;
                    }).toList();
                  });
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: Text(DateFormat('yyyy/MM/dd').format(selectedDay)),
                      content: _selectedDayLogs.isEmpty
                          ? const Text('着用記録がありません')
                          : SizedBox(
                              width: 300,
                              child: ListView.builder(
                                shrinkWrap: true,
                                itemCount: _selectedDayLogs.length,
                                itemBuilder: (context, idx) {
                                  final log = _selectedDayLogs[idx];
                                  final selfieUrl = log['selfieUrl'] as String?;
                                  final clothesIds = log['clothesIds'] as List?;
                                  final selections = log['selections'] as Map?;
                                  return Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      if (selfieUrl != null && selfieUrl.isNotEmpty)
                                        Padding(
                                          padding: const EdgeInsets.only(bottom: 8),
                                          child: Image.network(selfieUrl, height: 120, fit: BoxFit.cover, errorBuilder: (c, e, s) => const Icon(Icons.broken_image)),
                                        ),
                                      if (clothesIds != null && clothesIds.isNotEmpty)
                                        ...clothesIds.map<Widget>((id) => ClothesDetailMini(id: id.toString())),
                                      if (selections != null && selections.isNotEmpty)
                                        Padding(
                                          padding: const EdgeInsets.only(top: 4),
                                          child: Text('タグ: ${selections.entries.map((e) => '${e.key}: ${e.value}').join(', ')}', style: const TextStyle(fontSize: 12)),
                                        ),
                                      const Divider(),
                                    ],
                                  );
                                },
                              ),
                            ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(),
                          child: const Text('閉じる'),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),

            // ...existing code...
          ],
        ),
      ),
    );
  }

  // ...existing code...
// ここに何も書かない（ClothesDetailMiniは外部ファイルからimport）
}




