/// 服のデータを管理するモデルクラス
class ClothingItem {
  final String id;
  final String imagePath;
  final String category; // 大カテゴリ：トップス、ボトムスなど
  final String color; // カラー：ホワイト、ブラックなど
  final String thickness; // 厚さ：薄手、普通、厚手
  final String sleeveLength; // 袖の長さ：半袖、長袖など
  final String hemLength; // 裾の長さ：ショート、フルレングスなど
  final List<String> seasons; // 春、夏、秋、冬を複数選択可能
  final String scene; // シーン：カジュアル、きれいめなど
  final int wearingCount; // 着用回数

  ClothingItem({
    required this.id,
    required this.imagePath,
    required this.category,
    required this.color,
    required this.thickness,
    required this.sleeveLength,
    required this.hemLength,
    required this.seasons,
    required this.scene,
    this.wearingCount = 0,
  });

  /// MapからClothingItemオブジェクトを生成
  factory ClothingItem.fromMap(Map<String, dynamic> map) {
    return ClothingItem(
      id: map['id'] as String,
      imagePath: map['imagePath'] as String,
      category: map['category'] as String,
      color: map['color'] as String,
      thickness: map['thickness'] as String,
      sleeveLength: map['sleeveLength'] as String,
      hemLength: map['hemLength'] as String,
      seasons: List<String>.from(map['seasons'] as List),
      scene: map['scene'] as String,
      wearingCount: map['wearingCount'] as int? ?? 0,
    );
  }

  /// ClothingItemオブジェクトをMapに変換
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'imagePath': imagePath,
      'category': category,
      'color': color,
      'thickness': thickness,
      'sleeveLength': sleeveLength,
      'hemLength': hemLength,
      'seasons': seasons,
      'scene': scene,
      'wearingCount': wearingCount,
    };
  }

  /// copyWithメソッド（オブジェクトの一部を変更した新しいインスタンスを作成）
  ClothingItem copyWith({
    String? id,
    String? imagePath,
    String? category,
    String? color,
    String? thickness,
    String? sleeveLength,
    String? hemLength,
    List<String>? seasons,
    String? scene,
    int? wearingCount,
  }) {
    return ClothingItem(
      id: id ?? this.id,
      imagePath: imagePath ?? this.imagePath,
      category: category ?? this.category,
      color: color ?? this.color,
      thickness: thickness ?? this.thickness,
      sleeveLength: sleeveLength ?? this.sleeveLength,
      hemLength: hemLength ?? this.hemLength,
      seasons: seasons ?? this.seasons,
      scene: scene ?? this.scene,
      wearingCount: wearingCount ?? this.wearingCount,
    );
  }
}

/// 選択肢の定数クラス
class ClothingOptions {
  // 大カテゴリ
  static const List<String> categories = [
    'トップス',
    'ボトムス',
    'アウター',
    'ワンピース',
    'シューズ',
    'その他',
  ];

  // カラー
  static const List<String> colors = [
    'ホワイト',
    'ブラック',
    'グレー',
    'ブラウン',
    'ベージュ',
    'レッド',
    'ピンク',
    'オレンジ',
    'イエロー',
    'グリーン',
    'ブルー',
    'ネイビー',
    'パープル',
  ];

  // 厚さ
  static const List<String> thicknesses = ['薄手', '普通', '厚手'];

  // 袖の長さ
  static const List<String> sleeveLengths = ['ノースリーブ', '半袖', '七分袖', '長袖'];

  // 裾の長さ
  static const List<String> hemLengths = ['ショート', 'ミディアム', 'ロング', 'フルレングス'];

  // シーズン
  static const List<String> seasons = ['春', '夏', '秋', '冬'];

  // シーン
  static const List<String> scenes = [
    'カジュアル',
    'きれいめ',
    'フォーマル',
    'スポーツ',
    'リラックス',
  ];
}
