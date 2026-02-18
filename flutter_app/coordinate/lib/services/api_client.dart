import '../models/wear_item.dart';
import '../models/wear_log.dart';
import '../models/user.dart';

/// AWS API との通信担当（スタブ）
///
/// 【フェーズ1】ダミーデータを返す（API の代わり）
/// 【フェーズ2】http パッケージ等で実際の AWS API を叩くように差し替え
///
/// 使い方:
///   final client = ApiClient(baseUrl: 'https://xxxxx.execute-api.ap-northeast-1.amazonaws.com');
///   final items = await client.fetchItems(userId);
class ApiClient {
  final String baseUrl;

  ApiClient({this.baseUrl = ''});

  // ============================
  // 服（WearItem）
  // ============================

  /// GET /clothes — 服一覧を取得
  Future<List<WearItem>> fetchItems(String userId) async {
    // 【フェーズ2】実際の API 呼び出しに差し替え
    // final res = await http.get(Uri.parse('$baseUrl/clothes?userId=$userId'));
    // final list = jsonDecode(res.body) as List;
    // return list.map((e) => WearItem.fromMap(e)).toList();

    // フェーズ1: ダミーデータ
    await Future.delayed(const Duration(milliseconds: 300)); // 通信シミュレート
    return _dummyItems.where((i) => i.userId == userId).toList();
  }

  /// POST /clothes — 服を新規登録
  Future<void> postItem(WearItem item) async {
    // 【フェーズ2】実際の API 呼び出しに差し替え
    // await http.post(Uri.parse('$baseUrl/clothes'), body: jsonEncode(item.toMap()));

    await Future.delayed(const Duration(milliseconds: 200));
    // フェーズ1: 何もしない（ローカルだけで完結）
  }

  /// DELETE /clothes/{id} — 服を削除
  Future<void> deleteItem(String itemId) async {
    await Future.delayed(const Duration(milliseconds: 200));
  }

  // ============================
  // 着用ログ（WearLog）
  // ============================

  /// GET /logs — 着用ログ一覧を取得
  Future<List<WearLog>> fetchLogs(String userId) async {
    await Future.delayed(const Duration(milliseconds: 300));
    return _dummyLogs.where((l) => l.userId == userId).toList();
  }

  /// POST /logs — 着用ログを記録
  Future<void> postLog(WearLog log) async {
    await Future.delayed(const Duration(milliseconds: 200));
  }

  /// DELETE /logs/{id} — 着用ログを削除
  Future<void> deleteLog(String logId) async {
    await Future.delayed(const Duration(milliseconds: 200));
  }

  // ============================
  // ユーザー（User）
  // ============================

  /// ログイン中のユーザー情報を取得
  Future<User> fetchCurrentUser(String userId) async {
    await Future.delayed(const Duration(milliseconds: 200));
    return _dummyUser;
  }
}

// ============================================================
// ダミーデータ（フェーズ1用。フェーズ2で削除してOK）
// ============================================================

const _dummyUser =
    User(id: 'u001', name: 'テストユーザー', email: 'test@example.com');

final _dummyItems = [
  WearItem(id: 'i001', userId: 'u001', category: 'コート',         color: '黒',       itemName: 'チェスターコート（黒）',       createdAt: DateTime(2025, 10, 1)),
  WearItem(id: 'i002', userId: 'u001', category: 'コート',         color: '紺',       itemName: 'ステンカラーコート（紺）',     createdAt: DateTime(2025, 10, 1)),
  WearItem(id: 'i003', userId: 'u001', category: 'ニット',         color: '白',       itemName: 'タートルネック（白）',         createdAt: DateTime(2025, 10, 1)),
  WearItem(id: 'i004', userId: 'u001', category: 'ニット',         color: 'ベージュ', itemName: 'Vネックニット（ベージュ）',     createdAt: DateTime(2025, 10, 1)),
  WearItem(id: 'i005', userId: 'u001', category: 'ニット',         color: 'グレー',   itemName: 'クルーネックニット（グレー）', createdAt: DateTime(2025, 10, 1)),
  WearItem(id: 'i006', userId: 'u001', category: 'パーカー',       color: 'グレー',   itemName: 'ジップパーカー（グレー）',     createdAt: DateTime(2025, 10, 1)),
  WearItem(id: 'i007', userId: 'u001', category: 'パーカー',       color: '黒',       itemName: 'プルオーバーパーカー（黒）',   createdAt: DateTime(2025, 10, 1)),
  WearItem(id: 'i008', userId: 'u001', category: 'Tシャツ',        color: '白',       itemName: '無地Tシャツ（白）',           createdAt: DateTime(2025, 10, 1)),
  WearItem(id: 'i009', userId: 'u001', category: 'Tシャツ',        color: '黒',       itemName: 'ロゴTシャツ（黒）',           createdAt: DateTime(2025, 10, 1)),
  WearItem(id: 'i010', userId: 'u001', category: 'Tシャツ',        color: '青',       itemName: 'ボーダーTシャツ（青）',       createdAt: DateTime(2025, 10, 1)),
  WearItem(id: 'i011', userId: 'u001', category: 'シャツ',         color: '青',       itemName: 'オックスフォードシャツ（青）', createdAt: DateTime(2025, 10, 1)),
  WearItem(id: 'i012', userId: 'u001', category: 'シャツ',         color: '白',       itemName: 'リネンシャツ（白）',           createdAt: DateTime(2025, 10, 1)),
  WearItem(id: 'i013', userId: 'u001', category: 'シャツ',         color: 'チェック', itemName: 'チェックシャツ',               createdAt: DateTime(2025, 10, 1)),
  WearItem(id: 'i014', userId: 'u001', category: 'ショートパンツ', color: 'ベージュ', itemName: 'チノショーツ（ベージュ）',     createdAt: DateTime(2025, 10, 1)),
  WearItem(id: 'i015', userId: 'u001', category: 'ショートパンツ', color: '黒',       itemName: 'スウェットショーツ（黒）',     createdAt: DateTime(2025, 10, 1)),
];

