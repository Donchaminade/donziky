import 'package:donziker/providers/music_provider.dart';
import 'package:donziker/utils/song_utils.dart';
import 'package:donziker/widgets/song_list_tile.dart';
import 'package:flutter/material.dart';
import 'package:on_audio_query/on_audio_query.dart';
import 'package:provider/provider.dart';

class AlbumsScreen extends StatelessWidget {
  const AlbumsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final songs = context.watch<MusicProvider>().filteredSongs;
    final albums = SongUtils.groupByAlbum(songs);
    final keys = albums.keys.toList()..sort();

    return ListView.builder(
      itemCount: keys.length,
      itemBuilder: (context, i) {
        final name = keys[i];
        final albumSongs = albums[name]!;
        final first = albumSongs.first;
        return ListTile(
          leading: QueryArtworkWidget(
            id: first.id,
            type: ArtworkType.AUDIO,
            nullArtworkWidget: const Icon(Icons.album),
          ),
          title: Text(name),
          subtitle: Text('${albumSongs.length} titres · ${first.artist ?? ''}'),
          trailing: IconButton(
            icon: const Icon(Icons.play_circle_fill),
            onPressed: () => context.read<MusicProvider>().setQueue(albumSongs, 0),
          ),
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => _AlbumDetail(name: name, songs: albumSongs),
            ),
          ),
        );
      },
    );
  }
}

class _AlbumDetail extends StatelessWidget {
  final String name;
  final List<SongModel> songs;

  const _AlbumDetail({required this.name, required this.songs});

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
