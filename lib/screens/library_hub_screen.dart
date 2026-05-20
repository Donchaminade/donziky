import 'package:donziker/providers/music_provider.dart';
import 'package:donziker/screens/playlist_detail_screen.dart';
import 'package:donziker/screens/videos_screen.dart';
import 'package:donziker/theme/app_theme.dart';
import 'package:donziker/theme/theme_extensions.dart';
import 'package:donziker/utils/song_utils.dart';
import 'package:donziker/widgets/premium/premium_album_card.dart';
import 'package:donziker/widgets/premium/premium_song_tile.dart';
import 'package:flutter/material.dart';
import 'package:on_audio_query/on_audio_query.dart';
import 'package:provider/provider.dart';

enum _LibraryFilter { playlists, albums, artists, songs, genres, folders, videos }

class LibraryHubScreen extends StatefulWidget {
  const LibraryHubScreen({super.key});

  @override
  State<LibraryHubScreen> createState() => _LibraryHubScreenState();
}

class _LibraryHubScreenState extends State<LibraryHubScreen> {
  _LibraryFilter _filter = _LibraryFilter.songs;
  String _localSearch = '';

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<MusicProvider>();
    final c = context.dz;

    if (!provider.permissionGranted) {
      return Scaffold(
        body: Center(
          child: Text('Autorisez l\'accès aux médias', style: TextStyle(color: c.secondaryText)),
        ),
      );
    }

