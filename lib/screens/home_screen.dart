import 'package:donziker/providers/music_provider.dart';
import 'package:donziker/screens/favorites_screen.dart';
import 'package:donziker/screens/player_screen.dart';
import 'package:donziker/screens/video_player_screen.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:photo_manager_image_provider/photo_manager_image_provider.dart';
import 'package:provider/provider.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('DonZiker'),
        actions: [
          IconButton(
            icon: const Icon(Icons.favorite),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const FavoritesScreen(),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {}, 
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Music'),
            Tab(text: 'Videos'),
          ],
        ),
      ),
      body: Consumer<MusicProvider>(
        builder: (context, musicProvider, child) {
          if (!musicProvider.permissionState.isAuth) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text("Permissions not granted."),
                  ElevatedButton(
                    onPressed: () => PhotoManager.openSetting(),
                    child: const Text("Open Settings"),
                  )
                ],
              ),
            );
          }

          if (musicProvider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          return TabBarView(
            controller: _tabController,
            children: [
              _buildMusicList(musicProvider),
              _buildVideoList(musicProvider),
            ],
          );
        },
      ),
    );
  }

  Widget _buildMusicList(MusicProvider musicProvider) {
    if (musicProvider.songs.isEmpty) {
      return const Center(child: Text("No songs found."));
    }

    return ListView.builder(
      itemCount: musicProvider.songs.length,
      itemBuilder: (context, index) {
        final song = musicProvider.songs[index];
        return ListTile(
          leading: SizedBox(
            width: 56,
            height: 56,
            child: AssetEntityImage(
              song,
              isOriginal: false,
              thumbnailSize: const ThumbnailSize.square(200),
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return const Icon(Icons.music_note, color: Colors.white);
              },
            ),
          ),
          title: Text(song.title ?? "Unknown Title", maxLines: 1),
          subtitle: Text(song.title ?? "Unknown Title", maxLines: 1), // Using title as artist is not available
          onTap: () {
            musicProvider.setPlaylist(musicProvider.songs, index);
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const PlayerScreen(),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildVideoList(MusicProvider musicProvider) {
    if (musicProvider.videos.isEmpty) {
      return const Center(child: Text("No videos found."));
    }

    return ListView.builder(
      itemCount: musicProvider.videos.length,
      itemBuilder: (context, index) {
        final video = musicProvider.videos[index];
        return ListTile(
          leading: SizedBox(
            width: 56,
            height: 56,
            child: AssetEntityImage(
              video,
              isOriginal: false,
              thumbnailSize: const ThumbnailSize.square(200),
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return const Icon(Icons.videocam, color: Colors.white);
              },
            ),
          ),
          title: Text(video.title ?? "Unknown Title", maxLines: 1),
          subtitle: Text(""), // AssetEntity doesn't have an artist property
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => VideoPlayerScreen(video: video),
              ),
            );
          },
        );
      },
    );
  }
}