// // lib/services/auth_service.dart

// class AuthService {
//   // サインイン（ログイン）
//   // 要件定義書の Amazon Cognito と連携する部分
//   Future<bool> signIn(String email, String password) async {
//     try {
//       // 2/21のフェーズ2で、ここに Amplify.Auth.signIn を書く
//       print("Cognitoへ認証リクエスト: $email");
      
//       await Future.delayed(const Duration(seconds: 2)); // 通信中を演出
//       return true; // 今は必ず成功させる
//     } catch (e) {
//       print("サインインエラー: $e");
//       return false;
//     }
//   }

//   // サインアップ（新規登録）
//   Future<bool> signUp(String email, String password) async {
//     // 2/21に Amplify.Auth.signUp を実装
//     return true;
//   }
// }