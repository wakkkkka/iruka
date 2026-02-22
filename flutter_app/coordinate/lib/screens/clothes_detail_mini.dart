import 'package:flutter/material.dart';

// アイテムIDから画像とタグを簡易表示するウィジェット
class ClothesDetailMini extends StatelessWidget {
  final String id;
  const ClothesDetailMini({super.key, required this.id});

  @override
  Widget build(BuildContext context) {
    // ここでは簡易的にIDのみ表示。実際はWearRepository等から画像やタグを取得して表示する実装に拡張可能。
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          const Icon(Icons.checkroom, size: 18),
          const SizedBox(width: 4),
          Text('アイテムID: $id', style: const TextStyle(fontSize: 13)),
        ],
      ),
    );
  }
}
