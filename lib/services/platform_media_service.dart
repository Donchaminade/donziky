import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

class PlatformMediaService {
  static const _channel = MethodChannel('com.example.donziker/media');

  static Future<bool> setAsRingtone(String filePath) async {
    if (!Platform.isAndroid) {
      debugPrint('Sonnerie: Android uniquement');
      return false;
    }
    try {
      final result = await _channel.invokeMethod<bool>('setRingtone', {'path': filePath});
      return result ?? false;
    } catch (e) {
      debugPrint('setRingtone error: $e');
      return false;
    }
  }

  static Future<bool> enterPipMode() async {
    if (!Platform.isAndroid) return false;
    try {
      final result = await _channel.invokeMethod<bool>('enterPip');
      return result ?? false;
    } catch (e) {
      debugPrint('enterPip error: $e');
      return false;
    }
  }
}
