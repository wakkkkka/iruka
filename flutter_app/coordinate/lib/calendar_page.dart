import 'package:flutter/material.dart';

class CalendarPage extends StatelessWidget {
  const CalendarPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('カレンダー')),
      body: Center(
        child: Text('カレンダー（月表示）', style: TextStyle(fontSize: 24)),
      ),
    );
  }
}
