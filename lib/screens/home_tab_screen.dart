import 'package:donziker/providers/music_provider.dart';
import 'package:donziker/services/permission_service.dart';
import 'package:donziker/theme/app_theme.dart';
import 'package:donziker/theme/theme_extensions.dart';
import 'package:donziker/utils/song_scroll_helper.dart';
import 'package:donziker/widgets/compact_song_card.dart';
import 'package:donziker/widgets/home/discovery_carousel.dart';
import 'package:donziker/widgets/home/home_header.dart';
import 'package:donziker/widgets/home/pill_filter_bar.dart';
import 'package:donziker/widgets/motion/fade_slide_in.dart';
import 'package:donziker/widgets/motion/pressable_scale.dart';
import 'package:donziker/widgets/premium/premium_song_tile.dart';
import 'package:flutter/material.dart';
import 'package:on_audio_query/on_audio_query.dart';
import 'package:provider/provider.dart';

enum _HomeFilter { all, fresh, trending, playlists }

class HomeTabScreen extends StatefulWidget {
  const HomeTabScreen({super.key});

  @override
  State<HomeTabScreen> createState() => _HomeTabScreenState();
}

class _HomeTabScreenState extends State<HomeTabScreen> {
  final GlobalKey _playingItemKey = GlobalKey();
  int _lastLocateGen = -1;
  _HomeFilter _filter = _HomeFilter.all;
  bool _searchOpen = false;

