class ClothesOptions {
  static const List<String> categories = <String>[
    'tops',
    'bottoms',
    'outer',
    'dress',
    'shoes',
  ];

  static const Map<String, String> categoryLabels = <String, String>{
    'tops': 'トップス',
    'bottoms': 'ボトムス',
    'outer': 'アウター',
    'dress': 'ワンピース',
    'shoes': 'シューズ',
  };

  static const List<String> subCategories = <String>[
    't-shirt',
    'shirt/blouse',
    'knit/sweater',
    'sweatshirt/hoodie',
    'denim/jeans',
    'slacks/pants',
    'skirt',
    'shorts',
    'jacket/coat',
    'cardigan',
    'one-piece',
    'setup',
    'sneakers',
    'leather/pumps',
    'boots',
    'sandals',
  ];

  static const Map<String, String> subCategoryLabels = <String, String>{
    't-shirt': 'Tシャツ',
    'shirt/blouse': 'シャツ/ブラウス',
    'knit/sweater': 'ニット/セーター',
    'sweatshirt/hoodie': 'スウェット/パーカー',
    'denim/jeans': 'デニム/ジーンズ',
    'slacks/pants': 'スラックス/パンツ',
    'skirt': 'スカート',
    'shorts': 'ショーツ',
    'jacket/coat': 'ジャケット/コート',
    'cardigan': 'カーディガン',
    'one-piece': 'ワンピース',
    'setup': 'セットアップ',
    'sneakers': 'スニーカー',
    'leather/pumps': 'レザー/パンプス',
    'boots': 'ブーツ',
    'sandals': 'サンダル',
  };

  static const List<String> colors = <String>[
    'white',
    'black',
    'gray',
    'brown',
    'beige',
    'blue',
    'navy',
    'green',
    'yellow',
    'orange',
    'red',
    'pink',
    'purple',
    'gold',
    'silver',
    'denim',
    'multi-color',
  ];

  static const Map<String, String> colorLabels = <String, String>{
    'white': '白',
    'black': '黒',
    'gray': 'グレー',
    'brown': 'ブラウン',
    'beige': 'ベージュ',
    'blue': 'ブルー',
    'navy': 'ネイビー',
    'green': 'グリーン',
    'yellow': 'イエロー',
    'orange': 'オレンジ',
    'red': 'レッド',
    'pink': 'ピンク',
    'purple': 'パープル',
    'gold': 'ゴールド',
    'silver': 'シルバー',
    'denim': 'デニム',
    'multi-color': 'マルチ',
  };

  static const List<String> sleeveLengths = <String>['short', 'half', 'long'];

  static const Map<String, String> sleeveLengthLabels = <String, String>{
    'short': '半袖',
    'half': '五分袖',
    'long': '長袖',
  };

  static const List<String> hemLengths = <String>['short', 'half', 'long'];

  static const Map<String, String> hemLengthLabels = <String, String>{
    'short': '短め',
    'half': 'ミドル',
    'long': '長め',
  };

  static const List<String> seasons = <String>[
    'spring',
    'summer',
    'fall',
    'winter',
  ];

  static const Map<String, String> seasonLabels = <String, String>{
    'spring': '春',
    'summer': '夏',
    'fall': '秋',
    'winter': '冬',
  };

  static const List<String> scenes = <String>[
    'casual',
    'business',
    'feminine',
    'other',
  ];

  static const Map<String, String> sceneLabels = <String, String>{
    'casual': 'カジュアル',
    'business': 'ビジネス',
    'feminine': 'フェミニン',
    'other': 'その他',
  };

  static String labelFor(String value, Map<String, String> labels) {
    return labels[value] ?? value;
  }
}
