-- Profiles: user progression
create table if not exists profiles (
  user_id uuid primary key default gen_random_uuid(),
  points int not null default 10,
  rank int not null default 2,
  created_at timestamptz not null default now()
);

-- Tasks: lifecycle of tasks
create table if not exists tasks (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references profiles(user_id) on delete cascade,
  title text not null,
  status text not null check (status in ('PENDING','ACTIVE','COMPLETED','FAILED')),
  estimate_minutes int not null,
  weight int not null default 1,
  created_at timestamptz not null default now(),
  deadline_at timestamptz not null,
  extension_used boolean not null default false,
  completed_at timestamptz,
  self_report text,
  failed_at timestamptz
);

create index if not exists tasks_user_active_idx on tasks(user_id) where status = 'ACTIVE';
create index if not exists tasks_user_created_idx on tasks(user_id, created_at desc);

-- Task events / logs for audit
create table if not exists task_logs (
  id bigserial primary key,
  task_id uuid not null references tasks(id) on delete cascade,
  user_id uuid not null references profiles(user_id) on delete cascade,
  event_type text not null,
  payload jsonb,
  created_at timestamptz not null default now()
);

-- Simple function to ensure maximum 3 ACTIVE tasks per user
create or replace function enforce_max_active_tasks() returns trigger as $$
declare
  active_count int;
begin
  if (new.status = 'ACTIVE') then
    select count(*) into active_count 
    from tasks 
    where user_id = new.user_id 
      and status = 'ACTIVE' 
      and id <> new.id;
    
    if active_count >= 3 then
      raise exception 'User already has 3 active tasks';
    end if;
  end if;
  return new;
end;$$ language plpgsql;

create trigger trg_max_active_tasks
  before insert or update on tasks
  for each row execute procedure enforce_max_active_tasks();
