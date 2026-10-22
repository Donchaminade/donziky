import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

/// Palette « Tega » (accueil musique) et thème classique (graine + Jakarta).
class AppTheme {
  static const double radiusSm = 10;
  static const double radiusMd = 16;
  static const double radiusLg = 20;
  static const double radiusXl = 28;

  static const Color lime = Color(0xFFD4F26A);
  static const Color ink = Color(0xFF141414);
  static const Color text = Color(0xFF111111);
  static const Color muted = Color(0xFF6B6B6B);
  static const Color canvas = Color(0xFFF4F4F2);
  static const Color darkBg = Color(0xFF0E0E0E);
  static const Color darkCard = Color(0xFF1A1A1A);

  static ThemeData tegaLight() => _tega(Brightness.light);
  static ThemeData tegaDark() => _tega(Brightness.dark);

  static ThemeData classicLight(Color accent) => _classic(accent, Brightness.light);
  static ThemeData classicDark(Color accent) => _classic(accent, Brightness.dark);

  static ThemeData lightTheme(Color accent) => classicLight(accent);
  static ThemeData darkTheme(Color accent) => classicDark(accent);

  static TextTheme _inter(Brightness brightness) {
    final base = ThemeData(brightness: brightness).textTheme;
    try {
      return GoogleFonts.interTextTheme(base).apply(fontFamily: 'Inter');
    } catch (_) {
      return base.apply(fontFamily: 'Inter');
    }
  }

  static ThemeData _tega(Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    final scheme = ColorScheme.fromSeed(
      seedColor: lime,
      brightness: brightness,
      primary: lime,
      onPrimary: ink,
      surface: isDark ? darkBg : canvas,
      onSurface: isDark ? const Color(0xFFF4F4F2) : text,
    ).copyWith(
      primary: lime,
      onPrimary: ink,
      secondary: isDark ? const Color(0xFFF4F4F2) : ink,
      onSecondary: isDark ? ink : Colors.white,
      surface: isDark ? darkBg : canvas,
      onSurface: isDark ? const Color(0xFFF4F4F2) : text,
      surfaceContainerHighest: isDark ? darkCard : Colors.white,
      surfaceContainer: isDark ? darkCard : Colors.white,
      surfaceContainerLow: isDark ? const Color(0xFF161616) : Colors.white,
      outline: isDark ? const Color(0xFF2C2C2C) : const Color(0xFFE4E4E0),
    );

    final textTheme = _inter(brightness);
    return _assemble(scheme, textTheme, lime, fontFamily: 'Inter');
  }

  static ThemeData _classic(Color accent, Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    final scheme = ColorScheme.fromSeed(
      seedColor: accent,
      brightness: brightness,
      surface: isDark ? const Color(0xFF0A0A0A) : const Color(0xFFF2F2F7),
      surfaceContainerHighest: isDark ? const Color(0xFF1C1C1E) : const Color(0xFFE5E5EA),
    );
    final textTheme = GoogleFonts.plusJakartaSansTextTheme(
      ThemeData(brightness: brightness).textTheme,
    );
    return _assemble(
      scheme,
      textTheme,
      accent,
      fontFamily: GoogleFonts.plusJakartaSans().fontFamily,
    );
  }

  static ThemeData _assemble(
    ColorScheme scheme,
    TextTheme text,
    Color accent, {
    required String? fontFamily,
  }) {
    final isDark = scheme.brightness == Brightness.dark;
    return ThemeData(
      useMaterial3: true,
      brightness: scheme.brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor: scheme.surface,
      fontFamily: fontFamily,
      textTheme: text.apply(
        bodyColor: scheme.onSurface,
        displayColor: scheme.onSurface,
      ),
      appBarTheme: AppBarTheme(
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: scheme.onSurface,
        systemOverlayStyle: isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
        titleTextStyle: text.titleLarge?.copyWith(
          fontWeight: FontWeight.w700,
          letterSpacing: -0.5,
          color: scheme.onSurface,
        ),
      ),
      cardTheme: CardThemeData(
        color: scheme.surfaceContainerHighest,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radiusLg)),
      ),
      navigationBarTheme: NavigationBarThemeData(
        height: 64,
        elevation: 0,
        backgroundColor: scheme.surface.withValues(alpha: 0.92),
        indicatorColor: accent.withValues(alpha: 0.35),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return text.labelSmall?.copyWith(
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
            color: selected ? scheme.onSurface : scheme.onSurface.withValues(alpha: 0.55),
          );
        }),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: scheme.surfaceContainerHighest,
        selectedColor: accent,
        labelStyle: text.labelLarge!.copyWith(fontWeight: FontWeight.w600, color: scheme.onSurface),
        secondaryLabelStyle: text.labelLarge!.copyWith(fontWeight: FontWeight.w700, color: ink),
        side: BorderSide.none,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 0),
      ),
      listTileTheme: ListTileThemeData(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radiusSm)),
      ),
      dividerTheme: DividerThemeData(
        color: scheme.onSurface.withValues(alpha: 0.08),
        thickness: 0.5,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: scheme.primary,
          foregroundColor: scheme.onPrimary,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radiusLg)),
          textStyle: text.labelLarge?.copyWith(fontWeight: FontWeight.w700),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: scheme.surfaceContainerHighest,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMd),
          borderSide: BorderSide.none,
        ),
        hintStyle: text.bodyMedium?.copyWith(
          color: scheme.onSurface.withValues(alpha: 0.45),
        ),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: scheme.surfaceContainerHighest,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(radiusXl)),
        ),
      ),
      sliderTheme: SliderThemeData(
        trackHeight: 8,
        activeTrackColor: accent,
        inactiveTrackColor: scheme.onSurface.withValues(alpha: 0.12),
        thumbColor: scheme.onSurface,
        overlayShape: SliderComponentShape.noOverlay,
        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 7),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(color: accent),
    );
  }
}
