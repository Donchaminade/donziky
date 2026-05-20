import 'package:donziker/providers/music_provider.dart';
import 'package:donziker/providers/theme_provider.dart';
import 'package:flutter/material.dart';
import 'package:on_audio_query/on_audio_query.dart';
import 'package:provider/provider.dart';

class AddToPlaylistSheet extends StatelessWidget {
  final SongModel song;

  const AddToPlaylistSheet({super.key, required this.song});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<MusicProvider>();
    final accent = context.watch<ThemeProvider>().effectiveAccent(provider.dynamicAccentColor);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        color: Color(0xFF1A1A1A),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Ajouter à une playlist',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
          const SizedBox(height: 16),
          if (provider.playlists.isEmpty)
            const Text('Aucune playlist. Créez-en une dans l\'onglet Playlists.',
                style: TextStyle(color: Colors.white54))
          else
            ...provider.playlists.map((pl) => ListTile(
                  leading: Icon(Icons.queue_music, color: accent),
                  title: Text(pl.name, style: const TextStyle(color: Colors.white)),
                  subtitle: Text('${pl.songCount} titres', style: const TextStyle(color: Colors.white54)),
                  onTap: () async {
                    await provider.addToPlaylist(pl.id, song);
                    if (context.mounted) {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Ajouté à « ${pl.name} »')),
                      );
                    }
                  },
                )),
          const SizedBox(height: 8),
          TextButton.icon(
            onPressed: () => _createAndAdd(context),
            icon: const Icon(Icons.add),
            label: const Text('Nouvelle playlist'),
          ),
        ],
      ),
    );
  }

  Future<void> _createAndAdd(BuildContext context) async {
    final nameController = TextEditingController();
    final name = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Nouvelle playlist'),
        content: TextField(
          controller: nameController,
          decoration: const InputDecoration(hintText: 'Nom de la playlist'),
          autofocus: true,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Annuler')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, nameController.text.trim()),
            child: const Text('Créer'),
          ),
        ],
      ),
    );
    if (name == null || name.isEmpty || !context.mounted) return;
    final provider = context.read<MusicProvider>();
    final id = await provider.createPlaylist(name);
    await provider.addToPlaylist(id, song);
    if (context.mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Playlist « $name » créée')));
    }
  }
}
