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
    if (showText) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          CustomPaint(
            size: Size(size, size),
            painter: _TizonHexPainter(),
          ),
          SizedBox(width: size * 0.18),
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Tizón',
                style: TextStyle(
                  fontSize: size * 0.38,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF1B5E20),
                  height: 1.1,
                ),
              ),
              Text(
                'SAS',
                style: TextStyle(
                  fontSize: size * 0.18,
                  fontWeight: FontWeight.w400,
                  color: Colors.grey.shade500,
                  letterSpacing: 1.5,
                ),
              ),
            ],
          ),
        ],
      );
    }

    return CustomPaint(
      size: Size(size, size),
      painter: _TizonHexPainter(),
    );
  }
}

class _TizonHexPainter extends CustomPainter {
  // Calcula los 6 vértices de un hexágono centrado
  List<Offset> _hexVertices(Offset center, double radius) {
    return List.generate(6, (i) {
      final angle = (pi / 3) * i - pi / 2;
      return Offset(
        center.dx + radius * cos(angle),
        center.dy + radius * sin(angle),
      );
    });
  }

  Path _hexPath(Offset center, double radius) {
    final pts = _hexVertices(center, radius);
    final path = Path()..moveTo(pts[0].dx, pts[0].dy);
    for (int i = 1; i < 6; i++) path.lineTo(pts[i].dx, pts[i].dy);
    return path..close();
  }

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final r = size.width * 0.46;

    // Sombra sutil
    final shadowPaint = Paint()
      ..color = const Color(0xFF0a2e12).withOpacity(0.18)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
    canvas.drawPath(
      _hexPath(center.translate(0, size.width * 0.04), r),
      shadowPaint,
    );

    // Capa 1 — exterior oscuro
    canvas.drawPath(
      _hexPath(center, r),
      Paint()..color = const Color(0xFF1B5E20),
    );

    // Capa 2 — media
    canvas.drawPath(
      _hexPath(center, r * 0.76),
      Paint()..color = const Color(0xFF2E7D32),
    );

    // Capa 3 — interior más claro
    canvas.drawPath(
      _hexPath(center, r * 0.56),
      Paint()..color = const Color(0xFF388E3C),
    );

    // Borde exterior fino verde claro
    canvas.drawPath(
      _hexPath(center, r),
      Paint()
        ..color = const Color(0xFF66BB6A).withOpacity(0.6)
        ..style = PaintingStyle.stroke
        ..strokeWidth = size.width * 0.025,
    );

    // Puntos en los 6 vértices
    final dotPaint = Paint()..color = const Color(0xFF66BB6A);
    final dotRadius = size.width * 0.055;
    for (final pt in _hexVertices(center, r)) {
      canvas.drawCircle(pt, dotRadius, dotPaint);
    }

    // Letra T centrada
    final textPainter = TextPainter(
      text: TextSpan(
        text: 'T',
        style: TextStyle(
          fontSize: size.width * 0.42,
          fontWeight: FontWeight.bold,
          color: Colors.white.withOpacity(0.95),
          height: 1,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset(
        center.dx - textPainter.width / 2,
        center.dy - textPainter.height / 2,
      ),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
