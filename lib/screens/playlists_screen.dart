import 'package:donziker/providers/music_provider.dart';
import 'package:donziker/screens/playlist_detail_screen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class PlaylistsScreen extends StatelessWidget {
  const PlaylistsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<MusicProvider>();
    final playlists = provider.playlists;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: FilledButton.icon(
            onPressed: () => _createPlaylist(context),
            icon: const Icon(Icons.add),
            label: const Text('Créer une playlist'),
          ),
        ),
        Expanded(
          child: playlists.isEmpty
              ? const Center(child: Text('Aucune playlist personnalisée'))
              : ListView.builder(
                  itemCount: playlists.length,
                  itemBuilder: (context, i) {
                    final pl = playlists[i];
                    return ListTile(
                      leading: const Icon(Icons.queue_music),
                      title: Text(pl.name),
                      subtitle: Text('${pl.songCount} titres'),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete_outline),
                        onPressed: () async {
                          final ok = await showDialog<bool>(
                            context: context,
                            builder: (ctx) => AlertDialog(
                              title: const Text('Supprimer ?'),
                              content: Text('Supprimer « ${pl.name} » ?'),
                              actions: [
                                TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Non')),
                                TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Oui')),
                              ],
                            ),
                          );
                          if (ok == true) await provider.deletePlaylist(pl.id);
                        },
                      ),
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => PlaylistDetailScreen(playlistId: pl.id, name: pl.name)),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Future<void> _createPlaylist(BuildContext context) async {
    final controller = TextEditingController();
    final name = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Nouvelle playlist'),
        content: TextField(controller: controller, decoration: const InputDecoration(hintText: 'Nom')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Annuler')),
          TextButton(onPressed: () => Navigator.pop(ctx, controller.text.trim()), child: const Text('Créer')),
        ],
      ),
    );
    if (name != null && name.isNotEmpty && context.mounted) {
      await context.read<MusicProvider>().createPlaylist(name);
    }
  }
}
