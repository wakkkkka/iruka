/// 「いつ何を着たか」の記録を入れる「箱」
///
/// フェーズ1: ダミーデータで使う
/// フェーズ2: AWS DynamoDB の UsageLogs テーブルに対応
class WearLog {
  final String id;          // ログのユニークID
  final String userId;      // 誰の記録か
  final String wearItemId;  // 着た服のID（WearItem.id と紐づく）
  final String category;    // 服のカテゴリ（表示用にコピー）
  final String color;       // 服の色（表示用にコピー）
  final DateTime date;      // 着用日
  final String? selfieUrl;  // 自撮り画像のURL
  final DateTime createdAt;

  const WearLog({
    required this.id,
    required this.userId,
    required this.wearItemId,
    required this.category,
    required this.color,
    required this.date,
    this.selfieUrl,
    required this.createdAt,
  });

  /// 月から季節を自動判定
  String get season {
    final month = date.month;
    if (month >= 3 && month <= 5) return '春';
    if (month >= 6 && month <= 8) return '夏';
    if (month >= 9 && month <= 11) return '秋';
    return '冬';
  }

  /// Map に変換
  Map<String, dynamic> toMap() => {
        'id': id,
        'userId': userId,
        'wearItemId': wearItemId,
        'category': category,
        'color': color,
        'date': date.toIso8601String(),
        'selfieUrl': selfieUrl,
        'createdAt': createdAt.toIso8601String(),
      };

  /// Map から生成
  factory WearLog.fromMap(Map<String, dynamic> m) => WearLog(
        id: m['id'] as String,
        userId: m['userId'] as String,
        wearItemId: m['wearItemId'] as String,
        category: m['category'] as String,
        color: m['color'] as String,
        date: DateTime.parse(m['date'] as String),
        selfieUrl: m['selfieUrl'] as String?,
        createdAt: DateTime.parse(m['createdAt'] as String),
      );
}
