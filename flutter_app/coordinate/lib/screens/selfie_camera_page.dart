

import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;


class SelfieCameraPage extends StatefulWidget {
  const SelfieCameraPage({super.key});

  @override
  State<SelfieCameraPage> createState() => _SelfieCameraPageState();
}

class _SelfieCameraPageState extends State<SelfieCameraPage> {
  CameraController? _cameraController;
  List<CameraDescription>? _cameras;
  int _selectedCameraIndex = 0;
  bool _isCameraInitialized = false;
  XFile? _imageFile;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _initCamera();
  }

  Future<void> _initCamera() async {
    _cameras = await availableCameras();
    if (mounted) setState(() {});
    if (_cameras == null || _cameras!.isEmpty) return;
    if (_cameraController == null) {
      int frontCamIndex = _cameras!.indexWhere((cam) => cam.lensDirection == CameraLensDirection.front);
      if (frontCamIndex != -1) {
        _selectedCameraIndex = frontCamIndex;
      }
    }
    await _cameraController?.dispose();
    _cameraController = CameraController(
      _cameras![_selectedCameraIndex],
      ResolutionPreset.high,
      enableAudio: false,
      imageFormatGroup: ImageFormatGroup.jpeg,
    );
    try {
      await _cameraController!.initialize();
      if (!mounted) return;
      setState(() => _isCameraInitialized = true);
    } catch (e) {
      debugPrint("Camera Error: $e");
    }
  }

  Future<void> _toggleCamera() async {
    if (_cameras == null || _cameras!.length < 2) return;
    final currentDirection = _cameras![_selectedCameraIndex].lensDirection;
    final nextDirection = currentDirection == CameraLensDirection.back 
        ? CameraLensDirection.front 
        : CameraLensDirection.back;
    int nextIndex = _cameras!.indexWhere((cam) => cam.lensDirection == nextDirection);
    if (nextIndex == -1) {
      nextIndex = (_selectedCameraIndex + 1) % _cameras!.length;
    }
    setState(() {
      _isCameraInitialized = false;
      _selectedCameraIndex = nextIndex;
    });
    await _initCamera();
  }

  Future<void> _takePicture() async {
    if (!_isCameraInitialized || _cameraController!.value.isTakingPicture) return;
    try {
      final XFile photo = await _cameraController!.takePicture();
      setState(() => _imageFile = photo);
    } catch (e) {
      debugPrint("撮影エラー: $e");
    }
  }

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
    return PopScope(
      canPop: true,
      child: Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          title: const Text('着用記録'),
          backgroundColor: Colors.white,
          elevation: 1,
          foregroundColor: Colors.black,
        ),
        body: Stack(
          children: [
            Positioned.fill(
              child: _imageFile != null
                  ? _buildImageDisplay()
                  : _buildCameraPreview(),
            ),
            Align(
              alignment: Alignment.bottomCenter,
              child: _buildControlPanel(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImageDisplay() {
    return kIsWeb
        ? Image.network(_imageFile!.path, fit: BoxFit.contain)
        : Image.file(File(_imageFile!.path), fit: BoxFit.contain);
  }

  Widget _buildCameraPreview() {
    if (!_isCameraInitialized || _cameraController == null) {
      return const Center(child: CircularProgressIndicator());
    }
    return Container(
      color: Colors.black,
      child: Center(
        child: AspectRatio(
          aspectRatio: 1 / _cameraController!.value.aspectRatio,
          child: CameraPreview(_cameraController!),
        ),
      ),
    );
  }

  Widget _buildControlPanel() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.transparent, Colors.black.withValues(alpha: 0.7)],
        ),
      ),
      child: _imageFile == null ? _buildCameraControls() : _buildPreviewControls(),
    );
  }

  Widget _buildCameraControls() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        _actionButton(Icons.photo_library, "ギャラリー", _pickImageFromGallery),
        _shutterButton(),
        if (_cameras != null && _cameras!.length >= 2)
          _actionButton(
            Icons.flip_camera_ios,
            _cameras![_selectedCameraIndex].lensDirection == CameraLensDirection.front 
                ? "アウトカメ" 
                : "インカメ",
            _toggleCamera,
          )
        else
          const SizedBox(width: 60),
      ],
    );
  }

  Widget _buildPreviewControls() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ElevatedButton(
          onPressed: () => debugPrint("画像確定: \\${_imageFile!.path}"),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.white,
            foregroundColor: Colors.black,
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
            _actionButton(Icons.photo_library, "ギャラリー", _pickImageFromGallery),
          ],
        ),
      ],
    );
  }

  Widget _shutterButton() {
    return GestureDetector(
      onTap: _takePicture,
      child: Container(
        width: 64,
        height: 64,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: 4),
          color: Colors.white.withValues(alpha: 0.2),
        ),
        child: Center(
          child: Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }

  Widget _actionButton(IconData icon, String label, VoidCallback onPressed) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          icon: Icon(icon, size: 32, color: Colors.white),
          onPressed: onPressed,
        ),
        Text(
          label,
          style: const TextStyle(fontSize: 10, color: Colors.white),
        ),
      ],
    );
  }
}