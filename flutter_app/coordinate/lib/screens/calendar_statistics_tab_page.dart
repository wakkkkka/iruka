import 'package:flutter/material.dart';
import 'calendar_page.dart';
import 'statistics_page.dart';

/// カレンダーと統計をタブで切り替える統合ページ
class CalendarStatisticsTabPage extends StatefulWidget {
  const CalendarStatisticsTabPage({super.key});

  @override
  State<CalendarStatisticsTabPage> createState() => _CalendarStatisticsTabPageState();
}

class _CalendarStatisticsTabPageState extends State<CalendarStatisticsTabPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('カレンダー & 統計'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.calendar_today), text: 'カレンダー'),
            Tab(icon: Icon(Icons.bar_chart), text: '統計'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          CalendarPage(),
          AnalyticsDashboard(),
        ],
      ),
    );
  }
}
