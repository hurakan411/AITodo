# Obey — AIに従うミニマルTodo (MVP)

冷たい SF / 支配された世界観の自己管理型サバイバル Todo。

## 構成
- Frontend: Flutter (iOS/iPadOS 対応)
- Backend: FastAPI (Python)
- DB: Supabase (未設定時はインメモリ fallback)

## 機能 (MVP)
1. 契約儀式 (オンボーディング 3問 YES 必須)
2. タスク登録 (自由テキスト → AI 見積/期限提案)
3. AI 見積 & 期限 (当日/24h 内を優先)
4. 一度だけ期限延長 (ペナルティ重み増加予定)
5. 完了処理 (最小実行時間 1/5 以上 + セルフレポート)
6. 失敗処理 (期限超過 自動失敗 減点)
7. ポイント & ランク (1〜7 / Rank1 失敗で GameOver)
8. ステータス表示 (ポイント / 次閾値 / 最近履歴 / AI セリフ)

## 開発セットアップ

### Backend
```bash
cd backend
python -m venv .venv
source .venv/bin/activate  # Windows: .venv\\Scripts\\activate
pip install -r requirements.txt
cp .env.example .env  # 必要ならキーを設定
uvicorn main:app --reload
```

エンドポイント例:
- GET /health
- POST /tasks/propose {"text": "レポートを書く"}
- POST /tasks/accept (TaskProposal JSON をそのまま)
- POST /tasks/extend {"extra_minutes":30}
- POST /tasks/complete {"self_report":"内容を書いた"}
- GET /tasks/current
- GET /status

### Frontend
```bash
cd frontend
flutter run -d ios
```
iOS シミュレータ起動後に契約画面が表示されます。

### Supabase (後で導入)
`supabase/` にスキーマ追加予定。

## 次ステップ
- タスク作成モーダル/AI提案 UI
- API クライアント接続
- ポイント計算詳細 & ランク閾値調整
- GameOver 画面

## ライセンス
Private / Internal MVP
