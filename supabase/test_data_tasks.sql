-- tasksテーブルにテストデータを20件INSERT
-- 注意: user_idは既存のprofilesテーブルのuser_idに置き換えてください

-- 既存のuser_idを取得（最初のユーザー）
DO $$
DECLARE
    target_user_id uuid;
BEGIN
    SELECT user_id INTO target_user_id FROM profiles LIMIT 1;
    
    -- タスク1: 完了したタスク
    INSERT INTO tasks (user_id, title, status, estimate_minutes, weight, created_at, deadline_at, extension_used, completed_at, self_report)
    VALUES (target_user_id, 'レポートを作成する', 'COMPLETED', 180, 3, NOW() - INTERVAL '5 days', NOW() - INTERVAL '4 days', false, NOW() - INTERVAL '4 days 2 hours', 'レポートを完成させました');
    
    -- タスク2: 完了したタスク
    INSERT INTO tasks (user_id, title, status, estimate_minutes, weight, created_at, deadline_at, extension_used, completed_at, self_report)
    VALUES (target_user_id, 'メールを返信する', 'COMPLETED', 30, 1, NOW() - INTERVAL '4 days', NOW() - INTERVAL '3 days', false, NOW() - INTERVAL '3 days 5 hours', 'すべてのメールに返信しました');
    
    -- タスク3: 失敗したタスク
    INSERT INTO tasks (user_id, title, status, estimate_minutes, weight, created_at, deadline_at, extension_used, failed_at)
    VALUES (target_user_id, 'プレゼン資料を準備する', 'FAILED', 240, 4, NOW() - INTERVAL '10 days', NOW() - INTERVAL '9 days', false, NOW() - INTERVAL '9 days');
    
    -- タスク4: 完了したタスク
    INSERT INTO tasks (user_id, title, status, estimate_minutes, weight, created_at, deadline_at, extension_used, completed_at, self_report)
    VALUES (target_user_id, 'データベース設計を見直す', 'COMPLETED', 120, 2, NOW() - INTERVAL '8 days', NOW() - INTERVAL '7 days', false, NOW() - INTERVAL '7 days 1 hour', '設計を完了しました');
    
    -- タスク5: 完了したタスク
    INSERT INTO tasks (user_id, title, status, estimate_minutes, weight, created_at, deadline_at, extension_used, completed_at, self_report)
    VALUES (target_user_id, 'コードレビューを実施する', 'COMPLETED', 90, 2, NOW() - INTERVAL '6 days', NOW() - INTERVAL '5 days', false, NOW() - INTERVAL '5 days 3 hours', 'レビューを完了しました');
    
    -- タスク6: 失敗したタスク
    INSERT INTO tasks (user_id, title, status, estimate_minutes, weight, created_at, deadline_at, extension_used, failed_at)
    VALUES (target_user_id, 'ドキュメントを更新する', 'FAILED', 60, 1, NOW() - INTERVAL '7 days', NOW() - INTERVAL '6 days', false, NOW() - INTERVAL '6 days');
    
    -- タスク7: 完了したタスク
    INSERT INTO tasks (user_id, title, status, estimate_minutes, weight, created_at, deadline_at, extension_used, completed_at, self_report)
    VALUES (target_user_id, 'バグを修正する', 'COMPLETED', 150, 3, NOW() - INTERVAL '3 days', NOW() - INTERVAL '2 days', false, NOW() - INTERVAL '2 days 4 hours', 'バグを修正しました');
    
    -- タスク8: 完了したタスク
    INSERT INTO tasks (user_id, title, status, estimate_minutes, weight, created_at, deadline_at, extension_used, completed_at, self_report)
    VALUES (target_user_id, 'ミーティング議事録を作成', 'COMPLETED', 45, 1, NOW() - INTERVAL '2 days', NOW() - INTERVAL '1 day', false, NOW() - INTERVAL '1 day 6 hours', '議事録を共有しました');
    
    -- タスク9: 完了したタスク
    INSERT INTO tasks (user_id, title, status, estimate_minutes, weight, created_at, deadline_at, extension_used, completed_at, self_report)
    VALUES (target_user_id, 'テストケースを作成する', 'COMPLETED', 180, 3, NOW() - INTERVAL '9 days', NOW() - INTERVAL '8 days', false, NOW() - INTERVAL '8 days 2 hours', 'テストケースを作成しました');
    
    -- タスク10: 失敗したタスク
    INSERT INTO tasks (user_id, title, status, estimate_minutes, weight, created_at, deadline_at, extension_used, failed_at)
    VALUES (target_user_id, 'デプロイ準備をする', 'FAILED', 120, 2, NOW() - INTERVAL '5 days', NOW() - INTERVAL '4 days', false, NOW() - INTERVAL '4 days');
    
    -- タスク11: 完了したタスク
    INSERT INTO tasks (user_id, title, status, estimate_minutes, weight, created_at, deadline_at, extension_used, completed_at, self_report)
    VALUES (target_user_id, 'API仕様書を作成する', 'COMPLETED', 210, 4, NOW() - INTERVAL '12 days', NOW() - INTERVAL '11 days', false, NOW() - INTERVAL '11 days 1 hour', 'API仕様書を完成させました');
    
    -- タスク12: 完了したタスク
    INSERT INTO tasks (user_id, title, status, estimate_minutes, weight, created_at, deadline_at, extension_used, completed_at, self_report)
    VALUES (target_user_id, 'UIデザインを修正する', 'COMPLETED', 135, 2, NOW() - INTERVAL '11 days', NOW() - INTERVAL '10 days', false, NOW() - INTERVAL '10 days 3 hours', 'デザインを改善しました');
    
    -- タスク13: 完了したタスク
    INSERT INTO tasks (user_id, title, status, estimate_minutes, weight, created_at, deadline_at, extension_used, completed_at, self_report)
    VALUES (target_user_id, 'セキュリティ監査を実施', 'COMPLETED', 180, 3, NOW() - INTERVAL '15 days', NOW() - INTERVAL '14 days', false, NOW() - INTERVAL '14 days 2 hours', '監査を完了しました');
    
    -- タスク14: 失敗したタスク
    INSERT INTO tasks (user_id, title, status, estimate_minutes, weight, created_at, deadline_at, extension_used, failed_at)
    VALUES (target_user_id, 'パフォーマンス改善', 'FAILED', 240, 4, NOW() - INTERVAL '13 days', NOW() - INTERVAL '12 days', false, NOW() - INTERVAL '12 days');
    
    -- タスク15: 完了したタスク
    INSERT INTO tasks (user_id, title, status, estimate_minutes, weight, created_at, deadline_at, extension_used, completed_at, self_report)
    VALUES (target_user_id, 'ログ機能を実装する', 'COMPLETED', 120, 2, NOW() - INTERVAL '14 days', NOW() - INTERVAL '13 days', false, NOW() - INTERVAL '13 days 5 hours', 'ログ機能を実装しました');
    
    -- タスク16: 完了したタスク
    INSERT INTO tasks (user_id, title, status, estimate_minutes, weight, created_at, deadline_at, extension_used, completed_at, self_report)
    VALUES (target_user_id, 'エラーハンドリング改善', 'COMPLETED', 90, 2, NOW() - INTERVAL '16 days', NOW() - INTERVAL '15 days', false, NOW() - INTERVAL '15 days 4 hours', 'エラーハンドリングを改善しました');
    
    -- タスク17: 完了したタスク
    INSERT INTO tasks (user_id, title, status, estimate_minutes, weight, created_at, deadline_at, extension_used, completed_at, self_report)
    VALUES (target_user_id, 'CI/CDパイプライン設定', 'COMPLETED', 180, 3, NOW() - INTERVAL '18 days', NOW() - INTERVAL '17 days', false, NOW() - INTERVAL '17 days 2 hours', 'パイプラインを設定しました');
    
    -- タスク18: 失敗したタスク
    INSERT INTO tasks (user_id, title, status, estimate_minutes, weight, created_at, deadline_at, extension_used, failed_at)
    VALUES (target_user_id, 'モニタリング設定', 'FAILED', 150, 3, NOW() - INTERVAL '17 days', NOW() - INTERVAL '16 days', false, NOW() - INTERVAL '16 days');
    
    -- タスク19: 完了したタスク
    INSERT INTO tasks (user_id, title, status, estimate_minutes, weight, created_at, deadline_at, extension_used, completed_at, self_report)
    VALUES (target_user_id, 'バックアップ設定を見直す', 'COMPLETED', 75, 1, NOW() - INTERVAL '19 days', NOW() - INTERVAL '18 days', false, NOW() - INTERVAL '18 days 6 hours', 'バックアップ設定を完了しました');
    
    -- タスク20: 完了したタスク
    INSERT INTO tasks (user_id, title, status, estimate_minutes, weight, created_at, deadline_at, extension_used, completed_at, self_report)
    VALUES (target_user_id, 'ユーザーマニュアル作成', 'COMPLETED', 240, 4, NOW() - INTERVAL '20 days', NOW() - INTERVAL '19 days', false, NOW() - INTERVAL '19 days 1 hour', 'マニュアルを完成させました');
    
END $$;
