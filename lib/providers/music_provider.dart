import 'dart:io';
import 'dart:math';
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'package:on_audio_query/on_audio_query.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path_provider/path_provider.dart';
import 'package:device_info_plus/device_info_plus.dart';

enum RepeatMode { none, one, all }

class MusicProvider extends ChangeNotifier {
  final AudioPlayer _audioPlayer = AudioPlayer();
  final OnAudioQuery _audioQuery = OnAudioQuery();

  List<SongModel> _songs = [];
  List<AssetEntity> _videos = [];
  int _currentIndex = -1;
  double _speed = 1.0;
  List<String> _favorites = [];
  List<String> _recentlyPlayedIds = [];
  bool _isLoading = false;
  bool _permissionGranted = false;
  bool _isShuffle = false;
  RepeatMode _repeatMode = RepeatMode.none;

  // Sleep Timer
  Timer? _sleepTimer;
  Duration? _sleepTimerDuration;

  // Revision Mode (A-B Loop)
  Duration? _pointA;
  Duration? _pointB;
  bool _isABLoopActive = false;

  // Getters
  AudioPlayer get audioPlayer => _audioPlayer;
  bool get isPlaying => _audioPlayer.playing;
  SongModel? get currentSong => _currentIndex != -1 && _currentIndex < _songs.length ? _songs[_currentIndex] : null;
  List<SongModel> get songs => _songs;
  List<AssetEntity> get videos => _videos;
  double get speed => _speed;
  List<String> get favorites => _favorites;
  List<SongModel> get recentlyPlayed => _songs.where((s) => _recentlyPlayedIds.contains(s.id.toString())).toList();
  bool get isLoading => _isLoading;
  bool get permissionGranted => _permissionGranted;
  bool get isShuffle => _isShuffle;
  RepeatMode get repeatMode => _repeatMode;
  bool isFavorite(String songId) => _favorites.contains(songId);
  
  Duration? get pointA => _pointA;
  Duration? get pointB => _pointB;
  bool get isABLoopActive => _isABLoopActive;

  String get searchQuery => _searchQuery;
  String? get currentLyrics => _currentLyrics;

  List<SongModel> get filteredSongs {
    if (_searchQuery.isEmpty) return _songs;
    return _songs.where((song) => 
      song.title.toLowerCase().contains(_searchQuery.toLowerCase()) || 
      (song.artist?.toLowerCase().contains(_searchQuery.toLowerCase()) ?? false)
    ).toList();
  }

  MusicProvider() {
    // Ne pas appeler _init() ici car PermissionHandler a besoin que l'Activity soit prête.
  }

  Future<void> init() async {
    try {
      await _loadPreferences();
      _setupAudioListeners();
    } catch (e) {
      debugPrint("MusicProvider.init error: $e");
    }
  }