    return Scaffold(
      backgroundColor: c.surface,
      body: RefreshIndicator(
        color: c.accent,
        onRefresh: provider.refreshLibrary,
        child: CustomScrollView(
          slivers: [
            SliverAppBar(
              expandedHeight: 168,
              pinned: true,
              stretch: true,
              backgroundColor: c.surface,
              flexibleSpace: FlexibleSpaceBar(
                stretchModes: const [StretchMode.zoomBackground],
                background: Container(
                  decoration: BoxDecoration(gradient: c.heroGradient),
                  padding: const EdgeInsets.fromLTRB(20, 56, 20, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Text(
                        'Ta bibliothèque',
                        style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                              fontWeight: FontWeight.w800,
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
              ),
              actions: [
                IconButton(
                  icon: Icon(Icons.refresh_rounded, color: c.primaryText),
                  onPressed: provider.refreshLibrary,
                ),
              ],
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
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
            SliverToBoxAdapter(child: _FilterChips(filter: _filter, onSelect: (f) => setState(() => _filter = f))),
            ..._buildContent(context, provider, c),
            const SliverToBoxAdapter(child: SizedBox(height: 120)),
          ],
        ),
      ),
      floatingActionButton: _filter == _LibraryFilter.playlists
          ? FloatingActionButton.extended(
              onPressed: () => _createPlaylist(context),
              backgroundColor: c.accent,
              foregroundColor: c.scheme.onPrimary,
              icon: const Icon(Icons.add_rounded),
              label: const Text('Playlist'),
            )
          : null,
    );
  }

  List<Widget> _buildContent(BuildContext context, MusicProvider provider, DzColors c) {
    switch (_filter) {
      case _LibraryFilter.playlists:
        return _playlistsSlivers(context, provider, c);
      case _LibraryFilter.albums:
        return _albumsSlivers(context, provider, c);
      case _LibraryFilter.artists:
        return _artistsSlivers(context, provider, c);
      case _LibraryFilter.songs:
        return _songsSlivers(provider);
      case _LibraryFilter.genres:
        return _genresSlivers(context, provider, c);
      case _LibraryFilter.folders:
        return _foldersSlivers(context, provider, c);
      case _LibraryFilter.videos:
        return [const SliverFillRemaining(child: VideosScreen())];
    }
  }

  List<SongModel> _filterSongs(List<SongModel> songs) {
    if (_localSearch.isEmpty) return songs;
    return songs.where((s) {
      return s.title.toLowerCase().contains(_localSearch) ||
          (s.artist?.toLowerCase().contains(_localSearch) ?? false) ||
          (s.album?.toLowerCase().contains(_localSearch) ?? false);
    }).toList();
  }

  List<Widget> _playlistsSlivers(BuildContext context, MusicProvider provider, DzColors c) {
    final playlists = provider.playlists.where((p) {
      if (_localSearch.isEmpty) return true;
      return p.name.toLowerCase().contains(_localSearch);
    }).toList();

    if (playlists.isEmpty) {
      return [_emptySliver('Aucune playlist', 'Créez-en une avec le bouton +', c)];
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
              return _PlaylistGridCard(
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

  List<Widget> _albumsSlivers(BuildContext context, MusicProvider provider, DzColors c) {
    final songs = _filterSongs(provider.filteredSongs);
    final albums = SongUtils.groupByAlbum(songs);
    final keys = albums.keys.toList()..sort();

    if (keys.isEmpty) return [_emptySliver('Aucun album', null, c)];

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

  List<Widget> _artistsSlivers(BuildContext context, MusicProvider provider, DzColors c) {
    final songs = _filterSongs(provider.filteredSongs);
    final artists = SongUtils.groupByArtist(songs);
    final keys = artists.keys.toList()..sort();

    if (keys.isEmpty) return [_emptySliver('Aucun artiste', null, c)];

    return [
      SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, i) {
            final name = keys[i];
            final artistSongs = artists[name]!;
            return _ArtistRow(
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

  List<Widget> _songsSlivers(MusicProvider provider) {
    final songs = _filterSongs(provider.filteredSongs);
    if (songs.isEmpty) {
      return [SliverToBoxAdapter(child: Center(child: Text('Aucun morceau')))];
    }
    return [
      SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, i) => PremiumSongTile(
            song: songs[i],
            playlistContext: songs,
            index: i,
            highlight: provider.scrollToSongId != null,
          ),
          childCount: songs.length,
        ),
      ),
    ];
  }

  List<Widget> _genresSlivers(BuildContext context, MusicProvider provider, DzColors c) {
    final songs = _filterSongs(provider.filteredSongs);
    final genres = SongUtils.groupByGenre(songs);
    final keys = genres.keys.toList()..sort();
    if (keys.isEmpty) return [_emptySliver('Aucun genre', null, c)];

    return [
      SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, i) {
            final name = keys[i];
            final gSongs = genres[name]!;
            return _SimpleRow(
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

  List<Widget> _foldersSlivers(BuildContext context, MusicProvider provider, DzColors c) {
    final songs = _filterSongs(provider.filteredSongs);
    final folders = SongUtils.groupByFolder(songs);
    final keys = folders.keys.toList()..sort();
    if (keys.isEmpty) return [_emptySliver('Aucun dossier', null, c)];

    return [
      SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, i) {
            final path = keys[i];
            final fSongs = folders[path]!;
            return _SimpleRow(
              icon: Icons.folder_rounded,
              title: SongUtils.folderName(fSongs.first),
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

  SliverToBoxAdapter _emptySliver(String title, String? sub, DzColors c) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          children: [
            Icon(Icons.library_music_outlined, size: 56, color: c.tertiaryText),
            const SizedBox(height: 12),
            Text(title, style: TextStyle(fontWeight: FontWeight.w700, color: c.primaryText)),
            if (sub != null) ...[
              const SizedBox(height: 6),
              Text(sub, textAlign: TextAlign.center, style: TextStyle(color: c.secondaryText)),
            ],
          ],
        ),
      ),
    );
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

class _FilterChips extends StatelessWidget {
  final _LibraryFilter filter;
  final ValueChanged<_LibraryFilter> onSelect;

  const _FilterChips({required this.filter, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    const items = [
      (_LibraryFilter.playlists, 'Playlists'),
      (_LibraryFilter.albums, 'Albums'),
      (_LibraryFilter.artists, 'Artistes'),
      (_LibraryFilter.songs, 'Morceaux'),
      (_LibraryFilter.genres, 'Genres'),
      (_LibraryFilter.folders, 'Dossiers'),
      (_LibraryFilter.videos, 'Vidéos'),
    ];

    return SizedBox(
      height: 44,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: items.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, i) {
          final (f, label) = items[i];
          final selected = filter == f;
          return FilterChip(
            label: Text(label),
            selected: selected,
            onSelected: (_) => onSelect(f),
            showCheckmark: false,
            labelStyle: TextStyle(
              fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              color: selected ? context.dzAccent : context.dz.secondaryText,
            ),
          );
        },
      ),
    );
  }
}

class _PlaylistGridCard extends StatelessWidget {
  final String name;
  final int count;
  final VoidCallback onTap;

  const _PlaylistGridCard({required this.name, required this.count, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final c = context.dz;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [c.accent.withValues(alpha: 0.35), c.card],
          ),
        ),
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.queue_music_rounded, color: c.accent, size: 32),
            const Spacer(),
            Text(
              name,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: c.primaryText),
            ),
            Text('$count titres', style: TextStyle(fontSize: 12, color: c.secondaryText)),
          ],
        ),
      ),
    );
  }
}

class _ArtistRow extends StatelessWidget {
  final String name;
  final int count;
  final VoidCallback onTap;

  const _ArtistRow({required this.name, required this.count, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final c = context.dz;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 26,
                  backgroundColor: c.accent.withValues(alpha: 0.2),
                  child: Text(
                    name.isNotEmpty ? name[0].toUpperCase() : '?',
                    style: TextStyle(fontWeight: FontWeight.w800, color: c.accent, fontSize: 18),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(name, style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16, color: c.primaryText)),
                      Text('$count titres', style: TextStyle(fontSize: 13, color: c.secondaryText)),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right_rounded, color: c.tertiaryText),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SimpleRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _SimpleRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.dz;
    return ListTile(
      leading: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: c.card,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: c.accent),
      ),
      title: Text(title, style: TextStyle(fontWeight: FontWeight.w600, color: c.primaryText)),
      subtitle: Text(subtitle, style: TextStyle(color: c.secondaryText)),
      trailing: Icon(Icons.chevron_right_rounded, color: c.tertiaryText),
      onTap: onTap,
    );
  }
}

// Detail screens exported from albums/artists - move to library_hub file end

class AlbumDetailScreen extends StatelessWidget {
  final String name;
  final List<SongModel> songs;
  const AlbumDetailScreen({super.key, required this.name, required this.songs});

