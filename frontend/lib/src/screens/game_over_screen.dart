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
        decoration: BoxDecoration(
          gradient: RadialGradient(
            center: Alignment.center,
            radius: 1.0,
            colors: [
              const Color(0xFFFF3D3D).withOpacity(0.2),
              const Color(0xFF0A0A0A),
              Colors.black,
            ],
          ),
        ),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Pulsing error icon
                TweenAnimationBuilder<double>(
                  duration: const Duration(milliseconds: 1500),
                  tween: Tween(begin: 0.8, end: 1.2),
                  curve: Curves.easeInOut,
                  builder: (context, scale, child) {
                    return Transform.scale(
                      scale: scale,
                      child: Icon(
                        Icons.warning_amber_rounded,
                        size: 120,
                        color: const Color(0xFFFF3D3D).withOpacity(0.9),
                      ),
                    );
                  },
                  onEnd: () {
                    // Restart animation - handled by Flutter's rebuild
                  },
                ),
                
                const SizedBox(height: 40),
                
                // Game Over Title
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: const Color(0xFFFF3D3D),
                      width: 2,
                    ),
                    borderRadius: BorderRadius.circular(4),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFFF3D3D).withOpacity(0.3),
                        blurRadius: 20,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: Text(
                    'GAME OVER',
                    style: theme.textTheme.displayLarge?.copyWith(
                      fontSize: 40,
                      fontWeight: FontWeight.w100,
                      letterSpacing: 8,
                      color: const Color(0xFFFF3D3D),
                    ),
                  ),
                ),
                
                const SizedBox(height: 40),
                
                // Error divider
                Container(
                  height: 1,
                  width: 200,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.transparent,
                        const Color(0xFFFF3D3D),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
                
                const SizedBox(height: 40),
                
                // AI Message
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0A0A0A).withOpacity(0.8),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: const Color(0xFFFF3D3D).withOpacity(0.3),
                    ),
                  ),
                  child: Column(
                    children: [
                      Text(
                        'SYSTEM ERROR',
                        style: theme.textTheme.labelLarge?.copyWith(
                          color: const Color(0xFFFF3D3D),
                          fontSize: 11,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'データは消去された。\n再契約を試みるがいい。',
                        style: theme.textTheme.bodyLarge?.copyWith(
                          height: 1.8,
                          letterSpacing: 1,
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
                  child: ElevatedButton(
                    onPressed: () => _ack(context, ref),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFF3D3D),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      side: const BorderSide(
                        color: Color(0xFFFF3D3D),
                        width: 2,
                      ),
                    ),
                    child: const Text(
                      'RE-CONTRACT',
                      style: TextStyle(
                        letterSpacing: 3,
                        fontWeight: FontWeight.w600,
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
