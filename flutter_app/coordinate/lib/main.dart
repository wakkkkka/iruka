import 'package:flutter/material.dart';

import 'package:camera/camera.dart'; // 1. 追加
import 'login_page.dart';
import 'home_page.dart';

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
        '/login': (context) => const LoginPage(),
        '/home': (context) => const HomePage(),
        // ここでカメラページをルートに追加することもできますが、
        // 遷移時に引数を渡すことが多いので今はそのままでOKです。
      },
    );
  }
}
