import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:on_audio_query/on_audio_query.dart';
import 'package:provider/provider.dart';
import '../providers/music_provider.dart';

class SongOptionsSheet extends StatelessWidget {
  final SongModel song;

  const SongOptionsSheet({super.key, required this.song});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<MusicProvider>(context);
    final isFavorite = provider.isFavorite(song.id.toString());
    final accentColor = provider.currentAccentColor;

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 24),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.85),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
            border: Border.all(color: Colors.white.withOpacity(0.05)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Pull bar
              Container(
                width: 40,
                height: 5,
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              const SizedBox(height: 25),
              // Song Info Header
              Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: QueryArtworkWidget(
                      id: song.id,
                      type: ArtworkType.AUDIO,
                      artworkWidth: 60,
                      artworkHeight: 60,
                      nullArtworkWidget: Container(
                        width: 60,
                        height: 60,
                        color: Colors.white10,
                        child: const Icon(Icons.music_note, color: Colors.white30),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          song.title,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          song.artist ?? "Artiste inconnu",
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.5),
                            fontSize: 14,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 30),
              // Options
              _buildOption(
                icon: isFavorite ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                label: isFavorite ? "Retirer des favoris" : "Ajouter aux favoris",
                color: isFavorite ? accentColor : Colors.white,
                onTap: () {
                  provider.toggleFavorite(song.id.toString());
                  Navigator.pop(context);
                },
              ),
              _buildOption(
                icon: Icons.repeat_one_rounded,
                label: "Jouer en boucle cette chanson",
                color: provider.repeatMode == RepeatMode.one ? accentColor : Colors.white,
                onTap: () {
                  // On forcer le mode boucle 1
                  provider.forceRepeatOne(); 
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("Mode répétition de la chanson activé"),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                },
              ),
              _buildOption(
                icon: Icons.playlist_add_rounded,
                label: "Ajouter à une playlist",
                onTap: () {
                  // TODO: Playlist logic
                  Navigator.pop(context);
                },
              ),
              _buildOption(
                icon: Icons.info_outline_rounded,
                label: "Informations sur le fichier",
                onTap: () {
                   Navigator.pop(context);
                   _showFileInfo(context, song);
                },
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOption({
    required IconData icon,
    required String label,
    Color color = Colors.white,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: color.withOpacity(0.8), size: 28),
      title: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
      ),
      onTap: onTap,
      contentPadding: EdgeInsets.zero,
    );
  }

  void _showFileInfo(BuildContext context, SongModel song) {
     showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: const Text("Détails", style: TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _detailRow("Titre", song.title),
            _detailRow("Artiste", song.artist ?? "Inconnu"),
            _detailRow("Album", song.album ?? "Inconnu"),
            _detailRow("Format", song.fileExtension),
            _detailRow("Dossier", song.data.substring(0, song.data.lastIndexOf('/'))),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("OK")),
        ],
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: RichText(
        text: TextSpan(
          children: [
            TextSpan(text: "$label: ", style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white70)),
            TextSpan(text: value, style: const TextStyle(color: Colors.white)),
          ],
        ),
      ),
    );
  }
}
