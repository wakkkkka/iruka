import 'package:flutter/material.dart';
import '../services/auth_service.dart';

class SignupPage extends StatefulWidget {
  const SignupPage({super.key});

  @override
  State<SignupPage> createState() => _SignupPageState();
}

class _SignupPageState extends State<SignupPage> {
  final AuthService _authService = AuthService();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();
  final TextEditingController _confirmationCodeController =
      TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;
  String? _successMessage;
  bool _needsConfirmation = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _confirmationCodeController.dispose();
    super.dispose();
  }

  Future<void> _handleSignUp() async {
    // バリデーション
    if (_emailController.text.isEmpty ||
        _passwordController.text.isEmpty ||
        _confirmPasswordController.text.isEmpty) {
      setState(() {
        _errorMessage = 'すべての項目を入力してください。';
      });
      return;
    }

    if (_passwordController.text != _confirmPasswordController.text) {
      setState(() {
        _errorMessage = 'パスワードが一致しません。';
      });
      return;
    }

    if (_passwordController.text.length < 8) {
      setState(() {
        _errorMessage = 'パスワードは8文字以上である必要があります。';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _successMessage = null;
      _needsConfirmation = false;
    });

    final result = await _authService.signUp(
      _emailController.text,
      _passwordController.text,
    );

    if (mounted) {
      if (result.success) {
        if (result.isSignUpComplete) {
          setState(() {
            _successMessage = '登録が完了しました。ログインしてください。';
            _errorMessage = null;
          });

          Future.delayed(const Duration(seconds: 2), () {
            if (mounted) {
              Navigator.pop(context);
            }
          });
        } else {
          setState(() {
            _needsConfirmation = true;
            _successMessage = '確認コードをメールに送信しました。コードを入力して登録を完了してください。';
            _errorMessage = null;
          });
        }
      } else {
        setState(() {
          _errorMessage = result.errorMessage ?? '登録に失敗しました。もう一度お試しください。';
        });
      }
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _handleConfirmSignUp() async {
    if (_confirmationCodeController.text.trim().isEmpty) {
      setState(() {
        _errorMessage = '確認コードを入力してください。';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _successMessage = null;
    });

    final result = await _authService.confirmSignUp(
      _emailController.text,
      _confirmationCodeController.text,
    );

    if (!mounted) return;

    if (result.success) {
      setState(() {
        _successMessage = '登録が完了しました。ログインしてください。';
        _needsConfirmation = false;
      });

      Future.delayed(const Duration(seconds: 1), () {
        if (mounted) {
          Navigator.pop(context);
        }
      });
    } else {
      setState(() {
        _errorMessage = result.errorMessage ?? '確認に失敗しました。';
      });
    }

    setState(() {
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('新規登録'), centerTitle: true),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  'AIクローゼット',
                  style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 40),
                TextField(
                  controller: _emailController,
                  decoration: InputDecoration(
                    labelText: 'メールアドレス',
                    border: OutlineInputBorder(),
                  ),
                  enabled: !_isLoading,
                  keyboardType: TextInputType.emailAddress,
                  autocorrect: false,
                  enableSuggestions: false,
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: _passwordController,
                  obscureText: true,
                  decoration: InputDecoration(
                    labelText: 'パスワード（8文字以上）',
                    border: OutlineInputBorder(),
                  ),
                  enabled: !_isLoading,
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: _confirmPasswordController,
                  obscureText: true,
                  decoration: InputDecoration(
                    labelText: 'パスワード確認',
                    border: OutlineInputBorder(),
                  ),
                  enabled: !_isLoading,
                ),
                if (_needsConfirmation) ...[
                  const SizedBox(height: 20),
                  TextField(
                    controller: _confirmationCodeController,
                    decoration: const InputDecoration(
                      labelText: '確認コード',
                      border: OutlineInputBorder(),
                    ),
                    enabled: !_isLoading,
                    keyboardType: TextInputType.number,
                  ),
                ],
                if (_errorMessage != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 12.0),
                    child: Text(
                      _errorMessage!,
                      style: const TextStyle(color: Colors.red, fontSize: 14),
                    ),
                  ),
                if (_successMessage != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 12.0),
                    child: Text(
                      _successMessage!,
                      style: const TextStyle(color: Colors.green, fontSize: 14),
                    ),
                  ),
                const SizedBox(height: 30),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isLoading
                        ? null
                        : (_needsConfirmation
                              ? _handleConfirmSignUp
                              : _handleSignUp),
                    child: _isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text(_needsConfirmation ? '確認する' : '新規登録'),
                  ),
                ),
                const SizedBox(height: 20),
                Wrap(
                  alignment: WrapAlignment.center,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    const Text('既にアカウントをお持ちですか？'),
                    TextButton(
                      onPressed: _isLoading
                          ? null
                          : () {
                              Navigator.pop(context);
                            },
                      child: const Text('ログインする'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
