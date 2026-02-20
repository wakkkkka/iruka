import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;

class CameraPage extends StatefulWidget {
  const CameraPage({super.key});

  @override
  State<CameraPage> createState() => _CameraPageState();
}

class _CameraPageState extends State<CameraPage> {
  XFile? _imageFile;
  final ImagePicker _picker = ImagePicker();

  Future<void> _pickImage(ImageSource source) async {
    try {
      // Linux環境ではカメラを使用できないため、ギャラリーのみ
      if (!kIsWeb && Platform.isLinux && source == ImageSource.camera) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Linux環境ではギャラリーからのみ選択できます')),
        );
        return;
      }
      final photo = await _picker.pickImage(source: source);
      if (photo != null) {
        setState(() => _imageFile = photo);
      }
    } catch (e) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('エラー: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('着用記録'),
        backgroundColor: Colors.white,
        elevation: 1,
      ),
      body: Column(
        children: [
          Expanded(
            child: Center(
              child: _imageFile != null
                  ? kIsWeb
                      ? Image.network(_imageFile!.path)
                      : Image.file(File(_imageFile!.path))
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
    return Container(
      padding: const EdgeInsets.all(40),
      child: _imageFile == null
          ? Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _actionButton(
                  Icons.image,
                  "ギャラリー",
                  () => _pickImage(ImageSource.gallery),
                ),
                // Linux環境ではカメラボタンを表示しない
                if (!Platform.isLinux || kIsWeb)
                  _actionButton(
                    Icons.camera_alt,
                    "カメラで撮る",
                    () => _pickImage(ImageSource.camera),
                  ),
              ],
            )
          : Column(
              children: [
                ElevatedButton(
                  onPressed: () {
                    print("画像確定: ${_imageFile!.path}");
                  },
                  child: const Text("この写真で解析する"),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    setState(() => _imageFile = null);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey,
                  ),
                  child: const Text("別の写真を選択"),
                ),
              ],
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