import 'package:donziker/providers/music_provider.dart';
import 'package:donziker/screens/albums_screen.dart';
import 'package:donziker/screens/artists_screen.dart';
import 'package:donziker/screens/folders_screen.dart';
import 'package:donziker/screens/genres_screen.dart';
import 'package:donziker/screens/playlists_screen.dart';
import 'package:donziker/screens/songs_screen.dart';
import 'package:donziker/screens/videos_screen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class LibraryHubScreen extends StatefulWidget {
  const LibraryHubScreen({super.key});

  @override
  State<LibraryHubScreen> createState() => _LibraryHubScreenState();
}

class _LibraryHubScreenState extends State<LibraryHubScreen> with SingleTickerProviderStateMixin {
  late TabController _tab;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 7, vsync: this);
    _tab.addListener(() {
      if (!_tab.indexIsChanging) {
        context.read<MusicProvider>().setLibraryTab(_tab.index);
      }
    });
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<MusicProvider>();

    if (_tab.index != provider.libraryTabIndex) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _tab.index != provider.libraryTabIndex) {
          _tab.animateTo(provider.libraryTabIndex);
        }
      });
    }

    if (!provider.permissionGranted) {
      return const Scaffold(body: Center(child: Text('Autorisez l\'accès aux médias')));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Bibliothèque'),
        bottom: TabBar(
          controller: _tab,
          isScrollable: true,
          tabs: const [
            Tab(text: 'Chansons'),
            Tab(text: 'Albums'),
            Tab(text: 'Artistes'),
            Tab(text: 'Dossiers'),
            Tab(text: 'Genres'),
            Tab(text: 'Playlists'),
            Tab(text: 'Vidéos'),
          ],
        ),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: provider.refreshLibrary),
        ],
      ),
      body: TabBarView(
        controller: _tab,
        children: const [
          SongsScreen(),
          AlbumsScreen(),
          ArtistsScreen(),
          FoldersScreen(),
          GenresScreen(),
          PlaylistsScreen(),
          VideosScreen(),
        ],
      ),
    );
  }
}
