import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum AppVisualStyle { tega, classic }

class ThemeProvider extends ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.light;
  Color _accentColor = const Color(0xFFFF375F);
  AppVisualStyle _visualStyle = AppVisualStyle.tega;
  bool _disableAnimations = false;
  bool _circularPlayer = true;
  String _displayName = 'Tega';

  late final Future<void> ready;

  ThemeMode get themeMode => _themeMode;
  Color get accentColor => _accentColor;
  AppVisualStyle get visualStyle => _visualStyle;
  bool get disableAnimations => _disableAnimations;
  bool get circularPlayer => _circularPlayer;
  String get displayName => _displayName.trim().isEmpty ? 'Tega' : _displayName.trim();
  bool get isTega => _visualStyle == AppVisualStyle.tega;

  ThemeProvider() {
    ready = _loadSettings();
  }

  Future<void> _loadSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final isDark = prefs.getBool('is_dark') ?? false;
      _themeMode = isDark ? ThemeMode.dark : ThemeMode.light;
      final accentValue = prefs.getInt('accent_color');
      if (accentValue != null) {
        _accentColor = Color(accentValue);
      }
      final style = prefs.getString('visual_style');
      _visualStyle = style == 'classic' ? AppVisualStyle.classic : AppVisualStyle.tega;
      _disableAnimations = prefs.getBool('disable_animations') ?? false;
      _circularPlayer = prefs.getBool('circular_player') ?? true;
      final name = prefs.getString('display_name');
      if (name != null && name.trim().isNotEmpty) {
        _displayName = name.trim();
      }
      notifyListeners();
    } catch (e) {
      debugPrint('ThemeProvider load: $e');
    }
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
    await prefs.setInt('accent_color', color.toARGB32());
    notifyListeners();
  }

  Future<void> setVisualStyle(AppVisualStyle style) async {
    _visualStyle = style;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('visual_style', style == AppVisualStyle.classic ? 'classic' : 'tega');
    notifyListeners();
  }

  Future<void> setCircularPlayer(bool value) async {
    _circularPlayer = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('circular_player', value);
    notifyListeners();
  }

  Future<void> selectTega({required bool dark}) async {
    _visualStyle = AppVisualStyle.tega;
    _themeMode = dark ? ThemeMode.dark : ThemeMode.light;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('visual_style', 'tega');
    await prefs.setBool('is_dark', dark);
    notifyListeners();
  }

  Future<void> selectClassicAccent(Color color) async {
    _visualStyle = AppVisualStyle.classic;
    _accentColor = color;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('visual_style', 'classic');
    await prefs.setInt('accent_color', color.toARGB32());
    notifyListeners();
  }

  Future<void> setDisableAnimations(bool value) async {
    _disableAnimations = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('disable_animations', value);
    notifyListeners();
  }

  Future<void> setDisplayName(String name) async {
    _displayName = name.trim().isEmpty ? 'Tega' : name.trim();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('display_name', _displayName);
    notifyListeners();
  }

  Color effectiveAccent(Color dynamicColor, {bool useDynamic = false}) {
    return useDynamic ? dynamicColor : _accentColor;
  }
}
