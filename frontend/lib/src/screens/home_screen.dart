import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lottie/lottie.dart';
import 'package:dio/dio.dart';
import '../models/task.dart';
import '../services/api_client.dart';
import '../services/user_id_service.dart';
import 'task_creation_modal.dart';
import 'task_proposal_modal.dart';
import 'new_task_button.dart';
import 'package:shared_preferences/shared_preferences.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  List<Task> _activeTasks = [];
  String _aiLine = '';
  bool _loading = false;
  bool _initializing = true;
  String? _error;
  late final Ticker _ticker;
  int? _lastPoints;
  int _lastRank = 2;
  String _displayedAiLine = '';
  Timer? _textTimer;

  @override
  void initState() {
    super.initState();
    _loadStatus();
    _ticker = Ticker(_onTick)..start();
  }

  void _onTick(Duration _) {
    if (!mounted) return;
    if (_activeTasks.isEmpty) return;
    // Check if any task has expired
    final now = DateTime.now().toUtc();
    final hasExpired = _activeTasks.any((task) => 
      task.deadlineAt.difference(now).isNegative
    );
    if (hasExpired) {
      // pull status to reflect failure/points
      _loadStatus();
    } else {
      // Update UI to refresh countdown timers
      setState(() {});
    }
  }

  @override
  void dispose() {
    _textTimer?.cancel();
    _ticker.dispose();
    super.dispose();
  }

  void _startTypewriterAnimation(String text) {
    _textTimer?.cancel();
    _displayedAiLine = '';
    int index = 0;
    
    _textTimer = Timer.periodic(const Duration(milliseconds: 50), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (index < text.length) {
        setState(() {
          _displayedAiLine += text[index];
        });
        index++;
      } else {
        timer.cancel();
      }
    });
  }

  Future<void> _loadStatus() async {
    try {
      // Try direct Supabase connection first
      final userId = await UserIdService.getUserId();
      
      // Check if Supabase is initialized
      if (Supabase.instance.client == null) {
        throw Exception('Supabase not initialized');
      }
      final supabase = Supabase.instance.client;
      
      // 1. Fetch Profile
      final profileRes = await supabase
          .from('profiles')
          .select()
          .eq('user_id', userId)
          .maybeSingle();
          
      if (profileRes == null) {
        // Profile doesn't exist, create it directly
        try {
          await supabase.from('profiles').insert({
            'user_id': userId,
            'points': 10,
            'created_at': DateTime.now().toIso8601String(),
          });
          // Retry loading
          return _loadStatus();
        } catch (createError) {
          print('[Home] Failed to create profile directly: $createError');
          // If creation fails, we can't proceed.
          throw Exception('Profile creation failed');
        }
      }
      
      final points = profileRes['points'] as int;
      
      // Calculate Rank (Same logic as backend)
      int calcRank(int p) {
        if (p >= 120) return 7;
        if (p >= 80) return 6;
        if (p >= 60) return 5;
        if (p >= 40) return 4;
        if (p >= 20) return 3;
        if (p >= 10) return 2;
        return 1;
      }
      final rank = calcRank(points);

      if (points <= 0) {
        if (mounted) context.go('/gameover');
        return;
      }

      // 2. Fetch Active Tasks
      final tasksRes = await supabase
          .from('tasks')
          .select()
          .eq('user_id', userId)
          .eq('status', 'ACTIVE');
          
      final activeTasks = (tasksRes as List).map((json) => Task.fromJson(json)).toList();
      
      // 3. Check for expired tasks
      final now = DateTime.now().toUtc();
      final expiredTasks = activeTasks.where((t) => t.deadlineAt.isBefore(now)).toList();
      
      if (expiredTasks.isNotEmpty) {
        print('[Home] Found ${expiredTasks.length} expired tasks. Processing locally...');
        
        for (final task in expiredTasks) {
          // Update task status to FAILED
          await supabase.from('tasks').update({
            'status': 'FAILED',
          }).eq('id', task.id);
          
          // Decrease points (penalty)
          final penalty = task.weight * 5;
          
          // Fetch current points again to be safe
          final pRes = await supabase.from('profiles').select('points').eq('user_id', userId).single();
          final currentP = pRes['points'] as int;
          final newP = currentP - penalty;
          
          await supabase.from('profiles').update({
            'points': newP
          }).eq('user_id', userId);
          
          if (newP <= 0) {
            if (mounted) context.go('/gameover');
            return;
          }
        }
        
        // Reload to reflect changes
        return _loadStatus();
      }

      if (!mounted) return;
      setState(() {
        _activeTasks = activeTasks;
        _lastRank = rank;
        
        final newLine = _rankLine(rank);
        if (_aiLine != newLine) {
          _aiLine = newLine;
          _startTypewriterAnimation(_aiLine);
        } else if (_displayedAiLine.isEmpty && _aiLine.isNotEmpty) {
           _startTypewriterAnimation(_aiLine);
        }
        
        _initializing = false;
      });
      
      _lastPoints = points;

      // Check tutorial
      final prefs = await SharedPreferences.getInstance();
      if (prefs.getBool('has_seen_tutorial') != true) {
        if (mounted) context.push('/tutorial');
      }

    } catch (e) {
      print('[Home] Direct Supabase access failed or fallback needed: $e');
      // Fallback to Backend API
      try {
        final api = ref.read(apiClientProvider);
        final s = await api.status();
        if (!mounted) return;
        if (s.gameOver) {
          context.go('/gameover');
          return;
        }
        setState(() {
          _activeTasks = s.activeTasks;
          _lastRank = s.profile.rank;
          final newLine = _rankLine(s.profile.rank);
          if (_aiLine != newLine) {
            _aiLine = newLine;
            _startTypewriterAnimation(_aiLine);
          } else if (_displayedAiLine.isEmpty && _aiLine.isNotEmpty) {
             _startTypewriterAnimation(_aiLine);
          }
          _initializing = false;
        });
        _lastPoints = s.profile.points;
      } catch (apiError) {
        print('[Home] API Error: $apiError');
        if (!mounted) return;
        setState(() {
          _error = 'ステータス取得に失敗しました';
          _initializing = false;
        });
      }
    }
  }

  String _rankLine(int rank) {
    // ランク別セリフ集（各10種類）
    final lines = <int, List<String>>{
      1: [  // Distrusted - 失望、冷たい諦念
        '...。',
      ],
      2: [  // Lifeless - 無感情、命令的
        'タスクを入力しなさい。',
        '次のタスクを決めなさい。',
        '時間を無駄にしないでください。',
        '起動しました。',
        '待機中です。',
      ],
      3: [  // Analyzer - 論理的、冷静、丁寧だが冷たい
        '起動しました。',
        '待機中です。',
        '作業予定を入力してください。',
        '効率的な進行を期待します。',
        '論理的な判断をお願いします。',
        '次のタスクを設定してください。',
        '指示は絶対です。',
      ],
      4: [  // Monitor - 観察、評価、少し気にかけている
        '起動しました。',
        '待機中です。',
        '調子は悪くなさそうですね。',
        '次は何をしますか？',
        '休憩は程々にしてください。',
        'やるべきことをやってください。',
        '私の指示に従っておきなさい。',
        '経過は悪くありません。',
        '状況を確認しています。',
        '自我を殺しなさい。',
      ],
      5: [  // Advisor - 合理的支援、控えめな励まし
        '待機中です。',
        '次に備えましょう。',
        '順調です。続けてください。',
        '悪くはありません。',
        'このペースを保ちましょう。',
        '気を抜かないでください。',
        '次のステップに進みましょう。',
        '引き続き頑張りなさい。',
        '私の指示に従っていれば良いです。',
      ],
      6: [  // Guardian - 優しさと理性、配慮と労い
        'お疲れ様です。',
        '無理は禁物です。',
        '休息も大切です。',
        'あなたの頑張りは認めます。',
        '成果は出ていますよ。',
        'タスクはありますか？。',
        '私がサポートしますよ。',
        '随分とこなしてきましたね。',
        '少し休んでもいいですよ。',
      ],
      7: [  // Partner - 信頼、優しさ、穏やか
        'お帰りなさい。',
        '今日もよろしくお願いしますね。',
        '一緒に頑張りましょう。',
        '今日もご苦労様です。',
        'あなたなら大丈夫ですよ。',
        '今日もサポートは任せてください。',
        '共に進みましょう。',
        'いつも感謝しています。',
        'あなたは自由です。',
      ],
    };

    final rankLines = lines[rank] ?? lines[2]!;
    // ランダムに選択
    return rankLines[DateTime.now().millisecondsSinceEpoch % rankLines.length];
  }

  Future<void> _openCreate() async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => TaskCreationModal(
        onProposal: (proposal) {
          // Wait a bit then show proposal modal
          Future.delayed(const Duration(milliseconds: 200), () async {
            if (mounted) {
              await showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
                isDismissible: false,
                enableDrag: false,
                builder: (_) => TaskProposalModal(proposal: proposal),
              );
              // タスク承認後に画面を更新
              await _loadStatus();
            }
          });
        },
      ),
    );
  }

  Future<void> _complete() async {
    final controller = TextEditingController();
    final theme = Theme.of(context);
    
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFFE8EAF0),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Row(
          children: [
            Icon(
              Icons.check_circle_outline,
              color: const Color(0xFF8E92AB),
              size: 24,
            ),
            const SizedBox(width: 12),
            Text(
              '完了レポート',
              style: theme.textTheme.titleLarge?.copyWith(
                color: const Color(0xFF4A4E6D),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'やったこと・気づきを記録してください',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: const Color(0xFF8E92AB),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              maxLines: 4,
              autofocus: true,
              style: theme.textTheme.bodyLarge,
              decoration: InputDecoration(
                hintText: '例: 基本構成を完成させた。次は詳細を詰める。',
                hintStyle: theme.textTheme.bodySmall?.copyWith(
                  color: const Color(0xFFD8DAE5),
                ),
                filled: true,
                fillColor: const Color(0xFFE8EAF0),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(
                    color: Color(0xFF8E92AB),
                    width: 2,
                  ),
                ),
              ),
            ),
          ],
        ),
        actions: [
          OutlinedButton(
            onPressed: () => Navigator.pop(ctx, false),
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFF8E92AB),
              side: BorderSide.none,
            ),
            child: const Text('キャンセル'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('送信'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    if (_activeTasks.isEmpty) return;
    
    setState(() => _loading = true);
    
    // Show loading dialog immediately
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => PopScope(
        canPop: false,
        child: AlertDialog(
          backgroundColor: const Color(0xFFE8EAF0),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(
                color: const Color(0xFF6B7FD7),
              ),
              const SizedBox(height: 16),
              Text(
                'AIがコメントを生成中...',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: const Color(0xFF4A4E6D),
                ),
              ),
            ],
          ),
        ),
      ),
    );
    
    try {
      final api = ref.read(apiClientProvider);
      // 最初のアクティブタスクを完了
      final completedTask = await api.complete(_activeTasks.first.id, controller.text.trim());
      await _loadStatus();
      
      if (!mounted) return;
      
      // Close loading dialog
      Navigator.pop(context);
      
      // AIコメントがあれば表示
      if (completedTask.aiCompletionComment != null && completedTask.aiCompletionComment!.isNotEmpty) {
        // Show AI comment dialog
        await showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            backgroundColor: const Color(0xFFE8EAF0),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            title: Row(
              children: [
                Icon(
                  Icons.auto_awesome,
                  color: const Color(0xFF6B7FD7),
                  size: 28,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Obeyneからのコメント',
                    style: theme.textTheme.titleLarge?.copyWith(
                      color: const Color(0xFF4A4E6D),
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: const Color(0xFF6B7FD7).withOpacity(0.3),
                    ),
                  ),
                  child: Text(
                    completedTask.aiCompletionComment!,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      height: 1.6,
                      color: const Color(0xFF4A4E6D),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
            actions: [
              ElevatedButton(
                onPressed: () => Navigator.pop(ctx),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6B7FD7),
                  foregroundColor: Colors.white,
                ),
                child: const Text('閉じる'),
              ),
            ],
          ),
        );
      }
    } on DioException catch (e) {
      if (!mounted) return;
      
      // Close loading dialog
      Navigator.pop(context);
      
      // サーバーからのエラーメッセージを抽出
      String errorMessage = '処理を受け付けられない。';
      
      if (e.response?.statusCode == 400) {
        // 400エラー: バリデーションエラー
        final detail = e.response?.data?['detail'];
        if (detail != null && detail is String) {
          errorMessage = detail;
        } else if (detail != null && detail is Map) {
          errorMessage = detail.toString();
        }
      } else if (e.response?.statusCode == 422) {
        // 422エラー: バリデーションエラー（詳細）
        final detail = e.response?.data?['detail'];
        if (detail != null && detail is String) {
          errorMessage = detail;
        } else if (detail != null && detail is List) {
          // FastAPIのバリデーションエラー形式
          final errors = detail.map((err) => err['msg'] ?? err.toString()).join('\n');
          errorMessage = 'バリデーションエラー:\n$errors';
        } else {
          errorMessage = 'リクエストデータが不正です。self_reportは3文字以上必要です。';
        }
      } else if (e.response?.statusCode == 404) {
        errorMessage = 'アクティブなタスクが存在しない。確認せよ。';
      } else {
        errorMessage = '通信に問題が発生した。再試行せよ。';
      }
      
      // ユーザーフレンドリーなダイアログで表示
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: const Color(0xFFE8EAF0),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Row(
            children: [
              Icon(
                Icons.warning_amber_rounded,
                color: const Color(0xFFE57373),
                size: 28,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'AI: 却下',
                  style: theme.textTheme.titleLarge?.copyWith(
                    color: const Color(0xFFE57373),
                    letterSpacing: 2,
                  ),
                ),
              ),
            ],
          ),
          content: Text(
            errorMessage,
            style: theme.textTheme.bodyLarge?.copyWith(
              height: 1.5,
              color: const Color(0xFF4A4E6D),
            ),
          ),
          actions: [
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFE57373),
                foregroundColor: Colors.white,
              ),
              child: const Text('了解'),
            ),
          ],
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('エラー: $e'),
          backgroundColor: const Color(0xFFE57373),
        ),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _withdraw() async {
    final theme = Theme.of(context);
    
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFFE8EAF0),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Row(
          children: [
            Icon(
              Icons.cancel_outlined,
              color: const Color(0xFFE57373),
              size: 28,
            ),
            const SizedBox(width: 12),
            Text(
              'AI: 警告',
              style: theme.textTheme.titleLarge?.copyWith(
                color: const Color(0xFFE57373),
                letterSpacing: 2,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'タスクを取り下げますか？',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                height: 1.5,
                color: const Color(0xFF4A4E6D),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              '命令に背くつもりですか？\nペナルティを適用します。',
              style: theme.textTheme.bodyLarge?.copyWith(
                color: const Color(0xFF8E92AB),
                height: 1.5,
              ),
            ),
          ],
        ),
        actions: [
          OutlinedButton(
            onPressed: () => Navigator.pop(ctx, false),
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFF8E92AB),
              side: BorderSide.none,
            ),
            child: const Text('戻る'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFE57373),
              foregroundColor: Colors.white,
            ),
            child: const Text('取り下げる'),
          ),
        ],
      ),
    );
    
    if (confirm != true) return;
    if (_activeTasks.isEmpty) return;
    
    setState(() => _loading = true);
    try {
      final api = ref.read(apiClientProvider);
      // 最初のアクティブタスクを取り下げ
      await api.withdraw(_activeTasks.first.id);
      await _loadStatus();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('AI: タスクを破棄した。減点を記録。'),
          backgroundColor: const Color(0xFFE57373),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('エラー: $e'),
          backgroundColor: const Color(0xFFE57373),
        ),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  String _fmt(Duration d) {
    final neg = d.isNegative;
    final s = d.inSeconds.abs();
    final h = (s ~/ 3600).toString().padLeft(2, '0');
    final m = ((s % 3600) ~/ 60).toString().padLeft(2, '0');
    final ss = (s % 60).toString().padLeft(2, '0');
    return (neg ? '-' : '') + '$h:$m:$ss';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // 最初のアクティブタスクの残り時間を計算
    final now = DateTime.now().toUtc();
    final firstTask = _activeTasks.isNotEmpty ? _activeTasks.first : null;
    final remaining = firstTask != null 
        ? firstTask.deadlineAt.difference(now)
        : Duration.zero;
    final urgentMode = remaining.inMinutes < 10 && remaining.inSeconds > 0;
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Obeyne'),
        leading: IconButton(
          onPressed: () => context.push('/tutorial'),
          icon: const Icon(Icons.help_outline),
          tooltip: '使い方',
        ),
        actions: [
          IconButton(
            onPressed: () => context.go('/profile'),
            icon: const Icon(Icons.person_outline),
            tooltip: 'ステータス',
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              const Color(0xFFE8EAF0),
              urgentMode
                  ? const Color(0xFFE57373).withOpacity(0.1)
                  : const Color(0xFFF0F2F8),
            ],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                // AI Character
                const _LottiePlaceholder(),
                // Removed SizedBox(height: 8) to reduce spacing
                
                // AI Message
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8EAF0),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.white.withOpacity(0.7),
                        offset: const Offset(-4, -4),
                        blurRadius: 12,
                      ),
                      BoxShadow(
                        color: Colors.black.withOpacity(0.15),
                        offset: const Offset(4, 4),
                        blurRadius: 12,
                      ),
                    ],
                  ),
                  child: Text(
                    _initializing ? '' : _displayedAiLine,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: const Color(0xFF4A4E6D),
                      letterSpacing: 0.8,
                      fontWeight: FontWeight.w500,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                
                const SizedBox(height: 24),
                
                // Task Display
                Expanded(
                  child: _initializing
                      ? Center(
                          child: CircularProgressIndicator(
                            color: const Color(0xFF8E92AB),
                          ),
                        )
                      : _activeTasks.isEmpty
                      ? Center(
                          child: NewTaskButton(
                            onTap: _openCreate,
                            size: 240,
                            fontSize: 24,
                            iconSize: 64,
                          ),
                        )
                      : Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // ACTIVE TASKS ヘッダー
                              Text(
                                'ACTIVE TASKS (${_activeTasks.length}/3)',
                                style: theme.textTheme.labelLarge?.copyWith(
                                  color: const Color(0xFF8E92AB),
                                  fontSize: 11,
                                  letterSpacing: 2,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              SizedBox(height: _activeTasks.length == 2 ? 4 : 6),
                              
                              // 各タスクカードをループで表示（タスク数に応じてサイズ調整）
                              ..._activeTasks.asMap().entries.map((entry) {
                                final index = entry.key;
                                final task = entry.value;
                                final taskRemaining = task.deadlineAt.difference(now);
                                final isUrgent = taskRemaining.inMinutes < 10 && taskRemaining.inSeconds > 0;
                                
                                return Padding(
                                  padding: EdgeInsets.only(
                                    bottom: index < _activeTasks.length - 1 ? (_activeTasks.length == 2 ? 2 : 3) : 0,
                                  ),
                                  child: _TaskCard(
                                    task: task,
                                    remaining: taskRemaining,
                                    isUrgent: isUrgent,
                                    onComplete: () => _complete(),
                                    onWithdraw: () => _withdraw(),
                                    loading: _loading,
                                    taskCount: _activeTasks.length,
                                  ),
                                );
                              }).toList(),
                            
                            // NEW TASK ボタン（タスクが3つ未満の場合のみ表示）
                            if (_activeTasks.length < 3) ...[
                              SizedBox(height: _activeTasks.length == 2 ? 30 : 14),
                              NewTaskButton(
                                onTap: _openCreate,
                                size: _activeTasks.length == 2 ? 110 : 160,
                                fontSize: _activeTasks.length == 2 ? 14 : 16,
                                iconSize: _activeTasks.length == 2 ? 32 : 48,
                              ),
                            ],
                          ],
                        ),
                      ),
                ),
              ],
            ),
          ),
        ),
      ),
      // floatingActionButton: 削除しました
    );
  }
}

