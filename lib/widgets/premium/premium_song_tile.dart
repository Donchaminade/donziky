import 'package:donziker/providers/music_provider.dart';
import 'package:donziker/theme/theme_extensions.dart';
import 'package:donziker/widgets/song_options_sheet.dart';
import 'package:flutter/material.dart';
import 'package:on_audio_query/on_audio_query.dart';
import 'package:provider/provider.dart';

class PremiumSongTile extends StatelessWidget {
  final SongModel song;
  final List<SongModel> playlistContext;
  final int index;
  final bool highlight;

  const PremiumSongTile({
    super.key,
    required this.song,
    required this.playlistContext,
    required this.index,
    this.highlight = false,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.dz;
    final provider = context.watch<MusicProvider>();
    final isPlaying = provider.currentSong?.id == song.id;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
      child: Material(
        color: (highlight || isPlaying) ? c.highlight : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => provider.setQueue(playlistContext, index),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: QueryArtworkWidget(
                    id: song.id,
                    type: ArtworkType.AUDIO,
                    artworkWidth: 52,
                    artworkHeight: 52,
                    size: 52,
                    nullArtworkWidget: Container(
                      width: 52,
                      height: 52,
                      color: c.accent.withValues(alpha: 0.15),
                      child: Icon(Icons.music_note_rounded, color: c.accent, size: 26),
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        song.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontWeight: isPlaying ? FontWeight.w800 : FontWeight.w600,
                          fontSize: 15,
                          color: isPlaying ? c.accent : c.primaryText,
                          letterSpacing: -0.2,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        song.artist ?? 'Artiste inconnu',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 13, color: c.secondaryText),
                      ),
                    ],
                  ),
                ),
                if (isPlaying)
                  Padding(
                    padding: const EdgeInsets.only(right: 4),
                    child: Icon(Icons.equalizer_rounded, color: c.accent, size: 22),
                  ),
                IconButton(
                  icon: Icon(Icons.more_horiz_rounded, color: c.secondaryText),
                  onPressed: () => showModalBottomSheet(
                    context: context,
                    backgroundColor: Colors.transparent,
                    isScrollControlled: true,
                    builder: (_) => SongOptionsSheet(song: song),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
