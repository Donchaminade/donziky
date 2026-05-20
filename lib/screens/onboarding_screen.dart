import 'package:donziker/providers/music_provider.dart';
import 'package:donziker/screens/home_screen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class OnboardingScreen extends StatelessWidget {
  const OnboardingScreen({super.key});

  Future<void> _complete(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_completed', true);
    if (context.mounted) {
      Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => const HomeScreen()));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<MusicProvider>(
      builder: (context, musicProvider, _) {
        if (musicProvider.permissionGranted) {
          WidgetsBinding.instance.addPostFrameCallback((_) => _complete(context));
        }

        return Scaffold(
          backgroundColor: const Color(0xFF121212),
          body: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(28),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.library_music, size: 100, color: Colors.deepPurpleAccent),
                  const SizedBox(height: 32),
                  const Text(
                    'Bienvenue sur DonZiker',
                    style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'DonZiker ne contient aucune musique : l\'application lit uniquement les fichiers audio et vidéo déjà présents sur votre téléphone.',
                    style: TextStyle(fontSize: 16, color: Colors.white70, height: 1.4),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Vos fichiers restent sur l\'appareil. Rien n\'est envoyé sur Internet.',
                    style: TextStyle(fontSize: 14, color: Colors.white54),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 48),
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
