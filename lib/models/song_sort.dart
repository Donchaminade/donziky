enum SongSort { title, artist, album, duration, dateAdded }

extension SongSortLabel on SongSort {
  String get label {
    switch (this) {
      case SongSort.title:
        return 'Titre';
      case SongSort.artist:
        return 'Artiste';
      case SongSort.album:
        return 'Album';
      case SongSort.duration:
        return 'Durée';
      case SongSort.dateAdded:
        return 'Date d\'ajout';
    }
  }
}
