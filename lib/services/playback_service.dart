import 'dart:async';
import 'dart:io';

import 'package:audio_session/audio_session.dart';
import 'package:donziker/models/repeat_mode.dart';
import 'package:donziker/services/playback_continuity.dart';
import 'package:donziker/services/playback_wake_lock.dart';
import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';
import 'package:on_audio_query/on_audio_query.dart';

/// Lecture : transport, vitesse, répétition, minuterie, boucle A-B, karaoké.
///
/// Le lecteur plateforme n'est créé qu'au premier accès, pour que les tests
/// qui ne lancent pas de son n'ouvrent pas de canal natif.
class PlaybackService {
  AudioPlayer? _player;
  AudioPlayer get player {
    if (_player == null) {
      // Les interruptions « inconnues » (verrouillage Tecno/Xiaomi) sont gérées ici.
      // just_audio les traite comme une pause sans reprise.
      _player = AudioPlayer(handleInterruptions: false);
      unawaited(_configurePlayer(_player!));
    }
    return _player!;
  }
  bool get isPlayerOpen => _player != null;

  /// Volonté de l'utilisateur. Le moteur peut se taire (appel) sans l'effacer.
  bool userWantsPlayback = false;
  bool uiPlaying = false;
  bool syncingPlayback = false;
  double speed = 1.0;
  bool isShuffle = false;
  RepeatMode repeatMode = RepeatMode.all;
  bool gaplessEnabled = true;

  Timer? sleepTimer;
  StreamSubscription<ProcessingState>? endOfTrackSub;
  Duration? sleepTimerRemaining;
  DateTime? sleepTimerEndsAt;
  bool sleepEndOfTrack = false;

  Duration? pointA;
  Duration? pointB;
  bool isABLoopActive = false;
  int abLoopCount = 0;
  int abLoopMax = 0;

  bool karaokeMode = false;
  int karaokeLeadSeconds = 8;
  int? karaokeSkippedForIndex;

  Future<void> Function()? onPaused;
  VoidCallback? onChanged;

  Timer? _playbackSyncTimer;
  Timer? _resumeTimer;
  StreamSubscription<PlayerState>? _playerStateSub;
  StreamSubscription<PlaybackEvent>? _playbackEventSub;
  StreamSubscription<ProcessingState>? _processingSub;
  StreamSubscription<Duration>? _positionSub;
  StreamSubscription<int?>? _indexSub;
  StreamSubscription<AudioInterruptionEvent>? _interruptionSub;
  StreamSubscription<void>? _noisySub;
  bool _sessionConfigured = false;
  bool _phoneCallActive = false;
  int _failedSkips = 0;
  DateTime _lastContinue = DateTime.fromMillisecondsSinceEpoch(0);
  int? _lastContinueIndex;

  int Function() _queueLength = () => 0;
  int Function() _indexOf = () => 0;

  Duration lastSavedPosition = Duration.zero;

  Future<void> prepareTransport() => _configurePlayer(player);

  Future<void> _configurePlayer(AudioPlayer opened) async {
    try {
      await opened.setSpeed(speed);
      await opened.setLoopMode(_loopFor(repeatMode));
      await opened.setShuffleModeEnabled(isShuffle);
    } catch (e) {
      debugPrint('player setup: $e');
    }
    if (kIsWeb || !Platform.isAndroid) return;
    try {
      final session = await AudioSession.instance;
      if (!_sessionConfigured) {
        await session.configure(const AudioSessionConfiguration.music());
        _sessionConfigured = true;
        await _interruptionSub?.cancel();
        await _noisySub?.cancel();
        _interruptionSub = session.interruptionEventStream.listen(_onInterruption, onError: _logStream);
        _noisySub = session.becomingNoisyEventStream.listen((_) {
          // Casque débranché : on coupe pour ne pas basculer sur le haut-parleur.
          unawaited(pause(() {}));
        }, onError: _logStream);
      }
      await opened.setAndroidAudioAttributes(
        const AndroidAudioAttributes(
          contentType: AndroidAudioContentType.music,
          usage: AndroidAudioUsage.media,
        ),
      );
    } catch (e) {
      debugPrint('audio session: $e');
    }
  }

