import 'package:donziker/providers/music_provider.dart';
import 'package:flutter/material.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:photo_manager_image_provider/photo_manager_image_provider.dart';
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
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          Consumer<MusicProvider>(
            builder: (context, provider, child) {
              final song = provider.currentSong;
              if (song == null) {
                return const SizedBox.shrink();
              }
              return IconButton(
                icon: Icon(
                  provider.isFavorite(song.id) // Use id for now, will fix later
                      ? Icons.favorite
                      : Icons.favorite_border,
                ),
                onPressed: () {
                  provider.toggleFavorite(song.id); // Use id for now, will fix later
                },
              );
            },
          ),
          Consumer<MusicProvider>(
            builder: (context, provider, child) {
              return TextButton(
                onPressed: () => _showSpeedDialog(context, provider),
                child: Text("${provider.speed}x", style: const TextStyle(color: Colors.white)),
              );
            },
          ),
        ],
      ),
      body: Consumer<MusicProvider>(
        builder: (context, provider, child) {
          final song = provider.currentSong;
          if (song == null) {
            return const Center(child: Text("Aucune chanson sélectionnée"));
          }
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Spacer(),
                // Artwork
                SizedBox(
                  height: 250,
                  width: 250,
                  child: AssetEntityImage(
                    song,
                    isOriginal: false,
                    thumbnailSize: const ThumbnailSize.square(250),
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        height: 250,
                        width: 250,
                        decoration: BoxDecoration(
                          color: Colors.grey.withAlpha((255 * 0.2).round()),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.music_note, size: 100, color: Colors.white),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 32),
                // Title and Artist
                Text(
                  song.title ?? "Unknown Title",
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  song.title ?? "Unknown Title",
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 16, color: Colors.white.withAlpha((255 * 0.7).round())),
                ),
                const Spacer(),
                // Slider
                StreamBuilder<Duration?>(
                  stream: provider.audioPlayer.positionStream,
                  builder: (context, snapshot) {
                    final position = snapshot.data ?? Duration.zero;
                    final duration = provider.audioPlayer.duration ?? Duration.zero;
                    return Column(
                      children: [
                        Slider(
                          value: position.inSeconds.toDouble().clamp(0.0, duration.inSeconds.toDouble()),
                          onChanged: (value) {
                            provider.audioPlayer.seek(Duration(seconds: value.toInt()));
                          },
                          min: 0,
                          max: duration.inSeconds.toDouble() + 1.0, // Add a small buffer
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(_formatDuration(position)),
                              Text(_formatDuration(duration)),
                            ],
                          ),
                        )
                      ],
                    );
                  },
                ),
                // Controls
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    IconButton(
                      icon: Icon(
                        Icons.shuffle,
                        color: provider.isShuffle ? Colors.deepPurple : Colors.white,
                      ),
                      onPressed: provider.toggleShuffle,
                    ),
                    IconButton(
                      icon: const Icon(Icons.skip_previous, size: 40),
                      onPressed: provider.playPrevious,
                    ),
                    StreamBuilder<bool>(
                      stream: provider.audioPlayer.playingStream,
                      builder: (context, snapshot) {
                        final isPlaying = snapshot.data ?? false;
                        return IconButton(
                          icon: Icon(
                            isPlaying ? Icons.pause_circle_filled : Icons.play_circle_filled,
                            size: 70,
                          ),
                          onPressed: isPlaying ? provider.pause : provider.play,
                        );
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.skip_next, size: 40),
                      onPressed: provider.playNext,
                    ),
                    IconButton(
                      icon: Icon(
                        provider.repeatMode == RepeatMode.one
                            ? Icons.repeat_one
                            : Icons.repeat,
                        color: provider.repeatMode != RepeatMode.none
                            ? Colors.deepPurple
                            : Colors.white,
                      ),
                      onPressed: provider.cycleRepeatMode,
                    ),
                  ],
                ),
                const Spacer(),
              ],
            ),
          );
        },
      ),
    );
  }

  void _showSpeedDialog(BuildContext context, MusicProvider provider) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Vitesse de lecture"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              RadioListTile<double>(
                title: const Text("0.5x"),
                value: 0.5,
                groupValue: provider.speed,
                onChanged: (value) {
                  provider.setSpeed(value!);
                  Navigator.pop(context);
                },
              ),
              RadioListTile<double>(
                title: const Text("1.0x (Normal)"),
                value: 1.0,
                groupValue: provider.speed,
                onChanged: (value) {
                  provider.setSpeed(value!);
                  Navigator.pop(context);
                },
              ),
              RadioListTile<double>(
                title: const Text("1.5x"),
                value: 1.5,
                groupValue: provider.speed,
                onChanged: (value) {
                  provider.setSpeed(value!);
                  Navigator.pop(context);
                },
              ),
              RadioListTile<double>(
                title: const Text("2.0x"),
                value: 2.0,
                groupValue: provider.speed,
                onChanged: (value) {
                  provider.setSpeed(value!);
                  Navigator.pop(context);
                },
              ),
            ],
          ),
        );
      },
    );
  }
}
