import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Verrou CPU partiel. `wakelock_plus` ne pose que FLAG_KEEP_SCREEN_ON
/// sur la fenêtre : il ne tient pas le processeur écran éteint.
class PlaybackWakeLock {
  static const _channel = MethodChannel('com.example.donziker/media');

  static Future<void> acquire() async {
    if (kIsWeb || !Platform.isAndroid) return;
    try {
      await _channel.invokeMethod<void>('acquirePlaybackWakeLock');
    } catch (e) {
      debugPrint('WakeLock acquire: $e');
    }
  }

  static Future<void> release() async {
    if (kIsWeb || !Platform.isAndroid) return;
    try {
      await _channel.invokeMethod<void>('releasePlaybackWakeLock');
    } catch (e) {
      debugPrint('WakeLock release: $e');
    }
  }
}
