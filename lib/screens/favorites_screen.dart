import 'package:donziker/providers/music_provider.dart';
import 'package:donziker/screens/player_screen.dart';
import 'package:flutter/material.dart';
import 'package:on_audio_query/on_audio_query.dart';
// import 'package:on_audio_query_forked/on_audio_query.dart';
// import 'package:on_audio_query/on_audio_query.dart';
import 'package:provider/provider.dart';

class FavoritesScreen extends StatelessWidget {
  const FavoritesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Favoris'),
      ),
      body: Consumer<MusicProvider>(
        builder: (context, provider, child) {
          return FutureBuilder<List<SongModel>>(
            future: OnAudioQuery().querySongs(),
            builder: (context, snapshot) {
              if (snapshot.data == null) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.data!.isEmpty) {
                return const Center(child: Text('Aucune chanson trouvée'));
              }
              final allSongs = snapshot.data!;
              final favoriteSongs = allSongs.where((song) => provider.isFavorite(song.id)).toList();

              if (favoriteSongs.isEmpty) {
                return const Center(child: Text('Aucun favori pour le moment'));
              }

              return ListView.builder(
                itemCount: favoriteSongs.length,
                itemBuilder: (context, index) {
                  final song = favoriteSongs[index];
                  return ListTile(
                    title: Text(song.title),
                    subtitle: Text(song.artist ?? 'Artiste inconnu'),
                    leading: QueryArtworkWidget(
                      id: song.id,
                      type: ArtworkType.AUDIO,
                      nullArtworkWidget: const Icon(Icons.music_note),
                    ),
                    onTap: () {
                      provider.setPlaylist(favoriteSongs, index);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const PlayerScreen(),
                        ),
                      );
                    },
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}