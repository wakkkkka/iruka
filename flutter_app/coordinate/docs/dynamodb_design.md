# AIクローゼット DynamoDB 設計（案）

このドキュメントは「ユーザーの持ち服」および「着用記録」をDynamoDBに保存するための設計案です。

## 前提

- `userId` は Cognito のユーザーID（通常は `sub`）を入れる想定
  - メールアドレスはCognitoのユーザー属性であり、DynamoDBの主キーにメールを使うより `sub` 推奨
- 画像はS3に保存し、DynamoDBには **S3 Key（パス）** を保存する

---

## 1. Clothes テーブル（所持服マスター）

ユーザーが自分のクローゼットに登録した服の情報を管理するメインテーブル。

### 主キー

- PK: `userId` (String)
- SK: `clothesId` (String)

例:
- `userId`: `cognito-sub-uuid-12345`
- `clothesId`: `item_001`（ユニークID。UUID/ULID等でもOK）

### 属性

| 物理名 | 型 | 役割 | 例 |
|---|---|---|---|
| userId | String (PK) | パーティションキー | cognito-sub-uuid-12345 |
| clothesId | String (SK) | ソートキー | item_001 |
| category | String | 属性 | tops, bottoms, outer |
| subCategory | String | 属性 | t-shirt, denim/jeans |
| color | String | 属性 | navy, green, white |
| sleeveLength | String | 属性 | short, half, long |
| hemLength | String | 属性 | short, half, long |
| season | String Set (SS) *or* List | 属性 | ["spring", "fall"] |
| scene | String | 属性 | casual, business, feminine, other |
| imageKey | String | 属性 | public/photos/abc-123.jpg |
| categoryColor | String | 検索用属性 | tops#navy |
| createdAt | Number *or* String | 属性 | 1708312345 / 2026-02-19T12:34:56Z |

**補足（型について）**
- DynamoDBの「Set」は `SS`（String Set）です。重複が不要なら `SS` が扱いやすいです。
- `createdAt` は Unix timestamp（Number）でも ISO8601（String）でもOKですが、
  - 並び順や人間可読性を優先するなら ISO8601
  - サイズや比較を優先するなら Unix timestamp

---

## 2. インデックス設計（GSI）

AI解析結果（例: 「ネイビーのトップス」）から高速に検索（Query）するための設計。

### GSI-1: カテゴリ・色 検索用

- Index Name: `byCategoryAndColor`
- Partition Key: `userId`
- Sort Key: `categoryColor`

**メリット**
- Scan（全件読み込み）を回避
- `userId` の範囲で、`categoryColor = "tops#navy"` の条件に合うアイテムを高速抽出

**実装ポイント**
- 登録時に `categoryColor = "${category}#${color}"` を必ず作る
- AIが `category=tops`, `color=navy` を返したら `categoryColor = "tops#navy"` でQuery

---

## 3. WearingLog テーブル（着用記録）

「いつ何を着たか」の履歴を保存。

### 主キー

- PK: `userId` (String)
- SK: `date` (String)

例:
- `date`: `2026-02-19`（日付。ISO形式で固定）

### 属性

| 物理名 | 型 | 役割 | 備考 |
|---|---|---|---|
| userId | String (PK) | パーティションキー | Cognito `sub` |
| date | String (SK) | ソートキー | 2026-02-19 |
| topsId | String | 属性 | Clothes.clothesId |
| bottomsId | String | 属性 | Clothes.clothesId |
| selfieKey | String | 属性 | その日の自撮り画像のS3 Key |

---

## 4. 開発時の実装ポイント（要点）

- `userId` にはメールではなく Cognito の `sub` を使う
- S3はフルURLではなくKey（`public/...`）を保存する
- `categoryColor` を必ず生成して保存する
