import 'dart:math';
import 'package:flutter/material.dart';

class Fish {
  Color color;
  double speed;
  Offset position;
  double dx;
  double dy;
  double size;
  bool scaling;

  Fish({required this.color, required this.speed})
      : dx = (Random().nextDouble() - 0.5) * speed,
        dy = (Random().nextDouble() - 0.5) * speed,
        position = const Offset(150, 150),
        size = 1.0,
        scaling = true;

  Widget buildFish() {
    return Positioned(
      left: position.dx,
      top: position.dy,
      child: CustomPaint(
        size: Size(50 * size, 30 * size),
        painter: FishPainter(color: color),
      ),
    );
  }

  void moveFish() {
    position = Offset(position.dx + dx, position.dy + dy);
    if (position.dx <= 0 || position.dx >= 280) dx = -dx;
    if (position.dy <= 0 || position.dy >= 280) dy = -dy;
  }
}

class FishPainter extends CustomPainter {
  final Color color;

  FishPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    // Draw fish body (oval shape)
    canvas.drawOval(
      Rect.fromLTWH(0, size.height / 4, size.width * 0.7, size.height * 0.5),
      paint,
    );

    // Draw tail (triangle shape)
    var tailPath = Path();
    tailPath.moveTo(size.width * 0.7, size.height / 2);
    tailPath.lineTo(size.width * 0.9, size.height * 0.3);
    tailPath.lineTo(size.width * 0.9, size.height * 0.7);
    tailPath.close();
    canvas.drawPath(tailPath, paint);

    // Draw eye (small circle)
    final eyePaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(size.width * 0.2, size.height * 0.4), 2, eyePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return false;
  }
}
