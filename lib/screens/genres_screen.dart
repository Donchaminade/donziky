import 'package:donziker/providers/music_provider.dart';
import 'package:donziker/utils/song_utils.dart';
import 'package:donziker/widgets/song_list_tile.dart';
import 'package:flutter/material.dart';
import 'package:on_audio_query/on_audio_query.dart';
import 'package:provider/provider.dart';

class GenresScreen extends StatelessWidget {
  const GenresScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final songs = context.watch<MusicProvider>().filteredSongs;
    final genres = SongUtils.groupByGenre(songs);
    final keys = genres.keys.toList()..sort();

    return ListView.builder(
      itemCount: keys.length,
      itemBuilder: (context, i) {
        final name = keys[i];
        final genreSongs = genres[name]!;
        return ListTile(
          leading: const Icon(Icons.category),
          title: Text(name),
          subtitle: Text('${genreSongs.length} titres'),
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => _GenreDetail(name: name, songs: genreSongs)),
          ),
        );
      },
    );
  }
}

class _GenreDetail extends StatelessWidget {
  final String name;
  final List<SongModel> songs;

  const _GenreDetail({required this.name, required this.songs});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(name)),
      body: ListView.builder(
        itemCount: songs.length,
        itemBuilder: (context, i) => SongListTile(song: songs[i], playlistContext: songs, index: i),
      ),
    );
  }
}