  void _onInterruption(AudioInterruptionEvent event) {
    final kind = switch (event.type) {
      AudioInterruptionType.duck => AudioInterruptKind.duck,
      AudioInterruptionType.pause => AudioInterruptKind.pause,
      AudioInterruptionType.unknown => AudioInterruptKind.unknown,
    };
    if (event.begin) {
      if (!PlaybackContinuity.pauseForInterruption(kind)) return;
      _phoneCallActive = userWantsPlayback;
      unawaited(_enginePause());
      return;
    }
    final resume = PlaybackContinuity.resumeAfterInterruption(
      kind: kind,
      userWantsPlayback: userWantsPlayback,
      pausedForCall: _phoneCallActive,
    );
    _phoneCallActive = false;
    if (resume) _scheduleResume();
  }

  LoopMode _loopFor(RepeatMode mode) {
    switch (mode) {
      case RepeatMode.one:
        return LoopMode.one;
      case RepeatMode.all:
        return LoopMode.all;
      case RepeatMode.none:
        return LoopMode.off;
    }
  }

  void bind({
    required VoidCallback notify,
    required void Function() playNext,
    required Future<void> Function() pause,
    required SongModel? Function() currentSong,
    required int Function() currentIndex,
    required int Function() queueLength,
    required SongModel? Function(int index) songAt,
    required Future<void> Function(int index, SongModel song) onIndexChanged,
    required void Function(Duration position) onPosition,
  }) {
    _queueLength = queueLength;
    _indexOf = currentIndex;
    _playerStateSub?.cancel();
    _playbackEventSub?.cancel();
    _processingSub?.cancel();
    _positionSub?.cancel();
    _indexSub?.cancel();

    _playerStateSub = player.playerStateStream.listen((state) {
      if (state.playing) _failedSkips = 0;
      if (!PlaybackContinuity.externalPauseClearsIntent(
        syncingPlayback: syncingPlayback,
        enginePlaying: state.playing,
        phoneCallActive: _phoneCallActive,
        userWantsPlayback: userWantsPlayback,
      )) {
        return;
      }
      // just_audio ne passe `playing` à faux que sur pause() ou stop()
      // (notification, bouton casque). Un décrochage natif laisse le drapeau
      // à vrai : le verrou CPU et le service de premier plan le couvrent.
      userWantsPlayback = false;
      uiPlaying = false;
      _resumeTimer?.cancel();
      unawaited(_updateWakelock(false));
      onChanged?.call();
    }, onError: _logStream);

    _playbackEventSub = player.playbackEventStream.listen((_) {}, onError: (Object e, StackTrace st) {
      debugPrint('playback error: $e\n$st');
      unawaited(_continueQueue(failed: true));
    });

    _processingSub = player.processingStateStream.listen((state) async {
      if (state != ProcessingState.completed) return;
      if (sleepEndOfTrack) {
        await pause();
        cancelSleepTimer(notify);
        return;
      }
      await _continueQueue(failed: false);
    }, onError: _logStream);

    _positionSub = player.positionStream.listen((position) {
      if (isABLoopActive && pointA != null && pointB != null && position >= pointB!) {
        if (abLoopMax > 0) {
          abLoopCount++;
          if (abLoopCount >= abLoopMax) {
            clearABLoop();
            pause();
            notify();
            return;
          }
        }
        player.seek(pointA!);
      }
      _tickSleep(notify);
      onPosition(position);
      _tickKaraoke(position, currentSong, playNext, notify);
    }, onError: _logStream);

    _indexSub = player.currentIndexStream.listen((index) async {
      if (index != null && index != currentIndex() && index < queueLength()) {
        final song = songAt(index);
        if (song == null) return;
        karaokeSkippedForIndex = null;
        await onIndexChanged(index, song);
      }
    }, onError: _logStream);
  }

  void _logStream(Object error, StackTrace stack) {
    debugPrint('playback stream: $error\n$stack');
  }

  void _scheduleResume() {
    if (!PlaybackContinuity.keepEngineRunning(
      userWantsPlayback: userWantsPlayback,
      phoneCallActive: _phoneCallActive,
    )) {
      return;
    }
    _resumeTimer?.cancel();
    _resumeTimer = Timer(const Duration(milliseconds: 350), () async {
      if (!PlaybackContinuity.keepEngineRunning(
        userWantsPlayback: userWantsPlayback,
        phoneCallActive: _phoneCallActive,
      )) {
        return;
      }
      if (!isPlayerOpen || player.playing) return;
      try {
        await player.play();
      } catch (e, st) {
        debugPrint('reprise: $e\n$st');
        await _continueQueue(failed: true);
      }
    });
  }

  Future<void> _enginePause() async {
    if (!isPlayerOpen) return;
    syncingPlayback = true;
    try {
      await player.pause();
    } catch (e) {
      debugPrint('pause moteur: $e');
    } finally {
      syncingPlayback = false;
    }
  }

