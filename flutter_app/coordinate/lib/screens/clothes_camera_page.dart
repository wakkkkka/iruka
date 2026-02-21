import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'clothes_detail_page.dart';

class ClothesCameraPage extends StatefulWidget {
  const ClothesCameraPage({super.key});

  @override
  State<ClothesCameraPage> createState() => _ClothesCameraPageState();
}

class _ClothesCameraPageState extends State<ClothesCameraPage> {
  CameraController? _cameraController;
  bool _isCameraInitialized = false;
  XFile? _imageFile; // 撮影・選択されたファイルを保持
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _initCamera();
  }

  Future<void> _initCamera() async {
    final cameras = await availableCameras();
    if (cameras.isEmpty) return;

    // 背面カメラを選択
    final camera = cameras.firstWhere(
      (cam) => cam.lensDirection == CameraLensDirection.back,
      orElse: () => cameras.first,
    );

    _cameraController = CameraController(
      camera,
      ResolutionPreset.high,
      enableAudio: false,
    );

    try {
      await _cameraController!.initialize();
      if (!mounted) return;
      setState(() => _isCameraInitialized = true);
    } catch (e) {
      debugPrint("Camera Error: $e");
    }
  }

  // 撮影処理
  Future<void> _takePicture() async {
    if (!_isCameraInitialized || _cameraController!.value.isTakingPicture) return;
    try {
      final XFile photo = await _cameraController!.takePicture();
      setState(() => _imageFile = photo);
    } catch (e) {
      debugPrint("撮影エラー: $e");
    }
  }

  // ギャラリー選択処理
  Future<void> _pickImageFromGallery() async {
    try {
      final photo = await _picker.pickImage(source: ImageSource.gallery);
      if (photo != null) {
        setState(() => _imageFile = photo);
      }
    } catch (e) {
      debugPrint("ギャラリーエラー: $e");
    }
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // 戻るボタンの挙動制御（以前のコードのWillPopScopeを継承）
    return PopScope(
      canPop: true,
      child: Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          title: const Text('新規服登録'),
          backgroundColor: Colors.white,
          elevation: 1,
          foregroundColor: Colors.black,
        ),
        body: Stack(
          children: [
            // --- プレビュー/画像表示層 ---
            Positioned.fill(
              child: _imageFile != null
                  ? _buildImageDisplay() // 撮影・選択後の表示
                  : _buildCameraPreview(), // カメラ生中継
            ),

            // --- UI操作層 ---
            Align(
              alignment: Alignment.bottomCenter,
              child: _buildControlPanel(),
            ),
          ],
        ),
      ),
    );
  }

  // 画像表示（撮影後）
  Widget _buildImageDisplay() {
    return kIsWeb
        ? Image.network(_imageFile!.path, fit: BoxFit.contain)
        : Image.file(File(_imageFile!.path), fit: BoxFit.contain);
  }

  // カメラプレビュー（歪み対策済み）
  Widget _buildCameraPreview() {
    if (!_isCameraInitialized || _cameraController == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return ClipRect(
      child: FittedBox(
        fit: BoxFit.cover,
        child: SizedBox(
          width: _cameraController!.value.previewSize!.height,
          height: _cameraController!.value.previewSize!.width,
          child: CameraPreview(_cameraController!),
        ),
      ),
    );
  }

  // コントロールパネル（元のコードのロジックを統合）
  Widget _buildControlPanel() {
    return Container(
      padding: const EdgeInsets.fromLTRB(40, 20, 40, 40),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.transparent, Colors.black.withValues(alpha: 0.7)],
        ),
      ),
      child: _imageFile == null
          ? Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _actionButton(Icons.image, "ギャラリー", _pickImageFromGallery),
                _shutterButton(),
                // スペース調整用の空要素（左右バランスのため）
                const SizedBox(width: 60),
              ],
            )
          : Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ClothesDetailPage(imagePath: _imageFile!.path),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                  ),
                  child: const Text("この写真で服を登録する"),
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _actionButton(Icons.refresh, "撮り直す", () {
                      setState(() => _imageFile = null);
                    }),
                    _actionButton(Icons.image, "ギャラリー", _pickImageFromGallery),
                  ],
                ),
              ],
            ),
    );
  }

  // シャッターボタン
  Widget _shutterButton() {
    return GestureDetector(
      onTap: _takePicture,
      child: Container(
        height: 70,
        width: 70,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: 4),
        ),
        child: Container(
          margin: const EdgeInsets.all(4),
          decoration: const BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
          ),
        ),
      ),
    );
  }

  // アイコンボタン
  Widget _actionButton(IconData icon, String label, VoidCallback onPressed) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          icon: Icon(icon, size: 35, color: Colors.white),
          onPressed: onPressed,
        ),
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: Colors.white),
        ),
      ],
    );
  }
}