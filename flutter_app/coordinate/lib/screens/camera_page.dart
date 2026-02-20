import 'dart:math';
import 'dart:typed_data';

import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:flutter/foundation.dart'
    show kIsWeb, defaultTargetPlatform, TargetPlatform;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;

import '../services/clothes_api_service.dart';

enum CameraPagePurpose { registerItem, selfie }

class CameraPage extends StatefulWidget {
  const CameraPage({super.key, required this.purpose});

  final CameraPagePurpose purpose;

  @override
  State<CameraPage> createState() => _CameraPageState();
}

class _CameraPageState extends State<CameraPage> {
  XFile? _imageFile;
  Uint8List? _imageBytes;
  final ImagePicker _picker = ImagePicker();
  final ClothesApiService _clothesApiService = ClothesApiService();

  bool _isSubmitting = false;

  final TextEditingController _categoryController = TextEditingController();
  final TextEditingController _colorController = TextEditingController();
  final TextEditingController _subCategoryController = TextEditingController();
  final TextEditingController _sleeveLengthController = TextEditingController();
  final TextEditingController _hemLengthController = TextEditingController();
  final TextEditingController _seasonController = TextEditingController();
  final TextEditingController _sceneController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();

  @override
  void dispose() {
    _categoryController.dispose();
    _colorController.dispose();
    _subCategoryController.dispose();
    _sleeveLengthController.dispose();
    _hemLengthController.dispose();
    _seasonController.dispose();
    _sceneController.dispose();
    _nameController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final isLinux = !kIsWeb && defaultTargetPlatform == TargetPlatform.linux;

      // Linux環境ではカメラを使用できないため、ギャラリーのみ
      if (isLinux && source == ImageSource.camera) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Linux環境ではギャラリーからのみ選択できます')),
          );
        }
        return;
      }
      final photo = await _picker.pickImage(source: source);
      if (!mounted) return;
      if (photo != null) {
        final bytes = await photo.readAsBytes();
        if (!mounted) return;
        setState(() {
          _imageFile = photo;
          _imageBytes = bytes;
        });
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('エラー: $e')));
    }
  }

  String _buildUniqueFileName({required String extension}) {
    final ts = DateTime.now().microsecondsSinceEpoch;
    final rand = Random().nextInt(0x7fffffff);
    final safeExt = extension.isNotEmpty ? extension : '.jpg';
    return '$ts-$rand$safeExt';
  }

  List<String>? _parseSeason(String raw) {
    final cleaned = raw
        .split(',')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();
    return cleaned.isEmpty ? null : cleaned;
  }

  Future<void> _uploadAndCreateClothes() async {
    if (_isSubmitting) return;
    final imageFile = _imageFile;
    final imageBytes = _imageBytes;
    if (imageFile == null || imageBytes == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('先に写真を選択してください')));
      return;
    }

    if (widget.purpose != CameraPagePurpose.registerItem) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('自撮り解析はCRUD完成後に実装します')));
      return;
    }

    final category = _categoryController.text.trim();
    final color = _colorController.text.trim();
    if (category.isEmpty || color.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('カテゴリと色は必須です')));
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      final user = await Amplify.Auth.getCurrentUser();
      final userId = user.userId;

      final extFromName = p.extension(imageFile.name);
      final extFromPath = p.extension(imageFile.path);
      final ext = (extFromName.isNotEmpty ? extFromName : extFromPath);
      final fileName = _buildUniqueFileName(extension: ext);

      final objectPath = 'public/users/$userId/items/$fileName';

      await Amplify.Storage.uploadData(
        data: StorageDataPayload.bytes(imageBytes),
        path: StoragePath.fromString(objectPath),
      ).result;

      final created = await _clothesApiService.createClothes(
        category: category,
        color: color,
        subCategory: _subCategoryController.text.trim().isEmpty
            ? null
            : _subCategoryController.text.trim(),
        sleeveLength: _sleeveLengthController.text.trim().isEmpty
            ? null
            : _sleeveLengthController.text.trim(),
        hemLength: _hemLengthController.text.trim().isEmpty
            ? null
            : _hemLengthController.text.trim(),
        season: _parseSeason(_seasonController.text),
        scene: _sceneController.text.trim().isEmpty
            ? null
            : _sceneController.text.trim(),
        imageUrl: objectPath,
        name: _nameController.text.trim().isEmpty
            ? null
            : _nameController.text.trim(),
        notes: _notesController.text.trim().isEmpty
            ? null
            : _notesController.text.trim(),
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('登録しました: ${created['clothesId'] ?? ''}')),
      );

      Navigator.pop(context);
    } on AuthException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('認証エラー: ${e.message}')));
    } on StorageException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('アップロード失敗: ${e.message}')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('登録に失敗しました: $e')));
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.purpose == CameraPagePurpose.registerItem
        ? '服の新規登録'
        : '自撮り（未実装）';

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(title),
        backgroundColor: Colors.white,
        elevation: 1,
      ),
      body: Column(
        children: [
          Expanded(
            child: Center(
              child: _imageBytes != null
                  ? Image.memory(_imageBytes!)
                  : _buildPlaceholder(),
            ),
          ),
          _buildControlPanel(),
        ],
      ),
    );
  }

  Widget _buildPlaceholder() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.add_a_photo, size: 80, color: Colors.grey[300]),
        const SizedBox(height: 16),
        const Text(
          "下のボタンから撮影または選択してください",
          style: TextStyle(color: Colors.grey),
        ),
      ],
    );
  }

  Widget _buildControlPanel() {
    final isLinux = !kIsWeb && defaultTargetPlatform == TargetPlatform.linux;
    return Container(
      padding: const EdgeInsets.all(24),
      child: _imageFile == null
          ? Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _actionButton(
                  Icons.image,
                  'ギャラリー',
                  () => _pickImage(ImageSource.gallery),
                ),
                if (!isLinux)
                  _actionButton(
                    Icons.camera_alt,
                    'カメラで撮る',
                    () => _pickImage(ImageSource.camera),
                  ),
              ],
            )
          : SingleChildScrollView(
              child: Column(
                children: [
                  if (widget.purpose == CameraPagePurpose.registerItem) ...[
                    TextField(
                      controller: _categoryController,
                      decoration: const InputDecoration(
                        labelText: 'カテゴリ（必須）例: tops',
                        border: OutlineInputBorder(),
                      ),
                      enabled: !_isSubmitting,
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _colorController,
                      decoration: const InputDecoration(
                        labelText: '色（必須）例: navy',
                        border: OutlineInputBorder(),
                      ),
                      enabled: !_isSubmitting,
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _subCategoryController,
                      decoration: const InputDecoration(
                        labelText: 'サブカテゴリ 例: t-shirt',
                        border: OutlineInputBorder(),
                      ),
                      enabled: !_isSubmitting,
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _sleeveLengthController,
                      decoration: const InputDecoration(
                        labelText: '袖丈 例: short',
                        border: OutlineInputBorder(),
                      ),
                      enabled: !_isSubmitting,
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _hemLengthController,
                      decoration: const InputDecoration(
                        labelText: '丈 例: long',
                        border: OutlineInputBorder(),
                      ),
                      enabled: !_isSubmitting,
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _seasonController,
                      decoration: const InputDecoration(
                        labelText: '季節（カンマ区切り）例: spring,fall',
                        border: OutlineInputBorder(),
                      ),
                      enabled: !_isSubmitting,
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _sceneController,
                      decoration: const InputDecoration(
                        labelText: 'シーン 例: casual',
                        border: OutlineInputBorder(),
                      ),
                      enabled: !_isSubmitting,
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: '名前（任意）',
                        border: OutlineInputBorder(),
                      ),
                      enabled: !_isSubmitting,
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _notesController,
                      decoration: const InputDecoration(
                        labelText: 'メモ（任意）',
                        border: OutlineInputBorder(),
                      ),
                      enabled: !_isSubmitting,
                      maxLines: 3,
                    ),
                    const SizedBox(height: 16),
                  ],
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isSubmitting ? null : _uploadAndCreateClothes,
                      child: _isSubmitting
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Text(
                              widget.purpose == CameraPagePurpose.registerItem
                                  ? 'この写真で登録する'
                                  : 'この写真で解析する（未実装）',
                            ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isSubmitting
                          ? null
                          : () {
                              setState(() {
                                _imageFile = null;
                                _imageBytes = null;
                              });
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.grey,
                      ),
                      child: const Text('別の写真を選択'),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _actionButton(IconData icon, String label, VoidCallback onPressed) {
    return Column(
      children: [
        IconButton(icon: Icon(icon, size: 40), onPressed: onPressed),
        Text(label, style: const TextStyle(fontSize: 12)),
      ],
    );
  }
}
