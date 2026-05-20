import 'package:donziker/providers/music_provider.dart';
import 'package:donziker/screens/home_screen.dart';
import 'package:donziker/services/permission_service.dart';
import 'package:donziker/theme/theme_extensions.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

/// Logo après le splash natif → permissions (une seule fois) → accueil.
class SplashPermissionScreen extends StatefulWidget {
  const SplashPermissionScreen({super.key});

  @override
  State<SplashPermissionScreen> createState() => _SplashPermissionScreenState();
}

class _SplashPermissionScreenState extends State<SplashPermissionScreen> {
  bool _logoVisible = false;
  final _permissionService = PermissionService();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _bootstrap());
  }

  Future<void> _bootstrap() async {
    await Future.delayed(const Duration(milliseconds: 900));
    if (!mounted) return;
    setState(() => _logoVisible = true);

    final provider = context.read<MusicProvider>();
    final wasGranted = await MusicProvider.wasMediaGrantedBefore();
    final onboardingDone = await MusicProvider.wasOnboardingDone();

    await provider.refreshPermissionStatus();
    if (!mounted) return;

    if (provider.permissionGranted) {
      await _openHome();
      return;
    }

    // Déjà autorisé avant mais permission révoquée → demande système directe, sans long dialogue
    if (wasGranted || onboardingDone) {
      await provider.checkAndRequestPermissions();
      if (!mounted) return;
      if (provider.permissionGranted) {
        await _openHome();
        return;
      }
      await _showOpenSettingsDialog();
      return;
    }

    // Première installation : dialogue explicatif puis pop-up système
    await _showFirstLaunchDialog(provider);
  }

  Future<void> _showFirstLaunchDialog(MusicProvider provider) async {
    final proceed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        icon: Icon(Icons.library_music_rounded, size: 48, color: context.dzAccent),
        title: const Text('Accès à votre musique'),
        content: const Text(
          'DonZiker lit uniquement les fichiers déjà sur votre téléphone.\n\n'
          'Appuyez sur « Continuer » : Android affichera sa fenêtre d\'autorisation. '
          'Vous ne serez pas redemandé à chaque ouverture une fois accepté.',
          textAlign: TextAlign.center,
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Continuer'),
          ),
        ],
      ),
    );

    if (!mounted || proceed != true) return;

    await provider.checkAndRequestPermissions();
    if (!mounted) return;

    if (provider.permissionGranted) {
      await _openHome();
    } else {
      await _showOpenSettingsDialog();
    }
  }

  Future<void> _showOpenSettingsDialog() async {
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Permission refusée'),
        content: const Text(
          'Sans accès aux fichiers audio, DonZiker ne peut pas scanner votre musique.\n\n'
          'Activez « Musique et audio » (ou « Fichiers ») dans les paramètres de l\'application.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Fermer')),
          FilledButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await _permissionService.openSystemSettings();
            },
            child: const Text('Ouvrir les paramètres'),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.pop(ctx);
              final provider = context.read<MusicProvider>();
              await provider.checkAndRequestPermissions();
              if (provider.permissionGranted && mounted) await _openHome();
            },
            child: const Text('Réessayer'),
          ),
        ],
      ),
    );
    if (mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const HomeScreen()),
      );
    }
  }

  Future<void> _openHome() async {
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const HomeScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = context.dz;
    return Scaffold(
      backgroundColor: c.surface,
      body: Center(
        child: AnimatedOpacity(
          opacity: _logoVisible ? 1 : 0.4,
          duration: const Duration(milliseconds: 500),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset(
                'assets/images/logo.png',
                height: 140,
                errorBuilder: (_, __, ___) =>
                    const Icon(Icons.music_note, size: 120, color: Colors.white),
              ),
              const SizedBox(height: 24),
              Text(
                'DonZiker',
                style: TextStyle(fontSize: 32, fontWeight: FontWeight.w900, color: c.primaryText),
              ),
              const SizedBox(height: 28),
              CircularProgressIndicator(color: c.accent),
            ],
          ),
        ),
      ),
    );
  }
}
