import 'package:flutter/material.dart';
import 'package:amplify_flutter/amplify_flutter.dart';
import 'calendar_page.dart';
import 'settings_page.dart';
import 'statistics_page.dart';
import 'clothes_camera_page.dart';
import 'selfie_camera_page.dart';
import 'clothes_detail_page.dart';
import '../services/clothes_api_service.dart';
import '../constants/clothes_options.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final ClothesApiService _clothesApiService = ClothesApiService();

  bool _closetBusy = false;
  String? _closetError;
  List<Map<String, dynamic>> _closetItems = const [];
  final Map<String, Future<String>> _imageUrlFutures = {};

  @override
  void initState() {
    super.initState();
    _refreshCloset();
  }

  Future<void> _runClosetTask(Future<void> Function() task) async {
    if (_closetBusy) return;
    setState(() {
      _closetBusy = true;
    });
    try {
      await task();
    } finally {
      if (mounted) {
        setState(() {
          _closetBusy = false;
        });
      }
    }
  }

  Future<void> _refreshCloset() async {
    await _runClosetTask(() async {
      try {
        final items = await _clothesApiService.listClothes();
        if (!mounted) return;
        setState(() {
          _closetItems = items;
          _closetError = null;
        });
      } catch (e) {
        if (!mounted) return;
        setState(() {
          _closetError = e.toString();
        });
      }
    });
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

  String _buildSubtitle(Map<String, dynamic> item) {
    final parts = <String>[];
    final subCategory = item['subCategory'];
    final color = item['color'];
    final sleeveLength = item['sleeveLength'];
    final hemLength = item['hemLength'];

    if (subCategory is String && subCategory.trim().isNotEmpty) {
      parts.add(
        ClothesOptions.labelFor(
          subCategory.trim(),
          ClothesOptions.subCategoryLabels,
        ),
      );
    }
    if (color is String && color.trim().isNotEmpty) {
      parts.add(
        '色: ${ClothesOptions.labelFor(color.trim(), ClothesOptions.colorLabels)}',
      );
    }
    if (sleeveLength is String && sleeveLength.trim().isNotEmpty) {
      parts.add(
        '袖: ${ClothesOptions.labelFor(sleeveLength.trim(), ClothesOptions.sleeveLengthLabels)}',
      );
    }
    if (hemLength is String && hemLength.trim().isNotEmpty) {
      parts.add(
        '丈: ${ClothesOptions.labelFor(hemLength.trim(), ClothesOptions.hemLengthLabels)}',
      );
    }

    return parts.isEmpty ? '—' : parts.join(' / ');
  }

  Widget _buildThumbnail(String storagePath) {
    return FutureBuilder<String>(
      future: _resolveImageUrl(storagePath),
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return Container(
            width: 72,
            height: 72,
            color: Colors.black12,
            child: const Center(
              child: SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          );
        }
        final url = snapshot.data;
        if (url == null || url.isEmpty || snapshot.hasError) {
          return Container(
            width: 72,
            height: 72,
            color: Colors.black12,
            child: const Icon(Icons.image_not_supported),
          );
        }
        return ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.network(
            url,
            width: 72,
            height: 72,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              return Container(
                width: 72,
                height: 72,
                color: Colors.black12,
                child: const Icon(Icons.broken_image),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildClosetHome() {
    // カテゴリーごとにグループ化
    final Map<String, List<Map<String, dynamic>>> grouped = {};
    for (final item in _closetItems) {
      final category = (item['category'] is String)
          ? (item['category'] as String).trim()
          : 'その他';
      final label = category.isNotEmpty
          ? ClothesOptions.labelFor(category, ClothesOptions.categoryLabels)
          : 'その他';
      grouped.putIfAbsent(label, () => []).add(item);
    }

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
            if (_closetError != null) ...[
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  _closetError!,
                  style: const TextStyle(color: Colors.red, fontSize: 12),
                ),
              ),
            ],
            const SizedBox(height: 8),
            Expanded(
              child: RefreshIndicator(
                onRefresh: _refreshCloset,
                child: ListView(
                  children: grouped.entries.map((entry) {
                    final categoryLabel = entry.key;
                    final items = entry.value;
                    return ExpansionTile(
                      title: Text(categoryLabel, style: const TextStyle(fontWeight: FontWeight.bold)),
                      children: items.map((item) {
                        final clothesId = (item['clothesId'] is String)
                            ? (item['clothesId'] as String).trim()
                            : '';
                        final name = (item['name'] is String)
                            ? (item['name'] as String).trim()
                            : '';
                        final title = name.isNotEmpty
                            ? name
                            : categoryLabel;
                        final subtitle = _buildSubtitle(item);
                        final imageUrl = item['imageUrl'];
                        return Card(
                          child: InkWell(
                            onTap: clothesId.isEmpty
                                ? null
                                : () async {
                                    final changed = await Navigator.push<bool>(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => ClothesDetailPage(clothesId: clothesId),
                                      ),
                                    );
                                    if (!mounted) return;
                                    if (changed == true) {
                                      await _refreshCloset();
                                    }
                                  },
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (imageUrl is String && imageUrl.trim().isNotEmpty)
                                    _buildThumbnail(imageUrl)
                                  else
                                    Container(
                                      width: 72,
                                      height: 72,
                                      color: Colors.black12,
                                      child: const Icon(Icons.image),
                                    ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          title,
                                          style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          subtitle,
                                          style: const TextStyle(fontSize: 12),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    );
                  }).toList(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCircleMenuButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
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
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: Colors.black87),
        ),
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
                    child: const Icon(
                      Icons.camera_alt,
                      size: 40.0,
                      color: Colors.deepPurple,
                    ),
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
              BottomNavigationBarItem(icon: Icon(Icons.home), label: 'ホーム'),
              BottomNavigationBarItem(icon: Icon(Icons.bar_chart), label: '統計'),
              BottomNavigationBarItem(icon: Icon(Icons.settings), label: '設定'),
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
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        const SelfieCameraPage(),
                                  ),
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
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        const ClothesCameraPage(),
                                  ),
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
