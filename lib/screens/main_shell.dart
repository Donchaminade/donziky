import 'package:donziker/providers/music_provider.dart';
import 'package:donziker/screens/favorites_screen.dart';
import 'package:donziker/screens/home_tab_screen.dart';
import 'package:donziker/screens/library_hub_screen.dart';
import 'package:donziker/screens/settings_screen.dart';
import 'package:donziker/theme/theme_extensions.dart';
import 'package:donziker/widgets/floating_bottom_nav.dart';
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
          extendBody: true,
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
              FloatingBottomNav(
                selectedIndex: _index,
                onSelected: (i) {
                  setState(() => _index = i);
                  provider.setShellTab(i);
                },
              ),
              SizedBox(height: MediaQuery.paddingOf(context).bottom > 0 ? 4 : 12),
            ],
          ),
        );
      },
    );
  }
}
