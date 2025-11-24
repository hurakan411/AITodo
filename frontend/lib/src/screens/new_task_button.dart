
import 'package:flutter/material.dart';

class NewTaskButton extends StatefulWidget {
  final VoidCallback onTap;
  final double size;
  final double fontSize;
  final double iconSize;

  const NewTaskButton({
    super.key,
    required this.onTap,
    this.size = 160,
    this.fontSize = 16,
    this.iconSize = 48,
  });

  @override
  State<NewTaskButton> createState() => _NewTaskButtonState();
}

class _NewTaskButtonState extends State<NewTaskButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) async {
        setState(() => _isPressed = false);
        // Add a small delay for visual feedback before action
        await Future.delayed(const Duration(milliseconds: 50));
        widget.onTap();
      },
      onTapCancel: () => setState(() => _isPressed = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 100),
        width: widget.size,
        height: widget.size,
        transform: Matrix4.translationValues(
          0,
          _isPressed ? 4 : 0,
          0,
        ),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: _isPressed
                ? [
                    const Color(0xFFD0D3E0),
                    const Color(0xFFE0E2EC),
                  ]
                : [
                    const Color(0xFFE0E2EC),
                    const Color(0xFFF0F2F8),
                  ],
          ),
          boxShadow: _isPressed
              ? [
                  BoxShadow(
                    color: Colors.white.withOpacity(0.3),
                    offset: const Offset(-2, -2),
                    blurRadius: 8,
                    spreadRadius: 0,
                  ),
                  BoxShadow(
                    color: Colors.black.withOpacity(0.15),
                    offset: const Offset(2, 2),
                    blurRadius: 8,
                    spreadRadius: 0,
                  ),
                ]
              : [
                  BoxShadow(
                    color: Colors.white.withOpacity(0.8),
                    offset: const Offset(-6, -6),
                    blurRadius: 16,
                    spreadRadius: 1,
                  ),
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    offset: const Offset(6, 6),
                    blurRadius: 16,
                    spreadRadius: 1,
                  ),
                ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.add_circle_outline,
              size: widget.iconSize,
              color: const Color(0xFF8E92AB),
            ),
            const SizedBox(height: 12),
            Text(
              'NEW\nTASK',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: const Color(0xFF8E92AB),
                fontSize: widget.fontSize,
                fontWeight: FontWeight.w600,
                letterSpacing: 1.5,
                height: 1.2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
