import 'package:donziker/providers/music_provider.dart';
import 'package:donziker/theme/theme_extensions.dart';
import 'package:donziker/utils/song_utils.dart';
import 'package:donziker/widgets/premium/premium_song_tile.dart';
import 'package:flutter/material.dart';
import 'package:on_audio_query/on_audio_query.dart';
import 'package:provider/provider.dart';

class AlbumDetailScreen extends StatelessWidget {
  final String name;
  final List<SongModel> songs;
  const AlbumDetailScreen({super.key, required this.name, required this.songs});

  @override
  Widget build(BuildContext context) {
    final c = context.dz;
    return Scaffold(
      backgroundColor: c.surface,
      appBar: AppBar(title: Text(name)),
      body: ListView.builder(
        itemCount: songs.length,
        itemBuilder: (context, i) => PremiumSongTile(song: songs[i], playlistContext: songs, index: i),
      ),
    );
  }
}

class ArtistDetailScreen extends StatelessWidget {
  final String name;
  final List<SongModel> songs;
  const ArtistDetailScreen({super.key, required this.name, required this.songs});

  @override
  Widget build(BuildContext context) {
    final c = context.dz;
    return Scaffold(
      backgroundColor: c.surface,
      appBar: AppBar(title: Text(name)),
      floatingActionButton: FloatingActionButton(
        backgroundColor: c.accent,
        foregroundColor: c.scheme.onPrimary,
        onPressed: () => context.read<MusicProvider>().setQueue(songs, 0),
        child: const Icon(Icons.play_arrow_rounded),
      ),
      body: ListView.builder(
        itemCount: songs.length,
        itemBuilder: (context, i) => PremiumSongTile(song: songs[i], playlistContext: songs, index: i),
      ),
    );
  }
}

class GenreDetailScreen extends StatelessWidget {
  final String name;
  final List<SongModel> songs;
  const GenreDetailScreen({super.key, required this.name, required this.songs});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.dz.surface,
      appBar: AppBar(title: Text(name)),
      body: ListView.builder(
        itemCount: songs.length,
        itemBuilder: (context, i) => PremiumSongTile(song: songs[i], playlistContext: songs, index: i),
      ),
    );
  }
}

class FolderDetailScreen extends StatelessWidget {
  final String path;
  final List<SongModel> songs;
  const FolderDetailScreen({super.key, required this.path, required this.songs});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.dz.surface,
      appBar: AppBar(title: Text(SongUtils.folderName(songs.first))),
      body: ListView.builder(
        itemCount: songs.length,
        itemBuilder: (context, i) => PremiumSongTile(song: songs[i], playlistContext: songs, index: i),
      ),
    );
  }
}
