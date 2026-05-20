import 'dart:ui';

import 'package:donziker/theme/theme_extensions.dart';
import 'package:flutter/material.dart';

class GlassSurface extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final double radius;
  final double blur;

  const GlassSurface({
    super.key,
    required this.child,
    this.padding,
    this.radius = 20,
    this.blur = 18,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.dz;
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            color: c.glass,
            borderRadius: BorderRadius.circular(radius),
            border: Border.all(color: c.glassBorder, width: 0.5),
          ),
          child: child,
        ),
      ),
    );
  }
}
