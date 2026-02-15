import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:provider/provider.dart';
import 'models/wear_log.dart';
import 'providers/wear_log_provider.dart';
import 'utils/statistics_helper.dart';

// ============================
// 統計ページ本体
// ============================
class StatisticsPage extends StatelessWidget {
  const StatisticsPage({super.key});

  @override
  Widget build(BuildContext context) {
    // Provider から最新のログを取得（自動再描画）
    final logs = context.watch<WearLogProvider>().logs;

    return Scaffold(
      appBar: AppBar(
        title: const Text('統計'),
        centerTitle: true,
      ),
      // ====== テスト用 FAB（フェーズ2 で削除）======
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showTestAddDialog(context),
        icon: const Icon(Icons.add),
        label: const Text('テスト追加'),
        backgroundColor: Colors.deepPurple,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ---------- サマリーカード ----------
            _buildSummaryCards(logs),
            const SizedBox(height: 24),

            // ---------- よく着る服ランキング ----------
            const Text(
              '👑 よく着る服 ベスト3',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            _buildRankingSection(logs),
            const SizedBox(height: 32),

            // ---------- カテゴリ別 円グラフ ----------
            const Text(
              'カテゴリ別 着用回数',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 240,
              child: _buildPieChart(logs),
            ),
            const SizedBox(height: 8),
            _buildPieLegend(logs),
            const SizedBox(height: 32),

            // ---------- 季節別 棒グラフ ----------
            const Text(
              '季節別 着用回数',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 240,
              child: _buildBarChart(logs),
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
              child: _buildColorBarChart(logs),
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
  Widget _buildSummaryCards(List<WearLog> logs) {
    final totalWears = logs.length;
    final categories = countUniqueCategories(logs);
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
  // よく着る服ランキング（ベスト3）
  // ============================
  Widget _buildRankingSection(List<WearLog> logs) {
    final ranking = calculateRanking(logs, topN: 3);

    if (ranking.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Center(child: Text('まだ着用データがありません')),
        ),
      );
    }

    return Column(
      children: List.generate(ranking.length, (i) {
        final item = ranking[i];
        return _rankingTile(i + 1, item);
      }),
    );
  }

  Widget _rankingTile(int rank, RankingItem item) {
    // 順位に応じた色
    final Color medalColor;
    switch (rank) {
      case 1:
        medalColor = const Color(0xFFFFD700); // 金
        break;
      case 2:
        medalColor = const Color(0xFFC0C0C0); // 銀
        break;
      case 3:
        medalColor = const Color(0xFFCD7F32); // 銅
        break;
      default:
        medalColor = Colors.grey;
    }

    // カテゴリに応じたアイコン
    final IconData categoryIcon;
    switch (item.category) {
      case 'Tシャツ':
        categoryIcon = Icons.dry_cleaning;
        break;
      case 'パーカー':
        categoryIcon = Icons.checkroom;
        break;
      default:
        categoryIcon = Icons.checkroom;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.emoji_events, color: medalColor, size: 28),
            const SizedBox(width: 8),
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: BorderRadius.circular(8),
              ),
              child: item.imagePath != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.asset(item.imagePath!, fit: BoxFit.cover),
                    )
                  : Icon(categoryIcon, size: 28, color: Colors.grey.shade600),
            ),
          ],
        ),
        title: Text(
          item.itemName,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text('${item.category} / ${item.color}'),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.deepPurple.shade50,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Text(
            '${item.count}回',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.deepPurple.shade700,
              fontSize: 16,
            ),
          ),
        ),
      ),
    );
  }

  // ============================
  // カテゴリ別 円グラフ
  // ============================
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

  Widget _buildPieChart(List<WearLog> logs) {
    final counts = calculateCategoryCounts(logs);
    final total = counts.values.fold(0, (a, b) => a + b);

    if (total == 0) {
      return const Center(child: Text('データなし'));
    }

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

  Widget _buildPieLegend(List<WearLog> logs) {
    final counts = calculateCategoryCounts(logs);
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
            Text('${e.key}（${e.value}回）',
                style: const TextStyle(fontSize: 13)),
          ],
        );
      }).toList(),
    );
  }

  // ============================
  // 季節別 棒グラフ
  // ============================
  static const _seasonColors = {
    '春': Color(0xFFFF9FCE),
    '夏': Color(0xFF36A2EB),
    '秋': Color(0xFFFFCE56),
    '冬': Color(0xFF9966FF),
  };

  Widget _buildBarChart(List<WearLog> logs) {
    final counts = calculateSeasonCounts(logs);
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
  Widget _buildColorBarChart(List<WearLog> logs) {
    final counts = calculateColorCounts(logs);
    final colors = counts.keys.toList();

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

  // ============================
  // テスト用：着用ログ追加ダイアログ（フェーズ2 で削除）
  // ============================
  void _showTestAddDialog(BuildContext context) {
    final categories = ['Tシャツ', 'シャツ', 'パーカー', 'ニット', 'コート', 'ショートパンツ'];
    final colors = ['白', '黒', 'グレー', '青', 'ベージュ', '紺', 'チェック'];

    String selectedCategory = categories.first;
    String selectedColor = colors.first;

    showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('🧪 テスト：着用記録を追加'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<String>(
                    initialValue: selectedCategory,
                    decoration: const InputDecoration(labelText: 'カテゴリ'),
                    items: categories
                        .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                        .toList(),
                    onChanged: (v) {
                      setDialogState(() => selectedCategory = v!);
                    },
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue: selectedColor,
                    decoration: const InputDecoration(labelText: 'カラー'),
                    items: colors
                        .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                        .toList(),
                    onChanged: (v) {
                      setDialogState(() => selectedColor = v!);
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text('キャンセル'),
                ),
                FilledButton(
                  onPressed: () {
                    final provider = context.read<WearLogProvider>();
                    provider.addLog(
                      WearLog(
                        id: provider.generateNextId(),
                        category: selectedCategory,
                        color: selectedColor,
                        date: DateTime.now(),
                        itemName: '$selectedCategory（$selectedColor）',
                      ),
                    );
                    Navigator.pop(dialogContext);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('$selectedCategory（$selectedColor）を追加しました'),
                      ),
                    );
                  },
                  child: const Text('追加'),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
