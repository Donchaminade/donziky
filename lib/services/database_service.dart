import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

import '../models/local_playlist.dart';

class DatabaseService {
  static Database? _db;

  static Future<Database> get database async {
    if (_db != null) return _db!;
    _db = await _init();
    return _db!;
  }

  static Future<Database> _init() async {
    final dbPath = await getDatabasesPath();
    return openDatabase(
      p.join(dbPath, 'donziker.db'),
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE playlists (
            id TEXT PRIMARY KEY,
            name TEXT NOT NULL,
            created_at INTEGER NOT NULL
          )
        ''');
        await db.execute('''
          CREATE TABLE playlist_songs (
            playlist_id TEXT NOT NULL,
            song_id TEXT NOT NULL,
            position INTEGER NOT NULL,
            PRIMARY KEY (playlist_id, song_id)
          )
        ''');
        await db.execute('''
          CREATE TABLE play_stats (
            song_id TEXT PRIMARY KEY,
            play_count INTEGER NOT NULL DEFAULT 0,
            total_ms INTEGER NOT NULL DEFAULT 0,
            last_played INTEGER
          )
        ''');
      },
    );
  }

  Future<List<LocalPlaylist>> getPlaylists() async {
    final db = await database;
    final rows = await db.rawQuery('''
      SELECT p.id, p.name, p.created_at,
             COUNT(ps.song_id) as song_count
      FROM playlists p
      LEFT JOIN playlist_songs ps ON p.id = ps.playlist_id
      GROUP BY p.id
      ORDER BY p.created_at DESC
    ''');
    return rows.map(LocalPlaylist.fromMap).toList();
  }

  Future<String> createPlaylist(String name) async {
    final db = await database;
    final id = DateTime.now().millisecondsSinceEpoch.toString();
    await db.insert('playlists', {
      'id': id,
      'name': name,
      'created_at': DateTime.now().millisecondsSinceEpoch,
    });
    return id;
  }

  Future<void> renamePlaylist(String id, String name) async {
    final db = await database;
    await db.update('playlists', {'name': name}, where: 'id = ?', whereArgs: [id]);
  }

  Future<void> deletePlaylist(String id) async {
    final db = await database;
    await db.delete('playlist_songs', where: 'playlist_id = ?', whereArgs: [id]);
    await db.delete('playlists', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<String>> getPlaylistSongIds(String playlistId) async {
    final db = await database;
    final rows = await db.query(
      'playlist_songs',
      columns: ['song_id'],
      where: 'playlist_id = ?',
      whereArgs: [playlistId],
      orderBy: 'position ASC',
    );
    return rows.map((r) => r['song_id'] as String).toList();
  }

  Future<void> addSongToPlaylist(String playlistId, String songId) async {
    final db = await database;
    final existing = await getPlaylistSongIds(playlistId);
    if (existing.contains(songId)) return;
    await db.insert('playlist_songs', {
      'playlist_id': playlistId,
      'song_id': songId,
      'position': existing.length,
    });
  }

  Future<void> removeSongFromPlaylist(String playlistId, String songId) async {
    final db = await database;
    await db.delete(
      'playlist_songs',
      where: 'playlist_id = ? AND song_id = ?',
      whereArgs: [playlistId, songId],
    );
    await _reindexPlaylist(db, playlistId);
  }

  Future<void> _reindexPlaylist(Database db, String playlistId) async {
    final ids = await getPlaylistSongIds(playlistId);
    for (var i = 0; i < ids.length; i++) {
      await db.update(
        'playlist_songs',
        {'position': i},
        where: 'playlist_id = ? AND song_id = ?',
        whereArgs: [playlistId, ids[i]],
      );
    }
  }

  Future<void> recordPlay(String songId, int durationMs) async {
    final db = await database;
    final rows = await db.query('play_stats', where: 'song_id = ?', whereArgs: [songId]);
    if (rows.isEmpty) {
      await db.insert('play_stats', {
        'song_id': songId,
        'play_count': 1,
        'total_ms': durationMs,
        'last_played': DateTime.now().millisecondsSinceEpoch,
      });
    } else {
      final count = (rows.first['play_count'] as int) + 1;
      final total = (rows.first['total_ms'] as int) + durationMs;
      await db.update(
        'play_stats',
        {
          'play_count': count,
          'total_ms': total,
          'last_played': DateTime.now().millisecondsSinceEpoch,
        },
        where: 'song_id = ?',
        whereArgs: [songId],
      );
    }
  }

  Future<List<Map<String, dynamic>>> getTopPlayed(int limit) async {
    final db = await database;
    return db.query(
      'play_stats',
      orderBy: 'play_count DESC',
      limit: limit,
    );
  }

  Future<Map<String, int>> getListeningSummary() async {
    final db = await database;
    final rows = await db.rawQuery(
      'SELECT SUM(play_count) as plays, SUM(total_ms) as ms FROM play_stats',
    );
    if (rows.isEmpty || rows.first['plays'] == null) {
      return {'plays': 0, 'ms': 0};
    }
    return {
      'plays': (rows.first['plays'] as int?) ?? 0,
      'ms': (rows.first['ms'] as int?) ?? 0,
    };
  }
}
