import 'dart:math';
import 'dart:typed_data';
import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:flutter/foundation.dart'
    show kIsWeb, defaultTargetPlatform, TargetPlatform;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import '../services/clothes_api_service.dart';
import '../services/selfie_api_service.dart';
import '../constants/clothes_options.dart';

enum CameraPagePurpose { registerItem, selfie }

class CameraPage extends StatefulWidget {
  const CameraPage({
    super.key,
    required this.purpose,
    this.initialImageFile,
    this.initialImageBytes,
  });

  final CameraPagePurpose purpose;
  final XFile? initialImageFile;
  final Uint8List? initialImageBytes;

  @override
  State<CameraPage> createState() => _CameraPageState();
}

class _CameraPageState extends State<CameraPage> {
  XFile? _imageFile;
  Uint8List? _imageBytes;
  final ImagePicker _picker = ImagePicker();
  final ClothesApiService _clothesApiService = ClothesApiService();
  final SelfieApiService _selfieApiService = SelfieApiService();

  bool _autoSelfieAnalyzeScheduled = false;

  @override
  void initState() {
    super.initState();

    final initialFile = widget.initialImageFile;
    final initialBytes = widget.initialImageBytes;
    if (initialFile != null && initialBytes != null) {
      _imageFile = initialFile;
      _imageBytes = initialBytes;
      _scheduleAutoSelfieAnalyzeIfNeeded();
    } else if (initialFile != null) {
      _imageFile = initialFile;
      // Load bytes lazily.
      Future.microtask(() async {
        try {
          final bytes = await initialFile.readAsBytes();
          if (!mounted) return;
          setState(() {
            _imageBytes = bytes;
          });
          _scheduleAutoSelfieAnalyzeIfNeeded();
        } catch (_) {
          // Ignore; UI will ask user to re-select.
        }
      });
    }
  }

