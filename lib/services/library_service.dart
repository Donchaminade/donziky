import 'package:donziker/models/local_playlist.dart';
import 'package:donziker/models/song_sort.dart';
import 'package:donziker/services/database_service.dart';
import 'package:donziker/services/permission_service.dart';
import 'package:donziker/utils/song_utils.dart';
import 'package:flutter/foundation.dart';
import 'package:on_audio_query/on_audio_query.dart';
import 'package:photo_manager/photo_manager.dart';

/// Bibliothèque locale : morceaux, vidéos, playlists, favoris, tri et recherche.
class LibraryService {
  LibraryService({
    DatabaseService? database,
    PermissionService? permissions,
    OnAudioQuery? audioQuery,
  })  : db = database ?? DatabaseService(),
        permissions = permissions ?? PermissionService(),
        _audioQuery = audioQuery ?? OnAudioQuery();

  final DatabaseService db;
  final PermissionService permissions;
  final OnAudioQuery _audioQuery;

  List<SongModel> songs = [];
  List<AssetEntity> videos = [];
  List<LocalPlaylist> playlists = [];
  List<String> favorites = [];
  List<String> recentlyPlayedIds = [];
  Set<String> excludedFolders = {};

  bool isLoading = false;
  bool isBusy = false;
  bool permissionGranted = false;
  bool hideShortSounds = true;
  int minDurationMs = 10000;

  String searchQuery = '';
  SongSort songSort = SongSort.dateAdded;
  SortOrder sortOrder = SortOrder.descending;

  List<SongModel>? _cachedFilteredSongs;
  String? _cachedFilteredKey;

  final Map<String, List<SongModel>> previewPlaylistSongs = {};

  bool isFavorite(String songId) => favorites.contains(songId);

  void invalidateFilter() {
    _cachedFilteredKey = null;
    _cachedFilteredSongs = null;
  }

  List<SongModel> get filteredSongs {
    final key =
        '$searchQuery|$songSort|$sortOrder|${songs.length}|${excludedFolders.length}|$hideShortSounds|$minDurationMs';
    if (_cachedFilteredKey == key && _cachedFilteredSongs != null) {
      return _cachedFilteredSongs!;
    }
    final result = SongUtils.sortSongs(
      SongUtils.filterSongs(
        songs,
        query: searchQuery,
        excludedFolders: excludedFolders,
        minDurationMs: minDurationMs,
        hideShortSounds: hideShortSounds,
      ),
      songSort,
      sortOrder,
    );
    _cachedFilteredKey = key;
    _cachedFilteredSongs = result;
    return result;
  }

  List<SongModel> get recentlyPlayed {
    final result = <SongModel>[];
    for (final id in recentlyPlayedIds) {
      for (final s in songs) {
        if (SongUtils.songId(s) == id) {
          result.add(s);
          break;
        }
      }
    }
    return result;
  }

  List<SongModel> get favoriteSongs => SongUtils.sortSongs(
        songs.where((s) => isFavorite(SongUtils.songId(s))).toList(),
        songSort,
        sortOrder,
      );

  List<SongModel> get smartRecentlyAdded {
    final sorted = List<SongModel>.from(songs);
    sorted.sort((a, b) => (b.dateAdded ?? 0).compareTo(a.dateAdded ?? 0));
    return sorted.take(15).toList();
  }

  List<SongModel> smartMostPlayed(List<String> topPlayedIds) {
    final result = <SongModel>[];
    for (final id in topPlayedIds) {
      for (final s in songs) {
        if (SongUtils.songId(s) == id) {
          result.add(s);
          break;
        }
      }
    }
    return result;
  }

  void remember(String songId) {
    recentlyPlayedIds.remove(songId);
    recentlyPlayedIds.insert(0, songId);
    if (recentlyPlayedIds.length > 30) {
      recentlyPlayedIds = recentlyPlayedIds.take(30).toList();
    }
  }

  Future<bool> querySongs({int retryCount = 0}) async {
    await Future.delayed(Duration(milliseconds: 300 + (retryCount * 500)));
    songs = await _audioQuery.querySongs(
      sortType: SongSortType.DATE_ADDED,
      orderType: OrderType.DESC_OR_GREATER,
      uriType: UriType.EXTERNAL,
      ignoreCase: true,
    );
    if (hideShortSounds) {
      songs = songs.where((s) => (s.duration ?? 0) >= minDurationMs).toList();
    }
    invalidateFilter();
    return true;
  }

  Future<void> loadVideosIfAllowed() async {
    videos = [];
    if (!await permissions.hasVideoGalleryAccess()) {
      await permissions.requestVideoGalleryAccess();
    }
    if (!await permissions.hasVideoGalleryAccess()) return;

    try {
      final videoAlbums = await PhotoManager.getAssetPathList(type: RequestType.video);
      for (final album in videoAlbums.take(5)) {
        final assets = await album.getAssetListPaged(page: 0, size: 100);
        videos.addAll(assets);
      }
    } catch (e) {
      debugPrint('Video load error: $e');
    }
  }

  Future<void> loadPlaylists() async {
    playlists = await db.getPlaylists();
  }

  Future<String> createPlaylist(String name) async {
    final id = await db.createPlaylist(name);
    await loadPlaylists();
    return id;
  }

  Future<void> renamePlaylist(String id, String name) async {
    await db.renamePlaylist(id, name);
    await loadPlaylists();
  }

  Future<void> deletePlaylist(String id) async {
    await db.deletePlaylist(id);
    await loadPlaylists();
  }

  Future<List<SongModel>> playlistSongs(String playlistId) async {
    final seeded = previewPlaylistSongs[playlistId];
    if (seeded != null) return seeded;
    final ids = await db.getPlaylistSongIds(playlistId);
    final result = <SongModel>[];
    for (final id in ids) {
      for (final s in songs) {
        if (SongUtils.songId(s) == id) {
          result.add(s);
          break;
        }
      }
    }
    return result;
  }

  Future<void> addToPlaylist(String playlistId, SongModel song) async {
    await db.addSongToPlaylist(playlistId, SongUtils.songId(song));
    await loadPlaylists();
  }

  Future<void> removeFromPlaylist(String playlistId, String songId) async {
    await db.removeSongFromPlaylist(playlistId, songId);
    await loadPlaylists();
  }
}
