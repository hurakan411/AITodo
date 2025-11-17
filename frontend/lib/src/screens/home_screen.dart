import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lottie/lottie.dart';
import 'package:dio/dio.dart';
import '../models/task.dart';
import '../services/api_client.dart';
import 'task_creation_modal.dart';
import 'task_proposal_modal.dart';

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
  bool _isButtonPressed = false; // ボタン押下状態

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
    }
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  Future<void> _loadStatus() async {
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
        // フロントエンドでランダムにセリフを生成
        _aiLine = _rankLine(s.profile.rank);
        // ignore: avoid_print
        print('[Home] ai_line: $_aiLine');
        _initializing = false;
      });
      if (_lastPoints != null && s.profile.points < _lastPoints!) {
        // ポイント減少＝失敗の可能性が高い
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('期限超過：減点が適用されました')),
        );
      }
      _lastPoints = s.profile.points;
    } catch (e) {
      // ignore: avoid_print
      print('[Home] Error loading status: $e');
      if (!mounted) return;
      setState(() {
        _error = 'ステータス取得に失敗しました';
        _initializing = false;
      });
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
    // ボタンを押したらすぐに元に戻す
    setState(() => _isButtonPressed = true);
    await Future.delayed(const Duration(milliseconds: 100));
    if (mounted) {
      setState(() => _isButtonPressed = false);
    }
    
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
    try {
      final api = ref.read(apiClientProvider);
      // 最初のアクティブタスクを完了
      await api.complete(_activeTasks.first.id, controller.text.trim());
      await _loadStatus();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('完了を記録しました'),
          backgroundColor: const Color(0xFF8E92AB),
        ),
      );
    } on DioException catch (e) {
      if (!mounted) return;
      
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
              'タスクを取り下げるか？',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                height: 1.5,
                color: const Color(0xFF4A4E6D),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              '取り下げは失敗扱いだ。\nペナルティが適用される。',
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
        title: const Text('OBEY'),
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
                const SizedBox(height: 8),
                
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
                    _aiLine.isEmpty ? _rankLine(_lastRank) : _aiLine,
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
                  child: _initializing && _activeTasks.isNotEmpty
                      ? Center(
                          child: CircularProgressIndicator(
                            color: const Color(0xFF8E92AB),
                          ),
                        )
                      : _activeTasks.isEmpty
                      ? Center(
                          child: GestureDetector(
                            onTap: _openCreate,
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 100),
                              width: 240,
                              height: 240,
                              transform: Matrix4.translationValues(
                                0,
                                _isButtonPressed ? 4 : 0,
                                0,
                              ),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: _isButtonPressed
                                      ? [
                                          const Color(0xFFD0D3E0),
                                          const Color(0xFFE0E2EC),
                                        ]
                                      : [
                                          const Color(0xFFE0E2EC),
                                          const Color(0xFFF0F2F8),
                                        ],
                                ),
                                boxShadow: _isButtonPressed
                                    ? [
                                        // 押下時：小さな影で沈んだ印象
                                        BoxShadow(
                                          color: Colors.white.withOpacity(0.3),
                                          offset: const Offset(-2, -2),
                                          blurRadius: 8,
                                          spreadRadius: 0,
                                        ),
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.15),
                                          offset: const Offset(2, 2),
                                          blurRadius: 8,
                                          spreadRadius: 0,
                                        ),
                                      ]
                                    : [
                                        // 通常時：大きな影で浮き上がった印象
                                        BoxShadow(
                                          color: Colors.white.withOpacity(0.8),
                                          offset: const Offset(-8, -8),
                                          blurRadius: 20,
                                          spreadRadius: 2,
                                        ),
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.2),
                                          offset: const Offset(8, 8),
                                          blurRadius: 20,
                                          spreadRadius: 2,
                                        ),
                                      ],
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.add_circle_outline,
                                    size: 72,
                                    color: const Color(0xFF8E92AB),
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    'NEW\nTASK',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      color: const Color(0xFF8E92AB),
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 4,
                                      height: 1.2,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        )
                      : SingleChildScrollView(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
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
                              const SizedBox(height: 16),
                              
                              // 各タスクカードをループで表示
                              ..._activeTasks.asMap().entries.map((entry) {
                                final index = entry.key;
                                final task = entry.value;
                                final taskRemaining = task.deadlineAt.difference(now);
                                final isUrgent = taskRemaining.inMinutes < 10 && taskRemaining.inSeconds > 0;
                                
                                return Padding(
                                  padding: EdgeInsets.only(
                                    bottom: index < _activeTasks.length - 1 ? 16 : 0,
                                  ),
                                  child: _TaskCard(
                                    task: task,
                                    remaining: taskRemaining,
                                    isUrgent: isUrgent,
                                    onComplete: () => _complete(),
                                    onWithdraw: () => _withdraw(),
                                    loading: _loading,
                                  ),
                                );
                              }).toList(),
                            
                            // NEW TASK ボタン（タスクが3つ未満の場合のみ表示）
                            if (_activeTasks.length < 3) ...[
                              const SizedBox(height: 24),
                              GestureDetector(
                                onTap: _openCreate,
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 100),
                                  width: 160,
                                  height: 160,
                                  transform: Matrix4.translationValues(
                                    0,
                                    _isButtonPressed ? 4 : 0,
                                    0,
                                  ),
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    gradient: LinearGradient(
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                      colors: _isButtonPressed
                                          ? [
                                              const Color(0xFFD0D3E0),
                                              const Color(0xFFE0E2EC),
                                            ]
                                          : [
                                              const Color(0xFFE0E2EC),
                                              const Color(0xFFF0F2F8),
                                            ],
                                    ),
                                    boxShadow: _isButtonPressed
                                        ? [
                                            BoxShadow(
                                              color: Colors.white.withOpacity(0.3),
                                              offset: const Offset(-2, -2),
                                              blurRadius: 8,
                                              spreadRadius: 0,
                                            ),
                                            BoxShadow(
                                              color: Colors.black.withOpacity(0.15),
                                              offset: const Offset(2, 2),
                                              blurRadius: 8,
                                              spreadRadius: 0,
                                            ),
                                          ]
                                        : [
                                            BoxShadow(
                                              color: Colors.white.withOpacity(0.8),
                                              offset: const Offset(-6, -6),
                                              blurRadius: 16,
                                              spreadRadius: 1,
                                            ),
                                            BoxShadow(
                                              color: Colors.black.withOpacity(0.2),
                                              offset: const Offset(6, 6),
                                              blurRadius: 16,
                                              spreadRadius: 1,
                                            ),
                                          ],
                                  ),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.add_circle_outline,
                                        size: 48,
                                        color: const Color(0xFF8E92AB),
                                      ),
                                      const SizedBox(height: 12),
                                      Text(
                                        'NEW\nTASK',
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          color: const Color(0xFF8E92AB),
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          letterSpacing: 3,
                                          height: 1.2,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                            
                            if (_error != null) ...[
                              const SizedBox(height: 16),
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFF3D3D).withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: const Color(0xFFFF3D3D).withOpacity(0.3),
                                  ),
                                ),
                                child: Text(
                                  _error!,
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: const Color(0xFFFF3D3D),
                                  ),
                                ),
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
      height: 140,
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
class _NeumorphicButton extends StatelessWidget {
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
  Widget build(BuildContext context) {
    final enabled = onPressed != null;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: enabled ? onPressed : null,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
          decoration: BoxDecoration(
            color: enabled
                ? (isSecondary ? const Color(0xFFE8EAF0) : const Color(0xFF8E92AB))
                : const Color(0xFFE0E2EC),
            borderRadius: BorderRadius.circular(16),
            boxShadow: enabled
                ? [
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
                icon,
                color: enabled
                    ? (isSecondary ? const Color(0xFF4A4E6D) : Colors.white)
                    : const Color(0xFFD8DAE5),
                size: iconSize,
              ),
              const SizedBox(width: 10),
              Text(
                label,
                style: TextStyle(
                  color: enabled
                      ? (isSecondary ? const Color(0xFF4A4E6D) : Colors.white)
                      : const Color(0xFFD8DAE5),
                  fontSize: fontSize,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1.2,
                ),
              ),
            ],
          ),
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
  });

  final Task task;
  final Duration remaining;
  final bool isUrgent;
  final VoidCallback onComplete;
  final VoidCallback onWithdraw;
  final bool loading;

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
    
    return Container(
      padding: const EdgeInsets.all(20),
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
              fontSize: 16,
              height: 1.4,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF4A4E6D),
            ),
          ),
          const SizedBox(height: 16),
          
          // Countdown
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 24,
              vertical: 16,
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
                  size: 20,
                  color: isUrgent
                      ? const Color(0xFFE57373)
                      : const Color(0xFF8E92AB),
                ),
                const SizedBox(width: 12),
                Text(
                  _fmt(remaining),
                  style: TextStyle(
                    fontSize: 32,
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
          const SizedBox(height: 16),
          
          // Action Buttons
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 40,
                  child: _NeumorphicButton(
                    onPressed: loading ? null : onComplete,
                    icon: Icons.check_circle_outline,
                    label: '完了',
                    iconSize: 18,
                    fontSize: 13,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: SizedBox(
                  height: 40,
                  child: _NeumorphicButton(
                    onPressed: loading ? null : onWithdraw,
                    icon: Icons.delete_outline,
                    label: '取り下げ',
                    isSecondary: true,
                    iconSize: 18,
                    fontSize: 13,
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
