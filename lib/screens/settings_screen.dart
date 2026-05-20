import 'package:donziker/models/song_sort.dart';
import 'package:donziker/providers/music_provider.dart';
import 'package:donziker/providers/theme_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final musicProvider = Provider.of<MusicProvider>(context);
    final accent = themeProvider.effectiveAccent(
      musicProvider.dynamicAccentColor,
      useDynamic: musicProvider.useDynamicAccent,
    );

    return Scaffold(
      appBar: AppBar(title: const Text('Paramètres')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _title('Apparence'),
          SwitchListTile(
            title: const Text('Mode sombre'),
            value: themeProvider.themeMode == ThemeMode.dark,
            onChanged: themeProvider.toggleTheme,
          ),
          SwitchListTile(
            title: const Text('Couleur depuis la pochette'),
            subtitle: const Text('Sinon, couleur d\'accent choisie ci-dessous'),
            value: musicProvider.useDynamicAccent,
            onChanged: musicProvider.setUseDynamicAccent,
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Wrap(
              spacing: 10,
              children: [
                Colors.redAccent,
                Colors.blueAccent,
                Colors.greenAccent,
                Colors.purpleAccent,
                Colors.orangeAccent,
                Colors.pinkAccent,
              ].map((c) => GestureDetector(
                    onTap: () => themeProvider.updateAccentColor(c),
                    child: CircleAvatar(
                      radius: 20,
                      backgroundColor: c,
                      child: themeProvider.accentColor == c ? const Icon(Icons.check, color: Colors.white, size: 18) : null,
                    ),
                  )).toList(),
            ),
          ),
          const Divider(),
          _title('Bibliothèque locale'),
          ListTile(
            title: const Text('Rescanner le téléphone'),
            trailing: const Icon(Icons.refresh),
            onTap: musicProvider.refreshLibrary,
          ),
          DropdownButtonFormField<SongSort>(
            value: musicProvider.songSort,
            decoration: const InputDecoration(labelText: 'Tri par défaut'),
            items: SongSort.values.map((s) => DropdownMenuItem(value: s, child: Text(s.label))).toList(),
            onChanged: (v) {
              if (v != null) musicProvider.setSongSort(v);
            },
          ),
          SwitchListTile(
            title: const Text('Masquer les sons courts'),
            subtitle: const Text('Sonneries, notifications (< 10 s)'),
            value: musicProvider.hideShortSounds,
            onChanged: musicProvider.setHideShortSounds,
          ),
          if (musicProvider.excludedFolders.isNotEmpty) ...[
            const SizedBox(height: 8),
            const Text('Dossiers exclus', style: TextStyle(fontWeight: FontWeight.bold)),
            ...musicProvider.excludedFolders.map((f) => ListTile(
                  dense: true,
                  title: Text(f, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12)),
                  trailing: IconButton(
                    icon: const Icon(Icons.close, size: 18),
                    onPressed: () => musicProvider.removeExcludedFolder(f),
                  ),
                )),
          ],
          SwitchListTile(
            title: const Text('Mode karaoké'),
            subtitle: const Text('Passe au morceau suivant quelques secondes avant la fin'),
            value: musicProvider.karaokeMode,
            onChanged: (_) => musicProvider.toggleKaraokeMode(),
          ),
          ListTile(
            title: const Text('Anticipation karaoké (secondes)'),
            trailing: DropdownButton<int>(
              value: musicProvider.karaokeLeadSeconds,
              items: [5, 8, 10, 12, 15]
                  .map((s) => DropdownMenuItem(value: s, child: Text('$s s')))
                  .toList(),
              onChanged: (v) {
                if (v != null) musicProvider.setKaraokeLeadSeconds(v);
              },
            ),
          ),
          const Divider(),
          _title('Lecture'),
          ListTile(
            title: const Text('Reprendre la dernière lecture'),
            subtitle: const Text('Automatique au démarrage si disponible'),
          ),
          const Divider(),
          _title('À propos'),
          ListTile(title: const Text('Version'), trailing: Text('1.2.0', style: TextStyle(color: accent))),
          const ListTile(title: Text('Développeur'), trailing: Text('DonChaminade')),
          const ListTile(
            title: Text('DonZiker'),
            subtitle: Text('Lecteur 100 % local — musique et vidéos de votre appareil uniquement.'),
          ),
        ],
      ),
    );
  }

  Widget _title(String t) => Padding(
        padding: const EdgeInsets.only(bottom: 8, top: 8),
        child: Text(t.toUpperCase(), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white54)),
      );
}
