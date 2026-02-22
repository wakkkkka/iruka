 import 'package:flutter/material.dart';
import 'dart:io';
 

// import 'package:fl_chart/fl_chart.dart';

// ============================
// 季節判定ヘルパー
// ============================
String getSeason(int month) {
  if (month >= 3 && month <= 5) return "春";
  if (month >= 6 && month <= 8) return "夏";
  if (month >= 9 && month <= 11) return "秋";
  return "冬";
}

// ============================
// ダミーデータ（フェーズ2でAWSから取得に置き換え）
// ============================
/// 着用ログ 1件分
class WearLog {
  final String category; // 服のカテゴリ（Tシャツ, パーカー, etc.）
  final String color; // 色
  final DateTime date; // 着用日

  const WearLog({
    required this.category,
    required this.color,
    required this.date,
  });
}

/// フェーズ1用のダミー着用ログ
final List<WearLog> dummyWearLogs = [
  // --- 冬（12〜2月） ---
  WearLog(category: 'コート', color: '黒', date: DateTime(2025, 12, 3)),
  WearLog(category: 'ニット', color: '白', date: DateTime(2025, 12, 10)),
  WearLog(category: 'コート', color: '黒', date: DateTime(2025, 12, 20)),
  WearLog(category: 'パーカー', color: 'グレー', date: DateTime(2026, 1, 5)),
  WearLog(category: 'ニット', color: 'ベージュ', date: DateTime(2026, 1, 12)),
  WearLog(category: 'コート', color: '黒', date: DateTime(2026, 1, 25)),
  WearLog(category: 'パーカー', color: '黒', date: DateTime(2026, 2, 1)),
  WearLog(category: 'ニット', color: '白', date: DateTime(2026, 2, 8)),
  // --- 春（3〜5月） ---
  WearLog(category: 'Tシャツ', color: '白', date: DateTime(2025, 4, 10)),
  WearLog(category: 'シャツ', color: '青', date: DateTime(2025, 4, 20)),
  WearLog(category: 'パーカー', color: 'グレー', date: DateTime(2025, 5, 3)),
  WearLog(category: 'シャツ', color: '白', date: DateTime(2025, 5, 15)),
  WearLog(category: 'Tシャツ', color: '黒', date: DateTime(2025, 3, 22)),
  // --- 夏（6〜8月） ---
  WearLog(category: 'Tシャツ', color: '白', date: DateTime(2025, 6, 5)),
  WearLog(category: 'Tシャツ', color: '黒', date: DateTime(2025, 7, 10)),
  WearLog(category: 'Tシャツ', color: '白', date: DateTime(2025, 7, 20)),
  WearLog(category: 'ショートパンツ', color: 'ベージュ', date: DateTime(2025, 8, 1)),
  WearLog(category: 'Tシャツ', color: '青', date: DateTime(2025, 8, 15)),
  WearLog(category: 'ショートパンツ', color: '黒', date: DateTime(2025, 8, 25)),
  // --- 秋（9〜11月） ---
  WearLog(category: 'シャツ', color: 'チェック', date: DateTime(2025, 9, 8)),
  WearLog(category: 'パーカー', color: '黒', date: DateTime(2025, 10, 5)),
  WearLog(category: 'ニット', color: 'グレー', date: DateTime(2025, 10, 20)),
  WearLog(category: 'パーカー', color: 'グレー', date: DateTime(2025, 11, 3)),
  WearLog(category: 'コート', color: '紺', date: DateTime(2025, 11, 25)),
];

// ============================
// 統計ページ本体
// ============================
void main() {
  runApp(const ClosetAnalyticsApp());
}

class ClosetAnalyticsApp extends StatelessWidget {
  const ClosetAnalyticsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.light,
        scaffoldBackgroundColor: const Color(0xFFF3F4F6),
        useMaterial3: true,
      ),
      home: const AnalyticsDashboard(),
    );
  }
}