  void _scheduleAutoSelfieAnalyzeIfNeeded() {
    if (_autoSelfieAnalyzeScheduled) return;
    if (widget.purpose != CameraPagePurpose.selfie) return;
    if (_imageFile == null || _imageBytes == null) return;

    _autoSelfieAnalyzeScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (_isSubmitting) return;
      if (_analyzeResults.isNotEmpty) return;
      if (_selfieKey != null && _selfieKey!.trim().isNotEmpty) return;
      _runSelfieAnalyze();
    });
  }

  bool _isSubmitting = false;

  String? _selfieKey;
  List<Map<String, dynamic>> _analyzeResults = const [];
  Map<String, String> _selections = const {};
  final Map<String, Future<String>> _imageUrlFutures = {};

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();

  String? _category;
  String? _color;
  String? _subCategory;
  String? _sleeveLength;
  String? _hemLength;
  String? _season;
  String? _scene;

  @override
  void dispose() {
    _nameController.dispose();
    _notesController.dispose();
    super.dispose();
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

  Future<String> _resolveImageUrl(String storagePath) {
    final trimmed = storagePath.trim();
    return _imageUrlFutures.putIfAbsent(trimmed, () async {
      final result = await Amplify.Storage.getUrl(
        path: StoragePath.fromString(trimmed),
      ).result;
      return result.url.toString();
    });
  }

  String _isoDateLocal(DateTime dt) {
    final y = dt.year.toString().padLeft(4, '0');
    final m = dt.month.toString().padLeft(2, '0');
    final d = dt.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  Future<String> _uploadToStorage({
    required String folder,
    required XFile imageFile,
    required Uint8List imageBytes,
  }) async {
    final user = await Amplify.Auth.getCurrentUser();
    final userId = user.userId;

    final extFromName = p.extension(imageFile.name);
    final extFromPath = p.extension(imageFile.path);
    final ext = (extFromName.isNotEmpty ? extFromName : extFromPath);
    final fileName = _buildUniqueFileName(extension: ext);
    final objectPath = 'public/users/$userId/$folder/$fileName';

    await Amplify.Storage.uploadData(
      data: StorageDataPayload.bytes(imageBytes),
      path: StoragePath.fromString(objectPath),
    ).result;

    return objectPath;
  }

  String _selectionKeyForDetected(Map<String, dynamic>? detected, int index) {
    final category = detected?['category'];
    if (category is String && category.trim().isNotEmpty) {
      final parts = <String>[category.trim()];
      final sub = detected?['subCategory'];
      if (sub is String && sub.trim().isNotEmpty) {
        parts.add(sub.trim());
      }
      final color = detected?['color'];
      if (color is String && color.trim().isNotEmpty) {
        parts.add(color.trim());
      }
      return '${parts.join('|')}#$index';
    }
    return 'item$index';
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

    final category = _category;
    final color = _color;
    if (category == null || color == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('カテゴリと色は必須です')));
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      final objectPath = await _uploadToStorage(
        folder: 'items',
        imageFile: imageFile,
        imageBytes: imageBytes,
      );

      final created = await _clothesApiService.createClothes(
        category: category,
        color: color,
        subCategory: _subCategory,
        sleeveLength: _sleeveLength,
        hemLength: _hemLength,
        season: _parseSeason(_season ?? ''),
        scene: _scene,
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

  Future<void> _runSelfieAnalyze() async {
    if (_isSubmitting) return;
    final imageFile = _imageFile;
    final imageBytes = _imageBytes;
    if (imageFile == null || imageBytes == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('先に写真を選択してください')));
      return;
    }
    if (widget.purpose != CameraPagePurpose.selfie) return;

    setState(() {
      _isSubmitting = true;
      _analyzeResults = const [];
      _selections = const {};
      _selfieKey = null;
    });

    try {
      final objectPath = await _uploadToStorage(
        folder: 'selfies',
        imageFile: imageFile,
        imageBytes: imageBytes,
      );

      final selfieUrl = await _resolveImageUrl(objectPath);

      final decoded = await _selfieApiService.analyzeSelfie(
        selfieKey: objectPath,
        selfieUrl: selfieUrl,
        topK: 3,
      );

      final results = decoded['results'];
      final parsed = <Map<String, dynamic>>[];
      if (results is List) {
        for (final e in results) {
          if (e is Map) {
            parsed.add(Map<String, dynamic>.from(e));
          }
        }
      }

      if (!mounted) return;
      setState(() {
        _selfieKey = objectPath;
        _analyzeResults = parsed;
        _selections = {};
      });

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('解析が完了しました。候補を選択してください')));
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
      ).showSnackBar(SnackBar(content: Text('解析に失敗しました: $e')));
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  Future<void> _saveSelfieLog() async {
    if (_isSubmitting) return;
    if (widget.purpose != CameraPagePurpose.selfie) return;
    if (_analyzeResults.isEmpty) return;

    final nextSelections = <String, String>{};
    for (var i = 0; i < _analyzeResults.length; i++) {
      final detectedRaw = _analyzeResults[i]['detected'];
      final detected = detectedRaw is Map
          ? Map<String, dynamic>.from(detectedRaw)
          : null;

      final candidatesRaw = _analyzeResults[i]['candidates'];
      final hasCandidates = candidatesRaw is List && candidatesRaw.isNotEmpty;
      if (!hasCandidates) {
        // Nothing to select for this detected item.
        continue;
      }

      final key = _selectionKeyForDetected(detected, i);
      final selected = _selections[key];
      if (selected == null || selected.trim().isEmpty) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('各アイテムの候補を選択してください')));
        return;
      }
      nextSelections[key] = selected.trim();
    }

    if (nextSelections.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('候補が見つからなかったため記録できませんでした')));
      return;
    }

    final date = _isoDateLocal(DateTime.now());

    setState(() {
      _isSubmitting = true;
    });
    try {
      final ids = nextSelections.values.toSet().toList();
      await _selfieApiService.createWearLog(
        date: date,
        selfieKey: _selfieKey,
        selections: nextSelections,
        clothesIds: ids,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('記録しました')));
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('記録に失敗しました: $e')));
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
        : '自撮り';

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(title),
        backgroundColor: Colors.white,
        elevation: 1,
      ),
      body: Column(
        children: [
          Flexible(
            child: Center(
              child: _imageBytes != null
                  ? Image.memory(_imageBytes!, fit: BoxFit.contain)
                  : _buildPlaceholder(),
            ),
          ),
          Expanded(child: _buildControlPanel()),
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
    final hemDisabled =
        _category == 'tops' || _category == 'outer' || _category == 'shoes';
    return Container(
      padding: const EdgeInsets.all(24),
      child: _imageFile == null
          ? Center(
              child: Row(
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
              ),
            )
          : SingleChildScrollView(
              child: Column(
                children: [
                  if (widget.purpose == CameraPagePurpose.registerItem) ...[
                    _dropdownField(
                      label: 'カテゴリ（必須）',
                      options: ClothesOptions.categories,
                      value: _category,
                      enabled: !_isSubmitting,
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
                      enabled: !_isSubmitting,
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
                      enabled: !_isSubmitting,
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
                      enabled: !_isSubmitting,
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
                        enabled: !_isSubmitting,
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
                      enabled: !_isSubmitting,
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
                      enabled: !_isSubmitting,
                      optionLabels: ClothesOptions.sceneLabels,
                      onChanged: (v) {
                        setState(() {
                          _scene = v;
                        });
                      },
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

                  if (widget.purpose == CameraPagePurpose.selfie &&
                      _analyzeResults.isNotEmpty) ...[
                    _buildAnalyzeResults(),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isSubmitting ? null : _saveSelfieLog,
                        child: _isSubmitting
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Text('この内容で記録する'),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isSubmitting
                          ? null
                          : (widget.purpose == CameraPagePurpose.registerItem
                                ? _uploadAndCreateClothes
                                : _runSelfieAnalyze),
                      child: _isSubmitting
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Text(
                              widget.purpose == CameraPagePurpose.registerItem
                                  ? 'この写真で登録する'
                                  : 'この写真で解析する',
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
                                _selfieKey = null;
                                _analyzeResults = const [];
                                _selections = const {};
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

  Widget _buildAnalyzeResults() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          '候補',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        for (var i = 0; i < _analyzeResults.length; i++) ...[
          _buildDetectedBlock(_analyzeResults[i], i),
          const SizedBox(height: 12),
        ],
      ],
    );
  }

  Widget _buildDetectedBlock(Map<String, dynamic> block, int index) {
    final detectedRaw = block['detected'];
    final detected = detectedRaw is Map
        ? Map<String, dynamic>.from(detectedRaw)
        : null;
    final candidatesRaw = block['candidates'];

    final candidates = <Map<String, dynamic>>[];
    if (candidatesRaw is List) {
      for (final e in candidatesRaw) {
        if (e is Map) {
          candidates.add(Map<String, dynamic>.from(e));
        }
      }
    }

    final selectionKey = _selectionKeyForDetected(detected, index);
    final selectedId = _selections[selectionKey];

    final labelParts = <String>[];
    final category = detected?['category'];
    final color = detected?['color'];
    final sub = detected?['subCategory'];
    if (category is String && category.trim().isNotEmpty) {
      labelParts.add(category.trim());
    }
    if (sub is String && sub.trim().isNotEmpty) {
      labelParts.add(sub.trim());
    }
    if (color is String && color.trim().isNotEmpty) {
      labelParts.add('色:${color.trim()}');
    }
    final label = labelParts.isEmpty ? '検出アイテム' : labelParts.join(' / ');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: Colors.black87),
        ),
        const SizedBox(height: 8),
        if (candidates.isEmpty)
          const Text(
            '候補がありません',
            style: TextStyle(fontSize: 12, color: Colors.black54),
          )
        else
          SizedBox(
            height: 130,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: candidates.length,
              separatorBuilder: (context, i) => const SizedBox(width: 8),
              itemBuilder: (context, i) {
                final c = candidates[i];
                final id = (c['clothesId'] is String)
                    ? (c['clothesId'] as String).trim()
                    : '';
                final imageUrl = c['imageUrl'];
                final isSelected = selectedId != null && selectedId == id;

                return InkWell(
                  onTap: id.isEmpty
                      ? null
                      : () {
                          setState(() {
                            _selections = {..._selections, selectionKey: id};
                          });
                        },
                  child: Container(
                    width: 110,
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border.all(
                        color: isSelected ? Colors.deepPurple : Colors.black12,
                        width: isSelected ? 2 : 1,
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Expanded(
                          child:
                              (imageUrl is String && imageUrl.trim().isNotEmpty)
                              ? _buildCandidateThumbnail(imageUrl)
                              : Container(
                                  color: Colors.black12,
                                  child: const Icon(Icons.image),
                                ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          (c['subCategory'] is String &&
                                  (c['subCategory'] as String)
                                      .trim()
                                      .isNotEmpty)
                              ? (c['subCategory'] as String).trim()
                              : ((c['category'] is String)
                                    ? (c['category'] as String).trim()
                                    : 'アイテム'),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 11),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
      ],
    );
  }

  Widget _buildCandidateThumbnail(String storagePath) {
    return FutureBuilder<String>(
      future: _resolveImageUrl(storagePath),
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return Container(
            color: Colors.black12,
            child: const Center(
              child: SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          );
        }
        final url = snapshot.data;
        if (url == null || url.isEmpty || snapshot.hasError) {
          return Container(
            color: Colors.black12,
            child: const Icon(Icons.image_not_supported),
          );
        }
        return ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: Image.network(
            url,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              return Container(
                color: Colors.black12,
                child: const Icon(Icons.broken_image),
              );
            },
          ),
        );
      },
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
