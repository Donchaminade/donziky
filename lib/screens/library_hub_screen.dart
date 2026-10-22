import 'package:donziker/providers/music_provider.dart';
import 'package:donziker/screens/library_detail_screens.dart';
import 'package:donziker/screens/playlist_detail_screen.dart';
import 'package:donziker/screens/videos_screen.dart';
import 'package:donziker/theme/app_theme.dart';
import 'package:donziker/theme/theme_extensions.dart';
import 'package:donziker/utils/song_scroll_helper.dart';
import 'package:donziker/utils/song_utils.dart';
import 'package:donziker/widgets/home/pill_filter_bar.dart';
import 'package:donziker/widgets/library/library_tiles.dart';
import 'package:donziker/widgets/library_sort_button.dart';
import 'package:donziker/widgets/motion/fade_slide_in.dart';
import 'package:donziker/widgets/premium/premium_album_card.dart';
import 'package:donziker/widgets/premium/premium_song_tile.dart';
import 'package:flutter/material.dart';
import 'package:on_audio_query/on_audio_query.dart';
import 'package:provider/provider.dart';

enum LibraryFilter { playlists, albums, artists, songs, genres, folders, videos }

class LibraryHubScreen extends StatefulWidget {
  const LibraryHubScreen({super.key});

  @override
  State<LibraryHubScreen> createState() => _LibraryHubScreenState();
}

class _LibraryHubScreenState extends State<LibraryHubScreen> {
  LibraryFilter _filter = LibraryFilter.songs;
  String _localSearch = '';
  final GlobalKey _playingItemKey = GlobalKey();
  int _lastLocateGen = -1;

