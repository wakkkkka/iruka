/// ログインしている人の情報を入れる「箱」
///
/// フェーズ1: ダミーユーザー固定
/// フェーズ2: Cognito 等の認証情報に対応
class User {
  final String id;
  final String name;
  final String? email;

  const User({
    required this.id,
    required this.name,
    this.email,
  });

  /// Map に変換
  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'email': email,
      };

  /// Map から生成
  factory User.fromMap(Map<String, dynamic> m) => User(
        id: m['id'] as String,
        name: m['name'] as String,
        email: m['email'] as String?,
      );
}
