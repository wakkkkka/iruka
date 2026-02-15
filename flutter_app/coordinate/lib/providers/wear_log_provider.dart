import 'package:flutter/material.dart';
import '../models/wear_log.dart';

/// アプリ全体で着用ログを管理する Provider
///
/// フェーズ1: メモリ内のリスト（ダミーデータ初期化）
/// フェーズ2: DynamoDB からの読み書きに差し替え
class WearLogProvider extends ChangeNotifier {
  final List<WearLog> _logs = List.from(dummyWearLogs);

  /// 全ログ（読み取り専用）
  List<WearLog> get logs => List.unmodifiable(_logs);

  /// ログを追加（記録画面から呼ぶ）
  void addLog(WearLog log) {
    _logs.add(log);
    notifyListeners(); // ← これで統計画面が自動更新される
  }

  /// ログを削除
  void removeLog(String id) {
    _logs.removeWhere((log) => log.id == id);
    notifyListeners();
  }

  /// 全ログをリセット（テスト用）
  void resetToDefault() {
    _logs
      ..clear()
      ..addAll(dummyWearLogs);
    notifyListeners();
  }

  /// 次の ID を自動生成（簡易版）
  String generateNextId() {
    return 'w${DateTime.now().millisecondsSinceEpoch}';
  }
}
