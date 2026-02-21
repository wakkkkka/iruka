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
      final objectPath = await _uploadToStorage(
        folder: 'items',
        imageFile: imageFile,
        imageBytes: imageBytes,
      );

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
