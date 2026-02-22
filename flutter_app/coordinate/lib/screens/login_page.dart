import 'package:flutter/material.dart';
import '../services/auth_service.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final AuthService _authService = AuthService();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;

  Widget _buildBackground(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[
            cs.primary.withValues(alpha: 0.14),
            cs.secondary.withValues(alpha: 0.10),
            cs.tertiary.withValues(alpha: 0.08),
          ],
        ),
      ),
      child: const SizedBox.expand(),
    );
  }

  InputDecoration _inputDecoration(
    BuildContext context, {
    required String label,
    IconData? leadingIcon,
  }) {
    final cs = Theme.of(context).colorScheme;
    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: BorderSide(color: cs.outlineVariant),
    );

    return InputDecoration(
      labelText: label,
      prefixIcon: leadingIcon == null ? null : Icon(leadingIcon),
      border: border,
      enabledBorder: border,
      focusedBorder: border.copyWith(
        borderSide: BorderSide(color: cs.primary, width: 1.4),
      ),
      filled: true,
      fillColor: cs.surfaceContainerHighest.withValues(alpha: 0.65),
    );
  }

  @override
  void initState() {
    super.initState();
    _redirectIfSignedIn();
  }

  Future<void> _redirectIfSignedIn() async {
    final signedIn = await _authService.isSignedIn();
    if (!mounted || !signedIn) return;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        Navigator.pushReplacementNamed(context, '/home');
      }
    });
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final result = await _authService.signIn(
      _emailController.text,
      _passwordController.text,
    );

    if (!mounted) return;

    // デバッグ出力
    debugPrint(
      'signIn result: isSignedIn=${result.isSignedIn}, error=${result.errorMessage}',
    );

    if (result.isSignedIn) {
      Navigator.pushReplacementNamed(context, '/home');
      return;
    }

    // デバッグモードでも認証必須（本番環境と同じ挙動に修正）

    // 通常の失敗処理
    final msg = result.errorMessage ?? 'ログインに失敗しました。メールアドレスとパスワードを確認してください。';
    setState(() {
      _errorMessage = msg;
    });
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));

    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            _buildBackground(context),
            LayoutBuilder(
              builder: (context, constraints) {
                final keyboardBottom = MediaQuery.viewInsetsOf(context).bottom;

                return SingleChildScrollView(
                  padding: EdgeInsets.only(bottom: keyboardBottom),
                  keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior.onDrag,
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: constraints.maxHeight,
                    ),
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 420),
                          child: TweenAnimationBuilder<double>(
                            duration: const Duration(milliseconds: 520),
                            curve: Curves.easeOutCubic,
                            tween: Tween<double>(begin: 0, end: 1),
                            builder: (context, t, child) {
                              final dy = (1 - t) * 14;
                              return Opacity(
                                opacity: t,
                                child: Transform.translate(
                                  offset: Offset(0, dy),
                                  child: child,
                                ),
                              );
                            },
                            child: Card(
                              elevation: 0,
                              color: cs.surface.withValues(alpha: 0.92),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                                side: BorderSide(color: cs.outlineVariant),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.fromLTRB(
                                  20,
                                  22,
                                  20,
                                  18,
                                ),
                                child: AutofillGroup(
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.stretch,
                                    children: [
                                      Row(
                                        children: [
                                          Container(
                                            width: 44,
                                            height: 44,
                                            decoration: BoxDecoration(
                                              color: cs.primaryContainer,
                                              borderRadius:
                                                  BorderRadius.circular(14),
                                            ),
                                            child: Icon(
                                              Icons.checkroom,
                                              color: cs.onPrimaryContainer,
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          const Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  'AIクローゼット',
                                                  style: TextStyle(
                                                    fontSize: 22,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                                SizedBox(height: 2),
                                                Text(
                                                  'ログインして続ける',
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 18),
                                      TextField(
                                        controller: _emailController,
                                        decoration: _inputDecoration(
                                          context,
                                          label: 'メールアドレス',
                                          leadingIcon: Icons.alternate_email,
                                        ),
                                        enabled: !_isLoading,
                                        keyboardType:
                                            TextInputType.emailAddress,
                                        autocorrect: false,
                                        enableSuggestions: false,
                                        autofillHints: const [
                                          AutofillHints.email,
                                        ],
                                      ),
                                      const SizedBox(height: 14),
                                      TextField(
                                        controller: _passwordController,
                                        obscureText: true,
                                        decoration: _inputDecoration(
                                          context,
                                          label: 'パスワード',
                                          leadingIcon: Icons.lock_outline,
                                        ),
                                        enabled: !_isLoading,
                                        autofillHints: const [
                                          AutofillHints.password,
                                        ],
                                      ),
                                      AnimatedSwitcher(
                                        duration: const Duration(
                                          milliseconds: 180,
                                        ),
                                        child: _errorMessage == null
                                            ? const SizedBox(height: 16)
                                            : Padding(
                                                key: const ValueKey('error'),
                                                padding: const EdgeInsets.only(
                                                  top: 12,
                                                ),
                                                child: Row(
                                                  children: [
                                                    Icon(
                                                      Icons.error_outline,
                                                      size: 18,
                                                      color: cs.error,
                                                    ),
                                                    const SizedBox(width: 6),
                                                    Expanded(
                                                      child: Text(
                                                        _errorMessage!,
                                                        style: TextStyle(
                                                          color: cs.error,
                                                          fontSize: 12,
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                      ),
                                      const SizedBox(height: 6),
                                      SizedBox(
                                        height: 48,
                                        child: FilledButton(
                                          onPressed: _isLoading
                                              ? null
                                              : _handleLogin,
                                          child: AnimatedSwitcher(
                                            duration: const Duration(
                                              milliseconds: 160,
                                            ),
                                            child: _isLoading
                                                ? const SizedBox(
                                                    key: ValueKey('loading'),
                                                    height: 20,
                                                    width: 20,
                                                    child:
                                                        CircularProgressIndicator(
                                                          strokeWidth: 2,
                                                        ),
                                                  )
                                                : const Text(
                                                    'ログイン',
                                                    key: ValueKey('label'),
                                                  ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 10),
                                      Wrap(
                                        alignment: WrapAlignment.center,
                                        crossAxisAlignment:
                                            WrapCrossAlignment.center,
                                        children: [
                                          Text(
                                            'アカウントを作成しますか？',
                                            style: TextStyle(
                                              color: cs.onSurface.withValues(
                                                alpha: 0.75,
                                              ),
                                            ),
                                          ),
                                          TextButton(
                                            onPressed: _isLoading
                                                ? null
                                                : () {
                                                    Navigator.pushNamed(
                                                      context,
                                                      '/signup',
                                                    );
                                                  },
                                            child: const Text('新規登録'),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
