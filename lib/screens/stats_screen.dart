import 'package:donziker/providers/music_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class StatsScreen extends StatefulWidget {
  const StatsScreen({super.key});

  @override
  State<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen> {
  Map<String, int>? _summary;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final s = await context.read<MusicProvider>().getListeningSummary();
    if (mounted) setState(() => _summary = s);
  }

  String _formatMs(int ms) {
    final h = ms ~/ 3600000;
    final m = (ms % 3600000) ~/ 60000;
    if (h > 0) return '${h}h ${m}min';
    return '${m} min';
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<MusicProvider>();
    return Scaffold(
      appBar: AppBar(title: const Text('Statistiques')),
      body: _summary == null
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _card('Morceaux en bibliothèque', '${provider.songs.length}'),
                _card('Favoris', '${provider.favorites.length}'),
                _card('Lectures enregistrées', '${_summary!['plays']}'),
                _card('Temps d\'écoute', _formatMs(_summary!['ms'] ?? 0)),
                _card('Playlists', '${provider.playlists.length}'),
                const SizedBox(height: 16),
                const Text('DonZiker — statistiques locales uniquement, rien n\'est envoyé en ligne.',
                    style: TextStyle(color: Colors.white54)),
              ],
            ),
    );
  }

  Widget _card(String title, String value) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(title: Text(title), trailing: Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18))),
    );
  }
}
