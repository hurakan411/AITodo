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
  int _extendMinutes = 180;  // 3時間をデフォルトに
  String? _error;

  Future<void> _accept({bool andExtend = false}) async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final api = ref.read(apiClientProvider);
      await api.accept(widget.proposal);
      if (andExtend) {
        await api.extend(_extendMinutes);
      }
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
              const Color(0xFF121212),
              const Color(0xFF0A0A0A),
            ],
          ),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
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
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFF00D9FF).withOpacity(0.2),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(
                          color: const Color(0xFF00D9FF).withOpacity(0.5),
                        ),
                      ),
                      child: Text(
                        'AI PROPOSAL',
                        style: theme.textTheme.labelLarge?.copyWith(
                          color: const Color(0xFF00D9FF),
                          fontSize: 11,
                        ),
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close),
                      color: const Color(0xFF808080),
                    ),
                  ],
                ),
                
                const SizedBox(height: 24),
                
                // AI Comment
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        const Color(0xFF00D9FF).withOpacity(0.1),
                        const Color(0xFF00D9FF).withOpacity(0.05),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: const Color(0xFF00D9FF).withOpacity(0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.psychology_outlined,
                        color: const Color(0xFF00D9FF),
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          aiComment,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: const Color(0xFF00D9FF),
                            height: 1.4,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 16),
                
                // Expected Points
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1A1A1A),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: const Color(0xFF2A2A2A),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.star_border_rounded,
                        color: const Color(0xFFFFD700),
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        '達成時の基本報酬: ',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: const Color(0xFF808080),
                        ),
                      ),
                      Text(
                        '+$basePoints pts',
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: const Color(0xFFFFD700),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '+ 時間ボーナス',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: const Color(0xFF808080),
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 24),
                
                // Task Details Card
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1A1A1A),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: const Color(0xFF2A2A2A),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'TASK',
                        style: theme.textTheme.labelLarge?.copyWith(
                          color: const Color(0xFF808080),
                          fontSize: 11,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        p.title,
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontSize: 18,
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Divider(color: Color(0xFF2A2A2A)),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'ESTIMATE',
                                  style: theme.textTheme.labelLarge?.copyWith(
                                    color: const Color(0xFF808080),
                                    fontSize: 10,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${(p.estimateMinutes / 60).toStringAsFixed(1)}時間',
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    color: const Color(0xFF00D9FF),
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
                                    color: const Color(0xFF808080),
                                    fontSize: 10,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${p.deadlineAt.hour.toString().padLeft(2, '0')}:${p.deadlineAt.minute.toString().padLeft(2, '0')}',
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    color: const Color(0xFF00D9FF),
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
                
                // Extension Options
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1A1A1A).withOpacity(0.5),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: const Color(0xFF4A4A4A).withOpacity(0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        size: 16,
                        color: const Color(0xFF808080),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '延長オプション: ',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: const Color(0xFF808080),
                          ),
                        ),
                      ),
                      DropdownButton<int>(
                        value: _extendMinutes,
                        onChanged: _loading ? null : (v) => setState(() => _extendMinutes = v ?? 180),
                        dropdownColor: const Color(0xFF1A1A1A),
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: const Color(0xFF00D9FF),
                        ),
                        underline: Container(),
                        items: const [180, 240, 360, 480, 720]
                            .map((m) => DropdownMenuItem(
                                  value: m,
                                  child: Text('+${(m / 60).toStringAsFixed(1)}時間'),
                                ))
                            .toList(),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 24),
                
                // Action Buttons
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _loading ? null : () => _accept(andExtend: false),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        child: _loading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Text('承認'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _loading ? null : () => _accept(andExtend: true),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        child: _loading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.black),
                                ),
                              )
                            : const Text('延長して承認'),
                      ),
                    ),
                  ],
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
                    child: Row(
                      children: [
                        Icon(
                          Icons.error_outline,
                          size: 16,
                          color: const Color(0xFFFF3D3D),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _error!,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: const Color(0xFFFF3D3D),
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
