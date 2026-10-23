import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

/// Charge les polices déclarées (Inter) via [FontLoader], comme le ferait
/// l'outil de captures. À appeler après l'initialisation du binding de test.
Future<void> loadAppFonts() async {
  TestWidgetsFlutterBinding.ensureInitialized();
  final manifest = await rootBundle.loadString('FontManifest.json');
  final families = json.decode(manifest) as List<dynamic>;
  for (final entry in families) {
    final family = (entry as Map<String, dynamic>)['family'] as String;
    final fonts = entry['fonts'] as List<dynamic>;
    final loader = FontLoader(family);
    for (final font in fonts) {
      final asset = (font as Map<String, dynamic>)['asset'] as String;
      loader.addFont(rootBundle.load(asset));
    }
    await loader.load();
  }
}
