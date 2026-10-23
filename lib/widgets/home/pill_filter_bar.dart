import 'package:donziker/theme/app_theme.dart';
import 'package:donziker/theme/theme_extensions.dart';
import 'package:donziker/widgets/motion/pressable_scale.dart';
import 'package:flutter/material.dart';

class PillFilterBar extends StatelessWidget {
  final List<String> labels;
  final int selected;
  final ValueChanged<int> onSelected;

  const PillFilterBar({
    super.key,
    required this.labels,
    required this.selected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.dz;
    return SizedBox(
      height: 44,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: labels.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, i) {
          final on = i == selected;
          return PressableScale(
            onTap: () => onSelected(i),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOut,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: on ? AppTheme.lime : (c.isDark ? AppTheme.darkCard : Colors.white),
                borderRadius: BorderRadius.circular(24),
                boxShadow: on
                    ? null
                    : [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: c.isDark ? 0.2 : 0.04),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
              ),
              child: Text(
                labels[i],
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                  color: on ? AppTheme.ink : c.secondaryText,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
