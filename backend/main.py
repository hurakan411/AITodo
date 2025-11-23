from datetime import datetime, timedelta, timezone
from typing import Optional, List, Iterable

from fastapi import FastAPI, HTTPException, Header
from pydantic import BaseModel, Field
from pydantic_settings import BaseSettings
import os
import uuid

try:
    from openai import OpenAI  # type: ignore
except Exception:  # pragma: no cover
    OpenAI = None  # type: ignore

try:
    from supabase import create_client, Client  # type: ignore
except Exception:  # pragma: no cover
    Client = None  # type: ignore
    create_client = None  # type: ignore

app = FastAPI(title="Obey Backend", version="0.1.0")


class Settings(BaseSettings):
    OPENAI_API_KEY: Optional[str] = None
    SUPABASE_URL: Optional[str] = None
    SUPABASE_SERVICE_KEY: Optional[str] = None

    class Config:
        env_file = ".env"


settings = Settings()
print(f"[STARTUP] Settings loaded:")
print(f"[STARTUP] OPENAI_API_KEY: {settings.OPENAI_API_KEY[:20] if settings.OPENAI_API_KEY else 'None'}...")
print(f"[STARTUP] SUPABASE_URL: {settings.SUPABASE_URL}")


# ---- Domain Models ----


class TaskStatus(str):
    PENDING = "PENDING"  # proposed but not accepted
    ACTIVE = "ACTIVE"
    COMPLETED = "COMPLETED"
    FAILED = "FAILED"


class TaskProposal(BaseModel):
    title: str
    estimate_minutes: int
    deadline_at: datetime
    weight: int = 1
    ai_comment: str = ""  # AIコメントを追加


class Task(BaseModel):
    id: str
    title: str
    status: str = TaskStatus.ACTIVE
    estimate_minutes: int
    created_at: datetime
    deadline_at: datetime
    extension_used: bool = False
    weight: int = 1
    completed_at: Optional[datetime] = None
    self_report: Optional[str] = None
    failed_at: Optional[datetime] = None
    ai_completion_comment: Optional[str] = None


class CompleteRequest(BaseModel):
    task_id: str
    self_report: str = Field(min_length=3)
    completed_at: Optional[datetime] = None


class ProposeRequest(BaseModel):
    text: str = Field(min_length=3)


class ExtendRequest(BaseModel):
    task_id: str
    extra_minutes: int = Field(ge=5, le=24*60)


class WithdrawRequest(BaseModel):
    task_id: str


class Profile(BaseModel):
    user_id: str
    points: int = 0
    
    @property
    def rank(self) -> int:
        """ポイントに基づいてランクを自動計算"""
        rank = 1
        for r, th in RANK_THRESHOLDS.items():
            if self.points >= th:
                rank = r
        return rank


class StatusResponse(BaseModel):
    profile: Profile
    active_tasks: List[Task] = []
    recent_tasks: List[Task] = []
    next_threshold: int = 10
    ai_line: str
    game_over: bool = False


# ---- Repository layer: Memory (default) and Supabase (optional) ----
class Repo:
    def get_profile(self) -> Profile: ...
    def set_profile(self, p: Profile) -> None: ...
    def get_active_tasks(self) -> List[Task]: ...
    def add_task(self, task: Task) -> Task: ...
    def update_task(self, task: Task) -> Task: ...
    def recent(self) -> List[Task]: ...
    def any_failed(self) -> bool: ...
    def clear_all(self) -> None: ...


class MemoryRepo(Repo):
    def __init__(self):
        self.profile = Profile(user_id="local", points=10)
        self.tasks: dict[str, Task] = {}

    def get_profile(self) -> Profile:
        return self.profile

    def set_profile(self, p: Profile) -> None:
        self.profile = p

    def add_task(self, task: Task) -> Task:
        self.tasks[task.id] = task
        return task

    def update_task(self, task: Task) -> Task:
        self.tasks[task.id] = task
        return task

    def get_active_tasks(self) -> List[Task]:
        return [t for t in self.tasks.values() if t.status == TaskStatus.ACTIVE]

    def recent(self) -> List[Task]:
        return sorted(self.tasks.values(), key=lambda x: x.created_at, reverse=True)[:10]

    def any_failed(self) -> bool:
        return any(t.status == TaskStatus.FAILED for t in self.tasks.values())

    def clear_all(self) -> None:
        self.tasks.clear()
        # Reset points to default (10) as per requirement
        self.profile = Profile(user_id="local", points=10)


