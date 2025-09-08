import 'package:donziker/providers/music_provider.dart';
import 'package:donziker/screens/home_screen.dart';
import 'package:donziker/screens/onboarding_screen.dart';
import 'package:donziker/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  final bool onboardingCompleted = prefs.getBool('onboarding_completed') ?? false;

  runApp(
    ChangeNotifierProvider(
      create: (context) => MusicProvider(),
      child: MyApp(onboardingCompleted: onboardingCompleted),
    ),
  );
}

class MyApp extends StatelessWidget {
  final bool onboardingCompleted;

  const MyApp({super.key, required this.onboardingCompleted});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'DonZiker',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme(),
      home: HomeScreen(),
      // home: onboardingCompleted ? const HomeScreen() : const OnboardingScreen(),
    );
  }
}