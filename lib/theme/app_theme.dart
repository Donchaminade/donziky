import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  static ThemeData lightTheme(Color accentColor) {
    final base = ThemeData(useMaterial3: true, brightness: Brightness.light);
    return base.copyWith(
      colorScheme: ColorScheme.fromSeed(seedColor: accentColor, brightness: Brightness.light),
      textTheme: GoogleFonts.interTextTheme(base.textTheme),
    );
  }

  static ThemeData darkTheme(Color accentColor) {
    final base = ThemeData(useMaterial3: true, brightness: Brightness.dark);
    return base.copyWith(
      colorScheme: ColorScheme.fromSeed(seedColor: accentColor, brightness: Brightness.dark),
      scaffoldBackgroundColor: Colors.black,
      textTheme: GoogleFonts.interTextTheme(base.textTheme),
      appBarTheme: const AppBarTheme(backgroundColor: Colors.transparent, elevation: 0),
    );
  }
}
