import 'package:donziker/providers/music_provider.dart';
import 'package:donziker/widgets/song_list_tile.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class FavoritesScreen extends StatelessWidget {
  const FavoritesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Favoris')),
      body: Consumer<MusicProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          final songs = provider.favoriteSongs;
          if (songs.isEmpty) {
            return const Center(
              child: Text(
                'Aucun favori.\nAppuyez sur ♥ depuis le lecteur ou les options d\'un morceau.',
                textAlign: TextAlign.center,
              ),
            );
          }
          return ListView.builder(
            itemCount: songs.length,
            itemBuilder: (context, i) => SongListTile(song: songs[i], playlistContext: songs, index: i),
          );
        },
      ),
    );
  }
}
