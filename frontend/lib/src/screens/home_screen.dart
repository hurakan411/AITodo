import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lottie/lottie.dart';
import 'package:dio/dio.dart';
import '../models/task.dart';
import '../models/proposal.dart';
import '../services/api_client.dart';
import 'task_creation_modal.dart';
import 'task_proposal_modal.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  Task? _current;
  String _aiLine = '';
  Duration _remaining = Duration.zero;
  bool _loading = false;
  bool _initializing = true;
  String? _error;
  late final Ticker _ticker;
  int? _lastPoints;
  int _lastRank = 2;

  @override
  void initState() {
    super.initState();
    _loadStatus();
    _ticker = Ticker(_onTick)..start();
  }

  void _onTick(Duration _) {
    if (!mounted) return;
    if (_current == null) return;
    final now = DateTime.now().toUtc();
    final diff = _current!.deadlineAt.difference(now);
    setState(() => _remaining = diff);
    if (diff.isNegative) {
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
        _current = s.currentTask;
        _lastRank = s.profile.rank;
        // フロントエンドでランダムにセリフを生成
        _aiLine = _rankLine(s.profile.rank);
        // ignore: avoid_print
        print('[Home] ai_line: $_aiLine');
        _remaining = _current == null
            ? Duration.zero
            : _current!.deadlineAt.difference(DateTime.now().toUtc());
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

  Future<void> _extend() async {
    if (_current == null) return;
    setState(() => _loading = true);
    try {
      final api = ref.read(apiClientProvider);
      await api.extend(30);
      await _loadStatus();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('AI: 延長を許可した。30分の猶予を与える。'),
          backgroundColor: const Color(0xFF00D9FF),
        ),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('AI: 延長は既に使用済みだ。'),
          backgroundColor: const Color(0xFFFF3D3D),
        ),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _complete() async {
    final controller = TextEditingController();
    final theme = Theme.of(context);
    
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF121212),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: const Color(0xFF00D9FF).withOpacity(0.3),
          ),
        ),
        title: Row(
          children: [
            Icon(
              Icons.check_circle_outline,
              color: const Color(0xFF00D9FF),
              size: 24,
            ),
            const SizedBox(width: 12),
            Text(
              '完了レポート',
              style: theme.textTheme.titleLarge?.copyWith(
                color: const Color(0xFF00D9FF),
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
                color: const Color(0xFF808080),
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
                  color: const Color(0xFF4A4A4A),
                ),
                filled: true,
                fillColor: const Color(0xFF0A0A0A),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Color(0xFF2A2A2A)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Color(0xFF2A2A2A)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(
                    color: Color(0xFF00D9FF),
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
              foregroundColor: const Color(0xFF808080),
              side: const BorderSide(color: Color(0xFF4A4A4A)),
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
    setState(() => _loading = true);
    try {
      final api = ref.read(apiClientProvider);
      await api.complete(controller.text.trim());
      await _loadStatus();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('完了を記録しました'),
          backgroundColor: const Color(0xFF00D9FF),
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
          backgroundColor: const Color(0xFF121212),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(
              color: const Color(0xFFFF3D3D).withOpacity(0.3),
            ),
          ),
          title: Row(
            children: [
              Icon(
                Icons.warning_amber_rounded,
                color: const Color(0xFFFF3D3D),
                size: 28,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'AI: 却下',
                  style: theme.textTheme.titleLarge?.copyWith(
                    color: const Color(0xFFFF3D3D),
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
            ),
          ),
          actions: [
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFF3D3D),
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
          backgroundColor: const Color(0xFFFF3D3D),
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
        backgroundColor: const Color(0xFF121212),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: const Color(0xFFFF3D3D).withOpacity(0.5),
          ),
        ),
        title: Row(
          children: [
            Icon(
              Icons.cancel_outlined,
              color: const Color(0xFFFF3D3D),
              size: 28,
            ),
            const SizedBox(width: 12),
            Text(
              'AI: 警告',
              style: theme.textTheme.titleLarge?.copyWith(
                color: const Color(0xFFFF3D3D),
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
              ),
            ),
            const SizedBox(height: 12),
            Text(
              '取り下げは失敗扱いだ。\nペナルティが適用される。',
              style: theme.textTheme.bodyLarge?.copyWith(
                color: const Color(0xFF808080),
                height: 1.5,
              ),
            ),
          ],
        ),
        actions: [
          OutlinedButton(
            onPressed: () => Navigator.pop(ctx, false),
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFF00D9FF),
              side: const BorderSide(color: Color(0xFF00D9FF)),
            ),
            child: const Text('戻る'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFF3D3D),
              foregroundColor: Colors.white,
            ),
            child: const Text('取り下げる'),
          ),
        ],
      ),
    );
    
    if (confirm != true) return;
    
    setState(() => _loading = true);
    try {
      final api = ref.read(apiClientProvider);
      await api.withdraw();
      await _loadStatus();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('AI: タスクを破棄した。減点を記録。'),
          backgroundColor: const Color(0xFFFF3D3D),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('エラー: $e'),
          backgroundColor: const Color(0xFFFF3D3D),
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
    final urgentMode = _remaining.inMinutes < 10 && _remaining.inSeconds > 0;
    
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
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              const Color(0xFF0A0A0A),
              urgentMode
                  ? const Color(0xFFFF3D3D).withOpacity(0.1)
                  : const Color(0xFF00D9FF).withOpacity(0.05),
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
                const SizedBox(height: 16),
                
                // AI Message
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF121212).withOpacity(0.8),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: const Color(0xFF00D9FF).withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  child: Text(
                    _aiLine.isEmpty ? _rankLine(_lastRank) : _aiLine,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: const Color(0xFF00D9FF),
                      letterSpacing: 1,
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
                            color: const Color(0xFF00D9FF),
                          ),
                        )
                      : _current == null
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.inbox_outlined,
                                size: 64,
                                color: const Color(0xFF4A4A4A),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                '現在のタスクはありません',
                                style: theme.textTheme.bodyLarge?.copyWith(
                                  color: const Color(0xFF808080),
                                ),
                              ),
                              const SizedBox(height: 32),
                              ElevatedButton.icon(
                                onPressed: _openCreate,
                                icon: const Icon(Icons.add),
                                label: const Text('新規タスクを作成'),
                              ),
                            ],
                          ),
                        )
                      : SingleChildScrollView(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              // Task Card
                              Container(
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    const Color(0xFF121212),
                                    const Color(0xFF1A1A1A),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: urgentMode
                                      ? const Color(0xFFFF3D3D).withOpacity(0.5)
                                      : const Color(0xFF00D9FF).withOpacity(0.3),
                                  width: 2,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: urgentMode
                                        ? const Color(0xFFFF3D3D).withOpacity(0.2)
                                        : const Color(0xFF00D9FF).withOpacity(0.1),
                                    blurRadius: 20,
                                    spreadRadius: 2,
                                  ),
                                ],
                              ),
                              child: Column(
                                children: [
                                  Text(
                                    'ACTIVE TASK',
                                    style: theme.textTheme.labelLarge?.copyWith(
                                      color: const Color(0xFF808080),
                                      fontSize: 10,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    _current!.title,
                                    style: theme.textTheme.titleLarge?.copyWith(
                                      fontSize: 16,
                                      height: 1.3,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                  const SizedBox(height: 12),
                                  // Expected Points
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF0A0A0A),
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                        color: const Color(0xFFFFD700).withOpacity(0.3),
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          Icons.star_border_rounded,
                                          color: const Color(0xFFFFD700),
                                          size: 14,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          '獲得予定: ',
                                          style: theme.textTheme.bodySmall?.copyWith(
                                            color: const Color(0xFF808080),
                                            fontSize: 11,
                                          ),
                                        ),
                                        Text(
                                          '+${min(5, max(1, (_current!.estimateMinutes / 60 / 6).floor()))}',
                                          style: theme.textTheme.bodyMedium?.copyWith(
                                            color: const Color(0xFFFFD700),
                                            fontWeight: FontWeight.w600,
                                            fontSize: 12,
                                          ),
                                        ),
                                        if (_remaining.inSeconds > 0) ...[
                                          Text(
                                            ' +${min(7, _remaining.inSeconds ~/ 3600)}',
                                            style: theme.textTheme.bodyMedium?.copyWith(
                                              color: const Color(0xFF00D9FF),
                                              fontWeight: FontWeight.w600,
                                              fontSize: 12,
                                            ),
                                          ),
                                          Text(
                                            ' = ${min(5, max(1, (_current!.estimateMinutes / 60 / 6).floor())) + min(7, _remaining.inSeconds ~/ 3600)} pts',
                                            style: theme.textTheme.bodyMedium?.copyWith(
                                              color: const Color(0xFFFFD700),
                                              fontWeight: FontWeight.bold,
                                              fontSize: 13,
                                            ),
                                          ),
                                        ] else ...[
                                          Text(
                                            ' pts',
                                            style: theme.textTheme.bodySmall?.copyWith(
                                              color: const Color(0xFF808080),
                                              fontSize: 11,
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  // Countdown
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 24,
                                      vertical: 12,
                                    ),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF0A0A0A),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: urgentMode
                                            ? const Color(0xFFFF3D3D)
                                            : const Color(0xFF00D9FF).withOpacity(0.3),
                                      ),
                                    ),
                                    child: Text(
                                      _fmt(_remaining),
                                      style: TextStyle(
                                        fontSize: 32,
                                        fontWeight: FontWeight.w200,
                                        letterSpacing: 3,
                                        color: urgentMode
                                            ? const Color(0xFFFF3D3D)
                                            : Colors.white,
                                        shadows: urgentMode
                                            ? [
                                                Shadow(
                                                  color: const Color(0xFFFF3D3D),
                                                  blurRadius: 10,
                                                ),
                                              ]
                                            : null,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  // Action Buttons
                                  Row(
                                    children: [
                                      Expanded(
                                        child: ElevatedButton.icon(
                                          onPressed: _loading ? null : _complete,
                                          icon: const Icon(Icons.check_circle_outline),
                                          label: const Text('完了'),
                                          style: ElevatedButton.styleFrom(
                                            padding: const EdgeInsets.symmetric(vertical: 14),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: OutlinedButton.icon(
                                          onPressed: _loading || _current!.extensionUsed
                                              ? null
                                              : _extend,
                                          icon: const Icon(Icons.update),
                                          label: Text(
                                            _current!.extensionUsed ? '使用済' : '延長',
                                          ),
                                          style: OutlinedButton.styleFrom(
                                            padding: const EdgeInsets.symmetric(vertical: 14),
                                            disabledForegroundColor: const Color(0xFF4A4A4A),
                                            disabledBackgroundColor: Colors.transparent,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  // 取り下げボタン
                                  SizedBox(
                                    width: double.infinity,
                                    child: TextButton.icon(
                                      onPressed: _loading ? null : _withdraw,
                                      icon: Icon(
                                        Icons.delete_outline,
                                        size: 18,
                                        color: _loading 
                                            ? const Color(0xFF4A4A4A)
                                            : const Color(0xFFFF3D3D),
                                      ),
                                      label: Text(
                                        'タスクを取り下げる',
                                        style: TextStyle(
                                          fontSize: 13,
                                          color: _loading 
                                              ? const Color(0xFF4A4A4A)
                                              : const Color(0xFFFF3D3D),
                                        ),
                                      ),
                                      style: TextButton.styleFrom(
                                        padding: const EdgeInsets.symmetric(vertical: 8),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            
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