  void _handleLocate(MusicProvider provider, List<SongModel> songs) {
    if (provider.locateGeneration == _lastLocateGen) return;
    if (provider.scrollToSongId == null) return;
    _lastLocateGen = provider.locateGeneration;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (_filter != _HomeFilter.all) {
        setState(() => _filter = _HomeFilter.all);
      }
      SongScrollHelper.scrollToCurrentSong(
        context: context,
        itemKey: _playingItemKey,
        songs: songs,
      );
    });
  }

  List<DiscoveryCardData> _cards(MusicProvider provider) {
    final recent = provider.recentlyPlayed;
    final fresh = provider.smartRecentlyAdded;
    final top = provider.smartMostPlayed;
    final all = provider.filteredSongs;

    DiscoveryCardData card({
      required String badge,
      required String title,
      required String subtitle,
      required List<Color> gradient,
      SongModel? song,
      List<SongModel>? queue,
    }) {
      final q = queue ?? (song == null ? const <SongModel>[] : [song]);
      final index = song == null ? 0 : q.indexWhere((s) => s.id == song.id);
      return DiscoveryCardData(
        badge: badge,
        title: title,
        subtitle: subtitle,
        gradient: gradient,
        song: song,
        queue: q,
        index: index < 0 ? 0 : index,
      );
    }

    if (_filter == _HomeFilter.fresh) {
      final source = fresh.isNotEmpty ? fresh : all;
      return [
        for (var i = 0; i < source.take(4).length; i++)
          card(
            badge: 'NOUVEAU',
            title: source[i].title,
            subtitle: source[i].artist ?? 'Ajouté récemment',
            gradient: const [Color(0xFF7EC8F3), Color(0xFFF6C7A1)],
            song: source[i],
            queue: source,
          ),
      ];
    }
    if (_filter == _HomeFilter.trending) {
      final source = top.isNotEmpty ? top : all;
      return [
        for (var i = 0; i < source.take(4).length; i++)
          card(
            badge: 'TENDANCE',
            title: source[i].title,
            subtitle: source[i].artist ?? 'Souvent écouté',
            gradient: const [Color(0xFFF26B3A), Color(0xFF141414)],
            song: source[i],
            queue: source,
          ),
      ];
    }

    final hero = recent.isNotEmpty ? recent.first : (all.isNotEmpty ? all.first : null);
    final second = fresh.length > 1 ? fresh[1] : (all.length > 1 ? all[1] : hero);
    final third = top.isNotEmpty ? top.first : (all.length > 2 ? all[2] : hero);
    if (hero == null && second == null && third == null) {
      return [
        card(
          badge: 'CETTE SEMAINE',
          title: 'Découverte de la semaine',
          subtitle: 'Des pépites pour toi',
          gradient: const [Color(0xFF7EC8F3), Color(0xFFF6C7A1)],
        ),
      ];
    }
    return [
      card(
        badge: 'NEW THIS WEEK',
        title: 'Weekly Discovery',
        subtitle: 'Des pépites pour toi',
        gradient: const [Color(0xFF7EC8F3), Color(0xFFF6C7A1)],
        song: hero,
        queue: recent.isNotEmpty ? recent : all,
      ),
      card(
        badge: 'NOUVEAU',
        title: second?.album ?? 'Nouveautés',
        subtitle: second?.artist ?? 'Ajouts récents',
        gradient: const [Color(0xFFD4F26A), Color(0xFF1A1A1A)],
        song: second,
        queue: fresh.isNotEmpty ? fresh : all,
      ),
      card(
        badge: 'POUR TOI',
        title: third?.title ?? 'Feel-good',
        subtitle: 'Des pépites pour toi',
        gradient: const [Color(0xFFF26B3A), Color(0xFF243B55)],
        song: third,
        queue: top.isNotEmpty ? top : all,
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<MusicProvider>(
      builder: (context, provider, _) {
        final c = context.dz;

        if (provider.isLoading && provider.songs.isEmpty) {
          return Scaffold(
            backgroundColor: c.surface,
            body: Center(child: CircularProgressIndicator(color: c.accent)),
          );
        }
        if (!provider.permissionGranted) {
          return Scaffold(
            backgroundColor: c.surface,
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(28),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.library_music_rounded, size: 64, color: c.tertiaryText),
                    const SizedBox(height: 16),
                    Text(
                      'DonZiker lit la musique déjà sur votre téléphone.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 16, color: c.secondaryText, height: 1.4),
                    ),
                    const SizedBox(height: 24),
                    FilledButton(
                      onPressed: provider.checkAndRequestPermissions,
                      child: const Text('Autoriser l\'accès'),
                    ),
                    TextButton(
                      onPressed: () => PermissionService().openSystemSettings(),
                      child: const Text('Paramètres Android'),
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        final songs = provider.filteredSongs;
        _handleLocate(provider, songs);
        final searching = provider.searchQuery.isNotEmpty;
        final cards = _cards(provider);

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
                      child: HomeHeader(
                        searchOpen: _searchOpen || searching,
                        onSearch: () => setState(() => _searchOpen = !_searchOpen),
                        onFavorites: () => provider.setShellTab(2),
                        onQuery: provider.updateSearchQuery,
                      ),
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: FadeSlideIn(
                    index: 1,
                    child: PillFilterBar(
                      labels: const ['Tous', 'Nouveautés', 'Tendances', 'Playlists'],
                      selected: _filter.index,
                      onSelected: (i) => setState(() => _filter = _HomeFilter.values[i]),
                    ),
                  ),
                ),
                if (!searching && provider.currentSong != null)
                  SliverToBoxAdapter(
                    child: FadeSlideIn(
                      index: 2,
                      child: _ResumeBanner(provider: provider),
                    ),
                  ),
                if (!searching && _filter != _HomeFilter.playlists) ...[
                  _section('Pour toi', null),
                  SliverToBoxAdapter(
                    child: FadeSlideIn(index: 3, child: DiscoveryCarousel(cards: cards)),
                  ),
                ],
                if (!searching && (_filter == _HomeFilter.all || _filter == _HomeFilter.playlists)) ...[
                  _section('Tes playlists', () => provider.openLibrarySection('playlists')),
                  SliverToBoxAdapter(
                    child: FadeSlideIn(
                      index: 4,
                      child: _PlaylistStrip(provider: provider),
                    ),
                  ),
                ],
                if (!searching && _filter == _HomeFilter.all && provider.recentlyPlayed.isNotEmpty) ...[
                  _section('Écoutés récemment', null),
                  SliverToBoxAdapter(
                    child: FadeSlideIn(
                      index: 5,
                      child: CompactSongRow(songs: provider.recentlyPlayed),
                    ),
                  ),
                ],
                if (!searching && _filter == _HomeFilter.all && provider.favoriteSongs.isNotEmpty) ...[
                  _section('Mes favoris', () => provider.setShellTab(2)),
                  SliverToBoxAdapter(child: CompactSongRow(songs: provider.favoriteSongs)),
                ],
                if (!searching &&
                    (_filter == _HomeFilter.all || _filter == _HomeFilter.trending) &&
                    provider.smartMostPlayed.isNotEmpty) ...[
                  _section('Les plus écoutés', null),
                  SliverToBoxAdapter(child: CompactSongRow(songs: provider.smartMostPlayed)),
                ],
                if (!searching &&
                    (_filter == _HomeFilter.all || _filter == _HomeFilter.fresh) &&
                    provider.smartRecentlyAdded.isNotEmpty) ...[
                  _section('Ajoutés récemment', null),
                  SliverToBoxAdapter(child: CompactSongRow(songs: provider.smartRecentlyAdded)),
                ],
                if (searching)
                  _section('Résultats (${songs.length})', null)
                else if (_filter == _HomeFilter.all)
                  _section('Toutes les chansons (${songs.length})', null)
                else if (_filter == _HomeFilter.fresh)
                  _section('Nouveautés', null)
                else if (_filter == _HomeFilter.trending)
                  _section('Tendances', null),
                if (_filter != _HomeFilter.playlists || searching)
                  SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, i) {
                        final list = _listForFilter(provider, songs);
                        if (i >= list.length) return null;
                        final song = list[i];
                        final isCurrent = provider.currentSong?.id == song.id;
                        return PremiumSongTile(
                          song: song,
                          playlistContext: list,
                          index: i,
                          itemKey: isCurrent ? _playingItemKey : null,
                        );
                      },
                      childCount: _listForFilter(provider, songs).length,
                    ),
                  ),
                const SliverToBoxAdapter(child: SizedBox(height: 150)),
              ],
            ),
          ),
        );
      },
    );
  }

  List<SongModel> _listForFilter(MusicProvider provider, List<SongModel> songs) {
    if (provider.searchQuery.isNotEmpty || _filter == _HomeFilter.all) return songs;
    if (_filter == _HomeFilter.fresh) {
      return provider.smartRecentlyAdded.isNotEmpty ? provider.smartRecentlyAdded : songs;
    }
    if (_filter == _HomeFilter.trending) {
      return provider.smartMostPlayed.isNotEmpty ? provider.smartMostPlayed : songs;
    }
    return const [];
  }

  Widget _section(String title, VoidCallback? onSeeAll) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 22, 16, 10),
        child: Row(
          children: [
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.3,
                  color: context.dz.primaryText,
                ),
              ),
            ),
            if (onSeeAll != null)
              TextButton(
                onPressed: onSeeAll,
                child: Text('Tout voir', style: TextStyle(color: context.dz.secondaryText, fontWeight: FontWeight.w600)),
              ),
          ],
        ),
      ),
    );
  }
}

