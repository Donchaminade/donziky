import 'package:donziker/providers/music_provider.dart';
import 'package:donziker/services/battery_prompt.dart';
import 'package:donziker/services/playback_continuity.dart';
import 'package:donziker/services/playback_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('la répétition enchaîne, la fin de file sans répétition s\'arrête', () {
    expect(
      PlaybackContinuity.nextIndex(current: 0, length: 3, repeat: RepeatMode.none),
      1,
    );
    expect(
      PlaybackContinuity.nextIndex(current: 2, length: 3, repeat: RepeatMode.none),
      isNull,
    );
    expect(
      PlaybackContinuity.nextIndex(current: 2, length: 3, repeat: RepeatMode.all),
      0,
    );
    expect(
      PlaybackContinuity.nextIndex(current: 1, length: 3, repeat: RepeatMode.one),
      1,
    );
    expect(
      PlaybackContinuity.nextIndex(current: 0, length: 0, repeat: RepeatMode.all),
      isNull,
    );
  });

  test('un appel met en pause puis reprend, un focus inconnu non', () {
    expect(PlaybackContinuity.pauseForInterruption(AudioInterruptKind.pause), isTrue);
    expect(PlaybackContinuity.pauseForInterruption(AudioInterruptKind.unknown), isFalse);
    expect(PlaybackContinuity.pauseForInterruption(AudioInterruptKind.duck), isFalse);
    expect(
      PlaybackContinuity.resumeAfterInterruption(
        kind: AudioInterruptKind.pause,
        userWantsPlayback: true,
        pausedForCall: true,
      ),
      isTrue,
    );
    expect(
      PlaybackContinuity.resumeAfterInterruption(
        kind: AudioInterruptKind.pause,
        userWantsPlayback: false,
        pausedForCall: true,
      ),
      isFalse,
    );
    expect(
      PlaybackContinuity.resumeAfterInterruption(
        kind: AudioInterruptKind.unknown,
        userWantsPlayback: true,
        pausedForCall: true,
      ),
      isFalse,
    );
    expect(
      PlaybackContinuity.keepEngineRunning(userWantsPlayback: true, phoneCallActive: false),
      isTrue,
    );
    expect(
      PlaybackContinuity.keepEngineRunning(userWantsPlayback: true, phoneCallActive: true),
      isFalse,
    );
    expect(
      PlaybackContinuity.keepEngineRunning(userWantsPlayback: false, phoneCallActive: false),
      isFalse,
    );
  });

  test('une pause externe efface l\'intention, un appel non', () {
    expect(
      PlaybackContinuity.externalPauseClearsIntent(
        syncingPlayback: false,
        enginePlaying: false,
        phoneCallActive: false,
        userWantsPlayback: true,
      ),
      isTrue,
    );
    expect(
      PlaybackContinuity.externalPauseClearsIntent(
        syncingPlayback: true,
        enginePlaying: false,
        phoneCallActive: false,
        userWantsPlayback: true,
      ),
      isFalse,
    );
    expect(
      PlaybackContinuity.externalPauseClearsIntent(
        syncingPlayback: false,
        enginePlaying: false,
        phoneCallActive: true,
        userWantsPlayback: true,
      ),
      isFalse,
    );
    expect(
      PlaybackContinuity.externalPauseClearsIntent(
        syncingPlayback: false,
        enginePlaying: true,
        phoneCallActive: false,
        userWantsPlayback: true,
      ),
      isFalse,
    );
  });

  test('aucun cycle de vie ne coupe la lecture', () {
    for (final state in ['inactive', 'paused', 'hidden', 'detached', 'resumed']) {
      expect(PlaybackContinuity.lifecycleStopsPlayback(state), isFalse, reason: state);
    }
  });

  test('la minuterie de veille est inactive par défaut', () {
    final playback = PlaybackService();
    expect(playback.sleepTimerRemaining, isNull);
    expect(playback.userWantsPlayback, isFalse);
    expect(playback.uiPlaying, isFalse);
    expect(playback.repeatMode, RepeatMode.all);
  });

  test('quitter l\'écran ne lance pas la minuterie et ne démarre pas la lecture', () async {
    SharedPreferences.setMockInitialValues({});
    final music = MusicProvider();
    await music.onAppPaused();
    expect(music.isPlaying, isFalse);
    expect(music.sleepTimerRemaining, isNull);
    music.dispose();
  });

  test('la demande batterie ne s\'affiche qu\'une fois sur Android', () {
    expect(BatteryPrompt.shouldAutoPrompt(alreadyPrompted: false, android: true), isTrue);
    expect(BatteryPrompt.shouldAutoPrompt(alreadyPrompted: true, android: true), isFalse);
    expect(BatteryPrompt.shouldAutoPrompt(alreadyPrompted: false, android: false), isFalse);
  });
}
