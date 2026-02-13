import 'package:donziker/providers/music_provider.dart';
import 'package:donziker/providers/theme_provider.dart';
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
          icon: const Icon(Icons.keyboard_arrow_down, size: 30),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.more_vert),
            onPressed: () => _showMoreOptions(context),
          ),
        ],
      ),
      body: Consumer<MusicProvider>(
        builder: (context, provider, child) {
          final song = provider.currentSong;
          if (song == null) {
            return const Center(child: Text("Aucune chanson sélectionnée"));
          }

          return Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  accentColor.withOpacity(0.4),
                  Colors.black,
                ],
              ),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Column(
              children: [
                const SizedBox(height: 100),
                // Artwork
                Center(
                  child: Hero(
                    tag: 'artwork_${song.id}',
                    child: Container(
                      height: 300,
                      width: 300,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.5),
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: QueryArtworkWidget(
                          id: song.id,
                          type: ArtworkType.AUDIO,
                          artworkHeight: 300,
                          artworkWidth: 300,
                          nullArtworkWidget: Container(
                            color: Colors.grey[800],
                            child: const Icon(Icons.music_note, size: 100, color: Colors.white),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 48),
                // Title and Artist
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            song.title,
                            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            song.artist ?? "Unknown Artist",
                            style: TextStyle(fontSize: 18, color: Colors.white70),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: Icon(
                        provider.isFavorite(song.id.toString()) ? Icons.favorite : Icons.favorite_border,
                        color: provider.isFavorite(song.id.toString()) ? accentColor : Colors.white,
                        size: 30,
                      ),
                      onPressed: () => provider.toggleFavorite(song.id.toString()),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
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
                            trackHeight: 4,
                            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                            overlayShape: const RoundSliderOverlayShape(overlayRadius: 14),
                            activeTrackColor: Colors.white,
                            inactiveTrackColor: Colors.white24,
                            thumbColor: Colors.white,
                          ),
                          child: Slider(
                            value: position.inSeconds.toDouble().clamp(0.0, duration.inSeconds.toDouble()),
                            onChanged: (value) => provider.audioPlayer.seek(Duration(seconds: value.toInt())),
                            min: 0,
                            max: duration.inSeconds.toDouble() + 0.1,
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(_formatDuration(position), style: const TextStyle(fontSize: 12, color: Colors.white70)),
                              Text(_formatDuration(duration), style: const TextStyle(fontSize: 12, color: Colors.white70)),
                            ],
                          ),
                        ),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 16),
                // Revision Mode Controls (A-B)
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildRevisionButton(
                      label: "A",
                      isActive: provider.pointA != null,
                      onPressed: provider.setPointA,
                      accentColor: accentColor,
                    ),
                    const SizedBox(width: 20),
                    _buildRevisionButton(
                      label: "B",
                      isActive: provider.pointB != null,
                      onPressed: provider.setPointB,
                      accentColor: accentColor,
                    ),
                    const SizedBox(width: 20),
                    IconButton(
                      icon: Icon(Icons.replay, color: provider.isABLoopActive ? accentColor : Colors.white54),
                      onPressed: provider.clearABLoop,
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // Main Controls
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    IconButton(
                      icon: Icon(Icons.shuffle, color: provider.isShuffle ? accentColor : Colors.white),
                      onPressed: provider.toggleShuffle,
                    ),
                    IconButton(
                      icon: const Icon(Icons.skip_previous, size: 45),
                      onPressed: provider.playPrevious,
                    ),
                    Container(
                      decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                      child: IconButton(
                        icon: Icon(provider.isPlaying ? Icons.pause : Icons.play_arrow, size: 45, color: Colors.black),
                        onPressed: provider.isPlaying ? provider.pause : provider.play,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.skip_next, size: 45),
                      onPressed: provider.playNext,
                    ),
                    IconButton(
                      icon: Icon(
                        provider.repeatMode == RepeatMode.one ? Icons.repeat_one : Icons.repeat,
                        color: provider.repeatMode != RepeatMode.none ? accentColor : Colors.white,
                      ),
                      onPressed: provider.cycleRepeatMode,
                    ),
                  ],
                ),
                const Spacer(),
                // Bottom Icons (Speed, Sleep Timer, Lyrics, Queue)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.speed),
                      onPressed: () => _showSpeedDialog(context, provider),
                      tooltip: "Vitesse",
                    ),
                    IconButton(
                      icon: const Icon(Icons.timer_outlined),
                      onPressed: () => _showSleepTimerDialog(context, provider),
                      tooltip: "Minuterie",
                    ),
                    IconButton(
                      icon: const Icon(Icons.lyrics_outlined),
                      onPressed: () => _showLyricsBottomSheet(context, provider),
                      tooltip: "Paroles",
                    ),
                    IconButton(
                      icon: const Icon(Icons.queue_music),
                      onPressed: () => _showQueueBottomsheet(context, provider, accentColor),
                      tooltip: "File d'attente",
                    ),
                  ],
                ),
                const SizedBox(height: 40),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildRevisionButton({required String label, required bool isActive, required VoidCallback onPressed, required Color accentColor}) {
    return InkWell(
      onTap: onPressed,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          border: Border.all(color: isActive ? accentColor : Colors.white54),
          borderRadius: BorderRadius.circular(20),
          color: isActive ? accentColor.withOpacity(0.2) : Colors.transparent,
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isActive ? accentColor : Colors.white54,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  void _showMoreOptions(BuildContext context) {
    // Show a bottom sheet with options like 'Add to playlist', 'Share', etc.
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
