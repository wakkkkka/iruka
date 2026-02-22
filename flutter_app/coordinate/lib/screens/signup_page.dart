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

  void _showSnackBar(String message, {required bool isError}) {
    if (!mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          behavior: SnackBarBehavior.floating,
          backgroundColor: isError
              ? Theme.of(context).colorScheme.error
              : null,
        ),
      );
  }

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
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _confirmationCodeController.dispose();
    super.dispose();
  }

  Future<void> _handleSignUp() async {
    FocusManager.instance.primaryFocus?.unfocus();

    // バリデーション
    if (_emailController.text.isEmpty ||
        _passwordController.text.isEmpty ||
        _confirmPasswordController.text.isEmpty) {
      setState(() {
        _errorMessage = 'すべての項目を入力してください。';
      });
      _showSnackBar(_errorMessage!, isError: true);
      return;
    }

    if (_passwordController.text != _confirmPasswordController.text) {
      setState(() {
        _errorMessage = 'パスワードが一致しません。';
      });
      _showSnackBar(_errorMessage!, isError: true);
      return;
    }

    if (_passwordController.text.length < 8) {
      setState(() {
        _errorMessage = 'パスワードは8文字以上である必要があります。';
      });
      _showSnackBar(_errorMessage!, isError: true);
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

          _showSnackBar(_successMessage!, isError: false);

          Future.delayed(const Duration(seconds: 2), () {
            if (mounted) {
              Navigator.pop(context);
            }
          });
        } else {
          final destination =
              result.nextStep?.codeDeliveryDetails?.destination;
          setState(() {
            _needsConfirmation = true;
            _successMessage = destination == null
                ? '確認コードをメールに送信しました。コードを入力して登録を完了してください。'
                : '確認コードを送信しました（宛先: $destination）。コードを入力して登録を完了してください。';
            _errorMessage = null;
          });

          _showSnackBar(_successMessage!, isError: false);
        }
      } else {
        setState(() {
          _errorMessage = result.errorMessage ?? '登録に失敗しました。もう一度お試しください。';
        });

        _showSnackBar(_errorMessage!, isError: true);
      }
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _handleConfirmSignUp() async {
    FocusManager.instance.primaryFocus?.unfocus();

    if (_confirmationCodeController.text.trim().isEmpty) {
      setState(() {
        _errorMessage = '確認コードを入力してください。';
      });
      _showSnackBar(_errorMessage!, isError: true);
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

      _showSnackBar(_successMessage!, isError: false);

      Future.delayed(const Duration(seconds: 1), () {
        if (mounted) {
          Navigator.pop(context);
        }
      });
    } else {
      setState(() {
        _errorMessage = result.errorMessage ?? '確認に失敗しました。';
      });

      _showSnackBar(_errorMessage!, isError: true);
    }

    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _handleResendCode() async {
    FocusManager.instance.primaryFocus?.unfocus();

    if (_emailController.text.trim().isEmpty) {
      setState(() {
        _errorMessage = 'メールアドレスを入力してください。';
      });
      _showSnackBar(_errorMessage!, isError: true);
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _successMessage = null;
    });

    final result = await _authService.resendSignUpCode(_emailController.text);

    if (!mounted) return;

    if (result.success) {
      final destination = result.destination;
      setState(() {
        _successMessage = destination == null
            ? '確認コードを再送しました。'
            : '確認コードを再送しました（宛先: $destination）。';
      });
      _showSnackBar(_successMessage!, isError: false);
    } else {
      setState(() {
        _errorMessage = result.errorMessage ?? '確認コードの再送に失敗しました。';
      });
      _showSnackBar(_errorMessage!, isError: true);
    }

    setState(() {
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('新規登録'),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
      ),
      body: Stack(
        children: [
          _buildBackground(context),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.only(top: kToolbarHeight + 8),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final keyboardBottom = MediaQuery.viewInsetsOf(
                    context,
                  ).bottom;

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
                            constraints: const BoxConstraints(maxWidth: 460),
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
                                                color: cs.secondaryContainer,
                                                borderRadius:
                                                    BorderRadius.circular(14),
                                              ),
                                              child: Icon(
                                                Icons.person_add_alt_1,
                                                color: cs.onSecondaryContainer,
                                              ),
                                            ),
                                            const SizedBox(width: 12),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  const Text(
                                                    'AIクローゼット',
                                                    style: TextStyle(
                                                      fontSize: 22,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                    ),
                                                  ),
                                                  const SizedBox(height: 2),
                                                  Text(
                                                    _needsConfirmation
                                                        ? 'メールの確認コードを入力して完了'
                                                        : '新しいアカウントを作成',
                                                    style: const TextStyle(
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
                                            label: 'パスワード（8文字以上）',
                                            leadingIcon: Icons.lock_outline,
                                          ),
                                          enabled: !_isLoading,
                                          autofillHints: const [
                                            AutofillHints.newPassword,
                                          ],
                                        ),
                                        const SizedBox(height: 14),
                                        TextField(
                                          controller:
                                              _confirmPasswordController,
                                          obscureText: true,
                                          decoration: _inputDecoration(
                                            context,
                                            label: 'パスワード確認',
                                            leadingIcon: Icons.lock_reset,
                                          ),
                                          enabled: !_isLoading,
                                          autofillHints: const [
                                            AutofillHints.newPassword,
                                          ],
                                        ),
                                        AnimatedSize(
                                          duration: const Duration(
                                            milliseconds: 220,
                                          ),
                                          curve: Curves.easeOut,
                                          child: _needsConfirmation
                                              ? Padding(
                                                  padding:
                                                      const EdgeInsets.only(
                                                        top: 14,
                                                      ),
                                                  child: TextField(
                                                    controller:
                                                        _confirmationCodeController,
                                                    decoration: _inputDecoration(
                                                      context,
                                                      label: '確認コード',
                                                      leadingIcon: Icons
                                                          .verified_outlined,
                                                    ),
                                                    enabled: !_isLoading,
                                                    keyboardType:
                                                        TextInputType.number,
                                                    autofillHints: const [
                                                      AutofillHints.oneTimeCode,
                                                    ],
                                                  ),
                                                )
                                              : const SizedBox.shrink(),
                                        ),
                                        if (_needsConfirmation)
                                          Align(
                                            alignment: Alignment.centerRight,
                                            child: TextButton(
                                              onPressed: _isLoading
                                                  ? null
                                                  : _handleResendCode,
                                              child: const Text('確認コードを再送'),
                                            ),
                                          ),
                                        AnimatedSwitcher(
                                          duration: const Duration(
                                            milliseconds: 180,
                                          ),
                                          child:
                                              (_errorMessage == null &&
                                                  _successMessage == null)
                                              ? const SizedBox(height: 16)
                                              : Padding(
                                                  key: ValueKey(
                                                    '${_errorMessage ?? ''}/${_successMessage ?? ''}',
                                                  ),
                                                  padding:
                                                      const EdgeInsets.only(
                                                        top: 12,
                                                      ),
                                                  child: Row(
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .start,
                                                    children: [
                                                      Icon(
                                                        _errorMessage != null
                                                            ? Icons
                                                                  .error_outline
                                                            : Icons
                                                                  .check_circle_outline,
                                                        size: 18,
                                                        color:
                                                            _errorMessage !=
                                                                null
                                                            ? cs.error
                                                            : cs.primary,
                                                      ),
                                                      const SizedBox(width: 6),
                                                      Expanded(
                                                        child: Text(
                                                          _errorMessage ??
                                                              _successMessage ??
                                                              '',
                                                          style: TextStyle(
                                                            color:
                                                                _errorMessage !=
                                                                    null
                                                                ? cs.error
                                                                : cs.primary,
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
                                                : (_needsConfirmation
                                                      ? _handleConfirmSignUp
                                                      : _handleSignUp),
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
                                                  : Text(
                                                      _needsConfirmation
                                                          ? '確認する'
                                                          : '新規登録',
                                                      key: const ValueKey(
                                                        'label',
                                                      ),
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
                                              '既にアカウントをお持ちですか？',
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
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
