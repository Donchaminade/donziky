import 'dart:ui';

import 'package:donziker/providers/music_provider.dart';
import 'package:donziker/screens/player_screen.dart';
import 'package:donziker/theme/app_theme.dart';
import 'package:donziker/theme/theme_extensions.dart';
import 'package:flutter/material.dart';
import 'package:on_audio_query/on_audio_query.dart';
import 'package:provider/provider.dart';

class MiniPlayer extends StatelessWidget {
  const MiniPlayer({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<MusicProvider>(
      builder: (context, provider, _) {
        final song = provider.currentSong;
        if (song == null) return const SizedBox.shrink();

        final c = context.dz;

        return SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 0, 14, 6),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(AppTheme.radiusXl),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                child: Material(
                  color: c.card.withValues(alpha: 0.95),
                  child: InkWell(
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const PlayerScreen()),
                    ),
                    child: Container(
                      height: 72,
                      decoration: BoxDecoration(
                        border: Border.all(color: c.glassBorder),
                        borderRadius: BorderRadius.circular(AppTheme.radiusXl),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Row(
                        children: [
                          Hero(
                            tag: 'albumArt',
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: QueryArtworkWidget(
                                id: song.id,
                                type: ArtworkType.AUDIO,
                                artworkWidth: 48,
                                artworkHeight: 48,
                                nullArtworkWidget: Container(
                                  width: 48,
                                  height: 48,
                                  color: c.highlight,
                                  child: Icon(Icons.music_note_rounded, color: c.accent),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  song.title,
                                  style: TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 14,
                                    color: c.primaryText,
                                    letterSpacing: -0.2,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                                Text(
                                  song.artist ?? 'Artiste inconnu',
                                  style: TextStyle(fontSize: 12, color: c.secondaryText),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: Icon(
                              provider.isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                              color: c.accent,
                              size: 30,
                            ),
                            onPressed: provider.togglePlayPause,
                          ),
                          IconButton(
                            icon: Icon(Icons.skip_next_rounded, color: c.primaryText, size: 26),
                            onPressed: provider.playNext,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
