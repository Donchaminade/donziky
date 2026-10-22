import 'package:donziker/services/database_service.dart';
import 'package:on_audio_query/on_audio_query.dart';

/// Temps d'écoute et classements, stockés localement.
class ListeningStatsService {
  ListeningStatsService(this._db);

  final DatabaseService _db;
  Duration lastStatsPosition = Duration.zero;
  List<String> topPlayedIds = [];
  Map<String, int>? previewSummary;

  void tick({
    required bool playing,
    required SongModel? song,
    required String? songId,
    required Duration position,
  }) {
    if (!playing || song == null || songId == null) return;
    final delta = position - lastStatsPosition;
    lastStatsPosition = position;
    if (delta.inMilliseconds > 500 && delta.inMilliseconds < 5000) {
      _db.recordPlay(songId, delta.inMilliseconds);
    }
  }

  void resetPosition() {
    lastStatsPosition = Duration.zero;
  }

  Future<void> loadTop() async {
    if (previewSummary != null) return;
    final rows = await _db.getTopPlayed(20);
    topPlayedIds = rows.map((r) => r['song_id'] as String).toList();
  }

  Future<Map<String, int>> summary() async {
    if (previewSummary != null) return previewSummary!;
    return _db.getListeningSummary();
  }
}
