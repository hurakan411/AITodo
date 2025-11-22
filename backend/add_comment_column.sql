-- Add ai_completion_comment column to tasks table
ALTER TABLE tasks ADD COLUMN IF NOT EXISTS ai_completion_comment TEXT;
