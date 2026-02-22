import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';

import '../constants/clothes_options.dart';
import '../services/clothes_api_service.dart';
import '../services/selfie_api_service.dart';

class CalendarPage extends StatefulWidget {
  const CalendarPage({super.key});

  @override
  State<CalendarPage> createState() => _CalendarPageState();
}

class _CalendarPageState extends State<CalendarPage> {
  DateTime? _selectedDay;

  bool _isLoading = false;

  final ClothesApiService _clothesApiService = ClothesApiService();

  List<Map<String, dynamic>> _wearLogs = const [];
  final Map<DateTime, List<Map<String, dynamic>>> _wearLogsByDay = {};
  List<Map<String, dynamic>> _selectedDayLogs = const [];

  final Map<String, Future<String>> _imageUrlFutures = {};
  final Map<String, Future<Map<String, dynamic>>> _clothesByIdFutures = {};

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  Future<void> _refresh() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final logs = await SelfieApiService().listWearLogs();

      if (!mounted) return;
      setState(() {
        _wearLogs = logs;
        _rebuildWearLogsByDay();
      });
    } catch (_) {
      // ここではUIを壊さないため握りつぶし（必要ならSnackBarに拡張）
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  DateTime _dayKey(DateTime day) => DateTime(day.year, day.month, day.day);

  DateTime? _parseLogDate(Map<String, dynamic> log) {
    final raw = log['date'];
    if (raw is String) {
      final dt = DateTime.tryParse(raw);
      if (dt == null) return null;
      return dt.isUtc ? dt.toLocal() : dt;
    }
    return null;
  }

  void _rebuildWearLogsByDay() {
    _wearLogsByDay.clear();
    for (final log in _wearLogs) {
      final date = _parseLogDate(log);
      if (date == null) continue;
      final key = _dayKey(date);
      final list = _wearLogsByDay.putIfAbsent(
        key,
        () => <Map<String, dynamic>>[],
      );
      list.add(log);
    }
  }

  bool _hasLogsOnDay(DateTime day) {
    return _wearLogsByDay[_dayKey(day)]?.isNotEmpty ?? false;
  }

  Future<String> _resolveImageUrl(String storagePath) {
    final trimmed = storagePath.trim();
    return _imageUrlFutures.putIfAbsent(trimmed, () async {
      final result = await Amplify.Storage.getUrl(
        path: StoragePath.fromString(trimmed),
      ).result;
      return result.url.toString();
    });
  }

  Widget _buildThumbnailFromStorageOrUrl(String rawPathOrUrl) {
    final trimmed = rawPathOrUrl.trim();
    if (trimmed.isEmpty) {
      return Container(
        width: 56,
        height: 56,
        color: Colors.black12,
        child: const Center(child: Icon(Icons.image, size: 20)),
      );
    }

    if (trimmed.startsWith('http://') || trimmed.startsWith('https://')) {
      return Image.network(
        trimmed,
        width: 56,
        height: 56,
        fit: BoxFit.cover,
        errorBuilder: (c, e, s) => Container(
          width: 56,
          height: 56,
          color: Colors.black12,
          child: const Center(child: Icon(Icons.broken_image, size: 20)),
        ),
      );
    }

    return FutureBuilder<String>(
      future: _resolveImageUrl(trimmed),
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return Container(
            width: 56,
            height: 56,
            color: Colors.black12,
            child: const Center(
              child: SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          );
        }

        final url = snapshot.data;
        if (url == null || url.isEmpty || snapshot.hasError) {
          return Container(
            width: 56,
            height: 56,
            color: Colors.black12,
            child: const Center(child: Icon(Icons.broken_image, size: 20)),
          );
        }

        return Image.network(
          url,
          width: 56,
          height: 56,
          fit: BoxFit.cover,
          errorBuilder: (c, e, s) => Container(
            width: 56,
            height: 56,
            color: Colors.black12,
            child: const Center(child: Icon(Icons.broken_image, size: 20)),
          ),
        );
      },
    );
  }

  Future<Map<String, dynamic>> _getClothesById(String id) {
    final trimmed = id.trim();
    return _clothesByIdFutures.putIfAbsent(trimmed, () {
      return _clothesApiService.getClothes(trimmed);
    });
  }

  List<String> _extractClothesIdsFromLogs(List<Map<String, dynamic>> logs) {
    final ids = <String>{};
    for (final log in logs) {
      final raw = log['clothesIds'];
      if (raw is List) {
        for (final v in raw) {
          final id = v?.toString().trim();
          if (id != null && id.isNotEmpty) ids.add(id);
        }
      }
    }
    return ids.toList();
  }

  Widget _buildClothesRowFromId(String clothesId) {
    return FutureBuilder<Map<String, dynamic>>(
      future: _getClothesById(clothesId),
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Row(
              children: [
                Container(width: 56, height: 56, color: Colors.black12),
                const SizedBox(width: 10),
                const Expanded(
                  child: Text('読み込み中...', style: TextStyle(fontSize: 13)),
                ),
              ],
            ),
          );
        }

        final item = snapshot.data;
        if (item == null || snapshot.hasError) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Row(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  color: Colors.black12,
                  child: const Center(
                    child: Icon(Icons.broken_image, size: 20),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    '削除されたアイテム（削除済み）',
                    style: const TextStyle(fontSize: 12),
                  ),
                ),
              ],
            ),
          );
        }

        final categoryRaw = (item['category'] ?? '').toString().trim();
        final categoryLabel = categoryRaw.isEmpty
            ? 'カテゴリ不明'
            : ClothesOptions.labelFor(
                categoryRaw,
                ClothesOptions.categoryLabels,
              );
        final imageUrl = (item['imageUrl'] ?? '').toString();

        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: _buildThumbnailFromStorageOrUrl(imageUrl),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  categoryLabel,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDayCell(
    BuildContext context,
    DateTime day, {
    required bool isSelected,
    required bool isToday,
  }) {
    final cs = Theme.of(context).colorScheme;
    final hasItem = _hasLogsOnDay(day);

    final Color backgroundColor;
    final Color textColor;

    if (isSelected) {
      backgroundColor = Colors.grey[800]!;
      textColor = Colors.white;
    } else if (isToday) {
      backgroundColor = Colors.black;
      textColor = Colors.white;
    } else if (hasItem) {
      backgroundColor = cs.primary.withValues(alpha: 0.18);
      textColor = Colors.black;
    } else {
      backgroundColor = Colors.transparent;
      textColor = Colors.black;
    }

    return Center(
      child: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: backgroundColor,
          shape: BoxShape.circle,
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [Text('${day.day}', style: TextStyle(color: textColor))],
        ),
      ),
    );
  }

  void _onDaySelected(DateTime selectedDay) {
    setState(() {
      _selectedDay = selectedDay;
      _selectedDayLogs = List<Map<String, dynamic>>.unmodifiable(
        _wearLogsByDay[_dayKey(selectedDay)] ?? const [],
      );
    });

    final clothesIds = _extractClothesIdsFromLogs(_selectedDayLogs);

    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(DateFormat('yyyy/MM/dd').format(selectedDay)),
        content: SizedBox(
          width: 320,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '着用アイテム',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                if (_selectedDayLogs.isEmpty)
                  const Text('着用記録はありません')
                else if (clothesIds.isEmpty)
                  const Text('この日の着用記録に clothesIds がありません')
                else
                  ...clothesIds.map(_buildClothesRowFromId),
              ],
            ),
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
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(title: const Text('カレンダー')),
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: TableCalendar(
                      firstDay: DateTime.utc(2020, 1, 1),
                      lastDay: DateTime.utc(2030, 12, 31),
                      focusedDay: _selectedDay ?? DateTime.now(),
                      selectedDayPredicate: (day) =>
                          _selectedDay != null && isSameDay(day, _selectedDay),
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
                          final year = DateFormat.y().format(day);
                          final monthNumber = DateFormat.M().format(day);
                          final monthName = DateFormat.MMMM().format(day);
                          return Padding(
                            padding: const EdgeInsets.only(
                              left: 16.0,
                              top: 10,
                              bottom: 10,
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  year,
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.black87,
                                  ),
                                ),
                                Row(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.baseline,
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
                              ],
                            ),
                          );
                        },
                        defaultBuilder: (context, day, focusedDay) {
                          return _buildDayCell(
                            context,
                            day,
                            isSelected: false,
                            isToday: false,
                          );
                        },
                        todayBuilder: (context, day, focusedDay) {
                          return _buildDayCell(
                            context,
                            day,
                            isSelected: false,
                            isToday: true,
                          );
                        },
                        selectedBuilder: (context, day, focusedDay) {
                          return _buildDayCell(
                            context,
                            day,
                            isSelected: true,
                            isToday: false,
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
                        _onDaySelected(selectedDay);
                      },
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
