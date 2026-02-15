import '../models/wear_log.dart';

// ============================
// 集計ヘルパー関数
// フェーズ2 で logs の取得元を AWS に差し替えるだけでOK
// ============================

/// カテゴリ別の着用回数を集計
Map<String, int> calculateCategoryCounts(List<WearLog> logs) {
  final map = <String, int>{};
  for (final log in logs) {
    map[log.category] = (map[log.category] ?? 0) + 1;
  }
  return map;
}

/// 季節別の着用回数を集計
Map<String, int> calculateSeasonCounts(List<WearLog> logs) {
  final map = <String, int>{'春': 0, '夏': 0, '秋': 0, '冬': 0};
  for (final log in logs) {
    final s = log.computedSeason;
    map[s] = (map[s] ?? 0) + 1;
  }
  return map;
}

/// カラー別の着用回数を集計
Map<String, int> calculateColorCounts(List<WearLog> logs) {
  final map = <String, int>{};
  for (final log in logs) {
    map[log.color] = (map[log.color] ?? 0) + 1;
  }
  return map;
}

/// よく着るアイテムのランキングエントリ
class RankingItem {
  final String itemName;
  final String category;
  final String color;
  final int count;
  final String? imagePath;

  const RankingItem({
    required this.itemName,
    required this.category,
    required this.color,
    required this.count,
    this.imagePath,
  });
}

/// よく着るアイテムランキングを算出（上位 [topN] 件）
///
/// itemName でグルーピングし、着用回数が多い順にソート。
List<RankingItem> calculateRanking(List<WearLog> logs, {int topN = 3}) {
  // itemName ごとにログをまとめる
  final grouped = <String, List<WearLog>>{};
  for (final log in logs) {
    final key = log.itemName ?? '${log.category}（${log.color}）';
    grouped.putIfAbsent(key, () => []).add(log);
  }

  final ranking = grouped.entries.map((e) {
    final sample = e.value.first;
    return RankingItem(
      itemName: e.key,
      category: sample.category,
      color: sample.color,
      count: e.value.length,
      imagePath: sample.imagePath,
    );
  }).toList();

  // 着用回数の多い順にソート
  ranking.sort((a, b) => b.count.compareTo(a.count));

  return ranking.take(topN).toList();
}

/// ユニークなカテゴリ数
int countUniqueCategories(List<WearLog> logs) {
  return logs.map((e) => e.category).toSet().length;
}

/// 指定した季節のログだけに絞り込む
List<WearLog> filterBySeason(List<WearLog> logs, String season) {
  return logs.where((log) => log.computedSeason == season).toList();
}
