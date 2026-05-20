import 'package:donziker/widgets/premium/premium_song_tile.dart';
import 'package:flutter/material.dart';
import 'package:on_audio_query/on_audio_query.dart';

/// Alias vers le tile premium (thème global).
class SongListTile extends StatelessWidget {
  final SongModel song;
  final List<SongModel> playlistContext;
  final int index;
  final bool highlight;

  const SongListTile({
    super.key,
    required this.song,
    required this.playlistContext,
    required this.index,
    this.highlight = false,
  });

  @override
  Widget build(BuildContext context) {
    return PremiumSongTile(
      song: song,
      playlistContext: playlistContext,
      index: index,
      highlight: highlight,
    );
  }
}