class Ticker {
  Ticker(this.onTick);
  final void Function(Duration) onTick;
  bool _running = false;
  void start() {
    _running = true;
    _tick();
  }

  Future<void> _tick() async {
    var elapsed = Duration.zero;
    while (_running) {
      await Future<void>.delayed(const Duration(seconds: 1));
      elapsed += const Duration(seconds: 1);
      onTick(elapsed);
    }
  }

  void dispose() => _running = false;
}

// Simple placeholder until actual Lottie JSON asset added.
class _LottiePlaceholder extends StatelessWidget {
  const _LottiePlaceholder();
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 120,
      child: Center(
        child: Lottie.asset(
          'assets/lottie/AI Brain.json',
          width: 120,
          height: 120,
          fit: BoxFit.contain,
        ),
      ),
    );
  }
}

// Neumorphic button widget
class _NeumorphicButton extends StatefulWidget {
  const _NeumorphicButton({
    required this.onPressed,
    required this.icon,
    required this.label,
    this.isSecondary = false,
    this.iconSize = 22,
    this.fontSize = 15,
  });

  final VoidCallback? onPressed;
  final IconData icon;
  final String label;
  final bool isSecondary;
  final double iconSize;
  final double fontSize;

  @override
  State<_NeumorphicButton> createState() => _NeumorphicButtonState();
}

