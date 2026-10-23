import 'package:donziker/providers/music_provider.dart';
import 'package:donziker/providers/theme_provider.dart';
import 'package:donziker/theme/app_theme.dart';
import 'package:donziker/theme/theme_extensions.dart';
import 'package:donziker/widgets/motion/pressable_scale.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class HomeHeader extends StatelessWidget {
  final bool searchOpen;
  final VoidCallback onSearch;
  final VoidCallback onFavorites;
  final ValueChanged<String> onQuery;

  const HomeHeader({
    super.key,
    required this.searchOpen,
    required this.onSearch,
    required this.onFavorites,
    required this.onQuery,
  });

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<ThemeProvider>();
    final music = context.watch<MusicProvider>();
    final c = context.dz;
    final name = theme.displayName;
    final initial = name.isNotEmpty ? name[0].toUpperCase() : 'T';

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 46,
                height: 46,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppTheme.ink,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: c.isDark ? Colors.white24 : Colors.transparent,
                  ),
                ),
                child: Text(
                  initial,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 18,
                  ),
                ),
              ),
              const Spacer(),
              _RoundIconButton(icon: Icons.search_rounded, onTap: onSearch),
              const SizedBox(width: 10),
              _RoundIconButton(
                icon: music.favorites.isEmpty ? Icons.favorite_border_rounded : Icons.favorite_rounded,
                onTap: onFavorites,
              ),
            ],
          ),
          const SizedBox(height: 18),
          Text(
            'Salut, $name',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w600,
              letterSpacing: -0.8,
              color: c.primaryText,
              height: 1.1,
            ),
          ),
          if (searchOpen) ...[
            const SizedBox(height: 14),
            TextField(
              autofocus: true,
              onChanged: onQuery,
              style: TextStyle(color: c.primaryText),
              decoration: const InputDecoration(
                hintText: 'Rechercher titre, artiste, album…',
                prefixIcon: Icon(Icons.search_rounded),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _RoundIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _RoundIconButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final c = context.dz;
    return PressableScale(
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: c.isDark ? AppTheme.darkCard : Colors.white,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: c.isDark ? 0.28 : 0.06),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Icon(icon, size: 20, color: c.primaryText),
      ),
    );
  }
}
