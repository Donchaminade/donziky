import 'package:donziker/providers/music_provider.dart';
import 'package:donziker/services/permission_service.dart';
import 'package:donziker/providers/theme_provider.dart';
import 'package:donziker/screens/wow_splash_screen.dart';
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
      androidNotificationChannelName: 'DonZiker',
      androidNotificationChannelDescription: 'Contrôles de lecture musique',
      androidNotificationOngoing: true,
      androidNotificationIcon: 'drawable/ic_stat_donziker',
      androidShowNotificationBadge: true,
      preloadArtwork: true,
    );
    
    // Pause pour laisser les services se stabiliser
    await Future.delayed(const Duration(milliseconds: 300));

    final musicProvider = MusicProvider();
    final themeProvider = ThemeProvider();

    // Init provider et attendre un peu
    await musicProvider.init();
    await musicProvider.refreshPermissionStatus();
    if (musicProvider.permissionGranted) {
      await PermissionService().ensureNotificationPermission();
    }

    runApp(
      MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: musicProvider),
          ChangeNotifierProvider.value(value: themeProvider),
        ],
        child: const AppLifecycleHandler(
          child: MyApp(),
        ),
      ),
    );
  } catch (e, stack) {
    debugPrint("Critical startup error: $e\n$stack");
    runApp(MaterialApp(home: Scaffold(body: Center(child: Text("Erreur au démarrage: $e")))));
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

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
          home: const WowSplashScreen(),
        );
      },
    );
  }
}