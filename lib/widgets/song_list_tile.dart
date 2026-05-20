import 'package:donziker/providers/music_provider.dart';
import 'package:donziker/widgets/song_options_sheet.dart';
import 'package:flutter/material.dart';
import 'package:on_audio_query/on_audio_query.dart';
import 'package:provider/provider.dart';

class SongListTile extends StatelessWidget {
  final SongModel song;
  final List<SongModel> playlistContext;
  final int index;

  const SongListTile({
    super.key,
    required this.song,
    required this.playlistContext,
    required this.index,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: QueryArtworkWidget(
        id: song.id,
        type: ArtworkType.AUDIO,
        nullArtworkWidget: const Icon(Icons.music_note),
        artworkBorder: BorderRadius.circular(6),
        artworkQuality: FilterQuality.low,
        size: 56,
      ),
      title: Text(song.title, overflow: TextOverflow.ellipsis),
      subtitle: Text(song.artist ?? 'Artiste inconnu', overflow: TextOverflow.ellipsis),
      trailing: IconButton(
        icon: const Icon(Icons.more_vert),
        onPressed: () => showModalBottomSheet(
          context: context,
          backgroundColor: Colors.transparent,
          isScrollControlled: true,
          builder: (_) => SongOptionsSheet(song: song),
        ),
      ),
      onTap: () =>
          context.read<MusicProvider>().setQueue(playlistContext, index),
    );
  }
}
