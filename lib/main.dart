import 'package:donziker/providers/music_provider.dart';
import 'package:donziker/providers/theme_provider.dart';
import 'package:donziker/screens/home_screen.dart';
import 'package:donziker/screens/splash_permission_screen.dart';
import 'package:donziker/theme/app_theme.dart';
import 'package:donziker/widgets/app_lifecycle_handler.dart';
import 'package:flutter/material.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'package:provider/provider.dart';
Future<void> main() async {
  try {
    WidgetsFlutterBinding.ensureInitialized();
    
    // Initialisation séquentielle pour éviter les conflits SQLite au démarrage
    await JustAudioBackground.init(
      androidNotificationChannelId: 'com.donchaminade.donziker.channel.audio',
      androidNotificationChannelName: 'DonZiker Playback',
      androidNotificationOngoing: true,
      androidNotificationIcon: 'mipmap/ic_launcher',
    );
    
    // Pause pour laisser les services se stabiliser
    await Future.delayed(const Duration(milliseconds: 300));

    final musicProvider = MusicProvider();
    final themeProvider = ThemeProvider();

    // Init provider et attendre un peu
    await musicProvider.init();
    await musicProvider.refreshPermissionStatus();

    runApp(
      MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: musicProvider),
          ChangeNotifierProvider.value(value: themeProvider),
        ],
        child: AppLifecycleHandler(
          child: MyApp(skipPermissionSplash: musicProvider.permissionGranted),
        ),
      ),
    );
  } catch (e, stack) {
    debugPrint("Critical startup error: $e\n$stack");
    runApp(MaterialApp(home: Scaffold(body: Center(child: Text("Erreur au démarrage: $e")))));
  }
}

class MyApp extends StatelessWidget {
  final bool skipPermissionSplash;

  const MyApp({super.key, this.skipPermissionSplash = false});

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
          home: skipPermissionSplash
              ? const HomeScreen()
              : const SplashPermissionScreen(),
        );
      },
    );
  }
}