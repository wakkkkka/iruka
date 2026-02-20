import 'package:flutter/material.dart';
import 'calendar_page.dart';
import 'settings_page.dart';
import 'statistics_page.dart';
import 'clothes_camera_page.dart';
import 'selfie_camera_page.dart';


class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {

  Widget _buildCircleMenuButton({required IconData icon, required String label, required VoidCallback onTap}) {
    return Column(
      children: [
        Material(
          color: Colors.white,
          shape: const CircleBorder(),
          elevation: 4,
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: onTap,
            child: SizedBox(
              width: 60.0,
              height: 60.0,
              child: Icon(icon, size: 40.0, color: Colors.deepPurple),
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.black87)),
      ],
    );
  }

  int _selectedIndex = 1;
  final List<Widget> _pages = [
    const CalendarPage(),
    Center(child: Text('クローゼット（ホーム）', style: TextStyle(fontSize: 24))),
    const StatisticsPage(),
    const SettingsPage(),
  ];

  bool _showCameraOverlay = false;

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  void _showCameraMenu() {
    setState(() {
      _showCameraOverlay = true;
    });
  }

  void _hideCameraMenu() {
    setState(() {
      _showCameraOverlay = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Scaffold(
          body: _pages[_selectedIndex],
            floatingActionButton: _selectedIndex == 1
                ? SizedBox(
                    width: 60.0,
                    height: 60.0,
                    child: FloatingActionButton(
                      onPressed: _showCameraMenu,
                      shape: const CircleBorder(),
                      backgroundColor: Colors.white,
                      elevation: 4,
                      child: const Icon(Icons.camera_alt, size: 40.0, color: Colors.deepPurple),
                    ),
                  )
                : null,
          // 右下に寄せる
          floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
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
        ),
        if (_showCameraOverlay)
          Positioned.fill(
            child: Material(
      color: Colors.transparent, // 背景は透明にする
      child: GestureDetector(
        onTap: _hideCameraMenu,
        child: Container(
          color: Colors.white.withValues(alpha: 0.85),
          child: Stack(
            children: [
              Positioned(
                bottom: 85 + 56,
                right: 16,
                child: Column(
                  children: [
                    _buildCircleMenuButton(
                        icon: Icons.camera_front,
                        label: '着用記録',
                        onTap: () {
                          _hideCameraMenu();
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const SelfieCameraPage()),
                          );
                        },
                    ),
                    const SizedBox(height: 16),
                    _buildCircleMenuButton(
                        icon: Icons.add_a_photo,
                        label: '新規服登録',
                        onTap: () {
                          _hideCameraMenu();
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const ClothesCameraPage()),
                          );
                        },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  ),
      ],
    );

  }
}
