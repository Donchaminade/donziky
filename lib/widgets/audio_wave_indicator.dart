import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Barres animées type onde / radio pour le morceau en cours de lecture.
class AudioWaveIndicator extends StatefulWidget {
  final Color color;
  final double width;
  final double height;
  final bool animate;

  const AudioWaveIndicator({
    super.key,
    required this.color,
    this.width = 28,
    this.height = 22,
    this.animate = true,
  });

  @override
  State<AudioWaveIndicator> createState() => _AudioWaveIndicatorState();
}

class _AudioWaveIndicatorState extends State<AudioWaveIndicator> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 900));
    if (widget.animate) _controller.repeat();
  }

  @override
  void didUpdateWidget(AudioWaveIndicator oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.animate && !_controller.isAnimating) {
      _controller.repeat();
    } else if (!widget.animate) {
      _controller.stop();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.width,
      height: widget.height,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          return Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: List.generate(4, (i) {
              final phase = _controller.value * 2 * math.pi + i * 0.9;
              final h = widget.animate
                  ? widget.height * (0.35 + 0.65 * ((math.sin(phase) + 1) / 2))
                  : widget.height * 0.5;
              return Container(
                width: 4,
                height: h,
                decoration: BoxDecoration(
                  color: widget.color,
                  borderRadius: BorderRadius.circular(3),
                ),
              );
            }),
          );
        },
      ),
    );
  }
}
