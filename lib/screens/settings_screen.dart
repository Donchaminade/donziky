import 'package:donziker/models/song_sort.dart';
import 'package:donziker/providers/music_provider.dart';
import 'package:donziker/providers/theme_provider.dart';
import 'package:donziker/screens/stats_screen.dart';
import 'package:donziker/theme/app_theme.dart';
import 'package:donziker/theme/theme_extensions.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  /// Couleurs d'accent de master (`d29b30a` / `f98142f`), après les 6
  /// `Colors.*Accent` de `dbf13fb`.
  static const _accentPresets = <(String, Color)>[
    ('Rose', Color(0xFFFF375F)),
    ('Bleu', Color(0xFF0A84FF)),
    ('Vert', Color(0xFF30D158)),
    ('Violet', Color(0xFFBF5AF2)),
    ('Orange', Color(0xFFFF9F0A)),
    ('Rose clair', Color(0xFFFF6482)),
    ('Cyan', Color(0xFF64D2FF)),
    ('Rouge', Color(0xFFFF453A)),
  ];

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final musicProvider = context.watch<MusicProvider>();
    final c = context.dz;
    final isDark = themeProvider.themeMode == ThemeMode.dark;

    return Scaffold(
      backgroundColor: c.surface,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 120,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                'Réglages',
                style: TextStyle(fontWeight: FontWeight.w800, color: c.primaryText),
              ),
              background: Container(decoration: BoxDecoration(gradient: c.heroGradient)),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _Group(
                    title: 'Apparence',
                    child: Column(
                      children: [
                        _SettingTile(
                          title: 'Ton prénom',
                          subtitle: themeProvider.displayName,
                          trailing: Icon(Icons.edit_rounded, color: c.secondaryText),
                          onTap: () => _editName(context, themeProvider),
                        ),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              'Thèmes',
                              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: c.secondaryText),
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(12, 4, 12, 8),
                          child: _ThemeGrid(
                            theme: themeProvider,
                            music: musicProvider,
                            isDark: isDark,
                          ),
                        ),
                        _SettingTile(
                          title: 'Mode sombre',
                          subtitle: 'Pour les thèmes classiques',
                          trailing: Switch.adaptive(
                            value: isDark,
                            activeThumbColor: AppTheme.ink,
                            activeTrackColor: AppTheme.lime,
                            onChanged: themeProvider.toggleTheme,
                          ),
                        ),
                        _SettingTile(
                          title: 'Lecteur circulaire',
                          subtitle: 'Pochette ronde et arc de progression',
                          trailing: Switch.adaptive(
                            value: themeProvider.circularPlayer,
                            activeThumbColor: AppTheme.ink,
                            activeTrackColor: AppTheme.lime,
                            onChanged: themeProvider.setCircularPlayer,
                          ),
                        ),
                        _SettingTile(
                          title: 'Réduire les animations',
                          trailing: Switch.adaptive(
                            value: themeProvider.disableAnimations,
                            activeThumbColor: AppTheme.ink,
                            activeTrackColor: AppTheme.lime,
                            onChanged: themeProvider.setDisableAnimations,
                          ),
                        ),
                      ],
                    ),
                  ),
                  _Group(
                    title: 'Bibliothèque',
                    child: Column(
                      children: [
                        _SettingTile(
                          title: 'Rescanner le téléphone',
                          trailing: Icon(Icons.refresh_rounded, color: c.accent),
                          onTap: musicProvider.refreshLibrary,
                        ),
                        _SettingTile(
                          title: 'Tri par défaut',
                          trailing: DropdownButton<SongSort>(
                            value: musicProvider.songSort,
                            underline: const SizedBox.shrink(),
                            items: SongSort.values
                                .map((s) => DropdownMenuItem(value: s, child: Text(s.label)))
                                .toList(),
                            onChanged: (v) {
                              if (v != null) musicProvider.setSongSort(v);
                            },
                          ),
                        ),
                        _SettingTile(
                          title: 'Ordre du tri',
                          trailing: DropdownButton<SortOrder>(
                            value: musicProvider.sortOrder,
                            underline: const SizedBox.shrink(),
                            items: SortOrder.values
                                .map((o) => DropdownMenuItem(value: o, child: Text(o.label)))
                                .toList(),
                            onChanged: (v) {
                              if (v != null) musicProvider.setSortOrder(v);
                            },
                          ),
                        ),
                        _SettingTile(
                          title: 'Masquer les sons courts',
                          trailing: Switch.adaptive(
                            value: musicProvider.hideShortSounds,
                            activeThumbColor: AppTheme.ink,
                            activeTrackColor: AppTheme.lime,
                            onChanged: musicProvider.setHideShortSounds,
                          ),
                        ),
                      ],
                    ),
                  ),
                  _Group(
                    title: 'Lecture',
                    child: Column(
                      children: [
                        _SettingTile(
                          title: 'Mode karaoké',
                          subtitle: 'Morceau suivant avant la fin',
                          trailing: Switch.adaptive(
                            value: musicProvider.karaokeMode,
                            activeThumbColor: AppTheme.ink,
                            activeTrackColor: AppTheme.lime,
                            onChanged: (_) => musicProvider.toggleKaraokeMode(),
                          ),
                        ),
                        _SettingTile(
                          title: 'Anticipation karaoké',
                          trailing: DropdownButton<int>(
                            value: musicProvider.karaokeLeadSeconds,
                            underline: const SizedBox.shrink(),
                            items: [5, 8, 10, 12, 15]
                                .map((s) => DropdownMenuItem(value: s, child: Text('$s s')))
                                .toList(),
                            onChanged: (v) {
                              if (v != null) musicProvider.setKaraokeLeadSeconds(v);
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                  _Group(
                    title: 'Activité',
                    child: _SettingTile(
                      title: 'Statistiques',
                      subtitle: 'Temps d\'écoute, lectures, favoris',
                      trailing: Icon(Icons.bar_chart_rounded, color: c.accent),
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const StatsScreen())),
                    ),
                  ),
                  _Group(
                    title: 'À propos',
                    child: Column(
                      children: [
                        _SettingTile(title: 'Version', trailing: Text('1.3.0', style: TextStyle(color: c.secondaryText))),
                        _SettingTile(title: 'Développeur', trailing: Text('DonChaminade', style: TextStyle(color: c.secondaryText))),
                        Padding(
                          padding: const EdgeInsets.all(12),
                          child: Text(
                            'DonZiker lit uniquement les fichiers sur votre appareil.',
                            style: TextStyle(fontSize: 13, color: c.secondaryText, height: 1.4),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 100),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _editName(BuildContext context, ThemeProvider theme) async {
    final controller = TextEditingController(text: theme.displayName);
    final name = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Comment on t\'appelle ?'),
        content: TextField(controller: controller, autofocus: true, textCapitalization: TextCapitalization.words),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Annuler')),
          FilledButton(onPressed: () => Navigator.pop(ctx, controller.text.trim()), child: const Text('Enregistrer')),
        ],
      ),
    );
    if (name != null && name.isNotEmpty) {
      await theme.setDisplayName(name);
    }
  }
}

class _ThemeGrid extends StatelessWidget {
  final ThemeProvider theme;
  final MusicProvider music;
  final bool isDark;

  const _ThemeGrid({required this.theme, required this.music, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final c = context.dz;
    final options = <_ThemeChip>[
      _ThemeChip(
        label: 'Tega clair',
        colors: const [AppTheme.lime, AppTheme.canvas],
        selected: theme.isTega && !isDark,
        onTap: () {
          theme.selectTega(dark: false);
          music.setUseDynamicAccent(false);
        },
      ),
      _ThemeChip(
        label: 'Tega sombre',
        colors: const [AppTheme.lime, AppTheme.darkBg],
        selected: theme.isTega && isDark,
        onTap: () {
          theme.selectTega(dark: true);
          music.setUseDynamicAccent(false);
        },
      ),
      _ThemeChip(
        label: 'Classique dynamique',
        colors: const [Color(0xFF8EC8F5), Color(0xFFFF375F)],
        selected: !theme.isTega && music.useDynamicAccent,
        onTap: () {
          theme.setVisualStyle(AppVisualStyle.classic);
          music.setUseDynamicAccent(true);
        },
      ),
      for (final preset in SettingsScreen._accentPresets)
        _ThemeChip(
          label: preset.$1,
          colors: [preset.$2, preset.$2],
          selected: !theme.isTega && !music.useDynamicAccent && theme.accentColor.toARGB32() == preset.$2.toARGB32(),
          onTap: () {
            theme.selectClassicAccent(preset.$2);
            music.setUseDynamicAccent(false);
          },
        ),
    ];

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final option in options)
          SizedBox(
            width: 108,
            child: Material(
              color: option.selected ? AppTheme.lime : (c.isDark ? AppTheme.darkCard : Colors.white),
              borderRadius: BorderRadius.circular(16),
              child: InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: option.onTap,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(10, 10, 10, 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          for (final color in option.colors.take(2))
                            Container(
                              width: 16,
                              height: 16,
                              margin: const EdgeInsets.only(right: 4),
                              decoration: BoxDecoration(
                                color: color,
                                shape: BoxShape.circle,
                                border: Border.all(color: option.selected ? AppTheme.ink : c.primaryText.withValues(alpha: 0.2)),
                              ),
                            ),
                          if (option.selected) const Spacer(),
                          if (option.selected) const Icon(Icons.check_rounded, size: 16, color: AppTheme.ink),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        option.label,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12,
                          height: 1.15,
                          fontWeight: FontWeight.w700,
                          color: option.selected ? AppTheme.ink : c.primaryText,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _ThemeChip {
  final String label;
  final List<Color> colors;
  final bool selected;
  final VoidCallback onTap;

  const _ThemeChip({
    required this.label,
    required this.colors,
    required this.selected,
    required this.onTap,
  });
}

class _Group extends StatelessWidget {
  final String title;
  final Widget child;

  const _Group({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    final c = context.dz;
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 6, bottom: 8),
            child: Text(
              title.toUpperCase(),
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.8,
                color: c.secondaryText,
              ),
            ),
          ),
          Material(
            color: c.card,
            borderRadius: BorderRadius.circular(AppTheme.radiusMd),
            clipBehavior: Clip.antiAlias,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
              child: child,
            ),
          ),
        ],
      ),
    );
  }
}

class _SettingTile extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;

  const _SettingTile({
    required this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.dz;
    return ListTile(
      onTap: onTap,
      title: Text(title, style: TextStyle(fontWeight: FontWeight.w600, color: c.primaryText)),
      subtitle: subtitle != null ? Text(subtitle!, style: TextStyle(color: c.secondaryText, fontSize: 12)) : null,
      trailing: trailing,
    );
  }
}
