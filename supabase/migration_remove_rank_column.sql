-- profilesテーブルからrankカラムを削除
-- rankはpointsから自動計算されるため、データベースに保存する必要がありません

ALTER TABLE profiles DROP COLUMN IF EXISTS rank;
