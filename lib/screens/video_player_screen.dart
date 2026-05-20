import 'dart:async';
import 'dart:io';

import 'package:donziker/services/platform_media_service.dart';
import 'package:donziker/utils/subtitle_loader.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:screen_brightness/screen_brightness.dart';
import 'package:video_player/video_player.dart';
import 'package:volume_controller/volume_controller.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

class VideoPlayerScreen extends StatefulWidget {
  final List<AssetEntity> videos;
  final int initialIndex;

  const VideoPlayerScreen({
    super.key,
    required this.videos,
    required this.initialIndex,
  });

  @override
  State<VideoPlayerScreen> createState() => _VideoPlayerScreenState();
}

class _VideoPlayerScreenState extends State<VideoPlayerScreen> {
  VideoPlayerController? _controller;
  int _currentIndex = 0;
  bool _showControls = true;
  bool _rotationLocked = false;
  bool _subtitlesEnabled = true;
  Timer? _hideTimer;
  Timer? _positionTimer;

  double _volumePercent = 100;
  double _brightness = 0.5;
  List<SubtitleCue> _subtitles = [];
  final _volumeController = VolumeController();
  final _screenBrightness = ScreenBrightness();

  static const _seekStep = Duration(seconds: 5);

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex.clamp(0, widget.videos.length - 1);
    WakelockPlus.enable();
    _initVolume();
    _loadVideo(_currentIndex);
  }

  Future<void> _initVolume() async {
    try {
      final v = await _volumeController.getVolume();
      setState(() => _volumePercent = (v * 100).clamp(0, 200));
    } catch (_) {}
    try {
      _brightness = await _screenBrightness.current;
    } catch (_) {}
  }

  Future<void> _loadVideo(int index) async {
    _controller?.dispose();
    _controller = null;
    _subtitles = [];
    setState(() {});

    final entity = widget.videos[index];
    final file = await entity.file;
    if (file == null || !mounted) return;

    _subtitles = await SubtitleLoader.loadFromVideoPath(file.path);

    _controller = VideoPlayerController.file(file)
      ..initialize().then((_) {
        if (!mounted) return;
        _controller!.setVolume((_volumePercent / 100).clamp(0.0, 1.0));
        _controller!.play();
        setState(() {});
        _resetHideTimer();
        _startPositionTimer();
      });
  }

  void _startPositionTimer() {
    _positionTimer?.cancel();
    _positionTimer = Timer.periodic(const Duration(milliseconds: 200), (_) {
      if (mounted) setState(() {});
    });
  }

  void _resetHideTimer() {
    _hideTimer?.cancel();
    _hideTimer = Timer(const Duration(seconds: 4), () {
      if (mounted) setState(() => _showControls = false);
    });
  }

  void _toggleControls() {
    setState(() => _showControls = !_showControls);
    if (_showControls) _resetHideTimer();
  }

  void _seekRelative(Duration delta) {
    if (_controller == null || !_controller!.value.isInitialized) return;
    final pos = _controller!.value.position + delta;
    final max = _controller!.value.duration;
    _controller!.seekTo(pos < Duration.zero ? Duration.zero : (pos > max ? max : pos));
    _resetHideTimer();
  }

  Future<void> _setVolumePercent(double percent) async {
    _volumePercent = percent.clamp(0, 200);
    final normalized = (_volumePercent / 100).clamp(0.0, 1.0);
    final playerVol = normalized;
    await _controller?.setVolume(playerVol);
    try {
      _volumeController.setVolume(normalized);
    } catch (_) {}
    setState(() {});
  }

  Future<void> _setBrightness(double value) async {
    _brightness = value.clamp(0.05, 1.0);
    try {
      await _screenBrightness.setScreenBrightness(_brightness);
    } catch (_) {}
    setState(() {});
  }

  void _toggleRotationLock() {
    setState(() => _rotationLocked = !_rotationLocked);
    if (_rotationLocked) {
      SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    } else {
      SystemChrome.setPreferredOrientations(DeviceOrientation.values);
    }
  }

  void _playNext() {
    if (_currentIndex < widget.videos.length - 1) {
      _currentIndex++;
      _loadVideo(_currentIndex);
    }
  }

  void _playPrevious() {
    if (_currentIndex > 0) {
      _currentIndex--;
      _loadVideo(_currentIndex);
    }
  }

  void _onVerticalDrag(DragUpdateDetails d, BoxConstraints constraints) {
    final isLeft = d.localPosition.dx < constraints.maxWidth * 0.5;
    final delta = -d.delta.dy / constraints.maxHeight;
    if (isLeft) {
      _setBrightness(_brightness + delta * 1.2);
    } else {
      _setVolumePercent(_volumePercent + delta * 200);
    }
    setState(() => _showControls = true);
    _resetHideTimer();
  }

  void _onTap(TapUpDetails d, BoxConstraints constraints) {
    final w = constraints.maxWidth;
    final x = d.localPosition.dx;
    if (x < w * 0.35) {
      _seekRelative(-_seekStep);
    } else if (x > w * 0.65) {
      _seekRelative(_seekStep);
    } else {
      _toggleControls();
    }
  }

  String _format(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final initialized = _controller?.value.isInitialized ?? false;
    final pos = _controller?.value.position ?? Duration.zero;
    final dur = _controller?.value.duration ?? Duration.zero;
    final cue = _subtitlesEnabled ? SubtitleLoader.cueAt(_subtitles, pos) : null;

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTapUp: (d) => _onTap(d, constraints),
              onVerticalDragUpdate: (d) => _onVerticalDrag(d, constraints),
              onDoubleTapDown: (d) {
                final w = constraints.maxWidth;
                if (d.localPosition.dx < w * 0.5) {
                  _seekRelative(-_seekStep);
                } else {
                  _seekRelative(_seekStep);
                }
              },
              child: Stack(
                alignment: Alignment.center,
                children: [
                  if (initialized)
                    Center(
                      child: AspectRatio(
                        aspectRatio: _controller!.value.aspectRatio,
                        child: VideoPlayer(_controller!),
                      ),
                    )
                  else
                    const CircularProgressIndicator(),
                  if (cue != null)
                    Positioned(
                      bottom: 100,
                      left: 16,
                      right: 16,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.black54,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          cue.text,
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: Colors.white, fontSize: 16),
                        ),
                      ),
                    ),
                  if (!_showControls && initialized)
                    Positioned(
                      top: 8,
                      right: 8,
                      child: _badge('${_volumePercent.round()}%', Icons.volume_up),
                    ),
                  AnimatedOpacity(
                    opacity: _showControls ? 1 : 0,
                    duration: const Duration(milliseconds: 200),
                    child: IgnorePointer(
                      ignoring: !_showControls,
                      child: _buildControls(dur, pos),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _badge(String text, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(8)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 16),
          const SizedBox(width: 4),
          Text(text, style: const TextStyle(color: Colors.white, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildControls(Duration dur, Duration pos) {
    return Container(
      color: Colors.black.withValues(alpha: 0.45),
      child: Column(
        children: [
          AppBar(
            backgroundColor: Colors.transparent,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
            title: Text(
              widget.videos[_currentIndex].title ?? 'Vidéo ${_currentIndex + 1}',
              style: const TextStyle(color: Colors.white, fontSize: 16),
            ),
            actions: [
              IconButton(
                icon: Icon(_subtitlesEnabled ? Icons.subtitles : Icons.subtitles_off_outlined, color: Colors.white),
                onPressed: () => setState(() {
                  _subtitlesEnabled = !_subtitlesEnabled;
                  if (_subtitles.isEmpty && _subtitlesEnabled) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Aucun fichier .srt/.vtt à côté de la vidéo')),
                    );
                  }
                }),
              ),
              IconButton(
                icon: Icon(_rotationLocked ? Icons.screen_lock_rotation : Icons.screen_rotation, color: Colors.white),
                onPressed: _toggleRotationLock,
              ),
              if (Platform.isAndroid)
                IconButton(
                  icon: const Icon(Icons.picture_in_picture_alt, color: Colors.white),
                  onPressed: () async {
                    final ok = await PlatformMediaService.enterPipMode();
                    if (!ok && mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('PiP non disponible sur cet appareil')),
                      );
                    }
                  },
                ),
            ],
          ),
          const Spacer(),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                _badge('${(_brightness * 100).round()}%', Icons.brightness_6),
                const Spacer(),
                _badge('${_volumePercent.round()}%', Icons.volume_up),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: [
                Text(_format(pos), style: const TextStyle(color: Colors.white70, fontSize: 12)),
                Expanded(
                  child: Slider(
                    value: dur.inMilliseconds > 0
                        ? pos.inMilliseconds.toDouble().clamp(0, dur.inMilliseconds.toDouble())
                        : 0,
                    max: dur.inMilliseconds > 0 ? dur.inMilliseconds.toDouble() : 1,
                    onChanged: (v) => _controller?.seekTo(Duration(milliseconds: v.toInt())),
                    activeColor: Colors.redAccent,
                  ),
                ),
                Text(_format(dur), style: const TextStyle(color: Colors.white70, fontSize: 12)),
              ],
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              IconButton(
                icon: const Icon(Icons.skip_previous, color: Colors.white, size: 36),
                onPressed: _currentIndex > 0 ? _playPrevious : null,
              ),
              IconButton(
                icon: const Icon(Icons.replay_5, color: Colors.white, size: 32),
                onPressed: () => _seekRelative(-_seekStep),
              ),
              IconButton(
                icon: Icon(
                  _controller?.value.isPlaying == true ? Icons.pause_circle_filled : Icons.play_circle_filled,
                  color: Colors.white,
                  size: 56,
                ),
                onPressed: () {
                  if (_controller!.value.isPlaying) {
                    _controller!.pause();
                  } else {
                    _controller!.play();
                  }
                  setState(() {});
                },
              ),
              IconButton(
                icon: const Icon(Icons.forward_5, color: Colors.white, size: 32),
                onPressed: () => _seekRelative(_seekStep),
              ),
              IconButton(
                icon: const Icon(Icons.skip_next, color: Colors.white, size: 36),
                onPressed: _currentIndex < widget.videos.length - 1 ? _playNext : null,
              ),
            ],
          ),
          const Padding(
            padding: EdgeInsets.all(8),
            child: Text(
              'Gauche: luminosité ↑  |  Droite: volume ↑ (200 max)  |  Tap bords: ±5 s',
              style: TextStyle(color: Colors.white38, fontSize: 11),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _hideTimer?.cancel();
    _positionTimer?.cancel();
    _controller?.dispose();
    WakelockPlus.disable();
    SystemChrome.setPreferredOrientations(DeviceOrientation.values);
    super.dispose();
  }
}
