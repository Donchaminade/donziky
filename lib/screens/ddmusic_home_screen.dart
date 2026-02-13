import 'package:donziker/screens/settings_screen.dart';
import 'package:donziker/providers/music_provider.dart';
import 'package:donziker/providers/theme_provider.dart';
import 'package:donziker/screens/player_screen.dart';
import 'package:flutter/material.dart';
import 'package:on_audio_query/on_audio_query.dart';
import 'package:provider/provider.dart';

class DdmusicHomeScreen extends StatefulWidget {
  const DdmusicHomeScreen({super.key});

  @override
  State<DdmusicHomeScreen> createState() => _DdmusicHomeScreenState();
}

class _DdmusicHomeScreenState extends State<DdmusicHomeScreen> {
  int _selectedTabIndex = 0;

  @override
  void initState() {
    super.initState();
    // Demander les permissions une fois que l'écran est monté
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<MusicProvider>(context, listen: false).checkAndRequestPermissions();
    });
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final Color accentColor = themeProvider.accentColor;

    return Scaffold(
      body: Consumer<MusicProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!provider.permissionGranted) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text("Permission d'accès aux fichiers requise"),
                  ElevatedButton(
                    onPressed: provider.checkAndRequestPermissions,
                    child: const Text("Autoriser"),
                  ),
                ],
              ),
            );
          }

          final songs = provider.filteredSongs;
          final allSongs = provider.songs;
          final favorites = allSongs.where((s) => provider.favorites.contains(s.id.toString())).toList();
          final recentlyPlayed = provider.recentlyPlayed;

          return CustomScrollView(
            slivers: [
              _buildSliverAppBar(accentColor, provider),
              SliverToBoxAdapter(
                child: Column(
                  children: [
                    if (provider.searchQuery.isEmpty) ...[
                      if (favorites.isNotEmpty) ...[
                        _buildSectionTitle('Mes favoris'),
                        _buildFavoriteSongsSection(favorites, accentColor),
                      ],
                      if (recentlyPlayed.isNotEmpty) ...[
                        const SizedBox(height: 20),
                        _buildSectionTitle('Écoutées en dernier'),
                        _buildHorizontalSongList(recentlyPlayed, accentColor),
                      ],
                      const SizedBox(height: 20),
                      _buildSectionTitle('Toutes les chansons'),
                    ] else ...[
                      _buildSectionTitle('Résultats de recherche'),
                    ],
                    _buildVerticalSongList(songs, accentColor),
                    const SizedBox(height: 100), // Space for MiniPlayer
                  ],
                ),
              ),
            ],
          );
        },
      ),
      bottomSheet: const MiniPlayer(),
    );
  }

  Widget _buildSliverAppBar(Color accentColor, MusicProvider provider) {
    return SliverAppBar(
      expandedHeight: 280,
      floating: false,
      pinned: true,
      backgroundColor: Colors.black,
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          fit: StackFit.expand,
          children: [
            // Hero Banner Background
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    accentColor.withOpacity(0.8),
                    Colors.black,
                  ],
                ),
              ),
            ),
            // Abstract decorations
            Positioned(
              top: -50,
              right: -50,
              child: Container(
                width: 200,
                height: 200,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Bonjour,",
                    style: TextStyle(fontSize: 18, color: Colors.white70),
                  ),
                  const Text(
                    "Découvrez votre musique",
                    style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  const SizedBox(height: 20),
                  _buildSearchBar(provider),
                ],
              ),
            ),
          ],
        ),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.settings_outlined),
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const SettingsScreen()),
          ),
        ),
      ],
    );
  }

  Widget _buildSearchBar(MusicProvider provider) {
    return Container(
      height: 50,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(15),
      ),
      child: TextField(
        onChanged: provider.updateSearchQuery,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          hintText: "Rechercher une musique, un artiste...",
          hintStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
          prefixIcon: const Icon(Icons.search, color: Colors.white70),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 12),
        ),
      ),
    );
  }

  Widget _buildNavigationTabs(Color accentColor) {
    final List<String> tabs = ['Pour vous', 'Chansons', 'Playlist', 'Dossiers', 'Albums'];
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      child: Row(
        children: tabs.asMap().entries.map((entry) {
          final index = entry.key;
          final text = entry.value;
          final bool isActive = index == _selectedTabIndex;
          return GestureDetector(
            onTap: () => setState(() => _selectedTabIndex = index),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
              margin: const EdgeInsets.symmetric(horizontal: 5),
              decoration: BoxDecoration(
                color: isActive ? accentColor : Colors.transparent,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isActive ? accentColor : Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                ),
              ),
              child: Text(
                text,
                style: TextStyle(
                  color: isActive ? Theme.of(context).colorScheme.onPrimary : Theme.of(context).colorScheme.onSurface,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const Icon(Icons.chevron_right),
        ],
      ),
    );
  }

  Widget _buildFavoriteSongsSection(List<SongModel> songs, Color accentColor) {
    return SizedBox(
      height: 160,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: (songs.length / 2).ceil(),
        itemBuilder: (context, index) {
          final firstIndex = index * 2;
          final secondIndex = firstIndex + 1;
          return Container(
            width: 250,
            margin: const EdgeInsets.symmetric(horizontal: 8),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildSongCard(songs[firstIndex], accentColor),
                if (secondIndex < songs.length)
                  _buildSongCard(songs[secondIndex], accentColor),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSongCard(SongModel song, Color accentColor) {
    final provider = Provider.of<MusicProvider>(context, listen: false);
    return InkWell(
      onTap: () => provider.setPlaylist([song], 0),
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            QueryArtworkWidget(
              id: song.id,
              type: ArtworkType.AUDIO,
              nullArtworkWidget: const Icon(Icons.music_note, size: 40),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(song.title, style: const TextStyle(fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis),
                  Text(song.artist ?? '<unknown>', style: const TextStyle(fontSize: 12, color: Colors.grey), overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
            IconButton(
              icon: Icon(Icons.play_arrow, color: accentColor),
              onPressed: () => provider.setPlaylist([song], 0),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHorizontalSongList(List<SongModel> songs, Color accentColor) {
    return SizedBox(
      height: 200,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: songs.length,
        itemBuilder: (context, index) {
          final song = songs[index];
          return _buildSquareSongCard(song, index, songs, accentColor);
        },
      ),
    );
  }

  Widget _buildVerticalSongList(List<SongModel> songs, Color accentColor) {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: songs.length,
      itemBuilder: (context, index) {
        final song = songs[index];
        return ListTile(
          leading: QueryArtworkWidget(
            id: song.id,
            type: ArtworkType.AUDIO,
            nullArtworkWidget: const Icon(Icons.music_note),
          ),
          title: Text(song.title, overflow: TextOverflow.ellipsis),
          subtitle: Text(song.artist ?? '<unknown>', overflow: TextOverflow.ellipsis),
          trailing: IconButton(
            icon: const Icon(Icons.more_vert),
            onPressed: () {},
          ),
          onTap: () => Provider.of<MusicProvider>(context, listen: false).setPlaylist(songs, index),
        );
      },
    );
  }

  Widget _buildSquareSongCard(SongModel song, int index, List<SongModel> playlist, Color accentColor) {
    return Container(
      width: 150,
      margin: const EdgeInsets.symmetric(horizontal: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            children: [
              Container(
                width: 150,
                height: 150,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: QueryArtworkWidget(
                    id: song.id,
                    type: ArtworkType.AUDIO,
                    artworkWidth: 150,
                    artworkHeight: 150,
                    nullArtworkWidget: const Center(child: Icon(Icons.music_note, size: 80)),
                  ),
                ),
              ),
              Positioned(
                bottom: 5,
                right: 5,
                child: Container(
                  decoration: BoxDecoration(color: Colors.black54, shape: BoxShape.circle),
                  child: IconButton(
                    icon: Icon(Icons.play_arrow, color: accentColor),
                    onPressed: () => Provider.of<MusicProvider>(context, listen: false).setPlaylist(playlist, index),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 5),
          Text(song.title, style: const TextStyle(fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis),
          Text(song.artist ?? '<unknown>', style: const TextStyle(fontSize: 12, color: Colors.grey), overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }
}

class MiniPlayer extends StatelessWidget {
  const MiniPlayer({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<MusicProvider>(
      builder: (context, provider, child) {
        final song = provider.currentSong;
        if (song == null) return const SizedBox.shrink();

        return InkWell(
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const PlayerScreen())),
          child: Container(
            height: 70,
            margin: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.grey[900],
              borderRadius: BorderRadius.circular(12),
              boxShadow: [BoxShadow(color: Colors.black54, blurRadius: 10, offset: Offset(0, 4))],
            ),
            child: Row(
              children: [
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: QueryArtworkWidget(
                      id: song.id,
                      type: ArtworkType.AUDIO,
                      artworkWidth: 54,
                      artworkHeight: 54,
                      nullArtworkWidget: const Icon(Icons.music_note),
                    ),
                  ),
                ),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(song.title, style: const TextStyle(fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis),
                      Text(song.artist ?? '<unknown>', style: const TextStyle(fontSize: 12, color: Colors.grey), overflow: TextOverflow.ellipsis),
                    ],
                  ),
                ),
                IconButton(
                  icon: Icon(provider.isPlaying ? Icons.pause : Icons.play_arrow),
                  onPressed: () => provider.isPlaying ? provider.pause() : provider.play(),
                ),
                IconButton(
                  icon: const Icon(Icons.skip_next),
                  onPressed: provider.playNext,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}