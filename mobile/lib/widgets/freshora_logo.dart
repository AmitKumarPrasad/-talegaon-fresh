import 'package:flutter/material.dart';

/// Shared FRESHORA brand mark used across splash, landing, auth and home screens.
class FreshoraLogo extends StatelessWidget {
  const FreshoraLogo({super.key, this.size = 48, this.iconSize});

  final double size;
  final double? iconSize;

  @override
  Widget build(BuildContext context) => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF168B45), Color(0xFF0B5B2C)],
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF0B5B2C).withValues(alpha: .35),
              blurRadius: size * 0.25,
              offset: Offset(0, size * 0.08),
            ),
          ],
        ),
        child: Icon(
          Icons.eco_rounded,
          color: Colors.white,
          size: iconSize ?? size * 0.58,
        ),
      );
}
