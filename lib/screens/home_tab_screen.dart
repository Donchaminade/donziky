import 'dart:ui';
import 'package:donziker/providers/music_provider.dart';
import 'package:donziker/services/permission_service.dart';
import 'package:donziker/providers/theme_provider.dart';
import 'package:donziker/screens/stats_screen.dart';
import 'package:donziker/widgets/song_list_tile.dart';
import 'package:flutter/material.dart';
import 'package:on_audio_query/on_audio_query.dart';
import 'package:provider/provider.dart';

class HomeTabScreen extends StatelessWidget {
  const HomeTabScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer2<MusicProvider, ThemeProvider>(
      builder: (context, provider, theme, _) {
        if (provider.isLoading) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        if (!provider.permissionGranted) {
          return Scaffold(
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.library_music, size: 64, color: Colors.white54),
                    const SizedBox(height: 16),
                    const Text(
                      'DonZiker lit la musique déjà sur votre téléphone.\nAucun morceau n\'est fourni par l\'application.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 16),
                    ),
                    const SizedBox(height: 24),
                    FilledButton(
                      onPressed: provider.checkAndRequestPermissions,
                      child: const Text('Autoriser l\'accès'),
                    ),
                    const SizedBox(height: 12),
                    TextButton(
                      onPressed: () => PermissionService().openSystemSettings(),
                      child: const Text('Ouvrir les paramètres Android'),
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        final accent = theme.effectiveAccent(provider.dynamicAccentColor, useDynamic: provider.useDynamicAccent);
        final favorites = provider.favoriteSongs;
        final recent = provider.recentlyPlayed;
        final top = provider.smartMostPlayed;
        final added = provider.smartRecentlyAdded;

        return Scaffold(
          body: RefreshIndicator(
            onRefresh: provider.refreshLibrary,
            child: CustomScrollView(
              slivers: [
                SliverAppBar(
                  expandedHeight: 200,
                  pinned: true,
                  flexibleSpace: FlexibleSpaceBar(
                    background: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [accent.withValues(alpha: 0.7), Colors.black],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                      padding: const EdgeInsets.fromLTRB(20, 60, 20, 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          const Text('Bonjour,', style: TextStyle(color: Colors.white70, fontSize: 16)),
                          const Text('Votre musique',
                              style: TextStyle(
                                  color: Colors.white, fontSize: 28, fontWeight: FontWeight.w900)),
                          const SizedBox(height: 12),
                          _searchBar(context, provider),
                        ],
                      ),
                    ),
                  ),
                  actions: [
                    IconButton(
                      icon: const Icon(Icons.bar_chart),
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const StatsScreen()),
                      ),
                    ),
                  ],
                ),
                if (provider.searchQuery.isEmpty) ...[
                  if (favorites.isNotEmpty) ...[
                    _section('Mes favoris'),
                    SliverToBoxAdapter(child: _horizontal(favorites, accent, provider)),
                  ],
                  if (recent.isNotEmpty) ...[
                    _section('Écoutées récemment'),
                    SliverToBoxAdapter(child: _horizontal(recent, accent, provider)),
                  ],
                  if (top.isNotEmpty) ...[
                    _section('Les plus écoutés'),
                    SliverToBoxAdapter(child: _horizontal(top, accent, provider)),
                  ],
                  if (added.isNotEmpty) ...[
                    _section('Ajoutés récemment'),
                    SliverToBoxAdapter(child: _horizontal(added, accent, provider)),
                  ],
                  _section('Toutes les chansons (${provider.filteredSongs.length})'),
                ] else
                  _section('Résultats (${provider.filteredSongs.length})'),
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, i) {
                      final songs = provider.filteredSongs;
                      final song = songs[i];
                      return SongListTile(song: song, playlistContext: songs, index: i);
                    },
                    childCount: provider.filteredSongs.length,
                  ),
                ),
                const SliverToBoxAdapter(child: SizedBox(height: 120)),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _searchBar(BuildContext context, MusicProvider provider) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: TextField(
          onChanged: provider.updateSearchQuery,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: 'Rechercher titre, artiste, album...',
            hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.4)),
            prefixIcon: const Icon(Icons.search, color: Colors.white70),
            filled: true,
            fillColor: Colors.white.withValues(alpha: 0.1),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
          ),
        ),
      ),
    );
  }

  Widget _section(String title) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
        child: Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _horizontal(List<SongModel> songs, Color accent, MusicProvider provider) {
    return SizedBox(
      height: 190,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        itemCount: songs.length,
        itemBuilder: (context, i) {
          final song = songs[i];
          return GestureDetector(
            onTap: () => provider.setQueue(songs, i),
            child: Container(
              width: 140,
              margin: const EdgeInsets.only(right: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: QueryArtworkWidget(
                      id: song.id,
                      type: ArtworkType.AUDIO,
                      artworkWidth: 140,
                      artworkHeight: 140,
                      nullArtworkWidget: Container(
                        width: 140,
                        height: 140,
                        color: accent.withValues(alpha: 0.2),
                        child: const Icon(Icons.music_note, size: 48),
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(song.title, maxLines: 1, overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                  Text(song.artist ?? '', maxLines: 1, overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 11, color: Colors.grey)),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
