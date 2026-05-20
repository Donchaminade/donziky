import 'dart:ui';
import 'package:donziker/providers/music_provider.dart';
import 'package:donziker/providers/theme_provider.dart';
import 'package:donziker/services/platform_media_service.dart';
import 'package:donziker/utils/song_utils.dart';
import 'package:donziker/widgets/add_to_playlist_sheet.dart';
import 'package:flutter/material.dart';
import 'package:on_audio_query/on_audio_query.dart';
import 'package:provider/provider.dart';

class SongOptionsSheet extends StatelessWidget {
  final SongModel song;

  const SongOptionsSheet({super.key, required this.song});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<MusicProvider>(context);
    final theme = Provider.of<ThemeProvider>(context);
    final songId = SongUtils.songId(song);
    final isFavorite = provider.isFavorite(songId);
    final accent = theme.effectiveAccent(provider.dynamicAccentColor, useDynamic: provider.useDynamicAccent);

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 24),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.85),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(width: 40, height: 5, decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(10))),
              const SizedBox(height: 20),
              Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: QueryArtworkWidget(
                      id: song.id,
                      type: ArtworkType.AUDIO,
                      artworkWidth: 60,
                      artworkHeight: 60,
                      nullArtworkWidget: const Icon(Icons.music_note, size: 40),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(song.title, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold), maxLines: 1, overflow: TextOverflow.ellipsis),
                        Text(song.artist ?? 'Artiste inconnu', style: TextStyle(color: Colors.white.withValues(alpha: 0.5)), maxLines: 1, overflow: TextOverflow.ellipsis),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              _option(
                icon: isFavorite ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                label: isFavorite ? 'Retirer des favoris' : 'Ajouter aux favoris',
                color: isFavorite ? accent : Colors.white,
                onTap: () {
                  provider.toggleFavorite(songId);
                  Navigator.pop(context);
                },
              ),
              _option(
                icon: Icons.playlist_add_rounded,
                label: 'Ajouter à une playlist',
                onTap: () {
                  Navigator.pop(context);
                  showModalBottomSheet(
                    context: context,
                    backgroundColor: Colors.transparent,
                    builder: (_) => AddToPlaylistSheet(song: song),
                  );
                },
              ),
              _option(
                icon: Icons.ring_volume,
                label: 'Définir comme sonnerie',
                onTap: () async {
                  Navigator.pop(context);
                  final ok = await PlatformMediaService.setAsRingtone(song.data);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(ok
                            ? 'Sonnerie mise à jour'
                            : 'Impossible de définir la sonnerie (Android uniquement)'),
                      ),
                    );
                  }
                },
              ),
              _option(
                icon: Icons.repeat_one_rounded,
                label: 'Jouer en boucle',
                onTap: () {
                  provider.forceRepeatOne();
                  Navigator.pop(context);
                },
              ),
              _option(
                icon: Icons.folder_off_outlined,
                label: 'Exclure le dossier parent',
                onTap: () async {
                  await provider.addExcludedFolder(SongUtils.folderPath(song));
                  if (context.mounted) Navigator.pop(context);
                },
              ),
              _option(
                icon: Icons.info_outline_rounded,
                label: 'Informations fichier',
                onTap: () {
                  Navigator.pop(context);
                  _showFileInfo(context, song);
                },
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }

  Widget _option({required IconData icon, required String label, Color color = Colors.white, required VoidCallback onTap}) {
    return ListTile(
      leading: Icon(icon, color: color),
      title: Text(label, style: TextStyle(color: color)),
      onTap: onTap,
      contentPadding: EdgeInsets.zero,
    );
  }

  void _showFileInfo(BuildContext context, SongModel song) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Détails'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _row('Titre', song.title),
            _row('Artiste', song.artist ?? 'Inconnu'),
            _row('Album', song.album ?? 'Inconnu'),
            _row('Genre', song.genre ?? '—'),
            _row('Format', song.fileExtension),
            _row('Durée', '${(song.duration ?? 0) ~/ 1000}s'),
            _row('Chemin', song.data),
          ],
        ),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('OK'))],
      ),
    );
  }

  Widget _row(String k, String v) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: RichText(text: TextSpan(style: const TextStyle(color: Colors.white), children: [
          TextSpan(text: '$k: ', style: const TextStyle(fontWeight: FontWeight.bold)),
          TextSpan(text: v),
        ])),
      );
}
