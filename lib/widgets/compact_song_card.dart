import 'package:donziker/providers/music_provider.dart';
import 'package:donziker/theme/app_theme.dart';
import 'package:donziker/theme/theme_extensions.dart';
import 'package:flutter/material.dart';
import 'package:on_audio_query/on_audio_query.dart';
import 'package:provider/provider.dart';

/// Carte horizontale compacte pour favoris, récent, top, etc.
class CompactSongCard extends StatelessWidget {
  final SongModel song;
  final List<SongModel> playlistContext;
  final int index;

  const CompactSongCard({
    super.key,
    required this.song,
    required this.playlistContext,
    required this.index,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.dz;
    final provider = context.watch<MusicProvider>();
    final isCurrent = provider.currentSong?.id == song.id;
    final isPlaying = isCurrent && provider.isPlaying;

    return Material(
      color: isCurrent ? c.accent.withValues(alpha: 0.12) : c.card.withValues(alpha: 0.85),
      borderRadius: BorderRadius.circular(AppTheme.radiusMd),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        onTap: () {
          if (isCurrent) {
            provider.togglePlayPause();
          } else {
            provider.setQueue(playlistContext, index);
          }
        },
        child: Container(
          width: 168,
          padding: const EdgeInsets.all(8),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: QueryArtworkWidget(
                  id: song.id,
                  type: ArtworkType.AUDIO,
                  artworkWidth: 48,
                  artworkHeight: 48,
                  nullArtworkWidget: Container(
                    width: 48,
                    height: 48,
                    color: c.highlight,
                    child: Icon(Icons.music_note_rounded, color: c.accent, size: 22),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      song.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                        color: isCurrent ? c.accent : c.primaryText,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      song.artist ?? 'Artiste inconnu',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 11, color: c.secondaryText),
                    ),
                  ],
                ),
              ),
              Icon(
                isPlaying ? Icons.pause_circle_filled_rounded : Icons.play_circle_fill_rounded,
                color: c.accent,
                size: 28,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Liste horizontale de cartes compactes.
class CompactSongRow extends StatelessWidget {
  final List<SongModel> songs;

  const CompactSongRow({super.key, required this.songs});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 72,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: songs.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, i) => CompactSongCard(
          song: songs[i],
          playlistContext: songs,
          index: i,
        ),
      ),
    );
  }
}
