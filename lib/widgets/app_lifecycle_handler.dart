import 'package:donziker/providers/music_provider.dart';
import 'package:donziker/services/playback_continuity.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

/// Sauvegarde la lecture quand l'app passe en arrière-plan ou se ferme.
class AppLifecycleHandler extends StatefulWidget {
  final Widget child;

  const AppLifecycleHandler({super.key, required this.child});

  @override
  State<AppLifecycleHandler> createState() => _AppLifecycleHandlerState();
}

class _AppLifecycleHandlerState extends State<AppLifecycleHandler> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // paused / inactive / detached / hidden : on enregistre la position.
    // Aucun de ces états ne met la lecture en pause.
    if (PlaybackContinuity.lifecycleStopsPlayback(state.name)) return;
    if (!mounted) return;
    if (state == AppLifecycleState.inactive) return;
    try {
      context.read<MusicProvider>().onAppPaused();
    } catch (e, st) {
      debugPrint('sauvegarde au cycle de vie: $e\n$st');
    }
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
