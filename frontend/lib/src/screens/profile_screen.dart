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
  bool _aiRetryScheduled = false;
  bool _initializing = true;

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
      if ((s.aiLine).trim().isEmpty && !_aiRetryScheduled) {
        _aiRetryScheduled = true;
        Future.delayed(const Duration(seconds: 1), () async {
          if (!mounted) return;
          _aiRetryScheduled = false;
          await _load();
        });
      }
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
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(20),
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
                      
                      const SizedBox(height: 32),
                      
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
                        ..._recent.map((task) => Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: Container(
                                padding: const EdgeInsets.all(18),
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
                                child: Row(
                                  children: [
                                    Container(
                                      width: 10,
                                      height: 10,
                                      decoration: BoxDecoration(
                                        color: _getStatusColor(task.status),
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                    const SizedBox(width: 14),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            task.title,
                                            style: theme.textTheme.bodyLarge?.copyWith(
                                              color: const Color(0xFF4A4E6D),
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            '${task.status} · ${(task.estimateMinutes / 60).toStringAsFixed(1)}時間',
                                            style: theme.textTheme.bodySmall?.copyWith(
                                              color: const Color(0xFF8E92AB),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Icon(
                                      _getStatusIcon(task.status),
                                      size: 22,
                                      color: _getStatusColor(task.status),
                                    ),
                                  ],
                                ),
                              ),
                            )),
                    ],
                  ),
                ),
              ),
      ),
    );
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
      return 'よくできています。次に備えましょう。';
    case 6:
      return '焦らず進もう。必要なら支援する。';
    case 7:
      return 'ここまで順調です。任せて進みましょう。';
    default:
      return '...';
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
