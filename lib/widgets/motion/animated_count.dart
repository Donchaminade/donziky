import 'package:donziker/theme/motion.dart';
import 'package:flutter/material.dart';

/// Compteur 0 → valeur en 800 ms.
class AnimatedCount extends StatelessWidget {
  final double value;
  final TextStyle? style;
  final String Function(double value) format;

  const AnimatedCount({
    super.key,
    required this.value,
    required this.format,
    this.style,
  });

  @override
  Widget build(BuildContext context) {
    final reduce = MediaQuery.disableAnimationsOf(context);
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: value),
      duration: reduce ? Duration.zero : kCountDuration,
      curve: kEaseOutQuint,
      builder: (context, v, _) => Text(format(v), style: style),
    );
  }
}
