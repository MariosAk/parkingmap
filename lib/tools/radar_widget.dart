import 'package:flutter/material.dart';

class RotatingRadarWidget extends StatefulWidget {
  final double size; // Diameter of the radar
  final Color color; // Color of the radar sweep

  const RotatingRadarWidget({
    Key? key,
    this.size = 300,
    this.color = Colors.blue,
  }) : super(key: key);

  @override
  _RotatingRadarWidgetState createState() => _RotatingRadarWidgetState();
}

class _RotatingRadarWidgetState extends State<RotatingRadarWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _RadarPainter(
        animation: _controller,
        color: widget.color,
      ),
      child: SizedBox(
        width: widget.size,
        height: widget.size,
      ),
    );
  }
}

class _RadarPainter extends CustomPainter {
  final Animation<double> animation;
  final Color color;

  _RadarPainter({required this.animation, required this.color})
      : super(repaint: animation);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2.5;

    // Paint for concentric circles
    final circlePaint = Paint()
      ..color = color.withOpacity(0.7)
      ..style = PaintingStyle.fill;

    // Draw concentric circles
    for (int i = 3; i <= 3; i++) {
      canvas.drawCircle(center, (radius / 3) * i, circlePaint);
    }

    // Paint for rotating sweep
    final sweepPaint = Paint()
      ..color = Colors.white.withOpacity(0.7)
      ..style = PaintingStyle.fill;

    final sweepAngle = 2 * 3.141592653589793 * animation.value;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      sweepAngle,
      1.2, // Width of the sweep
      true,
      sweepPaint,
    );

    // Add pulsating effect
    final pulseRadius = radius * animation.value;
    final pulsePaint = Paint()
      ..color = Colors.white.withOpacity(1 - animation.value) // Fade out
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    canvas.drawCircle(center, pulseRadius, pulsePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
