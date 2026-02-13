import 'package:donziker/providers/music_provider.dart';
import 'package:donziker/providers/theme_provider.dart';
import 'package:donziker/screens/home_screen.dart';
import 'package:donziker/screens/onboarding_screen.dart';
import 'package:donziker/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> main() async {
  try {
    WidgetsFlutterBinding.ensureInitialized();
    
    // Initialisation séquentielle pour éviter les conflits SQLite au démarrage
    await JustAudioBackground.init(
      androidNotificationChannelId: 'com.ryanheise.bg_demo.channel.audio',
      androidNotificationChannelName: 'Audio playback',
      androidNotificationOngoing: true,
    );
    
    // Pause pour laisser les services se stabiliser
    await Future.delayed(const Duration(milliseconds: 300));

    final prefs = await SharedPreferences.getInstance();
    final bool onboardingCompleted = prefs.getBool('onboarding_completed') ?? false;

    final musicProvider = MusicProvider();
    final themeProvider = ThemeProvider();

    // Init provider et attendre un peu
    await musicProvider.init();
    await Future.delayed(const Duration(milliseconds: 200));

    runApp(
      MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: musicProvider),
          ChangeNotifierProvider.value(value: themeProvider),
        ],
        child: MyApp(onboardingCompleted: onboardingCompleted),
      ),
    );
  } catch (e, stack) {
    debugPrint("Critical startup error: $e\n$stack");
    runApp(MaterialApp(home: Scaffold(body: Center(child: Text("Erreur au démarrage: $e")))));
  }
}

class MyApp extends StatelessWidget {
  final bool onboardingCompleted;

  const MyApp({super.key, required this.onboardingCompleted});

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return MaterialApp(
          title: 'DonZiker',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme(themeProvider.accentColor),
          darkTheme: AppTheme.darkTheme(themeProvider.accentColor),
          themeMode: themeProvider.themeMode,
          // On s'assure que l'onboarding ou Home ne se lancent qu'une fois tout prêt
          home: onboardingCompleted ? const HomeScreen() : const OnboardingScreen(),
        );
      },
    );
  }
}