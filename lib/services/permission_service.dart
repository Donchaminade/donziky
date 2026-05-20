import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:on_audio_query/on_audio_query.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:photo_manager/photo_manager.dart';

/// Gestion des permissions médias — audio obligatoire, vidéos/photos optionnels.
class PermissionService {
  final OnAudioQuery _audioQuery = OnAudioQuery();

  Future<bool> hasAudioAccess() async {
    if (await _audioQuery.permissionsStatus()) return true;
    return _permissionHandlerAudioGranted();
  }

  Future<bool> requestAudioAccess() async {
    if (await _audioQuery.permissionsStatus()) return true;

    await _audioQuery.permissionsRequest();
    if (await _audioQuery.permissionsStatus()) return true;

    if (Platform.isAndroid) {
      final sdk = (await DeviceInfoPlugin().androidInfo).version.sdkInt;
      if (sdk >= 33) {
        final audio = await Permission.audio.request();
        if (audio.isGranted) return true;
        final storage = await Permission.storage.request();
        return storage.isGranted;
      }
      final storage = await Permission.storage.request();
      return storage.isGranted;
    }
    if (Platform.isIOS) {
      return (await Permission.mediaLibrary.request()).isGranted;
    }
    return (await Permission.storage.request()).isGranted;
  }

  Future<bool> _permissionHandlerAudioGranted() async {
    if (Platform.isAndroid) {
      final sdk = (await DeviceInfoPlugin().androidInfo).version.sdkInt;
      if (sdk >= 33) {
        return await Permission.audio.isGranted;
      }
      return await Permission.storage.isGranted;
    }
    if (Platform.isIOS) {
      return await Permission.mediaLibrary.isGranted;
    }
    return await Permission.storage.isGranted;
  }

  /// Optionnel — pour l'onglet vidéos uniquement.
  Future<bool> requestVideoGalleryAccess() async {
    try {
      final state = await PhotoManager.requestPermissionExtend();
      return state.isAuth;
    } catch (_) {
      return false;
    }
  }

  Future<bool> hasVideoGalleryAccess() async {
    try {
      final state = await PhotoManager.getPermissionState(
        requestOption: const PermissionRequestOption(),
      );
      return state.isAuth;
    } catch (_) {
      return false;
    }
  }

  Future<void> openSystemSettings() async {
    await openAppSettings();
  }

  /// Android 13+ : requis pour afficher la notification de lecture (écran d'accueil / pop-up).
  Future<void> ensureNotificationPermission() async {
    if (!Platform.isAndroid) return;
    final sdk = (await DeviceInfoPlugin().androidInfo).version.sdkInt;
    if (sdk >= 33) {
      await Permission.notification.request();
    }
  }
}