class _ResumeBanner extends StatelessWidget {
  final MusicProvider provider;
  const _ResumeBanner({required this.provider});

  @override
  Widget build(BuildContext context) {
    final song = provider.currentSong;
    if (song == null) return const SizedBox.shrink();
    final c = context.dz;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: PressableScale(
        onTap: provider.togglePlayPause,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: c.isDark ? AppTheme.darkCard : Colors.white,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            children: [
              const Icon(Icons.play_circle_fill_rounded, color: AppTheme.lime),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Reprendre l\'écoute', style: TextStyle(fontSize: 12, color: c.secondaryText)),
                    Text(
                      song.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontWeight: FontWeight.w700, color: c.primaryText),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PlaylistStrip extends StatelessWidget {
  final MusicProvider provider;
  const _PlaylistStrip({required this.provider});

  @override
  Widget build(BuildContext context) {
    final c = context.dz;
    final playlists = provider.playlists;
    if (playlists.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Text('Aucune playlist pour le moment.', style: TextStyle(color: c.secondaryText)),
      );
    }
    return SizedBox(
      height: 118,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: playlists.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, i) {
          final pl = playlists[i];
          return PressableScale(
            onTap: () => provider.openLibrarySection('playlists'),
            child: Container(
              width: 160,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: c.isDark ? AppTheme.darkCard : Colors.white,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.queue_music_rounded, color: c.isDark ? AppTheme.lime : AppTheme.ink),
                  const Spacer(),
                  Text(
                    pl.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontWeight: FontWeight.w700, color: c.primaryText),
                  ),
                  Text('${pl.songCount} titres', style: TextStyle(fontSize: 12, color: c.secondaryText)),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
