import 'package:donziker/models/song_sort.dart';
import 'package:donziker/utils/song_utils.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:on_audio_query/on_audio_query.dart';

void main() {
  test('SongSort has French labels', () {
    expect(SongSort.title.label, 'Titre');
    expect(SongSort.dateAdded.label, 'Date d\'ajout');
  });

  test('sortSongs dateAdded descending puts newest first', () {
    final songs = [
      SongModel({
        'id': 1,
        'title': 'Old',
        'date_added': 100,
      }),
      SongModel({
        'id': 2,
        'title': 'New',
        'date_added': 500,
      }),
    ];
    final sorted = SongUtils.sortSongs(songs, SongSort.dateAdded, SortOrder.descending);
    expect(sorted.first.title, 'New');
    expect(sorted.last.title, 'Old');
  });
}
