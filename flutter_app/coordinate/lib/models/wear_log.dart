/// 着用ログのデータモデル
/// フェーズ2 で DynamoDB のスキーマと合わせる前提の構造。
class WearLog {
  final String id;           // ユニークID（DynamoDB の PK になる想定）
  final String userId;       // ユーザーID（Cognito の sub）
  final String category;     // 服のカテゴリ（Tシャツ, パーカー, etc.）
  final String color;        // 色
  final DateTime date;       // 着用日
  final String? imagePath;   // 服の画像パス（S3 キーまたはローカルパス）
  final String? season;      // 季節（自動算出も可能）
  final String? itemName;    // アイテム名（例：「UNIQLOの白Tシャツ」）

  const WearLog({
    required this.id,
    this.userId = 'dummy-user-001',
    required this.category,
    required this.color,
    required this.date,
    this.imagePath,
    this.season,
    this.itemName,
  });

  /// 月から季節を自動判定
  String get computedSeason => getSeason(date.month);

  /// Map 変換（DynamoDB 保存時に利用する想定）
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'category': category,
      'color': color,
      'date': date.toIso8601String(),
      'imagePath': imagePath,
      'season': season ?? computedSeason,
      'itemName': itemName,
    };
  }

  /// Map からの復元
  factory WearLog.fromMap(Map<String, dynamic> map) {
    return WearLog(
      id: map['id'] as String,
      userId: map['userId'] as String? ?? 'dummy-user-001',
      category: map['category'] as String,
      color: map['color'] as String,
      date: DateTime.parse(map['date'] as String),
      imagePath: map['imagePath'] as String?,
      season: map['season'] as String?,
      itemName: map['itemName'] as String?,
    );
  }
}

// ============================
// 季節判定ヘルパー
// ============================
String getSeason(int month) {
  if (month >= 3 && month <= 5) return '春';
  if (month >= 6 && month <= 8) return '夏';
  if (month >= 9 && month <= 11) return '秋';
  return '冬';
}

// ============================
// ダミーデータ（フェーズ2 で AWS から取得に置き換え）
// ============================
final List<WearLog> dummyWearLogs = [
  // --- 冬（12〜2月） ---
  WearLog(id: 'w001', category: 'コート',       color: '黒',     date: DateTime(2025, 12, 3),  itemName: 'チェスターコート（黒）'),
  WearLog(id: 'w002', category: 'ニット',       color: '白',     date: DateTime(2025, 12, 10), itemName: 'タートルネック（白）'),
  WearLog(id: 'w003', category: 'コート',       color: '黒',     date: DateTime(2025, 12, 20), itemName: 'チェスターコート（黒）'),
  WearLog(id: 'w004', category: 'パーカー',     color: 'グレー', date: DateTime(2026, 1, 5),   itemName: 'ジップパーカー（グレー）'),
  WearLog(id: 'w005', category: 'ニット',       color: 'ベージュ', date: DateTime(2026, 1, 12), itemName: 'Vネックニット（ベージュ）'),
  WearLog(id: 'w006', category: 'コート',       color: '黒',     date: DateTime(2026, 1, 25),  itemName: 'チェスターコート（黒）'),
  WearLog(id: 'w007', category: 'パーカー',     color: '黒',     date: DateTime(2026, 2, 1),   itemName: 'プルオーバーパーカー（黒）'),
  WearLog(id: 'w008', category: 'ニット',       color: '白',     date: DateTime(2026, 2, 8),   itemName: 'タートルネック（白）'),
  // --- 春（3〜5月） ---
  WearLog(id: 'w009', category: 'Tシャツ',      color: '白',     date: DateTime(2025, 4, 10),  itemName: '無地Tシャツ（白）'),
  WearLog(id: 'w010', category: 'シャツ',       color: '青',     date: DateTime(2025, 4, 20),  itemName: 'オックスフォードシャツ（青）'),
  WearLog(id: 'w011', category: 'パーカー',     color: 'グレー', date: DateTime(2025, 5, 3),   itemName: 'ジップパーカー（グレー）'),
  WearLog(id: 'w012', category: 'シャツ',       color: '白',     date: DateTime(2025, 5, 15),  itemName: 'リネンシャツ（白）'),
  WearLog(id: 'w013', category: 'Tシャツ',      color: '黒',     date: DateTime(2025, 3, 22),  itemName: 'ロゴTシャツ（黒）'),
  // --- 夏（6〜8月） ---
  WearLog(id: 'w014', category: 'Tシャツ',      color: '白',     date: DateTime(2025, 6, 5),   itemName: '無地Tシャツ（白）'),
  WearLog(id: 'w015', category: 'Tシャツ',      color: '黒',     date: DateTime(2025, 7, 10),  itemName: 'ロゴTシャツ（黒）'),
  WearLog(id: 'w016', category: 'Tシャツ',      color: '白',     date: DateTime(2025, 7, 20),  itemName: '無地Tシャツ（白）'),
  WearLog(id: 'w017', category: 'ショートパンツ', color: 'ベージュ', date: DateTime(2025, 8, 1), itemName: 'チノショーツ（ベージュ）'),
  WearLog(id: 'w018', category: 'Tシャツ',      color: '青',     date: DateTime(2025, 8, 15),  itemName: 'ボーダーTシャツ（青）'),
  WearLog(id: 'w019', category: 'ショートパンツ', color: '黒',   date: DateTime(2025, 8, 25),  itemName: 'スウェットショーツ（黒）'),
  // --- 秋（9〜11月） ---
  WearLog(id: 'w020', category: 'シャツ',       color: 'チェック', date: DateTime(2025, 9, 8),  itemName: 'チェックシャツ'),
  WearLog(id: 'w021', category: 'パーカー',     color: '黒',     date: DateTime(2025, 10, 5),  itemName: 'プルオーバーパーカー（黒）'),
  WearLog(id: 'w022', category: 'ニット',       color: 'グレー', date: DateTime(2025, 10, 20), itemName: 'クルーネックニット（グレー）'),
  WearLog(id: 'w023', category: 'パーカー',     color: 'グレー', date: DateTime(2025, 11, 3),  itemName: 'ジップパーカー（グレー）'),
  WearLog(id: 'w024', category: 'コート',       color: '紺',     date: DateTime(2025, 11, 25), itemName: 'ステンカラーコート（紺）'),
];
