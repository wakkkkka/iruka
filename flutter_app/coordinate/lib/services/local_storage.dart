import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/wear_item.dart';
import '../models/wear_log.dart';
import '../models/user.dart';

/// ローカル保存担当
///
/// SharedPreferences を使い、服・ログ・ユーザー情報を
/// JSON 形式で端末に永続化する。
///
/// アプリを閉じて再起動しても前回のデータが残る。
class LocalStorage {
  static const _keyItems = 'cached_items';
  static const _keyLogs = 'cached_logs';
  static const _keyUser = 'cached_user';

  // ============================
  // 服（WearItem）
  // ============================

  /// ローカルに保存された服一覧を読み込む
  Future<List<WearItem>> loadItems() async {
    final prefs = await SharedPreferences.getInstance();
    final json = prefs.getString(_keyItems);
    if (json == null) return [];

    final list = jsonDecode(json) as List;
    return list
        .map((e) => WearItem.fromMap(e as Map<String, dynamic>))
        .toList();
  }

  /// 服一覧をローカルに保存する
  Future<void> saveItems(List<WearItem> items) async {
    final prefs = await SharedPreferences.getInstance();
    final json = jsonEncode(items.map((e) => e.toMap()).toList());
    await prefs.setString(_keyItems, json);
  }

  // ============================
  // 着用ログ（WearLog）
  // ============================

  /// ローカルに保存されたログ一覧を読み込む
  Future<List<WearLog>> loadLogs() async {
    final prefs = await SharedPreferences.getInstance();
    final json = prefs.getString(_keyLogs);
    if (json == null) return [];

    final list = jsonDecode(json) as List;
    return list
        .map((e) => WearLog.fromMap(e as Map<String, dynamic>))
        .toList();
  }

  /// ログ一覧をローカルに保存する
  Future<void> saveLogs(List<WearLog> logs) async {
    final prefs = await SharedPreferences.getInstance();
    final json = jsonEncode(logs.map((e) => e.toMap()).toList());
    await prefs.setString(_keyLogs, json);
  }

  // ============================
  // ユーザー（User）
  // ============================

  /// ローカルに保存されたユーザー情報を読み込む
  Future<User?> loadUser() async {
    final prefs = await SharedPreferences.getInstance();
    final json = prefs.getString(_keyUser);
    if (json == null) return null;

    return User.fromMap(jsonDecode(json) as Map<String, dynamic>);
  }

  /// ユーザー情報をローカルに保存する
  Future<void> saveUser(User user) async {
    final prefs = await SharedPreferences.getInstance();
    final json = jsonEncode(user.toMap());
    await prefs.setString(_keyUser, json);
  }

  // ============================
  // 全データクリア（ログアウト時などに使う）
  // ============================
  Future<void> clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyItems);
    await prefs.remove(_keyLogs);
    await prefs.remove(_keyUser);
  }
}