final _dummyCreatedAt = DateTime(2025, 1, 1);

final _dummyLogs = [
  WearLog(id: 'l001', userId: 'u001', wearItemId: 'i001', category: 'コート',         color: '黒',       date: DateTime(2025, 12, 3),  createdAt: _dummyCreatedAt),
  WearLog(id: 'l002', userId: 'u001', wearItemId: 'i003', category: 'ニット',         color: '白',       date: DateTime(2025, 12, 10), createdAt: _dummyCreatedAt),
  WearLog(id: 'l003', userId: 'u001', wearItemId: 'i001', category: 'コート',         color: '黒',       date: DateTime(2025, 12, 20), createdAt: _dummyCreatedAt),
  WearLog(id: 'l004', userId: 'u001', wearItemId: 'i006', category: 'パーカー',       color: 'グレー',   date: DateTime(2026, 1, 5),   createdAt: _dummyCreatedAt),
  WearLog(id: 'l005', userId: 'u001', wearItemId: 'i004', category: 'ニット',         color: 'ベージュ', date: DateTime(2026, 1, 12),  createdAt: _dummyCreatedAt),
  WearLog(id: 'l006', userId: 'u001', wearItemId: 'i001', category: 'コート',         color: '黒',       date: DateTime(2026, 1, 25),  createdAt: _dummyCreatedAt),
  WearLog(id: 'l007', userId: 'u001', wearItemId: 'i007', category: 'パーカー',       color: '黒',       date: DateTime(2026, 2, 1),   createdAt: _dummyCreatedAt),
  WearLog(id: 'l008', userId: 'u001', wearItemId: 'i003', category: 'ニット',         color: '白',       date: DateTime(2026, 2, 8),   createdAt: _dummyCreatedAt),
  WearLog(id: 'l009', userId: 'u001', wearItemId: 'i009', category: 'Tシャツ',        color: '黒',       date: DateTime(2025, 3, 22),  createdAt: _dummyCreatedAt),
  WearLog(id: 'l010', userId: 'u001', wearItemId: 'i008', category: 'Tシャツ',        color: '白',       date: DateTime(2025, 4, 10),  createdAt: _dummyCreatedAt),
  WearLog(id: 'l011', userId: 'u001', wearItemId: 'i011', category: 'シャツ',         color: '青',       date: DateTime(2025, 4, 20),  createdAt: _dummyCreatedAt),
  WearLog(id: 'l012', userId: 'u001', wearItemId: 'i006', category: 'パーカー',       color: 'グレー',   date: DateTime(2025, 5, 3),   createdAt: _dummyCreatedAt),
  WearLog(id: 'l013', userId: 'u001', wearItemId: 'i012', category: 'シャツ',         color: '白',       date: DateTime(2025, 5, 15),  createdAt: _dummyCreatedAt),
  WearLog(id: 'l014', userId: 'u001', wearItemId: 'i008', category: 'Tシャツ',        color: '白',       date: DateTime(2025, 6, 5),   createdAt: _dummyCreatedAt),
  WearLog(id: 'l015', userId: 'u001', wearItemId: 'i009', category: 'Tシャツ',        color: '黒',       date: DateTime(2025, 7, 10),  createdAt: _dummyCreatedAt),
  WearLog(id: 'l016', userId: 'u001', wearItemId: 'i008', category: 'Tシャツ',        color: '白',       date: DateTime(2025, 7, 20),  createdAt: _dummyCreatedAt),
  WearLog(id: 'l017', userId: 'u001', wearItemId: 'i014', category: 'ショートパンツ', color: 'ベージュ', date: DateTime(2025, 8, 1),   createdAt: _dummyCreatedAt),
  WearLog(id: 'l018', userId: 'u001', wearItemId: 'i010', category: 'Tシャツ',        color: '青',       date: DateTime(2025, 8, 15),  createdAt: _dummyCreatedAt),
  WearLog(id: 'l019', userId: 'u001', wearItemId: 'i015', category: 'ショートパンツ', color: '黒',       date: DateTime(2025, 8, 25),  createdAt: _dummyCreatedAt),
  WearLog(id: 'l020', userId: 'u001', wearItemId: 'i013', category: 'シャツ',         color: 'チェック', date: DateTime(2025, 9, 8),   createdAt: _dummyCreatedAt),
  WearLog(id: 'l021', userId: 'u001', wearItemId: 'i007', category: 'パーカー',       color: '黒',       date: DateTime(2025, 10, 5),  createdAt: _dummyCreatedAt),
  WearLog(id: 'l022', userId: 'u001', wearItemId: 'i005', category: 'ニット',         color: 'グレー',   date: DateTime(2025, 10, 20), createdAt: _dummyCreatedAt),
  WearLog(id: 'l023', userId: 'u001', wearItemId: 'i006', category: 'パーカー',       color: 'グレー',   date: DateTime(2025, 11, 3),  createdAt: _dummyCreatedAt),
  WearLog(id: 'l024', userId: 'u001', wearItemId: 'i002', category: 'コート',         color: '紺',       date: DateTime(2025, 11, 25), createdAt: _dummyCreatedAt),
];
