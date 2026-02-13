import 'package:donziker/providers/music_provider.dart';
import 'package:donziker/providers/theme_provider.dart';
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
  String _formatDuration(Duration? duration) {
    if (duration == null) return "0:00";
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    String twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60));
    String twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60));
    return "$twoDigitMinutes:$twoDigitSeconds";
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final accentColor = themeProvider.accentColor;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 36, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.more_horiz_rounded, color: Colors.white),
            onPressed: () => _showMoreOptions(context),
          ),
        ],
      ),
      body: Consumer<MusicProvider>(
        builder: (context, provider, child) {
          final song = provider.currentSong;
          if (song == null) return const Center(child: Text("Aucune chanson"));

          final dynamicColor = provider.currentAccentColor;

          return Stack(
            children: [
              // Dynamic Gradient Background
              AnimatedContainer(
                duration: const Duration(milliseconds: 800),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      dynamicColor.withOpacity(0.6),
                      Colors.black,
                      Colors.black,
                    ],
                  ),
                ),
              ),
              
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 28.0),
                child: Column(
                  children: [
                    const Spacer(flex: 2),
                    // Immersive Artwork
                    Center(
                      child: Hero(
                        tag: 'albumArt',
                        child: Container(
                          height: MediaQuery.of(context).size.width * 0.8,
                          width: MediaQuery.of(context).size.width * 0.8,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(28),
                            boxShadow: [
                              BoxShadow(
                                color: dynamicColor.withOpacity(0.3),
                                blurRadius: 40,
                                spreadRadius: 5,
                                offset: const Offset(0, 20),
                              ),
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(28),
                            child: QueryArtworkWidget(
                              id: song.id,
                              type: ArtworkType.AUDIO,
                              artworkHeight: 500,
                              artworkWidth: 500,
                              nullArtworkWidget: Container(
                                color: Colors.white.withOpacity(0.05),
                                child: const Icon(Icons.music_note, size: 120, color: Colors.white24),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const Spacer(flex: 1),
                    
                    // Song Details
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                song.title,
                                style: const TextStyle(
                                  fontSize: 26, 
                                  fontWeight: FontWeight.w900, 
                                  color: Colors.white,
                                  letterSpacing: -0.5,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                song.artist ?? "Artiste inconnu",
                                style: TextStyle(
                                  fontSize: 18, 
                                  color: Colors.white.withOpacity(0.6),
                                  fontWeight: FontWeight.w400,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: Icon(
                            provider.isFavorite(song.id.toString()) ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                            color: provider.isFavorite(song.id.toString()) ? dynamicColor : Colors.white70,
                            size: 32,
                          ),
                          onPressed: () => provider.toggleFavorite(song.id.toString()),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 30),
                    
                    // Slider
                    StreamBuilder<Duration?>(
                      stream: provider.audioPlayer.positionStream,
                      builder: (context, snapshot) {
                        final position = snapshot.data ?? Duration.zero;
                        final duration = provider.audioPlayer.duration ?? Duration.zero;
                        return Column(
                          children: [
                            SliderTheme(
                              data: SliderTheme.of(context).copyWith(
                                trackHeight: 6,
                                thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 0), // Hidden thumb for sleek look
                                activeTrackColor: Colors.white,
                                inactiveTrackColor: Colors.white10,
                                overlayShape: SliderComponentShape.noOverlay,
                              ),
                              child: Slider(
                                value: position.inSeconds.toDouble().clamp(0.0, duration.inSeconds.toDouble()),
                                onChanged: (value) => provider.audioPlayer.seek(Duration(seconds: value.toInt())),
                                min: 0,
                                max: duration.inSeconds.toDouble() + 0.1,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(_formatDuration(position), style: TextStyle(fontSize: 12, color: Colors.white.withOpacity(0.5), fontWeight: FontWeight.bold)),
                                Text(_formatDuration(duration), style: TextStyle(fontSize: 12, color: Colors.white.withOpacity(0.5), fontWeight: FontWeight.bold)),
                              ],
                            ),
                          ],
                        );
                      },
                    ),
                    
                    const SizedBox(height: 20),
                    
                    // Revision (A-B)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(30),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _buildRevisionButton(
                            label: "A",
                            isActive: provider.pointA != null,
                            onPressed: provider.setPointA,
                            accentColor: dynamicColor,
                          ),
                          const SizedBox(width: 15),
                          _buildRevisionButton(
                            label: "B",
                            isActive: provider.pointB != null,
                            onPressed: provider.setPointB,
                            accentColor: dynamicColor,
                          ),
                          const SizedBox(width: 15),
                          IconButton(
                            icon: Icon(Icons.refresh_rounded, color: provider.isABLoopActive ? dynamicColor : Colors.white38, size: 22),
                            onPressed: provider.clearABLoop,
                          ),
                        ],
                      ),
                    ),
                    
                    const Spacer(),
                    
                    // Main Controls
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        IconButton(
                          icon: Icon(Icons.shuffle_rounded, color: provider.isShuffle ? dynamicColor : Colors.white38, size: 28),
                          onPressed: provider.toggleShuffle,
                        ),
                        IconButton(
                          icon: const Icon(Icons.skip_previous_rounded, size: 48, color: Colors.white),
                          onPressed: provider.playPrevious,
                        ),
                        GestureDetector(
                          onTap: provider.isPlaying ? provider.pause : provider.play,
                          child: Container(
                            height: 85,
                            width: 85,
                            decoration: const BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              provider.isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                              size: 54,
                              color: Colors.black,
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.skip_next_rounded, size: 48, color: Colors.white),
                          onPressed: provider.playNext,
                        ),
                        IconButton(
                          icon: Icon(
                            provider.repeatMode == RepeatMode.one ? Icons.repeat_one_rounded : Icons.repeat_rounded,
                            color: provider.repeatMode != RepeatMode.none ? dynamicColor : Colors.white38,
                            size: 28,
                          ),
                          onPressed: provider.cycleRepeatMode,
                        ),
                      ],
                    ),
                    
                    const Spacer(),
                    
                    // Bottom Navigation
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _BottomIconButton(icon: Icons.speed_rounded, label: "Vitesse", onTap: () => _showSpeedDialog(context, provider)),
                        _BottomIconButton(icon: Icons.timer_outlined, label: "Veille", onTap: () => _showSleepTimerDialog(context, provider)),
                        _BottomIconButton(icon: Icons.lyrics_rounded, label: "Paroles", onTap: () => _showLyricsBottomSheet(context, provider)),
                        _BottomIconButton(icon: Icons.playlist_play_rounded, label: "File", onTap: () => _showQueueBottomsheet(context, provider, dynamicColor)),
                      ],
                    ),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildRevisionButton({required String label, required bool isActive, required VoidCallback onPressed, required Color accentColor}) {
    return InkWell(
      onTap: onPressed,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: isActive ? accentColor : Colors.white.withOpacity(0.1),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isActive ? Colors.black : Colors.white,
            fontWeight: FontWeight.w900,
            fontSize: 16,
          ),
        ),
      ),
    );
  }

  void _showMoreOptions(BuildContext context) {
    final provider = Provider.of<MusicProvider>(context, listen: false);
    final song = provider.currentSong;
    if (song != null) {
      showModalBottomSheet(
        context: context,
        backgroundColor: Colors.transparent,
        isScrollControlled: true,
        builder: (context) => SongOptionsSheet(song: song),
      );
    }
  }

  void _showSpeedDialog(BuildContext context, MusicProvider provider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Vitesse de lecture"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [0.5, 0.75, 1.0, 1.25, 1.5, 2.0].map((s) => RadioListTile<double>(
            title: Text("${s}x"),
            value: s,
            groupValue: provider.speed,
            onChanged: (v) {
              provider.setSpeed(v!);
              Navigator.pop(context);
            },
          )).toList(),
        ),
      ),
    );
  }

  void _showSleepTimerDialog(BuildContext context, MusicProvider provider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Minuterie de veille"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [5, 10, 15, 30, 45, 60].map((m) => ListTile(
            title: Text("$m minutes"),
            onTap: () {
              provider.setSleepTimer(Duration(minutes: m));
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Minuterie réglée sur $m minutes")));
            },
          )).toList(),
        ),
      ),
    );
  }

  void _showLyricsBottomSheet(BuildContext context, MusicProvider provider) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.75,
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.95),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(25)),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        child: Column(
          children: [
            Container(
              width: 40,
              height: 5,
              decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(10)),
            ),
            const SizedBox(height: 20),
            const Text(
              "Paroles",
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: provider.currentLyrics == null
                  ? const Center(child: Text("Aucune parole disponible", style: TextStyle(color: Colors.white54)))
                  : StreamBuilder<Duration?>(
                      stream: provider.audioPlayer.positionStream,
                      builder: (context, snapshot) {
                        final position = snapshot.data ?? Duration.zero;
                        final lines = provider.currentLyrics!.split('\n');
                        
                        return ListView.builder(
                          itemCount: lines.length,
                          itemBuilder: (context, index) {
                            final line = lines[index];
                            // Basic LRC parsing: [00:00.00]Text
                            final match = RegExp(r'\[(\d+):(\d+\.\d+)\](.*)').firstMatch(line);
                            if (match == null) return const SizedBox.shrink();

                            final min = int.parse(match.group(1)!);
                            final sec = double.parse(match.group(2)!);
                            final text = match.group(3)!;
                            final time = Duration(minutes: min, seconds: sec.toInt(), milliseconds: ((sec - sec.toInt()) * 1000).toInt());

                            final isCurrent = position >= time && 
                                (index == lines.length - 1 || 
                                 _getTimeOfLine(lines[index + 1]) > position);

                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 8.0),
                              child: Text(
                                text,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: isCurrent ? 24 : 18,
                                  fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
                                  color: isCurrent ? Colors.white : Colors.white38,
                                ),
                              ),
                            );
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

  Duration _getTimeOfLine(String line) {
    final match = RegExp(r'\[(\d+):(\d+\.\d+)\]').firstMatch(line);
    if (match == null) return Duration.zero;
    final min = int.parse(match.group(1)!);
    final sec = double.parse(match.group(2)!);
    return Duration(minutes: min, seconds: sec.toInt(), milliseconds: ((sec - sec.toInt()) * 1000).toInt());
  }

  void _showQueueBottomsheet(BuildContext context, MusicProvider provider, Color accentColor) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.grey[900],
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => Column(
        children: [
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text("À suivre", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: provider.songs.length,
              itemBuilder: (context, index) {
                final song = provider.songs[index];
                return ListTile(
                  leading: QueryArtworkWidget(id: song.id, type: ArtworkType.AUDIO, nullArtworkWidget: const Icon(Icons.music_note)),
                  title: Text(song.title, maxLines: 1, overflow: TextOverflow.ellipsis),
                  subtitle: Text(song.artist ?? "Unknown"),
                  trailing: index == provider.audioPlayer.currentIndex ? Icon(Icons.bar_chart, color: accentColor) : null,
                  onTap: () {
                    provider.audioPlayer.seek(Duration.zero, index: index);
                    Navigator.pop(context);
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

class _BottomIconButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _BottomIconButton({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          icon: Icon(icon, color: Colors.white70, size: 26),
          onPressed: onTap,
        ),
        Text(label, style: const TextStyle(color: Colors.white38, fontSize: 10, fontWeight: FontWeight.bold)),
      ],
    );
  }
}
