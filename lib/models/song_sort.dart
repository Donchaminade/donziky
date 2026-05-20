enum SongSort { dateAdded, title, artist, album, duration }

enum SortOrder { ascending, descending }

extension SongSortLabel on SongSort {
  String get label {
    switch (this) {
      case SongSort.dateAdded:
        return 'Date d\'ajout';
      case SongSort.title:
        return 'Titre';
      case SongSort.artist:
        return 'Artiste';
      case SongSort.album:
        return 'Album';
      case SongSort.duration:
        return 'Durée';
    }
  }

  /// Ordre recommandé quand on choisit ce critère.
  SortOrder get defaultOrder {
    switch (this) {
      case SongSort.dateAdded:
      case SongSort.duration:
        return SortOrder.descending;
      default:
        return SortOrder.ascending;
    }
  }
}

extension SortOrderLabel on SortOrder {
  String get label => this == SortOrder.ascending ? 'Croissant' : 'Décroissant';

  String get shortLabel =>
      this == SortOrder.ascending ? 'A→Z / court→long' : 'Z→A / long→court / récent';
}
