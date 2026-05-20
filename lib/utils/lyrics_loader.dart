import 'dart:io';

import 'package:flutter/foundation.dart';

class LyricsLoader {
  static Future<String?> loadFromPath(String audioPath) async {
    try {
      final base = audioPath.replaceAll(RegExp(r'\.[^.\\/]+$'), '');
      final candidates = [
        '$base.lrc',
        '$base.LRC',
        '$base.txt',
      ];
      for (final path in candidates) {
        final file = File(path);
        if (await file.exists()) {
          return await file.readAsString();
        }
      }
    } catch (e) {
      debugPrint('LyricsLoader error: $e');
    }
    return null;
  }
}
