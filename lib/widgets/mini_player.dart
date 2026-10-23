import 'package:donziker/providers/music_provider.dart';
import 'package:donziker/screens/player_screen.dart';
import 'package:donziker/theme/app_theme.dart';
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

        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
          child: Material(
            color: AppTheme.ink,
            borderRadius: BorderRadius.circular(28),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: () => Navigator.push(
                context,
                PageRouteBuilder(
                  transitionDuration: const Duration(milliseconds: 420),
                  reverseTransitionDuration: const Duration(milliseconds: 320),
                  pageBuilder: (_, __, ___) => const PlayerScreen(),
                  transitionsBuilder: (_, animation, __, child) {
                    return FadeTransition(opacity: animation, child: child);
                  },
                ),
              ),
              child: SizedBox(
                height: 64,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Row(
                    children: [
                      Hero(
                        tag: 'albumArt',
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: QueryArtworkWidget(
                            id: song.id,
                            type: ArtworkType.AUDIO,
                            artworkWidth: 48,
                            artworkHeight: 48,
                            nullArtworkWidget: Container(
                              width: 48,
                              height: 48,
                              color: const Color(0xFF2A2A2A),
                              child: const Icon(Icons.music_note_rounded, color: AppTheme.lime, size: 22),
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
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 14,
                                color: Colors.white,
                                letterSpacing: -0.2,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              song.artist ?? 'Artiste inconnu',
                              style: const TextStyle(fontSize: 12, color: Color(0xFFB5B5B5)),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: Icon(
                          provider.isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                          color: AppTheme.lime,
                          size: 30,
                        ),
                        onPressed: provider.togglePlayPause,
                      ),
                      IconButton(
                        icon: const Icon(Icons.skip_next_rounded, color: Colors.white, size: 26),
                        onPressed: provider.playNext,
                      ),
                    ],
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