class AnalyticsDashboard extends StatelessWidget {
            // 14日以上着ていない服を抽出
            List<WearLog> getUnwornSeasonItems() {
              final now = DateTime.now();
              final seasonLogs = getSeasonWearLogs();
              return seasonLogs.where((log) => now.difference(log.date).inDays >= 14).toList();
            }
          // 今の季節に該当する服を抽出
          List<WearLog> getSeasonWearLogs() {
            final season = getCurrentSeason();
            // カテゴリと季節の対応（例）
            final Map<String, List<String>> seasonCategories = {
              '春': ['シャツ', 'Tシャツ', 'パーカー'],
              '夏': ['Tシャツ', 'ショートパンツ'],
              '秋': ['シャツ', 'パーカー', 'ニット', 'コート'],
              '冬': ['コート', 'ニット', 'パーカー'],
            };
            final categories = seasonCategories[season] ?? [];
            return dummyWearLogs.where((log) => categories.contains(log.category)).toList();
          }
        // 現在の季節を取得
        String getCurrentSeason() {
          final now = DateTime.now();
          return getSeason(now.month);
        }
      // ファイルの最終更新時間を取得
      Future<int> getLastSyncHoursAgo() async {
        // ファイルパス
        final path = 'lib/screens/statistics_page.dart';
        // dart:ioはFlutter Webでは使えないが、ローカルアプリならOK
        try {
          final file = File(path);
          final lastModified = await file.lastModified();
          final now = DateTime.now();
          final diff = now.difference(lastModified);
          return diff.inHours;
        } catch (_) {
          return 0;
        }
      }
    // 直近1ヶ月の色上位5つを取得
    List<String> getTopColorsLastMonth() {
      final now = DateTime.now();
      final oneMonthAgo = DateTime(now.year, now.month - 1, now.day);
      final logsLastMonth = dummyWearLogs.where((log) => log.date.isAfter(oneMonthAgo)).toList();
      final colorCount = <String, int>{};
      for (var log in logsLastMonth) {
        colorCount[log.color] = (colorCount[log.color] ?? 0) + 1;
      }
      final sorted = colorCount.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));
      return sorted.take(5).map((e) => e.key).toList();
    }
  const AnalyticsDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              const SizedBox(height: 40),
              _buildTopStats(),
              const SizedBox(height: 40),
              const Text(
                'ITEMS REQUIRING ATTENTION',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFFD15E5E),
                  letterSpacing: 1.5,
                ),
              ),
              const SizedBox(height: 20),
              // メインの横スクロールエリア
              _buildHorizontalContent(),
              const SizedBox(height: 40),
              _buildSidebarGrid(),
              const SizedBox(height: 60),
              _buildFooter(),
            ],
          ),
        ),
      ),
    );
  }

  // --- UI Components ---

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF324B5C),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.bar_chart, color: Colors.white),
            ),
            const SizedBox(width: 12),
            const Text(
              'CLOSET OS / ANALYTICS',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, letterSpacing: -1),
            ),
          ],
        ),
        Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Row(
            children: [
              Container(
                width: 6,
                height: 6,
                decoration: const BoxDecoration(color: Color(0xFF50C878), shape: BoxShape.circle),
              ),
              const SizedBox(width: 8),
              const Text('LIVE SYSTEM', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTopStats() {
    // ダミーデータのアイテム数を集計
    final int itemCount = dummyWearLogs.length;
    return FutureBuilder<int>(
      future: getLastSyncHoursAgo(),
      builder: (context, snapshot) {
        final lastSyncHours = snapshot.data ?? 0;
        return Wrap(
          spacing: 20,
          runSpacing: 20,
          children: [
            _buildStatCard('Attention Required', itemCount.toString(), 'Items'),
            _buildStatCard('Last Sync', lastSyncHours.toString(), 'Hrs ago'),
            _buildSeasonCard(),
          ],
        );
      },
    );
  }

  Widget _buildStatCard(String label, String value, String unit) {
    return Container(
      width: 280,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(40),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label.toUpperCase(), style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Colors.grey)),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(value, style: const TextStyle(fontSize: 48, fontWeight: FontWeight.w900)),
              const SizedBox(width: 8),
              Text(unit, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: Colors.grey)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSeasonCard() {
    return Container(
      width: 280,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(40),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10)],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(16)),
            child: const Icon(Icons.ac_unit, color: Colors.blue),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('冬 (WINTER)', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
              Text('END OF SEASON ANALYSIS'.toUpperCase(), style: const TextStyle(fontSize: 8, fontWeight: FontWeight.bold, color: Colors.grey)),
            ],
          ),
        ],
      ),
    );
  }

  // 横スクロールのコンテンツ
  Widget _buildHorizontalContent() {
    // 最近着ていない服（14日以上着用なし・今季節該当）をダミーデータから抽出
    final unwornItems = getUnwornSeasonItems();
    return SizedBox(
      height: 520,
      child: unwornItems.isEmpty
          ? const Center(child: Text('今季節で14日以上着ていない服はありません', style: TextStyle(fontSize: 14, color: Colors.grey)))
          : ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: unwornItems.length,
              itemBuilder: (context, index) {
                final log = unwornItems[index];
                return Padding(
                  padding: const EdgeInsets.only(right: 24),
                  child: SizedBox(
                    width: 360,
                    child: RankingCard(
                      index: (index + 1).toString().padLeft(2, '0'),
                      name: log.category,
                      rate: '${DateTime.now().difference(log.date).inDays} days ago',
                      desc: 'Last worn color: ${log.color}',
                      category: log.category,
                      imageUrl: 'https://images.unsplash.com/photo-1539533018447-63fcce2678e3', // ダミー画像
                    ),
                  ),
                );
              },
            ),
    );
  }

  Widget _buildSidebarGrid() {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth > 800) {
          return Row(
            children: [
              Expanded(child: _buildColorPalette()),
            ],
          );
        } else {
          return Column(
            children: [
              _buildColorPalette(),
            ],
          );
        }
      },
    );
  }



  Widget _buildColorPalette() {
    final now = DateTime.now();
    final oneMonthAgo = DateTime(now.year, now.month - 1, now.day);
    final logsLastMonth = dummyWearLogs.where((log) => log.date.isAfter(oneMonthAgo)).toList();
    final colorCount = <String, int>{};
    for (var log in logsLastMonth) {
      colorCount[log.color] = (colorCount[log.color] ?? 0) + 1;
    }
    final sorted = colorCount.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    // 色名→グラデーション色マップ
    Map<String, List<Color>> colorGradients = {
      '黒': [Colors.black87, Colors.grey.shade800],
      '白': [Colors.white, Colors.grey.shade200],
      'グレー': [Colors.grey.shade400, Colors.grey.shade200],
      'ベージュ': [Colors.orange.shade100, Colors.orange.shade50],
      '青': [Colors.blue.shade700, Colors.blue.shade200],
      '紺': [Colors.indigo.shade900, Colors.indigo.shade400],
      'チェック': [Colors.brown.shade400, Colors.brown.shade100],
      '赤': [Colors.red.shade400, Colors.red.shade100],
      '黄': [Colors.yellow.shade700, Colors.yellow.shade200],
      '緑': [Colors.green.shade700, Colors.green.shade200],
      // 他の色も必要に応じて追加
    };

    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(40)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('TOP COLORS (LAST MONTH)', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Colors.grey, letterSpacing: 2)),
          const SizedBox(height: 24),
          ...sorted.take(5).map((entry) => Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Row(
              children: [
                SizedBox(
                  width: 120,
                  child: Text(entry.key, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                ),
                Expanded(
                  child: Container(
                    height: 18,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      gradient: LinearGradient(
                        colors: colorGradients[entry.key] ?? [Colors.blue.shade100, Colors.blue.shade50],
                      ),
                    ),
                    width: 180 * (entry.value / (sorted.first.value == 0 ? 1 : sorted.first.value)),
                  ),
                ),
                const SizedBox(width: 12),
                Text('${entry.value}回', style: const TextStyle(fontSize: 12, color: Colors.grey)),
              ],
            ),
          )),
        ],
      ),
    );
  }


  Widget _buildFooter() {
    return const Center(
      child: Text(
        'CLOSET ANALYTICS — OPTIMIZING YOUR WARDROBE EFFICIENCY',
        style: TextStyle(fontSize: 8, fontWeight: FontWeight.bold, color: Colors.grey, letterSpacing: 2),
      ),
    );
  }
}

