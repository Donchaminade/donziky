import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Propose une fois de sortir DonZiker de l'optimisation batterie.
/// Les ROM Tecno, Infinix et Xiaomi tuent sinon le lecteur écran éteint.
class BatteryPrompt {
  static const prefKey = 'battery_opt_prompted';

  static bool shouldAutoPrompt({required bool alreadyPrompted, required bool android}) =>
      android && !alreadyPrompted;

  static Future<void> offerOnce(BuildContext context) async {
    if (kIsWeb || !Platform.isAndroid) return;
    final prefs = await SharedPreferences.getInstance();
    if (!shouldAutoPrompt(alreadyPrompted: prefs.getBool(prefKey) ?? false, android: true)) {
      return;
    }
    await prefs.setBool(prefKey, true);
    if (!context.mounted) return;
    final accept = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Laisser la musique continuer'),
        content: const Text(
          'Sur Tecno, Infinix et Xiaomi, l\'optimisation batterie coupe DonZiker '
          'quand l\'écran s\'éteint. Autorise l\'exception pour que la lecture '
          'ne s\'arrête que si tu mets pause.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Plus tard')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Autoriser')),
        ],
      ),
    );
    if (accept == true) await requestExemption();
  }

  static Future<void> requestExemption() async {
    if (kIsWeb || !Platform.isAndroid) return;
    try {
      await Permission.ignoreBatteryOptimizations.request();
    } catch (e) {
      debugPrint('optimisation batterie: $e');
    }
  }
}
