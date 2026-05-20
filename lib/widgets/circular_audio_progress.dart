import 'dart:math' as math;

import 'package:flutter/material.dart';

class CircularAudioProgress extends StatelessWidget {
  final double progress;
  final double size;
  final double strokeWidth;
  final Color activeColor;
  final Color inactiveColor;
  final Widget child;
  final ValueChanged<double>? onSeek;

  const CircularAudioProgress({
    super.key,
    required this.progress,
    required this.size,
    required this.activeColor,
    required this.inactiveColor,
    required this.child,
    this.strokeWidth = 5,
    this.onSeek,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: GestureDetector(
        onPanUpdate: onSeek == null
            ? null
            : (details) {
                final box = context.findRenderObject() as RenderBox?;
                if (box == null) return;
                final local = box.globalToLocal(details.globalPosition);
                final center = Offset(size / 2, size / 2);
                final angle = math.atan2(local.dy - center.dy, local.dx - center.dx);
                var value = (angle + math.pi / 2) / (2 * math.pi);
                if (value < 0) value += 1;
                onSeek!(value.clamp(0.0, 1.0));
              },
        onTapDown: onSeek == null
            ? null
            : (details) {
                final box = context.findRenderObject() as RenderBox?;
                if (box == null) return;
                final local = box.globalToLocal(details.globalPosition);
                final center = Offset(size / 2, size / 2);
                final angle = math.atan2(local.dy - center.dy, local.dx - center.dx);
                var value = (angle + math.pi / 2) / (2 * math.pi);
                if (value < 0) value += 1;
                onSeek!(value.clamp(0.0, 1.0));
              },
        child: Stack(
          alignment: Alignment.center,
          children: [
            CustomPaint(
              size: Size(size, size),
              painter: _RingPainter(
                progress: progress,
                strokeWidth: strokeWidth,
                activeColor: activeColor,
                inactiveColor: inactiveColor,
              ),
            ),
            child,
          ],
        ),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  final double progress;
  final double strokeWidth;
  final Color activeColor;
  final Color inactiveColor;

  _RingPainter({
    required this.progress,
    required this.strokeWidth,
    required this.activeColor,
    required this.inactiveColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;
    final bg = Paint()
      ..color = inactiveColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;
    final fg = Paint()
      ..color = activeColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, bg);
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      2 * math.pi * progress.clamp(0.0, 1.0),
      false,
      fg,
    );
  }

  @override
  bool shouldRepaint(covariant _RingPainter old) =>
      old.progress != progress || old.activeColor != activeColor;
}
