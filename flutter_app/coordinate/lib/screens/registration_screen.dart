import 'package:flutter/material.dart';
import '../models/clothing_item.dart';
import '../utils/path_image.dart';

/// 服の登録画面
class RegistrationScreen extends StatefulWidget {
  final String imagePath; // 画像パス（撮影した写真）

  const RegistrationScreen({Key? key, required this.imagePath})
    : super(key: key);

  @override
  State<RegistrationScreen> createState() => _RegistrationScreenState();
}

class _RegistrationScreenState extends State<RegistrationScreen> {
  // フォームの状態管理
  String? selectedCategory;
  String? selectedColor;
  String? selectedThickness;
  String? selectedSleeveLength;
  String? selectedHemLength;
  Set<String> selectedSeasons = {};
  String? selectedScene;

  @override
  void initState() {
    super.initState();
    // 初期値を設定
    selectedCategory = ClothingOptions.categories.first;
    selectedThickness = ClothingOptions.thicknesses[1]; // 普通
    selectedSleeveLength = ClothingOptions.sleeveLengths[1]; // 半袖
    selectedHemLength = ClothingOptions.hemLengths[1]; // ミディアム
    selectedScene = ClothingOptions.scenes.first;
  }

  /// 保存ボタンが押された時の処理
  void _handleSave() {
    // バリデーション
    if (selectedColor == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('カラーを選択してください')));
      return;
    }

    if (selectedSeasons.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('シーズンを1つ以上選択してください')));
      return;
    }

    // ClothingItemオブジェクトを作成
    final clothingItem = ClothingItem(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      imagePath: widget.imagePath,
      category: selectedCategory!,
      color: selectedColor!,
      thickness: selectedThickness!,
      sleeveLength: selectedSleeveLength!,
      hemLength: selectedHemLength!,
      seasons: selectedSeasons.toList(),
      scene: selectedScene!,
      wearingCount: 0,
    );

    // 前の画面に戻る（登録した服のデータを渡す）
    Navigator.pop(context, clothingItem);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('服を登録'), centerTitle: true),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 画像プレビュー
              _buildImagePreview(),
              const SizedBox(height: 24),

              // 大カテゴリ
              _buildCategoryDropdown(),
              const SizedBox(height: 24),

              // カラー
              _buildColorSelection(),
              const SizedBox(height: 24),

              // 厚さ
              _buildThicknessSelection(),
              const SizedBox(height: 24),

              // 袖の長さ
              _buildSleeveLengthSelection(),
              const SizedBox(height: 24),

              // 裾の長さ
              _buildHemLengthSelection(),
              const SizedBox(height: 24),

              // シーズン
              _buildSeasonSelection(),
              const SizedBox(height: 24),

              // シーン
              _buildSceneSelection(),
              const SizedBox(height: 32),

              // 保存ボタン
              _buildSaveButton(),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  /// 画像プレビュー
  Widget _buildImagePreview() {
    return Center(
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: widget.imagePath.startsWith('assets/')
              ? // アセット画像の場合
                Container(
                  height: 300,
                  width: double.infinity,
                  color: Colors.grey.shade200,
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.image_outlined,
                          size: 80,
                          color: Colors.grey.shade400,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'プレビュー画像',
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              : // ファイルパスの場合
                buildPathImage(
                  path: widget.imagePath,
                  height: 300,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    // エラー時のプレースホルダー
                    return Container(
                      height: 300,
                      width: double.infinity,
                      color: Colors.grey.shade200,
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.broken_image_outlined,
                              size: 80,
                              color: Colors.grey.shade400,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '画像の読み込みに失敗しました',
                              style: TextStyle(
                                color: Colors.grey.shade600,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),
      ),
    );
  }

  /// 大カテゴリ選択
  Widget _buildCategoryDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '大カテゴリ',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(8),
          ),
          child: DropdownButton<String>(
            value: selectedCategory,
            isExpanded: true,
            underline: const SizedBox(),
            items: ClothingOptions.categories.map((category) {
              return DropdownMenuItem(value: category, child: Text(category));
            }).toList(),
            onChanged: (value) {
              setState(() {
                selectedCategory = value;
              });
            },
          ),
        ),
      ],
    );
  }

  /// カラー選択
  Widget _buildColorSelection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'カラー',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: ClothingOptions.colors.map((color) {
            final isSelected = selectedColor == color;
            return ChoiceChip(
              label: Text(color),
              selected: isSelected,
              onSelected: (selected) {
                setState(() {
                  selectedColor = color;
                });
              },
              selectedColor: Theme.of(context).colorScheme.primaryContainer,
              labelStyle: TextStyle(
                color: isSelected
                    ? Theme.of(context).colorScheme.onPrimaryContainer
                    : null,
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  /// 厚さ選択
  Widget _buildThicknessSelection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '厚さ',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        SegmentedButton<String>(
          segments: ClothingOptions.thicknesses.map((thickness) {
            return ButtonSegment(value: thickness, label: Text(thickness));
          }).toList(),
          selected: {selectedThickness!},
          onSelectionChanged: (Set<String> newSelection) {
            setState(() {
              selectedThickness = newSelection.first;
            });
          },
        ),
      ],
    );
  }

  /// 袖の長さ選択
  Widget _buildSleeveLengthSelection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '袖の長さ',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: ClothingOptions.sleeveLengths.map((length) {
            final isSelected = selectedSleeveLength == length;
            return ChoiceChip(
              label: Text(length),
              selected: isSelected,
              onSelected: (selected) {
                setState(() {
                  selectedSleeveLength = length;
                });
              },
              selectedColor: Theme.of(context).colorScheme.primaryContainer,
              labelStyle: TextStyle(
                color: isSelected
                    ? Theme.of(context).colorScheme.onPrimaryContainer
                    : null,
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  /// 裾の長さ選択
  Widget _buildHemLengthSelection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '裾の長さ',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: ClothingOptions.hemLengths.map((length) {
            final isSelected = selectedHemLength == length;
            return ChoiceChip(
              label: Text(length),
              selected: isSelected,
              onSelected: (selected) {
                setState(() {
                  selectedHemLength = length;
                });
              },
              selectedColor: Theme.of(context).colorScheme.primaryContainer,
              labelStyle: TextStyle(
                color: isSelected
                    ? Theme.of(context).colorScheme.onPrimaryContainer
                    : null,
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  /// シーズン選択（複数選択可能）
  Widget _buildSeasonSelection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'シーズン（複数選択可）',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: ClothingOptions.seasons.map((season) {
            final isSelected = selectedSeasons.contains(season);
            return FilterChip(
              label: Text(season),
              selected: isSelected,
              onSelected: (selected) {
                setState(() {
                  if (selected) {
                    selectedSeasons.add(season);
                  } else {
                    selectedSeasons.remove(season);
                  }
                });
              },
              selectedColor: Theme.of(context).colorScheme.primaryContainer,
              checkmarkColor: Theme.of(context).colorScheme.onPrimaryContainer,
              labelStyle: TextStyle(
                color: isSelected
                    ? Theme.of(context).colorScheme.onPrimaryContainer
                    : null,
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  /// シーン選択
  Widget _buildSceneSelection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'シーン',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: ClothingOptions.scenes.map((scene) {
            final isSelected = selectedScene == scene;
            return ChoiceChip(
              label: Text(scene),
              selected: isSelected,
              onSelected: (selected) {
                setState(() {
                  selectedScene = scene;
                });
              },
              selectedColor: Theme.of(context).colorScheme.primaryContainer,
              labelStyle: TextStyle(
                color: isSelected
                    ? Theme.of(context).colorScheme.onPrimaryContainer
                    : null,
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  /// 保存ボタン
  Widget _buildSaveButton() {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: FilledButton(
        onPressed: _handleSave,
        child: const Text(
          '保存する',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}
