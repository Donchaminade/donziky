import 'package:donziker/providers/music_provider.dart';
import 'package:donziker/providers/theme_provider.dart';
import 'package:donziker/utils/song_utils.dart';
import 'package:donziker/widgets/circular_audio_progress.dart';
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
    return Consumer2<MusicProvider, ThemeProvider>(
      builder: (context, provider, theme, _) {
        final song = provider.currentSong;
        if (song == null) {
          return const Scaffold(body: Center(child: Text('Aucune chanson en lecture')));
        }

        final accent = theme.effectiveAccent(provider.dynamicAccentColor, useDynamic: provider.useDynamicAccent);

        return Scaffold(
          extendBodyBehindAppBar: true,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            leading: IconButton(
              icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 36, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
            actions: [
              if (provider.sleepTimerRemaining != null)
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: Center(
                    child: Text(
                      _format(provider.sleepTimerRemaining),
                      style: TextStyle(color: accent, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              IconButton(
                icon: Icon(
                  provider.karaokeMode ? Icons.mic_external_on : Icons.mic_none,
                  color: provider.karaokeMode ? accent : Colors.white70,
                ),
                tooltip: 'Mode karaoké',
                onPressed: provider.toggleKaraokeMode,
              ),
              IconButton(
                icon: const Icon(Icons.my_location, color: Colors.white70),
                tooltip: 'Localiser dans la liste',
                onPressed: () {
                  provider.requestLocateCurrentSong();
                  Navigator.pop(context);
                },
              ),
              IconButton(
                icon: const Icon(Icons.more_horiz, color: Colors.white),
                onPressed: () => showModalBottomSheet(
                  context: context,
                  backgroundColor: Colors.transparent,
                  builder: (_) => SongOptionsSheet(song: song),
                ),
              ),
            ],
          ),
          body: Stack(
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 600),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [accent.withValues(alpha: 0.55), Colors.black, Colors.black],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  children: [
                    const Spacer(flex: 2),
                    StreamBuilder<Duration>(
                      stream: provider.audioPlayer.positionStream,
                      builder: (context, snap) {
                        final pos = snap.data ?? Duration.zero;
                        final dur = provider.audioPlayer.duration ?? Duration.zero;
                        final progress = dur.inMilliseconds > 0
                            ? pos.inMilliseconds / dur.inMilliseconds
                            : 0.0;
                        final size = MediaQuery.of(context).size.width * 0.72;
                        return Hero(
                          tag: 'albumArt',
                          child: CircularAudioProgress(
                            progress: progress.clamp(0.0, 1.0),
                            size: size,
                            strokeWidth: 6,
                            activeColor: accent,
                            inactiveColor: Colors.white12,
                            onSeek: (p) {
                              if (dur.inMilliseconds > 0) {
                                provider.audioPlayer.seek(
                                  Duration(milliseconds: (dur.inMilliseconds * p).toInt()),
                                );
                              }
                            },
                            child: ClipOval(
                              child: SizedBox(
                                width: size - 28,
                                height: size - 28,
                                child: QueryArtworkWidget(
                                  id: song.id,
                                  type: ArtworkType.AUDIO,
                                  nullArtworkWidget: Container(
                                    color: Colors.white10,
                                    child: const Icon(Icons.music_note, size: 80, color: Colors.white24),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 8),
                    StreamBuilder<Duration>(
                      stream: provider.audioPlayer.positionStream,
                      builder: (context, snap) {
                        final pos = snap.data ?? Duration.zero;
                        final dur = provider.audioPlayer.duration ?? Duration.zero;
                        return Text(
                          '${_format(pos)} / ${_format(dur)}',
                          style: const TextStyle(color: Colors.white54, fontSize: 12),
                        );
                      },
                    ),
                    const Spacer(),
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(song.title,
                                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: Colors.white),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis),
                              Text(song.artist ?? 'Artiste inconnu',
                                  style: TextStyle(fontSize: 16, color: Colors.white.withValues(alpha: 0.6)),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: Icon(
                            provider.isFavorite(SongUtils.songId(song))
                                ? Icons.favorite_rounded
                                : Icons.favorite_border_rounded,
                            color: provider.isFavorite(SongUtils.songId(song)) ? accent : Colors.white70,
                            size: 30,
                          ),
                          onPressed: () => provider.toggleFavorite(SongUtils.songId(song)),
                        ),
                      ],
                    ),
                    if (provider.karaokeMode)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Text(
                          'Mode karaoké : passage ${provider.karaokeLeadSeconds} s avant la fin',
                          style: TextStyle(color: accent, fontSize: 12, fontWeight: FontWeight.w600),
                        ),
                      ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _revBtn('A', provider.pointA != null, provider.setPointA, accent),
                        const SizedBox(width: 12),
                        _revBtn('B', provider.pointB != null, provider.setPointB, accent),
                        IconButton(
                          icon: Icon(Icons.refresh, color: provider.isABLoopActive ? accent : Colors.white38),
                          onPressed: provider.clearABLoop,
                        ),
                      ],
                    ),
                    const Spacer(),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        IconButton(
                          icon: Icon(Icons.shuffle, color: provider.isShuffle ? accent : Colors.white38),
                          onPressed: provider.toggleShuffle,
                        ),
                        IconButton(icon: const Icon(Icons.skip_previous, size: 42, color: Colors.white), onPressed: provider.playPrevious),
                        GestureDetector(
                          onTap: () => provider.isPlaying ? provider.pause() : provider.play(),
                          child: Container(
                            width: 72,
                            height: 72,
                            decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                            child: Icon(provider.isPlaying ? Icons.pause : Icons.play_arrow, size: 44, color: Colors.black),
                          ),
                        ),
                        IconButton(icon: const Icon(Icons.skip_next, size: 42, color: Colors.white), onPressed: provider.playNext),
                        IconButton(
                          icon: Icon(
                            provider.repeatMode == RepeatMode.one ? Icons.repeat_one : Icons.repeat,
                            color: provider.repeatMode != RepeatMode.none ? accent : Colors.white38,
                          ),
                          onPressed: provider.cycleRepeatMode,
                        ),
                      ],
                    ),
                    const Spacer(),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _bottom(Icons.speed, 'Vitesse', () => _speedDialog(provider)),
                        _bottom(Icons.timer_outlined, 'Veille', () => _sleepDialog(provider)),
                        _bottom(Icons.lyrics, 'Paroles', () => _lyricsSheet(provider)),
                        _bottom(Icons.queue_music, 'File', () => _queueSheet(provider, accent)),
                        _bottom(
                          provider.karaokeMode ? Icons.mic : Icons.mic_none,
                          'Karaoké',
                          provider.toggleKaraokeMode,
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _revBtn(String label, bool active, VoidCallback onTap, Color accent) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: active ? accent : Colors.white10,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(label, style: TextStyle(fontWeight: FontWeight.bold, color: active ? Colors.black : Colors.white)),
      ),
    );
  }

  Widget _bottom(IconData icon, String label, VoidCallback onTap) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(icon: Icon(icon, color: Colors.white70), onPressed: onTap),
        Text(label, style: const TextStyle(color: Colors.white38, fontSize: 10)),
      ],
    );
  }

  void _speedDialog(MusicProvider provider) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Vitesse'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [0.5, 0.75, 1.0, 1.25, 1.5, 2.0]
              .map((s) => RadioListTile<double>(
                    title: Text('${s}x'),
                    value: s,
                    groupValue: provider.speed,
                    onChanged: (v) {
                      provider.setSpeed(v!);
                      Navigator.pop(ctx);
                    },
                  ))
              .toList(),
        ),
      ),
    );
  }

  void _sleepDialog(MusicProvider provider) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Minuterie'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ...([5, 10, 15, 30, 45, 60].map((m) => ListTile(
                  title: Text('$m minutes'),
                  onTap: () {
                    provider.setSleepTimer(Duration(minutes: m));
                    Navigator.pop(ctx);
                  },
                ))),
            ListTile(
              title: const Text('Fin du morceau'),
              onTap: () {
                provider.setSleepTimer(Duration.zero, endOfTrack: true);
                Navigator.pop(ctx);
              },
            ),
            if (provider.sleepTimerRemaining != null)
              ListTile(
                title: const Text('Annuler', style: TextStyle(color: Colors.redAccent)),
                onTap: () {
                  provider.cancelSleepTimer();
                  Navigator.pop(ctx);
                },
              ),
          ],
        ),
      ),
    );
  }

  void _lyricsSheet(MusicProvider provider) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        builder: (_, controller) => Container(
          decoration: const BoxDecoration(
            color: Color(0xFF121212),
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          padding: const EdgeInsets.all(20),
          child: provider.currentLyrics == null
              ? const Center(
                  child: Text(
                    'Aucun fichier .lrc trouvé.\nPlacez un fichier du même nom que le morceau à côté du fichier audio.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white54),
                  ),
                )
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
                              fontWeight: active ? FontWeight.bold : FontWeight.normal,
                              color: active ? Colors.white : Colors.white38,
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

  void _queueSheet(MusicProvider provider, Color accent) {
    final queue = provider.queue;
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1A1A1A),
      builder: (ctx) => Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text('File d\'attente (${queue.length})', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: queue.length,
              itemBuilder: (context, i) {
                final s = queue[i];
                final playing = provider.audioPlayer.currentIndex == i;
                return ListTile(
                  leading: QueryArtworkWidget(id: s.id, type: ArtworkType.AUDIO, nullArtworkWidget: const Icon(Icons.music_note)),
                  title: Text(s.title, maxLines: 1, overflow: TextOverflow.ellipsis),
                  subtitle: Text(s.artist ?? ''),
                  trailing: playing ? Icon(Icons.equalizer, color: accent) : null,
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
    );
  }
}
