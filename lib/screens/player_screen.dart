import 'package:donziker/providers/music_provider.dart';
import 'package:donziker/theme/app_theme.dart';
import 'package:donziker/theme/theme_extensions.dart';
import 'package:donziker/utils/song_utils.dart';
import 'package:donziker/widgets/circular_audio_progress.dart';
import 'package:donziker/widgets/premium/glass_surface.dart';
import 'package:donziker/widgets/premium/player_controls.dart';
import 'package:donziker/widgets/song_options_sheet.dart';
import 'package:flutter/material.dart';
import 'package:on_audio_query/on_audio_query.dart';
import 'package:provider/provider.dart';

class PlayerScreen extends StatefulWidget {
  const PlayerScreen({super.key});

  @override
  State<PlayerScreen> createState() => _PlayerScreenState();
}

class _PlayerScreenState extends State<PlayerScreen> {
  String _format(Duration? d) {
    if (d == null) return '0:00';
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<MusicProvider>(
      builder: (context, provider, _) {
        final song = provider.currentSong;
        if (song == null) {
          return Scaffold(
            backgroundColor: context.dz.surface,
            body: Center(child: Text('Aucune chanson', style: TextStyle(color: context.dz.secondaryText))),
          );
        }

        final c = context.dz;

        return Scaffold(
          backgroundColor: c.surface,
          extendBodyBehindAppBar: true,
          body: Stack(
            children: [
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      c.accent.withValues(alpha: 0.45),
                      c.surface,
                      c.surface,
                    ],
                  ),
                ),
              ),
              SafeArea(
                child: Column(
                  children: [
                    _topBar(context, provider, song, c),
                    const Spacer(flex: 2),
                    _artwork(provider, song, c),
                    const SizedBox(height: 12),
                    _timeRow(provider, c),
                    const Spacer(),
                    _songInfo(provider, song, c),
                    if (provider.karaokeMode) ...[
                      const SizedBox(height: 8),
                      Text(
                        'Karaoké · ${provider.karaokeLeadSeconds}s avant la fin',
                        style: TextStyle(color: c.accent, fontWeight: FontWeight.w600, fontSize: 12),
                      ),
                    ],
                    const SizedBox(height: 12),
                    _abLoopRow(provider, c),
                    const Spacer(),
                    PlayerControls(
                      provider: provider,
                      onPlayPause: provider.togglePlayPause,
                    ),
                    const Spacer(),
                    _bottomActions(context, provider, c),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _topBar(BuildContext context, MusicProvider provider, SongModel song, DzColors c) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Row(
        children: [
          IconButton(
            icon: Icon(Icons.keyboard_arrow_down_rounded, size: 32, color: c.primaryText),
            onPressed: () => Navigator.pop(context),
          ),
          const Spacer(),
          if (provider.sleepTimerRemaining != null)
            GlassSurface(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              radius: 14,
              child: Text(
                _format(provider.sleepTimerRemaining),
                style: TextStyle(color: c.accent, fontWeight: FontWeight.w700, fontSize: 12),
              ),
            ),
          IconButton(
            icon: Icon(
              provider.karaokeMode ? Icons.mic_external_on_rounded : Icons.mic_none_rounded,
              color: provider.karaokeMode ? c.accent : c.secondaryText,
            ),
            onPressed: provider.toggleKaraokeMode,
          ),
          IconButton(
            icon: Icon(Icons.my_location_rounded, color: c.secondaryText),
            tooltip: 'Localiser dans la liste',
            onPressed: () {
              provider.requestLocateCurrentSong();
              Navigator.pop(context);
            },
          ),
          IconButton(
            icon: Icon(Icons.more_horiz_rounded, color: c.primaryText),
            onPressed: () => showModalBottomSheet(
              context: context,
              backgroundColor: Colors.transparent,
              isScrollControlled: true,
              builder: (_) => SongOptionsSheet(song: song),
            ),
          ),
        ],
      ),
    );
  }

  Widget _artwork(MusicProvider provider, SongModel song, DzColors c) {
    return StreamBuilder<Duration>(
      stream: provider.audioPlayer.positionStream,
      builder: (context, snap) {
        final pos = snap.data ?? Duration.zero;
        final dur = provider.audioPlayer.duration ?? Duration.zero;
        final progress = dur.inMilliseconds > 0 ? pos.inMilliseconds / dur.inMilliseconds : 0.0;
        final size = MediaQuery.of(context).size.width * 0.74;

        return Hero(
          tag: 'albumArt',
          child: CircularAudioProgress(
            progress: progress.clamp(0.0, 1.0),
            size: size,
            strokeWidth: 7,
            activeColor: c.accent,
            inactiveColor: c.primaryText.withValues(alpha: 0.12),
            onSeek: (p) {
              if (dur.inMilliseconds > 0) {
                provider.audioPlayer.seek(Duration(milliseconds: (dur.inMilliseconds * p).toInt()));
              }
            },
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: c.accent.withValues(alpha: 0.35),
                    blurRadius: 40,
                    spreadRadius: 4,
                  ),
                ],
              ),
              child: ClipOval(
                child: SizedBox(
                  width: size - 30,
                  height: size - 30,
                  child: QueryArtworkWidget(
                    id: song.id,
                    type: ArtworkType.AUDIO,
                    nullArtworkWidget: Container(
                      color: c.card,
                      child: Icon(Icons.music_note_rounded, size: 80, color: c.tertiaryText),
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

  Widget _timeRow(MusicProvider provider, DzColors c) {
    return StreamBuilder<Duration>(
      stream: provider.audioPlayer.positionStream,
      builder: (context, snap) {
        final pos = snap.data ?? Duration.zero;
        final dur = provider.audioPlayer.duration ?? Duration.zero;
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(_format(pos), style: TextStyle(color: c.secondaryText, fontSize: 12, fontWeight: FontWeight.w600)),
              Text(_format(dur), style: TextStyle(color: c.secondaryText, fontSize: 12, fontWeight: FontWeight.w600)),
            ],
          ),
        );
      },
    );
  }

  Widget _songInfo(MusicProvider provider, SongModel song, DzColors c) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 28),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  song.title,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: c.primaryText,
                    letterSpacing: -0.5,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  song.artist ?? 'Artiste inconnu',
                  style: TextStyle(fontSize: 16, color: c.secondaryText),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          Material(
            color: c.card,
            shape: const CircleBorder(),
            child: IconButton(
              icon: Icon(
                provider.isFavorite(SongUtils.songId(song)) ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                color: provider.isFavorite(SongUtils.songId(song)) ? c.accent : c.secondaryText,
                size: 28,
              ),
              onPressed: () => provider.toggleFavorite(SongUtils.songId(song)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _abLoopRow(MusicProvider provider, DzColors c) {
    return GlassSurface(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      radius: 24,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _revBtn('A', provider.pointA != null, provider.setPointA, c),
          const SizedBox(width: 10),
          _revBtn('B', provider.pointB != null, provider.setPointB, c),
          IconButton(
            icon: Icon(Icons.refresh_rounded, color: provider.isABLoopActive ? c.accent : c.tertiaryText, size: 22),
            onPressed: provider.clearABLoop,
          ),
        ],
      ),
    );
  }

  Widget _revBtn(String label, bool active, VoidCallback onTap, DzColors c) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: active ? c.accent : c.surface.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontWeight: FontWeight.w800,
            color: active ? c.scheme.onPrimary : c.primaryText,
          ),
        ),
      ),
    );
  }

  Widget _bottomActions(BuildContext context, MusicProvider provider, DzColors c) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: GlassSurface(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
        radius: AppTheme.radiusXl,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _action(Icons.speed_rounded, 'Vitesse', c, () => _speedDialog(provider, c)),
            _action(Icons.timer_outlined, 'Veille', c, () => _sleepDialog(provider, c)),
            _action(Icons.lyrics_rounded, 'Paroles', c, () => _lyricsSheet(provider, c)),
            _action(Icons.queue_music_rounded, 'File', c, () => _queueSheet(provider, c)),
          ],
        ),
      ),
    );
  }

  Widget _action(IconData icon, String label, DzColors c, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: c.primaryText, size: 24),
            const SizedBox(height: 4),
            Text(label, style: TextStyle(fontSize: 10, color: c.secondaryText, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }

  void _speedDialog(MusicProvider provider, DzColors c) {
    showModalBottomSheet(
      context: context,
      backgroundColor: c.card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppTheme.radiusXl)),
      ),
      builder: (ctx) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 12),
          Text('Vitesse', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18, color: c.primaryText)),
          ...[0.5, 0.75, 1.0, 1.25, 1.5, 2.0].map((s) => ListTile(
                title: Text('${s}x', style: TextStyle(color: c.primaryText)),
                trailing: provider.speed == s ? Icon(Icons.check_rounded, color: c.accent) : null,
                onTap: () {
                  provider.setSpeed(s);
                  Navigator.pop(ctx);
                },
              )),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  void _sleepDialog(MusicProvider provider, DzColors c) {
    showModalBottomSheet(
      context: context,
      backgroundColor: c.card,
      builder: (ctx) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 12),
          Text('Minuterie', style: TextStyle(fontWeight: FontWeight.w800, color: c.primaryText)),
          ...[5, 10, 15, 30, 45, 60].map((m) => ListTile(
                title: Text('$m minutes', style: TextStyle(color: c.primaryText)),
                onTap: () {
                  provider.setSleepTimer(Duration(minutes: m));
                  Navigator.pop(ctx);
                },
              )),
          ListTile(
            title: Text('Fin du morceau', style: TextStyle(color: c.primaryText)),
            onTap: () {
              provider.setSleepTimer(Duration.zero, endOfTrack: true);
              Navigator.pop(ctx);
            },
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  void _lyricsSheet(MusicProvider provider, DzColors c) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        builder: (_, controller) => Container(
          decoration: BoxDecoration(
            color: c.card,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(AppTheme.radiusXl)),
          ),
          padding: const EdgeInsets.all(20),
          child: provider.currentLyrics == null
              ? Center(child: Text('Aucun .lrc trouvé', style: TextStyle(color: c.secondaryText)))
              : StreamBuilder<Duration>(
                  stream: provider.audioPlayer.positionStream,
                  builder: (context, snap) {
                    final pos = snap.data ?? Duration.zero;
                    final lines = provider.currentLyrics!.split('\n');
                    return ListView.builder(
                      controller: controller,
                      itemCount: lines.length,
                      itemBuilder: (context, i) {
                        final line = lines[i];
                        final match = RegExp(r'\[(\d+):(\d+\.?\d*)\](.*)').firstMatch(line);
                        if (match == null) return const SizedBox.shrink();
                        final t = Duration(
                          minutes: int.parse(match.group(1)!),
                          seconds: double.parse(match.group(2)!).toInt(),
                        );
                        final text = match.group(3)!.trim();
                        final next = i + 1 < lines.length ? _lineTime(lines[i + 1]) : null;
                        final active = pos >= t && (next == null || pos < next);
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 6),
                          child: Text(
                            text,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: active ? 22 : 16,
                              fontWeight: active ? FontWeight.w800 : FontWeight.normal,
                              color: active ? c.accent : c.tertiaryText,
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
        ),
      ),
    );
  }

  Duration? _lineTime(String line) {
    final m = RegExp(r'\[(\d+):(\d+\.?\d*)\]').firstMatch(line);
    if (m == null) return null;
    return Duration(minutes: int.parse(m.group(1)!), seconds: double.parse(m.group(2)!).toInt());
  }

  void _queueSheet(MusicProvider provider, DzColors c) {
    final queue = provider.queue;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: c.card,
      builder: (ctx) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.6,
        builder: (_, controller) => Column(
          children: [
            const SizedBox(height: 12),
            Text('File d\'attente', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18, color: c.primaryText)),
            Expanded(
              child: ListView.builder(
                controller: controller,
                itemCount: queue.length,
                itemBuilder: (context, i) {
                  final s = queue[i];
                  final playing = provider.audioPlayer.currentIndex == i;
                  return ListTile(
                    leading: QueryArtworkWidget(
                      id: s.id,
                      type: ArtworkType.AUDIO,
                      nullArtworkWidget: Icon(Icons.music_note, color: c.accent),
                    ),
                    title: Text(s.title, style: TextStyle(color: c.primaryText)),
                    subtitle: Text(s.artist ?? '', style: TextStyle(color: c.secondaryText)),
                    trailing: playing ? Icon(Icons.equalizer_rounded, color: c.accent) : null,
                    onTap: () {
                      provider.audioPlayer.seek(Duration.zero, index: i);
                      Navigator.pop(ctx);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