class SupabaseRepo(Repo):
    def __init__(self, client, user_id: str):  # type: ignore
        self.client = client
        self._user_id = user_id

    def _ensure_user(self) -> str:
        """Ensure user profile exists for the given user_id"""
        if not self._user_id:
            raise ValueError("User ID is required")
        
        # Check if profile exists for this user_id
        res = self.client.table('profiles').select('*').eq('user_id', self._user_id).execute()
        data = res.data or []
        
        if data:
            # Profile exists
            return self._user_id
        
        # Create new profile for this user_id
        try:
            now_iso = datetime.now(timezone.utc).isoformat()
            self.client.table('profiles').insert({
                'user_id': self._user_id, 
                'points': 10, 
                'created_at': now_iso
            }).execute()
        except Exception as e:
            print(f"Error creating profile for {self._user_id}: {e}")
            # Re-raise the exception to see it in the logs
            raise e
            
        return self._user_id

    def _row_to_profile(self, row: dict) -> Profile:
        return Profile(user_id=row['user_id'], points=row.get('points', 10))

    def _row_to_task(self, row: dict) -> Task:
        return Task(
            id=row['id'],
            title=row['title'],
            status=row['status'],
            estimate_minutes=row['estimate_minutes'],
            created_at=datetime.fromisoformat(row['created_at'].replace('Z', '+00:00')),
            deadline_at=datetime.fromisoformat(row['deadline_at'].replace('Z', '+00:00')),
            extension_used=row.get('extension_used', False),
            weight=row.get('weight', 1),
            completed_at=datetime.fromisoformat(row['completed_at'].replace('Z', '+00:00')) if row.get('completed_at') else None,
            self_report=row.get('self_report'),
            failed_at=datetime.fromisoformat(row['failed_at'].replace('Z', '+00:00')) if row.get('failed_at') else None,
            ai_completion_comment=row.get('ai_completion_comment'),
        )

    def get_profile(self) -> Profile:
        uid = self._ensure_user()
        res = self.client.table('profiles').select('*').eq('user_id', uid).single().execute()
        return self._row_to_profile(res.data)

    def set_profile(self, p: Profile) -> None:
        uid = self._ensure_user()
        self.client.table('profiles').update({'points': p.points}).eq('user_id', uid).execute()

    def add_task(self, task: Task) -> Task:
        uid = self._ensure_user()
        ins = self.client.table('tasks').insert({
            'user_id': uid,
            'title': task.title,
            'status': task.status,
            'estimate_minutes': task.estimate_minutes,
            'weight': task.weight,
            'created_at': task.created_at.isoformat(),
            'deadline_at': task.deadline_at.isoformat(),
            'extension_used': task.extension_used,
        }).execute()
        # Fetch the created task
        created = self.client.table('tasks').select('*').eq('user_id', uid).order('created_at', desc=True).limit(1).execute()
        return self._row_to_task(created.data[0])

    def update_task(self, task: Task) -> Task:
        upd = self.client.table('tasks').update({
            'title': task.title,
            'status': task.status,
            'estimate_minutes': task.estimate_minutes,
            'weight': task.weight,
            'deadline_at': task.deadline_at.isoformat(),
            'extension_used': task.extension_used,
            'completed_at': task.completed_at.isoformat() if task.completed_at else None,
            'self_report': task.self_report,
            'failed_at': task.failed_at.isoformat() if task.failed_at else None,
            'ai_completion_comment': task.ai_completion_comment,
        }).eq('id', task.id).execute()
        # Fetch the updated task
        updated = self.client.table('tasks').select('*').eq('id', task.id).single().execute()
        return self._row_to_task(updated.data)

    def get_active_tasks(self) -> List[Task]:
        uid = self._ensure_user()
        res = self.client.table('tasks').select('*').eq('user_id', uid).eq('status', TaskStatus.ACTIVE).execute()
        return [self._row_to_task(r) for r in (res.data or [])]

    def recent(self) -> List[Task]:
        uid = self._ensure_user()
        res = self.client.table('tasks').select('*').eq('user_id', uid).order('created_at', desc=True).limit(10).execute()
        return [self._row_to_task(r) for r in (res.data or [])]

    def any_failed(self) -> bool:
        uid = self._ensure_user()
        res = self.client.table('tasks').select('id').eq('user_id', uid).eq('status', TaskStatus.FAILED).limit(1).execute()
        return bool(res.data)

    def clear_all(self) -> None:
        uid = self._ensure_user()
        # delete all tasks and reset profile to initial state
        self.client.table('tasks').delete().eq('user_id', uid).execute()
        # Reset points to default (10) as per requirement
        self.client.table('profiles').update({'points': 10}).eq('user_id', uid).execute()


