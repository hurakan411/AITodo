import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/proposal.dart';
import '../services/api_client.dart';
import 'package:dio/dio.dart';

class TaskProposalModal extends ConsumerStatefulWidget {
  const TaskProposalModal({super.key, required this.proposal});
  final TaskProposal proposal;

  @override
  ConsumerState<TaskProposalModal> createState() => _TaskProposalModalState();
}

class _TaskProposalModalState extends ConsumerState<TaskProposalModal> {
  bool _loading = false;
  String? _error;

  Future<void> _accept({bool andExtend = false}) async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final api = ref.read(apiClientProvider);
      await api.accept(widget.proposal);
      if (!mounted) return;
      
      // Close this proposal modal
      Navigator.of(context).pop();
      
      // 受諾完了（SnackBarは廃止）
    } on DioException catch (e) {
      if (mounted) {
        setState(() => _error = e.response?.data?.toString() ?? 'エラー');
      }
    } catch (e) {
      if (mounted) {
        setState(() => _error = '受諾に失敗しました');
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final p = widget.proposal;
    
    // UTC時刻をJST(+9時間)に変換
    final deadlineJst = p.deadlineAt.add(const Duration(hours: 9));
    
    // ポイント計算: 見積もり時間から算出
    final estimatedHours = p.estimateMinutes / 60;
    final basePoints = min(5, max(1, (estimatedHours / 6).floor()));
    
    // AIコメントはバックエンドから取得したものを使用（フォールバック付き）
    final aiComment = p.aiComment.isEmpty ? 'このタスクを分析した。実行せよ。' : p.aiComment;
    
    return Material(
      color: Colors.transparent,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              const Color(0xFFE8EAF0),
              const Color(0xFFF0F2F8),
            ],
          ),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            24,
            24,
            24,
            MediaQuery.of(context).viewInsets.bottom + 24,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF8E92AB).withOpacity(0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'AI PROPOSAL',
                        style: theme.textTheme.labelLarge?.copyWith(
                          color: const Color(0xFF8E92AB),
                          fontSize: 12,
                          letterSpacing: 2,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close),
                      color: const Color(0xFF8E92AB),
                    ),
                  ],
                ),
                
                const SizedBox(height: 24),
                
                // AI Comment
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8EAF0),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.psychology_outlined,
                        color: const Color(0xFF8E92AB),
                        size: 22,
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Text(
                          aiComment,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: const Color(0xFF4A4E6D),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 24),
                
                // Task Name - 目立つように
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8EAF0),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'TASK',
                        style: theme.textTheme.labelLarge?.copyWith(
                          color: const Color(0xFF4A4E6D),
                          fontSize: 11,
                          letterSpacing: 2,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        p.title,
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontSize: 22,
                          color: const Color(0xFF8E92AB),
                          fontWeight: FontWeight.w700,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 16),
                
                // Expected Points
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8EAF0),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.star_border_rounded,
                        color: const Color(0xFF8E92AB),
                        size: 22,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        '達成時の基本報酬: ',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: const Color(0xFF4A4E6D),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        '+$basePoints pts',
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: const Color(0xFF8E92AB),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '+ 時間ボーナス',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: const Color(0xFF8E92AB),
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 24),
                
                // Task Details Card (ESTIMATE & DEADLINE)
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8EAF0),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'ESTIMATE',
                                  style: theme.textTheme.labelLarge?.copyWith(
                                    color: const Color(0xFF4A4E6D),
                                    fontSize: 10,
                                    letterSpacing: 1.5,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  '${(p.estimateMinutes / 60).toStringAsFixed(1)}時間',
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    color: const Color(0xFF8E92AB),
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'DEADLINE',
                                  style: theme.textTheme.labelLarge?.copyWith(
                                    color: const Color(0xFF4A4E6D),
                                    fontSize: 10,
                                    letterSpacing: 1.5,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  '${deadlineJst.hour.toString().padLeft(2, '0')}:${deadlineJst.minute.toString().padLeft(2, '0')}',
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    color: const Color(0xFF8E92AB),
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 24),
                
                // Action Buttons
                SizedBox(
                  width: double.infinity,
                  child: _NeumorphicButton(
                    onPressed: _loading ? null : () => _accept(andExtend: false),
                    backgroundColor: const Color(0xFF8E92AB),
                    textColor: Colors.white,
                    child: _loading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : const Text('承認'),
                  ),
                ),
                
                if (_error != null) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE57373).withOpacity(0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.error_outline,
                          size: 18,
                          color: const Color(0xFFE57373),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            _error!,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: const Color(0xFFE57373),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NeumorphicButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final Widget child;
  final Color backgroundColor;
  final Color textColor;

  const _NeumorphicButton({
    required this.onPressed,
    required this.child,
    this.backgroundColor = const Color(0xFF8E92AB),
    this.textColor = Colors.white,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(14),
            boxShadow: onPressed == null
                ? []
                : [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.12),
                      offset: const Offset(4, 4),
                      blurRadius: 10,
                    ),
                    BoxShadow(
                      color: Colors.white.withOpacity(0.5),
                      offset: const Offset(-4, -4),
                      blurRadius: 10,
                    ),
                  ],
          ),
          child: DefaultTextStyle(
            style: TextStyle(
              color: textColor,
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
            child: Center(child: child),
          ),
        ),
      ),
    );
  }
}
