import 'package:flutter/material.dart';

/// Couleurs dérivées du [ThemeData] actif — suit l'accent choisi dans Paramètres.
class DzColors {
  final ColorScheme scheme;
  final Color accent;

  const DzColors({required this.scheme, required this.accent});

  Color get surface => scheme.surface;
  Color get card => scheme.surfaceContainerHighest;
  Color get primaryText => scheme.onSurface;
  Color get secondaryText => scheme.onSurface.withValues(alpha: 0.55);
  Color get tertiaryText => scheme.onSurface.withValues(alpha: 0.38);
  Color get glass => scheme.surface.withValues(alpha: 0.72);
  Color get glassBorder => scheme.onSurface.withValues(alpha: 0.1);
  Color get highlight => accent.withValues(alpha: 0.18);
  bool get isDark => scheme.brightness == Brightness.dark;

  LinearGradient get heroGradient => LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          accent.withValues(alpha: isDark ? 0.55 : 0.35),
          scheme.surface,
        ],
      );
}

extension DzThemeContext on BuildContext {
  ThemeData get dzTheme => Theme.of(this);
  ColorScheme get dzScheme => dzTheme.colorScheme;

  /// Accent global = [ColorScheme.primary], mis à jour quand tu changes le thème.
  Color get dzAccent => dzScheme.primary;

  DzColors get dz => DzColors(scheme: dzScheme, accent: dzAccent);
}
