// import 'package:donziker/providers/music_provider.dart';
// import 'package:donziker/screens/home_screen.dart';
// import 'package:flutter/material.dart';

// import 'package:photo_manager/photo_manager.dart';
// import 'package:provider/provider.dart';
// import 'package:shared_preferences/shared_preferences.dart';

// class OnboardingScreen extends StatelessWidget {
//   const OnboardingScreen({super.key});

//   Future<void> _completeOnboarding(BuildContext context) async {
//     final prefs = await SharedPreferences.getInstance();
//     await prefs.setBool('onboarding_completed', true);
//     Navigator.of(context).pushReplacement(
//       MaterialPageRoute(builder: (_) => const HomeScreen()),
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Consumer<MusicProvider>(
//       builder: (context, musicProvider, child) {
//         if (musicProvider.permissionState.isAuth) {
//           // Use a post-frame callback to avoid calling setState during a build.
//           WidgetsBinding.instance.addPostFrameCallback((_) {
//             _completeOnboarding(context);
//           });
//         }

//         return Scaffold(
//           backgroundColor: const Color(0xFF121212),
//           body: Center(
//             child: Padding(
//               padding: const EdgeInsets.all(24.0),
//               child: Column(
//                 mainAxisAlignment: MainAxisAlignment.center,
//                 children: <Widget>[
//                   Image.asset('assets/images/don.png', height: 120),
//                   const SizedBox(height: 48),
//                   const Text(
//                     'Welcome to Donziker',
//                     style: TextStyle(
//                       fontSize: 28,
//                       fontWeight: FontWeight.bold,
//                       color: Colors.white,
//                     ),
//                     textAlign: TextAlign.center,
//                   ),
//                   const SizedBox(height: 24),
//                   const Text(
//                     'To find and play music and videos from your device, we need access to your storage.',
//                     style: TextStyle(
//                       fontSize: 16,
//                       color: Colors.white70,
//                     ),
//                     textAlign: TextAlign.center,
//                   ),
//                   const SizedBox(height: 48),
//                   ElevatedButton(
//                     style: ElevatedButton.styleFrom(
//                       backgroundColor: Colors.deepPurple,
//                       padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
//                       textStyle: const TextStyle(fontSize: 18),
//                     ),
//                     onPressed: () => musicProvider.checkAndRequestPermissions(),
//                     child: const Text('Grant Permissions'),
//                   ),
//                 ],
//               ),
//             ),
//           ),
//         );
//       },
//     );
//   }
// }