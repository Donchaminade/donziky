import 'dart:ui';
import 'package:donziker/providers/music_provider.dart';
import 'package:donziker/providers/theme_provider.dart';
import 'package:donziker/screens/player_screen.dart';
import 'package:flutter/material.dart';
import 'package:on_audio_query/on_audio_query.dart';
import 'package:provider/provider.dart';

class MiniPlayer extends StatelessWidget {
  const MiniPlayer({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer2<MusicProvider, ThemeProvider>(
      builder: (context, provider, theme, _) {
        final song = provider.currentSong;
        if (song == null) return const SizedBox.shrink();
        final accent = theme.effectiveAccent(
          provider.dynamicAccentColor,
          useDynamic: provider.useDynamicAccent,
        );

        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                child: GestureDetector(
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const PlayerScreen()),
                  ),
                  child: Container(
                    height: 75,
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.6),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
                    ),
                    child: Row(
                      children: [
                        const SizedBox(width: 12),
                        Hero(
                          tag: 'albumArt',
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: QueryArtworkWidget(
                              id: song.id,
                              type: ArtworkType.AUDIO,
                              nullArtworkWidget: const Icon(Icons.music_note, color: Colors.white),
                              artworkWidth: 50,
                              artworkHeight: 50,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(song.title,
                                  style: const TextStyle(
                                      color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                                  overflow: TextOverflow.ellipsis),
                              Text(song.artist ?? 'Artiste inconnu',
                                  style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 12),
                                  overflow: TextOverflow.ellipsis),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: Icon(provider.isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                              color: accent, size: 32),
                          onPressed: () => provider.isPlaying ? provider.pause() : provider.play(),
                        ),
                        IconButton(
                          icon: const Icon(Icons.skip_next_rounded, color: Colors.white, size: 28),
                          onPressed: provider.playNext,
                        ),
                      ],
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
