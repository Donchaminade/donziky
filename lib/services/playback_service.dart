import 'dart:async';

import 'package:donziker/models/repeat_mode.dart';
import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';
import 'package:on_audio_query/on_audio_query.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

/// Lecture : transport, vitesse, répétition, minuterie, boucle A-B, karaoké.
///
/// Le lecteur plateforme n'est créé qu'au premier accès, pour que les tests
/// qui ne lancent pas de son n'ouvrent pas de canal natif.
class PlaybackService {
  AudioPlayer? _player;
  AudioPlayer get player {
    if (_player == null) {
      _player = AudioPlayer();
      _player!.setSpeed(speed);
    }
    return _player!;
  }
  bool get isPlayerOpen => _player != null;

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
  StreamSubscription<PlayerState>? _playerStateSub;
  StreamSubscription<PlaybackEvent>? _playbackEventSub;
  StreamSubscription<ProcessingState>? _processingSub;
  StreamSubscription<Duration>? _positionSub;
  StreamSubscription<int?>? _indexSub;

  Duration lastSavedPosition = Duration.zero;

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
    _playerStateSub?.cancel();
    _playbackEventSub?.cancel();
    _processingSub?.cancel();
    _positionSub?.cancel();
    _indexSub?.cancel();

    _playerStateSub = player.playerStateStream.listen((state) {
      if (syncingPlayback) return;
      if (uiPlaying && !state.playing && state.processingState == ProcessingState.loading) {
        return;
      }
      if (state.playing != uiPlaying) {
        uiPlaying = state.playing;
        _updateWakelock(state.playing);
        notify();
      }
    });

    _playbackEventSub = player.playbackEventStream.listen((event) async {
      if (syncingPlayback || !uiPlaying) return;
      final dur = event.duration ?? player.duration;
      final pos = event.updatePosition;
      if (dur == null) return;
      if (!player.playing &&
          event.processingState == ProcessingState.ready &&
          pos < dur - const Duration(seconds: 3)) {
        try {
          await player.play();
        } catch (e) {
          debugPrint('Auto-resume error: $e');
        }
      }
    });

    uiPlaying = player.playing;
    if (uiPlaying) _updateWakelock(true);

    _processingSub = player.processingStateStream.listen((state) async {
      if (state == ProcessingState.completed) {
        if (sleepEndOfTrack) {
          await pause();
          cancelSleepTimer(notify);
          return;
        }
        if (repeatMode == RepeatMode.one) {
          await player.seek(Duration.zero);
          uiPlaying = true;
          notify();
          await player.play();
        } else if (repeatMode == RepeatMode.all || currentIndex() < queueLength() - 1) {
          playNext();
        } else {
          uiPlaying = false;
          _updateWakelock(false);
          notify();
        }
      }
    });

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
    });

    _indexSub = player.currentIndexStream.listen((index) async {
      if (index != null && index != currentIndex() && index < queueLength()) {
        final song = songAt(index);
        if (song == null) return;
        karaokeSkippedForIndex = null;
        await onIndexChanged(index, song);
      }
    });
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
    notify();
    _playbackSyncTimer?.cancel();
    _playbackSyncTimer = Timer(const Duration(milliseconds: 50), () {
      applyUiState();
    });
  }

  Future<void> play(VoidCallback notify) async {
    if (uiPlaying) return;
    uiPlaying = true;
    notify();
    await applyUiState();
  }

  Future<void> pause(VoidCallback notify) async {
    if (!uiPlaying) return;
    uiPlaying = false;
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

  Future<void> holdWake(bool enable) => _updateWakelock(enable);

  Future<void> _updateWakelock(bool enable) async {
    try {
      if (enable) {
        await WakelockPlus.enable();
      } else {
        await WakelockPlus.disable();
      }
    } catch (e) {
      debugPrint('Wakelock error: $e');
    }
  }

  void playNext() => player.seekToNext();
  void playPrevious() => player.seekToPrevious();

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
    await _playerStateSub?.cancel();
    await _playbackEventSub?.cancel();
    await _processingSub?.cancel();
    await _positionSub?.cancel();
    await _indexSub?.cancel();
    sleepTimer?.cancel();
    await endOfTrackSub?.cancel();
    try {
      await WakelockPlus.disable();
    } catch (_) {}
    await _player?.dispose();
  }
}
