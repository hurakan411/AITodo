import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

class TutorialScreen extends StatefulWidget {
  const TutorialScreen({super.key});

  @override
  State<TutorialScreen> createState() => _TutorialScreenState();
}

class _TutorialScreenState extends State<TutorialScreen> {
  final PageController _controller = PageController();
  int _currentPage = 0;

  final List<Map<String, String>> _pages = [
    {
      'title': '1. タスク申請',
      'description': '「NEW TASK」ボタンから\nやるべきことを宣言してください。\n具体的であるほど、AIは正確に理解します。',
      'icon': 'handshake',
    },
    {
      'title': '2. 期限見積もり',
      'description': 'タスク管理AI"Obeyne"がタスクを分析し、\n期限を設定します。\n何も考えずに承認しましょう。',
      'icon': 'add_task',
    },
    {
      'title': '3. 完了報告',
      'description': 'タスクを完了したら、報告してください。ポイントが付与されます。',
      'icon': 'psychology',
    },
    {
      'title': '4. ランクアップ',
      'description': 'ポイントを貯めてランクを上げましょう。\nランクが上がるとObeyneのモードが変化し、\nあなたへの態度が変化していきます。',
      'icon': 'timer',
    },
  ];

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _finishTutorial() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('has_seen_tutorial', true);
    if (mounted) {
      context.go('/home');
    }
  }

  IconData _getIcon(String name) {
    switch (name) {
      case 'handshake': return Icons.handshake_outlined;
      case 'add_task': return Icons.add_task_outlined;
      case 'psychology': return Icons.psychology_outlined;
      case 'timer': return Icons.timer_outlined;
      case 'military_tech': return Icons.military_tech_outlined;
      default: return Icons.info_outline;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFFE8EAF0),
              Color(0xFFF0F2F8),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: PageView.builder(
                  controller: _controller,
                  onPageChanged: (index) {
                    setState(() {
                      _currentPage = index;
                    });
                  },
                  itemCount: _pages.length,
                  itemBuilder: (context, index) {
                    final page = _pages[index];
                    return Padding(
                      padding: const EdgeInsets.all(32.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 200,
                            height: 200,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: const LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  Color(0xFFE0E2EC),
                                  Color(0xFFF0F2F8),
                                ],
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.white.withOpacity(0.8),
                                  offset: const Offset(-8, -8),
                                  blurRadius: 16,
                                ),
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.1),
                                  offset: const Offset(8, 8),
                                  blurRadius: 16,
                                ),
                              ],
                            ),
                          child: Icon(
                            _getIcon(page['icon']!),
                            size: 80,
                            color: const Color(0xFF8E92AB),
                          ),
                        ),
                        const SizedBox(height: 48),
                        Text(
                          page['title']!,
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF2D3142),
                            letterSpacing: 1.2,
                          ),
                        ),
                        const SizedBox(height: 24),
                        Text(
                          page['description']!,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 16,
                            height: 1.6,
                            color: Color(0xFF4A4E6D),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(32.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Indicators
                  Row(
                    children: List.generate(
                      _pages.length,
                      (index) => AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        margin: const EdgeInsets.only(right: 8),
                        width: _currentPage == index ? 24 : 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: _currentPage == index
                              ? const Color(0xFF8E92AB)
                              : const Color(0xFFD0D3E0),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                  ),
                  // Button
                  ElevatedButton(
                    onPressed: () {
                      if (_currentPage < _pages.length - 1) {
                        _controller.nextPage(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                        );
                      } else {
                        _finishTutorial();
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF8E92AB),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 32,
                        vertical: 16,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                      elevation: 4,
                    ),
                    child: Text(
                      _currentPage < _pages.length - 1 ? '次へ' : '始める',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            ],
          ),
        ),
      ),
    );
  }
}
