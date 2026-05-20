import 'dart:ui';

import 'package:donziker/theme/app_theme.dart';
import 'package:donziker/theme/theme_extensions.dart';
import 'package:flutter/material.dart';

class FloatingBottomNav extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onSelected;

  const FloatingBottomNav({
    super.key,
    required this.selectedIndex,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.dz;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppTheme.radiusXl),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 28, sigmaY: 28),
          child: Container(
            decoration: BoxDecoration(
              color: c.card.withValues(alpha: 0.92),
              borderRadius: BorderRadius.circular(AppTheme.radiusXl),
              border: Border.all(color: c.glassBorder, width: 0.6),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: c.isDark ? 0.45 : 0.12),
                  blurRadius: 24,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: NavigationBar(
              height: 64,
              elevation: 0,
              backgroundColor: Colors.transparent,
              indicatorColor: c.accent.withValues(alpha: 0.22),
              surfaceTintColor: Colors.transparent,
              selectedIndex: selectedIndex,
              onDestinationSelected: onSelected,
              labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
              destinations: const [
                NavigationDestination(
                  icon: Icon(Icons.home_outlined),
                  selectedIcon: Icon(Icons.home_rounded),
                  label: 'Accueil',
                ),
                NavigationDestination(
                  icon: Icon(Icons.library_music_outlined),
                  selectedIcon: Icon(Icons.library_music_rounded),
                  label: 'Bibliothèque',
                ),
                NavigationDestination(
                  icon: Icon(Icons.favorite_outline_rounded),
                  selectedIcon: Icon(Icons.favorite_rounded),
                  label: 'Favoris',
                ),
                NavigationDestination(
                  icon: Icon(Icons.settings_outlined),
                  selectedIcon: Icon(Icons.settings_rounded),
                  label: 'Réglages',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
