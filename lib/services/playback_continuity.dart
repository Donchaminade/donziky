import 'package:donziker/models/repeat_mode.dart';

/// Décisions de lecture pures, testables sans moteur audio.
class PlaybackContinuity {
  /// Morceau à lancer quand l'actuel se termine ou ne se décode pas.
  /// `null` : la file est finie et la répétition est coupée.
  static int? nextIndex({
    required int current,
    required int length,
    required RepeatMode repeat,
  }) {
    if (length <= 0) return null;
    final index = current.clamp(0, length - 1);
    if (repeat == RepeatMode.one) return index;
    final next = index + 1;
    if (next < length) return next;
    if (repeat == RepeatMode.all) return 0;
    return null;
  }

  /// Un appel téléphonique met en pause. Un focus « inconnu »
  /// (verrouillage d'écran sur plusieurs constructeurs) ne doit pas couper.
  static bool pauseForInterruption(AudioInterruptKind kind) => kind == AudioInterruptKind.pause;

  /// Après un appel, on reprend seulement si l'utilisateur n'avait pas mis pause.
  static bool resumeAfterInterruption({
    required AudioInterruptKind kind,
    required bool userWantsPlayback,
    required bool pausedForCall,
  }) =>
      kind == AudioInterruptKind.pause && pausedForCall && userWantsPlayback;

  /// La lecture continue tant que l'utilisateur ne l'a pas arrêtée
  /// et qu'un appel n'est pas en cours.
  static bool keepEngineRunning({
    required bool userWantsPlayback,
    required bool phoneCallActive,
  }) =>
      userWantsPlayback && !phoneCallActive;

  /// Aucun état de cycle de vie ne coupe le son.
  static bool lifecycleStopsPlayback(String stateName) => false;

  /// Pause notification ou bouton média : l'intention utilisateur s'efface.
  /// Un appel en cours ou une synchro interne ne comptent pas.
  static bool externalPauseClearsIntent({
    required bool syncingPlayback,
    required bool enginePlaying,
    required bool phoneCallActive,
    required bool userWantsPlayback,
  }) =>
      !syncingPlayback && !enginePlaying && !phoneCallActive && userWantsPlayback;
}

enum AudioInterruptKind { duck, pause, unknown }
