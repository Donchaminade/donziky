import 'dart:ui';

import 'package:donziker/providers/music_provider.dart';
import 'package:donziker/screens/favorites_screen.dart';
import 'package:donziker/screens/home_tab_screen.dart';
import 'package:donziker/screens/library_hub_screen.dart';
import 'package:donziker/screens/settings_screen.dart';
import 'package:donziker/theme/theme_extensions.dart';
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
  Widget build(BuildContext context) {
    final c = context.dz;

    return Consumer<MusicProvider>(
      builder: (context, provider, _) {
        if (provider.shellTabIndex != _index) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) setState(() => _index = provider.shellTabIndex);
          });
        }

        return Scaffold(
          backgroundColor: c.surface,
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
              ClipRect(
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
                  child: NavigationBar(
                    selectedIndex: _index,
                    backgroundColor: c.surface.withValues(alpha: 0.88),
                    indicatorColor: c.accent.withValues(alpha: 0.22),
                    surfaceTintColor: Colors.transparent,
                    onDestinationSelected: (i) {
                      setState(() => _index = i);
                      provider.setShellTab(i);
                    },
                    destinations: const [
                      NavigationDestination(
                        icon: Icon(Icons.home_outlined),
                        selectedIcon: Icon(Icons.home_rounded),
                        label: 'Accueil',
                      ),
                      NavigationDestination(
                        icon: Icon(Icons.library_music_outlined),
                        selectedIcon: Icon(Icons.library_music_rounded),
                        label: 'Bibliothèque',
                      ),
                      NavigationDestination(
                        icon: Icon(Icons.favorite_outline_rounded),
                        selectedIcon: Icon(Icons.favorite_rounded),
                        label: 'Favoris',
                      ),
                      NavigationDestination(
                        icon: Icon(Icons.settings_outlined),
                        selectedIcon: Icon(Icons.settings_rounded),
                        label: 'Réglages',
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
