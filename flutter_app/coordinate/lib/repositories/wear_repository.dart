import '../models/wear_item.dart';
import '../models/wear_log.dart';
import '../models/user.dart';

/// データの「仲介役」
///
/// 画面（カレンダー、統計、ホーム等）はここからデータを取る。
/// 画面は「データがダミーか AWS か」を知る必要がない。
///
/// 【フェーズ1】ダミーデータを返す
/// 【フェーズ2】fetchAllData() の中身を AWS API 呼び出しに差し替えるだけ！
class WearRepository {
  // ============================
  // キャッシュ（アプリ内メモリに保存）
  // ============================
  List<WearItem> _items = [];
  List<WearLog> _logs = [];
  User? _currentUser;

  // ============================
  // 画面から使う getter
  // ============================
  List<WearItem> get items => List.unmodifiable(_items);
  List<WearLog> get logs => List.unmodifiable(_logs);
  User? get currentUser => _currentUser;

  // ============================
  // 起動時に呼ぶ（データを全部読み込む）
  // ============================
  Future<void> fetchAllData() async {
    _currentUser = _dummyUser;
    _items = _dummyItems;
    _logs = _dummyLogs;

    // 【フェーズ2】ここを AWS API に差し替える
    // _items = await ApiClient.getClothes();
    // _logs = await ApiClient.getLogs();
  }

  // ============================
  // 服を追加する
  // ============================
  Future<void> addItem(WearItem item) async {
    _items.add(item); // 画面に即反映（Optimistic UI）

    // 【フェーズ2】裏で AWS に送信
    // await ApiClient.postClothes(item);
  }

  // ============================
  // 着用ログを追加する
  // ============================
  Future<void> addLog(WearLog log) async {
    _logs.add(log); // 画面に即反映（Optimistic UI）

    // 【フェーズ2】裏で AWS に送信
    // await ApiClient.postLog(log);
  }

  // ============================
  // 便利メソッド
  // ============================

  /// 指定した日付の着用ログを取得
  List<WearLog> getLogsByDate(DateTime date) {
    return _logs.where((log) =>
        log.date.year == date.year &&
        log.date.month == date.month &&
        log.date.day == date.day).toList();
  }

  /// 指定した月の着用ログを取得
  List<WearLog> getLogsByMonth(int year, int month) {
    return _logs.where((log) =>
        log.date.year == year && log.date.month == month).toList();
  }

  /// WearItem の ID から服を取得
  WearItem? getItemById(String id) {
    try {
      return _items.firstWhere((item) => item.id == id);
    } on StateError {
      // 該当するアイテムが見つからなかった場合は null を返す
      return null;
    }
  }
}

// ============================================================
// ダミーデータ（フェーズ1用。フェーズ2で削除してOK）
// ============================================================

const _dummyUser = User(id: 'u001', name: 'テストユーザー', email: 'test@example.com');

final _dummyItems = [
  WearItem(id: 'i001', userId: 'u001', category: 'コート',       color: '黒',       itemName: 'チェスターコート（黒）',       createdAt: DateTime(2025, 10, 1)),
  WearItem(id: 'i002', userId: 'u001', category: 'コート',       color: '紺',       itemName: 'ステンカラーコート（紺）',     createdAt: DateTime(2025, 10, 1)),
  WearItem(id: 'i003', userId: 'u001', category: 'ニット',       color: '白',       itemName: 'タートルネック（白）',         createdAt: DateTime(2025, 10, 1)),
  WearItem(id: 'i004', userId: 'u001', category: 'ニット',       color: 'ベージュ', itemName: 'Vネックニット（ベージュ）',     createdAt: DateTime(2025, 10, 1)),
  WearItem(id: 'i005', userId: 'u001', category: 'ニット',       color: 'グレー',   itemName: 'クルーネックニット（グレー）', createdAt: DateTime(2025, 10, 1)),
  WearItem(id: 'i006', userId: 'u001', category: 'パーカー',     color: 'グレー',   itemName: 'ジップパーカー（グレー）',     createdAt: DateTime(2025, 10, 1)),
  WearItem(id: 'i007', userId: 'u001', category: 'パーカー',     color: '黒',       itemName: 'プルオーバーパーカー（黒）',   createdAt: DateTime(2025, 10, 1)),
  WearItem(id: 'i008', userId: 'u001', category: 'Tシャツ',      color: '白',       itemName: '無地Tシャツ（白）',           createdAt: DateTime(2025, 10, 1)),
  WearItem(id: 'i009', userId: 'u001', category: 'Tシャツ',      color: '黒',       itemName: 'ロゴTシャツ（黒）',           createdAt: DateTime(2025, 10, 1)),
  WearItem(id: 'i010', userId: 'u001', category: 'Tシャツ',      color: '青',       itemName: 'ボーダーTシャツ（青）',       createdAt: DateTime(2025, 10, 1)),
  WearItem(id: 'i011', userId: 'u001', category: 'シャツ',       color: '青',       itemName: 'オックスフォードシャツ（青）', createdAt: DateTime(2025, 10, 1)),
  WearItem(id: 'i012', userId: 'u001', category: 'シャツ',       color: '白',       itemName: 'リネンシャツ（白）',           createdAt: DateTime(2025, 10, 1)),
  WearItem(id: 'i013', userId: 'u001', category: 'シャツ',       color: 'チェック', itemName: 'チェックシャツ',               createdAt: DateTime(2025, 10, 1)),
  WearItem(id: 'i014', userId: 'u001', category: 'ショートパンツ', color: 'ベージュ', itemName: 'チノショーツ（ベージュ）',   createdAt: DateTime(2025, 10, 1)),
  WearItem(id: 'i015', userId: 'u001', category: 'ショートパンツ', color: '黒',     itemName: 'スウェットショーツ（黒）',     createdAt: DateTime(2025, 10, 1)),
];

