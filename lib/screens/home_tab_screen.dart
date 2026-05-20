import 'dart:ui';

import 'package:donziker/providers/music_provider.dart';
import 'package:donziker/services/permission_service.dart';
import 'package:donziker/screens/stats_screen.dart';
import 'package:donziker/theme/app_theme.dart';
import 'package:donziker/theme/theme_extensions.dart';
import 'package:donziker/utils/song_scroll_helper.dart';
import 'package:donziker/widgets/compact_song_card.dart';
import 'package:donziker/widgets/premium/premium_song_tile.dart';
import 'package:flutter/material.dart';
import 'package:on_audio_query/on_audio_query.dart';
import 'package:provider/provider.dart';

class HomeTabScreen extends StatefulWidget {
  const HomeTabScreen({super.key});

  @override
  State<HomeTabScreen> createState() => _HomeTabScreenState();
}

class _HomeTabScreenState extends State<HomeTabScreen> {
  final GlobalKey _playingItemKey = GlobalKey();
  int _lastLocateGen = -1;

  void _handleLocate(MusicProvider provider, List<SongModel> songs) {
    if (provider.locateGeneration == _lastLocateGen) return;
    if (provider.scrollToSongId == null) return;
    _lastLocateGen = provider.locateGeneration;
    SongScrollHelper.scrollToCurrentSong(
      context: context,
      itemKey: _playingItemKey,
      songs: songs,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<MusicProvider>(
      builder: (context, provider, _) {
        final c = context.dz;

        if (provider.isLoading) {
          return Scaffold(
            backgroundColor: c.surface,
            body: Center(child: CircularProgressIndicator(color: c.accent)),
          );
        }
        if (!provider.permissionGranted) {
          return Scaffold(
            backgroundColor: c.surface,
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(28),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.library_music_rounded, size: 64, color: c.tertiaryText),
                    const SizedBox(height: 16),
                    Text(
                      'DonZiker lit la musique déjà sur votre téléphone.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 16, color: c.secondaryText, height: 1.4),
                    ),
                    const SizedBox(height: 24),
                    FilledButton(
                      onPressed: provider.checkAndRequestPermissions,
                      child: const Text('Autoriser l\'accès'),
                    ),
                    TextButton(
                      onPressed: () => PermissionService().openSystemSettings(),
                      child: const Text('Paramètres Android'),
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        final songs = provider.filteredSongs;
        _handleLocate(provider, songs);

        final favorites = provider.favoriteSongs;
        final recent = provider.recentlyPlayed;
        final top = provider.smartMostPlayed;
        final added = provider.smartRecentlyAdded;
        final currentId = provider.currentSong?.id;

        return Scaffold(
          backgroundColor: c.surface,
          body: RefreshIndicator(
            color: c.accent,
            onRefresh: provider.refreshLibrary,
            child: CustomScrollView(
              slivers: [
                SliverAppBar(
                  expandedHeight: 200,
                  pinned: true,
                  stretch: true,
                  flexibleSpace: FlexibleSpaceBar(
                    stretchModes: const [StretchMode.zoomBackground],
                    background: Container(
                      decoration: BoxDecoration(gradient: c.heroGradient),
                      padding: const EdgeInsets.fromLTRB(20, 56, 20, 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Text('Bonjour,', style: TextStyle(color: c.secondaryText, fontSize: 16)),
                          Text(
                            'Votre musique',
                            style: TextStyle(
                              fontSize: 30,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.8,
                              color: c.primaryText,
                            ),
                          ),
                          const SizedBox(height: 14),
                          _searchBar(context, provider, c),
                        ],
                      ),
                    ),
                  ),
                  actions: [
                    IconButton(
                      icon: Icon(Icons.bar_chart_rounded, color: c.primaryText),
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const StatsScreen()),
                      ),
                    ),
                  ],
                ),
                if (provider.searchQuery.isEmpty) ...[
                  if (favorites.isNotEmpty) ...[
                    _section(context, 'Mes favoris'),
                    SliverToBoxAdapter(child: CompactSongRow(songs: favorites)),
                  ],
                  if (recent.isNotEmpty) ...[
                    _section(context, 'Écoutées récemment'),
                    SliverToBoxAdapter(child: CompactSongRow(songs: recent)),
                  ],
                  if (top.isNotEmpty) ...[
                    _section(context, 'Les plus écoutés'),
                    SliverToBoxAdapter(child: CompactSongRow(songs: top)),
                  ],
                  if (added.isNotEmpty) ...[
                    _section(context, 'Ajoutés récemment'),
                    SliverToBoxAdapter(child: CompactSongRow(songs: added)),
                  ],
                  _section(context, 'Toutes les chansons (${songs.length})'),
                ] else
                  _section(context, 'Résultats (${songs.length})'),
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, i) {
                      final song = songs[i];
                      final isCurrent = currentId == song.id;
                      return PremiumSongTile(
                        song: song,
                        playlistContext: songs,
                        index: i,
                        itemKey: isCurrent ? _playingItemKey : null,
                      );
                    },
                    childCount: songs.length,
                  ),
                ),
                const SliverToBoxAdapter(child: SizedBox(height: 140)),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _searchBar(BuildContext context, MusicProvider provider, DzColors c) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppTheme.radiusMd),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: TextField(
          onChanged: provider.updateSearchQuery,
          style: TextStyle(color: c.primaryText),
          decoration: InputDecoration(
            hintText: 'Rechercher titre, artiste, album...',
            filled: true,
            fillColor: c.card.withValues(alpha: 0.8),
            prefixIcon: Icon(Icons.search_rounded, color: c.secondaryText),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppTheme.radiusMd),
              borderSide: BorderSide.none,
            ),
          ),
        ),
      ),
    );
  }

  Widget _section(BuildContext context, String title) {
    final c = context.dz;
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 18, 16, 8),
        child: Text(
          title,
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, letterSpacing: -0.3, color: c.primaryText),
        ),
      ),
    );
  }

}
