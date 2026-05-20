import 'package:donziker/models/song_sort.dart';
import 'package:donziker/providers/music_provider.dart';
import 'package:donziker/theme/theme_extensions.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

/// Menu rapide de tri (critère + ordre) pour la bibliothèque.
class LibrarySortButton extends StatelessWidget {
  const LibrarySortButton({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<MusicProvider>();
    final c = context.dz;

    return PopupMenuButton<String>(
      tooltip: 'Trier',
      icon: Icon(Icons.sort_rounded, color: c.primaryText),
      onSelected: (value) {
        if (value == 'toggle_order') {
          provider.toggleSortOrder();
          return;
        }
        final sort = SongSort.values.firstWhere((s) => s.name == value);
        provider.setSongSort(sort);
      },
      itemBuilder: (ctx) {
        final items = <PopupMenuEntry<String>>[
          PopupMenuItem(
            enabled: false,
            child: Text(
              'Trier par',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                color: c.secondaryText,
                fontSize: 12,
              ),
            ),
          ),
          ...SongSort.values.map((sort) {
            final selected = provider.songSort == sort;
            return PopupMenuItem<String>(
              value: sort.name,
              child: Row(
                children: [
                  Icon(
                    selected ? Icons.check_rounded : Icons.circle_outlined,
                    size: 18,
                    color: selected ? c.accent : c.secondaryText,
                  ),
                  const SizedBox(width: 10),
                  Text(sort.label),
                ],
              ),
            );
          }),
          const PopupMenuDivider(),
          PopupMenuItem<String>(
            value: 'toggle_order',
            child: Row(
              children: [
                Icon(
                  provider.sortOrder == SortOrder.ascending
                      ? Icons.arrow_upward_rounded
                      : Icons.arrow_downward_rounded,
                  size: 18,
                  color: c.accent,
                ),
                const SizedBox(width: 10),
                Text(provider.sortOrder.label),
              ],
            ),
          ),
        ];
        return items;
      },
    );
  }
}
