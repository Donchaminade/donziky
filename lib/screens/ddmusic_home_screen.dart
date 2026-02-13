import 'dart:ui';
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
              
              if (provider.searchQuery.isEmpty) ...[
                // Favorites Section
                if (favorites.isNotEmpty) ...[
                  SliverToBoxAdapter(child: _buildSectionTitle('Mes favoris')),
                  SliverToBoxAdapter(child: _buildFavoriteSongsSection(favorites, accentColor)),
                ],
                
                // Recently Played Section
                if (recentlyPlayed.isNotEmpty) ...[
                  const SliverToBoxAdapter(child: SizedBox(height: 20)),
                  SliverToBoxAdapter(child: _buildSectionTitle('Écoutées en dernier')),
                  SliverToBoxAdapter(child: _buildHorizontalSongList(recentlyPlayed, accentColor)),
                ],
                
                const SliverToBoxAdapter(child: SizedBox(height: 20)),
                SliverToBoxAdapter(child: _buildSectionTitle('Toutes les chansons')),
              ] else ...[
                SliverToBoxAdapter(child: _buildSectionTitle('Résultats de recherche')),
              ],

              // Main Song List (Virtualized)
              _buildSliverSongList(songs, accentColor),
              
              const SliverToBoxAdapter(child: SizedBox(height: 100)), // Space for MiniPlayer
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
                   ShaderMask(
                    shaderCallback: (bounds) => LinearGradient(
                      colors: [Colors.white, Colors.white.withOpacity(0.5)],
                    ).createShader(bounds),
                    child: const Text(
                      "Bonjour,",
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w300, color: Colors.white),
                    ),
                  ),
                  const Text(
                    "Découvrez votre musique",
                    style: TextStyle(fontSize: 32, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: -0.5),
                  ),
                  const SizedBox(height: 25),
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
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          height: 60,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withOpacity(0.1)),
          ),
          child: TextField(
            onChanged: provider.updateSearchQuery,
            onTapOutside: (event) => FocusScope.of(context).unfocus(),
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: "Rechercher une musique, un artiste...",
              hintStyle: TextStyle(color: Colors.white.withOpacity(0.4)),
              prefixIcon: const Icon(Icons.search, color: Colors.white70),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(vertical: 18, horizontal: 20),
            ),
          ),
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
      height: 180,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        itemCount: (songs.length / 2).ceil(),
        itemBuilder: (context, index) {
          final firstIndex = index * 2;
          final secondIndex = firstIndex + 1;
          return Container(
            width: 280,
            margin: const EdgeInsets.symmetric(horizontal: 8),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
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
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface.withOpacity(0.5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white10),
      ),
      child: ListTile(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        leading: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: QueryArtworkWidget(
            id: song.id,
            type: ArtworkType.AUDIO,
            nullArtworkWidget: const Icon(Icons.music_note, size: 40),
            artworkBorder: BorderRadius.circular(8),
            artworkQuality: FilterQuality.low,
            size: 150, // Optimize for memory
          ),
        ),
        title: Text(song.title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13), overflow: TextOverflow.ellipsis),
        subtitle: Text(song.artist ?? '<unknown>', style: const TextStyle(fontSize: 11, color: Colors.grey), overflow: TextOverflow.ellipsis),
        trailing: Container(
          decoration: BoxDecoration(
            color: accentColor.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: IconButton(
            icon: Icon(Icons.play_arrow, color: accentColor, size: 20),
            onPressed: () => provider.setPlaylist([song], 0),
          ),
        ),
        onTap: () => provider.setPlaylist([song], 0),
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

  Widget _buildSliverSongList(List<SongModel> songs, Color accentColor) {
    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          final song = songs[index];
          return ListTile(
            leading: QueryArtworkWidget(
              id: song.id,
              type: ArtworkType.AUDIO,
              nullArtworkWidget: const Icon(Icons.music_note),
              artworkBorder: BorderRadius.circular(5),
              artworkQuality: FilterQuality.low,
              size: 100,
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
        childCount: songs.length,
      ),
    );
  }

  Widget _buildVerticalSongList(List<SongModel> songs, Color accentColor) {
    return const SliverToBoxAdapter(child: SizedBox.shrink());
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
                    artworkBorder: BorderRadius.circular(10),
                    artworkQuality: FilterQuality.low,
                    size: 150,
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

        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                child: GestureDetector(
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const PlayerScreen())),
                  child: Container(
                    height: 75,
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.6),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: Colors.white.withOpacity(0.15), width: 0.5),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.4),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        )
                      ],
                    ),
                    child: Row(
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: Hero(
                            tag: 'albumArt',
                            child: Container(
                              width: 50,
                              height: 50,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black38,
                                    blurRadius: 8,
                                    offset: Offset(0, 4),
                                  )
                                ],
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: QueryArtworkWidget(
                                  id: song.id,
                                  type: ArtworkType.AUDIO,
                                  nullArtworkWidget: const Icon(Icons.music_note, color: Colors.white),
                                ),
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                song.title,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                song.artist ?? '<unknown>',
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.6),
                                  fontSize: 12,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        _PlayerControl(
                          icon: provider.isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                          onPressed: () => provider.isPlaying ? provider.pause() : provider.play(),
                          padding: 4,
                        ),
                        _PlayerControl(
                          icon: Icons.skip_next_rounded,
                          onPressed: provider.playNext,
                        ),
                        const SizedBox(width: 8),
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

class _PlayerControl extends StatelessWidget {
  final IconData icon;
  final VoidCallback onPressed;
  final double padding;

  const _PlayerControl({
    required this.icon,
    required this.onPressed,
    this.padding = 8,
  });

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: Container(
        padding: EdgeInsets.all(padding),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.05),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: Colors.white, size: 28),
      ),
      onPressed: onPressed,
    );
  }
}