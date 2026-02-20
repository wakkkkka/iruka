import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:amplify_auth_cognito/amplify_auth_cognito.dart';
import 'package:amplify_api/amplify_api.dart';
import 'package:amplify_storage_s3/amplify_storage_s3.dart';
import 'package:camera/camera.dart'; // 1. 追加
import 'amplifyconfiguration.dart';
import 'screens/login_page.dart';
import 'screens/signup_page.dart';
import 'screens/home_page.dart';
import 'screens/review_page.dart';
import 'screens/registration_complete_page.dart';
import 'screens/settings_page.dart';

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
    if (kDebugMode) {
      debugPrint('カメラの取得に失敗しました: ${e.description}');
    }
    safePrint('カメラの取得に失敗しました: ${e.description}');
  }

  runApp(const MyApp());
}

Future<void> _initAmplify() async {
  try {
    if (Amplify.isConfigured) {
      return;
    }
    final auth = AmplifyAuthCognito();
    final api = AmplifyAPI();
    final storage = AmplifyStorageS3();
    await Amplify.addPlugin(auth);
    await Amplify.addPlugin(api);
    await Amplify.addPlugin(storage);
    final config = kIsWeb ? amplifyconfigWeb : amplifyconfig;
    await Amplify.configure(config);
    safePrint('Amplifyが正常に初期化されました');
  } on ConfigurationError catch (e) {
    safePrint('Amplify設定エラー: ${e.message}');
    safePrint(
      'Amplifyの設定ファイルが不足しています。開発環境の場合は、`amplify pull`コマンドでバックエンド設定を同期してください。',
    );
  } on AmplifyAlreadyConfiguredException {
    // Hot restart 等で二重に configure されても問題ないように握りつぶす
    return;
  } catch (e) {
    safePrint('Amplify初期化エラー: $e');
  }
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
        '/signup': (context) => const SignupPage(),
        '/home': (context) => HomePage(),
        '/settings': (context) => const SettingsPage(),
        '/registration_complete': (context) => const RegistrationCompletePage(),
      },
      onGenerateRoute: (settings) {
        if (settings.name == '/review') {
          final args = settings.arguments;
          if (args is String) {
            return MaterialPageRoute(
                builder: (context) => ReviewPage(imagePath: args));
          }
        }
        return null;
      },
    );
  }
}