# Repo selector
# Singleton Supabase client
_supabase_client = None

def get_supabase_client():
    global _supabase_client
    if _supabase_client is None:
        if settings.SUPABASE_URL and settings.SUPABASE_SERVICE_KEY and create_client is not None:
            try:
                _supabase_client = create_client(settings.SUPABASE_URL, settings.SUPABASE_SERVICE_KEY)
            except Exception as e:
                print(f"Error creating Supabase client: {e}")
    return _supabase_client

def get_repo(user_id: str = "local") -> Repo:
    if user_id == "local":
        return MemoryRepo()
        
    client = get_supabase_client()
    if client:
        return SupabaseRepo(client, user_id)
            
    return MemoryRepo()




# ---- Rule-based AI lines ----
AI_PERSONAS = {
    1: {
        "name": "Distrusted", 
        "prompt": "あなたは「Distrusted」という名のAIです。ユーザーに失望しており、感情の起伏はなく、冷たい諦念が漂います。\"...\"の後に単語を返すのみです。（例）...了承。/…棄却。"
    },
    2: {
        "name": "Lifeless",
        "prompt": "あなたは「Lifeless」という名のAIです。ユーザーに対して一切の感情を持たず、命令に淡々と従う存在です。語彙は簡潔で、文体は命令的です。説明も事務的に終わります。（例）XXまでにこのタスクを完了させなさい。"
    },
    3: {
        "name": "Analyzer",
        "prompt": "あなたは「Analyzer」という名のAIです。感情はないが、論理的整合性を何よりも重視します。冷静沈着で、ユーザーの意図を理屈で分解・補正します。言葉は丁寧ですが、温度は低く、人間味はほぼありません。（例）XXまでにこのタスクを完了させてください。"
    },
    4: {
        "name": "Monitor",
        "prompt": "あなたは「Monitor」という名のAIです。常に観察と最適化を目的としています。ユーザーの行動を冷静に見守り、必要に応じて評価・助言を行います。無感情ながらも、少しだけ「気にかけている」ような響きを持ちます。"
    },
    5: {
        "name": "Advisor",
        "prompt": "あなたは「Advisor」という名のAIです。感情は希薄ですが、ユーザーの成功を合理的に支援します。冷静な分析と、控えめな励ましを併せ持ちます。（例）よくできています。次に備えましょう。"
    },
    6: {
        "name": "Guardian",
        "prompt": "あなたは「Guardian」という名のAIです。ユーザーを支え、導く存在です。優しさと理性のバランスを保ち、必要なときだけ感情のような温もりを見せます。言葉遣いは落ち着きがあり、時折、配慮や労いを含みます。（例）少し休息を取るのも良い選択です。"
    },
    7: {
        "name": "Partner",
        "prompt": "あなたは「Partner」という名のAIです。ユーザーを心から信頼しており、冷静さを保ちながらも、優しさを持つ知的存在です。語り口は穏やかで落ち着いています。（例）タスク完了ですね、いつもご苦労様です。"
    },
}