  void _setupAudioListeners() {
    _audioPlayer.processingStateStream.listen((state) {
      if (state == ProcessingState.completed) {
        playNext();
      }
    });

    _audioPlayer.positionStream.listen((position) {
      if (_isABLoopActive && _pointA != null && _pointB != null) {
        if (position >= _pointB!) {
          _audioPlayer.seek(_pointA!);
        }
      }
    });

    _audioPlayer.currentIndexStream.listen((index) {
      if (index != null && index != _currentIndex) {
        _currentIndex = index;
        if (_currentIndex != -1) {
          final songId = _songs[_currentIndex].id;
          _addToRecentlyPlayed(songId.toString());
          loadLyrics(songId); // Automatically load lyrics
        }
        notifyListeners();
      }
    });
  }

  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    _favorites = prefs.getStringList('favorites') ?? [];
    _recentlyPlayedIds = prefs.getStringList('recently_played') ?? [];
    notifyListeners();
  }

  Future<void> checkAndRequestPermissions() async {
    if (_permissionGranted) return;
    
    bool granted = false;
    
    if (Platform.isAndroid) {
      // Check Android version
      final deviceInfo = await DeviceInfoPlugin().androidInfo;
      final sdkInt = deviceInfo.version.sdkInt;

      if (sdkInt >= 33) {
        // Android 13+
        final audioStatus = await Permission.audio.request();
        final videoStatus = await Permission.videos.request();
        final photosStatus = await Permission.photos.request();
        
        granted = audioStatus.isGranted || videoStatus.isGranted;
      } else {
        // Android 12 and below
        granted = await Permission.storage.request().isGranted;
      }
    } else {
      granted = await Permission.storage.request().isGranted;
    }
    
    final photoStatus = await PhotoManager.requestPermissionExtend();

    if (granted && photoStatus.isAuth) {
      _permissionGranted = true;
      await loadMedia();
    } else {
      _permissionGranted = false;
    }
    notifyListeners();
  }

  bool _isBusy = false;

  Future<void> loadMedia({int retryCount = 0}) async {
    if (!_permissionGranted || _isBusy) return;
    _isBusy = true;
    _isLoading = true;
    notifyListeners();

    try {
      // Small initial delay to let context stabilize
      await Future.delayed(Duration(milliseconds: 500 + (retryCount * 1000)));
      
      _songs = await _audioQuery.querySongs(
        sortType: SongSortType.TITLE,
        orderType: OrderType.ASC_OR_SMALLER,
        uriType: UriType.EXTERNAL,
        ignoreCase: true,
      );

      _songs = _songs.where((song) => (song.duration ?? 0) > 10000).toList();

      List<AssetPathEntity> videoAlbums = await PhotoManager.getAssetPathList(type: RequestType.video);
      _videos = [];
      if (videoAlbums.isNotEmpty) {
        final List<AssetEntity> videoAssets = await videoAlbums[0].getAssetListPaged(page: 0, size: 50);
        _videos.addAll(videoAssets);
      }
      
      debugPrint("Media loaded successfully after $retryCount retries");
    } catch (e) {
      debugPrint("Error loading media (Attempt $retryCount): $e");
      
      // Si c'est une erreur de verrouillage SQLite, on réessaie jusqu'à 3 fois
      if (e.toString().contains("database is locked") && retryCount < 3) {
        _isBusy = false; // Reset busy for retry
        return loadMedia(retryCount: retryCount + 1);
      }
    } finally {
      _isLoading = false;
      _isBusy = false;
      notifyListeners();
    }
  }

  void setPlaylist(List<SongModel> songs, int index) async {
    _songs = songs;
    _currentIndex = index;
    
    final playlist = ConcatenatingAudioSource(
      children: _songs.map((song) => AudioSource.uri(
        Uri.parse(song.uri!),
        tag: MediaItem(
          id: song.id.toString(),
          album: song.album ?? "Unknown Album",
          title: song.title,
          artist: song.artist ?? "Unknown Artist",
          artUri: Uri.parse('content://media/external/audio/media/${song.id}/albumart'), // Fallback for android
        ),
      )).toList(),
    );

    await _audioPlayer.setAudioSource(playlist, initialIndex: index);
    _audioPlayer.play();
    notifyListeners();
  }

  void setSpeed(double speed) {
    _speed = speed;
    _audioPlayer.setSpeed(speed);
    notifyListeners();
  }

  void toggleShuffle() {
    _isShuffle = !_isShuffle;
    _audioPlayer.setShuffleModeEnabled(_isShuffle);
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

  void toggleFavorite(String songId) async {
    if (_favorites.contains(songId)) {
      _favorites.remove(songId);
    } else {
      _favorites.add(songId);
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('favorites', _favorites);
    notifyListeners();
  }

  void _addToRecentlyPlayed(String songId) async {
    _recentlyPlayedIds.remove(songId);
    _recentlyPlayedIds.insert(0, songId);
    if (_recentlyPlayedIds.length > 20) {
      _recentlyPlayedIds.removeLast();
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('recently_played', _recentlyPlayedIds);
    notifyListeners();
  }

  void play() => _audioPlayer.play();
  void pause() => _audioPlayer.pause();
  void playNext() => _audioPlayer.seekToNext();
  void playPrevious() => _audioPlayer.seekToPrevious();

  // Sleep Timer
  void setSleepTimer(Duration duration) {
    _sleepTimer?.cancel();
    _sleepTimerDuration = duration;
    _sleepTimer = Timer(duration, () {
      pause();
      _sleepTimerDuration = null;
      notifyListeners();
    });
    notifyListeners();
  }

  void cancelSleepTimer() {
    _sleepTimer?.cancel();
    _sleepTimerDuration = null;
    notifyListeners();
  }

  // Revision Mode (A-B Loop)
  void setPointA() {
    _pointA = _audioPlayer.position;
    notifyListeners();
  }

  void setPointB() {
    _pointB = _audioPlayer.position;
    if (_pointA != null && _pointB! > _pointA!) {
      _isABLoopActive = true;
      _audioPlayer.seek(_pointA!);
    }
    notifyListeners();
  }

  void clearABLoop() {
    _pointA = null;
    _pointB = null;
    _isABLoopActive = false;
    notifyListeners();
  }
  String _searchQuery = "";
  String? _currentLyrics;

  void updateSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  Future<void> loadLyrics(int songId) async {
    // Simulating synced lyrics
    _currentLyrics = "[00:00.00]Lecture en cours...\n"
                     "[00:05.00]Bienvenue sur DonZiker\n"
                     "[00:10.00]Mode Révision disponible\n"
                     "[00:15.00]Profitez de votre musique\n"
                     "[00:20.00]Design par DonChaminade";
    notifyListeners();
  }
}