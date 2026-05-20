import 'package:donziker/models/song_sort.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('SongSort has French labels', () {
    expect(SongSort.title.label, 'Titre');
    expect(SongSort.artist.label, 'Artiste');
  });
}
