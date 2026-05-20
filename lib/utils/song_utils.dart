import 'package:on_audio_query/on_audio_query.dart';
import 'package:path/path.dart' as p;

import '../models/song_sort.dart';

class SongUtils {
  static String songId(SongModel song) => song.id.toString();

  static String folderPath(SongModel song) {
    final data = song.data;
    if (data.isEmpty) return 'Inconnu';
    return p.dirname(data);
  }

  static String folderName(SongModel song) {
    final folder = folderPath(song);
    return p.basename(folder);
  }

  static List<SongModel> sortSongs(List<SongModel> songs, SongSort sort) {
    final copy = List<SongModel>.from(songs);
    switch (sort) {
      case SongSort.title:
        copy.sort((a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()));
      case SongSort.artist:
        copy.sort((a, b) => (a.artist ?? '').toLowerCase().compareTo((b.artist ?? '').toLowerCase()));
      case SongSort.album:
        copy.sort((a, b) => (a.album ?? '').toLowerCase().compareTo((b.album ?? '').toLowerCase()));
      case SongSort.duration:
        copy.sort((a, b) => (b.duration ?? 0).compareTo(a.duration ?? 0));
      case SongSort.dateAdded:
        copy.sort((a, b) => (b.dateAdded ?? 0).compareTo(a.dateAdded ?? 0));
    }
    return copy;
  }

  static List<SongModel> filterSongs(
    List<SongModel> songs, {
    required String query,
    required Set<String> excludedFolders,
    required int minDurationMs,
    required bool hideShortSounds,
  }) {
    return songs.where((song) {
      if (hideShortSounds && (song.duration ?? 0) < minDurationMs) return false;
      final folder = folderPath(song);
      for (final excluded in excludedFolders) {
        if (folder.startsWith(excluded)) return false;
      }
      if (query.isEmpty) return true;
      final q = query.toLowerCase();
      return song.title.toLowerCase().contains(q) ||
          (song.artist?.toLowerCase().contains(q) ?? false) ||
          (song.album?.toLowerCase().contains(q) ?? false) ||
          folder.toLowerCase().contains(q);
    }).toList();
  }

  static Map<String, List<SongModel>> groupByAlbum(List<SongModel> songs) {
    final map = <String, List<SongModel>>{};
    for (final song in songs) {
      final key = song.album ?? 'Album inconnu';
      map.putIfAbsent(key, () => []).add(song);
    }
    return map;
  }

  static Map<String, List<SongModel>> groupByArtist(List<SongModel> songs) {
    final map = <String, List<SongModel>>{};
    for (final song in songs) {
      final key = song.artist ?? 'Artiste inconnu';
      map.putIfAbsent(key, () => []).add(song);
    }
    return map;
  }

  static Map<String, List<SongModel>> groupByGenre(List<SongModel> songs) {
    final map = <String, List<SongModel>>{};
    for (final song in songs) {
      final key = (song.genre?.isNotEmpty == true) ? song.genre! : 'Genre inconnu';
      map.putIfAbsent(key, () => []).add(song);
    }
    return map;
  }

  static Map<String, List<SongModel>> groupByFolder(List<SongModel> songs) {
    final map = <String, List<SongModel>>{};
    for (final song in songs) {
      final key = folderPath(song);
      map.putIfAbsent(key, () => []).add(song);
    }
    return map;
  }
}