// --- Ranking Card Component (70% Image on top, 30% Text on bottom) ---

class RankingCard extends StatelessWidget {
  final String index;
  final String name;
  final String rate; // このコンテキストでは "last worn days"
  final String desc;
  final String category;
  final String imageUrl;

  const RankingCard({
    super.key,
    required this.index,
    required this.name,
    required this.rate,
    required this.desc,
    required this.category,
    required this.imageUrl,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(48),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 20,
            offset: const Offset(0, 10),
          )
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 上部セクション: ビジュアル (70%)
          Expanded(
            flex: 7,
            child: Stack(
              fit: StackFit.expand,
              children: [
                Image.network(imageUrl, fit: BoxFit.cover),
                // AI バウンディングボックスのオーバーレイ
                Positioned(
                  top: 30,
                  left: 30,
                  right: 30,
                  bottom: 30,
                  child: Container(
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.5),
                        width: 1,
                      ),
                    ),
                    child: Stack(
                      children: [
                        Positioned(
                          top: 10,
                          left: 10,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.9),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 6,
                                  height: 6,
                                  decoration: const BoxDecoration(
                                    color: Colors.red,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  category.toUpperCase(),
                                  style: const TextStyle(
                                    fontSize: 8,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                _buildCorner(Alignment.topLeft),
                _buildCorner(Alignment.topRight),
                _buildCorner(Alignment.bottomLeft),
                _buildCorner(Alignment.bottomRight),
              ],
            ),
          ),
          
          // 下部セクション: テキスト情報 (30%)
          Expanded(
            flex: 3,
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Row(
                    children: [
                      Text(
                        index,
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w900,
                          color: Colors.grey.shade200,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          name,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -0.5,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'LAST WORN',
                            style: TextStyle(
                              fontSize: 8,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey,
                            ),
                          ),
                          Text(
                            rate,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                              color: Color(0xFFD15E5E),
                            ),
                          ),
                        ],
                      ),
                      const Icon(Icons.warning_amber_rounded, color: Colors.red, size: 24),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCorner(Alignment alignment) {
    return Positioned(
      top: alignment.y < 0 ? 20 : null,
      bottom: alignment.y > 0 ? 20 : null,
      left: alignment.x < 0 ? 20 : null,
      right: alignment.x > 0 ? 20 : null,
      child: Container(
        width: 15,
        height: 15,
        decoration: BoxDecoration(
          border: Border(
            top: alignment.y < 0
                ? const BorderSide(color: Colors.white, width: 2)
                : BorderSide.none,
            bottom: alignment.y > 0
                ? const BorderSide(color: Colors.white, width: 2)
                : BorderSide.none,
            left: alignment.x < 0
                ? const BorderSide(color: Colors.white, width: 2)
                : BorderSide.none,
            right: alignment.x > 0
                ? const BorderSide(color: Colors.white, width: 2)
                : BorderSide.none,
          ),
        ),
      ),
    );
  }
}