class LocalPlaylist {
  final String id;
  final String name;
  final int createdAt;
  final int songCount;

  const LocalPlaylist({
    required this.id,
    required this.name,
    required this.createdAt,
    this.songCount = 0,
  });

  factory LocalPlaylist.fromMap(Map<String, dynamic> map) {
    return LocalPlaylist(
      id: map['id'] as String,
      name: map['name'] as String,
      createdAt: map['created_at'] as int,
      songCount: (map['song_count'] as int?) ?? 0,
    );
  }
}
