import 'package:flutter/material.dart';

import '../services/selfie_api_service.dart';

class CalendarPage extends StatefulWidget {
  const CalendarPage({super.key});

  @override
  State<CalendarPage> createState() => _CalendarPageState();
}

class _CalendarPageState extends State<CalendarPage> {
  final SelfieApiService _selfieApiService = SelfieApiService();

  bool _busy = false;
  String? _error;
  List<Map<String, dynamic>> _items = const [];

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  String _isoDateLocal(DateTime dt) {
    final y = dt.year.toString().padLeft(4, '0');
    final m = dt.month.toString().padLeft(2, '0');
    final d = dt.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  Future<void> _refresh() async {
    if (_busy) return;
    setState(() {
      _busy = true;
    });
    try {
      final now = DateTime.now();
      final from = _isoDateLocal(now.subtract(const Duration(days: 30)));
      final to = _isoDateLocal(now);
      final items = await _selfieApiService.listWearLogs(from: from, to: to);
      if (!mounted) return;
      setState(() {
        _items = items;
        _error = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
      });
    } finally {
      if (mounted) {
        setState(() {
          _busy = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('履歴')),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _refresh,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              const Text(
                '直近30日の着用ログ',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              if (_error != null) ...[
                Text(
                  _error!,
                  style: const TextStyle(color: Colors.red, fontSize: 12),
                ),
                const SizedBox(height: 12),
              ],
              if (_items.isEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 24),
                  child: Center(
                    child: Text(
                      _busy ? '読み込み中…' : 'ログがありません',
                      style: const TextStyle(color: Colors.black54),
                    ),
                  ),
                )
              else
                ..._items.map(_buildItemCard),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildItemCard(Map<String, dynamic> item) {
    final date = (item['date'] is String)
        ? (item['date'] as String).trim()
        : '';
    final clothesIds = item['clothesIds'];
    final selections = item['selections'];

    String summary = '';
    if (clothesIds is List) {
      final ids = clothesIds
          .map((e) => e.toString())
          .where((e) => e.trim().isNotEmpty)
          .toList();
      summary = ids.isEmpty ? '' : ids.join(', ');
    }

    String selectionSummary = '';
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
}
