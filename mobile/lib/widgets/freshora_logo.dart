import 'package:flutter/material.dart';

/// Shared FRESHORA grocery mark used across splash, landing, auth and home screens.
class FreshoraLogo extends StatelessWidget {
  const FreshoraLogo({super.key, this.size = 48});

  final double size;

  @override
  Widget build(BuildContext context) => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(size * .28),
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF1FA463), Color(0xFF075B36)],
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF075B36).withValues(alpha: .28),
              blurRadius: size * .22,
              offset: Offset(0, size * .08),
            ),
          ],
        ),
        child: CustomPaint(
          painter: _FreshoraMarkPainter(),
          child: const SizedBox.expand(),
        ),
      );
}

class _FreshoraMarkPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final s = size.shortestSide;
    final center = Offset(size.width / 2, size.height / 2);

    final leaf = Paint()..color = const Color(0xFFB9F27C);
    final leafPath = Path()
      ..moveTo(center.dx - s * .03, s * .43)
      ..cubicTo(
        center.dx - s * .02,
        s * .18,
        center.dx + s * .20,
        s * .10,
        center.dx + s * .34,
        s * .15,
      )
      ..cubicTo(
        center.dx + s * .28,
        s * .36,
        center.dx + s * .12,
        s * .46,
        center.dx - s * .03,
        s * .43,
      )
      ..close();
    canvas.drawPath(leafPath, leaf);

    final stem = Paint()
      ..color = Colors.white.withValues(alpha: .82)
      ..strokeWidth = s * .035
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(
      Offset(center.dx - s * .04, s * .43),
      Offset(center.dx + s * .22, s * .20),
      stem,
    );

    final fruitPaint = Paint();
    fruitPaint.color = const Color(0xFFFFC857);
    canvas.drawCircle(Offset(center.dx - s * .28, s * .55), s * .105, fruitPaint);
    fruitPaint.color = const Color(0xFFFF7043);
    canvas.drawCircle(Offset(center.dx, s * .53), s * .12, fruitPaint);
    fruitPaint.color = const Color(0xFFE84A5F);
    canvas.drawCircle(Offset(center.dx + s * .27, s * .55), s * .105, fruitPaint);

    final basket = Paint()..color = const Color(0xFF8ED081);
    final basketPath = Path()
      ..moveTo(s * .18, s * .61)
      ..lineTo(s * .82, s * .61)
      ..lineTo(s * .73, s * .86)
      ..lineTo(s * .27, s * .86)
      ..close();
    canvas.drawPath(basketPath, basket);

    final rim = Paint()
      ..color = const Color(0xFFE8FFD6)
      ..strokeWidth = s * .055
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(Offset(s * .17, s * .61), Offset(s * .83, s * .61), rim);

    final slat = Paint()
      ..color = const Color(0xFF2C8C55)
      ..strokeWidth = s * .028
      ..style = PaintingStyle.stroke;
    for (final fraction in [.38, .50, .62]) {
      canvas.drawLine(
        Offset(s * fraction, s * .67),
        Offset(s * (fraction - .025), s * .82),
        slat,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
