-- Migration: Update active task constraint from 1 to 3
-- Drop old trigger and function
DROP TRIGGER IF EXISTS trg_single_active_task ON tasks;
DROP FUNCTION IF EXISTS enforce_single_active_task();

-- Create new function to allow up to 3 active tasks
CREATE OR REPLACE FUNCTION enforce_max_active_tasks() RETURNS trigger AS $$
DECLARE
  active_count int;
BEGIN
  IF (new.status = 'ACTIVE') THEN
    SELECT count(*) INTO active_count 
    FROM tasks 
    WHERE user_id = new.user_id 
      AND status = 'ACTIVE' 
      AND id <> new.id;
    
    IF active_count >= 3 THEN
      RAISE EXCEPTION 'User already has 3 active tasks';
    END IF;
  END IF;
  RETURN new;
END;
$$ LANGUAGE plpgsql;

-- Create new trigger
CREATE TRIGGER trg_max_active_tasks
  BEFORE INSERT OR UPDATE ON tasks
  FOR EACH ROW EXECUTE PROCEDURE enforce_max_active_tasks();
