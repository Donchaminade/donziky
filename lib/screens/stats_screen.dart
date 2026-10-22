import 'package:donziker/providers/music_provider.dart';
import 'package:donziker/theme/app_theme.dart';
import 'package:donziker/theme/motion.dart';
import 'package:donziker/theme/theme_extensions.dart';
import 'package:donziker/widgets/motion/animated_count.dart';
import 'package:donziker/widgets/motion/fade_slide_in.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class StatsScreen extends StatefulWidget {
  const StatsScreen({super.key});

  @override
  State<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen> with SingleTickerProviderStateMixin {
  Map<String, int>? _summary;
  late final AnimationController _bars;

  @override
  void initState() {
    super.initState();
    _bars = AnimationController(vsync: this, duration: const Duration(milliseconds: 900));
    _load();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (MediaQuery.disableAnimationsOf(context)) {
        _bars.value = 1;
      } else {
        _bars.forward();
      }
    });
  }

  @override
  void dispose() {
    _bars.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final s = await context.read<MusicProvider>().getListeningSummary();
    if (mounted) setState(() => _summary = s);
  }

  String _formatMs(num ms) {
    final total = ms.round();
    final h = total ~/ 3600000;
    final m = (total % 3600000) ~/ 60000;
    if (h > 0) return '${h}h ${m}min';
    return '$m min';
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<MusicProvider>();
    final c = context.dz;
    final summary = _summary;
    return Scaffold(
      backgroundColor: c.surface,
      appBar: AppBar(title: const Text('Statistiques')),
      body: summary == null
          ? Center(child: CircularProgressIndicator(color: c.accent))
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
              children: [
                FadeSlideIn(
                  index: 0,
                  child: Text(
                    'Ton écoute',
                    style: TextStyle(fontSize: 28, fontWeight: FontWeight.w600, letterSpacing: -0.6, color: c.primaryText),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Tout reste sur cet appareil.',
                  style: TextStyle(color: c.secondaryText),
                ),
                const SizedBox(height: 18),
                GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 1.35,
                  children: [
                    FadeSlideIn(
                      index: 1,
                      child: _Tile(
                        label: 'Temps d\'écoute',
                        icon: Icons.graphic_eq_rounded,
                        featured: true,
                        child: AnimatedCount(
                          value: (summary['ms'] ?? 0).toDouble(),
                          format: _formatMs,
                          style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w600, color: AppTheme.ink, letterSpacing: -0.6),
                        ),
                      ),
                    ),
                    FadeSlideIn(
                      index: 2,
                      child: _Tile(
                        label: 'Lectures',
                        icon: Icons.play_arrow_rounded,
                        child: AnimatedCount(
                          value: (summary['plays'] ?? 0).toDouble(),
                          format: (v) => v.round().toString(),
                          style: TextStyle(fontSize: 26, fontWeight: FontWeight.w600, color: c.primaryText, letterSpacing: -0.6),
                        ),
                      ),
                    ),
                    FadeSlideIn(
                      index: 3,
                      child: _Tile(
                        label: 'Favoris',
                        icon: Icons.favorite_rounded,
                        child: AnimatedCount(
                          value: provider.favorites.length.toDouble(),
                          format: (v) => v.round().toString(),
                          style: TextStyle(fontSize: 26, fontWeight: FontWeight.w600, color: c.primaryText, letterSpacing: -0.6),
                        ),
                      ),
                    ),
                    FadeSlideIn(
                      index: 4,
                      child: _Tile(
                        label: 'Bibliothèque',
                        icon: Icons.library_music_rounded,
                        child: AnimatedCount(
                          value: provider.songs.length.toDouble(),
                          format: (v) => v.round().toString(),
                          style: TextStyle(fontSize: 26, fontWeight: FontWeight.w600, color: c.primaryText, letterSpacing: -0.6),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                FadeSlideIn(
                  index: 5,
                  child: _BarsCard(
                    animation: _bars,
                    values: _barValues(provider, summary),
                    labels: const ['Titres', 'Favoris', 'Lectures', 'Listes', 'Récents', 'File', 'Vidéos'],
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  '${provider.playlists.length} playlists · données locales uniquement.',
                  style: TextStyle(color: c.secondaryText, fontSize: 13),
                ),
              ],
            ),
    );
  }

  List<double> _barValues(MusicProvider provider, Map<String, int> summary) {
    final raw = <double>[
      provider.songs.length.toDouble(),
      provider.favorites.length.toDouble(),
      (summary['plays'] ?? 0).toDouble(),
      provider.playlists.length.toDouble(),
      provider.recentlyPlayed.length.toDouble(),
      provider.queue.length.toDouble(),
      provider.videos.length.toDouble(),
    ];
    final maxV = raw.fold<double>(0, (a, b) => a > b ? a : b);
    if (maxV <= 0) return List<double>.filled(raw.length, 0.08);
    return raw.map((v) => (v / maxV).clamp(0.08, 1.0)).toList();
  }
}

class _Tile extends StatelessWidget {
  final String label;
  final IconData icon;
  final Widget child;
  final bool featured;

  const _Tile({
    required this.label,
    required this.icon,
    required this.child,
    this.featured = false,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.dz;
    final bg = featured ? AppTheme.lime : (c.isDark ? AppTheme.darkCard : Colors.white);
    final fg = featured ? AppTheme.ink : c.primaryText;
    final sub = featured ? AppTheme.ink.withValues(alpha: 0.7) : c.secondaryText;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: c.isDark ? 0.25 : 0.04),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: fg),
              const SizedBox(width: 6),
              Expanded(
                child: Text(label, style: TextStyle(fontSize: 13, color: sub, fontWeight: FontWeight.w600)),
              ),
            ],
          ),
          const Spacer(),
          child,
        ],
      ),
    );
  }
}

class _BarsCard extends StatelessWidget {
  final Animation<double> animation;
  final List<double> values;
  final List<String> labels;

  const _BarsCard({required this.animation, required this.values, required this.labels});

  @override
  Widget build(BuildContext context) {
    final c = context.dz;
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
      decoration: BoxDecoration(
        color: c.isDark ? AppTheme.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Répartition', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16, color: c.primaryText)),
          const SizedBox(height: 4),
          Text('Bibliothèque locale', style: TextStyle(color: c.secondaryText, fontSize: 12)),
          const SizedBox(height: 16),
          SizedBox(
            height: 140,
            child: AnimatedBuilder(
              animation: animation,
              builder: (context, _) {
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    for (var i = 0; i < values.length; i++)
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: _bar(i, c),
                        ),
                      ),
                  ],
                );
              },
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              for (var i = 0; i < labels.length; i++)
                Expanded(
                  child: Text(
                    labels[i],
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 9, color: c.secondaryText),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _bar(int i, DzColors c) {
    final start = i * 0.08;
    final t = ((animation.value - start) / 0.55).clamp(0.0, 1.0);
    final eased = kEaseOutQuint.transform(t);
    final h = 8 + (values[i] * 120 * eased);
    final featured = i == 2;
    return Align(
      alignment: Alignment.bottomCenter,
      child: Container(
        height: h,
        decoration: BoxDecoration(
          color: featured ? AppTheme.lime : (c.isDark ? const Color(0xFF2A2A2A) : AppTheme.ink),
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }
}
