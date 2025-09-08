import 'package:donziker/providers/music_provider.dart';
import 'package:donziker/screens/player_screen.dart';
import 'package:flutter/material.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:photo_manager_image_provider/photo_manager_image_provider.dart';
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
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          final allSongs = provider.songs;
          final favoriteSongs = allSongs.where((song) => provider.isFavorite(song.id)).toList();

          if (favoriteSongs.isEmpty) {
            return const Center(child: Text('Aucun favori pour le moment'));
          }

          return ListView.builder(
            itemCount: favoriteSongs.length,
            itemBuilder: (context, index) {
              final song = favoriteSongs[index];
              return ListTile(
                title: Text(song.title ?? "Unknown Title"),
                subtitle: Text(song.title ?? "Unknown Title"),
                leading: SizedBox(
                  width: 56,
                  height: 56,
                  child: AssetEntityImage(
                    song,
                    isOriginal: false,
                    thumbnailSize: const ThumbnailSize.square(200),
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return const Icon(Icons.music_note, color: Colors.white);
                    },
                  ),
                ),
                onTap: () {
                  // Find the index of the favorite song in the main songs list
                  final originalIndex = provider.songs.indexOf(song);
                  if (originalIndex != -1) {
                    provider.setPlaylist(provider.songs, originalIndex);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const PlayerScreen(),
                      ),
                    );
                  }
                },
              );
            },
          );
        },
      ),
    );
  }
}