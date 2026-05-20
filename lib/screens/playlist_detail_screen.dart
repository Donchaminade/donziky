import 'package:donziker/providers/music_provider.dart';
import 'package:donziker/theme/theme_extensions.dart';
import 'package:donziker/widgets/premium/premium_song_tile.dart';
import 'package:flutter/material.dart';
import 'package:on_audio_query/on_audio_query.dart';
import 'package:provider/provider.dart';

class PlaylistDetailScreen extends StatefulWidget {
  final String playlistId;
  final String name;

  const PlaylistDetailScreen({super.key, required this.playlistId, required this.name});

  @override
  State<PlaylistDetailScreen> createState() => _PlaylistDetailScreenState();
}

class _PlaylistDetailScreenState extends State<PlaylistDetailScreen> {
  List<SongModel> _songs = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final songs = await context.read<MusicProvider>().getPlaylistSongs(widget.playlistId);
    if (mounted) setState(() { _songs = songs; _loading = false; });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.dz.surface,
      appBar: AppBar(
        title: Text(widget.name),
        actions: [
          if (_songs.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.play_arrow),
              onPressed: () => context.read<MusicProvider>().setQueue(_songs, 0),
            ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _songs.isEmpty
              ? const Center(child: Text('Playlist vide — ajoutez des titres via ⋮'))
              : ListView.builder(
                  itemCount: _songs.length,
                  itemBuilder: (context, i) => PremiumSongTile(song: _songs[i], playlistContext: _songs, index: i),
                ),
    );
  }
}
