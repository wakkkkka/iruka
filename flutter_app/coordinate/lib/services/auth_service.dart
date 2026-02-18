import 'package:amplify_flutter/amplify_flutter.dart';

class AuthService {
  String _normalizeEmail(String email) {
    return email.trim();
  }

  Future<bool> isSignedIn() async {
    try {
      final session = await Amplify.Auth.fetchAuthSession();
      return session.isSignedIn;
    } on AuthException {
      return false;
    } catch (_) {
      return false;
    }
  }

  // サインイン（ログイン）
  // Amazon Cognito と連携する部分
  Future<
    ({bool isSignedIn, String? errorMessage, AuthNextSignInStep? nextStep})
  >
  signIn(String email, String password) async {
    try {
      final session = await Amplify.Auth.fetchAuthSession();
      if (session.isSignedIn) {
        safePrint('サインイン済みのため signIn をスキップします');
        return (isSignedIn: true, errorMessage: null, nextStep: null);
      }

      final normalizedEmail = _normalizeEmail(email);
      final normalizedPassword = password;
      safePrint('Cognitoへ認証リクエスト: $normalizedEmail');

      final result = await Amplify.Auth.signIn(
        username: normalizedEmail,
        password: normalizedPassword,
      );

      safePrint(
        'サインイン結果: isSignedIn=${result.isSignedIn}, nextStep=${result.nextStep.signInStep}',
      );
      return (
        isSignedIn: result.isSignedIn,
        errorMessage: null,
        nextStep: result.nextStep,
      );
    } on AuthException catch (e) {
      safePrint('サインインエラー: ${e.message}');
      return (isSignedIn: false, errorMessage: e.message, nextStep: null);
    } catch (e) {
      safePrint('予期しないエラー: $e');
      return (isSignedIn: false, errorMessage: e.toString(), nextStep: null);
    }
  }

  // サインアップ（新規登録）
  Future<
    ({
      bool success,
      bool isSignUpComplete,
      AuthNextSignUpStep? nextStep,
      String? errorMessage,
    })
  >
  signUp(String email, String password) async {
    try {
      final normalizedEmail = _normalizeEmail(email);
      final result = await Amplify.Auth.signUp(
        username: normalizedEmail,
        password: password,
        options: SignUpOptions(
          userAttributes: {AuthUserAttributeKey.email: normalizedEmail},
        ),
      );

      safePrint(
        'サインアップ結果: isSignUpComplete=${result.isSignUpComplete}, nextStep=${result.nextStep.signUpStep}',
      );
      return (
        success: true,
        isSignUpComplete: result.isSignUpComplete,
        nextStep: result.nextStep,
        errorMessage: null,
      );
    } on AuthException catch (e) {
      safePrint('サインアップエラー: ${e.message}');
      return (
        success: false,
        isSignUpComplete: false,
        nextStep: null,
        errorMessage: e.message,
      );
    } catch (e) {
      safePrint('予期しないエラー: $e');
      return (
        success: false,
        isSignUpComplete: false,
        nextStep: null,
        errorMessage: e.toString(),
      );
    }
  }

  Future<({bool success, String? errorMessage})> confirmSignUp(
    String email,
    String confirmationCode,
  ) async {
    try {
      final normalizedEmail = _normalizeEmail(email);
      final normalizedCode = confirmationCode.trim();

      final result = await Amplify.Auth.confirmSignUp(
        username: normalizedEmail,
        confirmationCode: normalizedCode,
      );

      safePrint('confirmSignUp: isComplete=${result.isSignUpComplete}');
      return (success: result.isSignUpComplete, errorMessage: null);
    } on AuthException catch (e) {
      safePrint('confirmSignUp エラー: ${e.message}');
      return (success: false, errorMessage: e.message);
    } catch (e) {
      safePrint('confirmSignUp 予期しないエラー: $e');
      return (success: false, errorMessage: e.toString());
    }
  }

  // 現在のユーザーを取得
  Future<AuthUser?> getCurrentUser() async {
    try {
      final user = await Amplify.Auth.getCurrentUser();
      return user;
    } catch (e) {
      safePrint('ユーザー取得エラー: $e');
      return null;
    }
  }

  // ログアウト
  Future<({bool success, String? errorMessage})> signOut() async {
    try {
      await Amplify.Auth.signOut();

      final session = await Amplify.Auth.fetchAuthSession();
      if (!session.isSignedIn) {
        safePrint('ログアウト成功');
        return (success: true, errorMessage: null);
      }

      safePrint('ログアウト後もセッションが残っています');
      return (success: false, errorMessage: 'ログアウトできませんでした（セッションが残っています）');
    } on AuthException catch (e) {
      safePrint('ログアウトエラー: ${e.message}');
      return (success: false, errorMessage: e.message);
    } catch (e) {
      safePrint('ログアウトエラー: $e');
      return (success: false, errorMessage: e.toString());
    }
  }
}
