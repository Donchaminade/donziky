import 'package:donziker/providers/music_provider.dart';
import 'package:donziker/utils/song_utils.dart';
import 'package:donziker/widgets/song_list_tile.dart';
import 'package:flutter/material.dart';
import 'package:on_audio_query/on_audio_query.dart';
import 'package:provider/provider.dart';

class ArtistsScreen extends StatelessWidget {
  const ArtistsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final songs = context.watch<MusicProvider>().filteredSongs;
    final artists = SongUtils.groupByArtist(songs);
    final keys = artists.keys.toList()..sort();

    return ListView.builder(
      itemCount: keys.length,
      itemBuilder: (context, i) {
        final name = keys[i];
        final artistSongs = artists[name]!;
        return ListTile(
          leading: CircleAvatar(child: Text(name.isNotEmpty ? name[0].toUpperCase() : '?')),
          title: Text(name),
          subtitle: Text('${artistSongs.length} titres'),
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => _ArtistDetail(name: name, songs: artistSongs)),
          ),
        );
      },
    );
  }
}

class _ArtistDetail extends StatelessWidget {
  final String name;
  final List<SongModel> songs;

  const _ArtistDetail({required this.name, required this.songs});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(name)),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.read<MusicProvider>().setQueue(songs, 0),
        child: const Icon(Icons.play_arrow),
      ),
      body: ListView.builder(
        itemCount: songs.length,
        itemBuilder: (context, i) => SongListTile(song: songs[i], playlistContext: songs, index: i),
      ),
    );
  }
}
