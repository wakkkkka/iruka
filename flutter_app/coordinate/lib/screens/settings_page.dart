import 'dart:math';
import 'dart:typed_data';

import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../services/auth_service.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final AuthService _authService = AuthService();
  bool _isLoading = false;
  String? _errorMessage;

  final TextEditingController _displayNameController = TextEditingController();
  String? _avatarUrl;
  Uint8List? _pickedAvatarBytes;

  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  @override
  void dispose() {
    _displayNameController.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    try {
      final attributes = await Amplify.Auth.fetchUserAttributes();

      String? displayName;
      String? picture;
      for (final attr in attributes) {
        if (attr.userAttributeKey == AuthUserAttributeKey.name) {
          displayName = attr.value;
        }
        if (attr.userAttributeKey == AuthUserAttributeKey.picture) {
          picture = attr.value;
        }
      }

      if (!mounted) return;
      setState(() {
        _displayNameController.text = (displayName ?? '').trim();
      });

      final pic = (picture ?? '').trim();
      if (pic.isEmpty) return;

      if (pic.startsWith('http://') || pic.startsWith('https://')) {
        if (!mounted) return;
        setState(() {
          _avatarUrl = pic;
        });
        return;
      }

      final result = await Amplify.Storage.getUrl(
        path: StoragePath.fromString(pic),
      ).result;
      if (!mounted) return;
      setState(() {
        _avatarUrl = result.url.toString();
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'プロフィールの読み込みに失敗しました: $e';
      });
    }
  }

  String _buildUniqueAvatarKey({required String userId}) {
    final ts = DateTime.now().microsecondsSinceEpoch;
    final rand = Random().nextInt(0x7fffffff);
    return 'public/users/$userId/profile/avatar-$ts-$rand.jpg';
  }

  Future<void> _saveProfile() async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final displayName = _displayNameController.text.trim();
      if (displayName.isNotEmpty) {
        await Amplify.Auth.updateUserAttribute(
          userAttributeKey: AuthUserAttributeKey.name,
          value: displayName,
        );
      }

      final bytes = _pickedAvatarBytes;
      if (bytes != null) {
        final user = await Amplify.Auth.getCurrentUser();
        final key = _buildUniqueAvatarKey(userId: user.userId);

        await Amplify.Storage.uploadData(
          data: StorageDataPayload.bytes(bytes),
          path: StoragePath.fromString(key),
        ).result;

        await Amplify.Auth.updateUserAttribute(
          userAttributeKey: AuthUserAttributeKey.picture,
          value: key,
        );

        final urlResult = await Amplify.Storage.getUrl(
          path: StoragePath.fromString(key),
        ).result;

        if (mounted) {
          setState(() {
            _avatarUrl = urlResult.url.toString();
            _pickedAvatarBytes = null;
          });
        }
      }

      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('プロフィールを保存しました')));
    } on AuthException catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = e.message;
      });
    } on StorageException catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = e.message;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = e.toString();
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _handleSignOut() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final result = await _authService.signOut();

    if (!mounted) return;

    if (result.success) {
      Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
    } else {
      setState(() {
        _errorMessage = result.errorMessage ?? 'ログアウトに失敗しました。';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('設定')),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 28.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 48,
                      backgroundColor: Colors.deepPurple.shade50,
                      child: (_pickedAvatarBytes == null && _avatarUrl == null)
                          ? Icon(
                              Icons.person,
                              size: 48,
                              color: Colors.deepPurple,
                            )
                          : ClipOval(
                              child: _pickedAvatarBytes != null
                                  ? Image.memory(
                                      _pickedAvatarBytes!,
                                      width: 96,
                                      height: 96,
                                      fit: BoxFit.cover,
                                    )
                                  : Image.network(
                                      _avatarUrl!,
                                      width: 96,
                                      height: 96,
                                      fit: BoxFit.cover,
                                      errorBuilder:
                                          (context, error, stackTrace) {
                                            return Icon(
                                              Icons.person,
                                              size: 48,
                                              color: Colors.deepPurple,
                                            );
                                          },
                                    ),
                            ),
                    ),
                    const SizedBox(height: 8),
                    TextButton(
                      onPressed: _showImageSourceSheet,
                      child: const Text('写真を変更'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              const Text(
                'プロフィール',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                '表示名は他のユーザーに公開されません。任意で設定してください。',
                style: TextStyle(fontSize: 13, color: Colors.black54),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _displayNameController,
                decoration: InputDecoration(
                  labelText: '表示名',
                  border: OutlineInputBorder(),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 18,
                  ),
                ),
              ),
              if (_errorMessage != null) ...[
                const SizedBox(height: 12),
                Text(
                  _errorMessage!,
                  style: const TextStyle(color: Colors.red, fontSize: 14),
                ),
              ],
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _saveProfile,
                  style: ElevatedButton.styleFrom(
                    shape: const StadiumBorder(),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('保存'),
                ),
              ),
              const SizedBox(height: 12),

              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: _isLoading ? null : _handleSignOut,
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: const StadiumBorder(),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('ログアウト'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showImageSourceSheet() {
    showModalBottomSheet<void>(
      context: context,
      builder: (BuildContext ctx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('ギャラリーから選択'),
                onTap: () {
                  Navigator.pop(ctx);
                  _pickImage(ImageSource.gallery);
                },
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: const Text('カメラで撮影'),
                onTap: () {
                  Navigator.pop(ctx);
                  _pickImage(ImageSource.camera);
                },
              ),
              ListTile(
                leading: const Icon(Icons.close),
                title: const Text('キャンセル'),
                onTap: () => Navigator.pop(ctx),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? file = await _picker.pickImage(
        source: source,
        maxWidth: 1080,
      );
      if (file == null) return;
      final bytes = await file.readAsBytes();
      if (!mounted) return;
      setState(() {
        _pickedAvatarBytes = bytes;
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('画像選択エラー: $e')));
    }
  }
}
