import 'dart:io';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'registration_complete_page.dart';

class ReviewPage extends StatefulWidget {
  final String imagePath;
  const ReviewPage({super.key, required this.imagePath});

  @override
  State<ReviewPage> createState() => _ReviewPageState();
}

class _ReviewPageState extends State<ReviewPage> {
  final List<String> _suggestedTags = ['Tシャツ', 'シャツ', 'パーカー', 'ニット', 'コート'];
  final Set<String> _selectedTags = {};

  void _toggleTag(String tag) {
    setState(() {
      if (_selectedTags.contains(tag)) {
        _selectedTags.remove(tag);
      } else {
        _selectedTags.add(tag);
      }
    });
  }

  void _showCandidates() {
    showModalBottomSheet(
      context: context,
      builder: (context) => SizedBox(
        height: 240,
        child: ListView(
          children: [
            ListTile(title: Text('候補1: Tシャツ / 白')),
            ListTile(title: Text('候補2: シャツ / 青')),
            ListTile(title: Text('候補3: パーカー / グレー')),
          ],
        ),
      ),
    );
  }

  void _completeRegistration() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const RegistrationCompletePage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('解析結果の確認')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Center(
                child: widget.imagePath.isEmpty
                    ? const Icon(Icons.image, size: 120)
                    : kIsWeb
                    ? Image.network(widget.imagePath)
                    : Image.file(File(widget.imagePath)),
              ),
            ),
            const SizedBox(height: 12),
            const Text('AI推定タグ（選択・編集してください）', style: TextStyle(fontSize: 16)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: _suggestedTags.map((t) {
                final selected = _selectedTags.contains(t);
                return FilterChip(
                  label: Text(t),
                  selected: selected,
                  onSelected: (_) => _toggleTag(t),
                );
              }).toList(),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: _completeRegistration,
                    child: const Text('登録する'),
                  ),
                ),
                const SizedBox(width: 12),
                OutlinedButton(
                  onPressed: _showCandidates,
                  child: const Text('候補を表示'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
