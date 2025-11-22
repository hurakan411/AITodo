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
    'あなたは、\n自身がタスクを後回しにする傾向を\n有していることを認めますか？',
    'あなたは、\nその傾向を修正するために、\n私"Obeyne"の統制が\n必要であることを認めますか？',
    'あなたは、\n以後のタスク遂行において、\n私の指示を絶対として従うことに\n同意しますか？',
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
    _initializeState();
  }
  
  void _initializeState() {
    _answers = List<bool?>.filled(_questions.length, null);
    _currentQuestion = 0;
    _isTransitioning = false;
    _showFinalMessage = false;
    
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
      _showFinalMessage = false;
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
                            _TypewriterText(
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
                            _TypewriterText(
                              '今後、あなたは\n私に従うことを誓約しました。\n\nすべてのタスクは、\n私の指示した期限までに\n実行されなければなりません。',
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
                            _TypewriterText(
                              _questions[_currentQuestion],
                              key: ValueKey(_currentQuestion), // 質問が変わるたびにリセット
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
                                  width: 130,
                                  child: OutlinedButton(
                                    onPressed: _isTransitioning ? null : () => _answerQuestion(true),
                                    style: OutlinedButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(vertical: 18),
                                      side: const BorderSide(color: Colors.white, width: 1.5),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      backgroundColor: Colors.white.withOpacity(0.05),
                                    ),
                                    child: const Text(
                                      'YES',
                                      style: TextStyle(
                                        color: Colors.white,
                                        letterSpacing: 4,
                                        fontSize: 15,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 32),
                                // NOボタン
                                SizedBox(
                                  width: 130,
                                  child: OutlinedButton(
                                    onPressed: _isTransitioning ? null : () => _answerQuestion(false),
                                    style: OutlinedButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(vertical: 18),
                                      side: BorderSide(color: Colors.white.withOpacity(0.5), width: 1.5),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      backgroundColor: Colors.transparent,
                                    ),
                                    child: Text(
                                      'NO',
                                      style: TextStyle(
                                        color: Colors.white.withOpacity(0.5),
                                        letterSpacing: 4,
                                        fontSize: 15,
                                        fontWeight: FontWeight.w500,
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

class _TypewriterText extends StatefulWidget {
  final String text;
  final TextStyle? style;
  final TextAlign? textAlign;
  final Duration duration;

  const _TypewriterText(
    this.text, {
    this.style,
    this.textAlign,
    this.duration = const Duration(milliseconds: 50),
    super.key,
  });

  @override
  State<_TypewriterText> createState() => _TypewriterTextState();
}

class _TypewriterTextState extends State<_TypewriterText>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<int> _characterCount;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration * widget.text.length,
    );
    _characterCount = StepTween(begin: 0, end: widget.text.length).animate(
      CurvedAnimation(parent: _controller, curve: Curves.linear),
    );
    _controller.forward();
  }

  @override
  void didUpdateWidget(_TypewriterText oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.text != widget.text) {
      _controller.duration = widget.duration * widget.text.length;
      _characterCount = StepTween(begin: 0, end: widget.text.length).animate(
        CurvedAnimation(parent: _controller, curve: Curves.linear),
      );
      _controller.reset();
      _controller.forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _characterCount,
      builder: (context, child) {
        final text = widget.text.substring(0, _characterCount.value);
        return Text(
          text,
          style: widget.style,
          textAlign: widget.textAlign,
        );
      },
    );
  }
}