  Future<void> _continueQueue({required bool failed}) async {
    if (failed) {
      _failedSkips++;
      if (_failedSkips > _queueLength().clamp(1, 10000)) {
        userWantsPlayback = false;
        uiPlaying = false;
        await _updateWakelock(false);
        onChanged?.call();
        return;
      }
    } else {
      _failedSkips = 0;
    }
    final length = _queueLength();
    final current = isPlayerOpen ? (player.currentIndex ?? _indexOf()) : _indexOf();
    var next = PlaybackContinuity.nextIndex(current: current, length: length, repeat: repeatMode);
    final spinning = next != null &&
        next == _lastContinueIndex &&
        DateTime.now().difference(_lastContinue) < const Duration(milliseconds: 800);
    if (spinning) {
      next = PlaybackContinuity.nextIndex(current: next, length: length, repeat: RepeatMode.all);
      if (next == _lastContinueIndex) next = null;
    }
    _lastContinue = DateTime.now();
    _lastContinueIndex = next;
    if (next == null || !userWantsPlayback) {
      if (!userWantsPlayback || next == null) {
        userWantsPlayback = false;
        uiPlaying = false;
        await _updateWakelock(false);
        onChanged?.call();
      }
      return;
    }
    try {
      await player.seek(Duration.zero, index: next);
      if (userWantsPlayback) await player.play();
    } catch (e, st) {
      debugPrint('morceau suivant: $e\n$st');
    }
  }

  void _tickSleep(VoidCallback notify) {
    if (sleepTimerEndsAt == null) return;
    final left = sleepTimerEndsAt!.difference(DateTime.now());
    if (left.isNegative) {
      sleepTimerRemaining = null;
      sleepTimerEndsAt = null;
    } else {
      sleepTimerRemaining = left;
    }
    notify();
  }

  void _tickKaraoke(
    Duration position,
    SongModel? Function() currentSong,
    void Function() playNext,
    VoidCallback notify,
  ) {
    if (!karaokeMode || !uiPlaying || currentSong() == null) return;
    final dur = player.duration;
    if (dur == null || dur.inMilliseconds < 3000) return;
    final remaining = dur - position;
    if (remaining > Duration(seconds: karaokeLeadSeconds)) return;
    if (remaining < const Duration(milliseconds: 300)) return;
    if (karaokeSkippedForIndex == player.currentIndex) return;
    karaokeSkippedForIndex = player.currentIndex;
    playNext();
    notify();
  }

  void toggleKaraoke(VoidCallback notify) {
    karaokeMode = !karaokeMode;
    karaokeSkippedForIndex = null;
    notify();
  }

  void setKaraokeLead(int seconds, VoidCallback notify) {
    karaokeLeadSeconds = seconds.clamp(3, 30);
    notify();
  }

  void setSpeed(double value) {
    speed = value;
    if (isPlayerOpen) player.setSpeed(value);
  }

  void setPitch(double pitch) {
    try {
      player.setSpeed(speed * pitch.clamp(0.5, 2.0));
    } catch (_) {}
  }

  void toggleShuffle(VoidCallback notify) {
    isShuffle = !isShuffle;
    player.setShuffleModeEnabled(isShuffle);
    if (isShuffle) player.shuffle();
    notify();
  }

  void cycleRepeat(VoidCallback notify) {
    switch (repeatMode) {
      case RepeatMode.none:
        repeatMode = RepeatMode.one;
        player.setLoopMode(LoopMode.one);
        break;
      case RepeatMode.one:
        repeatMode = RepeatMode.all;
        player.setLoopMode(LoopMode.all);
        break;
      case RepeatMode.all:
        repeatMode = RepeatMode.none;
        player.setLoopMode(LoopMode.off);
        break;
    }
    notify();
  }

  void forceRepeatOne(VoidCallback notify) {
    repeatMode = RepeatMode.one;
    player.setLoopMode(LoopMode.one);
    notify();
  }

  void togglePlayPause(VoidCallback notify) {
    uiPlaying = !uiPlaying;
    userWantsPlayback = uiPlaying;
    _phoneCallActive = false;
    notify();
    _playbackSyncTimer?.cancel();
    _playbackSyncTimer = Timer(const Duration(milliseconds: 50), () {
      applyUiState();
    });
  }

  Future<void> play(VoidCallback notify) async {
    if (uiPlaying && userWantsPlayback) return;
    uiPlaying = true;
    userWantsPlayback = true;
    _phoneCallActive = false;
    notify();
    await applyUiState();
  }

