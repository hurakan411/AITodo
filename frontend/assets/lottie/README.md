# Lottie アニメーション配置場所

このディレクトリに Lottie JSON ファイルを配置してください。

## 推奨ファイル名

- `ai_neutral.json` - Rank 3（中立・バランス）
- `ai_cold.json` - Rank 1-2（失望・警告）
- `ai_warm.json` - Rank 4-5（信頼・好感）
- `ai_awakened.json` - Rank 6-7（親愛・覚醒）

## 使い方

Flutter コード内で以下のように読み込みます:

```dart
import 'package:lottie/lottie.dart';

Lottie.asset('assets/lottie/ai_neutral.json', width: 100, height: 100)
```

## Lottie アニメーション入手先

- LottieFiles: https://lottiefiles.com/
- 無料アニメーションを探して JSON をダウンロード
- SF / ロボット / AI 系のキーワードで検索すると見つかりやすい

## サンプルプレースホルダー

実際のアニメーションが無い場合、プレースホルダー実装が `home_screen.dart` と `profile_screen.dart` に入っています（グレーの枠のみ）。
