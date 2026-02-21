import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:flutter/material.dart';

import '../constants/clothes_options.dart';
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

  String? _category;
  String? _color;
  String? _subCategory;
  String? _sleeveLength;
  String? _hemLength;
  String? _season;
  String? _scene;

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
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

      final categoryRaw = (item['category'] ?? '').toString().trim();
      final colorRaw = (item['color'] ?? '').toString().trim();
      final subCategoryRaw = (item['subCategory'] ?? '').toString().trim();
      final sleeveLengthRaw = (item['sleeveLength'] ?? '').toString().trim();
      final hemLengthRaw = (item['hemLength'] ?? '').toString().trim();
      final sceneRaw = (item['scene'] ?? '').toString().trim();

      _category = categoryRaw.isEmpty ? null : categoryRaw;
      _color = colorRaw.isEmpty ? null : colorRaw;
      _subCategory = subCategoryRaw.isEmpty ? null : subCategoryRaw;
      _sleeveLength = sleeveLengthRaw.isEmpty ? null : sleeveLengthRaw;
      _hemLength = hemLengthRaw.isEmpty ? null : hemLengthRaw;
      _scene = sceneRaw.isEmpty ? null : sceneRaw;
      _nameController.text = (item['name'] ?? '').toString();
      _notesController.text = (item['notes'] ?? '').toString();

      final imageUrl = (item['imageUrl'] ?? '').toString();

      final season = item['season'];
      if (season is List && season.isNotEmpty) {
        _season = season.first.toString().trim();
      } else if (season is Set && season.isNotEmpty) {
        _season = season.first.toString().trim();
      } else {
        _season = null;
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

  Widget _dropdownField({
    required String label,
    required List<String> options,
    required String? value,
    required ValueChanged<String?> onChanged,
    Map<String, String>? optionLabels,
    bool enabled = true,
  }) {
    final normalizedValue = (value != null && options.contains(value))
        ? value
        : null;

    return DropdownButtonFormField<String>(
      initialValue: normalizedValue,
      items: options
          .map(
            (e) => DropdownMenuItem<String>(
              value: e,
              child: Text(
                optionLabels == null
                    ? e
                    : ClothesOptions.labelFor(e, optionLabels),
              ),
            ),
          )
          .toList(),
      onChanged: enabled ? onChanged : null,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
      ),
    );
  }

  Future<void> _save() async {
    if (_saving || _deleting) return;

    final category = _category;
    final color = _color;
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
        subCategory: _subCategory,
        sleeveLength: _sleeveLength,
        hemLength: _hemLength,
        season: _parseSeason(_season ?? ''),
        scene: _scene,
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
          child: Image.network(
            url,
            height: 200,
            width: double.infinity,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              return Container(
                height: 200,
                color: Colors.black12,
                child: const Center(child: Icon(Icons.broken_image)),
              );
            },
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
    final hemDisabled =
        _category == 'tops' || _category == 'outer' || _category == 'shoes';

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
                    _dropdownField(
                      label: 'カテゴリ（必須）',
                      options: ClothesOptions.categories,
                      value: _category,
                      enabled: !busy,
                      optionLabels: ClothesOptions.categoryLabels,
                      onChanged: (v) {
                        setState(() {
                          _category = v;
                          if (_category == 'tops' ||
                              _category == 'outer' ||
                              _category == 'shoes') {
                            _hemLength = null;
                          }
                        });
                      },
                    ),
                    const SizedBox(height: 12),
                    _dropdownField(
                      label: '色（必須）',
                      options: ClothesOptions.colors,
                      value: _color,
                      enabled: !busy,
                      optionLabels: ClothesOptions.colorLabels,
                      onChanged: (v) {
                        setState(() {
                          _color = v;
                        });
                      },
                    ),
                    const SizedBox(height: 12),
                    _dropdownField(
                      label: 'サブカテゴリ',
                      options: ClothesOptions.subCategories,
                      value: _subCategory,
                      enabled: !busy,
                      optionLabels: ClothesOptions.subCategoryLabels,
                      onChanged: (v) {
                        setState(() {
                          _subCategory = v;
                        });
                      },
                    ),
                    const SizedBox(height: 12),
                    _dropdownField(
                      label: '袖丈',
                      options: ClothesOptions.sleeveLengths,
                      value: _sleeveLength,
                      enabled: !busy,
                      optionLabels: ClothesOptions.sleeveLengthLabels,
                      onChanged: (v) {
                        setState(() {
                          _sleeveLength = v;
                        });
                      },
                    ),
                    const SizedBox(height: 12),
                    if (hemDisabled)
                      TextFormField(
                        enabled: false,
                        initialValue: '丈は設定できません',
                        decoration: InputDecoration(
                          labelText: '丈',
                          border: OutlineInputBorder(),
                        ),
                      )
                    else
                      _dropdownField(
                        label: '丈',
                        options: ClothesOptions.hemLengths,
                        value: _hemLength,
                        enabled: !busy,
                        optionLabels: ClothesOptions.hemLengthLabels,
                        onChanged: (v) {
                          setState(() {
                            _hemLength = v;
                          });
                        },
                      ),
                    const SizedBox(height: 12),
                    _dropdownField(
                      label: '季節',
                      options: ClothesOptions.seasons,
                      value: _season,
                      enabled: !busy,
                      optionLabels: ClothesOptions.seasonLabels,
                      onChanged: (v) {
                        setState(() {
                          _season = v;
                        });
                      },
                    ),
                    const SizedBox(height: 12),
                    _dropdownField(
                      label: 'シーン',
                      options: ClothesOptions.scenes,
                      value: _scene,
                      enabled: !busy,
                      optionLabels: ClothesOptions.sceneLabels,
                      onChanged: (v) {
                        setState(() {
                          _scene = v;
                        });
                      },
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
