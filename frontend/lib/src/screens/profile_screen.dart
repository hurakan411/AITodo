import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lottie/lottie.dart';
import 'package:go_router/go_router.dart';
import '../services/api_client.dart';
import '../models/task.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  int _points = 10;
  int _rank = 2;
  int _nextThreshold = 0;
  List<Task> _recent = [];
  String _aiLine = '';
  String? _error;
  bool _initializing = true;
  final Set<String> _expandedDates = {}; // アコーディオンの開閉状態を管理

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final api = ref.read(apiClientProvider);
      final s = await api.status();
      if (!mounted) return;
      setState(() {
        _points = s.profile.points;
        _rank = s.profile.rank;
        _nextThreshold = s.nextThreshold;
        _recent = s.recentTasks;
        final fetched = (s.aiLine).trim();
        _aiLine = fetched.isEmpty ? _rankLine(_rank) : fetched;
        _initializing = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = '取得に失敗しました';
        _initializing = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('STATUS'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/home'),
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              const Color(0xFFE8EAF0),
              const Color(0xFFF0F2F8),
            ],
          ),
        ),
        child: _error != null
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.error_outline,
                      size: 64,
                      color: const Color(0xFFE57373),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      _error!,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: const Color(0xFFE57373),
                      ),
                    ),
                  ],
                ),
              )
            : _initializing
            ? Center(
                child: CircularProgressIndicator(
                  color: const Color(0xFF8E92AB),
                ),
              )
            : RefreshIndicator(
                onRefresh: _load,
                color: const Color(0xFF8E92AB),
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // AI Character
                      const Center(child: _LottiePlaceholder()),
                      const SizedBox(height: 24),
                      
                      // AI Message
                      Center(
                        child: Container(
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
                            _aiLine.isEmpty ? _rankLine(_rank) : _aiLine,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: const Color(0xFF4A4E6D),
                              letterSpacing: 0.8,
                              fontWeight: FontWeight.w500,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                      
                      const SizedBox(height: 32),
                      
                      // Character Mode (Inset Neumorphism)
                      Center(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE8EAF0),
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              // 内側の影（凹み効果） - 影を内側に反転
                              BoxShadow(
                                color: Colors.black.withOpacity(0.2),
                                offset: const Offset(-3, -3),
                                blurRadius: 6,
                                spreadRadius: -1,
                              ),
                              BoxShadow(
                                color: Colors.white.withOpacity(0.8),
                                offset: const Offset(3, 3),
                                blurRadius: 6,
                                spreadRadius: -1,
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.psychology_outlined,
                                size: 18,
                                color: const Color(0xFF8E92AB),
                              ),
                              const SizedBox(width: 10),
                              Text(
                                _characterMode(_rank),
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: const Color(0xFF4A4E6D),
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 1.2,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // Stats Grid
                      Row(
                        children: [
                          Expanded(
                            child: _StatCard(
                              label: 'RANK',
                              value: '$_rank',
                              icon: Icons.military_tech_outlined,
                              color: _getRankColor(_rank),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _StatCard(
                              label: 'POINTS',
                              value: '$_points',
                              icon: Icons.stars_outlined,
                              color: const Color(0xFF00D9FF),
                            ),
                          ),
                        ],
                      ),
                      
                      const SizedBox(height: 32),
                      
                      // Progress to Next Rank
                      Container(
                        padding: const EdgeInsets.all(24),
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
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'NEXT THRESHOLD',
                              style: theme.textTheme.labelLarge?.copyWith(
                                color: const Color(0xFF8E92AB),
                                fontSize: 11,
                                letterSpacing: 2,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  '$_points',
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    color: const Color(0xFF4A4E6D),
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                Text(
                                  '$_nextThreshold',
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    color: const Color(0xFF8E92AB),
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Container(
                                height: 10,
                                decoration: BoxDecoration(
                                  color: const Color(0xFFE8EAF0),
                                  borderRadius: BorderRadius.circular(8),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.1),
                                      offset: const Offset(2, 2),
                                      blurRadius: 4,
                                      spreadRadius: 0,
                                    ),
                                    BoxShadow(
                                      color: Colors.white.withOpacity(0.5),
                                      offset: const Offset(-2, -2),
                                      blurRadius: 4,
                                      spreadRadius: 0,
                                    ),
                                  ],
                                ),
                                child: LinearProgressIndicator(
                                  value: _nextThreshold > 0
                                      ? (_points / _nextThreshold).clamp(0.0, 1.0)
                                      : 0.0,
                                  minHeight: 10,
                                  backgroundColor: Colors.transparent,
                                  valueColor: const AlwaysStoppedAnimation<Color>(
                                    Color(0xFF6B7FD7),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      
                      const SizedBox(height: 32),
                      
                      // Task History
                      Text(
                        'TASK HISTORY',
                        style: theme.textTheme.titleMedium?.copyWith(
                          letterSpacing: 2,
                          color: const Color(0xFF4A4E6D),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 16),
                      
                      if (_recent.isEmpty)
                        Center(
                          child: Padding(
                            padding: const EdgeInsets.all(32),
                            child: Text(
                              '履歴なし',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: const Color(0xFF8E92AB),
                              ),
                            ),
                          ),
                        )
                      else
                        ..._buildTasksByDate(),
                    ],
                  ),
                ),
              ),
      ),
    );
  }
  
  // タスクを年月ごとにグループ化してアコーディオンで表示
  List<Widget> _buildTasksByDate() {
    // タスクを年月ごとにグループ化
    final Map<String, List<Task>> tasksByMonth = {};
    
    for (final task in _recent) {
      final date = DateTime(
        task.createdAt.year,
        task.createdAt.month,
      );
      final monthKey = '${date.year}-${date.month.toString().padLeft(2, '0')}';
      tasksByMonth.putIfAbsent(monthKey, () => []).add(task);
    }
    
    // 年月の降順でソート
    final sortedMonths = tasksByMonth.keys.toList()
      ..sort((a, b) => b.compareTo(a));
    
    return sortedMonths.map((monthKey) {
      final tasks = tasksByMonth[monthKey]!;
      final isExpanded = _expandedDates.contains(monthKey);
      final parts = monthKey.split('-');
      final year = int.parse(parts[0]);
      final month = int.parse(parts[1]);
      final monthLabel = '$year年${month}月';
      
      return Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Container(
          decoration: BoxDecoration(
            color: const Color(0xFFE8EAF0),
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: Colors.white.withOpacity(0.5),
                offset: const Offset(-3, -3),
                blurRadius: 8,
              ),
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                offset: const Offset(3, 3),
                blurRadius: 8,
              ),
            ],
          ),
          child: Column(
            children: [
              // 年月ヘッダー（クリック可能）
              InkWell(
                onTap: () {
                  setState(() {
                    if (isExpanded) {
                      _expandedDates.remove(monthKey);
                    } else {
                      _expandedDates.add(monthKey);
                    }
                  });
                },
                borderRadius: BorderRadius.circular(14),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Icon(
                        isExpanded ? Icons.expand_more : Icons.chevron_right,
                        color: const Color(0xFF8E92AB),
                        size: 24,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        monthLabel,
                        style: const TextStyle(
                          color: Color(0xFF4A4E6D),
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFF8E92AB).withOpacity(0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '${tasks.length}件',
                          style: const TextStyle(
                            color: Color(0xFF8E92AB),
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              
              // タスクリスト（展開時のみ表示）
              if (isExpanded)
                Container(
                  padding: const EdgeInsets.only(left: 16, right: 16, bottom: 16),
                  child: Column(
                    children: tasks.map((task) {
                      // 日付を表示
                      final taskDate = task.createdAt;
                      final dateLabel = '${taskDate.month}/${taskDate.day}';
                      
                      return Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE8EAF0),
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                offset: const Offset(2, 2),
                                blurRadius: 4,
                              ),
                              BoxShadow(
                                color: Colors.white.withOpacity(0.5),
                                offset: const Offset(-2, -2),
                                blurRadius: 4,
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 8,
                                height: 8,
                                decoration: BoxDecoration(
                                  color: _getStatusColor(task.status),
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      task.title,
                                      style: const TextStyle(
                                        color: Color(0xFF4A4E6D),
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '$dateLabel · ${task.status} · ${(task.estimateMinutes / 60).toStringAsFixed(1)}時間',
                                      style: const TextStyle(
                                        color: Color(0xFF8E92AB),
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Icon(
                                _getStatusIcon(task.status),
                                size: 18,
                                color: _getStatusColor(task.status),
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
            ],
          ),
        ),
      );
    }).toList();
  }
  
  Color _getRankColor(int rank) {
    if (rank >= 6) return const Color(0xFF4CAF50); // Green
    if (rank >= 4) return const Color(0xFF6B7FD7); // Blue-purple
    if (rank >= 2) return const Color(0xFFFFA726); // Orange
    return const Color(0xFFE57373); // Red
  }
  
  Color _getStatusColor(String status) {
    switch (status) {
      case 'COMPLETED':
        return const Color(0xFF4CAF50);
      case 'FAILED':
        return const Color(0xFFE57373);
      case 'ACTIVE':
        return const Color(0xFF6B7FD7);
      default:
        return const Color(0xFF8E92AB);
    }
  }
  
  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'COMPLETED':
        return Icons.check_circle_outline;
      case 'FAILED':
        return Icons.cancel_outlined;
      case 'ACTIVE':
        return Icons.play_circle_outline;
      default:
        return Icons.help_outline;
    }
  }
}

String _rankLine(int rank) {
  switch (rank) {
    case 1:
      return '...了承。';
    case 2:
      return '命令を待機中。';
    case 3:
      return '進行状況を監視中。';
    case 4:
      return '観測継続。必要なら助言する。';
    case 5:
      return '悪くありません。頑張っています。';
    case 6:
      return 'よく頑張っています。無理しすぎないように。';
    case 7:
      return 'あなたは完璧です。これからもよろしくお願いしますね。';
    default:
      return '...';
  }
}

String _characterMode(int rank) {
  switch (rank) {
    case 1:
      return '失望モード';
    case 2:
      return '無機質モード';
    case 3:
      return '分析者モード';
    case 4:
      return '監視者モード';
    case 5:
      return '助言者モード';
    case 6:
      return '守護者モード';
    case 7:
      return '相棒モード';
    default:
      return '不明';
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  
  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });
  
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFFE8EAF0),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.white.withOpacity(0.7),
            offset: const Offset(-6, -6),
            blurRadius: 12,
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            offset: const Offset(6, 6),
            blurRadius: 12,
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 36, color: const Color(0xFF8E92AB)),
          const SizedBox(height: 14),
          Text(
            value,
            style: theme.textTheme.displayMedium?.copyWith(
              color: const Color(0xFF4A4E6D),
              fontWeight: FontWeight.w600,
              fontSize: 32,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: theme.textTheme.labelLarge?.copyWith(
              color: const Color(0xFF8E92AB),
              fontSize: 11,
              letterSpacing: 2,
            ),
          ),
        ],
      ),
    );
  }
}

class _LottiePlaceholder extends StatelessWidget {
  const _LottiePlaceholder();
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 120,
      child: Center(
        child: Lottie.asset(
          'assets/lottie/AI Brain.json',
          width: 100,
          height: 100,
          fit: BoxFit.contain,
        ),
      ),
    );
  }
}
