import 'dart:io';
import 'dart:math';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum RepeatMode { none, one, all }

class MusicProvider extends ChangeNotifier {
  final AudioPlayer _audioPlayer = AudioPlayer();

  List<AssetEntity> _songs = [];
  List<AssetEntity> _videos = [];
  int _currentIndex = -1;
  double _speed = 1.0;
  List<String> _favorites = [];
  bool _isLoading = false;
  PermissionState _permissionState = PermissionState.denied;
  bool _isShuffle = false;
  RepeatMode _repeatMode = RepeatMode.none;

  // Getters
  AudioPlayer get audioPlayer => _audioPlayer;
  bool get isPlaying => _audioPlayer.playing;
  AssetEntity? get currentSong => _currentIndex != -1 ? _songs[_currentIndex] : null;
  List<AssetEntity> get songs => _songs;
  List<AssetEntity> get videos => _videos;
  double get speed => _speed;
  List<String> get favorites => _favorites;
  bool get isLoading => _isLoading;
  PermissionState get permissionState => _permissionState;
  bool get isShuffle => _isShuffle;
  RepeatMode get repeatMode => _repeatMode;
  bool isFavorite(String songId) => _favorites.contains(songId);

  MusicProvider() {
    _loadFavorites();
    checkAndRequestPermissions();
    _audioPlayer.processingStateStream.listen((state) {
      if (state == ProcessingState.completed) {
        playNext();
      }
    });
  }

  Future<void> checkAndRequestPermissions() async {
    _permissionState = await PhotoManager.requestPermissionExtend();
    if (_permissionState.isAuth) {
      loadMedia();
    }
    notifyListeners();
  }


  Future<void> loadMedia() async {
    _isLoading = true;
    notifyListeners();

    final List<AssetPathEntity> audioAlbums = await PhotoManager.getAssetPathList(
      type: RequestType.audio,
    );
    if (audioAlbums.isNotEmpty) {
      final List<AssetEntity> audioAssets = await audioAlbums[0].getAssetListPaged(
        page: 0,
        size: 1000, // Load a large number of audio files
      );
      _songs = audioAssets;
    }

    final List<AssetPathEntity> videoAlbums = await PhotoManager.getAssetPathList(
      type: RequestType.video,
    );
    if (videoAlbums.isNotEmpty) {
      final List<AssetEntity> videoAssets = await videoAlbums[0].getAssetListPaged(
        page: 0,
        size: 1000, // Load a large number of videos
      );
      _videos = videoAssets;
    }

    _isLoading = false;
    notifyListeners();
  }

  // Setters
  void setPlaylist(List<AssetEntity> songs, int index) {
    _songs = songs;
    _currentIndex = index;
    _playCurrentSong();
    notifyListeners();
  }

  void setSpeed(double speed) {
    _speed = speed;
    _audioPlayer.setSpeed(speed);
    notifyListeners();
  }

  void toggleShuffle() {
    _isShuffle = !_isShuffle;
    notifyListeners();
  }

  void cycleRepeatMode() {
    if (_repeatMode == RepeatMode.none) {
      _repeatMode = RepeatMode.one;
      _audioPlayer.setLoopMode(LoopMode.one);
    } else if (_repeatMode == RepeatMode.one) {
      _repeatMode = RepeatMode.all;
      _audioPlayer.setLoopMode(LoopMode.all);
    } else {
      _repeatMode = RepeatMode.none;
      _audioPlayer.setLoopMode(LoopMode.off);
    }
    notifyListeners();
  }

  // Favorites
  void _loadFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    final favorites = prefs.getStringList('favorites');
    if (favorites != null) {
      _favorites = favorites;
      notifyListeners();
    }
  }

  void toggleFavorite(String songId) async {
    final prefs = await SharedPreferences.getInstance();
    if (_favorites.contains(songId)) {
      _favorites.remove(songId);
    } else {
      _favorites.add(songId);
    }
    await prefs.setStringList('favorites', _favorites);;
    notifyListeners();
  }


  void _playCurrentSong() async {
    if (currentSong != null) {
      try {
        final file = await currentSong!.file;
        if (file != null) {
          await _audioPlayer.setAudioSource(
            AudioSource.uri(Uri.parse(file.path)),
          );
          _audioPlayer.play();
          _audioPlayer.setSpeed(_speed);
        }
      } catch (e) {
        debugPrint("Error playing song: $e");
        playNext();
      }
    }
  }

  void play() {
    _audioPlayer.play();
    notifyListeners();
  }

  void pause() {
    _audioPlayer.pause();
    notifyListeners();
  }

  void playNext() {
    if (_isShuffle) {
      _currentIndex = Random().nextInt(_songs.length);
    } else {
      if (_currentIndex < _songs.length - 1) {
        _currentIndex++;
      }
    }
    _playCurrentSong();
    notifyListeners();
  }

  void playPrevious() {
    if (_currentIndex > 0) {
      _currentIndex--;
      _playCurrentSong();
      notifyListeners();
    }
  }
}