import 'package:donziker/providers/music_provider.dart';
import 'package:donziker/utils/song_utils.dart';
import 'package:flutter/material.dart';
import 'package:on_audio_query/on_audio_query.dart';
import 'package:provider/provider.dart';

/// Fait défiler la liste pour centrer le morceau en cours de lecture.
class SongScrollHelper {
  static void scrollToCurrentSong({
    required BuildContext context,
    required GlobalKey itemKey,
    required List<SongModel> songs,
    int? locateGeneration,
  }) {
    final provider = context.read<MusicProvider>();
    final songId = provider.scrollToSongId;
    if (songId == null) return;

    final index = songs.indexWhere((s) => SongUtils.songId(s) == songId);
    if (index < 0) {
      provider.clearScrollToSong();
      return;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final ctx = itemKey.currentContext;
      if (ctx != null) {
        Scrollable.ensureVisible(
          ctx,
          alignment: 0.5,
          duration: const Duration(milliseconds: 450),
          curve: Curves.easeOutCubic,
        );
      }
      provider.clearScrollToSong();
    });
  }
}
