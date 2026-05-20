import 'package:donziker/providers/music_provider.dart';
import 'package:donziker/utils/song_utils.dart';
import 'package:donziker/widgets/song_list_tile.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class SongsScreen extends StatefulWidget {
  const SongsScreen({super.key});

  @override
  State<SongsScreen> createState() => _SongsScreenState();
}

class _SongsScreenState extends State<SongsScreen> {
  final _scrollController = ScrollController();
  String? _lastScrolledId;

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToSong(String songId, List songs) {
    if (_lastScrolledId == songId) return;
    final index = songs.indexWhere((s) => SongUtils.songId(s) == songId);
    if (index < 0) return;
    _lastScrolledId = songId;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      const itemHeight = 72.0;
      final offset = (index * itemHeight).clamp(0.0, _scrollController.position.maxScrollExtent);
      _scrollController.animateTo(offset, duration: const Duration(milliseconds: 400), curve: Curves.easeOut);
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<MusicProvider>();
    final songs = provider.filteredSongs;

    final scrollId = provider.scrollToSongId;
    if (scrollId != null && songs.isNotEmpty) {
      _scrollToSong(scrollId, songs);
      WidgetsBinding.instance.addPostFrameCallback((_) => provider.clearScrollToSong());
    }

    if (songs.isEmpty) {
      return const Center(child: Text('Aucun morceau trouvé sur cet appareil'));
    }

    return ListView.builder(
      controller: _scrollController,
      itemCount: songs.length,
      itemBuilder: (context, i) {
        final song = songs[i];
        final isCurrent = provider.currentSong?.id == song.id;
        return Container(
          color: isCurrent ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.15) : null,
          child: SongListTile(song: song, playlistContext: songs, index: i),
        );
      },
    );
  }
}
