import 'package:donziker/providers/music_provider.dart';
import 'package:donziker/theme/theme_extensions.dart';
import 'package:donziker/widgets/premium/premium_song_tile.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class FavoritesScreen extends StatelessWidget {
  const FavoritesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.dz;

    return Scaffold(
      backgroundColor: c.surface,
      body: Consumer<MusicProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading) {
            return Center(child: CircularProgressIndicator(color: c.accent));
          }

          final songs = provider.favoriteSongs;

          return CustomScrollView(
            slivers: [
              SliverAppBar(
                expandedHeight: 140,
                pinned: true,
                flexibleSpace: FlexibleSpaceBar(
                  title: Text('Favoris', style: TextStyle(fontWeight: FontWeight.w800, color: c.primaryText)),
                  background: Container(decoration: BoxDecoration(gradient: c.heroGradient)),
                ),
              ),
              if (songs.isEmpty)
                SliverFillRemaining(
                  child: Center(
                    child: Text(
                      'Aucun favori.\nAppuyez sur ♥ depuis le lecteur.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: c.secondaryText),
                    ),
                  ),
                )
              else
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, i) => PremiumSongTile(song: songs[i], playlistContext: songs, index: i),
                    childCount: songs.length,
                  ),
                ),
              const SliverToBoxAdapter(child: SizedBox(height: 120)),
            ],
          );
        },
      ),
    );
  }
}
