import 'package:flutter/material.dart';
import 'calendar_page.dart';
import 'settings_page.dart';
import 'statistics_page.dart';
import 'camera_page.dart';


class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 1;
  final List<Widget> _pages = [
    const CalendarPage(),
    Center(child: Text('クローゼット（ホーム）', style: TextStyle(fontSize: 24))),
    const StatisticsPage(),
    const SettingsPage(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          _pages[_selectedIndex],
          if (_selectedIndex == 1)
            Positioned(
              right: 16,
              bottom: 35, // ← ここで下からの距離を調整（元は16程度）
              child: SizedBox(
                width: 60.0, // 丸い枠の直径を大きく
                height: 60.0,
                child: FloatingActionButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const CameraPage()),
                    );
                  },
                  shape: const CircleBorder(),
                  elevation: 6.0,
                  backgroundColor: const Color.fromARGB(255, 227, 219, 233), // 必要に応じて色を調整
                   child: const Icon(
                    Icons.camera_alt,
                    size: 40.0, // アイコンの大きさを大きく
                  ),
                ),
              ),
            ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_today),
            label: 'カレンダー',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'ホーム',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.bar_chart),
            label: '統計',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: '設定',
          ),
        ],
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
      ),
    );
  }
}
