import 'package:flutter/foundation.dart' show debugPrint, kDebugMode;
import '../models/wear_item.dart';
import '../models/wear_log.dart';
import '../models/user.dart';
import '../services/local_storage.dart';
import '../services/api_client.dart';

/// データの「仲介役」
///
/// 画面（カレンダー、統計、ホーム等）はここからデータを取る。
/// 画面は「データがローカルか AWS か」を知る必要がない。
///
/// データの流れ:
///   起動時  → ① ローカルから即読み込み → ② API から最新取得 → ③ ローカルも更新
///   追加時  → ① メモリに即反映 → ② ローカルに保存 → ③ API に送信
///   手動更新 → ① API から取得 → ② メモリ + ローカルを更新
class WearRepository {
  final LocalStorage _local = LocalStorage();
  final ApiClient _api = ApiClient();

  // ============================
  // キャッシュ（アプリ内メモリに保存）
  // ============================
  List<WearItem> _items = [];
  List<WearLog> _logs = [];
  User? _currentUser;

  // ============================
  // 画面から使う getter（読み取り専用）
  // ============================
  List<WearItem> get items => List.unmodifiable(_items);
  List<WearLog> get logs => List.unmodifiable(_logs);
  User? get currentUser => _currentUser;

  // ============================
  // 起動時に呼ぶ（ローカル → API の順でデータを読み込む）
  // ============================
  Future<void> fetchAllData({String userId = 'u001'}) async {
    // ① まずローカルから即座に読み込む（高速・オフラインでも動く）
    _items = await _local.loadItems();
    _logs = await _local.loadLogs();
    _currentUser = await _local.loadUser();

    if (kDebugMode) {
      debugPrint('[Repo] ローカルから読み込み: 服${_items.length}着, ログ${_logs.length}件');
    }

    // ② ローカルが空 or 最新が欲しい場合は API から取得
    await refreshFromApi(userId: userId);
  }

  // ============================
  // API から最新データを取得してローカルも更新
  // ============================
  Future<void> refreshFromApi({String userId = 'u001'}) async {
    try {
      final apiItems = await _api.fetchItems(userId);
      final apiLogs = await _api.fetchLogs(userId);
      final apiUser = await _api.fetchCurrentUser(userId);

      // メモリを更新
      _items = apiItems;
      _logs = apiLogs;
      _currentUser = apiUser;

      // ローカルにも保存（次回起動時に即表示できるように）
      await _local.saveItems(_items);
      await _local.saveLogs(_logs);
      await _local.saveUser(apiUser);

      if (kDebugMode) {
        debugPrint('[Repo] API から取得＆ローカル保存完了: 服${_items.length}着, ログ${_logs.length}件');
      }
    } on Exception catch (e) {
      // API エラー時はローカルのデータをそのまま使い続ける
      if (kDebugMode) {
        debugPrint('[Repo] API取得失敗（ローカルデータで続行）: $e');
      }
    }
  }

  // ============================
  // 服を追加する
  // ============================
  Future<void> addItem(WearItem item) async {
    _items.add(item); // ① 画面に即反映（Optimistic UI）
    await _local.saveItems(_items); // ② ローカルに保存

    try {
      await _api.postItem(item); // ③ API に送信
    } on Exception catch (e) {
      if (kDebugMode) {
        debugPrint('[Repo] 服の送信失敗: $e');
      }
    }
  }

  // ============================
  // 着用ログを追加する
  // ============================
  Future<void> addLog(WearLog log) async {
    _logs.add(log); // ① 画面に即反映（Optimistic UI）
    await _local.saveLogs(_logs); // ② ローカルに保存

    try {
      await _api.postLog(log); // ③ API に送信
    } on Exception catch (e) {
      if (kDebugMode) {
        debugPrint('[Repo] ログの送信失敗: $e');
      }
    }
  }

  // ============================
  // 服を削除する
  // ============================
  Future<void> removeItem(String itemId) async {
    _items.removeWhere((i) => i.id == itemId);
    await _local.saveItems(_items);

    try {
      await _api.deleteItem(itemId);
    } on Exception catch (e) {
      if (kDebugMode) {
        debugPrint('[Repo] 服の削除失敗: $e');
      }
    }
  }

  // ============================
  // ログを削除する
  // ============================
  Future<void> removeLog(String logId) async {
    _logs.removeWhere((l) => l.id == logId);
    await _local.saveLogs(_logs);

    try {
      await _api.deleteLog(logId);
    } on Exception catch (e) {
      if (kDebugMode) {
        debugPrint('[Repo] ログの削除失敗: $e');
      }
    }
  }

  // ============================
  // ローカルデータを全消去（ログアウト時）
  // ============================
  Future<void> clearAll() async {
    _items = [];
    _logs = [];
    _currentUser = null;
    await _local.clearAll();
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
      return null;
    }
  }
}
