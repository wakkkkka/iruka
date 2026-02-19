import 'package:flutter/material.dart';
import 'calendar_page.dart';
import 'settings_page.dart';
import 'statistics_page.dart';
import 'camera_page.dart';
import '../services/clothes_api_service.dart';


class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final ClothesApiService _clothesApiService = ClothesApiService();

  bool _closetBusy = false;
  String _closetLog = '';

  Future<void> _runClosetTask(Future<void> Function() task) async {
    if (_closetBusy) return;
    setState(() {
      _closetBusy = true;
    });
    try {
      await task();
    } finally {
      if (!mounted) return;
      setState(() {
        _closetBusy = false;
      });
    }
  }

  void _appendLog(String text) {
    setState(() {
      final trimmed = text.trim();
      _closetLog = _closetLog.isEmpty ? trimmed : '$_closetLog\n\n$trimmed';
    });
  }

  Widget _buildClosetHome() {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'クローゼット（ホーム）',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: _closetBusy
                        ? null
                        : () => _runClosetTask(() async {
                              try {
                                final items = await _clothesApiService.listClothes();
                                _appendLog('GET /clothes\n${items.length}件\n$items');
                              } catch (e) {
                                _appendLog('GET /clothes 失敗\n$e');
                              }
                            }),
                    child: const Text('一覧取得'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _closetBusy
                        ? null
                        : () => _runClosetTask(() async {
                              try {
                                final created = await _clothesApiService.createClothes(
                                  category: 'tops',
                                  subCategory: 't-shirt',
                                  color: 'navy',
                                  sleeveLength: 'short',
                                  season: const ['spring', 'fall'],
                                  scene: 'casual',
                                );
                                _appendLog('POST /clothes 成功\n$created');
                              } catch (e) {
                                _appendLog('POST /clothes 失敗\n$e');
                              }
                            }),
                    child: const Text('サンプル追加'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.black12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: SingleChildScrollView(
                  child: Text(
                    _closetLog.isEmpty ? 'ここに結果が表示されます' : _closetLog,
                    style: const TextStyle(fontSize: 12),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

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
    final pages = <Widget>[
      const CalendarPage(),
      _buildClosetHome(),
      const StatisticsPage(),
      const SettingsPage(),
    ];

    return Stack(
      children: [
        Scaffold(
          body: pages[_selectedIndex],
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
                      label: '自撮り',
                      onTap: () {
                        _hideCameraMenu();
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const CameraPage()),
                        );
                      },
                    ),
                    const SizedBox(height: 16),
                    _buildCircleMenuButton(
                      icon: Icons.add_a_photo,
                      label: '新規登録',
                      onTap: () {
                        _hideCameraMenu();
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const CameraPage()),
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
