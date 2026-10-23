import 'package:donziker/providers/music_provider.dart';
import 'package:donziker/providers/theme_provider.dart';
import 'package:donziker/screens/home_screen.dart';
import 'package:donziker/theme/app_theme.dart';
import 'package:donziker/theme/theme_extensions.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  late final TextEditingController _name;

  @override
  void initState() {
    super.initState();
    _name = TextEditingController(text: context.read<ThemeProvider>().displayName);
  }

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _complete(BuildContext context) async {
    final theme = context.read<ThemeProvider>();
    await theme.setDisplayName(_name.text);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_completed', true);
    if (context.mounted) {
      Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => const HomeScreen()));
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.dz;
    return Consumer<MusicProvider>(
      builder: (context, musicProvider, _) {
        if (musicProvider.permissionGranted) {
          WidgetsBinding.instance.addPostFrameCallback((_) => _complete(context));
        }

        return Scaffold(
          backgroundColor: c.surface,
          body: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(28),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 96,
                    height: 96,
                    decoration: const BoxDecoration(color: AppTheme.lime, shape: BoxShape.circle),
                    child: const Icon(Icons.library_music_rounded, size: 48, color: AppTheme.ink),
                  ),
                  const SizedBox(height: 32),
                  Text(
                    'Bienvenue sur DonZiker',
                    style: TextStyle(fontSize: 28, fontWeight: FontWeight.w700, color: c.primaryText, letterSpacing: -0.6),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'DonZiker ne contient aucune musique : l\'application lit uniquement les fichiers audio et vidéo déjà présents sur votre téléphone.',
                    style: TextStyle(fontSize: 16, color: c.secondaryText, height: 1.4),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Vos fichiers restent sur l\'appareil. Rien n\'est envoyé sur Internet.',
                    style: TextStyle(fontSize: 14, color: c.tertiaryText),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 28),
                  TextField(
                    controller: _name,
                    textCapitalization: TextCapitalization.words,
                    decoration: const InputDecoration(hintText: 'Ton prénom'),
                  ),
                  const SizedBox(height: 28),
                  FilledButton(
                    onPressed: () => musicProvider.checkAndRequestPermissions(),
                    child: const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      child: Text('Autoriser l\'accès aux médias'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
