import '../models/clothing_item.dart';

/// 偽のデータベースクラス（開発用）
/// アプリ全体からアクセスできる静的なデータストア
class MockData {
  // 服のリストを静的に保持
  static final List<ClothingItem> _clothingItems = [
    ClothingItem(
      id: '1',
      imagePath: 'assets/images/dummy.png',
      category: 'トップス',
      color: 'ホワイト',
      thickness: '薄手',
      sleeveLength: '半袖',
      hemLength: 'ミディアム',
      seasons: ['春', '夏'],
      scene: 'カジュアル',
      wearingCount: 5,
    ),
    ClothingItem(
      id: '2',
      imagePath: 'assets/images/dummy.png',
      category: 'トップス',
      color: 'ブラック',
      thickness: '普通',
      sleeveLength: '長袖',
      hemLength: 'ミディアム',
      seasons: ['秋', '冬'],
      scene: 'きれいめ',
      wearingCount: 12,
    ),
    ClothingItem(
      id: '3',
      imagePath: 'assets/images/dummy.png',
      category: 'ボトムス',
      color: 'ネイビー',
      thickness: '普通',
      sleeveLength: 'ノースリーブ',
      hemLength: 'フルレングス',
      seasons: ['春', '秋'],
      scene: 'カジュアル',
      wearingCount: 8,
    ),
    ClothingItem(
      id: '4',
      imagePath: 'assets/images/dummy.png',
      category: 'ワンピース',
      color: 'ピンク',
      thickness: '薄手',
      sleeveLength: 'ノースリーブ',
      hemLength: 'ロング',
      seasons: ['春', '夏'],
      scene: 'きれいめ',
      wearingCount: 3,
    ),
    ClothingItem(
      id: '5',
      imagePath: 'assets/images/dummy.png',
      category: 'アウター',
      color: 'グレー',
      thickness: '厚手',
      sleeveLength: '長袖',
      hemLength: 'ミディアム',
      seasons: ['秋', '冬'],
      scene: 'カジュアル',
      wearingCount: 15,
    ),
  ];

  /// 全ての服データを取得
  static List<ClothingItem> getAllItems() {
    return List.unmodifiable(_clothingItems);
  }

  /// 服を追加
  static void addClothingItem(ClothingItem item) {
    _clothingItems.add(item);
  }

  /// 服を削除（IDで指定）
  static void removeClothingItem(String id) {
    _clothingItems.removeWhere((item) => item.id == id);
  }

  /// 特定の服を取得（IDで指定）
  static ClothingItem? getItemById(String id) {
    try {
      return _clothingItems.firstWhere((item) => item.id == id);
    } catch (e) {
      return null;
    }
  }

  /// カテゴリでフィルタリング
  static List<ClothingItem> getItemsByCategory(String category) {
    return _clothingItems.where((item) => item.category == category).toList();
  }

  /// データベースをリセット（初期データに戻す）
  static void reset() {
    _clothingItems.clear();
    _clothingItems.addAll([
      ClothingItem(
        id: '1',
        imagePath: 'assets/images/dummy.png',
        category: 'トップス',
        color: 'ホワイト',
        thickness: '薄手',
        sleeveLength: '半袖',
        hemLength: 'ミディアム',
        seasons: ['春', '夏'],
        scene: 'カジュアル',
        wearingCount: 5,
      ),
      ClothingItem(
        id: '2',
        imagePath: 'assets/images/dummy.png',
        category: 'トップス',
        color: 'ブラック',
        thickness: '普通',
        sleeveLength: '長袖',
        hemLength: 'ミディアム',
        seasons: ['秋', '冬'],
        scene: 'きれいめ',
        wearingCount: 12,
      ),
      ClothingItem(
        id: '3',
        imagePath: 'assets/images/dummy.png',
        category: 'ボトムス',
        color: 'ネイビー',
        thickness: '普通',
        sleeveLength: 'ノースリーブ',
        hemLength: 'フルレングス',
        seasons: ['春', '秋'],
        scene: 'カジュアル',
        wearingCount: 8,
      ),
      ClothingItem(
        id: '4',
        imagePath: 'assets/images/dummy.png',
        category: 'ワンピース',
        color: 'ピンク',
        thickness: '薄手',
        sleeveLength: 'ノースリーブ',
        hemLength: 'ロング',
        seasons: ['春', '夏'],
        scene: 'きれいめ',
        wearingCount: 3,
      ),
      ClothingItem(
        id: '5',
        imagePath: 'assets/images/dummy.png',
        category: 'アウター',
        color: 'グレー',
        thickness: '厚手',
        sleeveLength: '長袖',
        hemLength: 'ミディアム',
        seasons: ['秋', '冬'],
        scene: 'カジュアル',
        wearingCount: 15,
      ),
    ]);
  }
}