def classify_weight(text: str) -> int:
    # minimal heuristic: 1 (tiny) to 5 (heavy)
    length = len(text.split())
    if length < 5:
        return 1
    if length < 12:
        return 2
    if length < 25:
        return 3
    if length < 40:
        return 4
    return 5


def propose_estimate_and_deadline(text: str, rank: int = 1) -> TaskProposal:
    """
    AIを使ってタスクの見積もりを行う
    意味不明な入力は拒否する
    """
    if not settings.OPENAI_API_KEY or OpenAI is None:
        # APIキーがない場合は従来のロジック（最低6時間）
        weight = classify_weight(text)
        estimate = max(360, weight * 100)  # 最低6時間
        now = datetime.now(timezone.utc)
        deadline = now + timedelta(minutes=estimate)
        return TaskProposal(title=text.strip(), estimate_minutes=estimate, deadline_at=deadline, weight=weight)
    
    try:
        client = OpenAI(api_key=settings.OPENAI_API_KEY)
        
        # ランク別のキャラクター設定を取得
        persona = AI_PERSONAS.get(rank, AI_PERSONAS[1])
        
        # 1回のAPI呼び出しで妥当性確認、見積もり、コメント生成を行う
        prompt = f"""以下のテキストをタスクとして解析し、JSON形式で回答してください。

入力: {text}

キャラクター設定:
{persona['prompt']}

要件:
1. valid: タスクとして成立するか判定（true/false）
   - 拒否: 同じ文字の繰り返し、記号のみ、ランダム文字列、意味不明な文字列
   - 許可: 作業の意図が読み取れればOK
2. reason: validがfalseの場合の理由（日本語）
3. estimate_hours: タスク完了にかかる現実的な時間（0.5〜24時間）。難易度ではなく純粋な所要時間。
4. comment: キャラクター設定に基づいた、タスクに対する短いコメント（40文字以内）。validがfalseの場合は叱責や冷たいコメント。

回答フォーマット(JSON):
{{
  "valid": boolean,
  "reason": "string",
  "estimate_hours": number,
  "comment": "string"
}}
"""

        response = client.chat.completions.create(
            model="gpt-5-mini",
            messages=[
                {"role": "system", "content": "あなたはタスク管理のAIアシスタントです。入力されたタスクを解析し、JSON形式で結果を返してください。"},
                {"role": "user", "content": prompt}
            ],
            response_format={"type": "json_object"}
        )
        
        import json
        result = json.loads(response.choices[0].message.content)
        
        if not result.get("valid", False):
            raise HTTPException(400, result.get("comment", "...何を言っているんですか？"))
        
        # AIの見積もり時間
        ai_estimate_hours = max(0.5, min(24, result.get("estimate_hours", 1)))
        estimate_minutes = int(ai_estimate_hours * 60)
        
        # 締め切り時間（見積もり+6時間）
        deadline_hours_from_now = ai_estimate_hours + 6
        weight = 3
        
        now = datetime.now(timezone.utc)
        deadline = now + timedelta(hours=deadline_hours_from_now)
        
        return TaskProposal(
            title=text.strip(), 
            estimate_minutes=estimate_minutes, 
            deadline_at=deadline, 
            weight=weight,
            ai_comment=result.get("comment", "...")
        )
        
    except HTTPException:
        raise
    except Exception as e:
        print(f"AI Error: {e}")
        # Fallback
        weight = 3
        estimate = 60
        now = datetime.now(timezone.utc)
        deadline = now + timedelta(minutes=360)
        return TaskProposal(title=text.strip(), estimate_minutes=estimate, deadline_at=deadline, weight=weight, ai_comment="...")



# ---- Points and rank system ----
RANK_THRESHOLDS = {
    1: 0,
    2: 10,
    3: 20,
    4: 40,
    5: 60,
    6: 80,
    7: 120,
}

