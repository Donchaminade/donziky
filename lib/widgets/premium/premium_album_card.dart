import 'package:donziker/providers/music_provider.dart';
import 'package:donziker/theme/theme_extensions.dart';
import 'package:flutter/material.dart';
import 'package:on_audio_query/on_audio_query.dart';
import 'package:provider/provider.dart';

class PremiumAlbumCard extends StatelessWidget {
  final String name;
  final List<SongModel> songs;
  final VoidCallback onTap;

  const PremiumAlbumCard({
    super.key,
    required this.name,
    required this.songs,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.dz;
    final first = songs.first;

    return GestureDetector(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AspectRatio(
            aspectRatio: 1,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  QueryArtworkWidget(
                    id: first.id,
                    type: ArtworkType.AUDIO,
                    nullArtworkWidget: Container(
                      color: c.accent.withValues(alpha: 0.12),
                      child: Icon(Icons.album_rounded, color: c.accent, size: 48),
                    ),
                  ),
                  Positioned(
                    right: 8,
                    bottom: 8,
                    child: Material(
                      color: Colors.black.withValues(alpha: 0.45),
                      shape: const CircleBorder(),
                      child: InkWell(
                        customBorder: const CircleBorder(),
                        onTap: () => context.read<MusicProvider>().setQueue(songs, 0),
                        child: const Padding(
                          padding: EdgeInsets.all(8),
                          child: Icon(Icons.play_arrow_rounded, color: Colors.white, size: 22),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 14,
              color: c.primaryText,
              letterSpacing: -0.2,
            ),
          ),
          Text(
            '${songs.length} titres',
            style: TextStyle(fontSize: 12, color: c.secondaryText),
          ),
        ],
      ),
    );
  }
}
