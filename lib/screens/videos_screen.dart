import 'package:donziker/providers/music_provider.dart';
import 'package:donziker/screens/video_player_screen.dart';
import 'package:flutter/material.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:photo_manager_image_provider/photo_manager_image_provider.dart';
import 'package:provider/provider.dart';

class VideosScreen extends StatelessWidget {
  const VideosScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final videos = context.watch<MusicProvider>().videos;
    if (videos.isEmpty) {
      return const Center(child: Text('Aucune vidéo locale trouvée'));
    }
    return GridView.builder(
      padding: const EdgeInsets.all(8),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.85,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemCount: videos.length,
      itemBuilder: (context, i) {
        final video = videos[i];
        return GestureDetector(
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => VideoPlayerScreen(videos: videos, initialIndex: i),
            ),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Stack(
              fit: StackFit.expand,
              children: [
                AssetEntityImage(video, isOriginal: false, thumbnailSize: const ThumbnailSize(300, 300), fit: BoxFit.cover),
                const Positioned(
                  right: 8,
                  bottom: 8,
                  child: Icon(Icons.play_circle_fill, color: Colors.white, size: 36),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