final _dummyCreatedAt = DateTime(2025, 1, 1);

final _dummyLogs = [
  // --- 冬（12〜2月） ---
  WearLog(id: 'l001', userId: 'u001', wearItemId: 'i001', category: 'コート',   color: '黒',       date: DateTime(2025, 12, 3),  createdAt: _dummyCreatedAt),
  WearLog(id: 'l002', userId: 'u001', wearItemId: 'i003', category: 'ニット',   color: '白',       date: DateTime(2025, 12, 10), createdAt: _dummyCreatedAt),
  WearLog(id: 'l003', userId: 'u001', wearItemId: 'i001', category: 'コート',   color: '黒',       date: DateTime(2025, 12, 20), createdAt: _dummyCreatedAt),
  WearLog(id: 'l004', userId: 'u001', wearItemId: 'i006', category: 'パーカー', color: 'グレー',   date: DateTime(2026, 1, 5),   createdAt: _dummyCreatedAt),
  WearLog(id: 'l005', userId: 'u001', wearItemId: 'i004', category: 'ニット',   color: 'ベージュ', date: DateTime(2026, 1, 12),  createdAt: _dummyCreatedAt),
  WearLog(id: 'l006', userId: 'u001', wearItemId: 'i001', category: 'コート',   color: '黒',       date: DateTime(2026, 1, 25),  createdAt: _dummyCreatedAt),
  WearLog(id: 'l007', userId: 'u001', wearItemId: 'i007', category: 'パーカー', color: '黒',       date: DateTime(2026, 2, 1),   createdAt: _dummyCreatedAt),
  WearLog(id: 'l008', userId: 'u001', wearItemId: 'i003', category: 'ニット',   color: '白',       date: DateTime(2026, 2, 8),   createdAt: _dummyCreatedAt),
  // --- 春（3〜5月） ---
  WearLog(id: 'l009', userId: 'u001', wearItemId: 'i009', category: 'Tシャツ',  color: '黒',       date: DateTime(2025, 3, 22),  createdAt: _dummyCreatedAt),
  WearLog(id: 'l010', userId: 'u001', wearItemId: 'i008', category: 'Tシャツ',  color: '白',       date: DateTime(2025, 4, 10),  createdAt: _dummyCreatedAt),
  WearLog(id: 'l011', userId: 'u001', wearItemId: 'i011', category: 'シャツ',   color: '青',       date: DateTime(2025, 4, 20),  createdAt: _dummyCreatedAt),
  WearLog(id: 'l012', userId: 'u001', wearItemId: 'i006', category: 'パーカー', color: 'グレー',   date: DateTime(2025, 5, 3),   createdAt: _dummyCreatedAt),
  WearLog(id: 'l013', userId: 'u001', wearItemId: 'i012', category: 'シャツ',   color: '白',       date: DateTime(2025, 5, 15),  createdAt: _dummyCreatedAt),
  // --- 夏（6〜8月） ---
  WearLog(id: 'l014', userId: 'u001', wearItemId: 'i008', category: 'Tシャツ',        color: '白',       date: DateTime(2025, 6, 5),  createdAt: _dummyCreatedAt),
  WearLog(id: 'l015', userId: 'u001', wearItemId: 'i009', category: 'Tシャツ',        color: '黒',       date: DateTime(2025, 7, 10), createdAt: _dummyCreatedAt),
  WearLog(id: 'l016', userId: 'u001', wearItemId: 'i008', category: 'Tシャツ',        color: '白',       date: DateTime(2025, 7, 20), createdAt: _dummyCreatedAt),
  WearLog(id: 'l017', userId: 'u001', wearItemId: 'i014', category: 'ショートパンツ', color: 'ベージュ', date: DateTime(2025, 8, 1),  createdAt: _dummyCreatedAt),
  WearLog(id: 'l018', userId: 'u001', wearItemId: 'i010', category: 'Tシャツ',        color: '青',       date: DateTime(2025, 8, 15), createdAt: _dummyCreatedAt),
  WearLog(id: 'l019', userId: 'u001', wearItemId: 'i015', category: 'ショートパンツ', color: '黒',       date: DateTime(2025, 8, 25), createdAt: _dummyCreatedAt),
  // --- 秋（9〜11月） ---
  WearLog(id: 'l020', userId: 'u001', wearItemId: 'i013', category: 'シャツ',   color: 'チェック', date: DateTime(2025, 9, 8),   createdAt: _dummyCreatedAt),
  WearLog(id: 'l021', userId: 'u001', wearItemId: 'i007', category: 'パーカー', color: '黒',       date: DateTime(2025, 10, 5),  createdAt: _dummyCreatedAt),
  WearLog(id: 'l022', userId: 'u001', wearItemId: 'i005', category: 'ニット',   color: 'グレー',   date: DateTime(2025, 10, 20), createdAt: _dummyCreatedAt),
  WearLog(id: 'l023', userId: 'u001', wearItemId: 'i006', category: 'パーカー', color: 'グレー',   date: DateTime(2025, 11, 3),  createdAt: _dummyCreatedAt),
  WearLog(id: 'l024', userId: 'u001', wearItemId: 'i002', category: 'コート',   color: '紺',       date: DateTime(2025, 11, 25), createdAt: _dummyCreatedAt),
];
