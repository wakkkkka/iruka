/// クローゼットの中の服1着分を表す「箱」
///
/// フェーズ1: ダミーデータで使う
/// フェーズ2: AWS DynamoDB の Clothes テーブルに対応
class WearItem {
  final String id;         // 服のユニークID
  final String userId;     // 誰の服か
  final String category;   // "Tシャツ", "パーカー", "コート" etc.
  final String color;      // "白", "黒", "グレー" etc.
  final String itemName;   // "お気に入りの青シャツ" など
  final List<String> tags; // AIが検出したラベル + ユーザー追加タグ
  final String? imageUrl;  // 画像のURL（S3キー or ローカルパス）
  final DateTime createdAt;

  const WearItem({
    required this.id,
    required this.userId,
    required this.category,
    required this.color,
    required this.itemName,
    this.tags = const [],
    this.imageUrl,
    required this.createdAt,
  });

  /// Map に変換（フェーズ2で JSON⇔変換に使う）
  Map<String, dynamic> toMap() => {
        'id': id,
        'userId': userId,
        'category': category,
        'color': color,
        'itemName': itemName,
        'tags': tags,
        'imageUrl': imageUrl,
        'createdAt': createdAt.toIso8601String(),
      };

  /// Map から生成
  factory WearItem.fromMap(Map<String, dynamic> m) => WearItem(
        id: m['id'] as String,
        userId: m['userId'] as String,
        category: m['category'] as String,
        color: m['color'] as String,
        itemName: m['itemName'] as String,
        tags: List<String>.unmodifiable(m['tags'] ?? []),
        imageUrl: m['imageUrl'] as String?,
        createdAt: DateTime.parse(m['createdAt'] as String),
      );
}
