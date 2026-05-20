import 'package:donziker/providers/music_provider.dart';
import 'package:donziker/utils/song_utils.dart';
import 'package:donziker/widgets/song_list_tile.dart';
import 'package:flutter/material.dart';
import 'package:on_audio_query/on_audio_query.dart';
import 'package:provider/provider.dart';

class FoldersScreen extends StatelessWidget {
  const FoldersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<MusicProvider>();
    final songs = provider.filteredSongs;
    final folders = SongUtils.groupByFolder(songs);
    final keys = folders.keys.toList()..sort();

    return ListView.builder(
      itemCount: keys.length,
      itemBuilder: (context, i) {
        final path = keys[i];
        final folderSongs = folders[path]!;
        return ListTile(
          leading: const Icon(Icons.folder),
          title: Text(SongUtils.folderName(folderSongs.first), overflow: TextOverflow.ellipsis),
          subtitle: Text('$path\n${folderSongs.length} titres', maxLines: 2, overflow: TextOverflow.ellipsis),
          trailing: PopupMenuButton<String>(
            onSelected: (v) async {
              if (v == 'exclude') {
                await provider.addExcludedFolder(path);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Dossier exclu')));
                }
              }
            },
            itemBuilder: (_) => [const PopupMenuItem(value: 'exclude', child: Text('Exclure ce dossier'))],
          ),
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => _FolderDetail(path: path, songs: folderSongs)),
          ),
        );
      },
    );
  }
}

class _FolderDetail extends StatelessWidget {
  final String path;
  final List<SongModel> songs;

  const _FolderDetail({required this.path, required this.songs});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(SongUtils.folderName(songs.first))),
      body: ListView.builder(
        itemCount: songs.length,
        itemBuilder: (context, i) => SongListTile(song: songs[i], playlistContext: songs, index: i),
      ),
    );
  }
}
