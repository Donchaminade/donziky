import 'package:donziker/theme/app_theme.dart';
import 'package:donziker/theme/motion.dart';
import 'package:donziker/theme/theme_extensions.dart';
import 'package:donziker/widgets/motion/pressable_scale.dart';
import 'package:flutter/material.dart';

class FloatingBottomNav extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onSelected;

  const FloatingBottomNav({
    super.key,
    required this.selectedIndex,
    required this.onSelected,
  });

  static const _items = [
    (Icons.home_outlined, Icons.home_rounded, 'Accueil'),
    (Icons.library_music_outlined, Icons.library_music_rounded, 'Bibliothèque'),
    (Icons.favorite_outline_rounded, Icons.favorite_rounded, 'Favoris'),
    (Icons.settings_outlined, Icons.settings_rounded, 'Réglages'),
  ];

  @override
  Widget build(BuildContext context) {
    final c = context.dz;
    final reduce = MediaQuery.disableAnimationsOf(context);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: Container(
        height: 68,
        decoration: BoxDecoration(
          color: c.isDark ? AppTheme.darkCard : Colors.white,
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: c.isDark ? 0.35 : 0.08),
              blurRadius: 24,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final slot = constraints.maxWidth / _items.length;
            return Stack(
              children: [
                AnimatedPositioned(
                  duration: reduce ? Duration.zero : const Duration(milliseconds: 320),
                  curve: kEaseOutQuint,
                  left: selectedIndex * slot + 8,
                  top: 8,
                  width: slot - 16,
                  height: 52,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: AppTheme.lime,
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                ),
                Row(
                  children: [
                    for (var i = 0; i < _items.length; i++)
                      Expanded(
                        child: PressableScale(
                          onTap: () => onSelected(i),
                          child: SizedBox(
                            height: 68,
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  i == selectedIndex ? _items[i].$2 : _items[i].$1,
                                  size: 22,
                                  color: i == selectedIndex ? AppTheme.ink : c.secondaryText,
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  _items[i].$3,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: i == selectedIndex ? FontWeight.w700 : FontWeight.w500,
                                    color: i == selectedIndex ? AppTheme.ink : c.secondaryText,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
