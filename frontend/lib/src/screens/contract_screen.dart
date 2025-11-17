import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../services/storage_service.dart';

class ContractScreen extends ConsumerStatefulWidget {
  const ContractScreen({super.key});

  @override
  ConsumerState<ContractScreen> createState() => _ContractScreenState();
}

class _ContractScreenState extends ConsumerState<ContractScreen> with TickerProviderStateMixin {
  final List<String> _questions = const [
    'あなたはAIの命令に従うことに同意しますか？',
    '期限を守れない場合は減点されることを理解しましたか？',
    '達成時には簡易レポートを提出しますか？',
  ];

  late List<bool?> _answers;
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  int _currentQuestion = 0;
  bool _isTransitioning = false;
  bool _showFinalMessage = false;

  @override
  void initState() {
    super.initState();
    _answers = List<bool?>.filled(_questions.length, null);
    
    // アニメーションコントローラーを作成
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    );
    
    // 最初の質問をフェードイン
    _fadeController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  void _reset() {
    setState(() {
      _answers = List<bool?>.filled(_questions.length, null);
      _currentQuestion = 0;
      _isTransitioning = false;
    });
    _fadeController.reset();
    _fadeController.forward();
  }

  Future<void> _answerQuestion(bool answer) async {
    if (_isTransitioning) return;
    
    setState(() {
      _answers[_currentQuestion] = answer;
      _isTransitioning = true;
    });
    
    if (answer == false) {
      // NOを選んだらフェードアウトしてリセット
      await _fadeController.reverse();
      await Future.delayed(const Duration(milliseconds: 300));
      _reset();
    } else if (_currentQuestion < _questions.length - 1) {
      // YESを選んで次の質問がある場合、フェードアウト→次へ
      await _fadeController.reverse();
      setState(() {
        _currentQuestion++;
        _isTransitioning = false;
      });
      await _fadeController.forward();
    } else {
      // 最後の質問にYES - 最終メッセージを表示
      await _fadeController.reverse();
      setState(() {
        _showFinalMessage = true;
      });
      await _fadeController.forward();
      
      // 4秒待機
      await Future.delayed(const Duration(seconds: 4));
      
      // フェードアウト
      await _fadeController.reverse();
      
      // 契約状態を保存してホーム画面へ
      final storage = ref.read(storageServiceProvider);
      await storage.setConsentAccepted(true);
      if (mounted) context.go('/home');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(40),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Spacer(),
                
                // 現在の質問または最終メッセージをフェードイン/アウト
                FadeTransition(
                  opacity: _fadeAnimation,
                  child: _showFinalMessage
                      ? Column(
                          children: [
                            Text(
                              '契約は成立した',
                              style: theme.textTheme.headlineMedium?.copyWith(
                                color: Colors.white,
                                height: 1.6,
                                fontWeight: FontWeight.w300,
                                fontSize: 24,
                                letterSpacing: 4,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 40),
                            Text(
                              'あなたはAIに従う',
                              style: theme.textTheme.bodyLarge?.copyWith(
                                color: Colors.white.withOpacity(0.7),
                                height: 1.6,
                                fontWeight: FontWeight.w300,
                                fontSize: 16,
                                letterSpacing: 2,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        )
                      : Column(
                          children: [
                            // 質問番号
                            Text(
                              '${_currentQuestion + 1} / ${_questions.length}',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: Colors.white.withOpacity(0.5),
                                letterSpacing: 2,
                                fontSize: 12,
                              ),
                            ),
                            const SizedBox(height: 40),
                            
                            // 質問テキスト
                            Text(
                              _questions[_currentQuestion],
                              style: theme.textTheme.headlineSmall?.copyWith(
                                color: Colors.white,
                                height: 1.6,
                                fontWeight: FontWeight.w300,
                                fontSize: 20,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            
                            const SizedBox(height: 60),
                            
                            // YES/NOボタン
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                // YESボタン
                                SizedBox(
                                  width: 120,
                                  child: OutlinedButton(
                                    onPressed: _isTransitioning ? null : () => _answerQuestion(true),
                                    style: OutlinedButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(vertical: 16),
                                      side: const BorderSide(color: Colors.white, width: 1),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(0),
                                      ),
                                    ),
                                    child: const Text(
                                      'YES',
                                      style: TextStyle(
                                        color: Colors.white,
                                        letterSpacing: 3,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 40),
                                // NOボタン
                                SizedBox(
                                  width: 120,
                                  child: OutlinedButton(
                                    onPressed: _isTransitioning ? null : () => _answerQuestion(false),
                                    style: OutlinedButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(vertical: 16),
                                      side: const BorderSide(color: Colors.white, width: 1),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(0),
                                      ),
                                    ),
                                    child: const Text(
                                      'NO',
                                      style: TextStyle(
                                        color: Colors.white,
                                        letterSpacing: 3,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                ),
                
                const Spacer(),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
