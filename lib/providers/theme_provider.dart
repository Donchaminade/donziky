import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeProvider extends ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.dark;
  Color _accentColor = Colors.redAccent;

  ThemeMode get themeMode => _themeMode;
  Color get accentColor => _accentColor;

  ThemeProvider() {
    _loadSettings();
  }

  void _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final isDark = prefs.getBool('is_dark') ?? true;
    _themeMode = isDark ? ThemeMode.dark : ThemeMode.light;
    final accentValue = prefs.getInt('accent_color');
    if (accentValue != null) {
      _accentColor = Color(accentValue);
    }
    notifyListeners();
  }

  void toggleTheme(bool isDark) async {
    _themeMode = isDark ? ThemeMode.dark : ThemeMode.light;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('is_dark', isDark);
    notifyListeners();
  }

  void updateAccentColor(Color color) async {
    _accentColor = color;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('accent_color', color.value);
    notifyListeners();
  }
}
