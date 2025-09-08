import 'package:flutter/material.dart';

class AppTheme {
  static ThemeData darkTheme() {
    return ThemeData.dark().copyWith(
      scaffoldBackgroundColor: Colors.black,
      colorScheme: ColorScheme.fromSeed(
        seedColor: Colors.deepPurple,
        brightness: Brightness.dark,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        titleTextStyle: TextStyle(
          color: Colors.white,
          fontSize: 24,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
