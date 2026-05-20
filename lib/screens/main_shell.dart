import 'package:donziker/providers/music_provider.dart';
import 'package:donziker/screens/favorites_screen.dart';
import 'package:donziker/screens/home_tab_screen.dart';
import 'package:donziker/screens/library_hub_screen.dart';
import 'package:donziker/screens/settings_screen.dart';
import 'package:donziker/widgets/mini_player.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _index = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _syncFromProvider());
  }

  void _syncFromProvider() {
    final provider = context.read<MusicProvider>();
    if (provider.shellTabIndex != _index) {
      setState(() => _index = provider.shellTabIndex);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<MusicProvider>(
      builder: (context, provider, _) {
        if (provider.shellTabIndex != _index) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) setState(() => _index = provider.shellTabIndex);
          });
        }

        return Scaffold(
          body: IndexedStack(
            index: _index,
            children: const [
              HomeTabScreen(),
              LibraryHubScreen(),
              FavoritesScreen(),
              SettingsScreen(),
            ],
          ),
          bottomNavigationBar: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const MiniPlayer(),
              NavigationBar(
                selectedIndex: _index,
                onDestinationSelected: (i) {
                  setState(() => _index = i);
                  provider.setShellTab(i);
                },
                destinations: const [
                  NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home), label: 'Accueil'),
                  NavigationDestination(
                      icon: Icon(Icons.library_music_outlined),
                      selectedIcon: Icon(Icons.library_music),
                      label: 'Bibliothèque'),
                  NavigationDestination(
                      icon: Icon(Icons.favorite_border), selectedIcon: Icon(Icons.favorite), label: 'Favoris'),
                  NavigationDestination(
                      icon: Icon(Icons.settings_outlined), selectedIcon: Icon(Icons.settings), label: 'Réglages'),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
