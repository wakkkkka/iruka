import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';

import '../services/selfie_api_service.dart';
import 'package:camera/camera.dart';
import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:amplify_auth_cognito/amplify_auth_cognito.dart';
import '../amplifyconfiguration.dart';
import 'package:logger/logger.dart';

// 2. 利用可能なカメラのリストをグローバル（どこからでも呼べる場所）に定義
late List<CameraDescription> cameras;

Future<void> main() async {
  // 3. Flutterのエンジンとネイティブ機能（カメラ等）を接続するおまじない
  WidgetsFlutterBinding.ensureInitialized();

  // Amplifyの初期化
  await _initAmplify();

  try {
    // 4. デバイス上のカメラ（背面・前面など）をすべて取得
    cameras = await availableCameras();
  } on CameraException catch (e) {
    Logger().e('カメラの取得に失敗しました: ${e.description}');
  }

  runApp(const MyApp());
}

Future<void> _initAmplify() async {
  try {
    if (Amplify.isConfigured) {
      return;
    }
    final auth = AmplifyAuthCognito();
    await Amplify.addPlugin(auth);
    final config = kIsWeb ? amplifyconfigWeb : amplifyconfig;
    await Amplify.configure(config);
    Logger().i('Amplifyが正常に初期化されました');
  } on ConfigurationError catch (e) {
    Logger().e('Amplify設定エラー: ${e.message}');
    Logger().e(
      'Amplifyの設定ファイルが不足しています。開発環境の場合は、`amplify pull`コマンドでバックエンド設定を同期してください。',
    );
  } on AmplifyAlreadyConfiguredException {
    // Hot restart 等で二重に configure されても問題ないように握りつぶす
    return;
  } catch (e) {
    Logger().e('Amplify初期化エラー: $e');
  }
}

// CalendarPageとしても利用できるようエイリアスを追加
typedef CalendarPage = MonotoneCalendar;

class MonotoneCalendar extends StatelessWidget {
  const MonotoneCalendar({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('カレンダー'),
      ),
      body: Center(
        child: Text('ここにカレンダーを表示'),
      ),
    );
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Monotone App',
      theme: ThemeData(useMaterial3: true),
      // 2. ここを書き換える！ 
      // (今まで MyHomePage() とかになっていたのを変更)
      home: MonotoneCalendar(), 
    );
  }
}
