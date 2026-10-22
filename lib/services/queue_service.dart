import 'package:donziker/utils/song_utils.dart';
import 'package:just_audio/just_audio.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'package:on_audio_query/on_audio_query.dart';

/// File d'attente : ordre des morceaux et déplacement.
class QueueService {
  List<SongModel> items = [];
  int currentIndex = -1;

  SongModel? get current {
    if (currentIndex < 0 || currentIndex >= items.length) return null;
    return items[currentIndex];
  }

  /// Même convention que [ReorderableListView] : si [newIndex] > [oldIndex],
  /// il désigne la position après le retrait.
  static ({List<T> items, int currentIndex}) applyReorder<T>(
    List<T> source,
    int currentIndex,
    int oldIndex,
    int newIndex, {
    bool adjustForRemoval = true,
  }) {
    final items = List<T>.from(source);
    if (oldIndex < 0 || oldIndex >= items.length) {
      return (items: items, currentIndex: currentIndex);
    }
    var target = newIndex;
    if (adjustForRemoval && target > oldIndex) target -= 1;
    target = target.clamp(0, items.length - 1);
    final item = items.removeAt(oldIndex);
    items.insert(target, item);

    var current = currentIndex;
    if (currentIndex == oldIndex) {
      current = target;
    } else if (oldIndex < currentIndex && target >= currentIndex) {
      current -= 1;
    } else if (oldIndex > currentIndex && target <= currentIndex) {
      current += 1;
    }
    return (items: items, currentIndex: current);
  }

  void replace(List<SongModel> songs, int index) {
    items = List<SongModel>.from(songs);
    currentIndex = items.isEmpty ? -1 : index.clamp(0, items.length - 1);
  }

  void reorder(int oldIndex, int newIndex, {bool adjustForRemoval = true}) {
    final result = applyReorder(
      items,
      currentIndex,
      oldIndex,
      newIndex,
      adjustForRemoval: adjustForRemoval,
    );
    items = result.items;
    currentIndex = result.currentIndex;
  }

  /// Index final (après retrait) attendu par [ConcatenatingAudioSource.move]
  /// quand `move` insère sans réajuster. [newIndex] suit ReorderableListView.
  static int audioMoveTarget(int oldIndex, int newIndex) {
    var target = newIndex;
    if (target > oldIndex) target -= 1;
    return target;
  }

  Future<void> loadInto(AudioPlayer player, {required bool gapless}) async {
    final playlist = ConcatenatingAudioSource(
      useLazyPreparation: true,
      children: items.map((song) {
        return AudioSource.uri(
          Uri.parse(song.uri!),
          tag: MediaItem(
            id: SongUtils.songId(song),
            album: song.album ?? 'Album inconnu',
            title: song.title,
            artist: song.artist ?? 'Artiste inconnu',
            artUri: Uri.parse('content://media/external/audio/media/${song.id}/albumart'),
          ),
        );
      }).toList(),
    );
    await player.setAudioSource(
      playlist,
      initialIndex: currentIndex < 0 ? 0 : currentIndex,
      preload: gapless,
    );
  }

  int indexOfId(int id, {List<SongModel>? within}) {
    final list = within ?? items;
    return list.indexWhere((s) => s.id == id);
  }

  SongModel? byPersistentId(String id, List<SongModel> library) {
    for (final song in library) {
      if (SongUtils.songId(song) == id) return song;
    }
    return null;
  }
}