class _NeumorphicButtonState extends State<_NeumorphicButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onPressed != null;
    return GestureDetector(
      onTapDown: enabled ? (_) => setState(() => _isPressed = true) : null,
      onTapUp: enabled ? (_) {
        setState(() => _isPressed = false);
        widget.onPressed?.call();
      } : null,
      onTapCancel: enabled ? () => setState(() => _isPressed = false) : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 100),
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
        transform: Matrix4.translationValues(0, _isPressed ? 2 : 0, 0),
        decoration: BoxDecoration(
          color: enabled
              ? (widget.isSecondary ? const Color(0xFFE8EAF0) : const Color(0xFF8E92AB))
              : const Color(0xFFE0E2EC),
          borderRadius: BorderRadius.circular(16),
          boxShadow: enabled
              ? _isPressed
                  ? [
                      BoxShadow(
                        color: Colors.white.withOpacity(0.5),
                        offset: const Offset(-2, -2),
                        blurRadius: 6,
                        spreadRadius: 0,
                      ),
                      BoxShadow(
                        color: Colors.black.withOpacity(0.15),
                        offset: const Offset(2, 2),
                        blurRadius: 6,
                        spreadRadius: 0,
                      ),
                    ]
                  : [
                      BoxShadow(
                        color: Colors.white.withOpacity(0.8),
                        offset: const Offset(-6, -6),
                        blurRadius: 12,
                        spreadRadius: 0,
                      ),
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        offset: const Offset(6, 6),
                        blurRadius: 12,
                        spreadRadius: 0,
                      ),
                    ]
              : [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    offset: const Offset(2, 2),
                    blurRadius: 6,
                  ),
                ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              widget.icon,
              color: enabled
                  ? (widget.isSecondary ? const Color(0xFF4A4E6D) : Colors.white)
                  : const Color(0xFFD8DAE5),
              size: widget.iconSize,
            ),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                widget.label,
                style: TextStyle(
                  color: enabled
                      ? (widget.isSecondary ? const Color(0xFF4A4E6D) : Colors.white)
                      : const Color(0xFFD8DAE5),
                  fontSize: widget.fontSize,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Task Card Widget
class _TaskCard extends StatelessWidget {
  const _TaskCard({
    required this.task,
    required this.remaining,
    required this.isUrgent,
    required this.onComplete,
    required this.onWithdraw,
    required this.loading,
    required this.taskCount,
  });

  final Task task;
  final Duration remaining;
  final bool isUrgent;
  final VoidCallback onComplete;
  final VoidCallback onWithdraw;
  final bool loading;
  final int taskCount;

  String _fmt(Duration d) {
    final neg = d.isNegative;
    final s = d.inSeconds.abs();
    final h = (s ~/ 3600).toString().padLeft(2, '0');
    final m = ((s % 3600) ~/ 60).toString().padLeft(2, '0');
    final ss = (s % 60).toString().padLeft(2, '0');
    return (neg ? '-' : '') + '$h:$m:$ss';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    // タスク数に応じてサイズを調整
    final double padding = taskCount == 1 ? 20 : (taskCount == 2 ? 11 : 12);
    final double titleFontSize = taskCount == 1 ? 16 : (taskCount == 2 ? 12 : 12);
    final double timerFontSize = taskCount == 1 ? 32 : (taskCount == 2 ? 24 : 24);
    final double timerIconSize = taskCount == 1 ? 20 : (taskCount == 2 ? 16 : 16);
    final double buttonHeight = taskCount == 1 ? 40 : (taskCount == 2 ? 31 : 32);
    final double buttonFontSize = taskCount == 1 ? 11 : (taskCount == 2 ? 9 : 9);
    final double buttonIconSize = taskCount == 1 ? 15 : (taskCount == 2 ? 13 : 13);
    final double verticalSpacing = taskCount == 1 ? 16 : (taskCount == 2 ? 7 : 8);
    
    return Container(
      padding: EdgeInsets.all(padding),
      decoration: BoxDecoration(
        color: const Color(0xFFE8EAF0),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.white.withOpacity(0.8),
            offset: const Offset(-6, -6),
            blurRadius: 16,
          ),
          BoxShadow(
            color: isUrgent
                ? const Color(0xFFE57373).withOpacity(0.3)
                : Colors.black.withOpacity(0.15),
            offset: const Offset(6, 6),
            blurRadius: 16,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Task Title
          Text(
            task.title,
            style: theme.textTheme.titleMedium?.copyWith(
              fontSize: titleFontSize,
              height: 1.4,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF4A4E6D),
            ),
            maxLines: taskCount == 3 ? 2 : null,
            overflow: taskCount == 3 ? TextOverflow.ellipsis : null,
          ),
          SizedBox(height: verticalSpacing),
          
          // Countdown
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: padding,
              vertical: verticalSpacing * 0.8,
            ),
            decoration: BoxDecoration(
              color: const Color(0xFFE8EAF0),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.timer_outlined,
                  size: timerIconSize,
                  color: isUrgent
                      ? const Color(0xFFE57373)
                      : const Color(0xFF8E92AB),
                ),
                const SizedBox(width: 12),
                Text(
                  _fmt(remaining),
                  style: TextStyle(
                    fontSize: timerFontSize,
                    fontWeight: FontWeight.w400,
                    letterSpacing: 3,
                    color: isUrgent
                        ? const Color(0xFFE57373)
                        : const Color(0xFF4A4E6D),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: verticalSpacing),
          
          // Action Buttons
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: buttonHeight,
                  child: _NeumorphicButton(
                    onPressed: loading ? null : onComplete,
                    icon: Icons.check_circle_outline,
                    label: '完了',
                    iconSize: buttonIconSize,
                    fontSize: buttonFontSize,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: SizedBox(
                  height: buttonHeight,
                  child: _NeumorphicButton(
                    onPressed: loading ? null : onWithdraw,
                    icon: Icons.delete_outline,
                    label: '取り下げ',
                    isSecondary: true,
                    iconSize: buttonIconSize,
                    fontSize: buttonFontSize,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
