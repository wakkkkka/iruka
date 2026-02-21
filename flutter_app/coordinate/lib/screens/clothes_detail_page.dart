import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:flutter/material.dart';

import '../services/clothes_api_service.dart';

class ClothesDetailPage extends StatefulWidget {
  const ClothesDetailPage({super.key, required this.clothesId});

  final String clothesId;

  @override
  State<ClothesDetailPage> createState() => _ClothesDetailPageState();
}

class _ClothesDetailPageState extends State<ClothesDetailPage> {
  final ClothesApiService _clothesApiService = ClothesApiService();

  bool _loading = true;
  bool _saving = false;
  bool _deleting = false;
  String? _error;

  Future<String>? _imageUrlFuture;

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
  void initState() {
    super.initState();
    _load();
  }

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

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final item = await _clothesApiService.getClothes(widget.clothesId);
      if (!mounted) return;

      _categoryController.text = (item['category'] ?? '').toString();
      _colorController.text = (item['color'] ?? '').toString();
      _subCategoryController.text = (item['subCategory'] ?? '').toString();
      _sleeveLengthController.text = (item['sleeveLength'] ?? '').toString();
      _hemLengthController.text = (item['hemLength'] ?? '').toString();
      _sceneController.text = (item['scene'] ?? '').toString();
      _nameController.text = (item['name'] ?? '').toString();
      _notesController.text = (item['notes'] ?? '').toString();

      final imageUrl = (item['imageUrl'] ?? '').toString();

      final season = item['season'];
      if (season is List) {
        _seasonController.text = season.map((e) => e.toString()).join(',');
      } else if (season is Set) {
        _seasonController.text = season.map((e) => e.toString()).join(',');
      } else {
        _seasonController.text = '';
      }

      _imageUrlFuture = _resolveImageUrlIfNeeded(imageUrl);

      setState(() {
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  Future<String>? _resolveImageUrlIfNeeded(String raw) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty) return null;
    return () async {
      final result = await Amplify.Storage.getUrl(
        path: StoragePath.fromString(trimmed),
      ).result;
      return result.url.toString();
    }();
  }

  String? _emptyToNull(String value) {
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  List<String>? _parseSeason(String value) {
    final seasons = value
        .split(',')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();
    return seasons.isEmpty ? null : seasons;
  }

  Future<void> _save() async {
    if (_saving || _deleting) return;

    final category = _emptyToNull(_categoryController.text);
    final color = _emptyToNull(_colorController.text);
    if (category == null || color == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('カテゴリと色は必須です')));
      return;
    }

    setState(() {
      _saving = true;
      _error = null;
    });

    try {
      final updated = await _clothesApiService.updateClothes(
        widget.clothesId,
        category: category,
        color: color,
        subCategory: _emptyToNull(_subCategoryController.text),
        sleeveLength: _emptyToNull(_sleeveLengthController.text),
        hemLength: _emptyToNull(_hemLengthController.text),
        season: _parseSeason(_seasonController.text),
        scene: _emptyToNull(_sceneController.text),
        name: _emptyToNull(_nameController.text),
        notes: _emptyToNull(_notesController.text),
      );

      if (!mounted) return;

      final imageUrl = (updated['imageUrl'] ?? '').toString();
      _imageUrlFuture = _resolveImageUrlIfNeeded(imageUrl);
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _error = e.toString();
      });
    }
  }

  Future<void> _delete() async {
    if (_saving || _deleting) return;

    setState(() {
      _deleting = true;
      _error = null;
    });

    try {
      await _clothesApiService.deleteClothes(widget.clothesId);
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('削除しました')));
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _deleting = false;
        _error = e.toString();
      });
    }
  }

  Widget _buildImage() {
    final future = _imageUrlFuture;
    if (future == null) {
      return Container(
        height: 200,
        color: Colors.black12,
        child: const Center(child: Icon(Icons.image)),
      );
    }

    return FutureBuilder<String>(
      future: future,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return Container(
            height: 200,
            color: Colors.black12,
            child: const Center(
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          );
        }
        final url = snapshot.data;
        if (url == null || url.isEmpty || snapshot.hasError) {
          return Container(
            height: 200,
            color: Colors.black12,
            child: const Center(child: Icon(Icons.broken_image)),
          );
        }
        return ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: GestureDetector(
            onTap: () {
              showDialog(
                context: context,
                builder: (context) => Dialog(
                  child: InteractiveViewer(
                    child: Image.network(
                      url,
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
              );
            },
            child: Image.network(
              url,
              height: 200,
              width: double.infinity,
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  height: 200,
                  color: Colors.black12,
                  child: const Center(child: Icon(Icons.broken_image)),
                );
              },
            ),
          ),
        );
      },
    );
  }

  Widget _field({
    required TextEditingController controller,
    required String label,
    int maxLines = 1,
    bool enabled = true,
  }) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
      ),
      enabled: enabled,
      maxLines: maxLines,
    );
  }

  @override
  Widget build(BuildContext context) {
    final busy = _saving || _deleting;

    return Scaffold(
      appBar: AppBar(title: const Text('アイテム詳細'), centerTitle: true),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildImage(),
                    const SizedBox(height: 12),
                    if (_error != null) ...[
                      Text(
                        _error!,
                        style: const TextStyle(color: Colors.red, fontSize: 12),
                      ),
                      const SizedBox(height: 12),
                    ],
                    _field(
                      controller: _categoryController,
                      label: 'カテゴリ（必須）',
                      enabled: !busy,
                    ),
                    const SizedBox(height: 12),
                    _field(
                      controller: _colorController,
                      label: '色（必須）',
                      enabled: !busy,
                    ),
                    const SizedBox(height: 12),
                    _field(
                      controller: _subCategoryController,
                      label: 'サブカテゴリ',
                      enabled: !busy,
                    ),
                    const SizedBox(height: 12),
                    _field(
                      controller: _sleeveLengthController,
                      label: '袖丈',
                      enabled: !busy,
                    ),
                    const SizedBox(height: 12),
                    _field(
                      controller: _hemLengthController,
                      label: '丈',
                      enabled: !busy,
                    ),
                    const SizedBox(height: 12),
                    _field(
                      controller: _seasonController,
                      label: '季節（カンマ区切り）',
                      enabled: !busy,
                    ),
                    const SizedBox(height: 12),
                    _field(
                      controller: _sceneController,
                      label: 'シーン',
                      enabled: !busy,
                    ),
                    const SizedBox(height: 12),
                    _field(
                      controller: _nameController,
                      label: '名前',
                      enabled: !busy,
                    ),
                    const SizedBox(height: 12),
                    _field(
                      controller: _notesController,
                      label: 'メモ',
                      maxLines: 3,
                      enabled: !busy,
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: busy ? null : _save,
                        child: _saving
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Text('更新する'),
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: busy ? null : _delete,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                        ),
                        child: _deleting
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Text('削除する'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
