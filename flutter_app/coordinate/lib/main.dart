import 'package:flutter/material.dart';

import 'package:camera/camera.dart'; // 1. 追加
import 'screens/login_page.dart';
import 'screens/home_page.dart';
import 'repositories/wear_repository.dart';

// 2. 利用可能なカメラのリストをグローバル（どこからでも呼べる場所）に定義
late List<CameraDescription> cameras;

Future<void> main() async {
  // 3. Flutterのエンジンとネイティブ機能（カメラ等）を接続するおまじない
  WidgetsFlutterBinding.ensureInitialized();

  try {
    // 4. デバイス上のカメラ（背面・前面など）をすべて取得
    cameras = await availableCameras();
  } on CameraException catch (e) {
    print('カメラの取得に失敗しました: ${e.description}');
  }

  // ===== 動作確認（後で消してOK） =====
  final repo = WearRepository();
  await repo.fetchAllData();
  print('--- WearRepository 動作確認 ---');
  print('ユーザー: ${repo.currentUser?.name}');
  print('服の数: ${repo.items.length} 着');
  print('ログの数: ${repo.logs.length} 件');
  print('服一覧: ${repo.items.map((i) => i.itemName).join(", ")}');
  print('今日のログ: ${repo.getLogsByDate(DateTime.now()).length} 件');
  print('i001の服: ${repo.getItemById("i001")?.itemName}');
  print('-------------------------------');
  // ===== ここまで動作確認 =====

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AIクローゼット',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      initialRoute: '/login',
      routes: {
        '/login': (context) => LoginPage(),
        '/home': (context) => HomePage(),
        // ここでカメラページをルートに追加することもできますが、
        // 遷移時に引数を渡すことが多いので今はそのままでOKです。
      },
    );
  }
}
