import 'package:donziker/providers/music_provider.dart';
import 'package:donziker/screens/home_screen.dart';
import 'package:donziker/services/permission_service.dart';
import 'package:donziker/theme/app_theme.dart';
import 'package:donziker/theme/theme_extensions.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

/// Permissions après le splash animé (dialogues uniquement si [skipIntro]).
class SplashPermissionScreen extends StatefulWidget {
  final bool skipIntro;
  final bool preview;

  const SplashPermissionScreen({super.key, this.skipIntro = false, this.preview = false});

  @override
  State<SplashPermissionScreen> createState() => _SplashPermissionScreenState();
}

class _SplashPermissionScreenState extends State<SplashPermissionScreen> {
  final _permissionService = PermissionService();

  @override
  void initState() {
    super.initState();
    if (!widget.preview) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _bootstrap());
    }
  }

  Future<void> _bootstrap() async {
    if (!widget.skipIntro) {
      await Future.delayed(const Duration(milliseconds: 400));
    }
    if (!mounted) return;

    final provider = context.read<MusicProvider>();
    final wasGranted = await MusicProvider.wasMediaGrantedBefore();
    final onboardingDone = await MusicProvider.wasOnboardingDone();

    await provider.refreshPermissionStatus();
    if (!mounted) return;

    if (provider.permissionGranted) {
      await _openHome();
      return;
    }

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
    await _permissionService.ensureNotificationPermission();
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => const HomeScreen(),
        transitionDuration: const Duration(milliseconds: 500),
        transitionsBuilder: (_, animation, __, child) =>
            FadeTransition(opacity: animation, child: child),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = context.dz;
    return Scaffold(
      backgroundColor: c.surface,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 88,
                height: 88,
                decoration: const BoxDecoration(color: AppTheme.lime, shape: BoxShape.circle),
                child: const Icon(Icons.library_music_rounded, color: AppTheme.ink, size: 42),
              ),
              const SizedBox(height: 28),
              Text(
                'Accès à ta musique',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.w700, letterSpacing: -0.6, color: c.primaryText),
              ),
              const SizedBox(height: 14),
              Text(
                'DonZiker lit uniquement les fichiers déjà sur ton téléphone. Android demandera « Musique et audio » (READ_MEDIA_AUDIO à partir d\'Android 13).',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, height: 1.4, color: c.secondaryText),
              ),
              const SizedBox(height: 28),
              FilledButton(
                onPressed: widget.preview
                    ? () {}
                    : () => context.read<MusicProvider>().checkAndRequestPermissions(),
                child: const Text('Continuer'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
