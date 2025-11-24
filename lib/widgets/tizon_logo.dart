import 'package:flutter/material.dart';
import 'dart:math';

class TizonLogo extends StatelessWidget {
  final double size;
  final bool showText;
  final Color? color;

  const TizonLogo({
    super.key,
    this.size = 100,
    this.showText = true,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final logoColor = color ?? Colors.green;
    return CustomPaint(
      size: Size(size, size),
      painter: HexagonPainter(color: logoColor),
    );
  }
}

class HexagonPainter extends CustomPainter {
  final Color color;
  HexagonPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width * 0.4;
    final path = Path();
    
    for (int i = 0; i < 6; i++) {
      final angle = (pi / 3) * i - pi / 2;
      final x = center.dx + radius * cos(angle);
      final y = center.dy + radius * sin(angle);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}