  void _applySection(String section) {
    final next = switch (section) {
      'playlists' => LibraryFilter.playlists,
      'albums' => LibraryFilter.albums,
      'artists' => LibraryFilter.artists,
      'genres' => LibraryFilter.genres,
      'folders' => LibraryFilter.folders,
      'videos' => LibraryFilter.videos,
      _ => LibraryFilter.songs,
    };
    setState(() => _filter = next);
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<MusicProvider>();
    final c = context.dz;
    final requested = provider.requestedLibrarySection;
    if (requested != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _applySection(requested);
        provider.consumeLibrarySection();
      });
    }

    if (!provider.permissionGranted) {
      return Scaffold(
        backgroundColor: c.surface,
        body: Center(
          child: Text('Autorisez l\'accès aux médias', style: TextStyle(color: c.secondaryText)),
        ),
      );
    }

    return Scaffold(
      backgroundColor: c.surface,
      body: RefreshIndicator(
        color: AppTheme.lime,
        onRefresh: provider.refreshLibrary,
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: SafeArea(
                bottom: false,
                child: FadeSlideIn(
                  index: 0,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 12, 8, 4),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Bibliothèque',
                                style: TextStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: -0.8,
                                  color: c.primaryText,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${provider.filteredSongs.length} morceaux sur cet appareil',
                                style: TextStyle(color: c.secondaryText, fontSize: 14),
                              ),
                            ],
                          ),
                        ),
                        const LibrarySortButton(),
                        IconButton(
                          icon: Icon(Icons.refresh_rounded, color: c.primaryText),
                          onPressed: provider.refreshLibrary,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
                child: TextField(
                  onChanged: (v) => setState(() => _localSearch = v.trim().toLowerCase()),
                  style: TextStyle(color: c.primaryText),
                  decoration: InputDecoration(
                    hintText: 'Rechercher dans la bibliothèque',
                    prefixIcon: Icon(Icons.search_rounded, color: c.secondaryText),
                  ),
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: PillFilterBar(
                labels: const ['Playlists', 'Albums', 'Artistes', 'Morceaux', 'Genres', 'Dossiers', 'Vidéos'],
                selected: _filter.index,
                onSelected: (i) => setState(() => _filter = LibraryFilter.values[i]),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 12)),
            ..._buildContent(context, provider, c),
            const SliverToBoxAdapter(child: SizedBox(height: 140)),
          ],
        ),
      ),
      floatingActionButton: _filter == LibraryFilter.playlists
          ? FloatingActionButton.extended(
              onPressed: () => _createPlaylist(context),
              backgroundColor: AppTheme.lime,
              foregroundColor: AppTheme.ink,
              icon: const Icon(Icons.add_rounded),
              label: const Text('Playlist'),
            )
          : null,
    );
  }

  List<Widget> _buildContent(BuildContext context, MusicProvider provider, DzColors c) {
    switch (_filter) {
      case LibraryFilter.playlists:
        return _playlists(context, provider, c);
      case LibraryFilter.albums:
        return _albums(context, provider, c);
      case LibraryFilter.artists:
        return _artists(context, provider, c);
      case LibraryFilter.songs:
        return _songs(provider);
      case LibraryFilter.genres:
        return _genres(context, provider, c);
      case LibraryFilter.folders:
        return _folders(context, provider, c);
      case LibraryFilter.videos:
        return [const SliverFillRemaining(child: VideosScreen())];
    }
  }

  List<Widget> _playlists(BuildContext context, MusicProvider provider, DzColors c) {
    final playlists = provider.playlists.where((p) {
      if (_localSearch.isEmpty) return true;
      return p.name.toLowerCase().contains(_localSearch);
    }).toList();
    if (playlists.isEmpty) {
      return [const SliverToBoxAdapter(child: LibraryEmpty(title: 'Aucune playlist', subtitle: 'Créez-en une avec le bouton +'))];
    }
    return [
      SliverPadding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        sliver: SliverGrid(
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: 16,
            crossAxisSpacing: 14,
            childAspectRatio: 0.92,
          ),
          delegate: SliverChildBuilderDelegate(
            (context, i) {
              final pl = playlists[i];
              return LibraryPlaylistCard(
                name: pl.name,
                count: pl.songCount,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => PlaylistDetailScreen(playlistId: pl.id, name: pl.name),
                  ),
                ),
              );
            },
            childCount: playlists.length,
          ),
        ),
      ),
    ];
  }

  List<Widget> _albums(BuildContext context, MusicProvider provider, DzColors c) {
    final songs = _songsMatching(provider);
    final albums = SongUtils.groupByAlbum(songs);
    final keys = albums.keys.toList()..sort();
    if (keys.isEmpty) return [const SliverToBoxAdapter(child: LibraryEmpty(title: 'Aucun album'))];
    return [
      SliverPadding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
        sliver: SliverGrid(
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: 20,
            crossAxisSpacing: 14,
            childAspectRatio: 0.72,
          ),
          delegate: SliverChildBuilderDelegate(
            (context, i) {
              final name = keys[i];
              final albumSongs = albums[name]!;
              return PremiumAlbumCard(
                name: name,
                songs: albumSongs,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => AlbumDetailScreen(name: name, songs: albumSongs)),
                ),
              );
            },
            childCount: keys.length,
          ),
        ),
      ),
    ];
  }

  List<Widget> _artists(BuildContext context, MusicProvider provider, DzColors c) {
    final songs = _songsMatching(provider);
    final artists = SongUtils.groupByArtist(songs);
    final keys = artists.keys.toList()..sort();
    if (keys.isEmpty) return [const SliverToBoxAdapter(child: LibraryEmpty(title: 'Aucun artiste'))];
    return [
      SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, i) {
            final name = keys[i];
            final artistSongs = artists[name]!;
            return LibraryArtistTile(
              name: name,
              count: artistSongs.length,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => ArtistDetailScreen(name: name, songs: artistSongs)),
              ),
            );
          },
          childCount: keys.length,
        ),
      ),
    ];
  }

  List<Widget> _songs(MusicProvider provider) {
    final songs = _songsMatching(provider);
    if (provider.locateGeneration != _lastLocateGen && provider.scrollToSongId != null) {
      _lastLocateGen = provider.locateGeneration;
      SongScrollHelper.scrollToCurrentSong(context: context, itemKey: _playingItemKey, songs: songs);
    }
    if (songs.isEmpty) {
      return [const SliverToBoxAdapter(child: LibraryEmpty(title: 'Aucun morceau'))];
    }
    final currentId = provider.currentSong?.id;
    return [
      SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, i) {
            final song = songs[i];
            return PremiumSongTile(
              song: song,
              playlistContext: songs,
              index: i,
              itemKey: currentId == song.id ? _playingItemKey : null,
            );
          },
          childCount: songs.length,
        ),
      ),
    ];
  }

  List<Widget> _genres(BuildContext context, MusicProvider provider, DzColors c) {
    final songs = _songsMatching(provider);
    final genres = SongUtils.groupByGenre(songs);
    final keys = genres.keys.toList()..sort();
    if (keys.isEmpty) return [const SliverToBoxAdapter(child: LibraryEmpty(title: 'Aucun genre'))];
    return [
      SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, i) {
            final name = keys[i];
            final gSongs = genres[name]!;
            return LibrarySimpleTile(
              icon: Icons.category_rounded,
              title: name,
              subtitle: '${gSongs.length} titres',
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => GenreDetailScreen(name: name, songs: gSongs)),
              ),
            );
          },
          childCount: keys.length,
        ),
      ),
    ];
  }

  List<Widget> _folders(BuildContext context, MusicProvider provider, DzColors c) {
    final songs = _songsMatching(provider);
    final folders = SongUtils.groupByFolder(songs);
    final keys = folders.keys.toList()..sort();
    if (keys.isEmpty) return [const SliverToBoxAdapter(child: LibraryEmpty(title: 'Aucun dossier'))];
    return [
      SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, i) {
            final path = keys[i];
            final fSongs = folders[path]!;
            return LibrarySimpleTile(
              icon: Icons.folder_rounded,
              title: libraryFolderLabel(fSongs),
              subtitle: '${fSongs.length} titres',
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => FolderDetailScreen(path: path, songs: fSongs)),
              ),
            );
          },
          childCount: keys.length,
        ),
      ),
    ];
  }

  List<SongModel> _songsMatching(MusicProvider provider) {
    final songs = provider.filteredSongs;
    if (_localSearch.isEmpty) return songs;
    return songs.where((s) {
      return s.title.toLowerCase().contains(_localSearch) ||
          (s.artist?.toLowerCase().contains(_localSearch) ?? false) ||
          (s.album?.toLowerCase().contains(_localSearch) ?? false);
    }).toList();
  }

  Future<void> _createPlaylist(BuildContext context) async {
    final controller = TextEditingController();
    final name = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Nouvelle playlist'),
        content: TextField(controller: controller, autofocus: true, decoration: const InputDecoration(hintText: 'Nom')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Annuler')),
          FilledButton(onPressed: () => Navigator.pop(ctx, controller.text.trim()), child: const Text('Créer')),
        ],
      ),
    );
    if (name != null && name.isNotEmpty && context.mounted) {
      await context.read<MusicProvider>().createPlaylist(name);
    }
  }
}
