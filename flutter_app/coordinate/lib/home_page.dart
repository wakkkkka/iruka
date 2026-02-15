import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'calendar_page.dart';
import 'settings_page.dart';
import 'screens/closet_screen.dart';
import 'screens/registration_screen.dart';
import 'models/clothing_item.dart';
import 'data/mock_data.dart';
import 'statistics_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 1;

  /// 画像選択→登録画面への遷移
  Future<void> _pickImageAndNavigate() async {
    final ImagePicker picker = ImagePicker();

    // カメラまたはギャラリーから選択するダイアログを表示
    final ImageSource? source = await showModalBottomSheet<ImageSource>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) {
        return SafeArea(
          child: Wrap(
            children: [
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: const Text('カメラで撮影'),
                onTap: () => Navigator.pop(context, ImageSource.camera),
              ),
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('ギャラリーから選択'),
                onTap: () => Navigator.pop(context, ImageSource.gallery),
              ),
            ],
          ),
        );
      },
    );

    if (source == null) return;

    // 画像を選択
    final XFile? image = await picker.pickImage(source: source);

    if (image != null && mounted) {
      // 登録画面に遷移
      final ClothingItem? result = await Navigator.push<ClothingItem>(
        context,
        MaterialPageRoute(
          builder: (context) => RegistrationScreen(imagePath: image.path),
        ),
      );

      if (result != null) {
        MockData.addClothingItem(result);
      }

      // 画面を更新（ClosetScreenを再描画）
      setState(() {});
    }
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      const CalendarPage(),
      ClosetScreen(),
      const StatisticsPage(),
      const SettingsPage(),
    ];
    return Scaffold(
      body: pages[_selectedIndex],
      floatingActionButton: _selectedIndex == 1
          ? FloatingActionButton(
              onPressed: _pickImageAndNavigate,
              shape: const CircleBorder(),
              child: const Icon(Icons.camera_alt),
            )
          : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.endDocked,
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_today),
            label: 'カレンダー',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'ホーム'),
          BottomNavigationBarItem(icon: Icon(Icons.settings), label: '設定'),
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'ホーム'),
          BottomNavigationBarItem(icon: Icon(Icons.bar_chart), label: '統計'),
          BottomNavigationBarItem(icon: Icon(Icons.settings), label: '設定'),
        ],
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
      ),
    );
  }
}
