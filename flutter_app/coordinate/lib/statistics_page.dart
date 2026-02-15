import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

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
class StatisticsPage extends StatelessWidget {
  const StatisticsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('統計'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ---------- サマリーカード ----------
            _buildSummaryCards(),
            const SizedBox(height: 24),

            // ---------- カテゴリ別 円グラフ ----------
            const Text(
              'カテゴリ別 着用回数',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 240,
              child: _buildPieChart(),
            ),
            const SizedBox(height: 8),
            _buildPieLegend(),
            const SizedBox(height: 32),

            // ---------- 季節別 棒グラフ ----------
            const Text(
              '季節別 着用回数',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 240,
              child: _buildBarChart(),
            ),
            const SizedBox(height: 32),

            // ---------- 色別 棒グラフ ----------
            const Text(
              'カラー別 着用回数',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 240,
              child: _buildColorBarChart(),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  // ============================
  // サマリーカード
  // ============================
  Widget _buildSummaryCards() {
    final totalWears = dummyWearLogs.length;
    final categories =
        dummyWearLogs.map((e) => e.category).toSet().length;
    final currentSeason = getSeason(DateTime.now().month);

    return Row(
      children: [
        Expanded(
          child: _summaryCard('総着用回数', '$totalWears 回', Icons.checkroom),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _summaryCard('カテゴリ数', '$categories 種類', Icons.category),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _summaryCard('現在の季節', currentSeason, Icons.wb_sunny),
        ),
      ],
    );
  }

  Widget _summaryCard(String label, String value, IconData icon) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
        child: Column(
          children: [
            Icon(icon, size: 28, color: Colors.deepPurple),
            const SizedBox(height: 8),
            Text(value,
                style:
                    const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text(label,
                style: const TextStyle(fontSize: 12, color: Colors.grey)),
          ],
        ),
      ),
    );
  }

  // ============================
  // カテゴリ別 円グラフ
  // ============================
  /// カテゴリ → カウントの Map を作成
  Map<String, int> _categoryCount() {
    final map = <String, int>{};
    for (final log in dummyWearLogs) {
      map[log.category] = (map[log.category] ?? 0) + 1;
    }
    return map;
  }

  /// カテゴリごとの色
  static const _categoryColors = <String, Color>{
    'Tシャツ': Color(0xFFFF6384),
    'シャツ': Color(0xFF36A2EB),
    'パーカー': Color(0xFFFFCE56),
    'ニット': Color(0xFF4BC0C0),
    'コート': Color(0xFF9966FF),
    'ショートパンツ': Color(0xFFFF9F40),
  };

  Color _colorForCategory(String cat) {
    return _categoryColors[cat] ?? Colors.grey;
  }

  Widget _buildPieChart() {
    final counts = _categoryCount();
    final total = counts.values.fold(0, (a, b) => a + b);

    final sections = counts.entries.map((e) {
      final pct = (e.value / total * 100).toStringAsFixed(1);
      return PieChartSectionData(
        color: _colorForCategory(e.key),
        value: e.value.toDouble(),
        title: '$pct%',
        radius: 60,
        titleStyle: const TextStyle(
            fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
      );
    }).toList();

    return PieChart(
      PieChartData(
        sections: sections,
        centerSpaceRadius: 40,
        sectionsSpace: 2,
      ),
    );
  }

  Widget _buildPieLegend() {
    final counts = _categoryCount();
    return Wrap(
      spacing: 16,
      runSpacing: 8,
      children: counts.entries.map((e) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
                width: 14,
                height: 14,
                decoration: BoxDecoration(
                  color: _colorForCategory(e.key),
                  shape: BoxShape.circle,
                )),
            const SizedBox(width: 4),
            Text('${e.key}（${e.value}回）', style: const TextStyle(fontSize: 13)),
          ],
        );
      }).toList(),
    );
  }

  // ============================
  // 季節別 棒グラフ
  // ============================
  Map<String, int> _seasonCount() {
    final map = <String, int>{'春': 0, '夏': 0, '秋': 0, '冬': 0};
    for (final log in dummyWearLogs) {
      final s = getSeason(log.date.month);
      map[s] = (map[s] ?? 0) + 1;
    }
    return map;
  }

  static const _seasonColors = {
    '春': Color(0xFFFF9FCE),
    '夏': Color(0xFF36A2EB),
    '秋': Color(0xFFFFCE56),
    '冬': Color(0xFF9966FF),
  };

  Widget _buildBarChart() {
    final counts = _seasonCount();
    final seasons = ['春', '夏', '秋', '冬'];

    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: (counts.values.fold(0, (a, b) => a > b ? a : b) + 2).toDouble(),
        barTouchData: BarTouchData(
          touchTooltipData: BarTouchTooltipData(),
        ),
        titlesData: FlTitlesData(
          show: true,
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                final idx = value.toInt();
                if (idx < 0 || idx >= seasons.length) return const SizedBox();
                return Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(seasons[idx],
                      style: const TextStyle(
                          fontSize: 14, fontWeight: FontWeight.bold)),
                );
              },
              reservedSize: 32,
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 32,
              interval: 2,
              getTitlesWidget: (value, meta) {
                return Text('${value.toInt()}',
                    style: const TextStyle(fontSize: 12));
              },
            ),
          ),
          topTitles:
              AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles:
              AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        borderData: FlBorderData(show: false),
        barGroups: List.generate(seasons.length, (i) {
          return BarChartGroupData(
            x: i,
            barRods: [
              BarChartRodData(
                toY: counts[seasons[i]]!.toDouble(),
                color: _seasonColors[seasons[i]],
                width: 28,
                borderRadius: BorderRadius.circular(6),
              ),
            ],
          );
        }),
      ),
    );
  }

  // ============================
  // カラー別 棒グラフ
  // ============================
  Map<String, int> _colorCount() {
    final map = <String, int>{};
    for (final log in dummyWearLogs) {
      map[log.color] = (map[log.color] ?? 0) + 1;
    }
    return map;
  }

  Widget _buildColorBarChart() {
    final counts = _colorCount();
    final colors = counts.keys.toList();

    // 色名 → 表示色
    const colorMap = <String, Color>{
      '白': Color(0xFFBDBDBD),
      '黒': Color(0xFF424242),
      'グレー': Color(0xFF9E9E9E),
      '青': Color(0xFF42A5F5),
      'ベージュ': Color(0xFFD7CCC8),
      '紺': Color(0xFF283593),
      'チェック': Color(0xFFFF7043),
    };

    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: (counts.values.fold(0, (a, b) => a > b ? a : b) + 2).toDouble(),
        barTouchData: BarTouchData(
          touchTooltipData: BarTouchTooltipData(),
        ),
        titlesData: FlTitlesData(
          show: true,
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                final idx = value.toInt();
                if (idx < 0 || idx >= colors.length) return const SizedBox();
                return Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(colors[idx],
                      style: const TextStyle(fontSize: 11)),
                );
              },
              reservedSize: 32,
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 28,
              interval: 1,
              getTitlesWidget: (value, meta) {
                return Text('${value.toInt()}',
                    style: const TextStyle(fontSize: 12));
              },
            ),
          ),
          topTitles:
              AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles:
              AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        borderData: FlBorderData(show: false),
        barGroups: List.generate(colors.length, (i) {
          return BarChartGroupData(
            x: i,
            barRods: [
              BarChartRodData(
                toY: counts[colors[i]]!.toDouble(),
                color: colorMap[colors[i]] ?? Colors.deepPurple,
                width: 22,
                borderRadius: BorderRadius.circular(6),
              ),
            ],
          );
        }),
      ),
    );
  }
}
