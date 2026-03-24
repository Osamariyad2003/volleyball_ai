import 'package:flutter/material.dart';

class GlowIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onPressed;
  final Color? color;
  final double size;

  const GlowIconButton({
    super.key,
    required this.icon,
    required this.onPressed,
    this.color,
    this.size = 24,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accentColor = color ?? theme.colorScheme.primary;

    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: accentColor.withOpacity(0.2),
            blurRadius: 15,
            spreadRadius: 2,
          ),
        ],
      ),
      child: IconButton.filledTonal(
        icon: Icon(icon, size: size),
        onPressed: onPressed,
        style: IconButton.styleFrom(
          backgroundColor: accentColor.withOpacity(0.15),
          foregroundColor: accentColor,
        ),
      ),
    );
  }
}