  @override
  Widget build(BuildContext context) {
    final c = context.dz;
    return Scaffold(
      backgroundColor: c.surface,
      appBar: AppBar(title: Text(name)),
      body: ListView.builder(
        itemCount: songs.length,
        itemBuilder: (context, i) => PremiumSongTile(song: songs[i], playlistContext: songs, index: i),
      ),
    );
  }
}

class ArtistDetailScreen extends StatelessWidget {
  final String name;
  final List<SongModel> songs;
  const ArtistDetailScreen({super.key, required this.name, required this.songs});

  @override
  Widget build(BuildContext context) {
    final c = context.dz;
    return Scaffold(
      backgroundColor: c.surface,
      appBar: AppBar(title: Text(name)),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.read<MusicProvider>().setQueue(songs, 0),
        child: const Icon(Icons.play_arrow_rounded),
      ),
      body: ListView.builder(
        itemCount: songs.length,
        itemBuilder: (context, i) => PremiumSongTile(song: songs[i], playlistContext: songs, index: i),
      ),
    );
  }
}

class GenreDetailScreen extends StatelessWidget {
  final String name;
  final List<SongModel> songs;
  const GenreDetailScreen({super.key, required this.name, required this.songs});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(name)),
      body: ListView.builder(
        itemCount: songs.length,
        itemBuilder: (context, i) => PremiumSongTile(song: songs[i], playlistContext: songs, index: i),
      ),
    );
  }
}

class FolderDetailScreen extends StatelessWidget {
  final String path;
  final List<SongModel> songs;
  const FolderDetailScreen({super.key, required this.path, required this.songs});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(SongUtils.folderName(songs.first))),
      body: ListView.builder(
        itemCount: songs.length,
        itemBuilder: (context, i) => PremiumSongTile(song: songs[i], playlistContext: songs, index: i),
      ),
    );
  }
}
