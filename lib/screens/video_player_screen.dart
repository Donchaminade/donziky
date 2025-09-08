import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:video_player/video_player.dart';

class VideoPlayerScreen extends StatefulWidget {
  final AssetEntity video;

  const VideoPlayerScreen({super.key, required this.video});

  @override
  State<VideoPlayerScreen> createState() => _VideoPlayerScreenState();
}

class _VideoPlayerScreenState extends State<VideoPlayerScreen> {
  VideoPlayerController? _controller;
  bool _showControls = true;
  Timer? _controlsTimer;

  @override
  void initState() {
    super.initState();
    _initializeController();
  }

  Future<void> _initializeController() async {
    final file = await widget.video.file;
    if (file != null) {
      _controller = VideoPlayerController.file(file)
        ..initialize().then((_) {
          setState(() {});
          _controller!.play();
          _startControlsTimer();
        });
      _controller!.addListener(() {
        if (_controller!.value.isPlaying && _showControls) {
          _startControlsTimer();
        }
      });
    }
  }

  void _startControlsTimer() {
    _controlsTimer?.cancel();
    _controlsTimer = Timer(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() {
          _showControls = false;
        });
      }
    });
  }

  void _toggleControls() {
    setState(() {
      _showControls = !_showControls;
      if (_showControls) {
        _startControlsTimer();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: _showControls
          ? AppBar(
              title: Text(widget.video.title ?? "Video Player"),
              backgroundColor: Colors.black.withOpacity(0.5),
            )
          : null,
      body: GestureDetector(
        onTap: _toggleControls,
        child: Center(
          child: _controller != null && _controller!.value.isInitialized
              ? AspectRatio(
                  aspectRatio: _controller!.value.aspectRatio,
                  child: Stack(
                    alignment: Alignment.bottomCenter,
                    children: <Widget>[
                      VideoPlayer(_controller!),
                      _buildControls(),
                    ],
                  ),
                )
              : const CircularProgressIndicator(),
        ),
      ),
    );
  }

  Widget _buildControls() {
    if (_controller == null) {
      return const SizedBox.shrink();
    }
    return AnimatedOpacity(
      opacity: _showControls ? 1.0 : 0.0,
      duration: const Duration(milliseconds: 300),
      child: Container(
        color: Colors.black.withOpacity(0.5),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            VideoProgressIndicator(
              _controller!,
              allowScrubbing: true,
              padding: const EdgeInsets.symmetric(vertical: 8.0),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: <Widget>[
                IconButton(
                  icon: const Icon(Icons.replay_10, color: Colors.white),
                  onPressed: () {
                    _controller!.seekTo(_controller!.value.position - const Duration(seconds: 10));
                  },
                ),
                IconButton(
                  icon: Icon(
                    _controller!.value.isPlaying ? Icons.pause : Icons.play_arrow,
                    color: Colors.white,
                    size: 40,
                  ),
                  onPressed: () {
                    setState(() {
                      _controller!.value.isPlaying ? _controller!.pause() : _controller!.play();
                    });
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.forward_10, color: Colors.white),
                  onPressed: () {
                    _controller!.seekTo(_controller!.value.position + const Duration(seconds: 10));
                  },
                ),
                Row(
                  children: [
                    const Icon(Icons.volume_up, color: Colors.white),
                    Slider(
                      value: _controller!.value.volume,
                      onChanged: (value) {
                        setState(() {
                          _controller!.setVolume(value);
                        });
                      },
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _controlsTimer?.cancel();
    _controller?.dispose();
    super.dispose();
  }
}