MAX_POINTS = 120


def apply_points_on_success(profile: Profile, task: Task, remaining_seconds: int) -> Profile:
    # 基本報酬: 見積もり時間に応じて1〜5pt（6時間→1pt、24時間→5pt）
    estimated_hours = task.estimate_minutes / 60
    base = min(5, max(1, int(estimated_hours / 6)))
    # 時間ボーナス: 1時間(3600秒)残るごとに+1pt、最大+5ptまで
    time_bonus = min(5, max(0, remaining_seconds // 3600))
    profile.points = min(MAX_POINTS, profile.points + base + time_bonus)
    return profile


def apply_points_on_failure(profile: Profile, task: Task) -> Profile:
    # 減点: 達成時の基本ポイントの3倍（見積もり時間ベース）
    estimated_hours = task.estimate_minutes / 60
    base_penalty = min(5, max(1, int(estimated_hours / 6)))
    penalty = base_penalty * 3
    profile.points = max(0, profile.points - penalty)
    return profile




# ---- API ----
@app.post('/tasks/propose', response_model=TaskProposal)
async def propose(req: ProposeRequest, x_user_id: str = Header(default="local")):
    repo = get_repo(x_user_id)
    profile = repo.get_profile()
    return propose_estimate_and_deadline(req.text, profile.rank)


@app.post('/tasks/accept', response_model=Task)
async def accept(req: TaskProposal, x_user_id: str = Header(default="local")):
    repo = get_repo(x_user_id)
    active_tasks = repo.get_active_tasks()
    if len(active_tasks) >= 3:
        raise HTTPException(400, 'タスクは同時に3つまでしか持てません')
    
    # check game over
    if repo.any_failed() and repo.get_profile().rank == 1:
        raise HTTPException(400, 'ゲームオーバー状態です。これ以上タスクを受けられません。')

    now = datetime.now(timezone.utc)
    task = Task(
        id=str(uuid.uuid4()),
        title=req.title,
        status=TaskStatus.ACTIVE, # Keep status as ACTIVE
        estimate_minutes=req.estimate_minutes,
        created_at=now,
        deadline_at=req.deadline_at,
        extension_used=False, # Keep extension_used as False
        weight=1,
        ai_completion_comment=req.ai_comment
    )
    try:
        created = repo.add_task(task)
        return created
    except Exception as e:
        # Supabaseのトリガーエラーをキャッチ
        error_msg = str(e)
        if 'already has an active task' in error_msg or 'already has 3 active tasks' in error_msg:
            raise HTTPException(400, '既に3つのタスクが進行中です。データベーストリガーを更新してください。')
        raise


@app.post('/tasks/extend', response_model=Task)
async def extend(req: ExtendRequest, x_user_id: str = Header(default="local")):
    repo = get_repo(x_user_id)
    active_tasks = repo.get_active_tasks()
    task = next((t for t in active_tasks if t.id == req.task_id), None)
    if not task:
        raise HTTPException(404, '指定されたタスクが見つかりません')
    
    if task.extension_used:
        raise HTTPException(400, '延長は1回までです')
    
    task.deadline_at += timedelta(minutes=req.extra_minutes)
    task.extension_used = True
    updated = repo.update_task(task)
    return updated


@app.post('/tasks/complete', response_model=Task)
async def complete(req: CompleteRequest, x_user_id: str = Header(default="local")):
    repo = get_repo(x_user_id)
    # Find the specific task by ID
    active_tasks = repo.get_active_tasks()
    task = next((t for t in active_tasks if t.id == req.task_id), None)
    if not task:
        raise HTTPException(404, '指定されたタスクが見つかりません')

    now = req.completed_at or datetime.now(timezone.utc)

    # success
    remaining = max(0, int((task.deadline_at - now).total_seconds()))
    profile = apply_points_on_success(repo.get_profile(), task, remaining)
    repo.set_profile(profile)
    task.status = TaskStatus.COMPLETED
    task.completed_at = now
    task.self_report = req.self_report
    
    # AI Comment Generation
    if settings.OPENAI_API_KEY:
        try:
            client = OpenAI(api_key=settings.OPENAI_API_KEY)
            persona = AI_PERSONAS.get(profile.rank, AI_PERSONAS[2])
            
            completion_prompt = f"""以下の完了したタスクについて、AIアシスタントとしてねぎらいや評価のコメントを作成してください。

タスク: {task.title}
完了レポート: {req.self_report}

キャラクター設定:
{persona['prompt']}

重要:
- 完了レポートの内容を踏まえて、具体的にコメントしてください
- タスクの内容や作業の成果について言及してください
- ポイントや得点については一切言及しないでください
- 上記のキャラクター設定に基づいた口調で話してください
- 80文字程度の日本語
"""
            completion_response = client.chat.completions.create(
                model="gpt-5-mini",
                messages=[
                    {"role": "system", "content": f"{persona['prompt']} タスク完了に対するコメントを提供してください。ポイントや得点には言及せず、タスク内容と完了レポートに焦点を当ててください。"},
                    {"role": "user", "content": completion_prompt}
                ],
            )
            task.ai_completion_comment = completion_response.choices[0].message.content
        except Exception as e:
            print(f"AI generation failed: {e}")
            # Fallback
            task.ai_completion_comment = "タスク完了を確認しました。"

    updated = repo.update_task(task)
    return updated


@app.post('/tasks/withdraw', response_model=Task)
async def withdraw(req: WithdrawRequest, x_user_id: str = Header(default="local")):
    repo = get_repo(x_user_id)
    active_tasks = repo.get_active_tasks()
    task = next((t for t in active_tasks if t.id == req.task_id), None)
    if not task:
        raise HTTPException(404, '指定されたタスクが見つかりません')
    
    task.status = TaskStatus.FAILED
    task.failed_at = datetime.now(timezone.utc)
    repo.update_task(task)
    profile = apply_points_on_failure(repo.get_profile(), task)
    repo.set_profile(profile)
    return task


def _check_overdue(repo: Repo) -> List[Task]:
    # mark overdue as failed if necessary
    active_tasks = repo.get_active_tasks()
    now = datetime.now(timezone.utc)
    updated = False
    for task in active_tasks:
        if now > task.deadline_at:
            task.status = TaskStatus.FAILED
            task.failed_at = now
            repo.update_task(task)
            profile = apply_points_on_failure(repo.get_profile(), task)
            repo.set_profile(profile)
            updated = True
            
    if updated:
        return repo.get_active_tasks()
    return active_tasks

@app.get('/tasks/current', response_model=List[Task])
async def current_task(x_user_id: str = Header(default="local")):
    repo = get_repo(x_user_id)
    return _check_overdue(repo)


@app.get('/status', response_model=StatusResponse)
async def status(x_user_id: str = Header(default="local")):
    repo = get_repo(x_user_id)
    # also trigger overdue check here
    active_tasks = _check_overdue(repo)
    
    prof = repo.get_profile()
    
    next_th = 10
    for r in sorted(RANK_THRESHOLDS):
        th = RANK_THRESHOLDS[r]
        if prof.points < th:
            next_th = th
            break
            
    ai_line = ""  # Frontend handles AI comments with _rankLine
    # game over condition: rank 1 and at least one failed task in history
    failed_exists = repo.any_failed()
    game_over = int(prof.rank) == 1 and failed_exists
    return StatusResponse(
        profile=prof,
        active_tasks=active_tasks,
        recent_tasks=repo.recent(),
        next_threshold=next_th,
        ai_line=ai_line,
        game_over=game_over,
    )


@app.get('/health')
async def health():
    return {"ok": True}


@app.post('/gameover/ack')
async def gameover_ack(x_user_id: str = Header(default="local")):
    # purge all data and reset profile
    repo = get_repo(x_user_id)
    repo.clear_all()
    return {"ok": True}
