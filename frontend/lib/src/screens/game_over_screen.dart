import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/api_client.dart';
import 'package:go_router/go_router.dart';

class GameOverScreen extends ConsumerWidget {
  const GameOverScreen({super.key});

  Future<void> _ack(BuildContext context, WidgetRef ref) async {
    try {
      final api = ref.read(apiClientProvider);
      await api.gameoverAck();
      if (context.mounted) context.go('/contract');
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    
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
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Error icon with neumorphic effect
                Container(
                  padding: const EdgeInsets.all(30),
                  decoration: const BoxDecoration(
                    color: Color(0xFFE8EAF0),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.warning_amber_rounded,
                    size: 80,
                    color: const Color(0xFFE57373),
                  ),
                ),
                
                const SizedBox(height: 40),
                
                // Game Over Title
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 20),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8EAF0),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    'GAME OVER',
                    style: theme.textTheme.displayLarge?.copyWith(
                      fontSize: 36,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 6,
                      color: const Color(0xFFE57373),
                    ),
                  ),
                ),
                
                const SizedBox(height: 40),
                
                // Error divider
                Container(
                  height: 2,
                  width: 150,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.transparent,
                        const Color(0xFFE57373).withOpacity(0.4),
                        Colors.transparent,
                      ],
                    ),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                
                const SizedBox(height: 40),
                
                // AI Message
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8EAF0),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.08),
                        offset: const Offset(3, 3),
                        blurRadius: 8,
                      ),
                      BoxShadow(
                        color: Colors.white.withOpacity(0.5),
                        offset: const Offset(-3, -3),
                        blurRadius: 8,
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE57373).withOpacity(0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          'SYSTEM ERROR',
                          style: theme.textTheme.labelLarge?.copyWith(
                            color: const Color(0xFFE57373),
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 1,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'データは消去された。\n再契約を試みるがいい。',
                        style: theme.textTheme.bodyLarge?.copyWith(
                          height: 1.8,
                          letterSpacing: 0.5,
                          color: const Color(0xFF2D3142),
                          fontWeight: FontWeight.w500,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 60),
                
                // Re-contract button
                SizedBox(
                  width: double.infinity,
                  child: _NeumorphicButton(
                    onPressed: () => _ack(context, ref),
                    child: const Text(
                      '再契約',
                      style: TextStyle(
                        letterSpacing: 4,
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                      ),
                    ),
                  ),
                ),
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

  const _NeumorphicButton({
    required this.onPressed,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 20),
          decoration: BoxDecoration(
            color: const Color(0xFFE57373),
            borderRadius: BorderRadius.circular(14),
            boxShadow: onPressed == null
                ? []
                : [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.15),
                      offset: const Offset(4, 4),
                      blurRadius: 12,
                    ),
                    BoxShadow(
                      color: Colors.white.withOpacity(0.4),
                      offset: const Offset(-4, -4),
                      blurRadius: 12,
                    ),
                  ],
          ),
          child: DefaultTextStyle(
            style: const TextStyle(
              color: Colors.white,
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