  Future<void> pause(VoidCallback notify) async {
    if (!uiPlaying && !userWantsPlayback) return;
    uiPlaying = false;
    userWantsPlayback = false;
    _phoneCallActive = false;
    _resumeTimer?.cancel();
    notify();
    await applyUiState();
  }

  Future<void> applyUiState() async {
    final shouldPlay = uiPlaying;
    syncingPlayback = true;
    try {
      if (shouldPlay) {
        await _updateWakelock(true);
        await player.play();
      } else {
        await player.pause();
      }
    } catch (e) {
      debugPrint('playback sync: $e');
      if (isPlayerOpen) {
        uiPlaying = player.playing;
      }
      onChanged?.call();
    } finally {
      syncingPlayback = false;
      await _updateWakelock(uiPlaying);
      if (!shouldPlay) {
        await onPaused?.call();
      }
    }
  }

  Future<void> holdWake(bool enable) => _updateWakelock(enable && userWantsPlayback);

  Future<void> _updateWakelock(bool enable) async {
    if (enable && userWantsPlayback) {
      await PlaybackWakeLock.acquire();
    } else if (!userWantsPlayback) {
      await PlaybackWakeLock.release();
    }
  }

  Future<void> playNext() => _seekRelative(1);
  Future<void> playPrevious() => _seekRelative(-1);

  Future<void> _seekRelative(int delta) async {
    final length = _queueLength();
    if (!isPlayerOpen || length <= 0) {
      if (delta > 0) {
        await player.seekToNext();
      } else {
        await player.seekToPrevious();
      }
      return;
    }
    final index = player.currentIndex ?? _indexOf();
    var target = index + delta;
    if (delta > 0 && target >= length) {
      final wrapped = PlaybackContinuity.nextIndex(current: index, length: length, repeat: repeatMode);
      if (wrapped == null) return;
      target = wrapped;
    }
    if (target < 0) target = 0;
    if (target >= length) target = length - 1;
    try {
      await player.seek(Duration.zero, index: target);
      if (userWantsPlayback) await player.play();
    } catch (e, st) {
      debugPrint('changement de morceau: $e\n$st');
      if (delta > 0) await _continueQueue(failed: true);
    }
  }

  void setSleepTimer(Duration duration, {bool endOfTrack = false, required VoidCallback notify}) {
    sleepTimer?.cancel();
    endOfTrackSub?.cancel();
    sleepEndOfTrack = endOfTrack;
    if (endOfTrack) {
      sleepTimerEndsAt = null;
      sleepTimerRemaining = null;
    } else {
      sleepEndOfTrack = false;
      sleepTimerEndsAt = DateTime.now().add(duration);
      sleepTimerRemaining = duration;
      sleepTimer = Timer(duration, () {
        pause(notify);
        cancelSleepTimer(notify);
      });
    }
    notify();
  }

  void cancelSleepTimer(VoidCallback notify) {
    sleepEndOfTrack = false;
    sleepTimer?.cancel();
    endOfTrackSub?.cancel();
    endOfTrackSub = null;
    sleepTimer = null;
    sleepTimerEndsAt = null;
    sleepTimerRemaining = null;
    notify();
  }

  void setPointA(VoidCallback notify) {
    if (!isPlayerOpen) return;
    pointA = player.position;
    notify();
  }

  void setPointB(VoidCallback notify) {
    if (!isPlayerOpen) return;
    pointB = player.position;
    if (pointA != null && pointB! > pointA!) {
      isABLoopActive = true;
      abLoopCount = 0;
      player.seek(pointA!);
    }
    notify();
  }

  void setABLoopMax(int count, VoidCallback notify) {
    abLoopMax = count;
    notify();
  }

  void clearABLoop() {
    pointA = null;
    pointB = null;
    isABLoopActive = false;
    abLoopCount = 0;
  }

  bool shouldSave(Duration position) {
    if (!uiPlaying) return false;
    if ((position - lastSavedPosition).inSeconds.abs() < 4) return false;
    lastSavedPosition = position;
    return true;
  }

  Future<void> dispose() async {
    _playbackSyncTimer?.cancel();
    _resumeTimer?.cancel();
    await _playerStateSub?.cancel();
    await _playbackEventSub?.cancel();
    await _processingSub?.cancel();
    await _positionSub?.cancel();
    await _indexSub?.cancel();
    await _interruptionSub?.cancel();
    await _noisySub?.cancel();
    sleepTimer?.cancel();
    await endOfTrackSub?.cancel();
    userWantsPlayback = false;
    await PlaybackWakeLock.release();
    await _player?.dispose();
  }
}
